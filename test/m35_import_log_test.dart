import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmove/data/app_database.dart';
import 'package:newmove/data/daos/import_log_dao.dart';
import 'package:newmove/data/tables/tables.dart';
import 'package:newmove/features/novel/import_log_service.dart';

void main() {
  late AppDatabase db;
  late ImportLogDao logDao;
  late ImportLogService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    logDao = db.importLogDao;
    service = ImportLogService(logDao: logDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('ImportLogDao', () {
    test('insertLog 创建日志', () async {
      final id = await logDao.insertLog(
        step: 'read',
        status: 'success',
        message: '文件读取成功',
      );
      expect(id, greaterThan(0));
    });

    test('listByProject 获取项目日志', () async {
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试'),
      );

      await logDao.insertLog(
        step: 'read',
        status: 'success',
        projectId: projectId,
      );
      await logDao.insertLog(
        step: 'decode',
        status: 'success',
        projectId: projectId,
      );

      final logs = await logDao.listByProject(projectId);
      expect(logs, hasLength(2));
    });

    test('listGlobal 获取全局日志', () async {
      await logDao.insertLog(step: 'read', status: 'success');
      await logDao.insertLog(step: 'decode', status: 'success');

      final logs = await logDao.listGlobal();
      expect(logs, hasLength(2));
    });

    test('deleteByProject 删除项目日志', () async {
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试'),
      );

      await logDao.insertLog(
        step: 'read',
        status: 'success',
        projectId: projectId,
      );
      await logDao.deleteByProject(projectId);

      final logs = await logDao.listByProject(projectId);
      expect(logs, isEmpty);
    });
  });

  group('ImportLogService', () {
    test('record 记录步骤', () async {
      final id = await service.record(
        step: 'read',
        success: true,
        message: '读取成功',
      );
      expect(id, greaterThan(0));
    });

    test('recordRead 记录读取步骤', () async {
      final id = await service.recordRead(success: true);
      expect(id, greaterThan(0));
    });

    test('recordClean 记录清洗步骤', () async {
      final id = await service.recordClean(success: true);
      expect(id, greaterThan(0));
    });

    test('recordTitle 记录标题提取步骤', () async {
      final id = await service.recordTitle(
        success: true,
        title: '测试标题',
      );
      expect(id, greaterThan(0));
    });

    test('recordSlice 记录内容切片步骤', () async {
      final id = await service.recordSlice(
        success: true,
        wordCount: 1000,
      );
      expect(id, greaterThan(0));
    });

    test('recordCommit 记录提交步骤', () async {
      final id = await service.recordCommit(
        success: true,
        chapterId: 1,
      );
      expect(id, greaterThan(0));
    });

    test('record 记录失败步骤', () async {
      final id = await service.record(
        step: 'read',
        success: false,
        message: '文件不存在',
      );
      expect(id, greaterThan(0));

      final logs = await logDao.listGlobal();
      expect(logs.single.status, 'failed');
    });

    test('listByProject 获取项目日志', () async {
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试'),
      );

      await service.record(step: 'read', success: true, projectId: projectId);
      await service.record(step: 'decode', success: true, projectId: projectId);

      final logs = await service.listByProject(projectId);
      expect(logs, hasLength(2));
    });

    test('deleteByProject 删除项目日志', () async {
      final projectId = await db.projectDao.insertProject(
        ProjectsCompanion.insert(name: '测试'),
      );

      await service.record(step: 'read', success: true, projectId: projectId);
      await service.deleteByProject(projectId);

      final logs = await service.listByProject(projectId);
      expect(logs, isEmpty);
    });
  });
}
