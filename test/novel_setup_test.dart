import 'dart:convert' show jsonEncode;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/novel/novel_service.dart';
import 'package:newmove/features/novel/novel_setup_catalog.dart';
import 'package:newmove/features/novel/novel_setup_draft.dart';

void main() {
  group('NovelSetupCatalog', () {
    test('词表与边界常量符合规格', () {
      expect(NovelSetupCatalog.audiences, ['男频', '女频', '全性别']);
      expect(NovelSetupCatalog.workGenreGroups.length, 10);
      expect(NovelSetupCatalog.workGenreAll.length, 79);
      expect(NovelSetupCatalog.personaTags.length, 9);
      expect(NovelSetupCatalog.backgroundTags.length, 9);
      expect(NovelSetupCatalog.maxTagsPerGroup, 5);
      expect(NovelSetupCatalog.minVolumes, 1);
      expect(NovelSetupCatalog.maxVolumes, 20);
      expect(NovelSetupCatalog.minChaptersPerVolume, 1);
      expect(NovelSetupCatalog.maxChaptersPerVolume, 50);
      expect(NovelSetupCatalog.defaultVolumes, 10);
      expect(NovelSetupCatalog.defaultChaptersPerVolume, 50);
      // 跨类重复的类型只保留一份。
      expect(NovelSetupCatalog.workGenreAll.where((t) => t == '无限流').length, 1);
    });

    test('总章节数为卷数乘每卷章节数', () {
      expect(NovelSetupCatalog.totalChapters(10, 50), 500);
      expect(NovelSetupCatalog.totalChapters(0, 50), 0);
    });
  });

  group('NovelSetupDraft.briefText', () {
    NovelSetupDraft full() => const NovelSetupDraft(
      audience: '男频',
      workTypes: ['东方玄幻', '都市重生'],
      personaTags: ['热血少年'],
      backgroundTags: ['废土末世'],
      volumeCount: 10,
      chaptersPerVolume: 50,
      title: '觉醒之日',
      idea: '少年在末世觉醒治愈能力',
      synopsis: '病毒爆发后，他成为唯一的治愈者',
      characters: '林川｜主角｜寻找妹妹',
      protagonistAbility: '治愈能力，代价是寿命',
    );

    test('输出全部已填项', () {
      final text = full().briefText();
      expect(text, contains('【核心受众】男频'));
      expect(text, contains('【作品类型】东方玄幻 / 都市重生'));
      expect(text, contains('【人设标签】热血少年'));
      expect(text, contains('【背景标签】废土末世'));
      expect(text, contains('预计 500 章'));
      expect(text, contains('【作品名称】觉醒之日'));
      expect(text, contains('【创意】少年在末世觉醒治愈能力'));
      expect(text, contains('【作品简介】病毒爆发后，他成为唯一的治愈者'));
      expect(text, contains('【角色信息】林川｜主角｜寻找妹妹'));
      expect(text, contains('【主角能力】治愈能力，代价是寿命'));
    });

    test('省略当前正在生成的字段', () {
      expect(full().briefText(omit: SetupField.synopsis), isNot(contains('【作品简介】')));
      expect(full().briefText(omit: SetupField.characters), isNot(contains('【角色信息】')));
      expect(full().briefText(omit: SetupField.title), isNot(contains('【作品名称】')));
      expect(full().briefText(omit: SetupField.protagonistAbility),
        isNot(contains('【主角能力】')),
      );
      // 其它项不受影响。
      expect(full().briefText(omit: SetupField.synopsis), contains('【核心受众】男频'));
    });

    test('未填项不出现', () {
      final text = const NovelSetupDraft(audience: '女频').briefText();
      expect(text, contains('【核心受众】女频'));
      expect(text, isNot(contains('【作品类型】')));
      expect(text, isNot(contains('【人设标签】')));
      expect(text, isNot(contains('【背景标签】')));
      expect(text, contains('预计 500 章'));
      expect(text, isNot(contains('【作品简介】')));
    });

    test('纯空白字段视为未填', () {
      final text = const NovelSetupDraft(
        audience: '男频',
        workTypes: ['科幻'],
        synopsis: '   ',
        protagonistAbility: '\t',
      ).briefText();
      expect(text, isNot(contains('【作品简介】')));
      expect(text, isNot(contains('【主角能力】')));
    });
  });

  group('NovelSetupDraft.fillField', () {
    test('按字段写入并去首尾空白', () {
      final draft = const NovelSetupDraft();
      expect(draft.fillField(SetupField.title, '  觉醒之日  ').title, '觉醒之日');
      expect(draft.fillField(SetupField.synopsis, '  简介  ').synopsis, '简介');
      expect(draft.fillField(SetupField.characters, '  角色  ').characters, '角色');
      expect(
        draft.fillField(SetupField.protagonistAbility, '  金手指  ').protagonistAbility,
        '金手指',
      );
    });

    test('互不覆盖', () {
      final draft = const NovelSetupDraft()
          .fillField(SetupField.title, '书名')
          .fillField(SetupField.synopsis, '简介');
      expect(draft.title, '书名');
      expect(draft.synopsis, '简介');
      expect(draft.characters, '');
    });
  });

  group('NovelSetupDraft.isComplete', () {
    test('核心受众与作品类型齐全才通过', () {
      expect(const NovelSetupDraft().isComplete, isFalse);
      expect(const NovelSetupDraft(audience: '男频').isComplete, isFalse);
      expect(const NovelSetupDraft(workTypes: ['科幻']).isComplete, isFalse);
      expect(
        const NovelSetupDraft(audience: '男频', workTypes: ['科幻']).isComplete,
        isTrue,
      );
    });
  });

  group('NovelSetupDraft.toCompanion', () {
    test('落库 companion 写入全部基础设置字段', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试项目'),
      );
      final bookId = await db.novelDao.insertBook(
        const NovelSetupDraft(
          audience: '男频',
          workTypes: ['东方玄幻', '热血'],
          personaTags: ['热血少年', '天才'],
          backgroundTags: ['修仙'],
          volumeCount: 12,
          chaptersPerVolume: 30,
          title: '觉醒之日',
          synopsis: '病毒爆发后，他成为唯一的治愈者',
          protagonistAbility: '治愈能力，代价是寿命',
        ).toCompanion(projectId: projectId),
      );
      final row = await db.novelDao.findBook(bookId);
      expect(row, isNotNull);
      expect(row!.title, '觉醒之日');
      expect(row.audience, '男频');
      expect(row.workGenre, '["东方玄幻","热血"]');
      expect(
        row.tags,
        '{"personas":["热血少年","天才"],"backgrounds":["修仙"]}',
      );
      expect(row.volumeCount, 12);
      expect(row.chaptersPerVolume, 30);
      expect(row.synopsis, '病毒爆发后，他成为唯一的治愈者');
      expect(row.protagonistAbility, '治愈能力，代价是寿命');
    });

    test('空值不落 null 字符串，标题空时回落未命名作品', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试项目'),
      );
      final bookId = await db.novelDao.insertBook(
        const NovelSetupDraft(audience: '男频', workTypes: ['科幻']).toCompanion(
          projectId: projectId,
        ),
      );
      final row = await db.novelDao.findBook(bookId);
      expect(row, isNotNull);
      expect(row!.title, '未命名作品');
      expect(row.tags, isNull);
      expect(row.synopsis, isNull);
      expect(row.protagonistAbility, isNull);
      expect(row.volumeCount, 10);
      expect(row.chaptersPerVolume, 50);
    });
  });

  group('NovelService.genreContext', () {
    test('null 与空作品返回空串', () {
      expect(NovelService.genreContext(null), '');
      final empty = const NovelBook(
        id: 1,
        projectId: 1,
        title: '空书',
        genre: null,
        workType: '长篇',
        targetWords: 2000,
        premise: null,
        world: null,
        styleGuide: null,
        outline: null,
        audience: null,
        workGenre: null,
        tags: null,
        volumeCount: 0,
        chaptersPerVolume: 0,
        synopsis: null,
        protagonistAbility: null,
        status: '草稿',
      );
      expect(NovelService.genreContext(empty), '');
    });

    test('只输出非空项并以换行结尾', () {
      final book = const NovelBook(
        id: 1,
        projectId: 1,
        title: '书',
        genre: null,
        workType: '长篇',
        targetWords: 2000,
        premise: null,
        world: null,
        styleGuide: null,
        outline: null,
        audience: '男频',
        workGenre: '["东方玄幻"]',
        tags: '{"personas":["热血少年"],"backgrounds":["废土末世"]}',
        volumeCount: 10,
        chaptersPerVolume: 50,
        synopsis: null,
        protagonistAbility: null,
        status: '草稿',
      );
      final context = NovelService.genreContext(book);
      expect(context, endsWith('\n'));
      expect(context, contains('【核心受众】男频'));
      expect(context, contains('【作品类型】东方玄幻'));
      expect(context, contains('【人设标签】热血少年'));
      expect(context, contains('【背景标签】废土末世'));
      expect(context, contains('预计 500 章'));
    });

    test('超出上下文上限的类型与标签被截断', () {
      final overGenres = [for (var i = 0; i < 20; i++) '类型$i'];
      final overTags = [for (var i = 0; i < 20; i++) '标签$i'];
      final book = NovelBook(
        id: 1,
        projectId: 1,
        title: '书',
        genre: null,
        workType: '长篇',
        targetWords: 2000,
        premise: null,
        world: null,
        styleGuide: null,
        outline: null,
        audience: '全性别',
        workGenre: jsonEncode(overGenres),
        tags: '{"personas":["${overTags.join('","')}"]}',
        volumeCount: 0,
        chaptersPerVolume: 0,
        synopsis: null,
        protagonistAbility: null,
        status: '草稿',
      );
      final context = NovelService.genreContext(book);
      expect(context, contains('类型9'));
      expect(context, isNot(contains('类型10')));
      expect(context, contains('标签4'));
      expect(context, isNot(contains('标签5')));
      // 规划数字缺项时不出现该节。
      expect(context, isNot(contains('【章节规划】')));
    });

    test('脏数据不抛异常', () {
      final book = const NovelBook(
        id: 1,
        projectId: 1,
        title: '书',
        genre: null,
        workType: '长篇',
        targetWords: 2000,
        premise: null,
        world: null,
        styleGuide: null,
        outline: null,
        audience: null,
        workGenre: '这不是 JSON',
        tags: '[1,2,3]',
        volumeCount: 3,
        chaptersPerVolume: 2,
        synopsis: null,
        protagonistAbility: null,
        status: '草稿',
      );
      expect(NovelService.genreContext(book), contains('【章节规划】'));
    });
  });
}
