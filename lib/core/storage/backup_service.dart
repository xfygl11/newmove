import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/app_database.dart';
import '../../data/tables/tables.dart';

/// 项目导出/导入服务（M7 T8.1）。
///
/// 导出：项目全量表行序列化为 JSON，连同 assets/、videos/ 下被引用的
/// 媒体文件打包 zip。供应商配置随包导出，但 **API Key 永不入包**
/// （Key 存安全存储，T8.5）。
/// 导入：解析 zip，全部插入为新行（不动既有数据），旧外键 id 映射为
/// 新 id 回填；媒体文件解到应用文档目录后重写绝对路径。
class BackupService {
  BackupService({required this.db});

  final AppDatabase db;

  // ---- 导出 ----

  /// 导出单个项目为 zip，返回文件路径。
  Future<String> exportProject(int projectId) async {
    final data = await _collect(projectId);

    final archive = Archive();
    final jsonBytes =
        utf8.encode(const JsonEncoder.withIndent('  ').convert(data));
    archive.addFile(ArchiveFile('backup.json', jsonBytes.length, jsonBytes));

    // 媒体文件按相对路径打包。
    final docDir = await getApplicationDocumentsDirectory();
    for (final rel in (data['mediaFiles'] as List<String>)) {
      final f = File('${docDir.path}/$rel');
      if (!await f.exists()) continue;
      final bytes = await f.readAsBytes();
      archive.addFile(ArchiveFile(rel, bytes.length, bytes));
    }

    final project = await db.projectDao.findById(projectId);
    final safeName =
        (project?.name ?? 'project').replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final outFile =
        File('${(await getTemporaryDirectory()).path}/newmove_backup_$safeName.zip');
    await outFile.writeAsBytes(ZipEncoder().encode(archive));
    return outFile.path;
  }

  /// 收集项目全量数据（表行 toJson；附被引用媒体相对路径清单）。
  Future<Map<String, dynamic>> _collect(int projectId) async {
    final project = await db.projectDao.findById(projectId);
    if (project == null) throw StateError('项目不存在：$projectId');

    // 项目（示例工程）下单书模型：listByProject 未提供，走 watchBookByProject
    // 的一次性等价查询。
    final books = <NovelBook>[
      ?await db.novelDao.findBookByProject(projectId),
    ];
    final mediaFiles = <String>{};

    // ---- 书 → 章节 / 版本 / 真相文件 ----
    final booksJson = <Map<String, dynamic>>[];
    final chaptersJson = <Map<String, dynamic>>[];
    final chapterRevisionsJson = <Map<String, dynamic>>[];
    final truthsJson = <Map<String, dynamic>>[];
    for (final b in books) {
      booksJson.add(b.toJson());
      for (final c in await db.novelDao.listChapters(b.id)) {
        chaptersJson.add(c.toJson());
        for (final r in await db.chapterRevisionDao.listByChapter(c.id)) {
          chapterRevisionsJson.add(r.toJson());
        }
      }
      for (final t in await db.truthFileDao.listByBook(b.id)) {
        truthsJson.add(t.toJson());
      }
    }

    // ---- 剧本链：script → scene → beat / asset / shot 链 ----
    final scriptsJson = <Map<String, dynamic>>[];
    final scenesJson = <Map<String, dynamic>>[];
    final beatsJson = <Map<String, dynamic>>[];
    final assetsJson = <Map<String, dynamic>>[];
    final shotsJson = <Map<String, dynamic>>[];
    final shotFramesJson = <Map<String, dynamic>>[];
    final assetRefsJson = <Map<String, dynamic>>[];
    final videoTasksJson = <Map<String, dynamic>>[];
    final scriptRevisionsJson = <Map<String, dynamic>>[];

    for (final b in books) {
      for (final s in await db.scriptDao.listByBook(b.id)) {
        scriptsJson.add(s.toJson());
        for (final sc in await db.sceneDao.listByScript(s.id)) {
          scenesJson.add(sc.toJson());
          for (final beat in await db.beatDao.listByScene(sc.id)) {
            beatsJson.add(beat.toJson());
          }
        }
        for (final a in await db.assetDao.listByScript(s.id)) {
          assetsJson.add(a.toJson());
          _collectMedia(mediaFiles, a.imagePath);
        }
        for (final sh in await db.shotDao.listByScript(s.id)) {
          shotsJson.add(sh.toJson());
          _collectMedia(mediaFiles, sh.outputPath);
          for (final f in await db.shotFrameDao.listByShot(sh.id)) {
            shotFramesJson.add(f.toJson());
          }
          for (final r in await db.assetRefDao.listByShot(sh.id)) {
            assetRefsJson.add(r.toJson());
          }
          for (final v in await db.videoTaskDao.listByShot(sh.id)) {
            videoTasksJson.add(v.toJson());
          }
        }
        for (final r in await db.scriptRevisionDao.listByScript(s.id)) {
          scriptRevisionsJson.add(r.toJson());
        }
      }
    }

    // ---- 供应商配置（不含 Key） ----
    final providersJson =
        [for (final p in await db.providerDao.listAll()) p.toJson()];

    return {
      'formatVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'project': project.toJson(),
      'books': booksJson,
      'chapters': chaptersJson,
      'chapterRevisions': chapterRevisionsJson,
      'truthFiles': truthsJson,
      'scripts': scriptsJson,
      'scenes': scenesJson,
      'beats': beatsJson,
      'assets': assetsJson,
      'shots': shotsJson,
      'shotFrames': shotFramesJson,
      'assetRefs': assetRefsJson,
      'videoTasks': videoTasksJson,
      'scriptRevisions': scriptRevisionsJson,
      'providers': providersJson,
      'mediaFiles': mediaFiles.toList(),
    };
  }

