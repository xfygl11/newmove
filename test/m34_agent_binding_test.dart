import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/core/storage/secure_key_store.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/data/daos/agent_binding_dao.dart';
import 'package:newmove/data/daos/provider_dao.dart';
import 'package:newmove/features/provider_config/agent_binding_service.dart';

void main() {
  late AppDatabase db;
  late AgentBindingDao bindingDao;
  late ProviderDao providerDao;
  late SecureKeyStore keyStore;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    bindingDao = db.agentBindingDao;
    providerDao = db.providerDao;
    keyStore = SecureKeyStore();
  });

  tearDown(() async {
    await db.close();
  });

  group('AgentBindingDao', () {
    test('insertBinding 创建绑定', () async {
      // 先创建项目
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试项目'),
      );

      final id = await bindingDao.insertBinding(
        projectId: projectId,
        category: 'llm',
        agentId: 'provider-123',
      );
      expect(id, greaterThan(0));

      final bindings = await bindingDao.listByProject(projectId);
      expect(bindings, hasLength(1));
      expect(bindings.single.category, 'llm');
      expect(bindings.single.agentId, 'provider-123');
    });

    test('findByProjectAndCategory 查找绑定', () async {
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试'),
      );

      await bindingDao.insertBinding(
        projectId: projectId,
        category: 'llm',
        agentId: 'provider-123',
      );
      await bindingDao.insertBinding(
        projectId: projectId,
        category: 'image',
        agentId: 'provider-456',
      );

      final llmBinding = await bindingDao.findByProjectAndCategory(
        projectId,
        'llm',
      );
      expect(llmBinding, isNotNull);
      expect(llmBinding!.agentId, 'provider-123');

      final imageBinding = await bindingDao.findByProjectAndCategory(
        projectId,
        'image',
      );
      expect(imageBinding, isNotNull);
      expect(imageBinding!.agentId, 'provider-456');

      final notFound = await bindingDao.findByProjectAndCategory(
        projectId,
        'video',
      );
      expect(notFound, isNull);
    });

    test('updateBinding 更新 agentId', () async {
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试'),
      );

      final id = await bindingDao.insertBinding(
        projectId: projectId,
        category: 'llm',
        agentId: 'old-provider',
      );
      await bindingDao.updateBinding(id, 'new-provider');

      final bindings = await bindingDao.listByProject(projectId);
      expect(bindings.single.agentId, 'new-provider');
    });

    test('deleteBinding 删除绑定', () async {
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试'),
      );

      final id = await bindingDao.insertBinding(
        projectId: projectId,
        category: 'llm',
        agentId: 'provider-123',
      );
      await bindingDao.deleteBinding(id);

      final bindings = await bindingDao.listByProject(projectId);
      expect(bindings, isEmpty);
    });

    test('deleteByProject 删除项目的所有绑定', () async {
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试'),
      );

      await bindingDao.insertBinding(
        projectId: projectId,
        category: 'llm',
        agentId: 'provider-1',
      );
      await bindingDao.insertBinding(
        projectId: projectId,
        category: 'image',
        agentId: 'provider-2',
      );
      await bindingDao.deleteByProject(projectId);

      final bindings = await bindingDao.listByProject(projectId);
      expect(bindings, isEmpty);
    });

    test('唯一约束：同项目同类别只允许一条绑定', () async {
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试'),
      );

      await bindingDao.insertBinding(
        projectId: projectId,
        category: 'llm',
        agentId: 'provider-1',
      );

      expect(
        () => bindingDao.insertBinding(
          projectId: projectId,
          category: 'llm',
          agentId: 'provider-2',
        ),
        throwsA(anything),
      );
    });
  });

  group('AgentBindingService', () {
    test('createBinding 创建绑定', () async {
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试'),
      );
      final service = AgentBindingService(
        bindingDao: bindingDao,
        providerDao: providerDao,
        keyStore: keyStore,
      );

      final id = await service.createBinding(
        projectId: projectId,
        category: 'llm',
        agentId: 'provider-123',
      );
      expect(id, greaterThan(0));
    });

    test('listBindings 获取项目的全部绑定', () async {
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试'),
      );
      final service = AgentBindingService(
        bindingDao: bindingDao,
        providerDao: providerDao,
        keyStore: keyStore,
      );

      await service.createBinding(
        projectId: projectId,
        category: 'llm',
        agentId: 'provider-1',
      );
      await service.createBinding(
        projectId: projectId,
        category: 'image',
        agentId: 'provider-2',
      );

      final bindings = await service.listBindings(projectId);
      expect(bindings, hasLength(2));
    });

    test('deleteBinding 删除绑定', () async {
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试'),
      );
      final service = AgentBindingService(
        bindingDao: bindingDao,
        providerDao: providerDao,
        keyStore: keyStore,
      );

      final id = await service.createBinding(
        projectId: projectId,
        category: 'llm',
        agentId: 'provider-123',
      );
      await service.deleteBinding(id);

      final bindings = await service.listBindings(projectId);
      expect(bindings, isEmpty);
    });

    test('deleteByProject 删除项目的所有绑定', () async {
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试'),
      );
      final service = AgentBindingService(
        bindingDao: bindingDao,
        providerDao: providerDao,
        keyStore: keyStore,
      );

      await service.createBinding(
        projectId: projectId,
        category: 'llm',
        agentId: 'provider-1',
      );
      await service.createBinding(
        projectId: projectId,
        category: 'image',
        agentId: 'provider-2',
      );
      await service.deleteByProject(projectId);

      final bindings = await service.listBindings(projectId);
      expect(bindings, isEmpty);
    });

    test('resolveLlm 无绑定时回落全局', () async {
      final service = AgentBindingService(
        bindingDao: bindingDao,
        providerDao: providerDao,
        keyStore: keyStore,
      );

      // 没有供应商配置时返回 null
      final result = await service.resolveLlm(projectId: 1);
      expect(result, isNull);
    });

    test('resolveImage 无绑定时回落全局', () async {
      final service = AgentBindingService(
        bindingDao: bindingDao,
        providerDao: providerDao,
        keyStore: keyStore,
      );

      final result = await service.resolveImage(projectId: 1);
      expect(result, isNull);
    });

    test('resolveVideo 无绑定时回落全局', () async {
      final service = AgentBindingService(
        bindingDao: bindingDao,
        providerDao: providerDao,
        keyStore: keyStore,
      );

      final result = await service.resolveVideo(projectId: 1);
      expect(result, isNull);
    });
  });
}
