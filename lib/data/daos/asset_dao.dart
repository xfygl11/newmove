import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'asset_dao.g.dart';

/// 资产（角色 / 场景 / 道具）数据访问对象。
@DriftAccessor(tables: [Assets])
class AssetDao extends DatabaseAccessor<AppDatabase> with _$AssetDaoMixin {
  AssetDao(super.db);

  Future<List<Asset>> listByScript(int scriptId) {
    return (select(assets)
          ..where((t) => t.scriptId.equals(scriptId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.type),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  /// 回收卡死的资产状态，返回受影响的资产 id。
  ///
  /// 状态词表由调用方传入——DAO 只存字符串，不绑定业务语义。
  /// 资产出图是同步调用（`AssetService.generate` 内 `await` 到底），
  /// `generating` 只在那一次调用的生命周期内存在；库里出现该状态即意味着
  /// 进程在生成中途被杀，供应商侧可能早已结束而本地状态永不落回。
  Future<List<int>> flipStatus({
    required String fromStatus,
    required String toStatus,
  }) async {
    final query = select(assets);
    query.where((t) => t.status.equals(fromStatus));
    final ids = [for (final row in await query.get()) row.id];
    if (ids.isEmpty) return ids;
    await (update(assets)..where((t) => t.status.equals(fromStatus))).write(
      AssetsCompanion(status: Value(toStatus)),
    );
    return ids;
  }

  Stream<List<Asset>> watchByScript(int scriptId) {
    return (select(assets)
          ..where((t) => t.scriptId.equals(scriptId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.type),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .watch();
  }

  Future<List<Asset>> listByScriptAndType(int scriptId, String type) {
    return (select(assets)
          ..where((t) => t.scriptId.equals(scriptId) & t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Future<List<Asset>> listByStableId(int scriptId, String stableId) {
    return (select(assets)..where(
          (t) => t.scriptId.equals(scriptId) & t.stableId.equals(stableId),
        ))
        .get();
  }

  Future<Asset?> find(int id) {
    return (select(assets)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<Asset?> watch(int id) {
    return (select(assets)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// 列出挂在 [parentId] 下的全部变体。
  Future<List<Asset>> listVariants(int parentId) {
    return (select(assets)..where((t) => t.variantOf.equals(parentId))).get();
  }

  /// 插入资产。
  ///
  /// [entry.variantOf] 指向的父资产必须存在且属于同一剧本，否则抛 [ArgumentError]。
  /// `variantOf` 在表定义上不带 `references`（加外键需重建 assets 表，风险高），
  /// 这里在 DAO 层做同等校验，避免出现「变体父资产 #<不存在的 id>」的孤儿引用。
  Future<int> insert(AssetsCompanion entry) async {
    final variantOf = entry.variantOf.present ? entry.variantOf.value : null;
    if (variantOf != null) {
      final parent = await find(variantOf);
      if (parent == null) {
        throw ArgumentError('变体父资产不存在：#$variantOf');
      }
      if (parent.scriptId != entry.scriptId.value) {
        throw ArgumentError(
          '变体父资产 #$variantOf 属于剧本 ${parent.scriptId}，与当前剧本 ${entry.scriptId.value} 不一致',
        );
      }
    }
    return into(assets).insert(entry);
  }

  Future<bool> updateRow(Asset row) {
    return update(assets).replace(row);
  }

  Future<int> updateById(int id, AssetsCompanion entry) async {
    if (entry.variantOf.present && entry.variantOf.value != null) {
      final parentId = entry.variantOf.value!;
      if (parentId != id) {
        final parent = await find(parentId);
        if (parent == null) throw ArgumentError('变体父资产不存在：#$parentId');
        final self = await find(id);
        if (self != null && parent.scriptId != self.scriptId) {
          throw ArgumentError('变体父资产 #$parentId 与当前资产不属于同一剧本');
        }
      }
    }
    return (update(assets)..where((t) => t.id.equals(id))).write(entry);
  }

  /// 删除资产：先把挂在它下面的变体解绑（置空 variantOf），避免孤儿引用。
  Future<int> deleteById(int id) async {
    await attachedDatabase.transaction(() async {
      await (update(assets)..where((t) => t.variantOf.equals(id))).write(
        const AssetsCompanion(variantOf: Value(null)),
      );
    });
    return (delete(assets)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteByScript(int scriptId) {
    return (delete(assets)..where((t) => t.scriptId.equals(scriptId))).go();
  }

  /// 上游剧本场次变更后标记本剧本全部资产失效（M19 T21.14）。
  /// 只动未失效的行，重复调用幂等。
  Future<int> markStaleByScript(int scriptId) {
    return (update(assets)
          ..where((t) => t.scriptId.equals(scriptId) & t.isStale.equals(0)))
        .write(const AssetsCompanion(isStale: Value(1)));
  }

  /// 本资产重新出图后清除失效标记。
  Future<int> clearStaleById(int id) {
    return (update(assets)
          ..where((t) => t.id.equals(id) & t.isStale.equals(1)))
        .write(const AssetsCompanion(isStale: Value(0)));
  }

  /// 跨剧本查询：进行中的资产任务（任务中心用）。
  /// 状态取「生成中 / 待验收」。
  Stream<List<Asset>> watchActive() {
    return (select(assets)
          ..where((t) => t.status.isIn(['生成中', '待验收']))
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .watch();
  }
}
