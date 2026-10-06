import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/gate_codes.dart';
import '../../core/gate_issue.dart';
import '../../core/storage/providers.dart';
import '../../data/app_database.dart';

/// 质量门命中日志报表（M24 T25.6）。
///
/// 只读展示 `GateLogs`：哪条门响过几次、哪条门从没过。
/// 「从没响」不等于「没问题」——通过的运行不记录，所以「从未命中」同时包含
/// 「从没跑过」与「跑了但一直通过」，对提示词调优是同一条信息。
final gateLogsProvider = FutureProvider<List<GateLog>>(
  (ref) => ref.read(gateLogDaoProvider).all(),
);

/// 门码命中次数，按次数降序；报表页「最常响」榜单的数据源。
final gateCountsProvider = FutureProvider<Map<String, int>>(
  (ref) => ref.read(gateLogDaoProvider).hitsByGate(),
);

/// 门码 → 中文短名（仅 UI 展示；机器码与全集以 [GateCodes] 为准）。
const Map<String, String> gateCodeLabels = {
  GateCodes.overLimit: '单段超时长上限',
  GateCodes.underLimit: '单段短于下界',
  GateCodes.dialogueOverflow: '对白溢出段时长',
  GateCodes.totalMismatch: '总时长偏差超限',
  GateCodes.tooFewSegments: '段落数量偏少',
  GateCodes.batchTooLarge: '单批段落过多',
  GateCodes.lineTooLong: '单句台词过长',
  GateCodes.totalOverBudget: '总时长超预算',
  GateCodes.totalUnderBudget: '总时长短于预算',
  GateCodes.hasAction: '场次缺动作描述',
  GateCodes.actionProse: '动作字段混入台词',
  GateCodes.speakerUnknown: '说话人不在出场名单',
  GateCodes.crowdCheck: '同框角色过多',
  GateCodes.segmentSeq: '段号不连续',
  GateCodes.frameEmpty: '分镜图提示词为空',
  GateCodes.phraseMissing: '景别运镜词未落进提示词',
  GateCodes.videoNoNames: '视频提示词直呼角色名',
  GateCodes.costumeUnknown: '服装套名未在资产清单',
  GateCodes.costumeOrphan: '服装覆盖的角色未出镜',
  GateCodes.costumeDuplicate: '同一角色多套服装',
  GateCodes.promptSimilar: '角色外观锚点雷同',
  GateCodes.anchorCount: '外观锚点数量不足',
  GateCodes.lightingMissing: '提示词缺光照描述',
  GateCodes.propStates: '道具缺状态描述',
  GateCodes.propScale: '道具缺尺度描述',
  GateCodes.propWhiteBg: '道具缺白底表述',
  GateCodes.sceneNotEmpty: '场景提示词无空景标记',
  GateCodes.propHasHand: '道具提示词无手部排除',
  GateCodes.sceneNamedCharacter: '场景提示词出现角色名',
  GateCodes.styleConflict: '同批资产跨画风族',
  GateCodes.coverage: '骨架认领覆盖不全',
  GateCodes.tierMissing: '角色未标分档',
  GateCodes.tierCap: '分档人数超上限',
  GateCodes.evidenceUnverified: '角色引文未在正文命中',
  GateCodes.relationSelf: '角色关系指向自己',
  GateCodes.relationOrphan: '角色关系引用未知角色',
};

/// 检查项类型 → 中文短名。
const Map<String, String> gateSubjectLabels = {
  GateSubjects.characters: '角色画像',
  GateSubjects.assets: '资产提示词',
  GateSubjects.shots: '分镜镜头',
  GateSubjects.script: '剧本场次',
  GateSubjects.skeleton: '骨架认领',
};

class GateLogPage extends ConsumerWidget {
  const GateLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(gateLogsProvider);
    final countsAsync = ref.watch(gateCountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('质量门报表'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(gateLogsProvider);
              ref.invalidate(gateCountsProvider);
            },
          ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (logs) {
          final hits = countsAsync.value ?? const <String, int>{};
          final unseen = GateCodes.all
              .where((code) => !hits.containsKey(code))
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _RankSection(
                title: '最常响',
                subtitle: '命中次数最多的门，先改提示词还是先改内容',
                rows: hits.entries
                    .map(
                      (entry) => _RankRow(
                        code: entry.key,
                        count: entry.value,
                      ),
                    )
                    .toList(),
                empty: '还没有命中记录——点过「记一次」后这里才有内容。',
              ),
              _RankSection(
                title: '从未命中',
                subtitle: '从没跑过，或者跑了但一直通过',
                rows: unseen
                    .map((code) => _RankRow(code: code, count: 0))
                    .toList(),
                empty: '所有门码都至少命中过一次。',
              ),
              const _DividerLabel(label: '命中记录'),
              if (logs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '还没有命中记录。在各处体检面板点「记一次」写入。',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                for (final log in logs) _LogTile(log: log),
            ],
          );
        },
      ),
    );
  }
}

class _RankSection extends StatelessWidget {
  const _RankSection({
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.empty,
  });

  final String title;
  final String subtitle;
  final List<_RankRow> rows;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 8),
                child: Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (rows.isEmpty)
                Text(
                  empty,
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                for (final row in rows) row,
            ],
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.code, required this.count});

  final String code;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gateCodeLabels[code] ?? code,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  code,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text('$count 次'),
        ],
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final GateLog log;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            log.ok == 1 ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            size: 18,
            color: log.ok == 1
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${gateCodeLabels[log.gateId] ?? log.gateId}'
                  '${log.subjectLabel.isEmpty ? '' : ' · ${log.subjectLabel}'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${gateSubjectLabels[log.subjectType] ?? log.subjectType}'
                  '  ·  ${log.gateId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (log.detail.isNotEmpty)
                  Text(
                    log.detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                Text(
                  _time(log.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _time(DateTime value) {
    String p(int value) => value.toString().padLeft(2, '0');
    return '${value.year}-${p(value.month)}-${p(value.day)} '
        '${p(value.hour)}:${p(value.minute)}';
  }
}
