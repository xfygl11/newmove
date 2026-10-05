import '../data/app_database.dart';
import '../data/daos/prompt_override_dao.dart';
import 'skill_loader.dart';

/// 提示词三级覆盖解析器（M19 T21.11）。
///
/// 内置 skill 是打进 APK 的只读资源，用户改不了提示词，实测提示词规则只能
/// 靠用户在自己的项目里调。解析顺序：项目级覆盖 > 全局级覆盖 > 内置 skill
/// 原文。
///
/// 覆盖按整段替换，不做局部合并——局部合并需要插槽解析，语义太脆。
class PromptResolver {
  const PromptResolver(this.dao);

  final PromptOverrideDao dao;

  /// 可被覆盖的内置 skill 插槽，与 assets/skills 目录一一对应。
  static const allSlots = <String>[
    'adaptation/source_and_script.md',
    'adaptation/screen_adaptation.md',
    'novel/planning.md',
    'novel/writing.md',
    'novel/chapter_planning.md',
    'novel/review.md',
    'novel/settling.md',
    'skeleton/beat_parsing.md',
    'skeleton/asset_states.md',
    'asset/asset_design.md',
    'shot/storyboard.md',
    'shot/continuity.md',
  ];

  /// 解析某插槽当前可用的提示词全文。
  Future<String> resolve(String relativePath, {int? projectId}) async {
    if (projectId != null) {
      final project = await dao.find(
        PromptOverrideScopes.project,
        relativePath,
        projectId: projectId,
      );
      if (project != null && project.body.trim().isNotEmpty) {
        return project.body;
      }
    }
    final global = await dao.find(PromptOverrideScopes.global, relativePath);
    if (global != null && global.body.trim().isNotEmpty) {
      return global.body;
    }
    return SkillLoader.load(relativePath);
  }

  /// 按作品解析：bookId → 项目 → 项目级覆盖。
  ///
  /// 项目归属统一从作品表解析，调用点不自拼 bookId → projectId。
  /// [bookId] 为空（如剧本尚未落库的首次改编）时跳过项目级，只走全局与内置。
  Future<String> resolveByBook(String relativePath, {int? bookId}) {
    if (bookId == null) {
      return resolve(relativePath);
    }
    return dao.projectOfBook(bookId).then(
      (projectId) => resolve(relativePath, projectId: projectId),
    );
  }

  /// 当前插槽是否已被覆盖（用于设置页展示「已自定义」标记）。
  Future<PromptOverride?> findOverride(String relativePath, {int? projectId}) {
    if (projectId != null) {
      final project = dao.find(
        PromptOverrideScopes.project,
        relativePath,
        projectId: projectId,
      );
      return project.then((row) {
        if (row != null) return row;
        return dao.find(PromptOverrideScopes.global, relativePath);
      });
    }
    return dao.find(PromptOverrideScopes.global, relativePath);
  }
}
