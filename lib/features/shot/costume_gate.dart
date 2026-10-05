/// 镜头级服装覆盖的本地校验门（M19 T21.13）。
///
/// 纯函数、不写库、只提示不阻塞。校验码（新增前先登记 AGENTS.md）：
///
/// - `costume_unknown`（warn）覆盖的套名不在该资产 `costumeSets` 清单里——
///   模型自创的套名会让分镜图画出资产图里没有的第四套衣服。
/// - `costume_orphan`（warn）覆盖的角色不在本镜头参考绑定里——
///   为不出镜的角色指定服装，条目无效且提示词里白写一行。
/// - `costume_duplicate`（warn）同一镜头同一角色给了多套服装——
///   无法判定到底穿哪套，分镜图与视频会各自挑一套。
library;

import '../../core/gate_issue.dart';
import '../../data/app_database.dart';
import '../asset/asset_models.dart';
import 'shot_models.dart';

/// 镜头级服装覆盖门。
class CostumeGate {
  CostumeGate._();

  /// 校验单镜头的服装覆盖。
  ///
  /// [assetById] 是 `assetId → Asset` 映射，用于把 [refs] 解析出
  /// 本镜头出镜的角色及其 `costumeSets`。
  static List<GateIssue> validate(
    Shot shot,
    List<AssetRef> refs,
    Map<int, Asset> assetById,
  ) {
    final overrides = ShotCostumeOverride.decode(shot.costumeOverrides);
    if (overrides.isEmpty) return const [];

    // 本镜头出镜角色的套名清单；不在 refs 里的角色视为不出镜。
    final setsByStableId = <String, Set<String>>{};
    final nameByStableId = <String, String>{};
    for (final ref in refs) {
      final asset = assetById[ref.assetId];
      if (asset == null) continue;
      nameByStableId[asset.stableId] = asset.name;
      setsByStableId[asset.stableId] = asset.costumeNames.toSet();
    }

    final issues = <GateIssue>[];
    final seen = <String>{};
    for (final override in overrides) {
      final assetName = nameByStableId[override.stableId] ?? '未知角色';
      final locator = '${shot.globalSeq} · $assetName';

      if (!setsByStableId.containsKey(override.stableId)) {
        issues.add(
          GateIssue(
            code: 'costume_orphan',
            severity: GateSeverity.warn,
            locator: locator,
            message: '覆盖的角色不在本镜头参考绑定里，条目无效',
          ),
        );
        continue;
      }

      if (seen.contains(override.stableId)) {
        issues.add(
          GateIssue(
            code: 'costume_duplicate',
            severity: GateSeverity.warn,
            locator: locator,
            message: '同一镜头同一角色给了多套服装，无法判定穿哪套',
          ),
        );
        continue;
      }
      seen.add(override.stableId);

      final names = setsByStableId[override.stableId]!;
      if (!names.contains(override.name)) {
        final known = names.isEmpty ? '无' : names.join(' / ');
        issues.add(
          GateIssue(
            code: 'costume_unknown',
            severity: GateSeverity.warn,
            locator: locator,
            message: '服装套「${override.name}」不在该资产清单里（可用：$known）',
          ),
        );
      }
    }
    return issues;
  }
}
