// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta(
    'coverPath',
  );
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('草稿'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    coverPath,
    genre,
    description,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cover_path')) {
      context.handle(
        _coverPathMeta,
        coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta),
      );
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      coverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_path'],
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final int id;
  final String name;
  final String? coverPath;
  final String? genre;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Project({
    required this.id,
    required this.name,
    this.coverPath,
    this.genre,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      name: Value(name),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      genre: serializer.fromJson<String?>(json['genre']),
      description: serializer.fromJson<String?>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'coverPath': serializer.toJson<String?>(coverPath),
      'genre': serializer.toJson<String?>(genre),
      'description': serializer.toJson<String?>(description),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Project copyWith({
    int? id,
    String? name,
    Value<String?> coverPath = const Value.absent(),
    Value<String?> genre = const Value.absent(),
    Value<String?> description = const Value.absent(),
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Project(
    id: id ?? this.id,
    name: name ?? this.name,
    coverPath: coverPath.present ? coverPath.value : this.coverPath,
    genre: genre.present ? genre.value : this.genre,
    description: description.present ? description.value : this.description,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      genre: data.genre.present ? data.genre.value : this.genre,
      description: data.description.present
          ? data.description.value
          : this.description,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('coverPath: $coverPath, ')
          ..write('genre: $genre, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    coverPath,
    genre,
    description,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.name == this.name &&
          other.coverPath == this.coverPath &&
          other.genre == this.genre &&
          other.description == this.description &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> coverPath;
  final Value<String?> genre;
  final Value<String?> description;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.genre = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProjectsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.coverPath = const Value.absent(),
    this.genre = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Project> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? coverPath,
    Expression<String>? genre,
    Expression<String>? description,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (coverPath != null) 'cover_path': coverPath,
      if (genre != null) 'genre': genre,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProjectsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? coverPath,
    Value<String?>? genre,
    Value<String?>? description,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      coverPath: coverPath ?? this.coverPath,
      genre: genre ?? this.genre,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('coverPath: $coverPath, ')
          ..write('genre: $genre, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $NovelBooksTable extends NovelBooks
    with TableInfo<$NovelBooksTable, NovelBook> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NovelBooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES projects (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _styleGuideMeta = const VerificationMeta(
    'styleGuide',
  );
  @override
  late final GeneratedColumn<String> styleGuide = GeneratedColumn<String>(
    'style_guide',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _worldMeta = const VerificationMeta('world');
  @override
  late final GeneratedColumn<String> world = GeneratedColumn<String>(
    'world',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _premiseMeta = const VerificationMeta(
    'premise',
  );
  @override
  late final GeneratedColumn<String> premise = GeneratedColumn<String>(
    'premise',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outlineMeta = const VerificationMeta(
    'outline',
  );
  @override
  late final GeneratedColumn<String> outline = GeneratedColumn<String>(
    'outline',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('草稿'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    title,
    genre,
    styleGuide,
    world,
    premise,
    outline,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'novel_books';
  @override
  VerificationContext validateIntegrity(
    Insertable<NovelBook> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('style_guide')) {
      context.handle(
        _styleGuideMeta,
        styleGuide.isAcceptableOrUnknown(data['style_guide']!, _styleGuideMeta),
      );
    }
    if (data.containsKey('world')) {
      context.handle(
        _worldMeta,
        world.isAcceptableOrUnknown(data['world']!, _worldMeta),
      );
    }
    if (data.containsKey('premise')) {
      context.handle(
        _premiseMeta,
        premise.isAcceptableOrUnknown(data['premise']!, _premiseMeta),
      );
    }
    if (data.containsKey('outline')) {
      context.handle(
        _outlineMeta,
        outline.isAcceptableOrUnknown(data['outline']!, _outlineMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NovelBook map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NovelBook(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}project_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      styleGuide: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style_guide'],
      ),
      world: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}world'],
      ),
      premise: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}premise'],
      ),
      outline: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outline'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $NovelBooksTable createAlias(String alias) {
    return $NovelBooksTable(attachedDatabase, alias);
  }
}

class NovelBook extends DataClass implements Insertable<NovelBook> {
  final int id;
  final int projectId;
  final String title;
  final String? genre;
  final String? styleGuide;
  final String? world;
  final String? premise;
  final String? outline;
  final String status;
  const NovelBook({
    required this.id,
    required this.projectId,
    required this.title,
    this.genre,
    this.styleGuide,
    this.world,
    this.premise,
    this.outline,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || styleGuide != null) {
      map['style_guide'] = Variable<String>(styleGuide);
    }
    if (!nullToAbsent || world != null) {
      map['world'] = Variable<String>(world);
    }
    if (!nullToAbsent || premise != null) {
      map['premise'] = Variable<String>(premise);
    }
    if (!nullToAbsent || outline != null) {
      map['outline'] = Variable<String>(outline);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  NovelBooksCompanion toCompanion(bool nullToAbsent) {
    return NovelBooksCompanion(
      id: Value(id),
      projectId: Value(projectId),
      title: Value(title),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      styleGuide: styleGuide == null && nullToAbsent
          ? const Value.absent()
          : Value(styleGuide),
      world: world == null && nullToAbsent
          ? const Value.absent()
          : Value(world),
      premise: premise == null && nullToAbsent
          ? const Value.absent()
          : Value(premise),
      outline: outline == null && nullToAbsent
          ? const Value.absent()
          : Value(outline),
      status: Value(status),
    );
  }

  factory NovelBook.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NovelBook(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      title: serializer.fromJson<String>(json['title']),
      genre: serializer.fromJson<String?>(json['genre']),
      styleGuide: serializer.fromJson<String?>(json['styleGuide']),
      world: serializer.fromJson<String?>(json['world']),
      premise: serializer.fromJson<String?>(json['premise']),
      outline: serializer.fromJson<String?>(json['outline']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'title': serializer.toJson<String>(title),
      'genre': serializer.toJson<String?>(genre),
      'styleGuide': serializer.toJson<String?>(styleGuide),
      'world': serializer.toJson<String?>(world),
      'premise': serializer.toJson<String?>(premise),
      'outline': serializer.toJson<String?>(outline),
      'status': serializer.toJson<String>(status),
    };
  }

  NovelBook copyWith({
    int? id,
    int? projectId,
    String? title,
    Value<String?> genre = const Value.absent(),
    Value<String?> styleGuide = const Value.absent(),
    Value<String?> world = const Value.absent(),
    Value<String?> premise = const Value.absent(),
    Value<String?> outline = const Value.absent(),
    String? status,
  }) => NovelBook(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    title: title ?? this.title,
    genre: genre.present ? genre.value : this.genre,
    styleGuide: styleGuide.present ? styleGuide.value : this.styleGuide,
    world: world.present ? world.value : this.world,
    premise: premise.present ? premise.value : this.premise,
    outline: outline.present ? outline.value : this.outline,
    status: status ?? this.status,
  );
  NovelBook copyWithCompanion(NovelBooksCompanion data) {
    return NovelBook(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      title: data.title.present ? data.title.value : this.title,
      genre: data.genre.present ? data.genre.value : this.genre,
      styleGuide: data.styleGuide.present
          ? data.styleGuide.value
          : this.styleGuide,
      world: data.world.present ? data.world.value : this.world,
      premise: data.premise.present ? data.premise.value : this.premise,
      outline: data.outline.present ? data.outline.value : this.outline,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NovelBook(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('genre: $genre, ')
          ..write('styleGuide: $styleGuide, ')
          ..write('world: $world, ')
          ..write('premise: $premise, ')
          ..write('outline: $outline, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    title,
    genre,
    styleGuide,
    world,
    premise,
    outline,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NovelBook &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.title == this.title &&
          other.genre == this.genre &&
          other.styleGuide == this.styleGuide &&
          other.world == this.world &&
          other.premise == this.premise &&
          other.outline == this.outline &&
          other.status == this.status);
}

class NovelBooksCompanion extends UpdateCompanion<NovelBook> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<String> title;
  final Value<String?> genre;
  final Value<String?> styleGuide;
  final Value<String?> world;
  final Value<String?> premise;
  final Value<String?> outline;
  final Value<String> status;
  const NovelBooksCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.title = const Value.absent(),
    this.genre = const Value.absent(),
    this.styleGuide = const Value.absent(),
    this.world = const Value.absent(),
    this.premise = const Value.absent(),
    this.outline = const Value.absent(),
    this.status = const Value.absent(),
  });
  NovelBooksCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    required String title,
    this.genre = const Value.absent(),
    this.styleGuide = const Value.absent(),
    this.world = const Value.absent(),
    this.premise = const Value.absent(),
    this.outline = const Value.absent(),
    this.status = const Value.absent(),
  }) : projectId = Value(projectId),
       title = Value(title);
  static Insertable<NovelBook> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<String>? title,
    Expression<String>? genre,
    Expression<String>? styleGuide,
    Expression<String>? world,
    Expression<String>? premise,
    Expression<String>? outline,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (title != null) 'title': title,
      if (genre != null) 'genre': genre,
      if (styleGuide != null) 'style_guide': styleGuide,
      if (world != null) 'world': world,
      if (premise != null) 'premise': premise,
      if (outline != null) 'outline': outline,
      if (status != null) 'status': status,
    });
  }

  NovelBooksCompanion copyWith({
    Value<int>? id,
    Value<int>? projectId,
    Value<String>? title,
    Value<String?>? genre,
    Value<String?>? styleGuide,
    Value<String?>? world,
    Value<String?>? premise,
    Value<String?>? outline,
    Value<String>? status,
  }) {
    return NovelBooksCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      genre: genre ?? this.genre,
      styleGuide: styleGuide ?? this.styleGuide,
      world: world ?? this.world,
      premise: premise ?? this.premise,
      outline: outline ?? this.outline,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (styleGuide.present) {
      map['style_guide'] = Variable<String>(styleGuide.value);
    }
    if (world.present) {
      map['world'] = Variable<String>(world.value);
    }
    if (premise.present) {
      map['premise'] = Variable<String>(premise.value);
    }
    if (outline.present) {
      map['outline'] = Variable<String>(outline.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NovelBooksCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('genre: $genre, ')
          ..write('styleGuide: $styleGuide, ')
          ..write('world: $world, ')
          ..write('premise: $premise, ')
          ..write('outline: $outline, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $ChaptersTable extends Chapters with TableInfo<$ChaptersTable, Chapter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChaptersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES novel_books (id)',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordCountMeta = const VerificationMeta(
    'wordCount',
  );
  @override
  late final GeneratedColumn<int> wordCount = GeneratedColumn<int>(
    'word_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('草稿'),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    seq,
    title,
    summary,
    content,
    wordCount,
    status,
    revision,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Chapter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('word_count')) {
      context.handle(
        _wordCountMeta,
        wordCount.isAcceptableOrUnknown(data['word_count']!, _wordCountMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Chapter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Chapter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      wordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_count'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ChaptersTable createAlias(String alias) {
    return $ChaptersTable(attachedDatabase, alias);
  }
}

class Chapter extends DataClass implements Insertable<Chapter> {
  final int id;
  final int bookId;
  final int seq;
  final String title;
  final String? summary;
  final String? content;
  final int wordCount;
  final String status;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Chapter({
    required this.id,
    required this.bookId,
    required this.seq,
    required this.title,
    this.summary,
    this.content,
    required this.wordCount,
    required this.status,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<int>(bookId);
    map['seq'] = Variable<int>(seq);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    map['word_count'] = Variable<int>(wordCount);
    map['status'] = Variable<String>(status);
    map['revision'] = Variable<int>(revision);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChaptersCompanion toCompanion(bool nullToAbsent) {
    return ChaptersCompanion(
      id: Value(id),
      bookId: Value(bookId),
      seq: Value(seq),
      title: Value(title),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      wordCount: Value(wordCount),
      status: Value(status),
      revision: Value(revision),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Chapter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Chapter(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<int>(json['bookId']),
      seq: serializer.fromJson<int>(json['seq']),
      title: serializer.fromJson<String>(json['title']),
      summary: serializer.fromJson<String?>(json['summary']),
      content: serializer.fromJson<String?>(json['content']),
      wordCount: serializer.fromJson<int>(json['wordCount']),
      status: serializer.fromJson<String>(json['status']),
      revision: serializer.fromJson<int>(json['revision']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<int>(bookId),
      'seq': serializer.toJson<int>(seq),
      'title': serializer.toJson<String>(title),
      'summary': serializer.toJson<String?>(summary),
      'content': serializer.toJson<String?>(content),
      'wordCount': serializer.toJson<int>(wordCount),
      'status': serializer.toJson<String>(status),
      'revision': serializer.toJson<int>(revision),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Chapter copyWith({
    int? id,
    int? bookId,
    int? seq,
    String? title,
    Value<String?> summary = const Value.absent(),
    Value<String?> content = const Value.absent(),
    int? wordCount,
    String? status,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Chapter(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    seq: seq ?? this.seq,
    title: title ?? this.title,
    summary: summary.present ? summary.value : this.summary,
    content: content.present ? content.value : this.content,
    wordCount: wordCount ?? this.wordCount,
    status: status ?? this.status,
    revision: revision ?? this.revision,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Chapter copyWithCompanion(ChaptersCompanion data) {
    return Chapter(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      seq: data.seq.present ? data.seq.value : this.seq,
      title: data.title.present ? data.title.value : this.title,
      summary: data.summary.present ? data.summary.value : this.summary,
      content: data.content.present ? data.content.value : this.content,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
      status: data.status.present ? data.status.value : this.status,
      revision: data.revision.present ? data.revision.value : this.revision,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Chapter(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('seq: $seq, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('content: $content, ')
          ..write('wordCount: $wordCount, ')
          ..write('status: $status, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    seq,
    title,
    summary,
    content,
    wordCount,
    status,
    revision,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chapter &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.seq == this.seq &&
          other.title == this.title &&
          other.summary == this.summary &&
          other.content == this.content &&
          other.wordCount == this.wordCount &&
          other.status == this.status &&
          other.revision == this.revision &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChaptersCompanion extends UpdateCompanion<Chapter> {
  final Value<int> id;
  final Value<int> bookId;
  final Value<int> seq;
  final Value<String> title;
  final Value<String?> summary;
  final Value<String?> content;
  final Value<int> wordCount;
  final Value<String> status;
  final Value<int> revision;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ChaptersCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.seq = const Value.absent(),
    this.title = const Value.absent(),
    this.summary = const Value.absent(),
    this.content = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.status = const Value.absent(),
    this.revision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ChaptersCompanion.insert({
    this.id = const Value.absent(),
    required int bookId,
    required int seq,
    required String title,
    this.summary = const Value.absent(),
    this.content = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.status = const Value.absent(),
    this.revision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : bookId = Value(bookId),
       seq = Value(seq),
       title = Value(title);
  static Insertable<Chapter> custom({
    Expression<int>? id,
    Expression<int>? bookId,
    Expression<int>? seq,
    Expression<String>? title,
    Expression<String>? summary,
    Expression<String>? content,
    Expression<int>? wordCount,
    Expression<String>? status,
    Expression<int>? revision,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (seq != null) 'seq': seq,
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
      if (content != null) 'content': content,
      if (wordCount != null) 'word_count': wordCount,
      if (status != null) 'status': status,
      if (revision != null) 'revision': revision,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ChaptersCompanion copyWith({
    Value<int>? id,
    Value<int>? bookId,
    Value<int>? seq,
    Value<String>? title,
    Value<String?>? summary,
    Value<String?>? content,
    Value<int>? wordCount,
    Value<String>? status,
    Value<int>? revision,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ChaptersCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      seq: seq ?? this.seq,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      wordCount: wordCount ?? this.wordCount,
      status: status ?? this.status,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (wordCount.present) {
      map['word_count'] = Variable<int>(wordCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChaptersCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('seq: $seq, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('content: $content, ')
          ..write('wordCount: $wordCount, ')
          ..write('status: $status, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ChapterRevisionsTable extends ChapterRevisions
    with TableInfo<$ChapterRevisionsTable, ChapterRevision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChapterRevisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<int> chapterId = GeneratedColumn<int>(
    'chapter_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chapters (id)',
    ),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    chapterId,
    revision,
    content,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapter_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChapterRevision> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChapterRevision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChapterRevision(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ChapterRevisionsTable createAlias(String alias) {
    return $ChapterRevisionsTable(attachedDatabase, alias);
  }
}

class ChapterRevision extends DataClass implements Insertable<ChapterRevision> {
  final int id;
  final int chapterId;
  final int revision;
  final String? content;
  final DateTime createdAt;
  const ChapterRevision({
    required this.id,
    required this.chapterId,
    required this.revision,
    this.content,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['chapter_id'] = Variable<int>(chapterId);
    map['revision'] = Variable<int>(revision);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChapterRevisionsCompanion toCompanion(bool nullToAbsent) {
    return ChapterRevisionsCompanion(
      id: Value(id),
      chapterId: Value(chapterId),
      revision: Value(revision),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory ChapterRevision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChapterRevision(
      id: serializer.fromJson<int>(json['id']),
      chapterId: serializer.fromJson<int>(json['chapterId']),
      revision: serializer.fromJson<int>(json['revision']),
      content: serializer.fromJson<String?>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'chapterId': serializer.toJson<int>(chapterId),
      'revision': serializer.toJson<int>(revision),
      'content': serializer.toJson<String?>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChapterRevision copyWith({
    int? id,
    int? chapterId,
    int? revision,
    Value<String?> content = const Value.absent(),
    DateTime? createdAt,
  }) => ChapterRevision(
    id: id ?? this.id,
    chapterId: chapterId ?? this.chapterId,
    revision: revision ?? this.revision,
    content: content.present ? content.value : this.content,
    createdAt: createdAt ?? this.createdAt,
  );
  ChapterRevision copyWithCompanion(ChapterRevisionsCompanion data) {
    return ChapterRevision(
      id: data.id.present ? data.id.value : this.id,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      revision: data.revision.present ? data.revision.value : this.revision,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChapterRevision(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('revision: $revision, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, chapterId, revision, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChapterRevision &&
          other.id == this.id &&
          other.chapterId == this.chapterId &&
          other.revision == this.revision &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class ChapterRevisionsCompanion extends UpdateCompanion<ChapterRevision> {
  final Value<int> id;
  final Value<int> chapterId;
  final Value<int> revision;
  final Value<String?> content;
  final Value<DateTime> createdAt;
  const ChapterRevisionsCompanion({
    this.id = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.revision = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ChapterRevisionsCompanion.insert({
    this.id = const Value.absent(),
    required int chapterId,
    required int revision,
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : chapterId = Value(chapterId),
       revision = Value(revision);
  static Insertable<ChapterRevision> custom({
    Expression<int>? id,
    Expression<int>? chapterId,
    Expression<int>? revision,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chapterId != null) 'chapter_id': chapterId,
      if (revision != null) 'revision': revision,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ChapterRevisionsCompanion copyWith({
    Value<int>? id,
    Value<int>? chapterId,
    Value<int>? revision,
    Value<String?>? content,
    Value<DateTime>? createdAt,
  }) {
    return ChapterRevisionsCompanion(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      revision: revision ?? this.revision,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<int>(chapterId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChapterRevisionsCompanion(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('revision: $revision, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TruthFilesTable extends TruthFiles
    with TableInfo<$TruthFilesTable, TruthFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TruthFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES novel_books (id)',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    kind,
    content,
    revision,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'truth_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<TruthFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {bookId, kind},
  ];
  @override
  TruthFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TruthFile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TruthFilesTable createAlias(String alias) {
    return $TruthFilesTable(attachedDatabase, alias);
  }
}

class TruthFile extends DataClass implements Insertable<TruthFile> {
  final int id;
  final int bookId;
  final String kind;
  final String content;
  final int revision;
  final DateTime updatedAt;
  const TruthFile({
    required this.id,
    required this.bookId,
    required this.kind,
    required this.content,
    required this.revision,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<int>(bookId);
    map['kind'] = Variable<String>(kind);
    map['content'] = Variable<String>(content);
    map['revision'] = Variable<int>(revision);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TruthFilesCompanion toCompanion(bool nullToAbsent) {
    return TruthFilesCompanion(
      id: Value(id),
      bookId: Value(bookId),
      kind: Value(kind),
      content: Value(content),
      revision: Value(revision),
      updatedAt: Value(updatedAt),
    );
  }

  factory TruthFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TruthFile(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<int>(json['bookId']),
      kind: serializer.fromJson<String>(json['kind']),
      content: serializer.fromJson<String>(json['content']),
      revision: serializer.fromJson<int>(json['revision']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<int>(bookId),
      'kind': serializer.toJson<String>(kind),
      'content': serializer.toJson<String>(content),
      'revision': serializer.toJson<int>(revision),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TruthFile copyWith({
    int? id,
    int? bookId,
    String? kind,
    String? content,
    int? revision,
    DateTime? updatedAt,
  }) => TruthFile(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    kind: kind ?? this.kind,
    content: content ?? this.content,
    revision: revision ?? this.revision,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TruthFile copyWithCompanion(TruthFilesCompanion data) {
    return TruthFile(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      kind: data.kind.present ? data.kind.value : this.kind,
      content: data.content.present ? data.content.value : this.content,
      revision: data.revision.present ? data.revision.value : this.revision,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TruthFile(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('kind: $kind, ')
          ..write('content: $content, ')
          ..write('revision: $revision, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, bookId, kind, content, revision, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TruthFile &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.kind == this.kind &&
          other.content == this.content &&
          other.revision == this.revision &&
          other.updatedAt == this.updatedAt);
}

class TruthFilesCompanion extends UpdateCompanion<TruthFile> {
  final Value<int> id;
  final Value<int> bookId;
  final Value<String> kind;
  final Value<String> content;
  final Value<int> revision;
  final Value<DateTime> updatedAt;
  const TruthFilesCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.kind = const Value.absent(),
    this.content = const Value.absent(),
    this.revision = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TruthFilesCompanion.insert({
    this.id = const Value.absent(),
    required int bookId,
    required String kind,
    this.content = const Value.absent(),
    this.revision = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : bookId = Value(bookId),
       kind = Value(kind);
  static Insertable<TruthFile> custom({
    Expression<int>? id,
    Expression<int>? bookId,
    Expression<String>? kind,
    Expression<String>? content,
    Expression<int>? revision,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (kind != null) 'kind': kind,
      if (content != null) 'content': content,
      if (revision != null) 'revision': revision,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TruthFilesCompanion copyWith({
    Value<int>? id,
    Value<int>? bookId,
    Value<String>? kind,
    Value<String>? content,
    Value<int>? revision,
    Value<DateTime>? updatedAt,
  }) {
    return TruthFilesCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      kind: kind ?? this.kind,
      content: content ?? this.content,
      revision: revision ?? this.revision,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TruthFilesCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('kind: $kind, ')
          ..write('content: $content, ')
          ..write('revision: $revision, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ScriptsTable extends Scripts with TableInfo<$ScriptsTable, Script> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScriptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES novel_books (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _fidelityModeMeta = const VerificationMeta(
    'fidelityMode',
  );
  @override
  late final GeneratedColumn<String> fidelityMode = GeneratedColumn<String>(
    'fidelity_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('严格保留'),
  );
  static const VerificationMeta _artStyleMeta = const VerificationMeta(
    'artStyle',
  );
  @override
  late final GeneratedColumn<String> artStyle = GeneratedColumn<String>(
    'art_style',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aspectRatioMeta = const VerificationMeta(
    'aspectRatio',
  );
  @override
  late final GeneratedColumn<String> aspectRatio = GeneratedColumn<String>(
    'aspect_ratio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('16:9'),
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('zh'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('草案'),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    title,
    version,
    fidelityMode,
    artStyle,
    aspectRatio,
    language,
    status,
    content,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scripts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Script> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('fidelity_mode')) {
      context.handle(
        _fidelityModeMeta,
        fidelityMode.isAcceptableOrUnknown(
          data['fidelity_mode']!,
          _fidelityModeMeta,
        ),
      );
    }
    if (data.containsKey('art_style')) {
      context.handle(
        _artStyleMeta,
        artStyle.isAcceptableOrUnknown(data['art_style']!, _artStyleMeta),
      );
    }
    if (data.containsKey('aspect_ratio')) {
      context.handle(
        _aspectRatioMeta,
        aspectRatio.isAcceptableOrUnknown(
          data['aspect_ratio']!,
          _aspectRatioMeta,
        ),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Script map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Script(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      fidelityMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fidelity_mode'],
      )!,
      artStyle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}art_style'],
      ),
      aspectRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aspect_ratio'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
    );
  }

  @override
  $ScriptsTable createAlias(String alias) {
    return $ScriptsTable(attachedDatabase, alias);
  }
}

class Script extends DataClass implements Insertable<Script> {
  final int id;
  final int bookId;
  final String title;
  final int version;
  final String fidelityMode;
  final String? artStyle;
  final String aspectRatio;
  final String language;
  final String status;
  final String content;
  const Script({
    required this.id,
    required this.bookId,
    required this.title,
    required this.version,
    required this.fidelityMode,
    this.artStyle,
    required this.aspectRatio,
    required this.language,
    required this.status,
    required this.content,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<int>(bookId);
    map['title'] = Variable<String>(title);
    map['version'] = Variable<int>(version);
    map['fidelity_mode'] = Variable<String>(fidelityMode);
    if (!nullToAbsent || artStyle != null) {
      map['art_style'] = Variable<String>(artStyle);
    }
    map['aspect_ratio'] = Variable<String>(aspectRatio);
    map['language'] = Variable<String>(language);
    map['status'] = Variable<String>(status);
    map['content'] = Variable<String>(content);
    return map;
  }

  ScriptsCompanion toCompanion(bool nullToAbsent) {
    return ScriptsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      title: Value(title),
      version: Value(version),
      fidelityMode: Value(fidelityMode),
      artStyle: artStyle == null && nullToAbsent
          ? const Value.absent()
          : Value(artStyle),
      aspectRatio: Value(aspectRatio),
      language: Value(language),
      status: Value(status),
      content: Value(content),
    );
  }

  factory Script.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Script(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<int>(json['bookId']),
      title: serializer.fromJson<String>(json['title']),
      version: serializer.fromJson<int>(json['version']),
      fidelityMode: serializer.fromJson<String>(json['fidelityMode']),
      artStyle: serializer.fromJson<String?>(json['artStyle']),
      aspectRatio: serializer.fromJson<String>(json['aspectRatio']),
      language: serializer.fromJson<String>(json['language']),
      status: serializer.fromJson<String>(json['status']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<int>(bookId),
      'title': serializer.toJson<String>(title),
      'version': serializer.toJson<int>(version),
      'fidelityMode': serializer.toJson<String>(fidelityMode),
      'artStyle': serializer.toJson<String?>(artStyle),
      'aspectRatio': serializer.toJson<String>(aspectRatio),
      'language': serializer.toJson<String>(language),
      'status': serializer.toJson<String>(status),
      'content': serializer.toJson<String>(content),
    };
  }

  Script copyWith({
    int? id,
    int? bookId,
    String? title,
    int? version,
    String? fidelityMode,
    Value<String?> artStyle = const Value.absent(),
    String? aspectRatio,
    String? language,
    String? status,
    String? content,
  }) => Script(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    title: title ?? this.title,
    version: version ?? this.version,
    fidelityMode: fidelityMode ?? this.fidelityMode,
    artStyle: artStyle.present ? artStyle.value : this.artStyle,
    aspectRatio: aspectRatio ?? this.aspectRatio,
    language: language ?? this.language,
    status: status ?? this.status,
    content: content ?? this.content,
  );
  Script copyWithCompanion(ScriptsCompanion data) {
    return Script(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      title: data.title.present ? data.title.value : this.title,
      version: data.version.present ? data.version.value : this.version,
      fidelityMode: data.fidelityMode.present
          ? data.fidelityMode.value
          : this.fidelityMode,
      artStyle: data.artStyle.present ? data.artStyle.value : this.artStyle,
      aspectRatio: data.aspectRatio.present
          ? data.aspectRatio.value
          : this.aspectRatio,
      language: data.language.present ? data.language.value : this.language,
      status: data.status.present ? data.status.value : this.status,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Script(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('title: $title, ')
          ..write('version: $version, ')
          ..write('fidelityMode: $fidelityMode, ')
          ..write('artStyle: $artStyle, ')
          ..write('aspectRatio: $aspectRatio, ')
          ..write('language: $language, ')
          ..write('status: $status, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    title,
    version,
    fidelityMode,
    artStyle,
    aspectRatio,
    language,
    status,
    content,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Script &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.title == this.title &&
          other.version == this.version &&
          other.fidelityMode == this.fidelityMode &&
          other.artStyle == this.artStyle &&
          other.aspectRatio == this.aspectRatio &&
          other.language == this.language &&
          other.status == this.status &&
          other.content == this.content);
}

class ScriptsCompanion extends UpdateCompanion<Script> {
  final Value<int> id;
  final Value<int> bookId;
  final Value<String> title;
  final Value<int> version;
  final Value<String> fidelityMode;
  final Value<String?> artStyle;
  final Value<String> aspectRatio;
  final Value<String> language;
  final Value<String> status;
  final Value<String> content;
  const ScriptsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.title = const Value.absent(),
    this.version = const Value.absent(),
    this.fidelityMode = const Value.absent(),
    this.artStyle = const Value.absent(),
    this.aspectRatio = const Value.absent(),
    this.language = const Value.absent(),
    this.status = const Value.absent(),
    this.content = const Value.absent(),
  });
  ScriptsCompanion.insert({
    this.id = const Value.absent(),
    required int bookId,
    required String title,
    this.version = const Value.absent(),
    this.fidelityMode = const Value.absent(),
    this.artStyle = const Value.absent(),
    this.aspectRatio = const Value.absent(),
    this.language = const Value.absent(),
    this.status = const Value.absent(),
    this.content = const Value.absent(),
  }) : bookId = Value(bookId),
       title = Value(title);
  static Insertable<Script> custom({
    Expression<int>? id,
    Expression<int>? bookId,
    Expression<String>? title,
    Expression<int>? version,
    Expression<String>? fidelityMode,
    Expression<String>? artStyle,
    Expression<String>? aspectRatio,
    Expression<String>? language,
    Expression<String>? status,
    Expression<String>? content,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (title != null) 'title': title,
      if (version != null) 'version': version,
      if (fidelityMode != null) 'fidelity_mode': fidelityMode,
      if (artStyle != null) 'art_style': artStyle,
      if (aspectRatio != null) 'aspect_ratio': aspectRatio,
      if (language != null) 'language': language,
      if (status != null) 'status': status,
      if (content != null) 'content': content,
    });
  }

  ScriptsCompanion copyWith({
    Value<int>? id,
    Value<int>? bookId,
    Value<String>? title,
    Value<int>? version,
    Value<String>? fidelityMode,
    Value<String?>? artStyle,
    Value<String>? aspectRatio,
    Value<String>? language,
    Value<String>? status,
    Value<String>? content,
  }) {
    return ScriptsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      version: version ?? this.version,
      fidelityMode: fidelityMode ?? this.fidelityMode,
      artStyle: artStyle ?? this.artStyle,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      language: language ?? this.language,
      status: status ?? this.status,
      content: content ?? this.content,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (fidelityMode.present) {
      map['fidelity_mode'] = Variable<String>(fidelityMode.value);
    }
    if (artStyle.present) {
      map['art_style'] = Variable<String>(artStyle.value);
    }
    if (aspectRatio.present) {
      map['aspect_ratio'] = Variable<String>(aspectRatio.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScriptsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('title: $title, ')
          ..write('version: $version, ')
          ..write('fidelityMode: $fidelityMode, ')
          ..write('artStyle: $artStyle, ')
          ..write('aspectRatio: $aspectRatio, ')
          ..write('language: $language, ')
          ..write('status: $status, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }
}

class $ScriptRevisionsTable extends ScriptRevisions
    with TableInfo<$ScriptRevisionsTable, ScriptRevision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScriptRevisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _scriptIdMeta = const VerificationMeta(
    'scriptId',
  );
  @override
  late final GeneratedColumn<int> scriptId = GeneratedColumn<int>(
    'script_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scripts (id)',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scriptId,
    version,
    content,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'script_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScriptRevision> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('script_id')) {
      context.handle(
        _scriptIdMeta,
        scriptId.isAcceptableOrUnknown(data['script_id']!, _scriptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scriptIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScriptRevision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScriptRevision(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scriptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}script_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ScriptRevisionsTable createAlias(String alias) {
    return $ScriptRevisionsTable(attachedDatabase, alias);
  }
}

class ScriptRevision extends DataClass implements Insertable<ScriptRevision> {
  final int id;
  final int scriptId;
  final int version;
  final String? content;
  final DateTime createdAt;
  const ScriptRevision({
    required this.id,
    required this.scriptId,
    required this.version,
    this.content,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['script_id'] = Variable<int>(scriptId);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ScriptRevisionsCompanion toCompanion(bool nullToAbsent) {
    return ScriptRevisionsCompanion(
      id: Value(id),
      scriptId: Value(scriptId),
      version: Value(version),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory ScriptRevision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScriptRevision(
      id: serializer.fromJson<int>(json['id']),
      scriptId: serializer.fromJson<int>(json['scriptId']),
      version: serializer.fromJson<int>(json['version']),
      content: serializer.fromJson<String?>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scriptId': serializer.toJson<int>(scriptId),
      'version': serializer.toJson<int>(version),
      'content': serializer.toJson<String?>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ScriptRevision copyWith({
    int? id,
    int? scriptId,
    int? version,
    Value<String?> content = const Value.absent(),
    DateTime? createdAt,
  }) => ScriptRevision(
    id: id ?? this.id,
    scriptId: scriptId ?? this.scriptId,
    version: version ?? this.version,
    content: content.present ? content.value : this.content,
    createdAt: createdAt ?? this.createdAt,
  );
  ScriptRevision copyWithCompanion(ScriptRevisionsCompanion data) {
    return ScriptRevision(
      id: data.id.present ? data.id.value : this.id,
      scriptId: data.scriptId.present ? data.scriptId.value : this.scriptId,
      version: data.version.present ? data.version.value : this.version,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScriptRevision(')
          ..write('id: $id, ')
          ..write('scriptId: $scriptId, ')
          ..write('version: $version, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, scriptId, version, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScriptRevision &&
          other.id == this.id &&
          other.scriptId == this.scriptId &&
          other.version == this.version &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class ScriptRevisionsCompanion extends UpdateCompanion<ScriptRevision> {
  final Value<int> id;
  final Value<int> scriptId;
  final Value<int> version;
  final Value<String?> content;
  final Value<DateTime> createdAt;
  const ScriptRevisionsCompanion({
    this.id = const Value.absent(),
    this.scriptId = const Value.absent(),
    this.version = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ScriptRevisionsCompanion.insert({
    this.id = const Value.absent(),
    required int scriptId,
    required int version,
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : scriptId = Value(scriptId),
       version = Value(version);
  static Insertable<ScriptRevision> custom({
    Expression<int>? id,
    Expression<int>? scriptId,
    Expression<int>? version,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scriptId != null) 'script_id': scriptId,
      if (version != null) 'version': version,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ScriptRevisionsCompanion copyWith({
    Value<int>? id,
    Value<int>? scriptId,
    Value<int>? version,
    Value<String?>? content,
    Value<DateTime>? createdAt,
  }) {
    return ScriptRevisionsCompanion(
      id: id ?? this.id,
      scriptId: scriptId ?? this.scriptId,
      version: version ?? this.version,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scriptId.present) {
      map['script_id'] = Variable<int>(scriptId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScriptRevisionsCompanion(')
          ..write('id: $id, ')
          ..write('scriptId: $scriptId, ')
          ..write('version: $version, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ScenesTable extends Scenes with TableInfo<$ScenesTable, Scene> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScenesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _scriptIdMeta = const VerificationMeta(
    'scriptId',
  );
  @override
  late final GeneratedColumn<int> scriptId = GeneratedColumn<int>(
    'script_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scripts (id)',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<String> time = GeneratedColumn<String>(
    'time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _charactersMeta = const VerificationMeta(
    'characters',
  );
  @override
  late final GeneratedColumn<String> characters = GeneratedColumn<String>(
    'characters',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _startStateMeta = const VerificationMeta(
    'startState',
  );
  @override
  late final GeneratedColumn<String> startState = GeneratedColumn<String>(
    'start_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endStateMeta = const VerificationMeta(
    'endState',
  );
  @override
  late final GeneratedColumn<String> endState = GeneratedColumn<String>(
    'end_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transitionMeta = const VerificationMeta(
    'transition',
  );
  @override
  late final GeneratedColumn<String> transition = GeneratedColumn<String>(
    'transition',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dialogueMeta = const VerificationMeta(
    'dialogue',
  );
  @override
  late final GeneratedColumn<String> dialogue = GeneratedColumn<String>(
    'dialogue',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _soundMeta = const VerificationMeta('sound');
  @override
  late final GeneratedColumn<String> sound = GeneratedColumn<String>(
    'sound',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scriptId,
    seq,
    location,
    time,
    characters,
    summary,
    action,
    startState,
    endState,
    transition,
    dialogue,
    sound,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scenes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Scene> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('script_id')) {
      context.handle(
        _scriptIdMeta,
        scriptId.isAcceptableOrUnknown(data['script_id']!, _scriptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scriptIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('characters')) {
      context.handle(
        _charactersMeta,
        characters.isAcceptableOrUnknown(data['characters']!, _charactersMeta),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    }
    if (data.containsKey('start_state')) {
      context.handle(
        _startStateMeta,
        startState.isAcceptableOrUnknown(data['start_state']!, _startStateMeta),
      );
    }
    if (data.containsKey('end_state')) {
      context.handle(
        _endStateMeta,
        endState.isAcceptableOrUnknown(data['end_state']!, _endStateMeta),
      );
    }
    if (data.containsKey('transition')) {
      context.handle(
        _transitionMeta,
        transition.isAcceptableOrUnknown(data['transition']!, _transitionMeta),
      );
    }
    if (data.containsKey('dialogue')) {
      context.handle(
        _dialogueMeta,
        dialogue.isAcceptableOrUnknown(data['dialogue']!, _dialogueMeta),
      );
    }
    if (data.containsKey('sound')) {
      context.handle(
        _soundMeta,
        sound.isAcceptableOrUnknown(data['sound']!, _soundMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Scene map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Scene(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scriptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}script_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time'],
      )!,
      characters: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}characters'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      startState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_state'],
      ),
      endState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_state'],
      ),
      transition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transition'],
      ),
      dialogue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dialogue'],
      )!,
      sound: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound'],
      )!,
    );
  }

  @override
  $ScenesTable createAlias(String alias) {
    return $ScenesTable(attachedDatabase, alias);
  }
}

class Scene extends DataClass implements Insertable<Scene> {
  final int id;
  final int scriptId;
  final int seq;
  final String location;
  final String time;
  final String characters;
  final String? summary;
  final String action;
  final String? startState;
  final String? endState;
  final String? transition;
  final String dialogue;
  final String sound;
  const Scene({
    required this.id,
    required this.scriptId,
    required this.seq,
    required this.location,
    required this.time,
    required this.characters,
    this.summary,
    required this.action,
    this.startState,
    this.endState,
    this.transition,
    required this.dialogue,
    required this.sound,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['script_id'] = Variable<int>(scriptId);
    map['seq'] = Variable<int>(seq);
    map['location'] = Variable<String>(location);
    map['time'] = Variable<String>(time);
    map['characters'] = Variable<String>(characters);
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || startState != null) {
      map['start_state'] = Variable<String>(startState);
    }
    if (!nullToAbsent || endState != null) {
      map['end_state'] = Variable<String>(endState);
    }
    if (!nullToAbsent || transition != null) {
      map['transition'] = Variable<String>(transition);
    }
    map['dialogue'] = Variable<String>(dialogue);
    map['sound'] = Variable<String>(sound);
    return map;
  }

  ScenesCompanion toCompanion(bool nullToAbsent) {
    return ScenesCompanion(
      id: Value(id),
      scriptId: Value(scriptId),
      seq: Value(seq),
      location: Value(location),
      time: Value(time),
      characters: Value(characters),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      action: Value(action),
      startState: startState == null && nullToAbsent
          ? const Value.absent()
          : Value(startState),
      endState: endState == null && nullToAbsent
          ? const Value.absent()
          : Value(endState),
      transition: transition == null && nullToAbsent
          ? const Value.absent()
          : Value(transition),
      dialogue: Value(dialogue),
      sound: Value(sound),
    );
  }

  factory Scene.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Scene(
      id: serializer.fromJson<int>(json['id']),
      scriptId: serializer.fromJson<int>(json['scriptId']),
      seq: serializer.fromJson<int>(json['seq']),
      location: serializer.fromJson<String>(json['location']),
      time: serializer.fromJson<String>(json['time']),
      characters: serializer.fromJson<String>(json['characters']),
      summary: serializer.fromJson<String?>(json['summary']),
      action: serializer.fromJson<String>(json['action']),
      startState: serializer.fromJson<String?>(json['startState']),
      endState: serializer.fromJson<String?>(json['endState']),
      transition: serializer.fromJson<String?>(json['transition']),
      dialogue: serializer.fromJson<String>(json['dialogue']),
      sound: serializer.fromJson<String>(json['sound']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scriptId': serializer.toJson<int>(scriptId),
      'seq': serializer.toJson<int>(seq),
      'location': serializer.toJson<String>(location),
      'time': serializer.toJson<String>(time),
      'characters': serializer.toJson<String>(characters),
      'summary': serializer.toJson<String?>(summary),
      'action': serializer.toJson<String>(action),
      'startState': serializer.toJson<String?>(startState),
      'endState': serializer.toJson<String?>(endState),
      'transition': serializer.toJson<String?>(transition),
      'dialogue': serializer.toJson<String>(dialogue),
      'sound': serializer.toJson<String>(sound),
    };
  }

  Scene copyWith({
    int? id,
    int? scriptId,
    int? seq,
    String? location,
    String? time,
    String? characters,
    Value<String?> summary = const Value.absent(),
    String? action,
    Value<String?> startState = const Value.absent(),
    Value<String?> endState = const Value.absent(),
    Value<String?> transition = const Value.absent(),
    String? dialogue,
    String? sound,
  }) => Scene(
    id: id ?? this.id,
    scriptId: scriptId ?? this.scriptId,
    seq: seq ?? this.seq,
    location: location ?? this.location,
    time: time ?? this.time,
    characters: characters ?? this.characters,
    summary: summary.present ? summary.value : this.summary,
    action: action ?? this.action,
    startState: startState.present ? startState.value : this.startState,
    endState: endState.present ? endState.value : this.endState,
    transition: transition.present ? transition.value : this.transition,
    dialogue: dialogue ?? this.dialogue,
    sound: sound ?? this.sound,
  );
  Scene copyWithCompanion(ScenesCompanion data) {
    return Scene(
      id: data.id.present ? data.id.value : this.id,
      scriptId: data.scriptId.present ? data.scriptId.value : this.scriptId,
      seq: data.seq.present ? data.seq.value : this.seq,
      location: data.location.present ? data.location.value : this.location,
      time: data.time.present ? data.time.value : this.time,
      characters: data.characters.present
          ? data.characters.value
          : this.characters,
      summary: data.summary.present ? data.summary.value : this.summary,
      action: data.action.present ? data.action.value : this.action,
      startState: data.startState.present
          ? data.startState.value
          : this.startState,
      endState: data.endState.present ? data.endState.value : this.endState,
      transition: data.transition.present
          ? data.transition.value
          : this.transition,
      dialogue: data.dialogue.present ? data.dialogue.value : this.dialogue,
      sound: data.sound.present ? data.sound.value : this.sound,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Scene(')
          ..write('id: $id, ')
          ..write('scriptId: $scriptId, ')
          ..write('seq: $seq, ')
          ..write('location: $location, ')
          ..write('time: $time, ')
          ..write('characters: $characters, ')
          ..write('summary: $summary, ')
          ..write('action: $action, ')
          ..write('startState: $startState, ')
          ..write('endState: $endState, ')
          ..write('transition: $transition, ')
          ..write('dialogue: $dialogue, ')
          ..write('sound: $sound')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scriptId,
    seq,
    location,
    time,
    characters,
    summary,
    action,
    startState,
    endState,
    transition,
    dialogue,
    sound,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Scene &&
          other.id == this.id &&
          other.scriptId == this.scriptId &&
          other.seq == this.seq &&
          other.location == this.location &&
          other.time == this.time &&
          other.characters == this.characters &&
          other.summary == this.summary &&
          other.action == this.action &&
          other.startState == this.startState &&
          other.endState == this.endState &&
          other.transition == this.transition &&
          other.dialogue == this.dialogue &&
          other.sound == this.sound);
}

class ScenesCompanion extends UpdateCompanion<Scene> {
  final Value<int> id;
  final Value<int> scriptId;
  final Value<int> seq;
  final Value<String> location;
  final Value<String> time;
  final Value<String> characters;
  final Value<String?> summary;
  final Value<String> action;
  final Value<String?> startState;
  final Value<String?> endState;
  final Value<String?> transition;
  final Value<String> dialogue;
  final Value<String> sound;
  const ScenesCompanion({
    this.id = const Value.absent(),
    this.scriptId = const Value.absent(),
    this.seq = const Value.absent(),
    this.location = const Value.absent(),
    this.time = const Value.absent(),
    this.characters = const Value.absent(),
    this.summary = const Value.absent(),
    this.action = const Value.absent(),
    this.startState = const Value.absent(),
    this.endState = const Value.absent(),
    this.transition = const Value.absent(),
    this.dialogue = const Value.absent(),
    this.sound = const Value.absent(),
  });
  ScenesCompanion.insert({
    this.id = const Value.absent(),
    required int scriptId,
    required int seq,
    required String location,
    required String time,
    this.characters = const Value.absent(),
    this.summary = const Value.absent(),
    this.action = const Value.absent(),
    this.startState = const Value.absent(),
    this.endState = const Value.absent(),
    this.transition = const Value.absent(),
    this.dialogue = const Value.absent(),
    this.sound = const Value.absent(),
  }) : scriptId = Value(scriptId),
       seq = Value(seq),
       location = Value(location),
       time = Value(time);
  static Insertable<Scene> custom({
    Expression<int>? id,
    Expression<int>? scriptId,
    Expression<int>? seq,
    Expression<String>? location,
    Expression<String>? time,
    Expression<String>? characters,
    Expression<String>? summary,
    Expression<String>? action,
    Expression<String>? startState,
    Expression<String>? endState,
    Expression<String>? transition,
    Expression<String>? dialogue,
    Expression<String>? sound,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scriptId != null) 'script_id': scriptId,
      if (seq != null) 'seq': seq,
      if (location != null) 'location': location,
      if (time != null) 'time': time,
      if (characters != null) 'characters': characters,
      if (summary != null) 'summary': summary,
      if (action != null) 'action': action,
      if (startState != null) 'start_state': startState,
      if (endState != null) 'end_state': endState,
      if (transition != null) 'transition': transition,
      if (dialogue != null) 'dialogue': dialogue,
      if (sound != null) 'sound': sound,
    });
  }

  ScenesCompanion copyWith({
    Value<int>? id,
    Value<int>? scriptId,
    Value<int>? seq,
    Value<String>? location,
    Value<String>? time,
    Value<String>? characters,
    Value<String?>? summary,
    Value<String>? action,
    Value<String?>? startState,
    Value<String?>? endState,
    Value<String?>? transition,
    Value<String>? dialogue,
    Value<String>? sound,
  }) {
    return ScenesCompanion(
      id: id ?? this.id,
      scriptId: scriptId ?? this.scriptId,
      seq: seq ?? this.seq,
      location: location ?? this.location,
      time: time ?? this.time,
      characters: characters ?? this.characters,
      summary: summary ?? this.summary,
      action: action ?? this.action,
      startState: startState ?? this.startState,
      endState: endState ?? this.endState,
      transition: transition ?? this.transition,
      dialogue: dialogue ?? this.dialogue,
      sound: sound ?? this.sound,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scriptId.present) {
      map['script_id'] = Variable<int>(scriptId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (time.present) {
      map['time'] = Variable<String>(time.value);
    }
    if (characters.present) {
      map['characters'] = Variable<String>(characters.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (startState.present) {
      map['start_state'] = Variable<String>(startState.value);
    }
    if (endState.present) {
      map['end_state'] = Variable<String>(endState.value);
    }
    if (transition.present) {
      map['transition'] = Variable<String>(transition.value);
    }
    if (dialogue.present) {
      map['dialogue'] = Variable<String>(dialogue.value);
    }
    if (sound.present) {
      map['sound'] = Variable<String>(sound.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScenesCompanion(')
          ..write('id: $id, ')
          ..write('scriptId: $scriptId, ')
          ..write('seq: $seq, ')
          ..write('location: $location, ')
          ..write('time: $time, ')
          ..write('characters: $characters, ')
          ..write('summary: $summary, ')
          ..write('action: $action, ')
          ..write('startState: $startState, ')
          ..write('endState: $endState, ')
          ..write('transition: $transition, ')
          ..write('dialogue: $dialogue, ')
          ..write('sound: $sound')
          ..write(')'))
        .toString();
  }
}

class $BeatsTable extends Beats with TableInfo<$BeatsTable, Beat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BeatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sceneIdMeta = const VerificationMeta(
    'sceneId',
  );
  @override
  late final GeneratedColumn<int> sceneId = GeneratedColumn<int>(
    'scene_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scenes (id)',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _whoMeta = const VerificationMeta('who');
  @override
  late final GeneratedColumn<String> who = GeneratedColumn<String>(
    'who',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _objectMeta = const VerificationMeta('object');
  @override
  late final GeneratedColumn<String> object = GeneratedColumn<String>(
    'object',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceRefMeta = const VerificationMeta(
    'sourceRef',
  );
  @override
  late final GeneratedColumn<String> sourceRef = GeneratedColumn<String>(
    'source_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estDurationMsMeta = const VerificationMeta(
    'estDurationMs',
  );
  @override
  late final GeneratedColumn<int> estDurationMs = GeneratedColumn<int>(
    'est_duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sceneId,
    seq,
    type,
    who,
    content,
    object,
    sourceRef,
    estDurationMs,
    tags,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'beats';
  @override
  VerificationContext validateIntegrity(
    Insertable<Beat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scene_id')) {
      context.handle(
        _sceneIdMeta,
        sceneId.isAcceptableOrUnknown(data['scene_id']!, _sceneIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sceneIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('who')) {
      context.handle(
        _whoMeta,
        who.isAcceptableOrUnknown(data['who']!, _whoMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('object')) {
      context.handle(
        _objectMeta,
        object.isAcceptableOrUnknown(data['object']!, _objectMeta),
      );
    }
    if (data.containsKey('source_ref')) {
      context.handle(
        _sourceRefMeta,
        sourceRef.isAcceptableOrUnknown(data['source_ref']!, _sourceRefMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceRefMeta);
    }
    if (data.containsKey('est_duration_ms')) {
      context.handle(
        _estDurationMsMeta,
        estDurationMs.isAcceptableOrUnknown(
          data['est_duration_ms']!,
          _estDurationMsMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Beat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Beat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sceneId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scene_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      who: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}who'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      object: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}object'],
      ),
      sourceRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_ref'],
      )!,
      estDurationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}est_duration_ms'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
    );
  }

  @override
  $BeatsTable createAlias(String alias) {
    return $BeatsTable(attachedDatabase, alias);
  }
}

class Beat extends DataClass implements Insertable<Beat> {
  final int id;
  final int sceneId;
  final int seq;
  final String type;
  final String who;
  final String content;
  final String? object;
  final String sourceRef;
  final int estDurationMs;
  final String tags;
  const Beat({
    required this.id,
    required this.sceneId,
    required this.seq,
    required this.type,
    required this.who,
    required this.content,
    this.object,
    required this.sourceRef,
    required this.estDurationMs,
    required this.tags,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['scene_id'] = Variable<int>(sceneId);
    map['seq'] = Variable<int>(seq);
    map['type'] = Variable<String>(type);
    map['who'] = Variable<String>(who);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || object != null) {
      map['object'] = Variable<String>(object);
    }
    map['source_ref'] = Variable<String>(sourceRef);
    map['est_duration_ms'] = Variable<int>(estDurationMs);
    map['tags'] = Variable<String>(tags);
    return map;
  }

  BeatsCompanion toCompanion(bool nullToAbsent) {
    return BeatsCompanion(
      id: Value(id),
      sceneId: Value(sceneId),
      seq: Value(seq),
      type: Value(type),
      who: Value(who),
      content: Value(content),
      object: object == null && nullToAbsent
          ? const Value.absent()
          : Value(object),
      sourceRef: Value(sourceRef),
      estDurationMs: Value(estDurationMs),
      tags: Value(tags),
    );
  }

  factory Beat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Beat(
      id: serializer.fromJson<int>(json['id']),
      sceneId: serializer.fromJson<int>(json['sceneId']),
      seq: serializer.fromJson<int>(json['seq']),
      type: serializer.fromJson<String>(json['type']),
      who: serializer.fromJson<String>(json['who']),
      content: serializer.fromJson<String>(json['content']),
      object: serializer.fromJson<String?>(json['object']),
      sourceRef: serializer.fromJson<String>(json['sourceRef']),
      estDurationMs: serializer.fromJson<int>(json['estDurationMs']),
      tags: serializer.fromJson<String>(json['tags']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sceneId': serializer.toJson<int>(sceneId),
      'seq': serializer.toJson<int>(seq),
      'type': serializer.toJson<String>(type),
      'who': serializer.toJson<String>(who),
      'content': serializer.toJson<String>(content),
      'object': serializer.toJson<String?>(object),
      'sourceRef': serializer.toJson<String>(sourceRef),
      'estDurationMs': serializer.toJson<int>(estDurationMs),
      'tags': serializer.toJson<String>(tags),
    };
  }

  Beat copyWith({
    int? id,
    int? sceneId,
    int? seq,
    String? type,
    String? who,
    String? content,
    Value<String?> object = const Value.absent(),
    String? sourceRef,
    int? estDurationMs,
    String? tags,
  }) => Beat(
    id: id ?? this.id,
    sceneId: sceneId ?? this.sceneId,
    seq: seq ?? this.seq,
    type: type ?? this.type,
    who: who ?? this.who,
    content: content ?? this.content,
    object: object.present ? object.value : this.object,
    sourceRef: sourceRef ?? this.sourceRef,
    estDurationMs: estDurationMs ?? this.estDurationMs,
    tags: tags ?? this.tags,
  );
  Beat copyWithCompanion(BeatsCompanion data) {
    return Beat(
      id: data.id.present ? data.id.value : this.id,
      sceneId: data.sceneId.present ? data.sceneId.value : this.sceneId,
      seq: data.seq.present ? data.seq.value : this.seq,
      type: data.type.present ? data.type.value : this.type,
      who: data.who.present ? data.who.value : this.who,
      content: data.content.present ? data.content.value : this.content,
      object: data.object.present ? data.object.value : this.object,
      sourceRef: data.sourceRef.present ? data.sourceRef.value : this.sourceRef,
      estDurationMs: data.estDurationMs.present
          ? data.estDurationMs.value
          : this.estDurationMs,
      tags: data.tags.present ? data.tags.value : this.tags,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Beat(')
          ..write('id: $id, ')
          ..write('sceneId: $sceneId, ')
          ..write('seq: $seq, ')
          ..write('type: $type, ')
          ..write('who: $who, ')
          ..write('content: $content, ')
          ..write('object: $object, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('estDurationMs: $estDurationMs, ')
          ..write('tags: $tags')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sceneId,
    seq,
    type,
    who,
    content,
    object,
    sourceRef,
    estDurationMs,
    tags,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Beat &&
          other.id == this.id &&
          other.sceneId == this.sceneId &&
          other.seq == this.seq &&
          other.type == this.type &&
          other.who == this.who &&
          other.content == this.content &&
          other.object == this.object &&
          other.sourceRef == this.sourceRef &&
          other.estDurationMs == this.estDurationMs &&
          other.tags == this.tags);
}

class BeatsCompanion extends UpdateCompanion<Beat> {
  final Value<int> id;
  final Value<int> sceneId;
  final Value<int> seq;
  final Value<String> type;
  final Value<String> who;
  final Value<String> content;
  final Value<String?> object;
  final Value<String> sourceRef;
  final Value<int> estDurationMs;
  final Value<String> tags;
  const BeatsCompanion({
    this.id = const Value.absent(),
    this.sceneId = const Value.absent(),
    this.seq = const Value.absent(),
    this.type = const Value.absent(),
    this.who = const Value.absent(),
    this.content = const Value.absent(),
    this.object = const Value.absent(),
    this.sourceRef = const Value.absent(),
    this.estDurationMs = const Value.absent(),
    this.tags = const Value.absent(),
  });
  BeatsCompanion.insert({
    this.id = const Value.absent(),
    required int sceneId,
    required int seq,
    required String type,
    this.who = const Value.absent(),
    required String content,
    this.object = const Value.absent(),
    required String sourceRef,
    this.estDurationMs = const Value.absent(),
    this.tags = const Value.absent(),
  }) : sceneId = Value(sceneId),
       seq = Value(seq),
       type = Value(type),
       content = Value(content),
       sourceRef = Value(sourceRef);
  static Insertable<Beat> custom({
    Expression<int>? id,
    Expression<int>? sceneId,
    Expression<int>? seq,
    Expression<String>? type,
    Expression<String>? who,
    Expression<String>? content,
    Expression<String>? object,
    Expression<String>? sourceRef,
    Expression<int>? estDurationMs,
    Expression<String>? tags,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sceneId != null) 'scene_id': sceneId,
      if (seq != null) 'seq': seq,
      if (type != null) 'type': type,
      if (who != null) 'who': who,
      if (content != null) 'content': content,
      if (object != null) 'object': object,
      if (sourceRef != null) 'source_ref': sourceRef,
      if (estDurationMs != null) 'est_duration_ms': estDurationMs,
      if (tags != null) 'tags': tags,
    });
  }

  BeatsCompanion copyWith({
    Value<int>? id,
    Value<int>? sceneId,
    Value<int>? seq,
    Value<String>? type,
    Value<String>? who,
    Value<String>? content,
    Value<String?>? object,
    Value<String>? sourceRef,
    Value<int>? estDurationMs,
    Value<String>? tags,
  }) {
    return BeatsCompanion(
      id: id ?? this.id,
      sceneId: sceneId ?? this.sceneId,
      seq: seq ?? this.seq,
      type: type ?? this.type,
      who: who ?? this.who,
      content: content ?? this.content,
      object: object ?? this.object,
      sourceRef: sourceRef ?? this.sourceRef,
      estDurationMs: estDurationMs ?? this.estDurationMs,
      tags: tags ?? this.tags,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sceneId.present) {
      map['scene_id'] = Variable<int>(sceneId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (who.present) {
      map['who'] = Variable<String>(who.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (object.present) {
      map['object'] = Variable<String>(object.value);
    }
    if (sourceRef.present) {
      map['source_ref'] = Variable<String>(sourceRef.value);
    }
    if (estDurationMs.present) {
      map['est_duration_ms'] = Variable<int>(estDurationMs.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BeatsCompanion(')
          ..write('id: $id, ')
          ..write('sceneId: $sceneId, ')
          ..write('seq: $seq, ')
          ..write('type: $type, ')
          ..write('who: $who, ')
          ..write('content: $content, ')
          ..write('object: $object, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('estDurationMs: $estDurationMs, ')
          ..write('tags: $tags')
          ..write(')'))
        .toString();
  }
}

class $AssetsTable extends Assets with TableInfo<$AssetsTable, Asset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _scriptIdMeta = const VerificationMeta(
    'scriptId',
  );
  @override
  late final GeneratedColumn<int> scriptId = GeneratedColumn<int>(
    'script_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scripts (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stableIdMeta = const VerificationMeta(
    'stableId',
  );
  @override
  late final GeneratedColumn<String> stableId = GeneratedColumn<String>(
    'stable_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantOfMeta = const VerificationMeta(
    'variantOf',
  );
  @override
  late final GeneratedColumn<int> variantOf = GeneratedColumn<int>(
    'variant_of',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appearanceAnchorMeta = const VerificationMeta(
    'appearanceAnchor',
  );
  @override
  late final GeneratedColumn<String> appearanceAnchor = GeneratedColumn<String>(
    'appearance_anchor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _boardLayoutMeta = const VerificationMeta(
    'boardLayout',
  );
  @override
  late final GeneratedColumn<String> boardLayout = GeneratedColumn<String>(
    'board_layout',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('四视图'),
  );
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('待生成'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scriptId,
    type,
    name,
    stableId,
    variantOf,
    appearanceAnchor,
    boardLayout,
    prompt,
    imagePath,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Asset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('script_id')) {
      context.handle(
        _scriptIdMeta,
        scriptId.isAcceptableOrUnknown(data['script_id']!, _scriptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scriptIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('stable_id')) {
      context.handle(
        _stableIdMeta,
        stableId.isAcceptableOrUnknown(data['stable_id']!, _stableIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stableIdMeta);
    }
    if (data.containsKey('variant_of')) {
      context.handle(
        _variantOfMeta,
        variantOf.isAcceptableOrUnknown(data['variant_of']!, _variantOfMeta),
      );
    }
    if (data.containsKey('appearance_anchor')) {
      context.handle(
        _appearanceAnchorMeta,
        appearanceAnchor.isAcceptableOrUnknown(
          data['appearance_anchor']!,
          _appearanceAnchorMeta,
        ),
      );
    }
    if (data.containsKey('board_layout')) {
      context.handle(
        _boardLayoutMeta,
        boardLayout.isAcceptableOrUnknown(
          data['board_layout']!,
          _boardLayoutMeta,
        ),
      );
    }
    if (data.containsKey('prompt')) {
      context.handle(
        _promptMeta,
        prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Asset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Asset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scriptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}script_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      stableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stable_id'],
      )!,
      variantOf: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}variant_of'],
      ),
      appearanceAnchor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appearance_anchor'],
      ),
      boardLayout: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}board_layout'],
      )!,
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $AssetsTable createAlias(String alias) {
    return $AssetsTable(attachedDatabase, alias);
  }
}

class Asset extends DataClass implements Insertable<Asset> {
  final int id;
  final int scriptId;
  final String type;
  final String name;
  final String stableId;
  final int? variantOf;
  final String? appearanceAnchor;
  final String boardLayout;
  final String prompt;
  final String? imagePath;
  final String status;
  const Asset({
    required this.id,
    required this.scriptId,
    required this.type,
    required this.name,
    required this.stableId,
    this.variantOf,
    this.appearanceAnchor,
    required this.boardLayout,
    required this.prompt,
    this.imagePath,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['script_id'] = Variable<int>(scriptId);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    map['stable_id'] = Variable<String>(stableId);
    if (!nullToAbsent || variantOf != null) {
      map['variant_of'] = Variable<int>(variantOf);
    }
    if (!nullToAbsent || appearanceAnchor != null) {
      map['appearance_anchor'] = Variable<String>(appearanceAnchor);
    }
    map['board_layout'] = Variable<String>(boardLayout);
    map['prompt'] = Variable<String>(prompt);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  AssetsCompanion toCompanion(bool nullToAbsent) {
    return AssetsCompanion(
      id: Value(id),
      scriptId: Value(scriptId),
      type: Value(type),
      name: Value(name),
      stableId: Value(stableId),
      variantOf: variantOf == null && nullToAbsent
          ? const Value.absent()
          : Value(variantOf),
      appearanceAnchor: appearanceAnchor == null && nullToAbsent
          ? const Value.absent()
          : Value(appearanceAnchor),
      boardLayout: Value(boardLayout),
      prompt: Value(prompt),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      status: Value(status),
    );
  }

  factory Asset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Asset(
      id: serializer.fromJson<int>(json['id']),
      scriptId: serializer.fromJson<int>(json['scriptId']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      stableId: serializer.fromJson<String>(json['stableId']),
      variantOf: serializer.fromJson<int?>(json['variantOf']),
      appearanceAnchor: serializer.fromJson<String?>(json['appearanceAnchor']),
      boardLayout: serializer.fromJson<String>(json['boardLayout']),
      prompt: serializer.fromJson<String>(json['prompt']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scriptId': serializer.toJson<int>(scriptId),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'stableId': serializer.toJson<String>(stableId),
      'variantOf': serializer.toJson<int?>(variantOf),
      'appearanceAnchor': serializer.toJson<String?>(appearanceAnchor),
      'boardLayout': serializer.toJson<String>(boardLayout),
      'prompt': serializer.toJson<String>(prompt),
      'imagePath': serializer.toJson<String?>(imagePath),
      'status': serializer.toJson<String>(status),
    };
  }

  Asset copyWith({
    int? id,
    int? scriptId,
    String? type,
    String? name,
    String? stableId,
    Value<int?> variantOf = const Value.absent(),
    Value<String?> appearanceAnchor = const Value.absent(),
    String? boardLayout,
    String? prompt,
    Value<String?> imagePath = const Value.absent(),
    String? status,
  }) => Asset(
    id: id ?? this.id,
    scriptId: scriptId ?? this.scriptId,
    type: type ?? this.type,
    name: name ?? this.name,
    stableId: stableId ?? this.stableId,
    variantOf: variantOf.present ? variantOf.value : this.variantOf,
    appearanceAnchor: appearanceAnchor.present
        ? appearanceAnchor.value
        : this.appearanceAnchor,
    boardLayout: boardLayout ?? this.boardLayout,
    prompt: prompt ?? this.prompt,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    status: status ?? this.status,
  );
  Asset copyWithCompanion(AssetsCompanion data) {
    return Asset(
      id: data.id.present ? data.id.value : this.id,
      scriptId: data.scriptId.present ? data.scriptId.value : this.scriptId,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      stableId: data.stableId.present ? data.stableId.value : this.stableId,
      variantOf: data.variantOf.present ? data.variantOf.value : this.variantOf,
      appearanceAnchor: data.appearanceAnchor.present
          ? data.appearanceAnchor.value
          : this.appearanceAnchor,
      boardLayout: data.boardLayout.present
          ? data.boardLayout.value
          : this.boardLayout,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Asset(')
          ..write('id: $id, ')
          ..write('scriptId: $scriptId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('stableId: $stableId, ')
          ..write('variantOf: $variantOf, ')
          ..write('appearanceAnchor: $appearanceAnchor, ')
          ..write('boardLayout: $boardLayout, ')
          ..write('prompt: $prompt, ')
          ..write('imagePath: $imagePath, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scriptId,
    type,
    name,
    stableId,
    variantOf,
    appearanceAnchor,
    boardLayout,
    prompt,
    imagePath,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Asset &&
          other.id == this.id &&
          other.scriptId == this.scriptId &&
          other.type == this.type &&
          other.name == this.name &&
          other.stableId == this.stableId &&
          other.variantOf == this.variantOf &&
          other.appearanceAnchor == this.appearanceAnchor &&
          other.boardLayout == this.boardLayout &&
          other.prompt == this.prompt &&
          other.imagePath == this.imagePath &&
          other.status == this.status);
}

class AssetsCompanion extends UpdateCompanion<Asset> {
  final Value<int> id;
  final Value<int> scriptId;
  final Value<String> type;
  final Value<String> name;
  final Value<String> stableId;
  final Value<int?> variantOf;
  final Value<String?> appearanceAnchor;
  final Value<String> boardLayout;
  final Value<String> prompt;
  final Value<String?> imagePath;
  final Value<String> status;
  const AssetsCompanion({
    this.id = const Value.absent(),
    this.scriptId = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.stableId = const Value.absent(),
    this.variantOf = const Value.absent(),
    this.appearanceAnchor = const Value.absent(),
    this.boardLayout = const Value.absent(),
    this.prompt = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.status = const Value.absent(),
  });
  AssetsCompanion.insert({
    this.id = const Value.absent(),
    required int scriptId,
    required String type,
    required String name,
    required String stableId,
    this.variantOf = const Value.absent(),
    this.appearanceAnchor = const Value.absent(),
    this.boardLayout = const Value.absent(),
    this.prompt = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.status = const Value.absent(),
  }) : scriptId = Value(scriptId),
       type = Value(type),
       name = Value(name),
       stableId = Value(stableId);
  static Insertable<Asset> custom({
    Expression<int>? id,
    Expression<int>? scriptId,
    Expression<String>? type,
    Expression<String>? name,
    Expression<String>? stableId,
    Expression<int>? variantOf,
    Expression<String>? appearanceAnchor,
    Expression<String>? boardLayout,
    Expression<String>? prompt,
    Expression<String>? imagePath,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scriptId != null) 'script_id': scriptId,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (stableId != null) 'stable_id': stableId,
      if (variantOf != null) 'variant_of': variantOf,
      if (appearanceAnchor != null) 'appearance_anchor': appearanceAnchor,
      if (boardLayout != null) 'board_layout': boardLayout,
      if (prompt != null) 'prompt': prompt,
      if (imagePath != null) 'image_path': imagePath,
      if (status != null) 'status': status,
    });
  }

  AssetsCompanion copyWith({
    Value<int>? id,
    Value<int>? scriptId,
    Value<String>? type,
    Value<String>? name,
    Value<String>? stableId,
    Value<int?>? variantOf,
    Value<String?>? appearanceAnchor,
    Value<String>? boardLayout,
    Value<String>? prompt,
    Value<String?>? imagePath,
    Value<String>? status,
  }) {
    return AssetsCompanion(
      id: id ?? this.id,
      scriptId: scriptId ?? this.scriptId,
      type: type ?? this.type,
      name: name ?? this.name,
      stableId: stableId ?? this.stableId,
      variantOf: variantOf ?? this.variantOf,
      appearanceAnchor: appearanceAnchor ?? this.appearanceAnchor,
      boardLayout: boardLayout ?? this.boardLayout,
      prompt: prompt ?? this.prompt,
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scriptId.present) {
      map['script_id'] = Variable<int>(scriptId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (stableId.present) {
      map['stable_id'] = Variable<String>(stableId.value);
    }
    if (variantOf.present) {
      map['variant_of'] = Variable<int>(variantOf.value);
    }
    if (appearanceAnchor.present) {
      map['appearance_anchor'] = Variable<String>(appearanceAnchor.value);
    }
    if (boardLayout.present) {
      map['board_layout'] = Variable<String>(boardLayout.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetsCompanion(')
          ..write('id: $id, ')
          ..write('scriptId: $scriptId, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('stableId: $stableId, ')
          ..write('variantOf: $variantOf, ')
          ..write('appearanceAnchor: $appearanceAnchor, ')
          ..write('boardLayout: $boardLayout, ')
          ..write('prompt: $prompt, ')
          ..write('imagePath: $imagePath, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $ShotsTable extends Shots with TableInfo<$ShotsTable, Shot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _scriptIdMeta = const VerificationMeta(
    'scriptId',
  );
  @override
  late final GeneratedColumn<int> scriptId = GeneratedColumn<int>(
    'script_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scripts (id)',
    ),
  );
  static const VerificationMeta _globalSeqMeta = const VerificationMeta(
    'globalSeq',
  );
  @override
  late final GeneratedColumn<String> globalSeq = GeneratedColumn<String>(
    'global_seq',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchMeta = const VerificationMeta('batch');
  @override
  late final GeneratedColumn<int> batch = GeneratedColumn<int>(
    'batch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _modelVersionMeta = const VerificationMeta(
    'modelVersion',
  );
  @override
  late final GeneratedColumn<String> modelVersion = GeneratedColumn<String>(
    'model_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _globalTimeRangeMeta = const VerificationMeta(
    'globalTimeRange',
  );
  @override
  late final GeneratedColumn<String> globalTimeRange = GeneratedColumn<String>(
    'global_time_range',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _beatRefsMeta = const VerificationMeta(
    'beatRefs',
  );
  @override
  late final GeneratedColumn<String> beatRefs = GeneratedColumn<String>(
    'beat_refs',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _assetStatesMeta = const VerificationMeta(
    'assetStates',
  );
  @override
  late final GeneratedColumn<String> assetStates = GeneratedColumn<String>(
    'asset_states',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _shotTypeMeta = const VerificationMeta(
    'shotType',
  );
  @override
  late final GeneratedColumn<String> shotType = GeneratedColumn<String>(
    'shot_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sceneIdMeta = const VerificationMeta(
    'sceneId',
  );
  @override
  late final GeneratedColumn<int> sceneId = GeneratedColumn<int>(
    'scene_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('待提示词'),
  );
  static const VerificationMeta _outputPathMeta = const VerificationMeta(
    'outputPath',
  );
  @override
  late final GeneratedColumn<String> outputPath = GeneratedColumn<String>(
    'output_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outputTypeMeta = const VerificationMeta(
    'outputType',
  );
  @override
  late final GeneratedColumn<String> outputType = GeneratedColumn<String>(
    'output_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('image'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scriptId,
    globalSeq,
    batch,
    modelVersion,
    durationMs,
    globalTimeRange,
    beatRefs,
    assetStates,
    shotType,
    sceneId,
    prompt,
    status,
    outputPath,
    outputType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shots';
  @override
  VerificationContext validateIntegrity(
    Insertable<Shot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('script_id')) {
      context.handle(
        _scriptIdMeta,
        scriptId.isAcceptableOrUnknown(data['script_id']!, _scriptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scriptIdMeta);
    }
    if (data.containsKey('global_seq')) {
      context.handle(
        _globalSeqMeta,
        globalSeq.isAcceptableOrUnknown(data['global_seq']!, _globalSeqMeta),
      );
    } else if (isInserting) {
      context.missing(_globalSeqMeta);
    }
    if (data.containsKey('batch')) {
      context.handle(
        _batchMeta,
        batch.isAcceptableOrUnknown(data['batch']!, _batchMeta),
      );
    }
    if (data.containsKey('model_version')) {
      context.handle(
        _modelVersionMeta,
        modelVersion.isAcceptableOrUnknown(
          data['model_version']!,
          _modelVersionMeta,
        ),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('global_time_range')) {
      context.handle(
        _globalTimeRangeMeta,
        globalTimeRange.isAcceptableOrUnknown(
          data['global_time_range']!,
          _globalTimeRangeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_globalTimeRangeMeta);
    }
    if (data.containsKey('beat_refs')) {
      context.handle(
        _beatRefsMeta,
        beatRefs.isAcceptableOrUnknown(data['beat_refs']!, _beatRefsMeta),
      );
    }
    if (data.containsKey('asset_states')) {
      context.handle(
        _assetStatesMeta,
        assetStates.isAcceptableOrUnknown(
          data['asset_states']!,
          _assetStatesMeta,
        ),
      );
    }
    if (data.containsKey('shot_type')) {
      context.handle(
        _shotTypeMeta,
        shotType.isAcceptableOrUnknown(data['shot_type']!, _shotTypeMeta),
      );
    }
    if (data.containsKey('scene_id')) {
      context.handle(
        _sceneIdMeta,
        sceneId.isAcceptableOrUnknown(data['scene_id']!, _sceneIdMeta),
      );
    }
    if (data.containsKey('prompt')) {
      context.handle(
        _promptMeta,
        prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('output_path')) {
      context.handle(
        _outputPathMeta,
        outputPath.isAcceptableOrUnknown(data['output_path']!, _outputPathMeta),
      );
    }
    if (data.containsKey('output_type')) {
      context.handle(
        _outputTypeMeta,
        outputType.isAcceptableOrUnknown(data['output_type']!, _outputTypeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Shot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Shot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scriptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}script_id'],
      )!,
      globalSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}global_seq'],
      )!,
      batch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}batch'],
      )!,
      modelVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_version'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      globalTimeRange: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}global_time_range'],
      )!,
      beatRefs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}beat_refs'],
      )!,
      assetStates: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_states'],
      )!,
      shotType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shot_type'],
      ),
      sceneId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scene_id'],
      ),
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      outputPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}output_path'],
      ),
      outputType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}output_type'],
      )!,
    );
  }

  @override
  $ShotsTable createAlias(String alias) {
    return $ShotsTable(attachedDatabase, alias);
  }
}

class Shot extends DataClass implements Insertable<Shot> {
  final int id;
  final int scriptId;
  final String globalSeq;
  final int batch;
  final String? modelVersion;
  final int durationMs;
  final String globalTimeRange;
  final String beatRefs;
  final String assetStates;
  final String? shotType;
  final int? sceneId;
  final String prompt;
  final String status;
  final String? outputPath;
  final String outputType;
  const Shot({
    required this.id,
    required this.scriptId,
    required this.globalSeq,
    required this.batch,
    this.modelVersion,
    required this.durationMs,
    required this.globalTimeRange,
    required this.beatRefs,
    required this.assetStates,
    this.shotType,
    this.sceneId,
    required this.prompt,
    required this.status,
    this.outputPath,
    required this.outputType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['script_id'] = Variable<int>(scriptId);
    map['global_seq'] = Variable<String>(globalSeq);
    map['batch'] = Variable<int>(batch);
    if (!nullToAbsent || modelVersion != null) {
      map['model_version'] = Variable<String>(modelVersion);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    map['global_time_range'] = Variable<String>(globalTimeRange);
    map['beat_refs'] = Variable<String>(beatRefs);
    map['asset_states'] = Variable<String>(assetStates);
    if (!nullToAbsent || shotType != null) {
      map['shot_type'] = Variable<String>(shotType);
    }
    if (!nullToAbsent || sceneId != null) {
      map['scene_id'] = Variable<int>(sceneId);
    }
    map['prompt'] = Variable<String>(prompt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || outputPath != null) {
      map['output_path'] = Variable<String>(outputPath);
    }
    map['output_type'] = Variable<String>(outputType);
    return map;
  }

  ShotsCompanion toCompanion(bool nullToAbsent) {
    return ShotsCompanion(
      id: Value(id),
      scriptId: Value(scriptId),
      globalSeq: Value(globalSeq),
      batch: Value(batch),
      modelVersion: modelVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(modelVersion),
      durationMs: Value(durationMs),
      globalTimeRange: Value(globalTimeRange),
      beatRefs: Value(beatRefs),
      assetStates: Value(assetStates),
      shotType: shotType == null && nullToAbsent
          ? const Value.absent()
          : Value(shotType),
      sceneId: sceneId == null && nullToAbsent
          ? const Value.absent()
          : Value(sceneId),
      prompt: Value(prompt),
      status: Value(status),
      outputPath: outputPath == null && nullToAbsent
          ? const Value.absent()
          : Value(outputPath),
      outputType: Value(outputType),
    );
  }

  factory Shot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Shot(
      id: serializer.fromJson<int>(json['id']),
      scriptId: serializer.fromJson<int>(json['scriptId']),
      globalSeq: serializer.fromJson<String>(json['globalSeq']),
      batch: serializer.fromJson<int>(json['batch']),
      modelVersion: serializer.fromJson<String?>(json['modelVersion']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      globalTimeRange: serializer.fromJson<String>(json['globalTimeRange']),
      beatRefs: serializer.fromJson<String>(json['beatRefs']),
      assetStates: serializer.fromJson<String>(json['assetStates']),
      shotType: serializer.fromJson<String?>(json['shotType']),
      sceneId: serializer.fromJson<int?>(json['sceneId']),
      prompt: serializer.fromJson<String>(json['prompt']),
      status: serializer.fromJson<String>(json['status']),
      outputPath: serializer.fromJson<String?>(json['outputPath']),
      outputType: serializer.fromJson<String>(json['outputType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scriptId': serializer.toJson<int>(scriptId),
      'globalSeq': serializer.toJson<String>(globalSeq),
      'batch': serializer.toJson<int>(batch),
      'modelVersion': serializer.toJson<String?>(modelVersion),
      'durationMs': serializer.toJson<int>(durationMs),
      'globalTimeRange': serializer.toJson<String>(globalTimeRange),
      'beatRefs': serializer.toJson<String>(beatRefs),
      'assetStates': serializer.toJson<String>(assetStates),
      'shotType': serializer.toJson<String?>(shotType),
      'sceneId': serializer.toJson<int?>(sceneId),
      'prompt': serializer.toJson<String>(prompt),
      'status': serializer.toJson<String>(status),
      'outputPath': serializer.toJson<String?>(outputPath),
      'outputType': serializer.toJson<String>(outputType),
    };
  }

  Shot copyWith({
    int? id,
    int? scriptId,
    String? globalSeq,
    int? batch,
    Value<String?> modelVersion = const Value.absent(),
    int? durationMs,
    String? globalTimeRange,
    String? beatRefs,
    String? assetStates,
    Value<String?> shotType = const Value.absent(),
    Value<int?> sceneId = const Value.absent(),
    String? prompt,
    String? status,
    Value<String?> outputPath = const Value.absent(),
    String? outputType,
  }) => Shot(
    id: id ?? this.id,
    scriptId: scriptId ?? this.scriptId,
    globalSeq: globalSeq ?? this.globalSeq,
    batch: batch ?? this.batch,
    modelVersion: modelVersion.present ? modelVersion.value : this.modelVersion,
    durationMs: durationMs ?? this.durationMs,
    globalTimeRange: globalTimeRange ?? this.globalTimeRange,
    beatRefs: beatRefs ?? this.beatRefs,
    assetStates: assetStates ?? this.assetStates,
    shotType: shotType.present ? shotType.value : this.shotType,
    sceneId: sceneId.present ? sceneId.value : this.sceneId,
    prompt: prompt ?? this.prompt,
    status: status ?? this.status,
    outputPath: outputPath.present ? outputPath.value : this.outputPath,
    outputType: outputType ?? this.outputType,
  );
  Shot copyWithCompanion(ShotsCompanion data) {
    return Shot(
      id: data.id.present ? data.id.value : this.id,
      scriptId: data.scriptId.present ? data.scriptId.value : this.scriptId,
      globalSeq: data.globalSeq.present ? data.globalSeq.value : this.globalSeq,
      batch: data.batch.present ? data.batch.value : this.batch,
      modelVersion: data.modelVersion.present
          ? data.modelVersion.value
          : this.modelVersion,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      globalTimeRange: data.globalTimeRange.present
          ? data.globalTimeRange.value
          : this.globalTimeRange,
      beatRefs: data.beatRefs.present ? data.beatRefs.value : this.beatRefs,
      assetStates: data.assetStates.present
          ? data.assetStates.value
          : this.assetStates,
      shotType: data.shotType.present ? data.shotType.value : this.shotType,
      sceneId: data.sceneId.present ? data.sceneId.value : this.sceneId,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      status: data.status.present ? data.status.value : this.status,
      outputPath: data.outputPath.present
          ? data.outputPath.value
          : this.outputPath,
      outputType: data.outputType.present
          ? data.outputType.value
          : this.outputType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Shot(')
          ..write('id: $id, ')
          ..write('scriptId: $scriptId, ')
          ..write('globalSeq: $globalSeq, ')
          ..write('batch: $batch, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('durationMs: $durationMs, ')
          ..write('globalTimeRange: $globalTimeRange, ')
          ..write('beatRefs: $beatRefs, ')
          ..write('assetStates: $assetStates, ')
          ..write('shotType: $shotType, ')
          ..write('sceneId: $sceneId, ')
          ..write('prompt: $prompt, ')
          ..write('status: $status, ')
          ..write('outputPath: $outputPath, ')
          ..write('outputType: $outputType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scriptId,
    globalSeq,
    batch,
    modelVersion,
    durationMs,
    globalTimeRange,
    beatRefs,
    assetStates,
    shotType,
    sceneId,
    prompt,
    status,
    outputPath,
    outputType,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shot &&
          other.id == this.id &&
          other.scriptId == this.scriptId &&
          other.globalSeq == this.globalSeq &&
          other.batch == this.batch &&
          other.modelVersion == this.modelVersion &&
          other.durationMs == this.durationMs &&
          other.globalTimeRange == this.globalTimeRange &&
          other.beatRefs == this.beatRefs &&
          other.assetStates == this.assetStates &&
          other.shotType == this.shotType &&
          other.sceneId == this.sceneId &&
          other.prompt == this.prompt &&
          other.status == this.status &&
          other.outputPath == this.outputPath &&
          other.outputType == this.outputType);
}

class ShotsCompanion extends UpdateCompanion<Shot> {
  final Value<int> id;
  final Value<int> scriptId;
  final Value<String> globalSeq;
  final Value<int> batch;
  final Value<String?> modelVersion;
  final Value<int> durationMs;
  final Value<String> globalTimeRange;
  final Value<String> beatRefs;
  final Value<String> assetStates;
  final Value<String?> shotType;
  final Value<int?> sceneId;
  final Value<String> prompt;
  final Value<String> status;
  final Value<String?> outputPath;
  final Value<String> outputType;
  const ShotsCompanion({
    this.id = const Value.absent(),
    this.scriptId = const Value.absent(),
    this.globalSeq = const Value.absent(),
    this.batch = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.globalTimeRange = const Value.absent(),
    this.beatRefs = const Value.absent(),
    this.assetStates = const Value.absent(),
    this.shotType = const Value.absent(),
    this.sceneId = const Value.absent(),
    this.prompt = const Value.absent(),
    this.status = const Value.absent(),
    this.outputPath = const Value.absent(),
    this.outputType = const Value.absent(),
  });
  ShotsCompanion.insert({
    this.id = const Value.absent(),
    required int scriptId,
    required String globalSeq,
    this.batch = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.durationMs = const Value.absent(),
    required String globalTimeRange,
    this.beatRefs = const Value.absent(),
    this.assetStates = const Value.absent(),
    this.shotType = const Value.absent(),
    this.sceneId = const Value.absent(),
    this.prompt = const Value.absent(),
    this.status = const Value.absent(),
    this.outputPath = const Value.absent(),
    this.outputType = const Value.absent(),
  }) : scriptId = Value(scriptId),
       globalSeq = Value(globalSeq),
       globalTimeRange = Value(globalTimeRange);
  static Insertable<Shot> custom({
    Expression<int>? id,
    Expression<int>? scriptId,
    Expression<String>? globalSeq,
    Expression<int>? batch,
    Expression<String>? modelVersion,
    Expression<int>? durationMs,
    Expression<String>? globalTimeRange,
    Expression<String>? beatRefs,
    Expression<String>? assetStates,
    Expression<String>? shotType,
    Expression<int>? sceneId,
    Expression<String>? prompt,
    Expression<String>? status,
    Expression<String>? outputPath,
    Expression<String>? outputType,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scriptId != null) 'script_id': scriptId,
      if (globalSeq != null) 'global_seq': globalSeq,
      if (batch != null) 'batch': batch,
      if (modelVersion != null) 'model_version': modelVersion,
      if (durationMs != null) 'duration_ms': durationMs,
      if (globalTimeRange != null) 'global_time_range': globalTimeRange,
      if (beatRefs != null) 'beat_refs': beatRefs,
      if (assetStates != null) 'asset_states': assetStates,
      if (shotType != null) 'shot_type': shotType,
      if (sceneId != null) 'scene_id': sceneId,
      if (prompt != null) 'prompt': prompt,
      if (status != null) 'status': status,
      if (outputPath != null) 'output_path': outputPath,
      if (outputType != null) 'output_type': outputType,
    });
  }

  ShotsCompanion copyWith({
    Value<int>? id,
    Value<int>? scriptId,
    Value<String>? globalSeq,
    Value<int>? batch,
    Value<String?>? modelVersion,
    Value<int>? durationMs,
    Value<String>? globalTimeRange,
    Value<String>? beatRefs,
    Value<String>? assetStates,
    Value<String?>? shotType,
    Value<int?>? sceneId,
    Value<String>? prompt,
    Value<String>? status,
    Value<String?>? outputPath,
    Value<String>? outputType,
  }) {
    return ShotsCompanion(
      id: id ?? this.id,
      scriptId: scriptId ?? this.scriptId,
      globalSeq: globalSeq ?? this.globalSeq,
      batch: batch ?? this.batch,
      modelVersion: modelVersion ?? this.modelVersion,
      durationMs: durationMs ?? this.durationMs,
      globalTimeRange: globalTimeRange ?? this.globalTimeRange,
      beatRefs: beatRefs ?? this.beatRefs,
      assetStates: assetStates ?? this.assetStates,
      shotType: shotType ?? this.shotType,
      sceneId: sceneId ?? this.sceneId,
      prompt: prompt ?? this.prompt,
      status: status ?? this.status,
      outputPath: outputPath ?? this.outputPath,
      outputType: outputType ?? this.outputType,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scriptId.present) {
      map['script_id'] = Variable<int>(scriptId.value);
    }
    if (globalSeq.present) {
      map['global_seq'] = Variable<String>(globalSeq.value);
    }
    if (batch.present) {
      map['batch'] = Variable<int>(batch.value);
    }
    if (modelVersion.present) {
      map['model_version'] = Variable<String>(modelVersion.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (globalTimeRange.present) {
      map['global_time_range'] = Variable<String>(globalTimeRange.value);
    }
    if (beatRefs.present) {
      map['beat_refs'] = Variable<String>(beatRefs.value);
    }
    if (assetStates.present) {
      map['asset_states'] = Variable<String>(assetStates.value);
    }
    if (shotType.present) {
      map['shot_type'] = Variable<String>(shotType.value);
    }
    if (sceneId.present) {
      map['scene_id'] = Variable<int>(sceneId.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (outputPath.present) {
      map['output_path'] = Variable<String>(outputPath.value);
    }
    if (outputType.present) {
      map['output_type'] = Variable<String>(outputType.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShotsCompanion(')
          ..write('id: $id, ')
          ..write('scriptId: $scriptId, ')
          ..write('globalSeq: $globalSeq, ')
          ..write('batch: $batch, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('durationMs: $durationMs, ')
          ..write('globalTimeRange: $globalTimeRange, ')
          ..write('beatRefs: $beatRefs, ')
          ..write('assetStates: $assetStates, ')
          ..write('shotType: $shotType, ')
          ..write('sceneId: $sceneId, ')
          ..write('prompt: $prompt, ')
          ..write('status: $status, ')
          ..write('outputPath: $outputPath, ')
          ..write('outputType: $outputType')
          ..write(')'))
        .toString();
  }
}

class $ShotFramesTable extends ShotFrames
    with TableInfo<$ShotFramesTable, ShotFrame> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShotFramesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _shotIdMeta = const VerificationMeta('shotId');
  @override
  late final GeneratedColumn<int> shotId = GeneratedColumn<int>(
    'shot_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shots (id)',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeRangeMeta = const VerificationMeta(
    'timeRange',
  );
  @override
  late final GeneratedColumn<String> timeRange = GeneratedColumn<String>(
    'time_range',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shotSizeMeta = const VerificationMeta(
    'shotSize',
  );
  @override
  late final GeneratedColumn<String> shotSize = GeneratedColumn<String>(
    'shot_size',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _angleMeta = const VerificationMeta('angle');
  @override
  late final GeneratedColumn<String> angle = GeneratedColumn<String>(
    'angle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cameraMeta = const VerificationMeta('camera');
  @override
  late final GeneratedColumn<String> camera = GeneratedColumn<String>(
    'camera',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _blockingMeta = const VerificationMeta(
    'blocking',
  );
  @override
  late final GeneratedColumn<String> blocking = GeneratedColumn<String>(
    'blocking',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _performanceMeta = const VerificationMeta(
    'performance',
  );
  @override
  late final GeneratedColumn<String> performance = GeneratedColumn<String>(
    'performance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dialogueMeta = const VerificationMeta(
    'dialogue',
  );
  @override
  late final GeneratedColumn<String> dialogue = GeneratedColumn<String>(
    'dialogue',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shotId,
    seq,
    timeRange,
    subject,
    shotSize,
    angle,
    camera,
    blocking,
    performance,
    dialogue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shot_frames';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShotFrame> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('shot_id')) {
      context.handle(
        _shotIdMeta,
        shotId.isAcceptableOrUnknown(data['shot_id']!, _shotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shotIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('time_range')) {
      context.handle(
        _timeRangeMeta,
        timeRange.isAcceptableOrUnknown(data['time_range']!, _timeRangeMeta),
      );
    } else if (isInserting) {
      context.missing(_timeRangeMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('shot_size')) {
      context.handle(
        _shotSizeMeta,
        shotSize.isAcceptableOrUnknown(data['shot_size']!, _shotSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_shotSizeMeta);
    }
    if (data.containsKey('angle')) {
      context.handle(
        _angleMeta,
        angle.isAcceptableOrUnknown(data['angle']!, _angleMeta),
      );
    } else if (isInserting) {
      context.missing(_angleMeta);
    }
    if (data.containsKey('camera')) {
      context.handle(
        _cameraMeta,
        camera.isAcceptableOrUnknown(data['camera']!, _cameraMeta),
      );
    }
    if (data.containsKey('blocking')) {
      context.handle(
        _blockingMeta,
        blocking.isAcceptableOrUnknown(data['blocking']!, _blockingMeta),
      );
    }
    if (data.containsKey('performance')) {
      context.handle(
        _performanceMeta,
        performance.isAcceptableOrUnknown(
          data['performance']!,
          _performanceMeta,
        ),
      );
    }
    if (data.containsKey('dialogue')) {
      context.handle(
        _dialogueMeta,
        dialogue.isAcceptableOrUnknown(data['dialogue']!, _dialogueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShotFrame map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShotFrame(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      shotId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shot_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      timeRange: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_range'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      shotSize: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shot_size'],
      )!,
      angle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}angle'],
      )!,
      camera: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}camera'],
      )!,
      blocking: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blocking'],
      )!,
      performance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}performance'],
      )!,
      dialogue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dialogue'],
      ),
    );
  }

  @override
  $ShotFramesTable createAlias(String alias) {
    return $ShotFramesTable(attachedDatabase, alias);
  }
}

class ShotFrame extends DataClass implements Insertable<ShotFrame> {
  final int id;
  final int shotId;
  final int seq;
  final String timeRange;
  final String subject;
  final String shotSize;
  final String angle;
  final String camera;
  final String blocking;
  final String performance;
  final String? dialogue;
  const ShotFrame({
    required this.id,
    required this.shotId,
    required this.seq,
    required this.timeRange,
    required this.subject,
    required this.shotSize,
    required this.angle,
    required this.camera,
    required this.blocking,
    required this.performance,
    this.dialogue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['shot_id'] = Variable<int>(shotId);
    map['seq'] = Variable<int>(seq);
    map['time_range'] = Variable<String>(timeRange);
    map['subject'] = Variable<String>(subject);
    map['shot_size'] = Variable<String>(shotSize);
    map['angle'] = Variable<String>(angle);
    map['camera'] = Variable<String>(camera);
    map['blocking'] = Variable<String>(blocking);
    map['performance'] = Variable<String>(performance);
    if (!nullToAbsent || dialogue != null) {
      map['dialogue'] = Variable<String>(dialogue);
    }
    return map;
  }

  ShotFramesCompanion toCompanion(bool nullToAbsent) {
    return ShotFramesCompanion(
      id: Value(id),
      shotId: Value(shotId),
      seq: Value(seq),
      timeRange: Value(timeRange),
      subject: Value(subject),
      shotSize: Value(shotSize),
      angle: Value(angle),
      camera: Value(camera),
      blocking: Value(blocking),
      performance: Value(performance),
      dialogue: dialogue == null && nullToAbsent
          ? const Value.absent()
          : Value(dialogue),
    );
  }

  factory ShotFrame.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShotFrame(
      id: serializer.fromJson<int>(json['id']),
      shotId: serializer.fromJson<int>(json['shotId']),
      seq: serializer.fromJson<int>(json['seq']),
      timeRange: serializer.fromJson<String>(json['timeRange']),
      subject: serializer.fromJson<String>(json['subject']),
      shotSize: serializer.fromJson<String>(json['shotSize']),
      angle: serializer.fromJson<String>(json['angle']),
      camera: serializer.fromJson<String>(json['camera']),
      blocking: serializer.fromJson<String>(json['blocking']),
      performance: serializer.fromJson<String>(json['performance']),
      dialogue: serializer.fromJson<String?>(json['dialogue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'shotId': serializer.toJson<int>(shotId),
      'seq': serializer.toJson<int>(seq),
      'timeRange': serializer.toJson<String>(timeRange),
      'subject': serializer.toJson<String>(subject),
      'shotSize': serializer.toJson<String>(shotSize),
      'angle': serializer.toJson<String>(angle),
      'camera': serializer.toJson<String>(camera),
      'blocking': serializer.toJson<String>(blocking),
      'performance': serializer.toJson<String>(performance),
      'dialogue': serializer.toJson<String?>(dialogue),
    };
  }

  ShotFrame copyWith({
    int? id,
    int? shotId,
    int? seq,
    String? timeRange,
    String? subject,
    String? shotSize,
    String? angle,
    String? camera,
    String? blocking,
    String? performance,
    Value<String?> dialogue = const Value.absent(),
  }) => ShotFrame(
    id: id ?? this.id,
    shotId: shotId ?? this.shotId,
    seq: seq ?? this.seq,
    timeRange: timeRange ?? this.timeRange,
    subject: subject ?? this.subject,
    shotSize: shotSize ?? this.shotSize,
    angle: angle ?? this.angle,
    camera: camera ?? this.camera,
    blocking: blocking ?? this.blocking,
    performance: performance ?? this.performance,
    dialogue: dialogue.present ? dialogue.value : this.dialogue,
  );
  ShotFrame copyWithCompanion(ShotFramesCompanion data) {
    return ShotFrame(
      id: data.id.present ? data.id.value : this.id,
      shotId: data.shotId.present ? data.shotId.value : this.shotId,
      seq: data.seq.present ? data.seq.value : this.seq,
      timeRange: data.timeRange.present ? data.timeRange.value : this.timeRange,
      subject: data.subject.present ? data.subject.value : this.subject,
      shotSize: data.shotSize.present ? data.shotSize.value : this.shotSize,
      angle: data.angle.present ? data.angle.value : this.angle,
      camera: data.camera.present ? data.camera.value : this.camera,
      blocking: data.blocking.present ? data.blocking.value : this.blocking,
      performance: data.performance.present
          ? data.performance.value
          : this.performance,
      dialogue: data.dialogue.present ? data.dialogue.value : this.dialogue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShotFrame(')
          ..write('id: $id, ')
          ..write('shotId: $shotId, ')
          ..write('seq: $seq, ')
          ..write('timeRange: $timeRange, ')
          ..write('subject: $subject, ')
          ..write('shotSize: $shotSize, ')
          ..write('angle: $angle, ')
          ..write('camera: $camera, ')
          ..write('blocking: $blocking, ')
          ..write('performance: $performance, ')
          ..write('dialogue: $dialogue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    shotId,
    seq,
    timeRange,
    subject,
    shotSize,
    angle,
    camera,
    blocking,
    performance,
    dialogue,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShotFrame &&
          other.id == this.id &&
          other.shotId == this.shotId &&
          other.seq == this.seq &&
          other.timeRange == this.timeRange &&
          other.subject == this.subject &&
          other.shotSize == this.shotSize &&
          other.angle == this.angle &&
          other.camera == this.camera &&
          other.blocking == this.blocking &&
          other.performance == this.performance &&
          other.dialogue == this.dialogue);
}

class ShotFramesCompanion extends UpdateCompanion<ShotFrame> {
  final Value<int> id;
  final Value<int> shotId;
  final Value<int> seq;
  final Value<String> timeRange;
  final Value<String> subject;
  final Value<String> shotSize;
  final Value<String> angle;
  final Value<String> camera;
  final Value<String> blocking;
  final Value<String> performance;
  final Value<String?> dialogue;
  const ShotFramesCompanion({
    this.id = const Value.absent(),
    this.shotId = const Value.absent(),
    this.seq = const Value.absent(),
    this.timeRange = const Value.absent(),
    this.subject = const Value.absent(),
    this.shotSize = const Value.absent(),
    this.angle = const Value.absent(),
    this.camera = const Value.absent(),
    this.blocking = const Value.absent(),
    this.performance = const Value.absent(),
    this.dialogue = const Value.absent(),
  });
  ShotFramesCompanion.insert({
    this.id = const Value.absent(),
    required int shotId,
    required int seq,
    required String timeRange,
    required String subject,
    required String shotSize,
    required String angle,
    this.camera = const Value.absent(),
    this.blocking = const Value.absent(),
    this.performance = const Value.absent(),
    this.dialogue = const Value.absent(),
  }) : shotId = Value(shotId),
       seq = Value(seq),
       timeRange = Value(timeRange),
       subject = Value(subject),
       shotSize = Value(shotSize),
       angle = Value(angle);
  static Insertable<ShotFrame> custom({
    Expression<int>? id,
    Expression<int>? shotId,
    Expression<int>? seq,
    Expression<String>? timeRange,
    Expression<String>? subject,
    Expression<String>? shotSize,
    Expression<String>? angle,
    Expression<String>? camera,
    Expression<String>? blocking,
    Expression<String>? performance,
    Expression<String>? dialogue,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shotId != null) 'shot_id': shotId,
      if (seq != null) 'seq': seq,
      if (timeRange != null) 'time_range': timeRange,
      if (subject != null) 'subject': subject,
      if (shotSize != null) 'shot_size': shotSize,
      if (angle != null) 'angle': angle,
      if (camera != null) 'camera': camera,
      if (blocking != null) 'blocking': blocking,
      if (performance != null) 'performance': performance,
      if (dialogue != null) 'dialogue': dialogue,
    });
  }

  ShotFramesCompanion copyWith({
    Value<int>? id,
    Value<int>? shotId,
    Value<int>? seq,
    Value<String>? timeRange,
    Value<String>? subject,
    Value<String>? shotSize,
    Value<String>? angle,
    Value<String>? camera,
    Value<String>? blocking,
    Value<String>? performance,
    Value<String?>? dialogue,
  }) {
    return ShotFramesCompanion(
      id: id ?? this.id,
      shotId: shotId ?? this.shotId,
      seq: seq ?? this.seq,
      timeRange: timeRange ?? this.timeRange,
      subject: subject ?? this.subject,
      shotSize: shotSize ?? this.shotSize,
      angle: angle ?? this.angle,
      camera: camera ?? this.camera,
      blocking: blocking ?? this.blocking,
      performance: performance ?? this.performance,
      dialogue: dialogue ?? this.dialogue,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (shotId.present) {
      map['shot_id'] = Variable<int>(shotId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (timeRange.present) {
      map['time_range'] = Variable<String>(timeRange.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (shotSize.present) {
      map['shot_size'] = Variable<String>(shotSize.value);
    }
    if (angle.present) {
      map['angle'] = Variable<String>(angle.value);
    }
    if (camera.present) {
      map['camera'] = Variable<String>(camera.value);
    }
    if (blocking.present) {
      map['blocking'] = Variable<String>(blocking.value);
    }
    if (performance.present) {
      map['performance'] = Variable<String>(performance.value);
    }
    if (dialogue.present) {
      map['dialogue'] = Variable<String>(dialogue.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShotFramesCompanion(')
          ..write('id: $id, ')
          ..write('shotId: $shotId, ')
          ..write('seq: $seq, ')
          ..write('timeRange: $timeRange, ')
          ..write('subject: $subject, ')
          ..write('shotSize: $shotSize, ')
          ..write('angle: $angle, ')
          ..write('camera: $camera, ')
          ..write('blocking: $blocking, ')
          ..write('performance: $performance, ')
          ..write('dialogue: $dialogue')
          ..write(')'))
        .toString();
  }
}

class $AssetRefsTable extends AssetRefs
    with TableInfo<$AssetRefsTable, AssetRef> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetRefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _shotIdMeta = const VerificationMeta('shotId');
  @override
  late final GeneratedColumn<int> shotId = GeneratedColumn<int>(
    'shot_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shots (id)',
    ),
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<int> assetId = GeneratedColumn<int>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES assets (id)',
    ),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, shotId, assetId, role, order];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_refs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetRef> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('shot_id')) {
      context.handle(
        _shotIdMeta,
        shotId.isAcceptableOrUnknown(data['shot_id']!, _shotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shotIdMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetRef map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetRef(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      shotId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shot_id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}asset_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
    );
  }

  @override
  $AssetRefsTable createAlias(String alias) {
    return $AssetRefsTable(attachedDatabase, alias);
  }
}

class AssetRef extends DataClass implements Insertable<AssetRef> {
  final int id;
  final int shotId;
  final int assetId;
  final String role;
  final int order;
  const AssetRef({
    required this.id,
    required this.shotId,
    required this.assetId,
    required this.role,
    required this.order,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['shot_id'] = Variable<int>(shotId);
    map['asset_id'] = Variable<int>(assetId);
    map['role'] = Variable<String>(role);
    map['order'] = Variable<int>(order);
    return map;
  }

  AssetRefsCompanion toCompanion(bool nullToAbsent) {
    return AssetRefsCompanion(
      id: Value(id),
      shotId: Value(shotId),
      assetId: Value(assetId),
      role: Value(role),
      order: Value(order),
    );
  }

  factory AssetRef.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetRef(
      id: serializer.fromJson<int>(json['id']),
      shotId: serializer.fromJson<int>(json['shotId']),
      assetId: serializer.fromJson<int>(json['assetId']),
      role: serializer.fromJson<String>(json['role']),
      order: serializer.fromJson<int>(json['order']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'shotId': serializer.toJson<int>(shotId),
      'assetId': serializer.toJson<int>(assetId),
      'role': serializer.toJson<String>(role),
      'order': serializer.toJson<int>(order),
    };
  }

  AssetRef copyWith({
    int? id,
    int? shotId,
    int? assetId,
    String? role,
    int? order,
  }) => AssetRef(
    id: id ?? this.id,
    shotId: shotId ?? this.shotId,
    assetId: assetId ?? this.assetId,
    role: role ?? this.role,
    order: order ?? this.order,
  );
  AssetRef copyWithCompanion(AssetRefsCompanion data) {
    return AssetRef(
      id: data.id.present ? data.id.value : this.id,
      shotId: data.shotId.present ? data.shotId.value : this.shotId,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      role: data.role.present ? data.role.value : this.role,
      order: data.order.present ? data.order.value : this.order,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetRef(')
          ..write('id: $id, ')
          ..write('shotId: $shotId, ')
          ..write('assetId: $assetId, ')
          ..write('role: $role, ')
          ..write('order: $order')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, shotId, assetId, role, order);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetRef &&
          other.id == this.id &&
          other.shotId == this.shotId &&
          other.assetId == this.assetId &&
          other.role == this.role &&
          other.order == this.order);
}

class AssetRefsCompanion extends UpdateCompanion<AssetRef> {
  final Value<int> id;
  final Value<int> shotId;
  final Value<int> assetId;
  final Value<String> role;
  final Value<int> order;
  const AssetRefsCompanion({
    this.id = const Value.absent(),
    this.shotId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.role = const Value.absent(),
    this.order = const Value.absent(),
  });
  AssetRefsCompanion.insert({
    this.id = const Value.absent(),
    required int shotId,
    required int assetId,
    required String role,
    this.order = const Value.absent(),
  }) : shotId = Value(shotId),
       assetId = Value(assetId),
       role = Value(role);
  static Insertable<AssetRef> custom({
    Expression<int>? id,
    Expression<int>? shotId,
    Expression<int>? assetId,
    Expression<String>? role,
    Expression<int>? order,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shotId != null) 'shot_id': shotId,
      if (assetId != null) 'asset_id': assetId,
      if (role != null) 'role': role,
      if (order != null) 'order': order,
    });
  }

  AssetRefsCompanion copyWith({
    Value<int>? id,
    Value<int>? shotId,
    Value<int>? assetId,
    Value<String>? role,
    Value<int>? order,
  }) {
    return AssetRefsCompanion(
      id: id ?? this.id,
      shotId: shotId ?? this.shotId,
      assetId: assetId ?? this.assetId,
      role: role ?? this.role,
      order: order ?? this.order,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (shotId.present) {
      map['shot_id'] = Variable<int>(shotId.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<int>(assetId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetRefsCompanion(')
          ..write('id: $id, ')
          ..write('shotId: $shotId, ')
          ..write('assetId: $assetId, ')
          ..write('role: $role, ')
          ..write('order: $order')
          ..write(')'))
        .toString();
  }
}

class $VideoTasksTable extends VideoTasks
    with TableInfo<$VideoTasksTable, VideoTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VideoTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _shotIdMeta = const VerificationMeta('shotId');
  @override
  late final GeneratedColumn<int> shotId = GeneratedColumn<int>(
    'shot_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shots (id)',
    ),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('排队'),
  );
  static const VerificationMeta _paramsJsonMeta = const VerificationMeta(
    'paramsJson',
  );
  @override
  late final GeneratedColumn<String> paramsJson = GeneratedColumn<String>(
    'params_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outputPathMeta = const VerificationMeta(
    'outputPath',
  );
  @override
  late final GeneratedColumn<String> outputPath = GeneratedColumn<String>(
    'output_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    shotId,
    taskId,
    providerId,
    status,
    paramsJson,
    error,
    outputPath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'video_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<VideoTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('shot_id')) {
      context.handle(
        _shotIdMeta,
        shotId.isAcceptableOrUnknown(data['shot_id']!, _shotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shotIdMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('params_json')) {
      context.handle(
        _paramsJsonMeta,
        paramsJson.isAcceptableOrUnknown(data['params_json']!, _paramsJsonMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('output_path')) {
      context.handle(
        _outputPathMeta,
        outputPath.isAcceptableOrUnknown(data['output_path']!, _outputPathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VideoTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VideoTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      shotId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shot_id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      paramsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}params_json'],
      )!,
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      outputPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}output_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VideoTasksTable createAlias(String alias) {
    return $VideoTasksTable(attachedDatabase, alias);
  }
}

class VideoTask extends DataClass implements Insertable<VideoTask> {
  final int id;
  final int shotId;
  final String taskId;
  final String providerId;
  final String status;
  final String paramsJson;
  final String? error;
  final String? outputPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  const VideoTask({
    required this.id,
    required this.shotId,
    required this.taskId,
    required this.providerId,
    required this.status,
    required this.paramsJson,
    this.error,
    this.outputPath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['shot_id'] = Variable<int>(shotId);
    map['task_id'] = Variable<String>(taskId);
    map['provider_id'] = Variable<String>(providerId);
    map['status'] = Variable<String>(status);
    map['params_json'] = Variable<String>(paramsJson);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    if (!nullToAbsent || outputPath != null) {
      map['output_path'] = Variable<String>(outputPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VideoTasksCompanion toCompanion(bool nullToAbsent) {
    return VideoTasksCompanion(
      id: Value(id),
      shotId: Value(shotId),
      taskId: Value(taskId),
      providerId: Value(providerId),
      status: Value(status),
      paramsJson: Value(paramsJson),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      outputPath: outputPath == null && nullToAbsent
          ? const Value.absent()
          : Value(outputPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VideoTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VideoTask(
      id: serializer.fromJson<int>(json['id']),
      shotId: serializer.fromJson<int>(json['shotId']),
      taskId: serializer.fromJson<String>(json['taskId']),
      providerId: serializer.fromJson<String>(json['providerId']),
      status: serializer.fromJson<String>(json['status']),
      paramsJson: serializer.fromJson<String>(json['paramsJson']),
      error: serializer.fromJson<String?>(json['error']),
      outputPath: serializer.fromJson<String?>(json['outputPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'shotId': serializer.toJson<int>(shotId),
      'taskId': serializer.toJson<String>(taskId),
      'providerId': serializer.toJson<String>(providerId),
      'status': serializer.toJson<String>(status),
      'paramsJson': serializer.toJson<String>(paramsJson),
      'error': serializer.toJson<String?>(error),
      'outputPath': serializer.toJson<String?>(outputPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VideoTask copyWith({
    int? id,
    int? shotId,
    String? taskId,
    String? providerId,
    String? status,
    String? paramsJson,
    Value<String?> error = const Value.absent(),
    Value<String?> outputPath = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => VideoTask(
    id: id ?? this.id,
    shotId: shotId ?? this.shotId,
    taskId: taskId ?? this.taskId,
    providerId: providerId ?? this.providerId,
    status: status ?? this.status,
    paramsJson: paramsJson ?? this.paramsJson,
    error: error.present ? error.value : this.error,
    outputPath: outputPath.present ? outputPath.value : this.outputPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VideoTask copyWithCompanion(VideoTasksCompanion data) {
    return VideoTask(
      id: data.id.present ? data.id.value : this.id,
      shotId: data.shotId.present ? data.shotId.value : this.shotId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      status: data.status.present ? data.status.value : this.status,
      paramsJson: data.paramsJson.present
          ? data.paramsJson.value
          : this.paramsJson,
      error: data.error.present ? data.error.value : this.error,
      outputPath: data.outputPath.present
          ? data.outputPath.value
          : this.outputPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VideoTask(')
          ..write('id: $id, ')
          ..write('shotId: $shotId, ')
          ..write('taskId: $taskId, ')
          ..write('providerId: $providerId, ')
          ..write('status: $status, ')
          ..write('paramsJson: $paramsJson, ')
          ..write('error: $error, ')
          ..write('outputPath: $outputPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    shotId,
    taskId,
    providerId,
    status,
    paramsJson,
    error,
    outputPath,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VideoTask &&
          other.id == this.id &&
          other.shotId == this.shotId &&
          other.taskId == this.taskId &&
          other.providerId == this.providerId &&
          other.status == this.status &&
          other.paramsJson == this.paramsJson &&
          other.error == this.error &&
          other.outputPath == this.outputPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VideoTasksCompanion extends UpdateCompanion<VideoTask> {
  final Value<int> id;
  final Value<int> shotId;
  final Value<String> taskId;
  final Value<String> providerId;
  final Value<String> status;
  final Value<String> paramsJson;
  final Value<String?> error;
  final Value<String?> outputPath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const VideoTasksCompanion({
    this.id = const Value.absent(),
    this.shotId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.providerId = const Value.absent(),
    this.status = const Value.absent(),
    this.paramsJson = const Value.absent(),
    this.error = const Value.absent(),
    this.outputPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  VideoTasksCompanion.insert({
    this.id = const Value.absent(),
    required int shotId,
    required String taskId,
    required String providerId,
    this.status = const Value.absent(),
    this.paramsJson = const Value.absent(),
    this.error = const Value.absent(),
    this.outputPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : shotId = Value(shotId),
       taskId = Value(taskId),
       providerId = Value(providerId);
  static Insertable<VideoTask> custom({
    Expression<int>? id,
    Expression<int>? shotId,
    Expression<String>? taskId,
    Expression<String>? providerId,
    Expression<String>? status,
    Expression<String>? paramsJson,
    Expression<String>? error,
    Expression<String>? outputPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shotId != null) 'shot_id': shotId,
      if (taskId != null) 'task_id': taskId,
      if (providerId != null) 'provider_id': providerId,
      if (status != null) 'status': status,
      if (paramsJson != null) 'params_json': paramsJson,
      if (error != null) 'error': error,
      if (outputPath != null) 'output_path': outputPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  VideoTasksCompanion copyWith({
    Value<int>? id,
    Value<int>? shotId,
    Value<String>? taskId,
    Value<String>? providerId,
    Value<String>? status,
    Value<String>? paramsJson,
    Value<String?>? error,
    Value<String?>? outputPath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return VideoTasksCompanion(
      id: id ?? this.id,
      shotId: shotId ?? this.shotId,
      taskId: taskId ?? this.taskId,
      providerId: providerId ?? this.providerId,
      status: status ?? this.status,
      paramsJson: paramsJson ?? this.paramsJson,
      error: error ?? this.error,
      outputPath: outputPath ?? this.outputPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (shotId.present) {
      map['shot_id'] = Variable<int>(shotId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (paramsJson.present) {
      map['params_json'] = Variable<String>(paramsJson.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (outputPath.present) {
      map['output_path'] = Variable<String>(outputPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VideoTasksCompanion(')
          ..write('id: $id, ')
          ..write('shotId: $shotId, ')
          ..write('taskId: $taskId, ')
          ..write('providerId: $providerId, ')
          ..write('status: $status, ')
          ..write('paramsJson: $paramsJson, ')
          ..write('error: $error, ')
          ..write('outputPath: $outputPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ProviderConfigsTable extends ProviderConfigs
    with TableInfo<$ProviderConfigsTable, ProviderConfig> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupMeta = const VerificationMeta('group');
  @override
  late final GeneratedColumn<String> group = GeneratedColumn<String>(
    'group',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protocolMeta = const VerificationMeta(
    'protocol',
  );
  @override
  late final GeneratedColumn<String> protocol = GeneratedColumn<String>(
    'protocol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelsMeta = const VerificationMeta('models');
  @override
  late final GeneratedColumn<String> models = GeneratedColumn<String>(
    'models',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _readmeMeta = const VerificationMeta('readme');
  @override
  late final GeneratedColumn<String> readme = GeneratedColumn<String>(
    'readme',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    group,
    label,
    baseUrl,
    protocol,
    models,
    readme,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderConfig> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group')) {
      context.handle(
        _groupMeta,
        group.isAcceptableOrUnknown(data['group']!, _groupMeta),
      );
    } else if (isInserting) {
      context.missing(_groupMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('protocol')) {
      context.handle(
        _protocolMeta,
        protocol.isAcceptableOrUnknown(data['protocol']!, _protocolMeta),
      );
    } else if (isInserting) {
      context.missing(_protocolMeta);
    }
    if (data.containsKey('models')) {
      context.handle(
        _modelsMeta,
        models.isAcceptableOrUnknown(data['models']!, _modelsMeta),
      );
    }
    if (data.containsKey('readme')) {
      context.handle(
        _readmeMeta,
        readme.isAcceptableOrUnknown(data['readme']!, _readmeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProviderConfig map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderConfig(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      group: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      )!,
      protocol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}protocol'],
      )!,
      models: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}models'],
      )!,
      readme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}readme'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProviderConfigsTable createAlias(String alias) {
    return $ProviderConfigsTable(attachedDatabase, alias);
  }
}

class ProviderConfig extends DataClass implements Insertable<ProviderConfig> {
  final String id;
  final String group;
  final String label;
  final String baseUrl;
  final String protocol;
  final String models;
  final String? readme;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ProviderConfig({
    required this.id,
    required this.group,
    required this.label,
    required this.baseUrl,
    required this.protocol,
    required this.models,
    this.readme,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group'] = Variable<String>(group);
    map['label'] = Variable<String>(label);
    map['base_url'] = Variable<String>(baseUrl);
    map['protocol'] = Variable<String>(protocol);
    map['models'] = Variable<String>(models);
    if (!nullToAbsent || readme != null) {
      map['readme'] = Variable<String>(readme);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProviderConfigsCompanion toCompanion(bool nullToAbsent) {
    return ProviderConfigsCompanion(
      id: Value(id),
      group: Value(group),
      label: Value(label),
      baseUrl: Value(baseUrl),
      protocol: Value(protocol),
      models: Value(models),
      readme: readme == null && nullToAbsent
          ? const Value.absent()
          : Value(readme),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProviderConfig.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderConfig(
      id: serializer.fromJson<String>(json['id']),
      group: serializer.fromJson<String>(json['group']),
      label: serializer.fromJson<String>(json['label']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      protocol: serializer.fromJson<String>(json['protocol']),
      models: serializer.fromJson<String>(json['models']),
      readme: serializer.fromJson<String?>(json['readme']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'group': serializer.toJson<String>(group),
      'label': serializer.toJson<String>(label),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'protocol': serializer.toJson<String>(protocol),
      'models': serializer.toJson<String>(models),
      'readme': serializer.toJson<String?>(readme),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProviderConfig copyWith({
    String? id,
    String? group,
    String? label,
    String? baseUrl,
    String? protocol,
    String? models,
    Value<String?> readme = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProviderConfig(
    id: id ?? this.id,
    group: group ?? this.group,
    label: label ?? this.label,
    baseUrl: baseUrl ?? this.baseUrl,
    protocol: protocol ?? this.protocol,
    models: models ?? this.models,
    readme: readme.present ? readme.value : this.readme,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProviderConfig copyWithCompanion(ProviderConfigsCompanion data) {
    return ProviderConfig(
      id: data.id.present ? data.id.value : this.id,
      group: data.group.present ? data.group.value : this.group,
      label: data.label.present ? data.label.value : this.label,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      protocol: data.protocol.present ? data.protocol.value : this.protocol,
      models: data.models.present ? data.models.value : this.models,
      readme: data.readme.present ? data.readme.value : this.readme,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderConfig(')
          ..write('id: $id, ')
          ..write('group: $group, ')
          ..write('label: $label, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('protocol: $protocol, ')
          ..write('models: $models, ')
          ..write('readme: $readme, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    group,
    label,
    baseUrl,
    protocol,
    models,
    readme,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderConfig &&
          other.id == this.id &&
          other.group == this.group &&
          other.label == this.label &&
          other.baseUrl == this.baseUrl &&
          other.protocol == this.protocol &&
          other.models == this.models &&
          other.readme == this.readme &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProviderConfigsCompanion extends UpdateCompanion<ProviderConfig> {
  final Value<String> id;
  final Value<String> group;
  final Value<String> label;
  final Value<String> baseUrl;
  final Value<String> protocol;
  final Value<String> models;
  final Value<String?> readme;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProviderConfigsCompanion({
    this.id = const Value.absent(),
    this.group = const Value.absent(),
    this.label = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.protocol = const Value.absent(),
    this.models = const Value.absent(),
    this.readme = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderConfigsCompanion.insert({
    required String id,
    required String group,
    required String label,
    required String baseUrl,
    required String protocol,
    this.models = const Value.absent(),
    this.readme = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       group = Value(group),
       label = Value(label),
       baseUrl = Value(baseUrl),
       protocol = Value(protocol);
  static Insertable<ProviderConfig> custom({
    Expression<String>? id,
    Expression<String>? group,
    Expression<String>? label,
    Expression<String>? baseUrl,
    Expression<String>? protocol,
    Expression<String>? models,
    Expression<String>? readme,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (group != null) 'group': group,
      if (label != null) 'label': label,
      if (baseUrl != null) 'base_url': baseUrl,
      if (protocol != null) 'protocol': protocol,
      if (models != null) 'models': models,
      if (readme != null) 'readme': readme,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProviderConfigsCompanion copyWith({
    Value<String>? id,
    Value<String>? group,
    Value<String>? label,
    Value<String>? baseUrl,
    Value<String>? protocol,
    Value<String>? models,
    Value<String?>? readme,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProviderConfigsCompanion(
      id: id ?? this.id,
      group: group ?? this.group,
      label: label ?? this.label,
      baseUrl: baseUrl ?? this.baseUrl,
      protocol: protocol ?? this.protocol,
      models: models ?? this.models,
      readme: readme ?? this.readme,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (group.present) {
      map['group'] = Variable<String>(group.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (protocol.present) {
      map['protocol'] = Variable<String>(protocol.value);
    }
    if (models.present) {
      map['models'] = Variable<String>(models.value);
    }
    if (readme.present) {
      map['readme'] = Variable<String>(readme.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderConfigsCompanion(')
          ..write('id: $id, ')
          ..write('group: $group, ')
          ..write('label: $label, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('protocol: $protocol, ')
          ..write('models: $models, ')
          ..write('readme: $readme, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $NovelBooksTable novelBooks = $NovelBooksTable(this);
  late final $ChaptersTable chapters = $ChaptersTable(this);
  late final $ChapterRevisionsTable chapterRevisions = $ChapterRevisionsTable(
    this,
  );
  late final $TruthFilesTable truthFiles = $TruthFilesTable(this);
  late final $ScriptsTable scripts = $ScriptsTable(this);
  late final $ScriptRevisionsTable scriptRevisions = $ScriptRevisionsTable(
    this,
  );
  late final $ScenesTable scenes = $ScenesTable(this);
  late final $BeatsTable beats = $BeatsTable(this);
  late final $AssetsTable assets = $AssetsTable(this);
  late final $ShotsTable shots = $ShotsTable(this);
  late final $ShotFramesTable shotFrames = $ShotFramesTable(this);
  late final $AssetRefsTable assetRefs = $AssetRefsTable(this);
  late final $VideoTasksTable videoTasks = $VideoTasksTable(this);
  late final $ProviderConfigsTable providerConfigs = $ProviderConfigsTable(
    this,
  );
  late final ProjectDao projectDao = ProjectDao(this as AppDatabase);
  late final NovelDao novelDao = NovelDao(this as AppDatabase);
  late final ChapterRevisionDao chapterRevisionDao = ChapterRevisionDao(
    this as AppDatabase,
  );
  late final TruthFileDao truthFileDao = TruthFileDao(this as AppDatabase);
  late final ScriptDao scriptDao = ScriptDao(this as AppDatabase);
  late final SceneDao sceneDao = SceneDao(this as AppDatabase);
  late final ScriptRevisionDao scriptRevisionDao = ScriptRevisionDao(
    this as AppDatabase,
  );
  late final BeatDao beatDao = BeatDao(this as AppDatabase);
  late final AssetDao assetDao = AssetDao(this as AppDatabase);
  late final AssetRefDao assetRefDao = AssetRefDao(this as AppDatabase);
  late final ShotDao shotDao = ShotDao(this as AppDatabase);
  late final ShotFrameDao shotFrameDao = ShotFrameDao(this as AppDatabase);
  late final VideoTaskDao videoTaskDao = VideoTaskDao(this as AppDatabase);
  late final ProviderDao providerDao = ProviderDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    projects,
    novelBooks,
    chapters,
    chapterRevisions,
    truthFiles,
    scripts,
    scriptRevisions,
    scenes,
    beats,
    assets,
    shots,
    shotFrames,
    assetRefs,
    videoTasks,
    providerConfigs,
  ];
}

typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> coverPath,
  Value<String?> genre,
  Value<String?> description,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> coverPath,
  Value<String?> genre,
  Value<String?> description,
  Value<String> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$ProjectsTableReferences
    extends BaseReferences<_$AppDatabase, $ProjectsTable, Project> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NovelBooksTable, List<NovelBook>>
  _novelBooksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.novelBooks,
    aliasName: 'projects__id__novel_books__project_id',
  );

  $$NovelBooksTableProcessedTableManager get novelBooksRefs {
    final manager = $$NovelBooksTableTableManager(
      $_db,
      $_db.novelBooks,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_novelBooksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> novelBooksRefs(
    Expression<bool> Function($$NovelBooksTableFilterComposer f) f,
  ) {
    final $$NovelBooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.novelBooks,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NovelBooksTableFilterComposer(
            $db: $db,
            $table: $db.novelBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> novelBooksRefs<T extends Object>(
    Expression<T> Function($$NovelBooksTableAnnotationComposer a) f,
  ) {
    final $$NovelBooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.novelBooks,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NovelBooksTableAnnotationComposer(
            $db: $db,
            $table: $db.novelBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, $$ProjectsTableReferences),
          Project,
          PrefetchHooks Function({bool novelBooksRefs})
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                name: name,
                coverPath: coverPath,
                genre: genre,
                description: description,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> coverPath = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                name: name,
                coverPath: coverPath,
                genre: genre,
                description: description,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectsTable, Project>(table),
                  $$ProjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({novelBooksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (novelBooksRefs) db.novelBooks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (novelBooksRefs)
                    await $_getPrefetchedData<
                      Project,
                      $ProjectsTable,
                      NovelBook
                    >(
                      currentTable: table,
                      referencedTable: $$ProjectsTableReferences
                          ._novelBooksRefsTable(db),
                      managerFromTypedResult: (p0) => $$ProjectsTableReferences(
                        db,
                        table,
                        p0,
                      ).novelBooksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.projectId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, $$ProjectsTableReferences),
      Project,
      PrefetchHooks Function({bool novelBooksRefs})
    >;
typedef $$NovelBooksTableCreateCompanionBuilder = NovelBooksCompanion Function({
  Value<int> id,
  required int projectId,
  required String title,
  Value<String?> genre,
  Value<String?> styleGuide,
  Value<String?> world,
  Value<String?> premise,
  Value<String?> outline,
  Value<String> status,
});
typedef $$NovelBooksTableUpdateCompanionBuilder = NovelBooksCompanion Function({
  Value<int> id,
  Value<int> projectId,
  Value<String> title,
  Value<String?> genre,
  Value<String?> styleGuide,
  Value<String?> world,
  Value<String?> premise,
  Value<String?> outline,
  Value<String> status,
});

final class $$NovelBooksTableReferences
    extends BaseReferences<_$AppDatabase, $NovelBooksTable, NovelBook> {
  $$NovelBooksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('novel_books__project_id__projects__id');

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<int>('project_id')!;

    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ChaptersTable, List<Chapter>> _chaptersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.chapters,
    aliasName: 'novel_books__id__chapters__book_id',
  );

  $$ChaptersTableProcessedTableManager get chaptersRefs {
    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_chaptersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TruthFilesTable, List<TruthFile>>
  _truthFilesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.truthFiles,
    aliasName: 'novel_books__id__truth_files__book_id',
  );

  $$TruthFilesTableProcessedTableManager get truthFilesRefs {
    final manager = $$TruthFilesTableTableManager(
      $_db,
      $_db.truthFiles,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_truthFilesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ScriptsTable, List<Script>> _scriptsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.scripts,
    aliasName: 'novel_books__id__scripts__book_id',
  );

  $$ScriptsTableProcessedTableManager get scriptsRefs {
    final manager = $$ScriptsTableTableManager(
      $_db,
      $_db.scripts,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_scriptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NovelBooksTableFilterComposer
    extends Composer<_$AppDatabase, $NovelBooksTable> {
  $$NovelBooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get styleGuide => $composableBuilder(
    column: $table.styleGuide,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get world => $composableBuilder(
    column: $table.world,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get premise => $composableBuilder(
    column: $table.premise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outline => $composableBuilder(
    column: $table.outline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> chaptersRefs(
    Expression<bool> Function($$ChaptersTableFilterComposer f) f,
  ) {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> truthFilesRefs(
    Expression<bool> Function($$TruthFilesTableFilterComposer f) f,
  ) {
    final $$TruthFilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.truthFiles,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TruthFilesTableFilterComposer(
            $db: $db,
            $table: $db.truthFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scriptsRefs(
    Expression<bool> Function($$ScriptsTableFilterComposer f) f,
  ) {
    final $$ScriptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableFilterComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NovelBooksTableOrderingComposer
    extends Composer<_$AppDatabase, $NovelBooksTable> {
  $$NovelBooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get styleGuide => $composableBuilder(
    column: $table.styleGuide,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get world => $composableBuilder(
    column: $table.world,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get premise => $composableBuilder(
    column: $table.premise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outline => $composableBuilder(
    column: $table.outline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NovelBooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $NovelBooksTable> {
  $$NovelBooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get styleGuide => $composableBuilder(
    column: $table.styleGuide,
    builder: (column) => column,
  );

  GeneratedColumn<String> get world =>
      $composableBuilder(column: $table.world, builder: (column) => column);

  GeneratedColumn<String> get premise =>
      $composableBuilder(column: $table.premise, builder: (column) => column);

  GeneratedColumn<String> get outline =>
      $composableBuilder(column: $table.outline, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> chaptersRefs<T extends Object>(
    Expression<T> Function($$ChaptersTableAnnotationComposer a) f,
  ) {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> truthFilesRefs<T extends Object>(
    Expression<T> Function($$TruthFilesTableAnnotationComposer a) f,
  ) {
    final $$TruthFilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.truthFiles,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TruthFilesTableAnnotationComposer(
            $db: $db,
            $table: $db.truthFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> scriptsRefs<T extends Object>(
    Expression<T> Function($$ScriptsTableAnnotationComposer a) f,
  ) {
    final $$ScriptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableAnnotationComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NovelBooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NovelBooksTable,
          NovelBook,
          $$NovelBooksTableFilterComposer,
          $$NovelBooksTableOrderingComposer,
          $$NovelBooksTableAnnotationComposer,
          $$NovelBooksTableCreateCompanionBuilder,
          $$NovelBooksTableUpdateCompanionBuilder,
          (NovelBook, $$NovelBooksTableReferences),
          NovelBook,
          PrefetchHooks Function({
            bool projectId,
            bool chaptersRefs,
            bool truthFilesRefs,
            bool scriptsRefs,
          })
        > {
  $$NovelBooksTableTableManager(_$AppDatabase db, $NovelBooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NovelBooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NovelBooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NovelBooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> projectId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> styleGuide = const Value.absent(),
                Value<String?> world = const Value.absent(),
                Value<String?> premise = const Value.absent(),
                Value<String?> outline = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => NovelBooksCompanion(
                id: id,
                projectId: projectId,
                title: title,
                genre: genre,
                styleGuide: styleGuide,
                world: world,
                premise: premise,
                outline: outline,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int projectId,
                required String title,
                Value<String?> genre = const Value.absent(),
                Value<String?> styleGuide = const Value.absent(),
                Value<String?> world = const Value.absent(),
                Value<String?> premise = const Value.absent(),
                Value<String?> outline = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => NovelBooksCompanion.insert(
                id: id,
                projectId: projectId,
                title: title,
                genre: genre,
                styleGuide: styleGuide,
                world: world,
                premise: premise,
                outline: outline,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NovelBooksTable, NovelBook>(table),
                  $$NovelBooksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                projectId = false,
                chaptersRefs = false,
                truthFilesRefs = false,
                scriptsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (chaptersRefs) db.chapters,
                    if (truthFilesRefs) db.truthFiles,
                    if (scriptsRefs) db.scripts,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (projectId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.projectId,
                            referencedTable: $$NovelBooksTableReferences
                                ._projectIdTable(db),
                            referencedColumn: $$NovelBooksTableReferences
                                ._projectIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (chaptersRefs)
                        await $_getPrefetchedData<
                          NovelBook,
                          $NovelBooksTable,
                          Chapter
                        >(
                          currentTable: table,
                          referencedTable: $$NovelBooksTableReferences
                              ._chaptersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NovelBooksTableReferences(
                                db,
                                table,
                                p0,
                              ).chaptersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (truthFilesRefs)
                        await $_getPrefetchedData<
                          NovelBook,
                          $NovelBooksTable,
                          TruthFile
                        >(
                          currentTable: table,
                          referencedTable: $$NovelBooksTableReferences
                              ._truthFilesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NovelBooksTableReferences(
                                db,
                                table,
                                p0,
                              ).truthFilesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (scriptsRefs)
                        await $_getPrefetchedData<
                          NovelBook,
                          $NovelBooksTable,
                          Script
                        >(
                          currentTable: table,
                          referencedTable: $$NovelBooksTableReferences
                              ._scriptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NovelBooksTableReferences(
                                db,
                                table,
                                p0,
                              ).scriptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$NovelBooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NovelBooksTable,
      NovelBook,
      $$NovelBooksTableFilterComposer,
      $$NovelBooksTableOrderingComposer,
      $$NovelBooksTableAnnotationComposer,
      $$NovelBooksTableCreateCompanionBuilder,
      $$NovelBooksTableUpdateCompanionBuilder,
      (NovelBook, $$NovelBooksTableReferences),
      NovelBook,
      PrefetchHooks Function({
        bool projectId,
        bool chaptersRefs,
        bool truthFilesRefs,
        bool scriptsRefs,
      })
    >;
typedef $$ChaptersTableCreateCompanionBuilder = ChaptersCompanion Function({
  Value<int> id,
  required int bookId,
  required int seq,
  required String title,
  Value<String?> summary,
  Value<String?> content,
  Value<int> wordCount,
  Value<String> status,
  Value<int> revision,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$ChaptersTableUpdateCompanionBuilder = ChaptersCompanion Function({
  Value<int> id,
  Value<int> bookId,
  Value<int> seq,
  Value<String> title,
  Value<String?> summary,
  Value<String?> content,
  Value<int> wordCount,
  Value<String> status,
  Value<int> revision,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$ChaptersTableReferences
    extends BaseReferences<_$AppDatabase, $ChaptersTable, Chapter> {
  $$ChaptersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NovelBooksTable _bookIdTable(_$AppDatabase db) =>
      db.novelBooks.createAlias('chapters__book_id__novel_books__id');

  $$NovelBooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$NovelBooksTableTableManager(
      $_db,
      $_db.novelBooks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ChapterRevisionsTable, List<ChapterRevision>>
  _chapterRevisionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.chapterRevisions,
    aliasName: 'chapters__id__chapter_revisions__chapter_id',
  );

  $$ChapterRevisionsTableProcessedTableManager get chapterRevisionsRefs {
    final manager = $$ChapterRevisionsTableTableManager(
      $_db,
      $_db.chapterRevisions,
    ).filter((f) => f.chapterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _chapterRevisionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChaptersTableFilterComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$NovelBooksTableFilterComposer get bookId {
    final $$NovelBooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.novelBooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NovelBooksTableFilterComposer(
            $db: $db,
            $table: $db.novelBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> chapterRevisionsRefs(
    Expression<bool> Function($$ChapterRevisionsTableFilterComposer f) f,
  ) {
    final $$ChapterRevisionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapterRevisions,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChapterRevisionsTableFilterComposer(
            $db: $db,
            $table: $db.chapterRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChaptersTableOrderingComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$NovelBooksTableOrderingComposer get bookId {
    final $$NovelBooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.novelBooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NovelBooksTableOrderingComposer(
            $db: $db,
            $table: $db.novelBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChaptersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$NovelBooksTableAnnotationComposer get bookId {
    final $$NovelBooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.novelBooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NovelBooksTableAnnotationComposer(
            $db: $db,
            $table: $db.novelBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> chapterRevisionsRefs<T extends Object>(
    Expression<T> Function($$ChapterRevisionsTableAnnotationComposer a) f,
  ) {
    final $$ChapterRevisionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapterRevisions,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChapterRevisionsTableAnnotationComposer(
            $db: $db,
            $table: $db.chapterRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChaptersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChaptersTable,
          Chapter,
          $$ChaptersTableFilterComposer,
          $$ChaptersTableOrderingComposer,
          $$ChaptersTableAnnotationComposer,
          $$ChaptersTableCreateCompanionBuilder,
          $$ChaptersTableUpdateCompanionBuilder,
          (Chapter, $$ChaptersTableReferences),
          Chapter,
          PrefetchHooks Function({bool bookId, bool chapterRevisionsRefs})
        > {
  $$ChaptersTableTableManager(_$AppDatabase db, $ChaptersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChaptersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChaptersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChaptersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<int> wordCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ChaptersCompanion(
                id: id,
                bookId: bookId,
                seq: seq,
                title: title,
                summary: summary,
                content: content,
                wordCount: wordCount,
                status: status,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bookId,
                required int seq,
                required String title,
                Value<String?> summary = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<int> wordCount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ChaptersCompanion.insert(
                id: id,
                bookId: bookId,
                seq: seq,
                title: title,
                summary: summary,
                content: content,
                wordCount: wordCount,
                status: status,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChaptersTable, Chapter>(table),
                  $$ChaptersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({bookId = false, chapterRevisionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (chapterRevisionsRefs) db.chapterRevisions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (bookId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.bookId,
                            referencedTable: $$ChaptersTableReferences
                                ._bookIdTable(db),
                            referencedColumn: $$ChaptersTableReferences
                                ._bookIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (chapterRevisionsRefs)
                        await $_getPrefetchedData<
                          Chapter,
                          $ChaptersTable,
                          ChapterRevision
                        >(
                          currentTable: table,
                          referencedTable: $$ChaptersTableReferences
                              ._chapterRevisionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChaptersTableReferences(
                                db,
                                table,
                                p0,
                              ).chapterRevisionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chapterId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ChaptersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChaptersTable,
      Chapter,
      $$ChaptersTableFilterComposer,
      $$ChaptersTableOrderingComposer,
      $$ChaptersTableAnnotationComposer,
      $$ChaptersTableCreateCompanionBuilder,
      $$ChaptersTableUpdateCompanionBuilder,
      (Chapter, $$ChaptersTableReferences),
      Chapter,
      PrefetchHooks Function({bool bookId, bool chapterRevisionsRefs})
    >;
typedef $$ChapterRevisionsTableCreateCompanionBuilder =
    ChapterRevisionsCompanion Function({
      Value<int> id,
      required int chapterId,
      required int revision,
      Value<String?> content,
      Value<DateTime> createdAt,
    });
typedef $$ChapterRevisionsTableUpdateCompanionBuilder =
    ChapterRevisionsCompanion Function({
      Value<int> id,
      Value<int> chapterId,
      Value<int> revision,
      Value<String?> content,
      Value<DateTime> createdAt,
    });

final class $$ChapterRevisionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ChapterRevisionsTable, ChapterRevision> {
  $$ChapterRevisionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ChaptersTable _chapterIdTable(_$AppDatabase db) =>
      db.chapters.createAlias('chapter_revisions__chapter_id__chapters__id');

  $$ChaptersTableProcessedTableManager get chapterId {
    final $_column = $_itemColumn<int>('chapter_id')!;

    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chapterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChapterRevisionsTableFilterComposer
    extends Composer<_$AppDatabase, $ChapterRevisionsTable> {
  $$ChapterRevisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ChaptersTableFilterComposer get chapterId {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChapterRevisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChapterRevisionsTable> {
  $$ChapterRevisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChaptersTableOrderingComposer get chapterId {
    final $$ChaptersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableOrderingComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChapterRevisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChapterRevisionsTable> {
  $$ChapterRevisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ChaptersTableAnnotationComposer get chapterId {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChapterRevisionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChapterRevisionsTable,
          ChapterRevision,
          $$ChapterRevisionsTableFilterComposer,
          $$ChapterRevisionsTableOrderingComposer,
          $$ChapterRevisionsTableAnnotationComposer,
          $$ChapterRevisionsTableCreateCompanionBuilder,
          $$ChapterRevisionsTableUpdateCompanionBuilder,
          (ChapterRevision, $$ChapterRevisionsTableReferences),
          ChapterRevision,
          PrefetchHooks Function({bool chapterId})
        > {
  $$ChapterRevisionsTableTableManager(
    _$AppDatabase db,
    $ChapterRevisionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChapterRevisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChapterRevisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChapterRevisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> chapterId = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ChapterRevisionsCompanion(
                id: id,
                chapterId: chapterId,
                revision: revision,
                content: content,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int chapterId,
                required int revision,
                Value<String?> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ChapterRevisionsCompanion.insert(
                id: id,
                chapterId: chapterId,
                revision: revision,
                content: content,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChapterRevisionsTable, ChapterRevision>(table),
                  $$ChapterRevisionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({chapterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (chapterId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.chapterId,
                        referencedTable: $$ChapterRevisionsTableReferences
                            ._chapterIdTable(db),
                        referencedColumn: $$ChapterRevisionsTableReferences
                            ._chapterIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChapterRevisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChapterRevisionsTable,
      ChapterRevision,
      $$ChapterRevisionsTableFilterComposer,
      $$ChapterRevisionsTableOrderingComposer,
      $$ChapterRevisionsTableAnnotationComposer,
      $$ChapterRevisionsTableCreateCompanionBuilder,
      $$ChapterRevisionsTableUpdateCompanionBuilder,
      (ChapterRevision, $$ChapterRevisionsTableReferences),
      ChapterRevision,
      PrefetchHooks Function({bool chapterId})
    >;
typedef $$TruthFilesTableCreateCompanionBuilder = TruthFilesCompanion Function({
  Value<int> id,
  required int bookId,
  required String kind,
  Value<String> content,
  Value<int> revision,
  Value<DateTime> updatedAt,
});
typedef $$TruthFilesTableUpdateCompanionBuilder = TruthFilesCompanion Function({
  Value<int> id,
  Value<int> bookId,
  Value<String> kind,
  Value<String> content,
  Value<int> revision,
  Value<DateTime> updatedAt,
});

final class $$TruthFilesTableReferences
    extends BaseReferences<_$AppDatabase, $TruthFilesTable, TruthFile> {
  $$TruthFilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NovelBooksTable _bookIdTable(_$AppDatabase db) =>
      db.novelBooks.createAlias('truth_files__book_id__novel_books__id');

  $$NovelBooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$NovelBooksTableTableManager(
      $_db,
      $_db.novelBooks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TruthFilesTableFilterComposer
    extends Composer<_$AppDatabase, $TruthFilesTable> {
  $$TruthFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$NovelBooksTableFilterComposer get bookId {
    final $$NovelBooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.novelBooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NovelBooksTableFilterComposer(
            $db: $db,
            $table: $db.novelBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TruthFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $TruthFilesTable> {
  $$TruthFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$NovelBooksTableOrderingComposer get bookId {
    final $$NovelBooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.novelBooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NovelBooksTableOrderingComposer(
            $db: $db,
            $table: $db.novelBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TruthFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TruthFilesTable> {
  $$TruthFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$NovelBooksTableAnnotationComposer get bookId {
    final $$NovelBooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.novelBooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NovelBooksTableAnnotationComposer(
            $db: $db,
            $table: $db.novelBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TruthFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TruthFilesTable,
          TruthFile,
          $$TruthFilesTableFilterComposer,
          $$TruthFilesTableOrderingComposer,
          $$TruthFilesTableAnnotationComposer,
          $$TruthFilesTableCreateCompanionBuilder,
          $$TruthFilesTableUpdateCompanionBuilder,
          (TruthFile, $$TruthFilesTableReferences),
          TruthFile,
          PrefetchHooks Function({bool bookId})
        > {
  $$TruthFilesTableTableManager(_$AppDatabase db, $TruthFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TruthFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TruthFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TruthFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TruthFilesCompanion(
                id: id,
                bookId: bookId,
                kind: kind,
                content: content,
                revision: revision,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bookId,
                required String kind,
                Value<String> content = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TruthFilesCompanion.insert(
                id: id,
                bookId: bookId,
                kind: kind,
                content: content,
                revision: revision,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TruthFilesTable, TruthFile>(table),
                  $$TruthFilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$TruthFilesTableReferences
                            ._bookIdTable(db),
                        referencedColumn: $$TruthFilesTableReferences
                            ._bookIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TruthFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TruthFilesTable,
      TruthFile,
      $$TruthFilesTableFilterComposer,
      $$TruthFilesTableOrderingComposer,
      $$TruthFilesTableAnnotationComposer,
      $$TruthFilesTableCreateCompanionBuilder,
      $$TruthFilesTableUpdateCompanionBuilder,
      (TruthFile, $$TruthFilesTableReferences),
      TruthFile,
      PrefetchHooks Function({bool bookId})
    >;
typedef $$ScriptsTableCreateCompanionBuilder = ScriptsCompanion Function({
  Value<int> id,
  required int bookId,
  required String title,
  Value<int> version,
  Value<String> fidelityMode,
  Value<String?> artStyle,
  Value<String> aspectRatio,
  Value<String> language,
  Value<String> status,
  Value<String> content,
});
typedef $$ScriptsTableUpdateCompanionBuilder = ScriptsCompanion Function({
  Value<int> id,
  Value<int> bookId,
  Value<String> title,
  Value<int> version,
  Value<String> fidelityMode,
  Value<String?> artStyle,
  Value<String> aspectRatio,
  Value<String> language,
  Value<String> status,
  Value<String> content,
});

final class $$ScriptsTableReferences
    extends BaseReferences<_$AppDatabase, $ScriptsTable, Script> {
  $$ScriptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NovelBooksTable _bookIdTable(_$AppDatabase db) =>
      db.novelBooks.createAlias('scripts__book_id__novel_books__id');

  $$NovelBooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$NovelBooksTableTableManager(
      $_db,
      $_db.novelBooks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ScriptRevisionsTable, List<ScriptRevision>>
  _scriptRevisionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scriptRevisions,
    aliasName: 'scripts__id__script_revisions__script_id',
  );

  $$ScriptRevisionsTableProcessedTableManager get scriptRevisionsRefs {
    final manager = $$ScriptRevisionsTableTableManager(
      $_db,
      $_db.scriptRevisions,
    ).filter((f) => f.scriptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _scriptRevisionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ScenesTable, List<Scene>> _scenesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.scenes,
    aliasName: 'scripts__id__scenes__script_id',
  );

  $$ScenesTableProcessedTableManager get scenesRefs {
    final manager = $$ScenesTableTableManager(
      $_db,
      $_db.scenes,
    ).filter((f) => f.scriptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_scenesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AssetsTable, List<Asset>> _assetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.assets,
    aliasName: 'scripts__id__assets__script_id',
  );

  $$AssetsTableProcessedTableManager get assetsRefs {
    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.scriptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_assetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ShotsTable, List<Shot>> _shotsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.shots,
    aliasName: 'scripts__id__shots__script_id',
  );

  $$ShotsTableProcessedTableManager get shotsRefs {
    final manager = $$ShotsTableTableManager(
      $_db,
      $_db.shots,
    ).filter((f) => f.scriptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_shotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScriptsTableFilterComposer
    extends Composer<_$AppDatabase, $ScriptsTable> {
  $$ScriptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fidelityMode => $composableBuilder(
    column: $table.fidelityMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artStyle => $composableBuilder(
    column: $table.artStyle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aspectRatio => $composableBuilder(
    column: $table.aspectRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  $$NovelBooksTableFilterComposer get bookId {
    final $$NovelBooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.novelBooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NovelBooksTableFilterComposer(
            $db: $db,
            $table: $db.novelBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> scriptRevisionsRefs(
    Expression<bool> Function($$ScriptRevisionsTableFilterComposer f) f,
  ) {
    final $$ScriptRevisionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scriptRevisions,
      getReferencedColumn: (t) => t.scriptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptRevisionsTableFilterComposer(
            $db: $db,
            $table: $db.scriptRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scenesRefs(
    Expression<bool> Function($$ScenesTableFilterComposer f) f,
  ) {
    final $$ScenesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scenes,
      getReferencedColumn: (t) => t.scriptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScenesTableFilterComposer(
            $db: $db,
            $table: $db.scenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> assetsRefs(
    Expression<bool> Function($$AssetsTableFilterComposer f) f,
  ) {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.scriptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> shotsRefs(
    Expression<bool> Function($$ShotsTableFilterComposer f) f,
  ) {
    final $$ShotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.scriptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotsTableFilterComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScriptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScriptsTable> {
  $$ScriptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fidelityMode => $composableBuilder(
    column: $table.fidelityMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artStyle => $composableBuilder(
    column: $table.artStyle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aspectRatio => $composableBuilder(
    column: $table.aspectRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  $$NovelBooksTableOrderingComposer get bookId {
    final $$NovelBooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.novelBooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NovelBooksTableOrderingComposer(
            $db: $db,
            $table: $db.novelBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScriptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScriptsTable> {
  $$ScriptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get fidelityMode => $composableBuilder(
    column: $table.fidelityMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artStyle =>
      $composableBuilder(column: $table.artStyle, builder: (column) => column);

  GeneratedColumn<String> get aspectRatio => $composableBuilder(
    column: $table.aspectRatio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  $$NovelBooksTableAnnotationComposer get bookId {
    final $$NovelBooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.novelBooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NovelBooksTableAnnotationComposer(
            $db: $db,
            $table: $db.novelBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> scriptRevisionsRefs<T extends Object>(
    Expression<T> Function($$ScriptRevisionsTableAnnotationComposer a) f,
  ) {
    final $$ScriptRevisionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scriptRevisions,
      getReferencedColumn: (t) => t.scriptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptRevisionsTableAnnotationComposer(
            $db: $db,
            $table: $db.scriptRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> scenesRefs<T extends Object>(
    Expression<T> Function($$ScenesTableAnnotationComposer a) f,
  ) {
    final $$ScenesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scenes,
      getReferencedColumn: (t) => t.scriptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScenesTableAnnotationComposer(
            $db: $db,
            $table: $db.scenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> assetsRefs<T extends Object>(
    Expression<T> Function($$AssetsTableAnnotationComposer a) f,
  ) {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.scriptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> shotsRefs<T extends Object>(
    Expression<T> Function($$ShotsTableAnnotationComposer a) f,
  ) {
    final $$ShotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.scriptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotsTableAnnotationComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScriptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScriptsTable,
          Script,
          $$ScriptsTableFilterComposer,
          $$ScriptsTableOrderingComposer,
          $$ScriptsTableAnnotationComposer,
          $$ScriptsTableCreateCompanionBuilder,
          $$ScriptsTableUpdateCompanionBuilder,
          (Script, $$ScriptsTableReferences),
          Script,
          PrefetchHooks Function({
            bool bookId,
            bool scriptRevisionsRefs,
            bool scenesRefs,
            bool assetsRefs,
            bool shotsRefs,
          })
        > {
  $$ScriptsTableTableManager(_$AppDatabase db, $ScriptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScriptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScriptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScriptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> fidelityMode = const Value.absent(),
                Value<String?> artStyle = const Value.absent(),
                Value<String> aspectRatio = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> content = const Value.absent(),
              }) => ScriptsCompanion(
                id: id,
                bookId: bookId,
                title: title,
                version: version,
                fidelityMode: fidelityMode,
                artStyle: artStyle,
                aspectRatio: aspectRatio,
                language: language,
                status: status,
                content: content,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bookId,
                required String title,
                Value<int> version = const Value.absent(),
                Value<String> fidelityMode = const Value.absent(),
                Value<String?> artStyle = const Value.absent(),
                Value<String> aspectRatio = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> content = const Value.absent(),
              }) => ScriptsCompanion.insert(
                id: id,
                bookId: bookId,
                title: title,
                version: version,
                fidelityMode: fidelityMode,
                artStyle: artStyle,
                aspectRatio: aspectRatio,
                language: language,
                status: status,
                content: content,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScriptsTable, Script>(table),
                  $$ScriptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                bookId = false,
                scriptRevisionsRefs = false,
                scenesRefs = false,
                assetsRefs = false,
                shotsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (scriptRevisionsRefs) db.scriptRevisions,
                    if (scenesRefs) db.scenes,
                    if (assetsRefs) db.assets,
                    if (shotsRefs) db.shots,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (bookId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.bookId,
                            referencedTable: $$ScriptsTableReferences
                                ._bookIdTable(db),
                            referencedColumn: $$ScriptsTableReferences
                                ._bookIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (scriptRevisionsRefs)
                        await $_getPrefetchedData<
                          Script,
                          $ScriptsTable,
                          ScriptRevision
                        >(
                          currentTable: table,
                          referencedTable: $$ScriptsTableReferences
                              ._scriptRevisionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScriptsTableReferences(
                                db,
                                table,
                                p0,
                              ).scriptRevisionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scriptId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (scenesRefs)
                        await $_getPrefetchedData<Script, $ScriptsTable, Scene>(
                          currentTable: table,
                          referencedTable: $$ScriptsTableReferences
                              ._scenesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScriptsTableReferences(
                                db,
                                table,
                                p0,
                              ).scenesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scriptId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (assetsRefs)
                        await $_getPrefetchedData<Script, $ScriptsTable, Asset>(
                          currentTable: table,
                          referencedTable: $$ScriptsTableReferences
                              ._assetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScriptsTableReferences(
                                db,
                                table,
                                p0,
                              ).assetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scriptId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (shotsRefs)
                        await $_getPrefetchedData<Script, $ScriptsTable, Shot>(
                          currentTable: table,
                          referencedTable: $$ScriptsTableReferences
                              ._shotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScriptsTableReferences(db, table, p0).shotsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scriptId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ScriptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScriptsTable,
      Script,
      $$ScriptsTableFilterComposer,
      $$ScriptsTableOrderingComposer,
      $$ScriptsTableAnnotationComposer,
      $$ScriptsTableCreateCompanionBuilder,
      $$ScriptsTableUpdateCompanionBuilder,
      (Script, $$ScriptsTableReferences),
      Script,
      PrefetchHooks Function({
        bool bookId,
        bool scriptRevisionsRefs,
        bool scenesRefs,
        bool assetsRefs,
        bool shotsRefs,
      })
    >;
typedef $$ScriptRevisionsTableCreateCompanionBuilder =
    ScriptRevisionsCompanion Function({
      Value<int> id,
      required int scriptId,
      required int version,
      Value<String?> content,
      Value<DateTime> createdAt,
    });
typedef $$ScriptRevisionsTableUpdateCompanionBuilder =
    ScriptRevisionsCompanion Function({
      Value<int> id,
      Value<int> scriptId,
      Value<int> version,
      Value<String?> content,
      Value<DateTime> createdAt,
    });

final class $$ScriptRevisionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ScriptRevisionsTable, ScriptRevision> {
  $$ScriptRevisionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ScriptsTable _scriptIdTable(_$AppDatabase db) =>
      db.scripts.createAlias('script_revisions__script_id__scripts__id');

  $$ScriptsTableProcessedTableManager get scriptId {
    final $_column = $_itemColumn<int>('script_id')!;

    final manager = $$ScriptsTableTableManager(
      $_db,
      $_db.scripts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scriptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ScriptRevisionsTableFilterComposer
    extends Composer<_$AppDatabase, $ScriptRevisionsTable> {
  $$ScriptRevisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ScriptsTableFilterComposer get scriptId {
    final $$ScriptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptId,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableFilterComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScriptRevisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScriptRevisionsTable> {
  $$ScriptRevisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScriptsTableOrderingComposer get scriptId {
    final $$ScriptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptId,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableOrderingComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScriptRevisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScriptRevisionsTable> {
  $$ScriptRevisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ScriptsTableAnnotationComposer get scriptId {
    final $$ScriptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptId,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableAnnotationComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScriptRevisionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScriptRevisionsTable,
          ScriptRevision,
          $$ScriptRevisionsTableFilterComposer,
          $$ScriptRevisionsTableOrderingComposer,
          $$ScriptRevisionsTableAnnotationComposer,
          $$ScriptRevisionsTableCreateCompanionBuilder,
          $$ScriptRevisionsTableUpdateCompanionBuilder,
          (ScriptRevision, $$ScriptRevisionsTableReferences),
          ScriptRevision,
          PrefetchHooks Function({bool scriptId})
        > {
  $$ScriptRevisionsTableTableManager(
    _$AppDatabase db,
    $ScriptRevisionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScriptRevisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScriptRevisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScriptRevisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> scriptId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ScriptRevisionsCompanion(
                id: id,
                scriptId: scriptId,
                version: version,
                content: content,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int scriptId,
                required int version,
                Value<String?> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ScriptRevisionsCompanion.insert(
                id: id,
                scriptId: scriptId,
                version: version,
                content: content,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScriptRevisionsTable, ScriptRevision>(table),
                  $$ScriptRevisionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scriptId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scriptId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.scriptId,
                        referencedTable: $$ScriptRevisionsTableReferences
                            ._scriptIdTable(db),
                        referencedColumn: $$ScriptRevisionsTableReferences
                            ._scriptIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ScriptRevisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScriptRevisionsTable,
      ScriptRevision,
      $$ScriptRevisionsTableFilterComposer,
      $$ScriptRevisionsTableOrderingComposer,
      $$ScriptRevisionsTableAnnotationComposer,
      $$ScriptRevisionsTableCreateCompanionBuilder,
      $$ScriptRevisionsTableUpdateCompanionBuilder,
      (ScriptRevision, $$ScriptRevisionsTableReferences),
      ScriptRevision,
      PrefetchHooks Function({bool scriptId})
    >;
typedef $$ScenesTableCreateCompanionBuilder = ScenesCompanion Function({
  Value<int> id,
  required int scriptId,
  required int seq,
  required String location,
  required String time,
  Value<String> characters,
  Value<String?> summary,
  Value<String> action,
  Value<String?> startState,
  Value<String?> endState,
  Value<String?> transition,
  Value<String> dialogue,
  Value<String> sound,
});
typedef $$ScenesTableUpdateCompanionBuilder = ScenesCompanion Function({
  Value<int> id,
  Value<int> scriptId,
  Value<int> seq,
  Value<String> location,
  Value<String> time,
  Value<String> characters,
  Value<String?> summary,
  Value<String> action,
  Value<String?> startState,
  Value<String?> endState,
  Value<String?> transition,
  Value<String> dialogue,
  Value<String> sound,
});

final class $$ScenesTableReferences
    extends BaseReferences<_$AppDatabase, $ScenesTable, Scene> {
  $$ScenesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScriptsTable _scriptIdTable(_$AppDatabase db) =>
      db.scripts.createAlias('scenes__script_id__scripts__id');

  $$ScriptsTableProcessedTableManager get scriptId {
    final $_column = $_itemColumn<int>('script_id')!;

    final manager = $$ScriptsTableTableManager(
      $_db,
      $_db.scripts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scriptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BeatsTable, List<Beat>> _beatsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.beats,
    aliasName: 'scenes__id__beats__scene_id',
  );

  $$BeatsTableProcessedTableManager get beatsRefs {
    final manager = $$BeatsTableTableManager(
      $_db,
      $_db.beats,
    ).filter((f) => f.sceneId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_beatsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScenesTableFilterComposer
    extends Composer<_$AppDatabase, $ScenesTable> {
  $$ScenesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get characters => $composableBuilder(
    column: $table.characters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startState => $composableBuilder(
    column: $table.startState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endState => $composableBuilder(
    column: $table.endState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transition => $composableBuilder(
    column: $table.transition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dialogue => $composableBuilder(
    column: $table.dialogue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sound => $composableBuilder(
    column: $table.sound,
    builder: (column) => ColumnFilters(column),
  );

  $$ScriptsTableFilterComposer get scriptId {
    final $$ScriptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptId,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableFilterComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> beatsRefs(
    Expression<bool> Function($$BeatsTableFilterComposer f) f,
  ) {
    final $$BeatsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.beats,
      getReferencedColumn: (t) => t.sceneId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeatsTableFilterComposer(
            $db: $db,
            $table: $db.beats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScenesTableOrderingComposer
    extends Composer<_$AppDatabase, $ScenesTable> {
  $$ScenesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get characters => $composableBuilder(
    column: $table.characters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startState => $composableBuilder(
    column: $table.startState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endState => $composableBuilder(
    column: $table.endState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transition => $composableBuilder(
    column: $table.transition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dialogue => $composableBuilder(
    column: $table.dialogue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sound => $composableBuilder(
    column: $table.sound,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScriptsTableOrderingComposer get scriptId {
    final $$ScriptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptId,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableOrderingComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScenesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScenesTable> {
  $$ScenesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<String> get characters => $composableBuilder(
    column: $table.characters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get startState => $composableBuilder(
    column: $table.startState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endState =>
      $composableBuilder(column: $table.endState, builder: (column) => column);

  GeneratedColumn<String> get transition => $composableBuilder(
    column: $table.transition,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dialogue =>
      $composableBuilder(column: $table.dialogue, builder: (column) => column);

  GeneratedColumn<String> get sound =>
      $composableBuilder(column: $table.sound, builder: (column) => column);

  $$ScriptsTableAnnotationComposer get scriptId {
    final $$ScriptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptId,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableAnnotationComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> beatsRefs<T extends Object>(
    Expression<T> Function($$BeatsTableAnnotationComposer a) f,
  ) {
    final $$BeatsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.beats,
      getReferencedColumn: (t) => t.sceneId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BeatsTableAnnotationComposer(
            $db: $db,
            $table: $db.beats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScenesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScenesTable,
          Scene,
          $$ScenesTableFilterComposer,
          $$ScenesTableOrderingComposer,
          $$ScenesTableAnnotationComposer,
          $$ScenesTableCreateCompanionBuilder,
          $$ScenesTableUpdateCompanionBuilder,
          (Scene, $$ScenesTableReferences),
          Scene,
          PrefetchHooks Function({bool scriptId, bool beatsRefs})
        > {
  $$ScenesTableTableManager(_$AppDatabase db, $ScenesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScenesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScenesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScenesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> scriptId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String> time = const Value.absent(),
                Value<String> characters = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String?> startState = const Value.absent(),
                Value<String?> endState = const Value.absent(),
                Value<String?> transition = const Value.absent(),
                Value<String> dialogue = const Value.absent(),
                Value<String> sound = const Value.absent(),
              }) => ScenesCompanion(
                id: id,
                scriptId: scriptId,
                seq: seq,
                location: location,
                time: time,
                characters: characters,
                summary: summary,
                action: action,
                startState: startState,
                endState: endState,
                transition: transition,
                dialogue: dialogue,
                sound: sound,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int scriptId,
                required int seq,
                required String location,
                required String time,
                Value<String> characters = const Value.absent(),
                Value<String?> summary = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String?> startState = const Value.absent(),
                Value<String?> endState = const Value.absent(),
                Value<String?> transition = const Value.absent(),
                Value<String> dialogue = const Value.absent(),
                Value<String> sound = const Value.absent(),
              }) => ScenesCompanion.insert(
                id: id,
                scriptId: scriptId,
                seq: seq,
                location: location,
                time: time,
                characters: characters,
                summary: summary,
                action: action,
                startState: startState,
                endState: endState,
                transition: transition,
                dialogue: dialogue,
                sound: sound,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScenesTable, Scene>(table),
                  $$ScenesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scriptId = false, beatsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (beatsRefs) db.beats],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scriptId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.scriptId,
                        referencedTable: $$ScenesTableReferences._scriptIdTable(
                          db,
                        ),
                        referencedColumn: $$ScenesTableReferences
                            ._scriptIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (beatsRefs)
                    await $_getPrefetchedData<Scene, $ScenesTable, Beat>(
                      currentTable: table,
                      referencedTable: $$ScenesTableReferences._beatsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$ScenesTableReferences(db, table, p0).beatsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sceneId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ScenesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScenesTable,
      Scene,
      $$ScenesTableFilterComposer,
      $$ScenesTableOrderingComposer,
      $$ScenesTableAnnotationComposer,
      $$ScenesTableCreateCompanionBuilder,
      $$ScenesTableUpdateCompanionBuilder,
      (Scene, $$ScenesTableReferences),
      Scene,
      PrefetchHooks Function({bool scriptId, bool beatsRefs})
    >;
typedef $$BeatsTableCreateCompanionBuilder = BeatsCompanion Function({
  Value<int> id,
  required int sceneId,
  required int seq,
  required String type,
  Value<String> who,
  required String content,
  Value<String?> object,
  required String sourceRef,
  Value<int> estDurationMs,
  Value<String> tags,
});
typedef $$BeatsTableUpdateCompanionBuilder = BeatsCompanion Function({
  Value<int> id,
  Value<int> sceneId,
  Value<int> seq,
  Value<String> type,
  Value<String> who,
  Value<String> content,
  Value<String?> object,
  Value<String> sourceRef,
  Value<int> estDurationMs,
  Value<String> tags,
});

final class $$BeatsTableReferences
    extends BaseReferences<_$AppDatabase, $BeatsTable, Beat> {
  $$BeatsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScenesTable _sceneIdTable(_$AppDatabase db) =>
      db.scenes.createAlias('beats__scene_id__scenes__id');

  $$ScenesTableProcessedTableManager get sceneId {
    final $_column = $_itemColumn<int>('scene_id')!;

    final manager = $$ScenesTableTableManager(
      $_db,
      $_db.scenes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sceneIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BeatsTableFilterComposer extends Composer<_$AppDatabase, $BeatsTable> {
  $$BeatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get who => $composableBuilder(
    column: $table.who,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get object => $composableBuilder(
    column: $table.object,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceRef => $composableBuilder(
    column: $table.sourceRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estDurationMs => $composableBuilder(
    column: $table.estDurationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  $$ScenesTableFilterComposer get sceneId {
    final $$ScenesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sceneId,
      referencedTable: $db.scenes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScenesTableFilterComposer(
            $db: $db,
            $table: $db.scenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BeatsTableOrderingComposer
    extends Composer<_$AppDatabase, $BeatsTable> {
  $$BeatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get who => $composableBuilder(
    column: $table.who,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get object => $composableBuilder(
    column: $table.object,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceRef => $composableBuilder(
    column: $table.sourceRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estDurationMs => $composableBuilder(
    column: $table.estDurationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScenesTableOrderingComposer get sceneId {
    final $$ScenesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sceneId,
      referencedTable: $db.scenes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScenesTableOrderingComposer(
            $db: $db,
            $table: $db.scenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BeatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BeatsTable> {
  $$BeatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get who =>
      $composableBuilder(column: $table.who, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get object =>
      $composableBuilder(column: $table.object, builder: (column) => column);

  GeneratedColumn<String> get sourceRef =>
      $composableBuilder(column: $table.sourceRef, builder: (column) => column);

  GeneratedColumn<int> get estDurationMs => $composableBuilder(
    column: $table.estDurationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  $$ScenesTableAnnotationComposer get sceneId {
    final $$ScenesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sceneId,
      referencedTable: $db.scenes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScenesTableAnnotationComposer(
            $db: $db,
            $table: $db.scenes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BeatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BeatsTable,
          Beat,
          $$BeatsTableFilterComposer,
          $$BeatsTableOrderingComposer,
          $$BeatsTableAnnotationComposer,
          $$BeatsTableCreateCompanionBuilder,
          $$BeatsTableUpdateCompanionBuilder,
          (Beat, $$BeatsTableReferences),
          Beat,
          PrefetchHooks Function({bool sceneId})
        > {
  $$BeatsTableTableManager(_$AppDatabase db, $BeatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BeatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BeatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BeatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sceneId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> who = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> object = const Value.absent(),
                Value<String> sourceRef = const Value.absent(),
                Value<int> estDurationMs = const Value.absent(),
                Value<String> tags = const Value.absent(),
              }) => BeatsCompanion(
                id: id,
                sceneId: sceneId,
                seq: seq,
                type: type,
                who: who,
                content: content,
                object: object,
                sourceRef: sourceRef,
                estDurationMs: estDurationMs,
                tags: tags,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sceneId,
                required int seq,
                required String type,
                Value<String> who = const Value.absent(),
                required String content,
                Value<String?> object = const Value.absent(),
                required String sourceRef,
                Value<int> estDurationMs = const Value.absent(),
                Value<String> tags = const Value.absent(),
              }) => BeatsCompanion.insert(
                id: id,
                sceneId: sceneId,
                seq: seq,
                type: type,
                who: who,
                content: content,
                object: object,
                sourceRef: sourceRef,
                estDurationMs: estDurationMs,
                tags: tags,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BeatsTable, Beat>(table),
                  $$BeatsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sceneId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sceneId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sceneId,
                        referencedTable: $$BeatsTableReferences._sceneIdTable(
                          db,
                        ),
                        referencedColumn: $$BeatsTableReferences
                            ._sceneIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BeatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BeatsTable,
      Beat,
      $$BeatsTableFilterComposer,
      $$BeatsTableOrderingComposer,
      $$BeatsTableAnnotationComposer,
      $$BeatsTableCreateCompanionBuilder,
      $$BeatsTableUpdateCompanionBuilder,
      (Beat, $$BeatsTableReferences),
      Beat,
      PrefetchHooks Function({bool sceneId})
    >;
typedef $$AssetsTableCreateCompanionBuilder = AssetsCompanion Function({
  Value<int> id,
  required int scriptId,
  required String type,
  required String name,
  required String stableId,
  Value<int?> variantOf,
  Value<String?> appearanceAnchor,
  Value<String> boardLayout,
  Value<String> prompt,
  Value<String?> imagePath,
  Value<String> status,
});
typedef $$AssetsTableUpdateCompanionBuilder = AssetsCompanion Function({
  Value<int> id,
  Value<int> scriptId,
  Value<String> type,
  Value<String> name,
  Value<String> stableId,
  Value<int?> variantOf,
  Value<String?> appearanceAnchor,
  Value<String> boardLayout,
  Value<String> prompt,
  Value<String?> imagePath,
  Value<String> status,
});

final class $$AssetsTableReferences
    extends BaseReferences<_$AppDatabase, $AssetsTable, Asset> {
  $$AssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScriptsTable _scriptIdTable(_$AppDatabase db) =>
      db.scripts.createAlias('assets__script_id__scripts__id');

  $$ScriptsTableProcessedTableManager get scriptId {
    final $_column = $_itemColumn<int>('script_id')!;

    final manager = $$ScriptsTableTableManager(
      $_db,
      $_db.scripts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scriptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AssetRefsTable, List<AssetRef>>
  _assetRefsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.assetRefs,
    aliasName: 'assets__id__asset_refs__asset_id',
  );

  $$AssetRefsTableProcessedTableManager get assetRefsRefs {
    final manager = $$AssetRefsTableTableManager(
      $_db,
      $_db.assetRefs,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_assetRefsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AssetsTableFilterComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stableId => $composableBuilder(
    column: $table.stableId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get variantOf => $composableBuilder(
    column: $table.variantOf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appearanceAnchor => $composableBuilder(
    column: $table.appearanceAnchor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boardLayout => $composableBuilder(
    column: $table.boardLayout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$ScriptsTableFilterComposer get scriptId {
    final $$ScriptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptId,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableFilterComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> assetRefsRefs(
    Expression<bool> Function($$AssetRefsTableFilterComposer f) f,
  ) {
    final $$AssetRefsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetRefs,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetRefsTableFilterComposer(
            $db: $db,
            $table: $db.assetRefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stableId => $composableBuilder(
    column: $table.stableId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get variantOf => $composableBuilder(
    column: $table.variantOf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appearanceAnchor => $composableBuilder(
    column: $table.appearanceAnchor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boardLayout => $composableBuilder(
    column: $table.boardLayout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScriptsTableOrderingComposer get scriptId {
    final $$ScriptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptId,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableOrderingComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get stableId =>
      $composableBuilder(column: $table.stableId, builder: (column) => column);

  GeneratedColumn<int> get variantOf =>
      $composableBuilder(column: $table.variantOf, builder: (column) => column);

  GeneratedColumn<String> get appearanceAnchor => $composableBuilder(
    column: $table.appearanceAnchor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boardLayout => $composableBuilder(
    column: $table.boardLayout,
    builder: (column) => column,
  );

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$ScriptsTableAnnotationComposer get scriptId {
    final $$ScriptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptId,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableAnnotationComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> assetRefsRefs<T extends Object>(
    Expression<T> Function($$AssetRefsTableAnnotationComposer a) f,
  ) {
    final $$AssetRefsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetRefs,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetRefsTableAnnotationComposer(
            $db: $db,
            $table: $db.assetRefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AssetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetsTable,
          Asset,
          $$AssetsTableFilterComposer,
          $$AssetsTableOrderingComposer,
          $$AssetsTableAnnotationComposer,
          $$AssetsTableCreateCompanionBuilder,
          $$AssetsTableUpdateCompanionBuilder,
          (Asset, $$AssetsTableReferences),
          Asset,
          PrefetchHooks Function({bool scriptId, bool assetRefsRefs})
        > {
  $$AssetsTableTableManager(_$AppDatabase db, $AssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> scriptId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> stableId = const Value.absent(),
                Value<int?> variantOf = const Value.absent(),
                Value<String?> appearanceAnchor = const Value.absent(),
                Value<String> boardLayout = const Value.absent(),
                Value<String> prompt = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => AssetsCompanion(
                id: id,
                scriptId: scriptId,
                type: type,
                name: name,
                stableId: stableId,
                variantOf: variantOf,
                appearanceAnchor: appearanceAnchor,
                boardLayout: boardLayout,
                prompt: prompt,
                imagePath: imagePath,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int scriptId,
                required String type,
                required String name,
                required String stableId,
                Value<int?> variantOf = const Value.absent(),
                Value<String?> appearanceAnchor = const Value.absent(),
                Value<String> boardLayout = const Value.absent(),
                Value<String> prompt = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => AssetsCompanion.insert(
                id: id,
                scriptId: scriptId,
                type: type,
                name: name,
                stableId: stableId,
                variantOf: variantOf,
                appearanceAnchor: appearanceAnchor,
                boardLayout: boardLayout,
                prompt: prompt,
                imagePath: imagePath,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AssetsTable, Asset>(table),
                  $$AssetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scriptId = false, assetRefsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (assetRefsRefs) db.assetRefs],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scriptId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.scriptId,
                        referencedTable: $$AssetsTableReferences._scriptIdTable(
                          db,
                        ),
                        referencedColumn: $$AssetsTableReferences
                            ._scriptIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (assetRefsRefs)
                    await $_getPrefetchedData<Asset, $AssetsTable, AssetRef>(
                      currentTable: table,
                      referencedTable: $$AssetsTableReferences
                          ._assetRefsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$AssetsTableReferences(db, table, p0).assetRefsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.assetId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetsTable,
      Asset,
      $$AssetsTableFilterComposer,
      $$AssetsTableOrderingComposer,
      $$AssetsTableAnnotationComposer,
      $$AssetsTableCreateCompanionBuilder,
      $$AssetsTableUpdateCompanionBuilder,
      (Asset, $$AssetsTableReferences),
      Asset,
      PrefetchHooks Function({bool scriptId, bool assetRefsRefs})
    >;
typedef $$ShotsTableCreateCompanionBuilder = ShotsCompanion Function({
  Value<int> id,
  required int scriptId,
  required String globalSeq,
  Value<int> batch,
  Value<String?> modelVersion,
  Value<int> durationMs,
  required String globalTimeRange,
  Value<String> beatRefs,
  Value<String> assetStates,
  Value<String?> shotType,
  Value<int?> sceneId,
  Value<String> prompt,
  Value<String> status,
  Value<String?> outputPath,
  Value<String> outputType,
});
typedef $$ShotsTableUpdateCompanionBuilder = ShotsCompanion Function({
  Value<int> id,
  Value<int> scriptId,
  Value<String> globalSeq,
  Value<int> batch,
  Value<String?> modelVersion,
  Value<int> durationMs,
  Value<String> globalTimeRange,
  Value<String> beatRefs,
  Value<String> assetStates,
  Value<String?> shotType,
  Value<int?> sceneId,
  Value<String> prompt,
  Value<String> status,
  Value<String?> outputPath,
  Value<String> outputType,
});

final class $$ShotsTableReferences
    extends BaseReferences<_$AppDatabase, $ShotsTable, Shot> {
  $$ShotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScriptsTable _scriptIdTable(_$AppDatabase db) =>
      db.scripts.createAlias('shots__script_id__scripts__id');

  $$ScriptsTableProcessedTableManager get scriptId {
    final $_column = $_itemColumn<int>('script_id')!;

    final manager = $$ScriptsTableTableManager(
      $_db,
      $_db.scripts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scriptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ShotFramesTable, List<ShotFrame>>
  _shotFramesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shotFrames,
    aliasName: 'shots__id__shot_frames__shot_id',
  );

  $$ShotFramesTableProcessedTableManager get shotFramesRefs {
    final manager = $$ShotFramesTableTableManager(
      $_db,
      $_db.shotFrames,
    ).filter((f) => f.shotId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_shotFramesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AssetRefsTable, List<AssetRef>>
  _assetRefsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.assetRefs,
    aliasName: 'shots__id__asset_refs__shot_id',
  );

  $$AssetRefsTableProcessedTableManager get assetRefsRefs {
    final manager = $$AssetRefsTableTableManager(
      $_db,
      $_db.assetRefs,
    ).filter((f) => f.shotId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_assetRefsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VideoTasksTable, List<VideoTask>>
  _videoTasksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.videoTasks,
    aliasName: 'shots__id__video_tasks__shot_id',
  );

  $$VideoTasksTableProcessedTableManager get videoTasksRefs {
    final manager = $$VideoTasksTableTableManager(
      $_db,
      $_db.videoTasks,
    ).filter((f) => f.shotId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_videoTasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ShotsTableFilterComposer extends Composer<_$AppDatabase, $ShotsTable> {
  $$ShotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get globalSeq => $composableBuilder(
    column: $table.globalSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get batch => $composableBuilder(
    column: $table.batch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get globalTimeRange => $composableBuilder(
    column: $table.globalTimeRange,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beatRefs => $composableBuilder(
    column: $table.beatRefs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetStates => $composableBuilder(
    column: $table.assetStates,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shotType => $composableBuilder(
    column: $table.shotType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sceneId => $composableBuilder(
    column: $table.sceneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outputPath => $composableBuilder(
    column: $table.outputPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outputType => $composableBuilder(
    column: $table.outputType,
    builder: (column) => ColumnFilters(column),
  );

  $$ScriptsTableFilterComposer get scriptId {
    final $$ScriptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptId,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableFilterComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> shotFramesRefs(
    Expression<bool> Function($$ShotFramesTableFilterComposer f) f,
  ) {
    final $$ShotFramesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shotFrames,
      getReferencedColumn: (t) => t.shotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotFramesTableFilterComposer(
            $db: $db,
            $table: $db.shotFrames,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> assetRefsRefs(
    Expression<bool> Function($$AssetRefsTableFilterComposer f) f,
  ) {
    final $$AssetRefsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetRefs,
      getReferencedColumn: (t) => t.shotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetRefsTableFilterComposer(
            $db: $db,
            $table: $db.assetRefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> videoTasksRefs(
    Expression<bool> Function($$VideoTasksTableFilterComposer f) f,
  ) {
    final $$VideoTasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.videoTasks,
      getReferencedColumn: (t) => t.shotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VideoTasksTableFilterComposer(
            $db: $db,
            $table: $db.videoTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShotsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShotsTable> {
  $$ShotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get globalSeq => $composableBuilder(
    column: $table.globalSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get batch => $composableBuilder(
    column: $table.batch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get globalTimeRange => $composableBuilder(
    column: $table.globalTimeRange,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beatRefs => $composableBuilder(
    column: $table.beatRefs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetStates => $composableBuilder(
    column: $table.assetStates,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shotType => $composableBuilder(
    column: $table.shotType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sceneId => $composableBuilder(
    column: $table.sceneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outputPath => $composableBuilder(
    column: $table.outputPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outputType => $composableBuilder(
    column: $table.outputType,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScriptsTableOrderingComposer get scriptId {
    final $$ScriptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptId,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableOrderingComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShotsTable> {
  $$ShotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get globalSeq =>
      $composableBuilder(column: $table.globalSeq, builder: (column) => column);

  GeneratedColumn<int> get batch =>
      $composableBuilder(column: $table.batch, builder: (column) => column);

  GeneratedColumn<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get globalTimeRange => $composableBuilder(
    column: $table.globalTimeRange,
    builder: (column) => column,
  );

  GeneratedColumn<String> get beatRefs =>
      $composableBuilder(column: $table.beatRefs, builder: (column) => column);

  GeneratedColumn<String> get assetStates => $composableBuilder(
    column: $table.assetStates,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shotType =>
      $composableBuilder(column: $table.shotType, builder: (column) => column);

  GeneratedColumn<int> get sceneId =>
      $composableBuilder(column: $table.sceneId, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get outputPath => $composableBuilder(
    column: $table.outputPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outputType => $composableBuilder(
    column: $table.outputType,
    builder: (column) => column,
  );

  $$ScriptsTableAnnotationComposer get scriptId {
    final $$ScriptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptId,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableAnnotationComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> shotFramesRefs<T extends Object>(
    Expression<T> Function($$ShotFramesTableAnnotationComposer a) f,
  ) {
    final $$ShotFramesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shotFrames,
      getReferencedColumn: (t) => t.shotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotFramesTableAnnotationComposer(
            $db: $db,
            $table: $db.shotFrames,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> assetRefsRefs<T extends Object>(
    Expression<T> Function($$AssetRefsTableAnnotationComposer a) f,
  ) {
    final $$AssetRefsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetRefs,
      getReferencedColumn: (t) => t.shotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetRefsTableAnnotationComposer(
            $db: $db,
            $table: $db.assetRefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> videoTasksRefs<T extends Object>(
    Expression<T> Function($$VideoTasksTableAnnotationComposer a) f,
  ) {
    final $$VideoTasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.videoTasks,
      getReferencedColumn: (t) => t.shotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VideoTasksTableAnnotationComposer(
            $db: $db,
            $table: $db.videoTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShotsTable,
          Shot,
          $$ShotsTableFilterComposer,
          $$ShotsTableOrderingComposer,
          $$ShotsTableAnnotationComposer,
          $$ShotsTableCreateCompanionBuilder,
          $$ShotsTableUpdateCompanionBuilder,
          (Shot, $$ShotsTableReferences),
          Shot,
          PrefetchHooks Function({
            bool scriptId,
            bool shotFramesRefs,
            bool assetRefsRefs,
            bool videoTasksRefs,
          })
        > {
  $$ShotsTableTableManager(_$AppDatabase db, $ShotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> scriptId = const Value.absent(),
                Value<String> globalSeq = const Value.absent(),
                Value<int> batch = const Value.absent(),
                Value<String?> modelVersion = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> globalTimeRange = const Value.absent(),
                Value<String> beatRefs = const Value.absent(),
                Value<String> assetStates = const Value.absent(),
                Value<String?> shotType = const Value.absent(),
                Value<int?> sceneId = const Value.absent(),
                Value<String> prompt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> outputPath = const Value.absent(),
                Value<String> outputType = const Value.absent(),
              }) => ShotsCompanion(
                id: id,
                scriptId: scriptId,
                globalSeq: globalSeq,
                batch: batch,
                modelVersion: modelVersion,
                durationMs: durationMs,
                globalTimeRange: globalTimeRange,
                beatRefs: beatRefs,
                assetStates: assetStates,
                shotType: shotType,
                sceneId: sceneId,
                prompt: prompt,
                status: status,
                outputPath: outputPath,
                outputType: outputType,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int scriptId,
                required String globalSeq,
                Value<int> batch = const Value.absent(),
                Value<String?> modelVersion = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                required String globalTimeRange,
                Value<String> beatRefs = const Value.absent(),
                Value<String> assetStates = const Value.absent(),
                Value<String?> shotType = const Value.absent(),
                Value<int?> sceneId = const Value.absent(),
                Value<String> prompt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> outputPath = const Value.absent(),
                Value<String> outputType = const Value.absent(),
              }) => ShotsCompanion.insert(
                id: id,
                scriptId: scriptId,
                globalSeq: globalSeq,
                batch: batch,
                modelVersion: modelVersion,
                durationMs: durationMs,
                globalTimeRange: globalTimeRange,
                beatRefs: beatRefs,
                assetStates: assetStates,
                shotType: shotType,
                sceneId: sceneId,
                prompt: prompt,
                status: status,
                outputPath: outputPath,
                outputType: outputType,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShotsTable, Shot>(table),
                  $$ShotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                scriptId = false,
                shotFramesRefs = false,
                assetRefsRefs = false,
                videoTasksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (shotFramesRefs) db.shotFrames,
                    if (assetRefsRefs) db.assetRefs,
                    if (videoTasksRefs) db.videoTasks,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (scriptId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.scriptId,
                            referencedTable: $$ShotsTableReferences
                                ._scriptIdTable(db),
                            referencedColumn: $$ShotsTableReferences
                                ._scriptIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (shotFramesRefs)
                        await $_getPrefetchedData<Shot, $ShotsTable, ShotFrame>(
                          currentTable: table,
                          referencedTable: $$ShotsTableReferences
                              ._shotFramesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShotsTableReferences(
                                db,
                                table,
                                p0,
                              ).shotFramesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.shotId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (assetRefsRefs)
                        await $_getPrefetchedData<Shot, $ShotsTable, AssetRef>(
                          currentTable: table,
                          referencedTable: $$ShotsTableReferences
                              ._assetRefsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShotsTableReferences(
                                db,
                                table,
                                p0,
                              ).assetRefsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.shotId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (videoTasksRefs)
                        await $_getPrefetchedData<Shot, $ShotsTable, VideoTask>(
                          currentTable: table,
                          referencedTable: $$ShotsTableReferences
                              ._videoTasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShotsTableReferences(
                                db,
                                table,
                                p0,
                              ).videoTasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.shotId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ShotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShotsTable,
      Shot,
      $$ShotsTableFilterComposer,
      $$ShotsTableOrderingComposer,
      $$ShotsTableAnnotationComposer,
      $$ShotsTableCreateCompanionBuilder,
      $$ShotsTableUpdateCompanionBuilder,
      (Shot, $$ShotsTableReferences),
      Shot,
      PrefetchHooks Function({
        bool scriptId,
        bool shotFramesRefs,
        bool assetRefsRefs,
        bool videoTasksRefs,
      })
    >;
typedef $$ShotFramesTableCreateCompanionBuilder = ShotFramesCompanion Function({
  Value<int> id,
  required int shotId,
  required int seq,
  required String timeRange,
  required String subject,
  required String shotSize,
  required String angle,
  Value<String> camera,
  Value<String> blocking,
  Value<String> performance,
  Value<String?> dialogue,
});
typedef $$ShotFramesTableUpdateCompanionBuilder = ShotFramesCompanion Function({
  Value<int> id,
  Value<int> shotId,
  Value<int> seq,
  Value<String> timeRange,
  Value<String> subject,
  Value<String> shotSize,
  Value<String> angle,
  Value<String> camera,
  Value<String> blocking,
  Value<String> performance,
  Value<String?> dialogue,
});

final class $$ShotFramesTableReferences
    extends BaseReferences<_$AppDatabase, $ShotFramesTable, ShotFrame> {
  $$ShotFramesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ShotsTable _shotIdTable(_$AppDatabase db) =>
      db.shots.createAlias('shot_frames__shot_id__shots__id');

  $$ShotsTableProcessedTableManager get shotId {
    final $_column = $_itemColumn<int>('shot_id')!;

    final manager = $$ShotsTableTableManager(
      $_db,
      $_db.shots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ShotFramesTableFilterComposer
    extends Composer<_$AppDatabase, $ShotFramesTable> {
  $$ShotFramesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeRange => $composableBuilder(
    column: $table.timeRange,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shotSize => $composableBuilder(
    column: $table.shotSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get angle => $composableBuilder(
    column: $table.angle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get camera => $composableBuilder(
    column: $table.camera,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blocking => $composableBuilder(
    column: $table.blocking,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get performance => $composableBuilder(
    column: $table.performance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dialogue => $composableBuilder(
    column: $table.dialogue,
    builder: (column) => ColumnFilters(column),
  );

  $$ShotsTableFilterComposer get shotId {
    final $$ShotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shotId,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotsTableFilterComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShotFramesTableOrderingComposer
    extends Composer<_$AppDatabase, $ShotFramesTable> {
  $$ShotFramesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeRange => $composableBuilder(
    column: $table.timeRange,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shotSize => $composableBuilder(
    column: $table.shotSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get angle => $composableBuilder(
    column: $table.angle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get camera => $composableBuilder(
    column: $table.camera,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blocking => $composableBuilder(
    column: $table.blocking,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get performance => $composableBuilder(
    column: $table.performance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dialogue => $composableBuilder(
    column: $table.dialogue,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShotsTableOrderingComposer get shotId {
    final $$ShotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shotId,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotsTableOrderingComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShotFramesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShotFramesTable> {
  $$ShotFramesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get timeRange =>
      $composableBuilder(column: $table.timeRange, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get shotSize =>
      $composableBuilder(column: $table.shotSize, builder: (column) => column);

  GeneratedColumn<String> get angle =>
      $composableBuilder(column: $table.angle, builder: (column) => column);

  GeneratedColumn<String> get camera =>
      $composableBuilder(column: $table.camera, builder: (column) => column);

  GeneratedColumn<String> get blocking =>
      $composableBuilder(column: $table.blocking, builder: (column) => column);

  GeneratedColumn<String> get performance => $composableBuilder(
    column: $table.performance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dialogue =>
      $composableBuilder(column: $table.dialogue, builder: (column) => column);

  $$ShotsTableAnnotationComposer get shotId {
    final $$ShotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shotId,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotsTableAnnotationComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShotFramesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShotFramesTable,
          ShotFrame,
          $$ShotFramesTableFilterComposer,
          $$ShotFramesTableOrderingComposer,
          $$ShotFramesTableAnnotationComposer,
          $$ShotFramesTableCreateCompanionBuilder,
          $$ShotFramesTableUpdateCompanionBuilder,
          (ShotFrame, $$ShotFramesTableReferences),
          ShotFrame,
          PrefetchHooks Function({bool shotId})
        > {
  $$ShotFramesTableTableManager(_$AppDatabase db, $ShotFramesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShotFramesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShotFramesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShotFramesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> shotId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> timeRange = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> shotSize = const Value.absent(),
                Value<String> angle = const Value.absent(),
                Value<String> camera = const Value.absent(),
                Value<String> blocking = const Value.absent(),
                Value<String> performance = const Value.absent(),
                Value<String?> dialogue = const Value.absent(),
              }) => ShotFramesCompanion(
                id: id,
                shotId: shotId,
                seq: seq,
                timeRange: timeRange,
                subject: subject,
                shotSize: shotSize,
                angle: angle,
                camera: camera,
                blocking: blocking,
                performance: performance,
                dialogue: dialogue,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int shotId,
                required int seq,
                required String timeRange,
                required String subject,
                required String shotSize,
                required String angle,
                Value<String> camera = const Value.absent(),
                Value<String> blocking = const Value.absent(),
                Value<String> performance = const Value.absent(),
                Value<String?> dialogue = const Value.absent(),
              }) => ShotFramesCompanion.insert(
                id: id,
                shotId: shotId,
                seq: seq,
                timeRange: timeRange,
                subject: subject,
                shotSize: shotSize,
                angle: angle,
                camera: camera,
                blocking: blocking,
                performance: performance,
                dialogue: dialogue,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShotFramesTable, ShotFrame>(table),
                  $$ShotFramesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shotId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (shotId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.shotId,
                        referencedTable: $$ShotFramesTableReferences
                            ._shotIdTable(db),
                        referencedColumn: $$ShotFramesTableReferences
                            ._shotIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ShotFramesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShotFramesTable,
      ShotFrame,
      $$ShotFramesTableFilterComposer,
      $$ShotFramesTableOrderingComposer,
      $$ShotFramesTableAnnotationComposer,
      $$ShotFramesTableCreateCompanionBuilder,
      $$ShotFramesTableUpdateCompanionBuilder,
      (ShotFrame, $$ShotFramesTableReferences),
      ShotFrame,
      PrefetchHooks Function({bool shotId})
    >;
typedef $$AssetRefsTableCreateCompanionBuilder = AssetRefsCompanion Function({
  Value<int> id,
  required int shotId,
  required int assetId,
  required String role,
  Value<int> order,
});
typedef $$AssetRefsTableUpdateCompanionBuilder = AssetRefsCompanion Function({
  Value<int> id,
  Value<int> shotId,
  Value<int> assetId,
  Value<String> role,
  Value<int> order,
});

final class $$AssetRefsTableReferences
    extends BaseReferences<_$AppDatabase, $AssetRefsTable, AssetRef> {
  $$AssetRefsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ShotsTable _shotIdTable(_$AppDatabase db) =>
      db.shots.createAlias('asset_refs__shot_id__shots__id');

  $$ShotsTableProcessedTableManager get shotId {
    final $_column = $_itemColumn<int>('shot_id')!;

    final manager = $$ShotsTableTableManager(
      $_db,
      $_db.shots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AssetsTable _assetIdTable(_$AppDatabase db) =>
      db.assets.createAlias('asset_refs__asset_id__assets__id');

  $$AssetsTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<int>('asset_id')!;

    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AssetRefsTableFilterComposer
    extends Composer<_$AppDatabase, $AssetRefsTable> {
  $$AssetRefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  $$ShotsTableFilterComposer get shotId {
    final $$ShotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shotId,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotsTableFilterComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AssetsTableFilterComposer get assetId {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetRefsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetRefsTable> {
  $$AssetRefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShotsTableOrderingComposer get shotId {
    final $$ShotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shotId,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotsTableOrderingComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AssetsTableOrderingComposer get assetId {
    final $$AssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableOrderingComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetRefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetRefsTable> {
  $$AssetRefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  $$ShotsTableAnnotationComposer get shotId {
    final $$ShotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shotId,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotsTableAnnotationComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AssetsTableAnnotationComposer get assetId {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetRefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetRefsTable,
          AssetRef,
          $$AssetRefsTableFilterComposer,
          $$AssetRefsTableOrderingComposer,
          $$AssetRefsTableAnnotationComposer,
          $$AssetRefsTableCreateCompanionBuilder,
          $$AssetRefsTableUpdateCompanionBuilder,
          (AssetRef, $$AssetRefsTableReferences),
          AssetRef,
          PrefetchHooks Function({bool shotId, bool assetId})
        > {
  $$AssetRefsTableTableManager(_$AppDatabase db, $AssetRefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetRefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetRefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetRefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> shotId = const Value.absent(),
                Value<int> assetId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<int> order = const Value.absent(),
              }) => AssetRefsCompanion(
                id: id,
                shotId: shotId,
                assetId: assetId,
                role: role,
                order: order,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int shotId,
                required int assetId,
                required String role,
                Value<int> order = const Value.absent(),
              }) => AssetRefsCompanion.insert(
                id: id,
                shotId: shotId,
                assetId: assetId,
                role: role,
                order: order,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AssetRefsTable, AssetRef>(table),
                  $$AssetRefsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shotId = false, assetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (shotId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.shotId,
                        referencedTable: $$AssetRefsTableReferences
                            ._shotIdTable(db),
                        referencedColumn: $$AssetRefsTableReferences
                            ._shotIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (assetId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.assetId,
                        referencedTable: $$AssetRefsTableReferences
                            ._assetIdTable(db),
                        referencedColumn: $$AssetRefsTableReferences
                            ._assetIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AssetRefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetRefsTable,
      AssetRef,
      $$AssetRefsTableFilterComposer,
      $$AssetRefsTableOrderingComposer,
      $$AssetRefsTableAnnotationComposer,
      $$AssetRefsTableCreateCompanionBuilder,
      $$AssetRefsTableUpdateCompanionBuilder,
      (AssetRef, $$AssetRefsTableReferences),
      AssetRef,
      PrefetchHooks Function({bool shotId, bool assetId})
    >;
typedef $$VideoTasksTableCreateCompanionBuilder = VideoTasksCompanion Function({
  Value<int> id,
  required int shotId,
  required String taskId,
  required String providerId,
  Value<String> status,
  Value<String> paramsJson,
  Value<String?> error,
  Value<String?> outputPath,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$VideoTasksTableUpdateCompanionBuilder = VideoTasksCompanion Function({
  Value<int> id,
  Value<int> shotId,
  Value<String> taskId,
  Value<String> providerId,
  Value<String> status,
  Value<String> paramsJson,
  Value<String?> error,
  Value<String?> outputPath,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$VideoTasksTableReferences
    extends BaseReferences<_$AppDatabase, $VideoTasksTable, VideoTask> {
  $$VideoTasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ShotsTable _shotIdTable(_$AppDatabase db) =>
      db.shots.createAlias('video_tasks__shot_id__shots__id');

  $$ShotsTableProcessedTableManager get shotId {
    final $_column = $_itemColumn<int>('shot_id')!;

    final manager = $$ShotsTableTableManager(
      $_db,
      $_db.shots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VideoTasksTableFilterComposer
    extends Composer<_$AppDatabase, $VideoTasksTable> {
  $$VideoTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paramsJson => $composableBuilder(
    column: $table.paramsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outputPath => $composableBuilder(
    column: $table.outputPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ShotsTableFilterComposer get shotId {
    final $$ShotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shotId,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotsTableFilterComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VideoTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $VideoTasksTable> {
  $$VideoTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paramsJson => $composableBuilder(
    column: $table.paramsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outputPath => $composableBuilder(
    column: $table.outputPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShotsTableOrderingComposer get shotId {
    final $$ShotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shotId,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotsTableOrderingComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VideoTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $VideoTasksTable> {
  $$VideoTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get paramsJson => $composableBuilder(
    column: $table.paramsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<String> get outputPath => $composableBuilder(
    column: $table.outputPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ShotsTableAnnotationComposer get shotId {
    final $$ShotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shotId,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotsTableAnnotationComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VideoTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VideoTasksTable,
          VideoTask,
          $$VideoTasksTableFilterComposer,
          $$VideoTasksTableOrderingComposer,
          $$VideoTasksTableAnnotationComposer,
          $$VideoTasksTableCreateCompanionBuilder,
          $$VideoTasksTableUpdateCompanionBuilder,
          (VideoTask, $$VideoTasksTableReferences),
          VideoTask,
          PrefetchHooks Function({bool shotId})
        > {
  $$VideoTasksTableTableManager(_$AppDatabase db, $VideoTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VideoTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VideoTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VideoTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> shotId = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> paramsJson = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String?> outputPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => VideoTasksCompanion(
                id: id,
                shotId: shotId,
                taskId: taskId,
                providerId: providerId,
                status: status,
                paramsJson: paramsJson,
                error: error,
                outputPath: outputPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int shotId,
                required String taskId,
                required String providerId,
                Value<String> status = const Value.absent(),
                Value<String> paramsJson = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<String?> outputPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => VideoTasksCompanion.insert(
                id: id,
                shotId: shotId,
                taskId: taskId,
                providerId: providerId,
                status: status,
                paramsJson: paramsJson,
                error: error,
                outputPath: outputPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VideoTasksTable, VideoTask>(table),
                  $$VideoTasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shotId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (shotId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.shotId,
                        referencedTable: $$VideoTasksTableReferences
                            ._shotIdTable(db),
                        referencedColumn: $$VideoTasksTableReferences
                            ._shotIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VideoTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VideoTasksTable,
      VideoTask,
      $$VideoTasksTableFilterComposer,
      $$VideoTasksTableOrderingComposer,
      $$VideoTasksTableAnnotationComposer,
      $$VideoTasksTableCreateCompanionBuilder,
      $$VideoTasksTableUpdateCompanionBuilder,
      (VideoTask, $$VideoTasksTableReferences),
      VideoTask,
      PrefetchHooks Function({bool shotId})
    >;
typedef $$ProviderConfigsTableCreateCompanionBuilder =
    ProviderConfigsCompanion Function({
      required String id,
      required String group,
      required String label,
      required String baseUrl,
      required String protocol,
      Value<String> models,
      Value<String?> readme,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ProviderConfigsTableUpdateCompanionBuilder =
    ProviderConfigsCompanion Function({
      Value<String> id,
      Value<String> group,
      Value<String> label,
      Value<String> baseUrl,
      Value<String> protocol,
      Value<String> models,
      Value<String?> readme,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ProviderConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $ProviderConfigsTable> {
  $$ProviderConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get group => $composableBuilder(
    column: $table.group,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get protocol => $composableBuilder(
    column: $table.protocol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get models => $composableBuilder(
    column: $table.models,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readme => $composableBuilder(
    column: $table.readme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProviderConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProviderConfigsTable> {
  $$ProviderConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get group => $composableBuilder(
    column: $table.group,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get protocol => $composableBuilder(
    column: $table.protocol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get models => $composableBuilder(
    column: $table.models,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readme => $composableBuilder(
    column: $table.readme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProviderConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProviderConfigsTable> {
  $$ProviderConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get group =>
      $composableBuilder(column: $table.group, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get protocol =>
      $composableBuilder(column: $table.protocol, builder: (column) => column);

  GeneratedColumn<String> get models =>
      $composableBuilder(column: $table.models, builder: (column) => column);

  GeneratedColumn<String> get readme =>
      $composableBuilder(column: $table.readme, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProviderConfigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProviderConfigsTable,
          ProviderConfig,
          $$ProviderConfigsTableFilterComposer,
          $$ProviderConfigsTableOrderingComposer,
          $$ProviderConfigsTableAnnotationComposer,
          $$ProviderConfigsTableCreateCompanionBuilder,
          $$ProviderConfigsTableUpdateCompanionBuilder,
          (
            ProviderConfig,
            BaseReferences<
              _$AppDatabase,
              $ProviderConfigsTable,
              ProviderConfig
            >,
          ),
          ProviderConfig,
          PrefetchHooks Function()
        > {
  $$ProviderConfigsTableTableManager(
    _$AppDatabase db,
    $ProviderConfigsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProviderConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProviderConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> group = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<String> protocol = const Value.absent(),
                Value<String> models = const Value.absent(),
                Value<String?> readme = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderConfigsCompanion(
                id: id,
                group: group,
                label: label,
                baseUrl: baseUrl,
                protocol: protocol,
                models: models,
                readme: readme,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String group,
                required String label,
                required String baseUrl,
                required String protocol,
                Value<String> models = const Value.absent(),
                Value<String?> readme = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderConfigsCompanion.insert(
                id: id,
                group: group,
                label: label,
                baseUrl: baseUrl,
                protocol: protocol,
                models: models,
                readme: readme,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProviderConfigsTable, ProviderConfig>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ProviderConfigsTable,
                    ProviderConfig
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProviderConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProviderConfigsTable,
      ProviderConfig,
      $$ProviderConfigsTableFilterComposer,
      $$ProviderConfigsTableOrderingComposer,
      $$ProviderConfigsTableAnnotationComposer,
      $$ProviderConfigsTableCreateCompanionBuilder,
      $$ProviderConfigsTableUpdateCompanionBuilder,
      (
        ProviderConfig,
        BaseReferences<_$AppDatabase, $ProviderConfigsTable, ProviderConfig>,
      ),
      ProviderConfig,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$NovelBooksTableTableManager get novelBooks =>
      $$NovelBooksTableTableManager(_db, _db.novelBooks);
  $$ChaptersTableTableManager get chapters =>
      $$ChaptersTableTableManager(_db, _db.chapters);
  $$ChapterRevisionsTableTableManager get chapterRevisions =>
      $$ChapterRevisionsTableTableManager(_db, _db.chapterRevisions);
  $$TruthFilesTableTableManager get truthFiles =>
      $$TruthFilesTableTableManager(_db, _db.truthFiles);
  $$ScriptsTableTableManager get scripts =>
      $$ScriptsTableTableManager(_db, _db.scripts);
  $$ScriptRevisionsTableTableManager get scriptRevisions =>
      $$ScriptRevisionsTableTableManager(_db, _db.scriptRevisions);
  $$ScenesTableTableManager get scenes =>
      $$ScenesTableTableManager(_db, _db.scenes);
  $$BeatsTableTableManager get beats =>
      $$BeatsTableTableManager(_db, _db.beats);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db, _db.assets);
  $$ShotsTableTableManager get shots =>
      $$ShotsTableTableManager(_db, _db.shots);
  $$ShotFramesTableTableManager get shotFrames =>
      $$ShotFramesTableTableManager(_db, _db.shotFrames);
  $$AssetRefsTableTableManager get assetRefs =>
      $$AssetRefsTableTableManager(_db, _db.assetRefs);
  $$VideoTasksTableTableManager get videoTasks =>
      $$VideoTasksTableTableManager(_db, _db.videoTasks);
  $$ProviderConfigsTableTableManager get providerConfigs =>
      $$ProviderConfigsTableTableManager(_db, _db.providerConfigs);
}