  void _collectMedia(Set<String> out, String? path) {
    if (path == null || path.isEmpty) return;
    final i = path.indexOf('/files/');
    if (i >= 0) {
      out.add(path.substring(i + '/files/'.length));
    }
  }

  // ---- 导入 ----

  /// 从 zip 恢复项目，返回新项目 id。
  Future<int> importProject(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final jsonFile = archive.findFile('backup.json');
    if (jsonFile == null) throw const FormatException('备份包缺少 backup.json');
    final data = (jsonDecode(utf8.decode(jsonFile.content as List<int>))
            as Map)
        .cast<String, dynamic>();

    // 解压媒体文件到应用文档目录，记录 相对路径 → 新绝对路径。
    final docDir = await getApplicationDocumentsDirectory();
    final mediaMap = <String, String>{};
    for (final f in archive.files) {
      if (f.name == 'backup.json') continue;
      final out = File('${docDir.path}/${f.name}');
      await out.parent.create(recursive: true);
      await out.writeAsBytes(f.content as List<int>);
      mediaMap[f.name] = out.path;
    }

    return db.transaction(() async {
      final idMap = <String, Map<int, int>>{};

      // 通用插入：JSON 行 → snake_case 列 → RawValuesInsertable<T>。
      Future<int> insertRows<T extends Table, D>(
        TableInfo<T, D> table,
        String key,
        Map<String, Object?> Function(Map<String, dynamic>) transform,
      ) async {
        final rows =
            (data[key] as List? ?? const []).cast<Map<String, dynamic>>();
        for (final row in rows) {
          final cols = <String, Expression<Object>>{};
          for (final e in transform(row).entries) {
            cols[_snake(e.key)] = _expr(e.value);
          }
          final newId =
              await db.into(table).insert(RawValuesInsertable<D>(cols));
          (idMap[key] ??= {})[row['id'] as int] = newId;
        }
        return rows.length;
      }

      // 项目（顶层无外键映射，单独插入拿 id）。
      final projCols = <String, Expression<Object>>{};
      for (final e in (data['project'] as Map<String, dynamic>).entries) {
        if (e.key == 'id') continue;
        projCols[_snake(e.key)] = _expr(e.value);
      }
      final projectId =
          await db.into(db.projects).insert(RawValuesInsertable<Project>(projCols));

      // ---- 需要跨表 id 映射的表，显式构造 transform ----
      int mapped(String key, dynamic old) => idMap[key]?[old as int] ?? 0;

      await insertRows<NovelBooks, NovelBook>(db.novelBooks, 'books', (r) {
        final remapped = _remap(r, const {});
        remapped['projectId'] = projectId;
        return remapped;
      });
      await insertRows<Chapters, Chapter>(db.chapters, 'chapters', (r) {
        final remapped = _remap(r, const {});
        remapped['bookId'] = mapped('books', r['bookId']);
        return remapped;
      });
      await insertRows<ChapterRevisions, ChapterRevision>(
          db.chapterRevisions, 'chapterRevisions', (r) {
        final remapped = _remap(r, const {});
        remapped['chapterId'] = mapped('chapters', r['chapterId']);
        return remapped;
      });
      await insertRows<TruthFiles, TruthFile>(db.truthFiles, 'truthFiles', (r) {
        final remapped = _remap(r, const {});
        remapped['bookId'] = mapped('books', r['bookId']);
        return remapped;
      });
      await insertRows<Scripts, Script>(db.scripts, 'scripts', (r) {
        final remapped = _remap(r, const {});
        remapped['bookId'] = mapped('books', r['bookId']);
        return remapped;
      });
      await insertRows<Scenes, Scene>(db.scenes, 'scenes', (r) {
        final remapped = _remap(r, const {});
        remapped['scriptId'] = mapped('scripts', r['scriptId']);
        return remapped;
      });
      await insertRows<Beats, Beat>(db.beats, 'beats', (r) {
        final remapped = _remap(r, const {});
        remapped['sceneId'] = mapped('scenes', r['sceneId']);
        return remapped;
      });
      await insertRows<Assets, Asset>(db.assets, 'assets', (r) {
        final remapped = _remap(r, const {});
        remapped['scriptId'] = mapped('scripts', r['scriptId']);
        if (r['variantOf'] != null) {
          remapped['variantOf'] = mapped('assets', r['variantOf']);
        }
        remapped['imagePath'] = _media(r['imagePath'], mediaMap);
        return remapped;
      });
      await insertRows<Shots, Shot>(db.shots, 'shots', (r) {
        final remapped = _remap(r, const {});
        remapped['scriptId'] = mapped('scripts', r['scriptId']);
        remapped['outputPath'] = _media(r['outputPath'], mediaMap);
        return remapped;
      });
      await insertRows<ShotFrames, ShotFrame>(db.shotFrames, 'shotFrames', (r) {
        final remapped = _remap(r, const {});
        remapped['shotId'] = mapped('shots', r['shotId']);
        return remapped;
      });
      await insertRows<AssetRefs, AssetRef>(db.assetRefs, 'assetRefs', (r) {
        final remapped = _remap(r, const {});
        remapped['shotId'] = mapped('shots', r['shotId']);
        remapped['assetId'] = mapped('assets', r['assetId']);
        return remapped;
      });
      await insertRows<VideoTasks, VideoTask>(db.videoTasks, 'videoTasks', (r) {
        final remapped = _remap(r, const {});
        remapped['shotId'] = mapped('shots', r['shotId']);
        return remapped;
      });
      await insertRows<ScriptRevisions, ScriptRevision>(
          db.scriptRevisions, 'scriptRevisions', (r) {
        final remapped = _remap(r, const {});
        remapped['scriptId'] = mapped('scripts', r['scriptId']);
        return remapped;
      });

      // 供应商配置：同 id 覆盖（保留本地安全存储中的 Key 绑定）。
      for (final row in (data['providers'] as List? ?? const [])
          .cast<Map<String, dynamic>>()) {
        await db.into(db.providerConfigs).insert(
              RawValuesInsertable<ProviderConfig>({
                for (final e in row.entries)
                  if (e.key != 'id') _snake(e.key): _expr(e.value),
                'id': Variable(row['id'] as String),
              }),
              onConflict: DoUpdate(
                (_) => RawValuesInsertable<ProviderConfig>({
                  for (final e in row.entries)
                    if (e.key != 'id' && e.key != 'createdAt')
                      _snake(e.key): _expr(e.value),
                  'updated_at': Variable(DateTime.now()),
                }),
                target: [db.providerConfigs.id],
              ),
            );
      }

      return projectId;
    });
  }

