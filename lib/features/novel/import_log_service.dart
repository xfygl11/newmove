import 'dart:convert';

import '../../data/app_database.dart';
import '../../data/daos/import_log_dao.dart';

/// 导入日志服务（M35）。
///
/// 包装 DAO，提供按步骤记录导入过程的便捷 API。
class ImportLogService {
  final ImportLogDao _logDao;

  ImportLogService({required this._logDao});

  /// 记录一步导入过程。
  Future<int> record({
    required String step,
    required bool success,
    String message = '',
    Map<String, dynamic>? metadata,
    int? projectId,
  }) {
    return _logDao.insertLog(
      step: step,
      status: success ? 'success' : 'failed',
      message: message,
      metadata: metadata != null ? jsonEncode(metadata) : '{}',
      projectId: projectId,
    );
  }

  /// 记录导入开始（读取步骤）。
  Future<int> recordRead({
    required bool success,
    String message = '',
    int? projectId,
  }) {
    return record(
      step: 'read',
      success: success,
      message: message,
      projectId: projectId,
    );
  }

  /// 记录文本清洗步骤。
  Future<int> recordClean({
    required bool success,
    String message = '',
    int? projectId,
  }) {
    return record(
      step: 'decode',
      success: success,
      message: message,
      projectId: projectId,
    );
  }

  /// 记录标题提取步骤。
  Future<int> recordTitle({
    required bool success,
    String message = '',
    String? title,
    int? projectId,
  }) {
    return record(
      step: 'title',
      success: success,
      message: message,
      metadata: title != null ? {'title': title} : null,
      projectId: projectId,
    );
  }

  /// 记录内容切片步骤。
  Future<int> recordSlice({
    required bool success,
    String message = '',
    int? wordCount,
    int? projectId,
  }) {
    return record(
      step: 'slice',
      success: success,
      message: message,
      metadata: wordCount != null ? {'wordCount': wordCount} : null,
      projectId: projectId,
    );
  }

  /// 记录提交步骤（落库）。
  Future<int> recordCommit({
    required bool success,
    String message = '',
    int? chapterId,
    int? projectId,
  }) {
    return record(
      step: 'commit',
      success: success,
      message: message,
      metadata: chapterId != null ? {'chapterId': chapterId} : null,
      projectId: projectId,
    );
  }

  /// 获取某项目的导入日志。
  Future<List<ImportLog>> listByProject(int projectId, {int limit = 50}) {
    return _logDao.listByProject(projectId, limit: limit);
  }

  /// 获取全局导入日志。
  Future<List<ImportLog>> listGlobal({int limit = 50}) {
    return _logDao.listGlobal(limit: limit);
  }

  /// 删除某项目的全部导入日志。
  Future<void> deleteByProject(int projectId) {
    return _logDao.deleteByProject(projectId);
  }
}
