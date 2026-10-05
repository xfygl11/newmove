import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/protocols.dart';
import '../../core/network/providers.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import 'model_fetcher.dart';
import 'provider_models.dart';

/// 打开供应商编辑 Sheet。[group] 仅新建时传入；[existing] 编辑时传入。
/// Base URL 校验：必须 https，或显式允许本机回环（本地调试用）。
///
/// 此前只判非空，`http://` / `file://` 都能通过，API Key 以 Bearer 明文
/// 随请求发出，局域网内任何一跳都能截走。
String? validateBaseUrl(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return '请填写 Base URL';
  final uri = Uri.tryParse(text);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return 'Base URL 格式不正确，应形如 https://api.example.com/v1';
  }
  if (uri.scheme == 'https') return null;
  final loopback =
      uri.host == 'localhost' ||
      uri.host == '127.0.0.1' ||
      uri.host == '[::1]' ||
      uri.host == '::1';
  return loopback ? null : '必须使用 https，明文 http 会在链路上泄露 API Key';
}

Future<void> showProviderEditSheet(
  BuildContext context, {
  ProviderGroup? group,
  ProviderConfig? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ProviderEditSheet(group: group, existing: existing),
  );
}

/// 供应商新增 / 编辑 / 删除 / 连接测试。
class ProviderEditSheet extends ConsumerStatefulWidget {
  const ProviderEditSheet({super.key, this.group, this.existing});

  final ProviderGroup? group;
  final ProviderConfig? existing;

  @override
  ConsumerState<ProviderEditSheet> createState() => _ProviderEditSheetState();
}