  /// 行副本：排除 id、应用显式映射（值为旧 id 的键在 transform 内重写）。
  Map<String, Object?> _remap(
    Map<String, dynamic> row,
    Map<String, Object?> overrides,
  ) {
    final copy = <String, Object?>{...row}..remove('id');
    copy.addAll(overrides);
    return copy;
  }

  /// 媒体路径重写：包内相对路径命中则换新绝对路径。
  Object? _media(Object? old, Map<String, String> mediaMap) {
    if (old is String && mediaMap.containsKey(old)) return mediaMap[old];
    return old;
  }

  /// JSON 值 → drift 表达式。
  ///
  /// drift 默认 toJson：DateTime → epoch millis int（探测：>10^12），
  /// bool → int。导入时把毫秒数还原为 DateTime 交给 Variable。
  /// ISO 字符串分支兜底旧格式包。
  Expression<Object> _expr(Object? v) {
    if (v == null) return const CustomExpression('NULL');
    if (v is bool) return Variable(v ? 1 : 0);
    if (v is int && v > 1000000000000) {
      return Variable(DateTime.fromMillisecondsSinceEpoch(v));
    }
    if (v is String && _isoPattern.hasMatch(v)) {
      final dt = DateTime.tryParse(v);
      if (dt != null) return Variable(dt);
    }
    return Variable(v);
  }

  static final _isoPattern = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}');

  /// camelCase 字段名 → snake_case 列名（drift 默认命名）。
  String _snake(String name) {
    final lowered = name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (m) => '_${m.group(1)!.toLowerCase()}',
    );
    // 仅去除首字符产生的前导下划线（如 GlobalSeq → _global_seq）。
    return lowered.startsWith('_') ? lowered.substring(1) : lowered;
  }
}
