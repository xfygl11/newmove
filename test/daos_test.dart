import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/provider_config/provider_models.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('ProjectDao', () {
    test('插入并列出项目', () async {
      await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试项目'),
      );

      final list = await db.projectDao.listAll();
      expect(list, hasLength(1));
      expect(list.first.name, '测试项目');
      expect(list.first.status, '草稿');
    });

    test('按更新时间倒序返回', () async {
      await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '旧项目'),
      );
      await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '新项目'),
      );

      final list = await db.projectDao.listAll();
      expect(list.first.name, '新项目');
    });

    test('删除项目', () async {
      final id = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '待删除'),
      );
      final affected = await db.projectDao.deleteProject(id);

      expect(affected, 1);
      expect(await db.projectDao.listAll(), isEmpty);
    });
  });

  group('ProviderDao', () {
    test('插入并可查询供应商', () async {
      await db.providerDao.upsert(
        ProviderConfigsCompanion.insert(
          id: 'deepseek',
          group: 'llm',
          label: 'DeepSeek',
          baseUrl: 'https://api.deepseek.com',
          protocol: 'openai-completions',
          models: Value(
            ProviderModelCodec.encode(
              const [
                ProviderModel(id: 'deepseek-chat', label: 'DeepSeek Chat'),
              ],
            ),
          ),
        ),
      );

      final found = await db.providerDao.findById('deepseek');
      expect(found, isNotNull);
      expect(found!.protocol, 'openai-completions');
      final models = ProviderModelCodec.decode(found.models);
      expect(models, hasLength(1));
      expect(models.first.id, 'deepseek-chat');
    });

    test('upsert 同 id 为更新', () async {
      await db.providerDao.upsert(
        ProviderConfigsCompanion.insert(
          id: 'p1',
          group: 'llm',
          label: '旧名',
          baseUrl: 'https://a.com',
          protocol: 'openai-completions',
        ),
      );
      await db.providerDao.upsert(
        ProviderConfigsCompanion.insert(
          id: 'p1',
          group: 'llm',
          label: '新名',
          baseUrl: 'https://a.com',
          protocol: 'openai-completions',
        ),
      );

      final all = await db.providerDao.listAll();
      expect(all, hasLength(1));
      expect(all.first.label, '新名');
    });

    test('按分组查询', () async {
      await db.providerDao.upsert(
        ProviderConfigsCompanion.insert(
          id: 'llm1',
          group: 'llm',
          label: 'L',
          baseUrl: 'https://a.com',
          protocol: 'openai-completions',
        ),
      );
      await db.providerDao.upsert(
        ProviderConfigsCompanion.insert(
          id: 'img1',
          group: 'image',
          label: 'I',
          baseUrl: 'https://a.com',
          protocol: 'openai-images',
        ),
      );

      final llm = await db.providerDao.listByGroup('llm');
      expect(llm, hasLength(1));
      expect(llm.first.id, 'llm1');
    });
  });
}
