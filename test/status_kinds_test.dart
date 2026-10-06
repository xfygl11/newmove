import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/status_constants.dart';
import 'package:newmove/data/daos/generation_attempt_dao.dart';
import 'package:newmove/features/asset/asset_models.dart';
import 'package:newmove/features/novel/truth_file_store.dart';
import 'package:newmove/features/shot/shot_models.dart';
import 'package:newmove/widgets/status_badge.dart';

void main() {
  // 走 StatusBadge 渲染的状态字面量必须全部登记在 StatusKinds 里。
  // 漏登记不会报错（回落 fallback），只会让「已完成」和「排队中」外观一致
  // ——M18 审计时任务中心 8 个状态只有 2 个被识别，就是这个机制掩盖的。
  final badgeStatuses = <String>{
    for (final s in ShotStatuses.all) s,
    for (final s in [
      AssetStatuses.pending,
      AssetStatuses.generating,
      AssetStatuses.reviewing,
      AssetStatuses.accepted,
      AssetStatuses.discarded,
    ])
      s,
    for (final s in [
      VideoTaskStatuses.queued,
      VideoTaskStatuses.generating,
      VideoTaskStatuses.succeeded,
      VideoTaskStatuses.failed,
      VideoTaskStatuses.cancelled,
    ])
      s,
    for (final s in [
      AttemptStatuses.pending,
      AttemptStatuses.running,
      AttemptStatuses.succeeded,
      AttemptStatuses.failed,
      AttemptStatuses.cancelled,
    ])
      s,
  };

  test('StatusKinds 覆盖全部走 StatusBadge 的状态字面量（T20.22）', () {
    final missing =
        badgeStatuses.where((s) => !StatusKinds.contains(s)).toList()..sort();
    expect(missing, isEmpty, reason: '未登记即回落灰色默认样式：$missing');
  });

  // 章节与伏笔状态不经 StatusBadge，各有自己的颜色映射，
  // 但仍要求登记在单一状态表里，避免又长出一套字面量分叉。
  test('StatusKinds 覆盖章节与伏笔的展示状态', () {
    final chapterStatuses = ChapterStatuses.all;
    final hookLabels = [
      HookStates.label('open'),
      HookStates.label('progressing'),
      HookStates.label('deferred'),
      HookStates.label('resolved'),
      HookStates.label('superseded'),
    ];
    final missing = [...chapterStatuses, ...hookLabels]
        .where((s) => !StatusKinds.contains(s))
        .toList()
      ..sort();
    expect(missing, isEmpty, reason: '章节/伏笔状态分叉：$missing');
  });

  test('StatusKinds 无重复键、无空白键', () {
    final keys = StatusKinds.all.toList();
    final blank = keys.where((s) => s.trim().isEmpty).toList();
    expect(blank, isEmpty, reason: '空白状态键会静默吞掉真实状态');
    expect(keys.length, keys.toSet().length);
  });

  test('StatusKinds.of 对未登记状态回落 fallback 而不抛错', () {
    expect(StatusKinds.of('不存在'), same(StatusKinds.fallback));
    expect(StatusKinds.of(''), same(StatusKinds.fallback));
  });

  test('VideoTaskStatuses 的 inProgress 与 terminal 覆盖全部状态', () {
    final all = {
      VideoTaskStatuses.queued,
      VideoTaskStatuses.generating,
      VideoTaskStatuses.succeeded,
      VideoTaskStatuses.failed,
      VideoTaskStatuses.cancelled,
    };
    final covered = VideoTaskStatuses.inProgress.toSet()
      ..addAll(VideoTaskStatuses.terminal);
    expect(covered, all, reason: '未归类的状态既不会被轮询也不会被判定终态');
    expect(
      VideoTaskStatuses.inProgress.toSet()
          .intersection(VideoTaskStatuses.terminal.toSet()),
      isEmpty,
      reason: '同一状态既判进行中又判终态会让轮询逻辑自相矛盾',
    );
  });
}
