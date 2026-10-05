import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/asset/asset_models.dart';
import 'package:newmove/features/provider_config/provider_edit_sheet.dart';
import 'package:newmove/features/provider_config/provider_models.dart';

/// 项目 → 书籍 → 剧本 → 资产夹具（assets.script_id 有外键，必须先建父行）。
Future<int> _insertAsset(
  AppDatabase db,
  int scriptId,
  String type,
  String stableId,
  String name,
  String status,
) {
  return db.assetDao.insert(
    AssetsCompanion.insert(
      scriptId: scriptId,
      type: type,
      stableId: stableId,
      name: name,
      status: Value(status),
    ),
  );
}

Future<int> _newScript(AppDatabase db) async {
  final projectId = await db.projectDao.insertProject(
    ProjectsCompanion.insert(name: '测试项目'),
  );
  final bookId = await db.novelDao.insertBook(
    NovelBooksCompanion.insert(projectId: projectId, title: '测试书'),
  );
  return db.scriptDao.insert(
    ScriptsCompanion.insert(bookId: bookId, title: '测试剧本'),
  );
}

void main() {
  group('AssetDao.flipStatus（T20.13 卡死资产回收）', () {
    late AppDatabase db;
    late int scriptId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      scriptId = await _newScript(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('把指定状态全部改回，返回受影响 id，不动其它状态', () async {
      await _insertAsset(
        db,
        scriptId,
        '角色',
        'c-1',
        '主角',
        AssetStatuses.generating,
      );
      await _insertAsset(
        db,
        scriptId,
        '角色',
        'c-2',
        '配角',
        AssetStatuses.reviewing,
      );
      await _insertAsset(
        db,
        scriptId,
        '场景',
        's-1',
        '场景',
        AssetStatuses.generating,
      );

      final ids = await db.assetDao.flipStatus(
        fromStatus: AssetStatuses.generating,
        toStatus: AssetStatuses.pending,
      );

      expect(ids, hasLength(2));
      final list = await db.assetDao.listByScript(scriptId);
      final byId = {for (final a in list) a.id: a.status};
      for (final id in ids) {
        expect(byId[id], AssetStatuses.pending);
      }
      // 待验收那条不受影响——不能一把梭改全表。
      final untouched = list.where((a) => a.stableId == 'c-2').single;
      expect(untouched.status, AssetStatuses.reviewing);
    });

    test('没有卡死资产时返回空列表，不抛错', () async {
      await _insertAsset(
        db,
        scriptId,
        '角色',
        'c-1',
        '主角',
        AssetStatuses.pending,
      );

      expect(
        await db.assetDao.flipStatus(
          fromStatus: AssetStatuses.generating,
          toStatus: AssetStatuses.pending,
        ),
        isEmpty,
      );
    });
  });

  group('validateBaseUrl（T20.15 Base URL 必须 https）', () {
    test('https 通过', () {
      expect(validateBaseUrl('https://api.deepseek.com'), isNull);
      expect(validateBaseUrl('https://api.deepseek.com/v1'), isNull);
    });

    test('空值要求填写', () {
      expect(validateBaseUrl(null), '请填写 Base URL');
      expect(validateBaseUrl(''), '请填写 Base URL');
      expect(validateBaseUrl('   '), '请填写 Base URL');
    });

    test('明文 http 拒绝', () {
      expect(validateBaseUrl('http://api.example.com'), isNotNull);
    });

    test('本机回环放行（本地调试）', () {
      expect(validateBaseUrl('http://localhost:11434/v1'), isNull);
      expect(validateBaseUrl('http://127.0.0.1:11434/v1'), isNull);
    });

    test('缺 scheme 或 host 视为格式错误', () {
      expect(validateBaseUrl('api.example.com'), isNotNull);
      expect(validateBaseUrl('file:///tmp/x'), isNotNull);
    });
  });

  group('ProviderModelCodec.decode（T20.12 宽容解析）', () {
    test('数字写成字符串也能解析', () {
      final list = ProviderModelCodec.decode(
        '[{"id":"m1","label":"M1","maxImageRefs":"3",'
        '"contextWindow":"128000","maxOutputTokens":"4096"}]',
      );
      expect(list, hasLength(1));
      expect(list.single.maxImageRefs, 3);
      expect(list.single.contextWindow, 128000);
      expect(list.single.maxOutputTokens, 4096);
    });

    test('非对象的条目被跳过，不拖垮整组', () {
      final list = ProviderModelCodec.decode(
        '[42,"not-an-object",{"id":"m2","label":"M2"}]',
      );
      expect(list, hasLength(1));
      expect(list.single.id, 'm2');
    });

    test('顶层不是列表时返回空列表（此前 as List 强转抛 TypeError）', () {
      expect(ProviderModelCodec.decode('{"id":"m1"}'), isEmpty);
      expect(ProviderModelCodec.decode('"a string"'), isEmpty);
      expect(ProviderModelCodec.decode('null'), isEmpty);
    });

    test('非法 JSON 返回空列表，不抛异常', () {
      expect(ProviderModelCodec.decode('{oops'), isEmpty);
      expect(ProviderModelCodec.decode('{"not":"a list"}'), isEmpty);
    });

    test('能力字段过滤后为空视为未知（null），不是空列表', () {
      final list = ProviderModelCodec.decode(
        '[{"id":"m1","label":"M1","imageSizes":[42,3.14]}]',
      );
      expect(list.single.imageSizes, isNull);
    });
  });
}
