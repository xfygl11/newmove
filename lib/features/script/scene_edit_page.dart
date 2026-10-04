import 'dart:convert';

import 'package:drift/drift.dart' hide Column, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/json_values.dart';
import '../../data/app_database.dart';
import 'script_models.dart';
import 'script_providers.dart';

/// 场次编辑：基本信息 + 对白 + 声音提示。
class SceneEditPage extends ConsumerStatefulWidget {
  const SceneEditPage({
    super.key,
    required this.projectId,
    required this.sceneId,
  });

  final int projectId;
  final int sceneId;

  @override
  ConsumerState<SceneEditPage> createState() => _SceneEditPageState();
}

class _SceneEditPageState extends ConsumerState<SceneEditPage> {
  final _seq = TextEditingController();
  final _location = TextEditingController();
  final _time = TextEditingController();
  final _characters = TextEditingController();
  final _summary = TextEditingController();
  final _action = TextEditingController();
  final _startState = TextEditingController();
  final _endState = TextEditingController();
  final _transition = TextEditingController();
  final _sound = TextEditingController();

  List<DialogueLine> _dialogue = [];
  bool _loaded = false;
  bool _busy = false;

  static const _types = ['对白', 'OS', 'VO'];

  @override
  void dispose() {
    for (final c in [
      _seq,
      _location,
      _time,
      _characters,
      _summary,
      _action,
      _startState,
      _endState,
      _transition,
      _sound,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _load(Scene scene) {
    if (_loaded) return;
    _loaded = true;
    _seq.text = '${scene.seq}';
    _location.text = scene.location;
    _time.text = scene.time;
    _characters.text = _decodeStringList(scene.characters).join('、');
    _summary.text = scene.summary ?? '';
    _action.text = scene.action;
    _startState.text = scene.startState ?? '';
    _endState.text = scene.endState ?? '';
    _transition.text = scene.transition ?? '';
    _sound.text = jsonString(_decodeMap(scene.sound)['text']);
    _dialogue = [
      for (final d in _decodeList(scene.dialogue))
        DialogueLine.fromJson(jsonMap(d)),
    ];
  }

  static List<String> _decodeStringList(String raw) {
    final d = _tryDecode(raw);
    if (d is List) return [for (final v in d) '$v'];
    return const [];
  }

  static List<dynamic> _decodeList(String raw) {
    final d = _tryDecode(raw);
    if (d is List) return d;
    return const [];
  }

  static Map<String, dynamic> _decodeMap(String raw) {
    final d = _tryDecode(raw);
    if (d is Map) return d.cast<String, dynamic>();
    return const {};
  }

  static dynamic _tryDecode(String raw) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  Future<void> _save() async {
    final seq = int.tryParse(_seq.text.trim());
    if (seq == null) {
      _toast('场次序号必须是数字');
      return;
    }
    setState(() => _busy = true);
    try {
      final data = ScenesCompanion(
        seq: Value(seq),
        location: Value(_location.text.trim()),
        time: Value(_time.text.trim()),
        characters: Value(
          jsonEncode(
            _characters.text
                .split('、')
                .where((s) => s.trim().isNotEmpty)
                .toList(),
          ),
        ),
        summary: Value(_summary.text.trim()),
        action: Value(_action.text.trim()),
        startState: Value(_startState.text.trim()),
        endState: Value(_endState.text.trim()),
        transition: Value(_transition.text.trim()),
        dialogue: Value(jsonEncode([for (final d in _dialogue) d.toJson()])),
        sound: Value(
          jsonEncode(
            _sound.text.trim().isEmpty
                ? const <String, dynamic>{}
                : <String, dynamic>{'text': _sound.text.trim()},
          ),
        ),
      );
      await ref.read(scriptServiceProvider).updateScene(widget.sceneId, data);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _toast('保存失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final sceneAsync = ref.watch(sceneProvider(widget.sceneId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('场次编辑'),
        actions: [
          IconButton(
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _busy ? null : _save,
          ),
        ],
      ),
      body: sceneAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (scene) {
          if (scene == null) {
            return const Center(child: Text('场次不存在'));
          }
          _load(scene);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _field('序号', _seq, keyboardType: TextInputType.number),
              _field('地点', _location),
              _field('时间', _time),
              _field('出场人物（用「、」分隔）', _characters),
              _field('概要', _summary, maxLines: 2),
              _field('画面与动作', _action, maxLines: 4),
              _field('起始状态', _startState),
              _field('结束状态', _endState),
              _field('转场', _transition),
              _field('声音 / 音效提示', _sound, maxLines: 2),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '对白',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('加对白'),
                    onPressed: () => setState(() {
                      _dialogue.add(
                        DialogueLine(speaker: '', type: '对白', text: ''),
                      );
                    }),
                  ),
                ],
              ),
              for (var i = 0; i < _dialogue.length; i++)
                _DialogueEditor(
                  index: i,
                  line: _dialogue[i],
                  types: _types,
                  onChanged: (d) => setState(() => _dialogue[i] = d),
                  onDelete: () => setState(() => _dialogue.removeAt(i)),
                  onMoveUp: i == 0
                      ? null
                      : () => setState(() {
                          final d = _dialogue.removeAt(i);
                          _dialogue.insert(i - 1, d);
                        }),
                  onMoveDown: i == _dialogue.length - 1
                      ? null
                      : () => setState(() {
                          final d = _dialogue.removeAt(i);
                          _dialogue.insert(i + 1, d);
                        }),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _DialogueEditor extends StatefulWidget {
  const _DialogueEditor({
    required this.index,
    required this.line,
    required this.types,
    required this.onChanged,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final int index;
  final DialogueLine line;
  final List<String> types;
  final ValueChanged<DialogueLine> onChanged;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  State<_DialogueEditor> createState() => _DialogueEditorState();
}

class _DialogueEditorState extends State<_DialogueEditor> {
  late final TextEditingController _speaker;
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _speaker = TextEditingController(text: widget.line.speaker);
    _text = TextEditingController(text: widget.line.text);
  }

  @override
  void didUpdateWidget(_DialogueEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 排序 / 删除导致同一位置对应不同对白时，同步编辑器文本。
    if (widget.index != oldWidget.index ||
        widget.line.speaker != _speaker.text ||
        widget.line.text != _text.text) {
      _speaker.text = widget.line.speaker;
      _text.text = widget.line.text;
    }
  }

  @override
  void dispose() {
    _speaker.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: '说话人'),
                    controller: _speaker,
                    onChanged: (v) =>
                        widget.onChanged(line.copyWith(speaker: v)),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: widget.types.contains(line.type) ? line.type : '对白',
                  items: [
                    for (final t in widget.types)
                      DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: (v) =>
                      widget.onChanged(line.copyWith(type: v ?? '对白')),
                ),
              ],
            ),
            TextField(
              decoration: const InputDecoration(labelText: '台词'),
              maxLines: 2,
              controller: _text,
              onChanged: (v) => widget.onChanged(line.copyWith(text: v)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: widget.onMoveUp,
                  tooltip: '上移',
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  onPressed: widget.onMoveDown,
                  tooltip: '下移',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.onDelete,
                  tooltip: '删除',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
