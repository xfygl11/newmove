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
    final archive = await _buildArchive(data, null);
    final project = await db.projectDao.findById(projectId);
    final safeName = (project?.name ?? 'project').replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );
    final outFile = File(
      '${(await getTemporaryDirectory()).path}/newmove_backup_$safeName.zip',
    );
    await outFile.writeAsBytes(ZipEncoder().encode(archive));
    return outFile.path;
  }

  /// 全库导出：所有项目 + 供应商配置 + 被引用媒体，打包为单个 zip。
  Future<String> exportAll() async {
    final data = await _collectAll();
    final archive = await _buildArchive(data, 'full');
    final outFile = File(
      '${(await getTemporaryDirectory()).path}/newmove_full_backup_${DateTime.now().millisecondsSinceEpoch ~/ 1000}.zip',
    );
    await outFile.writeAsBytes(ZipEncoder().encode(archive));
    return outFile.path;
  }

  Future<Archive> _buildArchive(
    Map<String, dynamic> data,
    String? scope,
  ) async {
    final archive = Archive();
    final jsonBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(data),
    );
    archive.addFile(ArchiveFile('backup.json', jsonBytes.length, jsonBytes));
    final docDir = await getApplicationDocumentsDirectory();
    for (final rel in (data['mediaFiles'] as List<String>)) {
      final f = File('${docDir.path}/$rel');
      if (!await f.exists()) continue;
      final bytes = await f.readAsBytes();
      archive.addFile(ArchiveFile(rel, bytes.length, bytes));
    }
    return archive;
  }

  /// 收集全部项目数据（全库备份用）。
  Future<Map<String, dynamic>> _collectAll() async {
    final projects = await db.projectDao.listAll();
    final mediaFiles = <String>{};

    final booksJson = <Map<String, dynamic>>[];
    final chaptersJson = <Map<String, dynamic>>[];
    final chapterRevisionsJson = <Map<String, dynamic>>[];
    final truthsJson = <Map<String, dynamic>>[];
    final scriptsJson = <Map<String, dynamic>>[];
    final scenesJson = <Map<String, dynamic>>[];
    final beatsJson = <Map<String, dynamic>>[];
    final assetsJson = <Map<String, dynamic>>[];
    final shotsJson = <Map<String, dynamic>>[];
    final shotFramesJson = <Map<String, dynamic>>[];
    final assetRefsJson = <Map<String, dynamic>>[];
    final videoTasksJson = <Map<String, dynamic>>[];
    final scriptRevisionsJson = <Map<String, dynamic>>[];

    for (final p in projects) {
      final books = <NovelBook>[?await db.novelDao.findBookByProject(p.id)];
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
              _collectMedia(mediaFiles, v.outputPath);
            }
          }
          for (final r in await db.scriptRevisionDao.listByScript(s.id)) {
            scriptRevisionsJson.add(r.toJson());
          }
        }
      }
    }

    final providersJson = [
      for (final p in await db.providerDao.listAll()) p.toJson(),
    ];

    return {
      'formatVersion': 1,
      'scope': 'full',
      'exportedAt': DateTime.now().toIso8601String(),
      'projects': [for (final p in projects) p.toJson()],
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

  /// 收集项目全量数据（表行 toJson；附被引用媒体相对路径清单）。
  Future<Map<String, dynamic>> _collect(int projectId) async {
    final project = await db.projectDao.findById(projectId);
    if (project == null) throw StateError('项目不存在：$projectId');

    // 项目（示例工程）下单书模型：listByProject 未提供，走 watchBookByProject
    // 的一次性等价查询。
    final books = <NovelBook>[?await db.novelDao.findBookByProject(projectId)];
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
            _collectMedia(mediaFiles, v.outputPath);
          }
        }
        for (final r in await db.scriptRevisionDao.listByScript(s.id)) {
          scriptRevisionsJson.add(r.toJson());
        }
      }
    }

    // ---- 供应商配置（不含 Key） ----
    final providersJson = [
      for (final p in await db.providerDao.listAll()) p.toJson(),
    ];

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

  // ---- 冲突检测（P2-11） ----

  /// 备份包导入上限 500MB（备份含被引用媒体，超大包全量载入内存有 OOM 风险）。
  static const int maxImportBytes = 500 * 1024 * 1024;

  /// 解压后总量上限。PNG/MP4 几乎不可压缩，中央目录声明的解压总量远大于压缩包时
  /// 是典型的 zip bomb：解压前判断，避免写出几个 GB 后再 OOM。
  static const int maxExtractedBytes = 2 * 1024 * 1024 * 1024;

  /// 校验备份包大小，超限抛 [StateError]（先校验再读取，避免全量读入内存）。
  static Future<void> _guardImportSize(String zipPath) async {
    final file = File(zipPath);
    if (!file.existsSync()) throw StateError('文件不存在：$zipPath');
    if (file.lengthSync() > maxImportBytes) {
      throw StateError('备份包超过 500MB 上限，请只导出部分项目后重试');
    }
  }

  /// 流式读取 zip：只解析中央目录建立索引，各条目内容按需解压。
  ///
  /// 替代旧的 `readAsBytes` + `decodeBytes`——那份写法让压缩包原始字节与解压后
  /// 字节同时驻留内存，两个 500MB 包直接突破 358MiB 预算。`input.close()` 必须
  /// 调用，`ArchiveFile` 惰性引用该流的当前位置。
  Future<Archive> _openArchive(String zipPath) async {
    final input = InputFileStream(zipPath);
    try {
      return ZipDecoder().decodeStream(input);
    } finally {
      await input.close();
    }
  }

  /// 校验解压后总量（zip bomb 防护），同时顺带验证包可正常解析。
  Future<void> _guardExtractedSize(Archive archive) async {
    var total = 0;
    for (final f in archive.files) {
      if (f.name == 'backup.json') continue;
      total += f.size;
      if (total > maxExtractedBytes) {
        throw StateError('备份包解压后超过 2GB 上限，可能是损坏或异常的包，已拒绝导入');
      }
    }
  }

  /// 解析 zip 中的项目名列表（不写入 DB），用于导入前冲突提示。
  ///
  /// 返回包内所有项目名；单项目包返回 1 项，全库包返回 N 项。
  Future<List<String>> peekProjectNames(String zipPath) async {
    await _guardImportSize(zipPath);
    final archive = await _openArchive(zipPath);
    try {
      final jsonFile = archive.findFile('backup.json');
      if (jsonFile == null) {
        throw const FormatException('备份包缺少 backup.json');
      }
      final data = _decodeBackupJson(jsonFile.content as List<int>);
      if (data['scope'] == 'full' && data['projects'] != null) {
        return [
          for (final p
              in (data['projects'] as List).cast<Map<String, dynamic>>())
            p['name'] as String? ?? '',
        ];
      }
      return [
        (data['project'] as Map<String, dynamic>? ?? const {})['name']
                as String? ??
            '',
      ];
    } finally {
      archive.clearSync();
    }
  }

  /// 检查包内项目名是否已存在于本地，返回冲突项列表。
  Future<List<String>> findConflicts(String zipPath) async {
    final names = await peekProjectNames(zipPath);
    final existing = await db.projectDao.listAll();
    final existingNames = existing.map((p) => p.name.toLowerCase()).toSet();
    return [
      for (final n in names)
        if (n.isNotEmpty && existingNames.contains(n.toLowerCase())) n,
    ];
  }

  // ---- 导入 ----

  /// 从 zip 恢复项目，返回新项目 id。
  ///
  /// 支持单项目包（`project` 字段）与全库包（`projects` 列表字段，
  /// `scope: full`）。全库包中各子表行携带原始 `projectId`/`bookId` 等
  /// 外键，导入时按映射链重写。
  Future<int> importProject(String zipPath) async {
    await _guardImportSize(zipPath);
    final archive = await _openArchive(zipPath);
    var result = 0;
    try {
      result = await _importArchive(archive);
    } finally {
      archive.clearSync();
    }
    return result;
  }

  /// 解析包内 backup.json 并完成全部落盘与入库。
  Future<int> _importArchive(Archive archive) async {
    final jsonFile = archive.findFile('backup.json');
    if (jsonFile == null) throw const FormatException('备份包缺少 backup.json');
    final data = _decodeBackupJson(jsonFile.content as List<int>);
    await _guardExtractedSize(archive);

    // 解压媒体文件到应用文档目录，记录 相对路径 → 新绝对路径。
    final docDir = await getApplicationDocumentsDirectory();
    final mediaMap = <String, String>{};
    for (final f in archive.files) {
      if (f.name == 'backup.json') continue;
      final out = _resolveMediaPath(docDir, f.name);
      await out.parent.create(recursive: true);
      // 先查声明长度再写：超大条目不整体载入内存。
      if (f.size > maxImportBytes) {
        throw StateError('备份包内 ${f.name} 超过 500MB 上限，已拒绝导入');
      }
      await out.writeAsBytes(f.content as List<int>);
      mediaMap[f.name] = out.path;
    }

    final isFull = data['scope'] == 'full' && data['projects'] != null;

    return db.transaction(() async {
      final idMap = <String, Map<int, int>>{};

      // 通用插入：JSON 行 → snake_case 列 → RawValuesInsertable<T>。
      Future<int> insertRows<T extends Table, D>(
        TableInfo<T, D> table,
        String key,
        Map<String, Object?> Function(Map<String, dynamic>) transform,
      ) async {
        final rows = (data[key] as List? ?? const [])
            .cast<Map<String, dynamic>>();
        for (final row in rows) {
          final cols = <String, Expression<Object>>{};
          for (final e in transform(row).entries) {
            cols[_snake(e.key)] = _expr(e.value);
          }
          final newId = await db
              .into(table)
              .insert(RawValuesInsertable<D>(cols));
          (idMap[key] ??= {})[row['id'] as int] = newId;
        }
        return rows.length;
      }

      int mapped(String key, dynamic old) => idMap[key]?[old as int] ?? 0;

      // 插入项目行，返回第一个新 id（UI 提示用）。
      final int firstNewProjectId;
      if (isFull) {
        final projectsList = (data['projects'] as List)
            .cast<Map<String, dynamic>>();
        if (projectsList.isEmpty) {
          throw const FormatException('全库备份不包含任何项目');
        }
        final newProjectIds = <int>[];
        for (final prow in projectsList) {
          final cols = <String, Expression<Object>>{};
          for (final e in prow.entries) {
            if (e.key == 'id') continue;
            cols[_snake(e.key)] = _expr(e.value);
          }
          newProjectIds.add(
            await db
                .into(db.projects)
                .insert(RawValuesInsertable<Project>(cols)),
          );
        }
        idMap['projects'] = {
          for (var i = 0; i < projectsList.length; i++)
            (projectsList[i]['id'] as int): newProjectIds[i],
        };
        firstNewProjectId = newProjectIds.first;

        // 全库包：books 按原始 projectId 映射到新 projectId。
        await insertRows<NovelBooks, NovelBook>(db.novelBooks, 'books', (r) {
          final remapped = _remap(r, const {});
          remapped['projectId'] = mapped('projects', r['projectId'] ?? 0) == 0
              ? newProjectIds.first
              : mapped('projects', r['projectId'] ?? 0);
          return remapped;
        });
      } else {
        final projCols = <String, Expression<Object>>{};
        for (final e in (data['project'] as Map<String, dynamic>).entries) {
          if (e.key == 'id') continue;
          projCols[_snake(e.key)] = _expr(e.value);
        }
        firstNewProjectId = await db
            .into(db.projects)
            .insert(RawValuesInsertable<Project>(projCols));

        await insertRows<NovelBooks, NovelBook>(db.novelBooks, 'books', (r) {
          final remapped = _remap(r, const {});
          remapped['projectId'] = firstNewProjectId;
          return remapped;
        });
      }

      // ---- 需要跨表 id 映射的表，显式构造 transform ----
      await insertRows<Chapters, Chapter>(db.chapters, 'chapters', (r) {
        final remapped = _remap(r, const {});
        remapped['bookId'] = mapped('books', r['bookId']);
        return remapped;
      });
      await insertRows<ChapterRevisions, ChapterRevision>(
        db.chapterRevisions,
        'chapterRevisions',
        (r) {
          final remapped = _remap(r, const {});
          remapped['chapterId'] = mapped('chapters', r['chapterId']);
          return remapped;
        },
      );
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
        remapped['outputPath'] = _media(r['outputPath'], mediaMap);
        return remapped;
      });
      await insertRows<ScriptRevisions, ScriptRevision>(
        db.scriptRevisions,
        'scriptRevisions',
        (r) {
          final remapped = _remap(r, const {});
          remapped['scriptId'] = mapped('scripts', r['scriptId']);
          return remapped;
        },
      );

      // 供应商配置：同 id 覆盖（保留本地安全存储中的 Key 绑定）。
      for (final row
          in (data['providers'] as List? ?? const [])
              .cast<Map<String, dynamic>>()) {
        await db
            .into(db.providerConfigs)
            .insert(
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

      return firstNewProjectId;
    });
  }

  /// 解析 backup.json。用户提供的包，任何脏数据都不该让整次导入以未捕获
  /// 异常结束——统一抛 [FormatException]，UI 层统一提示「备份包已损坏」。
  static Map<String, dynamic> _decodeBackupJson(List<int> bytes) {
    String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      throw const FormatException('备份包已损坏：backup.json 不是合法 UTF-8');
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        throw const FormatException('备份包已损坏：backup.json 顶层不是对象');
      }
      return decoded.cast<String, dynamic>();
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('备份包已损坏：backup.json 不是合法 JSON');
    }
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

  /// 把压缩包内相对路径解析到 [docDir] 之内。
  ///
  /// 拒绝绝对路径与 `.`/`..` 段，防止构造过的备份包越界写文件
  /// （zip slip）；解析后仍校验绝对路径前缀，双重保险。
  static File _resolveMediaPath(Directory docDir, String name) {
    // 绝对路径（含 Windows 盘符）直接拒绝，避免构造包指定任意目标位置。
    if (RegExp(r'^[\\/]|[A-Za-z]:[\\/]').hasMatch(name)) {
      throw FormatException('备份包包含非法媒体路径：$name');
    }
    final rel = name.replaceAll('\\', '/');
    final segments = rel.split('/');
    if (rel.isEmpty ||
        segments.any((s) => s == '..' || s == '.' || s.isEmpty)) {
      throw FormatException('备份包包含非法媒体路径：$name');
    }
    final root = docDir.absolute.path;
    final resolved = File('$root/$rel').absolute.path;
    if (resolved != root && !resolved.startsWith('$root/')) {
      throw FormatException('备份包包含越界媒体路径：$name');
    }
    return File(resolved);
  }

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
