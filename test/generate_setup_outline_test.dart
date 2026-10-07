import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/agent/active_llm.dart';
import 'package:newmove/agent/prompt_resolver.dart';
import 'package:newmove/core/network/llm_provider_adapter.dart';
import 'package:newmove/core/network/protocols.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/novel/novel_agents.dart';
import 'package:newmove/features/novel/novel_service.dart';
import 'package:newmove/features/provider_config/provider_models.dart';

/// 假 LLM 适配器：返回预设 JSON，验证 generateSetup 的 outline 落库链路。
class _FakeAdapter extends LlmProviderAdapter {
  _FakeAdapter(this.reply);

  final String reply;

  @override
  Future<String> chat({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<({ChatRole role, String content})> messages,
    double temperature = 0.8,
  }) async => reply;
}

ActiveLlm _llm() => ActiveLlm(
  provider: ProviderConfig(
    id: 'test',
    group: 'llm',
    label: 'test',
    baseUrl: 'https://example.com/v1',
    protocol: Protocols.openaiCompletions,
    models: '[]',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  ),
  apiKey: 'test-key',
  model: const ProviderModel(id: 'gpt-test', label: 'test model'),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late int bookId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '测试项目'),
    );
    bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(projectId: projectId, title: '测试书'),
    );
  });

  tearDown(() async => db.close());

  NovelService serviceWith(String reply) {
    final agents = NovelAgents(
      adapter: _FakeAdapter(reply),
      resolver: PromptResolver(db.promptOverrideDao),
    );
    return NovelService(
      novelDao: db.novelDao,
      truthDao: db.truthFileDao,
      revisionDao: db.chapterRevisionDao,
      agents: agents,
      attemptDao: db.generationAttemptDao,
    );
  }

  test('AI 返回含大纲 JSON 时 outline 正确落库', () async {
    final reply = '''
```json
{
  "premise": "少年觉醒",
  "world": "废土",
  "characters": [{"name": "主角", "role": "主角"}],
  "styleGuide": "冷峻",
  "outline": "第 1 章：觉醒\\n主角在废墟中醒来。",
  "proposals": []
}
```
''';
    final svc = serviceWith(reply);
    await svc.generateSetup(
      bookId: bookId,
      idea: '创意',
      genre: '玄幻',
      llm: _llm(),
    );

    final book = await db.novelDao.findBook(bookId);
    expect(book!.outline, isNotNull);
    expect(book.outline, contains('第 1 章：觉醒'));
  });

  test('AI 返回 JSON 无 outline 字段时落库为空串', () async {
    final reply = '''
{
  "premise": "少年觉醒",
  "world": "废土",
  "characters": [],
  "styleGuide": "冷峻",
  "proposals": []
}
''';
    final svc = serviceWith(reply);
    await svc.generateSetup(
      bookId: bookId,
      idea: '创意',
      genre: '玄幻',
      llm: _llm(),
    );

    final book = await db.novelDao.findBook(bookId);
    expect(book!.outline, isEmpty);
  });
}
