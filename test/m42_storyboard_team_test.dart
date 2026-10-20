import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/agent/prompt_resolver.dart';
import 'package:newmove/agent/team/storyboard_team.dart';
import 'package:newmove/core/network/llm_provider_adapter.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/novel/novel_agents.dart';
import 'package:newmove/features/shot/shot_agents.dart';
import 'package:newmove/features/script/script_agents.dart';

void main() {
  group('StoryboardTeam（M42）', () {
    late AppDatabase db;
    late StoryboardTeam team;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      final resolver = PromptResolver(db.promptOverrideDao);
      final adapter = LlmProviderAdapter();
      final director = ShotAgents(adapter: adapter, resolver: resolver);
      final writer = ScriptAgents(adapter: adapter, resolver: resolver);
      final reviewer = NovelAgents(adapter: adapter, resolver: resolver);
      team = StoryboardTeam(
        director: director,
        writer: writer,
        reviewer: reviewer,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('members 包含三个成员', () {
      expect(team.members, hasLength(3));
      expect(team.members, contains('director'));
      expect(team.members, contains('writer'));
      expect(team.members, contains('reviewer'));
    });

    test('knowledge 非空', () {
      expect(team.knowledge, isNotEmpty);
      expect(team.knowledge, contains('剧本改编'));
      expect(team.knowledge, contains('分镜导演'));
      expect(team.knowledge, contains('质量审校'));
    });
  });
}