class _ProviderEditSheetState extends ConsumerState<ProviderEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _baseUrl;
  late final TextEditingController _apiKey;
  late final TextEditingController _protocol;
  late final TextEditingController _readme;

  late ProviderGroup _group;
  late List<ProviderModel> _models;

  bool _saving = false;
  bool _testing = false;
  bool _fetching = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _group = existing != null
        ? ProviderGroup.fromValue(existing.group)
        : widget.group ?? ProviderGroup.llm;
    _label = TextEditingController(text: existing?.label ?? '');
    _baseUrl = TextEditingController(text: existing?.baseUrl ?? '');
    _apiKey = TextEditingController();
    _protocol = TextEditingController(
      text: existing?.protocol ?? _defaultProtocol(_group),
    );
    _readme = TextEditingController(text: existing?.readme ?? '');
    _models = existing != null
        ? ProviderModelCodec.decode(existing.models)
        : [ProviderModel(id: '', label: '')];
  }

  @override
  void dispose() {
    _label.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    _protocol.dispose();
    _readme.dispose();
    super.dispose();
  }

  /// 若当前 `_protocol` 值不在 [_protocolOptions] 里（历史数据/预设），
  /// 返回第一项兜底，避免 DropdownButton 断言崩溃。
  String _safeProtocol() {
    final current = _protocol.text;
    final options = _protocolOptions(_group);
    if (options.contains(current)) return current;
    return options.first;
  }

  static String _defaultProtocol(ProviderGroup group) {
    return Protocols.optionsFor(group.name).first;
  }

  static List<String> _protocolOptions(ProviderGroup group) {
    return Protocols.optionsFor(group.name);
  }

  String _newId() {
    return 'p${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // 保留全部有 id 的模型（未勾选的也存，勾选态是配置的一部分）；
    // 但至少要有一个已勾选模型，否则生成链路无可用模型。
    final validModels = _models
        .where((m) => m.id.trim().isNotEmpty)
        .map(
          (m) => m.copyWith(
            id: m.id.trim(),
            label: m.label.trim().isEmpty ? m.id.trim() : m.label.trim(),
          ),
        )
        .toList();
    if (validModels.isEmpty) {
      _showMessage('请至少添加一个模型');
      return;
    }
    if (!validModels.any((m) => m.enabled)) {
      _showMessage('请至少勾选启用一个模型');
      return;
    }
    // 协议必须属于当前分组，避免生成链路静默落到默认分支。
    final protocol = _protocol.text.trim();
    if (!Protocols.isSupported(_group.name, protocol)) {
      _showMessage('协议「$protocol」不支持该分组');
      return;
    }

    // 新建时 API Key 必填。
    if (!_isEdit && _apiKey.text.trim().isEmpty) {
      _showMessage('请填写 API Key');
      return;
    }

    setState(() => _saving = true);
    try {
      final dao = ref.read(providerDaoProvider);
      final keyStore = ref.read(secureKeyStoreProvider);

      final id = _isEdit ? widget.existing!.id : _newId();
      await dao.upsert(
        ProviderConfigsCompanion.insert(
          id: id,
          group: _group.name,
          label: _label.text.trim(),
          baseUrl: _baseUrl.text.trim(),
          protocol: protocol,
          models: Value(ProviderModelCodec.encode(validModels)),
          readme: Value(
            _readme.text.trim().isEmpty ? null : _readme.text.trim(),
          ),
        ),
      );

      // 仅当用户填写了新 Key 时才覆盖；编辑留空则保持原 Key。
      final apiKey = _apiKey.text.trim();
      if (apiKey.isNotEmpty) {
        await keyStore.writeKey(id, apiKey);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showMessage('保存失败：$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.existing!.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除供应商'),
        content: Text('确认删除「${widget.existing!.label}」？API Key 将一并清除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(providerDaoProvider).deleteById(id);
    await ref.read(secureKeyStoreProvider).deleteKey(id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _testConnection() async {
    if (_group != ProviderGroup.llm) {
      _showMessage('连接测试目前仅支持 LLM 供应商');
      return;
    }
    final baseUrl = _baseUrl.text.trim();
    if (baseUrl.isEmpty) {
      _showMessage('请先填写 Base URL');
      return;
    }
    final models = _models.where((m) => m.id.trim().isNotEmpty).toList();
    if (models.isEmpty) {
      _showMessage('请先添加模型');
      return;
    }

    // 编辑时若未填新 Key，则读取已存 Key。
    var apiKey = _apiKey.text.trim();
    if (apiKey.isEmpty && _isEdit) {
      apiKey =
          await ref.read(secureKeyStoreProvider).readKey(widget.existing!.id) ??
          '';
    }
    if (apiKey.isEmpty) {
      _showMessage('请填写 API Key');
      return;
    }

    setState(() => _testing = true);
    try {
      await ref
          .read(llmProviderAdapterProvider)
          .testConnection(
            baseUrl: baseUrl,
            apiKey: apiKey,
            model: models.first.id,
          );
      _showMessage('连接成功');
    } catch (e) {
      _showMessage('连接失败：$e');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  /// 一键获取模型（docs/02 §4.1.1）：拉取 /models 并合并进列表，
  /// 同 id 保留勾选态，新模型默认不勾选。
  Future<void> _fetchModels() async {
    final baseUrl = _baseUrl.text.trim();
    if (baseUrl.isEmpty) {
      _showMessage('请先填写 Base URL');
      return;
    }
    // 编辑时若未填新 Key，则读取已存 Key。
    var apiKey = _apiKey.text.trim();
    if (apiKey.isEmpty && _isEdit) {
      apiKey =
          await ref.read(secureKeyStoreProvider).readKey(widget.existing!.id) ??
          '';
    }
    if (apiKey.isEmpty) {
      _showMessage('请填写 API Key');
      return;
    }

    setState(() => _fetching = true);
    try {
      final fetched = await ModelFetcher().fetch(
        baseUrl: baseUrl,
        apiKey: apiKey,
        protocol: _protocol.text.trim(),
        group: _group,
      );
      if (fetched.isEmpty) {
        _showMessage('未获取到模型');
        return;
      }
      setState(() {
        _models = ModelFetcher.mergeFetched(
          existing: _models,
          fetched: fetched,
        );
      });
      _showMessage('已获取 ${fetched.length} 个模型，请勾选启用');
    } catch (e) {
      _showMessage('获取失败：$e');
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? '编辑供应商' : '添加供应商',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (!_isEdit)
                SegmentedButton<ProviderGroup>(
                  segments: [
                    for (final g in ProviderGroup.values)
                      ButtonSegment(value: g, label: Text(g.label)),
                  ],
                  selected: {_group},
                  onSelectionChanged: (s) => setState(() {
                    _group = s.first;
                    _protocol.text = _defaultProtocol(_group);
                  }),
                ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _label,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '如 DeepSeek',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请填写名称' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _baseUrl,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'https://api.deepseek.com',
                ),
                validator: validateBaseUrl,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _apiKey,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: _isEdit ? '留空则保持不变' : 'sk-...',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _safeProtocol(),
                decoration: const InputDecoration(labelText: '协议'),
                items: [
                  for (final p in _protocolOptions(_group))
                    DropdownMenuItem(value: p, child: Text(p)),
                ],
                onChanged: (v) {
                  if (v != null) _protocol.text = v;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _readme,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '说明（可选）',
                  hintText: '如：768P 仅 0.09 元/秒，前往平台获取密钥',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('模型列表', style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _fetching ? null : _fetchModels,
                    icon: _fetching
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_download_outlined, size: 18),
                    label: const Text('获取模型'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '勾选启用的模型才会出现在生成页；也可手动输入模型 ID。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _models.length; i++)
                _ModelRow(
                  key: ValueKey('model_$i'),
                  model: _models[i],
                  group: _group,
                  onChanged: (m) => setState(() => _models[i] = m),
                  onRemove: _models.length > 1
                      ? () => setState(() => _models.removeAt(i))
                      : null,
                ),
              TextButton.icon(
                onPressed: () => setState(
                  () => _models.add(
                    const ProviderModel(id: '', label: '', enabled: false),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('添加模型'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _testing ? null : _testConnection,
                      child: _testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('连接测试'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_isEdit)
                    IconButton(
                      tooltip: '删除',
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('保存'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelRow extends StatelessWidget {
  const _ModelRow({
    super.key,
    required this.model,
    required this.group,
    required this.onChanged,
    required this.onRemove,
  });

  final ProviderModel model;
  final ProviderGroup group;
  final ValueChanged<ProviderModel> onChanged;
  final VoidCallback? onRemove;

  /// 能力摘要（用于编辑对话框入口副标题）。
  String get _capabilitySummary {
    final parts = <String>[];
    final durations = model.supportedDurations;
    if (durations.isNotEmpty) {
      parts.add('${durations.first}-${durations.last}s');
    }
    final res = model.durationResolutions;
    if (res != null && res.isNotEmpty) {
      parts.add(res.first.resolution.join('/'));
    }
    if (model.maxImageRefs != null) parts.add('参考≤${model.maxImageRefs}');
    if (model.supportsStartFrame) parts.add('首帧');
    return parts.isEmpty ? '未设置能力（点此补全）' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 勾选态：是否启用进生成链路（docs/02 §4.1.2）。
              SizedBox(
                width: 40,
                child: Checkbox(
                  value: model.enabled,
                  onChanged: (v) =>
                      onChanged(model.copyWith(enabled: v ?? false)),
                ),
              ),
              Expanded(
                child: TextFormField(
                  initialValue: model.id,
                  decoration: const InputDecoration(
                    labelText: '模型 ID',
                    hintText: 'deepseek-chat',
                    isDense: true,
                  ),
                  onChanged: (v) => onChanged(model.copyWith(id: v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: model.label,
                  decoration: const InputDecoration(
                    labelText: '显示名',
                    hintText: 'DeepSeek Chat',
                    isDense: true,
                  ),
                  onChanged: (v) => onChanged(model.copyWith(label: v)),
                ),
              ),
              IconButton(
                tooltip: '能力设置',
                onPressed: () async {
                  final updated = await showDialog<ProviderModel>(
                    context: context,
                    builder: (_) =>
                        _ModelCapabilityDialog(model: model, group: group),
                  );
                  if (updated != null) onChanged(updated);
                },
                icon: const Icon(Icons.tune, size: 20),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close),
                tooltip: '删除模型',
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              _capabilitySummary,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// 模型能力编辑对话框（借鉴 Toonflow `MediaModel` 能力字段）。
///
/// 视频：时长/分辨率/支持模式/最大参考图/音频三态；
/// 图片：尺寸/画幅。用逗号分隔文本录入，空表示未知。
class _ModelCapabilityDialog extends StatefulWidget {
  const _ModelCapabilityDialog({required this.model, required this.group});

  final ProviderModel model;
  final ProviderGroup group;

  @override
  State<_ModelCapabilityDialog> createState() => _ModelCapabilityDialogState();
}

class _ModelCapabilityDialogState extends State<_ModelCapabilityDialog> {
  late final TextEditingController _durations;
  late final TextEditingController _resolutions;
  late final TextEditingController _imageSizes;
  late final TextEditingController _imageRatios;
  late final TextEditingController _maxRefs;
  late Set<String> _modes;
  late int _audio; // 0 可选 / 1 强制开 / 2 强制关

  bool get _isVideo => widget.group == ProviderGroup.video;

  @override
  void initState() {
    super.initState();
    final m = widget.model;
    final durations = m.supportedDurations;
    final res = m.durationResolutions;
    _durations = TextEditingController(text: durations.join(','));
    _resolutions = TextEditingController(
      text: res == null
          ? ''
          : (res.expand((e) => e.resolution).toSet().toList()).join(','),
    );
    _imageSizes = TextEditingController(text: m.imageSizes?.join(',') ?? '');
    _imageRatios = TextEditingController(text: m.imageRatios?.join(',') ?? '');
    _maxRefs = TextEditingController(text: m.maxImageRefs?.toString() ?? '');
    _modes = {...?m.videoModes};
    _audio = m.audioRequired ? 1 : (m.audioDisabled ? 2 : 0);
  }

  @override
  void dispose() {
    _durations.dispose();
    _resolutions.dispose();
    _imageSizes.dispose();
    _imageRatios.dispose();
    _maxRefs.dispose();
    super.dispose();
  }

  List<String> _split(String raw) => [
    for (final p in raw.split(RegExp(r'[,，]')))
      if (p.trim().isNotEmpty) p.trim(),
  ];

  void _save() {
    final m = widget.model;
    var updated = m;
    if (_isVideo) {
      final durations = [
        for (final p in _split(_durations.text))
          if (int.tryParse(p) != null) int.parse(p),
      ]..sort();
      final resolutions = _split(_resolutions.text);
      updated = updated.copyWith(
        durationResolutions: durations.isEmpty || resolutions.isEmpty
            ? null
            : [(duration: durations, resolution: resolutions)],
        clearDurationResolutions: durations.isEmpty || resolutions.isEmpty,
        videoModes: _modes.isEmpty ? null : _modes.toList(),
        clearVideoModes: _modes.isEmpty,
        maxImageRefs: int.tryParse(_maxRefs.text.trim()),
        audio: switch (_audio) {
          1 => true,
          2 => false,
          _ => 'optional',
        },
      );
    } else {
      final sizes = _split(_imageSizes.text);
      final ratios = _split(_imageRatios.text);
      updated = updated.copyWith(
        imageSizes: sizes.isEmpty ? null : sizes,
        clearImageSizes: sizes.isEmpty,
        imageRatios: ratios.isEmpty ? null : ratios,
        clearImageRatios: ratios.isEmpty,
      );
    }
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('模型能力'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '留空表示未知，生成页会回退通用词表。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (_isVideo) ...[
              TextField(
                controller: _durations,
                decoration: const InputDecoration(
                  labelText: '支持时长（秒，逗号分隔）',
                  hintText: '4,5,6,...,15',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _resolutions,
                decoration: const InputDecoration(
                  labelText: '支持分辨率（逗号分隔）',
                  hintText: '480p,720p,1080p',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Text('支持模式', style: Theme.of(context).textTheme.bodySmall),
              Wrap(
                spacing: 8,
                children: [
                  for (final entry in const {
                    'text': '文生',
                    'multiImage': '多图参考',
                    'startFrameOptional': '首帧可选',
                  }.entries)
                    FilterChip(
                      label: Text(entry.value),
                      selected: _modes.contains(entry.key),
                      onSelected: (sel) => setState(() {
                        if (sel) {
                          _modes.add(entry.key);
                        } else {
                          _modes.remove(entry.key);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _maxRefs,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '最大参考图数（默认 9）',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Text('音频能力', style: Theme.of(context).textTheme.bodySmall),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('可选')),
                  ButtonSegment(value: 1, label: Text('强制开')),
                  ButtonSegment(value: 2, label: Text('强制关')),
                ],
                selected: {_audio},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _audio = s.first),
              ),
            ] else ...[
              TextField(
                controller: _imageSizes,
                decoration: const InputDecoration(
                  labelText: '支持尺寸（逗号分隔）',
                  hintText: '1K,2K,4K',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _imageRatios,
                decoration: const InputDecoration(
                  labelText: '支持画幅（逗号分隔）',
                  hintText: '16:9,9:16,1:1',
                  isDense: true,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _save, child: const Text('确定')),
      ],
    );
  }
}
