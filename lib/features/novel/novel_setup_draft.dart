/// 创作前「基础设置」向导的表单状态与落库映射。
///
/// 页面只维护这一个对象，避免十几个 state 字段散落在 State 类里。
/// `briefText` 是喂给 AI 的唯一摘要格式，新增字段必须同步登记。
library;

import 'dart:convert' show jsonEncode;

import 'package:drift/drift.dart' show Value;
import 'package:newmove/data/app_database.dart';

import 'novel_setup_catalog.dart';

/// 高级设置里可 AI 帮写的字段。
enum SetupField {
  title('作品名称'),
  synopsis('作品简介'),
  characters('角色信息'),
  protagonistAbility('主角能力');

  const SetupField(this.label);

  final String label;
}

class NovelSetupDraft {
  const NovelSetupDraft({
    this.audience = '',
    this.workTypes = const [],
    this.personaTags = const [],
    this.backgroundTags = const [],
    this.volumeCount = NovelSetupCatalog.defaultVolumes,
    this.chaptersPerVolume = NovelSetupCatalog.defaultChaptersPerVolume,
    this.title = '',
    this.idea = '',
    this.synopsis = '',
    this.characters = '',
    this.protagonistAbility = '',
  });

  final String audience;
  final List<String> workTypes;
  final List<String> personaTags;
  final List<String> backgroundTags;
  final int volumeCount;
  final int chaptersPerVolume;
  final String title;
  final String idea;
  final String synopsis;
  final String characters;
  final String protagonistAbility;

  int get totalChapters =>
      NovelSetupCatalog.totalChapters(volumeCount, chaptersPerVolume);

  /// 基础设置里必填项（核心受众 + 至少一个作品类型）是否已填。
  bool get isComplete => audience.isNotEmpty && workTypes.isNotEmpty;

  NovelSetupDraft copyWith({
    String? audience,
    List<String>? workTypes,
    List<String>? personaTags,
    List<String>? backgroundTags,
    int? volumeCount,
    int? chaptersPerVolume,
    String? title,
    String? idea,
    String? synopsis,
    String? characters,
    String? protagonistAbility,
  }) {
    return NovelSetupDraft(
      audience: audience ?? this.audience,
      workTypes: workTypes ?? this.workTypes,
      personaTags: personaTags ?? this.personaTags,
      backgroundTags: backgroundTags ?? this.backgroundTags,
      volumeCount: volumeCount ?? this.volumeCount,
      chaptersPerVolume: chaptersPerVolume ?? this.chaptersPerVolume,
      title: title ?? this.title,
      idea: idea ?? this.idea,
      synopsis: synopsis ?? this.synopsis,
      characters: characters ?? this.characters,
      protagonistAbility: protagonistAbility ?? this.protagonistAbility,
    );
  }

  /// AI 帮写回填：按字段写入对应文本。
  NovelSetupDraft fillField(SetupField field, String text) {
    final trimmed = text.trim();
    return switch (field) {
      SetupField.title => copyWith(title: trimmed),
      SetupField.synopsis => copyWith(synopsis: trimmed),
      SetupField.characters => copyWith(characters: trimmed),
      SetupField.protagonistAbility =>
        copyWith(protagonistAbility: trimmed),
    };
  }

  /// 生成某字段时的当前内容，供 ConfirmSheet 展示上下文。
  String briefText({SetupField? omit}) {
    final rows = <String>[
      if (audience.isNotEmpty) '【核心受众】$audience',
      if (workTypes.isNotEmpty) '【作品类型】${workTypes.join(' / ')}',
      if (personaTags.isNotEmpty) '【人设标签】${personaTags.join('、')}',
      if (backgroundTags.isNotEmpty) '【背景标签】${backgroundTags.join('、')}',
      if (totalChapters > 0)
        '【章节规划】$volumeCount 卷 × $chaptersPerVolume 章，'
            '预计 $totalChapters 章',
      if (omit != SetupField.title && title.trim().isNotEmpty)
        '【作品名称】${title.trim()}',
      if (idea.trim().isNotEmpty) '【创意】${idea.trim()}',
      if (omit != SetupField.synopsis && synopsis.trim().isNotEmpty)
        '【作品简介】${synopsis.trim()}',
      if (omit != SetupField.characters && characters.trim().isNotEmpty)
        '【角色信息】${characters.trim()}',
      if (omit != SetupField.protagonistAbility &&
          protagonistAbility.trim().isNotEmpty)
        '【主角能力】${protagonistAbility.trim()}',
    ];
    return rows.join('\n');
  }

  /// 落库 companion（仅创建分支：创作前设置只发生一次）。
  NovelBooksCompanion toCompanion({required int projectId}) {
    final audience = Value<String?>(
      this.audience.isEmpty ? null : this.audience,
    );
    final workGenre = Value<String?>(
      workTypes.isEmpty ? null : jsonEncode(workTypes),
    );
    final tags = Value<String?>(
      personaTags.isEmpty && backgroundTags.isEmpty
          ? null
          : jsonEncode({
              'personas': personaTags,
              'backgrounds': backgroundTags,
            }),
    );
    final synopsis = Value<String?>(
      this.synopsis.trim().isEmpty ? null : this.synopsis.trim(),
    );
    final protagonistAbility = Value<String?>(
      this.protagonistAbility.trim().isEmpty
          ? null
          : this.protagonistAbility.trim(),
    );
    return NovelBooksCompanion.insert(
      projectId: projectId,
      title: title.trim().isEmpty ? '未命名作品' : title.trim(),
      audience: audience,
      workGenre: workGenre,
      tags: tags,
      volumeCount: Value(volumeCount),
      chaptersPerVolume: Value(chaptersPerVolume),
      synopsis: synopsis,
      protagonistAbility: protagonistAbility,
    );
  }
}
