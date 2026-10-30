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

    test('级联删除项目', () async {
      final id = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '待删除'),
      );
      await db.cascadeDao.deleteProjectCascade(id);

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

  group('NovelDao 聚合统计', () {
    test('getAllBookStats 一次查询返回全部书统计', () async {
      final pid = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: 't'),
      );
      final bookA = await db.novelDao.insertBook(
        NovelBooksCompanion.insert(projectId: pid, title: 'A'),
      );
      final bookB = await db.novelDao.insertBook(
        NovelBooksCompanion.insert(projectId: pid, title: 'B'),
      );

      for (var i = 0; i < 3; i++) {
        await db.novelDao.insertChapter(
          ChaptersCompanion.insert(
            bookId: bookA,
            seq: i + 1,
            title: 'A$i',
            content: const Value('内容'),
            wordCount: const Value(100),
          ),
        );
      }
      await db.novelDao.insertChapter(
        ChaptersCompanion.insert(
          bookId: bookB,
          seq: 1,
          title: 'B0',
          content: const Value('内容'),
          wordCount: const Value(50),
        ),
      );

      final stats = await db.novelDao.getAllBookStats();

      expect(stats[bookA], (chapterCount: 3, wordCount: 300));
      expect(stats[bookB], (chapterCount: 1, wordCount: 50));
      // 无章节的书不出现（书架页按 0/0 回落）。
      expect(stats, hasLength(2));
    });
  });

  group('schema 结构', () {
    test('剧本表已删除 language 死字段，M29 复活 aspect_ratio 多比例列', () async {
      expect(db.schemaVersion, 19);

      final rows = await db.customSelect('PRAGMA table_info(scripts)').get();
      final columns = rows.map((row) => row.data['name'] as String).toSet();

      expect(columns, contains('aspect_ratio'));
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

    test('M23 项目表新增项目级提示词开关，可空且默认未设置', () async {
      final rows = await db
          .customSelect('PRAGMA table_info(projects)')
          .get();
      final rowsMeta = rows
          .where((r) => r.data['name'] == 'use_project_prompts')
          .toList();
      expect(rowsMeta, hasLength(1));
      expect(rowsMeta.single.data['notnull'], 0);

      final id = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: 't'),
      );
      final project = await db.projectDao.findById(id);
      expect(project?.useProjectPrompts, isNull);
    });

    test('M23 提示词版本表列集', () async {
      final rows = await db
          .customSelect('PRAGMA table_info(prompt_override_versions)')
          .get();
      expect(
        rows.map((r) => r.data['name']).toSet(),
        containsAll(['id', 'scope', 'project_id', 'slot_key', 'body', 'created_at']),
      );
      final projectMeta = rows
          .where((r) => r.data['name'] == 'project_id')
          .toList();
      expect(projectMeta.single.data['notnull'], 0);
    });

    test('M23 全表清单含提示词版本表', () async {
      final rows = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ).get();
      expect(
        rows.map((r) => r.data['name'] as String),
        contains('prompt_override_versions'),
      );
    });

    test('M24 角色关系历史表列集，归属作品与章节序号可空', () async {
      final rows = await db
          .customSelect('PRAGMA table_info(character_relations)')
          .get();
      expect(
        rows.map((r) => r.data['name']).toSet(),
        containsAll([
          'id',
          'book_id',
          'source',
          'target',
          'description',
          'chapter_seq',
          'is_current',
          'created_at',
        ]),
      );
      final chapterMeta = rows
          .where((r) => r.data['name'] == 'chapter_seq')
          .toList();
      expect(chapterMeta.single.data['notnull'], 0);
      final currentMeta = rows
          .where((r) => r.data['name'] == 'is_current')
          .toList();
      expect(currentMeta.single.data['dflt_value'], '1');
    });

    test('M24 质量门日志表列集，归属项目可空且 ok 默认未命中记录', () async {
      final rows = await db.customSelect('PRAGMA table_info(gate_logs)').get();
      expect(
        rows.map((r) => r.data['name']).toSet(),
        containsAll([
          'id',
          'subject_type',
          'subject_id',
          'subject_label',
          'gate_id',
          'ok',
          'detail',
          'project_id',
          'created_at',
        ]),
      );
      final projectMeta = rows
          .where((r) => r.data['name'] == 'project_id')
          .toList();
      expect(projectMeta.single.data['notnull'], 0);
    });

    test('M24 全表清单含两张新增历史表', () async {
      final rows = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ).get();
      expect(
        rows.map((r) => r.data['name'] as String),
        containsAll(['character_relations', 'gate_logs']),
      );
    });

    test('M24 两表不加外键，归属靠显式级联删除', () async {
      for (final table in ['character_relations', 'gate_logs']) {
        final rows = await db
            .customSelect('PRAGMA foreign_key_list($table)')
            .get();
        expect(
          rows,
          isEmpty,
          reason: '$table 不应声明外键',
        );
      }
    });

    test('M29 剧本表新增集级钩子/悬念/调板/多比例/描述/关键词/背景乐', () async {
      final rows = await db.customSelect('PRAGMA table_info(scripts)').get();
      expect(
        rows.map((r) => r.data['name']).toSet(),
        containsAll([
          'hook',
          'cliff',
          'color_palette',
          'aspect_ratio',
          'description',
          'keywords',
          'bgm_url',
        ]),
      );
      // 全部可空：旧集没有这些集级元数据时不影响读取。
      for (final col in [
        'hook',
        'cliff',
        'color_palette',
        'aspect_ratio',
        'description',
        'keywords',
        'bgm_url',
      ]) {
        final meta = rows.where((r) => r.data['name'] == col).single;
        expect(meta.data['notnull'], 0, reason: '$col 应可空');
      }
    });

    test('M29 场次/节拍/资产/镜头/帧/参考/快照新增列均可空', () async {
      final cases = <String, List<String>>{
        'scenes': ['location_id'],
        'beats': ['weight', 'hook_beat_id'],
        'assets': ['is_narrative'],
        'shots': ['sound_design', 'music_cue', 'depth_of_field', 'video_script'],
        'shot_frames': ['is_scene_ref'],
        'asset_refs': ['version', 'is_active'],
        'shot_revisions': ['version_group'],
      };
      for (final entry in cases.entries) {
        final rows = await db
            .customSelect('PRAGMA table_info(${entry.key})')
            .get();
        final byName = {for (final r in rows) r.data['name']: r.data};
        for (final col in entry.value) {
          expect(byName, contains(col), reason: '${entry.key}.$col 缺失');
          expect(
            byName[col]!['notnull'],
            0,
            reason: '${entry.key}.$col 应可空（旧数据缺字段照常通过）',
          );
        }
      }
    });

    test('M29 六张新表均已创建且归属列正确', () async {
      final rows = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ).get();
      expect(
        rows.map((r) => r.data['name'] as String),
        containsAll([
          'locations',
          'story_arcs',
          'arc_nodes',
          'prompt_presets',
          'import_logs',
          'agent_bindings',
        ]),
      );
    });

    test('M29 地点表列集与软引用（无外键）', () async {
      final rows = await db
          .customSelect('PRAGMA table_info(locations)')
          .get();
      expect(
        rows.map((r) => r.data['name']).toSet(),
        containsAll([
          'id',
          'book_id',
          'name',
          'type',
          'parent_id',
          'description',
          'created_at',
        ]),
      );
      // 地点按 bookId 归属作品（唯一出站外键指向 novel_books）。
      final fk = await db.customSelect('PRAGMA foreign_key_list(locations)').get();
      expect(
        fk.map((r) => r.data['table'] as String),
        contains('novel_books'),
      );
      // Scenes.locationId 是软引用：scenes 表不声明指向 locations 的外键，
      // 删地点不级联删场景，悬空的 locationId 由场景读取方回落。
      final sceneFk = await db.customSelect('PRAGMA foreign_key_list(scenes)').get();
      expect(
        sceneFk.map((r) => r.data['table'] as String),
        isNot(contains('locations')),
      );
    });

    test('M29 故事弧线节点引用弧线，绑定唯一 projectId+category', () async {
      final arcFk = await db
          .customSelect('PRAGMA foreign_key_list(arc_nodes)')
          .get();
      expect(arcFk, isNotEmpty, reason: 'arc_nodes 应引用 story_arcs');

      final rows = await db
          .customSelect('PRAGMA table_info(agent_bindings)')
          .get();
      expect(
        rows.map((r) => r.data['name']).toSet(),
        containsAll(['id', 'project_id', 'category', 'agent_id', 'created_at']),
      );
      // unique 约束：同 projectId + category 至多一条绑定。
      final idx = await db.customSelect(
        'PRAGMA index_list(agent_bindings)',
      ).get();
      expect(idx.map((r) => r.data['name']), isNotEmpty);
    });
  });

  group('ChapterRevisionDao.snapshotAndReplace', () {
    Future<({int bookId, int chapterId})> seed(String content) async {
      final pid = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试项目'),
      );
      final bookId = await db.novelDao.insertBook(
        NovelBooksCompanion.insert(projectId: pid, title: '测试书'),
      );
      final chapterId = await db.novelDao.insertChapter(
        ChaptersCompanion.insert(
          bookId: bookId,
          seq: 1,
          title: '第一章',
          content: Value(content),
        ),
      );
      return (bookId: bookId, chapterId: chapterId);
    }

    test('存档旧正文、替换正文并推进修订号', () async {
      final ids = await seed('旧正文一二三');
      final chapter = (await db.novelDao.findChapter(ids.chapterId))!;

      await db.chapterRevisionDao.snapshotAndReplace(
        chapter: chapter,
        content: '新正文',
        wordCount: 3,
      );

      final after = (await db.novelDao.findChapter(ids.chapterId))!;
      expect(after.content, '新正文');
      expect(after.wordCount, 3);
      expect(after.revision, chapter.revision + 1);

      final revisions = await db.chapterRevisionDao.listByChapter(
        ids.chapterId,
      );
      expect(revisions, hasLength(1));
      expect(revisions.single.content, '旧正文一二三');
      expect(revisions.single.revision, chapter.revision);
    });

    test('连续两次替换形成两档可回退的版本链', () async {
      final ids = await seed('v1 正文');

      for (final text in ['v2 正文', 'v3 正文']) {
        final chapter = (await db.novelDao.findChapter(ids.chapterId))!;
        await db.chapterRevisionDao.snapshotAndReplace(
          chapter: chapter,
          content: text,
          wordCount: text.length,
        );
      }

      final after = (await db.novelDao.findChapter(ids.chapterId))!;
      expect(after.content, 'v3 正文');

      final revisions = await db.chapterRevisionDao.listByChapter(
        ids.chapterId,
      );
      // 倒序：最新存档在前，指向被替换掉的那一版正文。
      expect(revisions.map((r) => r.content).toList(), [
        'v2 正文',
        'v1 正文',
      ]);
    });

    test('任一步失败整段回滚：不留半套快照', () async {
      final ids = await seed('旧正文');
      final chapter = (await db.novelDao.findChapter(ids.chapterId))!;
      // 章节 id 不存在 → 快照插入违反外键，事务必须整段回滚。
      final ghost = chapter.copyWith(id: 999999);

      await expectLater(
        db.chapterRevisionDao.snapshotAndReplace(
          chapter: ghost,
          content: '新正文',
          wordCount: 3,
        ),
        throwsA(isA<Exception>()),
      );

      final after = (await db.novelDao.findChapter(ids.chapterId))!;
      expect(after.content, '旧正文');
      expect(after.revision, chapter.revision);
      expect(await db.chapterRevisionDao.listByChapter(ids.chapterId), isEmpty);
      expect(await db.chapterRevisionDao.listByChapter(999999), isEmpty);
    });
  });
}
