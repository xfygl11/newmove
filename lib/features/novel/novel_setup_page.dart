import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../agent/active_llm.dart';
import '../../core/storage/providers.dart';
import '../../widgets/confirm_sheet.dart';
import 'novel_providers.dart';
import 'novel_setup_catalog.dart';
import 'novel_setup_draft.dart';

/// 创作前基础设置：受众 / 作品类型 / 作品标签 / 章节规划 / 高级设置。
///
/// 全部字段落作品行；章节规划只记录卷数与每卷章节数，不铺开章节行。
/// 高级设置四项可 AI 帮写，结果回填表单由用户确认后再提交。
class NovelSetupPage extends ConsumerStatefulWidget {
  const NovelSetupPage({super.key, required this.projectId});

  final int projectId;

  @override
  ConsumerState<NovelSetupPage> createState() => NovelSetupPageState();
}

class NovelSetupPageState extends ConsumerState<NovelSetupPage> {
  late NovelSetupDraft _draft;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _ideaCtrl;
  late final TextEditingController _synopsisCtrl;
  late final TextEditingController _charactersCtrl;
  late final TextEditingController _abilityCtrl;
  final TextEditingController _customGenreCtrl = TextEditingController();
  final TextEditingController _customPersonaCtrl = TextEditingController();
  final TextEditingController _customBackgroundCtrl = TextEditingController();
  final Map<SetupField, bool> _generating = {};
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    final draft = NovelSetupDraft(audience: NovelSetupCatalog.audiences.first);
    _draft = draft;
    _titleCtrl = TextEditingController(text: draft.title);
    _ideaCtrl = TextEditingController(text: draft.idea);
    _synopsisCtrl = TextEditingController(text: draft.synopsis);
    _charactersCtrl = TextEditingController(text: draft.characters);
    _abilityCtrl = TextEditingController(text: draft.protagonistAbility);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _ideaCtrl.dispose();
    _synopsisCtrl.dispose();
    _charactersCtrl.dispose();
    _abilityCtrl.dispose();
    _customGenreCtrl.dispose();
    _customPersonaCtrl.dispose();
    _customBackgroundCtrl.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _set(NovelSetupDraft draft) => setState(() => _draft = draft);

  TextEditingController _controllerOf(SetupField field) => switch (field) {
    SetupField.title => _titleCtrl,
    SetupField.synopsis => _synopsisCtrl,
    SetupField.characters => _charactersCtrl,
    SetupField.protagonistAbility => _abilityCtrl,
  };

  // ---- 作品类型 ----

  void _toggleWorkGenre(String type) {
    final selected = _draft.workTypes.contains(type);
    final next = List<String>.from(_draft.workTypes)..remove(type);
    if (!selected) next.add(type);
    _set(_draft.copyWith(workTypes: next));
  }

  // ---- 标签（人设 / 背景各上限 5）----

  /// 人设标签增删：ChoiceChip 与自定义输入共用，带 5 个上限校验。
  Future<String?> _addPersona(String tag) => _addTag(
    selected: _draft.personaTags,
    tag: tag,
    onToggle: (next) => _set(_draft.copyWith(personaTags: next)),
  );

  /// 背景标签增删：ChoiceChip 与自定义输入共用，带 5 个上限校验。
  Future<String?> _addBackground(String tag) => _addTag(
    selected: _draft.backgroundTags,
    tag: tag,
    onToggle: (next) => _set(_draft.copyWith(backgroundTags: next)),
  );

  /// 标签增删统一入口：空串 / 重复 / 超出上限都返回可见提示。
  Future<String?> _addTag({
    required List<String> selected,
    required String tag,
    required void Function(List<String>) onToggle,
  }) async {
    if (tag.trim().isEmpty) return '标签不能为空';
    final isNew = !selected.contains(tag);
    if (isNew &&
        selected.length >= NovelSetupCatalog.maxTagsPerGroup) {
      return '标签最多 ${NovelSetupCatalog.maxTagsPerGroup} 个，请先移除一个';
    }
    final next = List<String>.from(selected)
      ..remove(tag);
    if (isNew) next.add(tag);
    onToggle(next);
    return null;
  }

