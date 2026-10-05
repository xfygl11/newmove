import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/json_values.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import '../../data/daos/generation_attempt_dao.dart';
import '../../widgets/status_badge.dart';
import '../project/project_providers.dart';

/// 生成尝试台账（M17 T19.4）。
///
/// 只读展示 `GenerationAttempts`：当时用的什么提示词、什么参数、第几次尝试、
/// 失败原因。提示词 / 参数 / 引用 / 授权指纹是当次执行的证据，
/// 任何界面都不得回写（见 docs/02 §6.13.4）。
final attemptLogProvider = FutureProvider<List<GenerationAttempt>>(
  (ref) => ref.read(generationAttemptDaoProvider).list(),
);

/// 对象类型 → 中文标签。
const Map<String, String> attemptSubjectLabels = {
  AttemptSubjects.novelPlan: '小说规划',
  AttemptSubjects.novelWrite: '写章节',
  AttemptSubjects.novelReview: '章节审校',
  AttemptSubjects.novelSettle: '章节定稿',
  AttemptSubjects.scriptAdapt: '剧本改编',
  AttemptSubjects.skeletonExtract: '骨架提取',
  AttemptSubjects.shotDirection: '分镜导演',
  AttemptSubjects.shotImage: '分镜图',
  AttemptSubjects.shotVideo: '视频',
  AttemptSubjects.assetExtract: '资产提取',
  AttemptSubjects.assetImage: '资产图',
  AttemptSubjects.validate: '质量门校验',
};

/// 台账状态筛选项；空串表示全部。
const List<String> attemptFilters = <String>[
  '',
  AttemptStatuses.succeeded,
  AttemptStatuses.failed,
  AttemptStatuses.running,
  AttemptStatuses.pending,
  AttemptStatuses.cancelled,
];

class AttemptLogPage extends ConsumerStatefulWidget {
  const AttemptLogPage({super.key});

  @override
  ConsumerState<AttemptLogPage> createState() => _AttemptLogPageState();
}

class _AttemptLogPageState extends ConsumerState<AttemptLogPage> {
  String _status = '';
  int? _projectId;

  @override
  Widget build(BuildContext context) {
    final attempts = ref.watch(attemptLogProvider);
    final projects = ref.read(projectListProvider).value ?? const <Project>[];

    final filtered = attempts.maybeWhen(
      data: (all) => all
          .where(
            (a) =>
                (_status.isEmpty || a.status == _status) &&
                (_projectId == null || a.projectId == _projectId),
          )
          .toList(),
      orElse: () => const <GenerationAttempt>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('生成台账'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: attempts.isLoading ? null : _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              children: [
                for (final s in attemptFilters)
                  ChoiceChip(
                    label: Text(_filterLabel(s)),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                  ),
              ],
            ),
          ),
          if (projects.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<int?>(
                initialValue: _projectId,
                isExpanded: true,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  labelText: '按项目筛选',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('全部项目'),
                  ),
                  for (final p in projects)
                    DropdownMenuItem<int?>(value: p.id, child: Text(p.name)),
                ],
                onChanged: (v) => setState(() => _projectId = v),
              ),
            ),
          Expanded(child: _buildList(attempts, filtered)),
        ],
      ),
    );
  }

  Widget _buildList(
    AsyncValue<List<GenerationAttempt>> attempts,
    List<GenerationAttempt> filtered,
  ) {
    if (attempts.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (filtered.isEmpty) {
      return Center(
        child: Text(attempts.hasError ? '加载失败：${attempts.error}' : '暂无生成记录'),
      );
    }
    final names = _projectNames();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _AttemptCard(
        attempt: filtered[index],
        projectName: names[filtered[index].projectId] ?? '',
      ),
    );
  }

  /// 项目 id → 名称，列表页只算一次。
  Map<int, String> _projectNames() {
    final list = ref.read(projectListProvider).value ?? const <Project>[];
    return {for (final p in list) p.id: p.name};
  }

  void _reload() => ref.invalidate(attemptLogProvider);
}

/// 台账状态过滤值 → 展示文案。
String _filterLabel(String status) => switch (status) {
  '' => '全部',
  AttemptStatuses.succeeded => '成功',
  AttemptStatuses.failed => '失败',
  AttemptStatuses.running => '进行中',
  AttemptStatuses.pending => '待执行',
  AttemptStatuses.cancelled => '已取消',
  _ => status,
};

class _AttemptCard extends StatelessWidget {
  const _AttemptCard({required this.attempt, required this.projectName});

  final GenerationAttempt attempt;
  final String projectName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kind =
        attemptSubjectLabels[attempt.subjectType] ?? attempt.subjectType;
    final name = attempt.subjectLabel.isNotEmpty
        ? attempt.subjectLabel
        : (attempt.subjectId != null ? '#${attempt.subjectId}' : '（未命名）');

    return Card(
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$kind · $name', style: theme.textTheme.titleSmall),
                  Text(_metaLine(), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            StatusBadge(status: attempt.status),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ?_errorSection(theme),
                _section('提示词', attempt.prompt, theme),
                _section('参数', _prettyJson(attempt.params), theme),
                if (attempt.refs.isNotEmpty && attempt.refs != '[]')
                  _section('引用', _prettyJson(attempt.refs), theme),
                if (attempt.before.isNotEmpty && attempt.before != '{}')
                  _section('执行前状态', _prettyJson(attempt.before), theme),
                _section('结果', _resultText(), theme),
                const SizedBox(height: 4),
                Text(_timeText(), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _metaLine() {
    final parts = <String>[
      '第 ${attempt.attemptNo} 次',
      _filterLabel(attempt.status),
      '授权 ${attempt.grantLimit} 次',
    ];
    if (projectName.isNotEmpty) parts.insert(1, projectName);
    return parts.join(' · ');
  }

  Widget? _errorSection(ThemeData theme) {
    final msg = attempt.errorMessage;
    if (msg == null || msg.isEmpty) return null;
    return _section('失败原因', msg, theme, color: Colors.red.shade400);
  }

  String _resultText() {
    final path = attempt.resultPath;
    if (path == null || path.isEmpty) {
      return attempt.status == AttemptStatuses.succeeded ? '（未记录路径）' : '—';
    }
    return File(path).existsSync() ? path : '产物文件已被删除：$path';
  }

  String _timeText() {
    final t = attempt.createdAt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  /// 把落库的 JSON 字符串还原成逐行可读文本；不是 JSON 时原文展示。
  String _prettyJson(String raw) {
    if (raw.isEmpty) return '';
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return raw;
    }
    if (decoded is List) {
      return decoded.isEmpty
          ? ''
          : decoded.map((e) => '· $_value(e)').join('\n');
    }
    final map = jsonMap(decoded);
    if (map.isEmpty) return raw;
    return map.entries.map((e) => '${e.key}: ${_value(e.value)}').join('\n');
  }

  static String _value(Object? v) => v is String ? v : jsonEncode(v);

  Widget _section(String title, String body, ThemeData theme, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          SelectableText(
            body.isEmpty ? '—' : body,
            style: color == null ? null : TextStyle(color: color),
          ),
        ],
      ),
    );
  }
}
