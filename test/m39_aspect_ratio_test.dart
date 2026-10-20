import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/features/script/script_service.dart';
import 'package:newmove/features/script/script_agents.dart';
import 'package:newmove/agent/prompt_resolver.dart';
import 'package:newmove/core/network/llm_provider_adapter.dart';

class _FakeAdapter implements LlmProviderAdapter {
  @override
  Stream<String> chatStream({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<({ChatRole role, String content})> messages,
    double temperature = 0.8,
  }) async* {}

  @override
  Future<String> chat({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<({ChatRole role, String content})> messages,
    double temperature = 0.8,
  }) async {
    return '{}';
  }

  @override
  Future<void> testConnection({
    required String baseUrl,
    required String apiKey,
    required String model,
  }) async {}
}

void main() {
  late AppDatabase db;
  late ScriptService service;
  late int scriptId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    // 创建项目、书籍、剧本。
    final projectId = await db.projectDao.insertProject(
      ProjectsCompanion.insert(name: '测试'),
    );
    final bookId = await db.novelDao.insertBook(
      NovelBooksCompanion.insert(
        projectId: projectId,
        title: '测试书籍',
      ),
    );
    scriptId = await db.scriptDao.insert(
      ScriptsCompanion.insert(
        bookId: bookId,
        title: '测试剧本',
      ),
    );

    service = ScriptService(
      db: db,
      scriptDao: db.scriptDao,
      sceneDao: db.sceneDao,
      revisionDao: db.scriptRevisionDao,
      novelDao: db.novelDao,
      truthDao: db.truthFileDao,
      cascadeDao: db.cascadeDao,
      agents: ScriptAgents(
        adapter: _FakeAdapter(),
        resolver: PromptResolver(db.promptOverrideDao),
      ),
      assetDao: db.assetDao,
      shotDao: db.shotDao,
      attemptDao: db.generationAttemptDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ScriptService aspectRatio（M39）', () {
    test('effectiveAspectRatio 空值返回默认 16:9', () async {
      final ratio = await service.effectiveAspectRatio(scriptId);
      expect(ratio, '16:9');
    });

    test('effectiveAspectRatio 有值返回该值', () async {
      final script = (await db.scriptDao.find(scriptId))!;
      await db.scriptDao.updateRow(script.copyWith(aspectRatio: const Value('9:16')));

      final ratio = await service.effectiveAspectRatio(scriptId);
      expect(ratio, '9:16');
    });

    test('effectiveAspectRatio 空白字符串返回默认', () async {
      final script = (await db.scriptDao.find(scriptId))!;
      await db.scriptDao.updateRow(script.copyWith(aspectRatio: const Value('  ')));

      final ratio = await service.effectiveAspectRatio(scriptId);
      expect(ratio, '16:9');
    });

    test('updateAspectRatio 更新比例', () async {
      await service.updateAspectRatio(scriptId, '1:1');

      final script = await db.scriptDao.find(scriptId);
      expect(script?.aspectRatio, '1:1');
    });

    test('updateAspectRatio 不存在剧本抛错', () async {
      expect(
        () => service.updateAspectRatio(999, '16:9'),
        throwsA(isA<StateError>()),
      );
    });

    test('effectiveAspectRatio 不存在剧本返回默认', () async {
      final ratio = await service.effectiveAspectRatio(999);
      expect(ratio, '16:9');
    });

    test('updateAspectRatio 更新后 effectiveAspectRatio 返回新值', () async {
      await service.updateAspectRatio(scriptId, '9:16');
      final ratio = await service.effectiveAspectRatio(scriptId);
      expect(ratio, '9:16');
    });
  });
}
