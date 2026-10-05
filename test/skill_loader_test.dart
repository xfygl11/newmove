import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/agent/prompt_resolver.dart';
import 'package:newmove/agent/skill_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 这条测试拦住两类只能真机发现的问题：资源没打进包、路径拼错。
  // `rootBundle.loadString` 在测试里走 asset manifest，与 APK 打包同源。
  test('PromptResolver.allSlots 逐一可加载且以 Markdown 标题开头（T20.24）', () async {
    final missing = <String>[];
    final badTitle = <String>[];
    for (final slot in PromptResolver.allSlots) {
      final text = await SkillLoader.load(slot);
      if (text.trim().isEmpty) {
        missing.add(slot);
        continue;
      }
      // 约定：每个 skill 首行是 `# ` 一级标题，便于用户在自己的编辑器里
      // 一眼看出这是哪份提示词。
      final head = text.trim().split('\n').first.trim();
      if (!head.startsWith('# ')) badTitle.add('$slot（首行：$head）');
    }
    expect(missing, isEmpty, reason: '下列 skill 加载为空：$missing');
    expect(badTitle, isEmpty,
        reason: '下列 skill 首行不是 # 标题：$badTitle');
  });

  // 反向守卫：assets/skills 里新增文件而忘记登记进 allSlots，
  // 用户就永远覆盖不到它，且没有任何报错。
  test('assets/skills 下无未登记的孤立 skill 文件', () {
    final root = Directory('assets/skills');
    if (!root.existsSync()) {
      return; // 测试在资源目录缺失时跳过，让上一条测试报加载失败。
    }
    final onDisk = <String>{};
    for (final entry in root.listSync(recursive: true)) {
      if (entry is! File || !entry.path.endsWith('.md')) continue;
      final rel = entry.path.replaceFirst('assets/skills/', '');
      if (rel.isNotEmpty) onDisk.add(rel);
    }
    final registered = PromptResolver.allSlots.toSet();
    expect(onDisk, registered,
        reason: '目录与 allSlots 不一致——孤立文件用户无法覆盖，'
            '缺失项会导致运行时空指针。');
  });

  test('SkillLoader 缓存命中后不再读 rootBundle', () async {
    SkillLoader.isCached('shot/storyboard.md');
    final first = await SkillLoader.load('shot/storyboard.md');
    expect(SkillLoader.isCached('shot/storyboard.md'), isTrue);
    final second = await SkillLoader.load('shot/storyboard.md');
    expect(second, first);
  });
}
