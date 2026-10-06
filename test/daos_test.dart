import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/data/daos/prompt_override_dao.dart';
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
      await db.projectDao.insertProject(ProjectsCompanion.insert(name: '测试项目'));

      final list = await db.projectDao.listAll();
      expect(list, hasLength(1));
      expect(list.first.name, '测试项目');
      expect(list.first.status, '草稿');
    });

    test('按更新时间倒序返回', () async {
      await db.projectDao.insertProject(
        ProjectsCompanion.insert(
          name: '旧项目',
          updatedAt: Value(DateTime(2026, 1, 1)),
        ),
      );
      await db.projectDao.insertProject(
        ProjectsCompanion.insert(
          name: '新项目',
          updatedAt: Value(DateTime(2026, 1, 2)),
        ),
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
            ProviderModelCodec.encode(const [
              ProviderModel(id: 'deepseek-chat', label: 'DeepSeek Chat'),
            ]),
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

  group('schema v13 结构', () {
    test('剧本表已删除 aspect_ratio 与 language 死字段', () async {
      expect(db.schemaVersion, 13);

      final rows = await db.customSelect('PRAGMA table_info(scripts)').get();
      final columns = rows.map((row) => row.data['name'] as String).toSet();

      expect(columns, isNot(contains('aspect_ratio')));
      expect(columns, isNot(contains('language')));
      expect(
        columns,
        containsAll([
          'id',
          'book_id',
          'title',
          'version',
          'fidelity_mode',
          'art_style',
          'status',
          'content',
        ]),
      );
    });

    test('剧本表新增 M16 集元数据三列', () async {
      final rows = await db.customSelect('PRAGMA table_info(scripts)').get();
      final columns = rows.map((row) => row.data['name'] as String).toSet();

      expect(
        columns,
        containsAll(['episode_no', 'target_duration_ms', 'model_version']),
      );
    });

    test('作品表新增 M17 每章目标字数，默认 2000', () async {
      final rows = await db
          .customSelect('PRAGMA table_info(novel_books)')
          .get();
      final columns = rows.map((row) => row.data['name'] as String).toSet();
      expect(columns, contains('target_words'));

      final pid = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: 't'),
      );
      final id = await db.novelDao.insertBook(
        NovelBooksCompanion.insert(projectId: pid, title: 't'),
      );
      final book = await db.novelDao.findBook(id);
      expect(book?.targetWords, 2000);
    });

    test('M19 镜头结构化字段九列与失效标记', () async {
      final rows = await db.customSelect('PRAGMA table_info(shots)').get();
      final columns = rows.map((row) => row.data['name'] as String).toSet();
      expect(
        columns,
        containsAll([
          'composition',
          'lens',
          'camera_position',
          'eyeline',
          'focus',
          'stability',
          'blocking',
          'dialogue_start_ratio',
          'dialogue_end_ratio',
          'is_stale',
        ]),
      );
    });

    test('M19 T21.13 镜头表新增服装覆盖列', () async {
      final rows = await db.customSelect('PRAGMA table_info(shots)').get();
      final rowsMeta = rows
          .where((r) => r.data['name'] == 'costume_overrides')
          .toList();
      expect(rowsMeta, hasLength(1));
      // 可空：无覆盖的镜头该列为 NULL，与「全部沿用基础态」同义。
      expect(rowsMeta.single.data['notnull'], 0);
    });

    test('M19 剧本指纹与资产结构化字段、失效标记', () async {
      final scripts = await db.customSelect('PRAGMA table_info(scripts)').get();
      expect(
        scripts.map((r) => r.data['name']).toSet(),
        contains('script_hash'),
      );

      final assets = await db.customSelect('PRAGMA table_info(assets)').get();
      expect(
        assets.map((r) => r.data['name']).toSet(),
        containsAll(['height_cm', 'body_type', 'costume_sets', 'is_stale']),
      );
    });

    test('M19 提示词覆盖表列集与作用域常量', () async {
      final rows = await db
          .customSelect('PRAGMA table_info(prompt_overrides)')
          .get();
      expect(
        rows.map((r) => r.data['name']).toSet(),
        containsAll([
          'id',
          'scope',
          'project_id',
          'slot_key',
          'body',
          'updated_at',
        ]),
      );
      expect(PromptOverrideScopes.global, 'global');
      expect(PromptOverrideScopes.project, 'project');
    });
  });
}