  // ---- AI 帮写（只回填表单，不落库）----

  Future<void> _generateField(SetupField field) async {
    if (_generating[field] == true) return;
    final llm = await ref.read(activeLlmProvider.future);
    if (!mounted || llm == null) {
      _toast('请先在设置里配置 LLM 供应商');
      return;
    }
    final brief = _draft.briefText(omit: field);
    if (!await ConfirmSheet.confirm(
      context,
      objectName: field.label,
      quantity: '1 个字段',
      promptPreview: brief.isEmpty
          ? '（尚未填写其它基础设置，AI 将仅按字段类型自由发挥）'
          : brief,
      params: [
        '供应商：${llm.provider.label}',
        '模型：${llm.modelId}',
        '结果只回填输入框，需你确认后才算数',
      ],
      title: 'AI 帮写${field.label}',
      gate: '创作前设置（不写库，仅回填表单）',
    )) {
      return;
    }
    setState(() => _generating[field] = true);
    try {
      final text = await ref
          .read(novelServiceProvider)
          .generateSetupField(field: field, brief: brief, llm: llm);
      if (!mounted) return;
      _controllerOf(field).text = text.trim();
      _set(_draft.fillField(field, text));
      _toast('${field.label}已生成，请检查后再提交');
    } catch (e) {
      _toast('生成失败：$e');
    } finally {
      if (mounted) {
        setState(() => _generating.remove(field));
      }
    }
  }

  // ---- 提交 ----

  Future<void> _create() async {
    if (_creating) return;
    _draft = _draft.copyWith(
      title: _titleCtrl.text,
      idea: _ideaCtrl.text,
      synopsis: _synopsisCtrl.text,
      characters: _charactersCtrl.text,
      protagonistAbility: _abilityCtrl.text,
    );
    if (!_draft.isComplete) {
      _toast('请先选择核心受众与至少一个作品类型');
      return;
    }
    final llm = await ref.read(activeLlmProvider.future);
    if (llm == null) {
      _toast('请先在设置里配置 LLM 供应商');
      return;
    }
    final idea = _draft.idea.trim().isEmpty
        ? _draft.briefText()
        : '${_draft.idea.trim()}\n${_draft.briefText()}';
    if (!mounted) return;
    if (!await ConfirmSheet.confirm(
      context,
      objectName: _draft.title.trim().isEmpty ? '未命名作品' : _draft.title.trim(),
      quantity:
          '基础设置 + AI 生成世界观 / 角色矩阵 / 大纲'
          '${_draft.totalChapters > 0 ? '（规划 ${_draft.totalChapters} 章）' : ''}',
      promptPreview: '【创意】$idea\n请按规则产出设定 JSON。',
      params: [
        '供应商：${llm.provider.label}',
        '模型：${llm.modelId}',
        '作品形式：${_draft.workType}',
        '核心受众：${_draft.audience}',
        '作品类型：${_draft.workTypes.join(' / ')}',
        if (_draft.personaTags.isNotEmpty)
          '人设标签：${_draft.personaTags.join('、')}',
        if (_draft.backgroundTags.isNotEmpty)
          '背景标签：${_draft.backgroundTags.join('、')}',
        '角色信息将写入角色矩阵 TruthFile，可在角色管理页继续调整',
      ],
      title: '开始创作',
      gate: '作品创建（生成世界观 / 角色 / 大纲后进入书架）',
    )) {
      return;
    }
    setState(() => _creating = true);
    try {
      final dao = ref.read(novelDaoProvider);
      final bookId = await dao.insertBook(
        _draft.toCompanion(projectId: widget.projectId),
      );
      await ref
          .read(novelServiceProvider)
          .generateSetup(
            bookId: bookId,
            idea: idea,
            genre: _draft.workTypes.join(' / '),
            llm: llm,
            workType: _draft.workType,
            brief: _draft.briefText(),
          );
      if (!mounted) return;
      context.go('/novel/${widget.projectId}');
    } catch (e) {
      _toast('创建失败：$e');
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('基础设置')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section('基础设置'),
                    _workForm(),
                    _coreAudience(),
                    _workGenre(),
                    _workTags(),
                    _section('章节规划'),
                    _chapterPlan(),
                    _section('高级设置'),
                    _advancedFields(),
                  ],
                ),
              ),
            ),
            _submitBar(),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 22, 0, 10),
    child: Row(
      children: [
        Container(width: 4, height: 16, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );

  // ---- 基础设置 ----

  Widget _workForm() => _Card(
    label: '作品形式',
    required: true,
    hint: '决定结构与篇幅的组织方式，题材类型在下面单独选择',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final form in NovelSetupCatalog.workForms)
          ChoiceChip(
            label: Text(form),
            selected: _draft.workType == form,
            onSelected: (_) => _set(_draft.copyWith(workType: form)),
          ),
      ],
    ),
  );

  Widget _coreAudience() => _Card(
    label: '核心受众',
    required: true,
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in NovelSetupCatalog.audiences)
          ChoiceChip(
            label: Text(a),
            selected: _draft.audience == a,
            onSelected: (_) => _set(_draft.copyWith(audience: a)),
          ),
      ],
    ),
  );

  Widget _workGenre() => _Card(
    label: '作品类型',
    required: true,
    hint: '可多选，如「东方玄幻 / 都市重生」',
    child: Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in _draft.workTypes)
              ActionChip(
                label: Text(type),
                avatar: const Icon(Icons.close, size: 14),
                onPressed: () => _toggleWorkGenre(type),
              ),
            for (final group in NovelSetupCatalog.workGenreGroups.entries)
              ...group.value.map(
                (type) => ChoiceChip(
                  label: Text(type),
                  selected: _draft.workTypes.contains(type),
                  onSelected: (_) => _toggleWorkGenre(type),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _customAddField(
          controller: _customGenreCtrl,
          hint: '没有找到合适的？输入自定义类型',
          onAdd: (text) async {
            if (text.trim().isEmpty) return '类型不能为空';
            if (_draft.workTypes.contains(text)) return '该类型已添加';
            _toggleWorkGenre(text.trim());
            return null;
          },
        ),
      ],
    ),
  );

  Widget _workTags() => _Card(
    label: '作品标签',
    required: true,
    child: Column(
      children: [
        _tagGroup(
          label: '人设',
          catalog: NovelSetupCatalog.personaTags,
          selected: _draft.personaTags,
          controller: _customPersonaCtrl,
          onToggle: _addPersona,
        ),
        const SizedBox(height: 12),
        _tagGroup(
          label: '背景',
          catalog: NovelSetupCatalog.backgroundTags,
          selected: _draft.backgroundTags,
          controller: _customBackgroundCtrl,
          onToggle: _addBackground,
        ),
      ],
    ),
  );

  // ---- 章节规划 ----

  /// 卷数与每卷章节数按作品形式给出读法，避免「短篇 10 卷」这种误解。
  String _chapterPlanNote(String workType) {
    const note = '章节规划仅记录作品体感规模，不会生成章节占位行。';
    return switch (workType) {
      '短篇' => '短篇通常 1 卷成型，这里只表示篇幅规模。$note',
      '剧本' => '剧本按分集组读卷数、按场次数读每卷章节。$note',
      '影游' => '影游按章节组读卷数、按关卡数读每卷章节。$note',
      _ => note,
    };
  }

  Widget _chapterPlan() => _Card(
    label: '章节规划',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _countField(
          label: '总卷数',
          unit: '卷',
          min: NovelSetupCatalog.minVolumes,
          max: NovelSetupCatalog.maxVolumes,
          value: _draft.volumeCount,
          onChanged: (v) => _set(_draft.copyWith(volumeCount: v)),
        ),
        const Divider(height: 1),
        _countField(
          label: '每卷章节',
          unit: '章',
          min: NovelSetupCatalog.minChaptersPerVolume,
          max: NovelSetupCatalog.maxChaptersPerVolume,
          value: _draft.chaptersPerVolume,
          onChanged: (v) => _set(_draft.copyWith(chaptersPerVolume: v)),
        ),
        const Divider(height: 1),
        Text(
          '预计总章节数：${_draft.totalChapters}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          _chapterPlanNote(_draft.workType),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Colors.grey),
        ),
      ],
    ),
  );

  // ---- 高级设置 ----

  Widget _advancedFields() => _Card(
    label: '作品信息',
    hint: '全部可选，也可点右侧「AI 帮写」',
    child: Column(
      children: [
        _field(
          label: '作品名称',
          controller: _titleCtrl,
          field: SetupField.title,
          hint: '适配故事的书名',
          lines: 1,
          onChanged: (v) => _set(_draft.copyWith(title: v)),
        ),
        const Divider(height: 1),
        _field(
          label: '作品简介',
          controller: _synopsisCtrl,
          field: SetupField.synopsis,
          hint: '简要介绍作品的故事背景和内容',
          lines: 3,
          onChanged: (v) => _set(_draft.copyWith(synopsis: v)),
        ),
        const Divider(height: 1),
        _field(
          label: '角色信息',
          controller: _charactersCtrl,
          field: SetupField.characters,
          hint: '主角、配角等角色信息',
          lines: 4,
          onChanged: (v) => _set(_draft.copyWith(characters: v)),
        ),
        const Divider(height: 1),
        _field(
          label: '主角能力',
          controller: _abilityCtrl,
          field: SetupField.protagonistAbility,
          hint: '主角的特殊能力或金手指设定',
          lines: 2,
          onChanged: (v) => _set(_draft.copyWith(protagonistAbility: v)),
        ),
      ],
    ),
  );

  // ---- 底部提交 ----

  Widget _submitBar() {
    final theme = Theme.of(context);
    final complete = _draft.isComplete;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ideaCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: '写一句话故事核心，或直接点 AI 帮写逐项生成',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (v) => _set(_draft.copyWith(idea: v)),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: FilledButton(
                onPressed: _creating || !complete ? null : _create,
                child: _creating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('开始创作'),
              ),
            ),
            if (!complete)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '还需选择核心受众与作品类型',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---- 私有小组件 ----

  Widget _customAddField({
    required TextEditingController controller,
    required String hint,
    required Future<String?> Function(String text) onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onSubmitted: (text) async {
              final msg = await onAdd(text);
              controller.clear();
              if (msg != null) _toast(msg);
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () async {
            final msg = await onAdd(controller.text);
            controller.clear();
            if (msg != null) _toast(msg);
          },
        ),
      ],
    );
  }

  Widget _tagGroup({
    required String label,
    required List<String> catalog,
    required List<String> selected,
    required TextEditingController controller,
    required Future<String?> Function(String tag) onToggle,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label（可多选，最多 ${NovelSetupCatalog.maxTagsPerGroup} 个）'
          ' ${selected.length}/${NovelSetupCatalog.maxTagsPerGroup}',
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in catalog)
              ChoiceChip(
                label: Text(tag),
                selected: selected.contains(tag),
                onSelected: (_) => onToggle(tag),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _customAddField(
          controller: controller,
          hint: '自定义$label标签',
          onAdd: onToggle,
        ),
      ],
    );
  }

  Widget _countField({
    required String label,
    required String unit,
    required int min,
    required int max,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label ($min-$max$unit)',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            child: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          TextButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            child: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required SetupField field,
    required String hint,
    required int lines,
    required ValueChanged<String> onChanged,
  }) {
    final theme = Theme.of(context);
    final generating = _generating[field] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.labelMedium)),
              TextButton.icon(
                onPressed: generating ? null : () => _generateField(field),
                icon: generating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 16),
                label: Text(generating ? '生成中' : 'AI 帮写'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(64, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          TextField(
            controller: controller,
            maxLines: lines,
            minLines: 1,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// 分组卡片：可选的必填标记与说明。
class _Card extends StatelessWidget {
  const _Card({
    required this.label,
    required this.child,
    this.required = false,
    this.hint = '',
  });

  final String label;
  final Widget child;
  final bool required;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, style: theme.textTheme.titleMedium),
                ),
                if (required)
                  Text(
                    '*',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
            if (hint.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
