import 'package:drift/drift.dart';

/// 项目：一部作品的顶层容器。
@DataClassName('Project')
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get coverPath => text().nullable()();
  TextColumn get genre => text().nullable()();
  TextColumn get description => text().nullable()();
  // 状态：草稿 / 进行中 / 完结。
  TextColumn get status => text().withDefault(const Constant('草稿'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 小说书：项目内的写作实体（借鉴 InkOS 的 book）。
@DataClassName('NovelBook')
class NovelBooks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId => integer().references(Projects, #id)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get genre => text().nullable()();
  TextColumn get styleGuide => text().nullable()();
  // 世界观描述（静态设定）。
  TextColumn get world => text().nullable()();
  // 故事命题：谁想要什么，受什么阻碍，失败失去什么。
  TextColumn get premise => text().nullable()();
  // 大纲（Markdown，逐章目标/事件/结尾）。
  TextColumn get outline => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('草稿'))();
}

/// 章节。
@DataClassName('Chapter')
class Chapters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer().references(NovelBooks, #id)();
  IntColumn get seq => integer()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get summary => text().nullable()();
  TextColumn get content => text().nullable()();
  IntColumn get wordCount => integer().withDefault(const Constant(0))();
  // 状态：草稿 / 审校中 / 定稿。
  TextColumn get status => text().withDefault(const Constant('草稿'))();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 真相状态（借鉴 InkOS 权威状态机制，7 类）。
/// kind：世界事实 / 角色矩阵 / 资源与道具 / 伏笔钩子 / 章节摘要 / 作者意图 / 当前焦点。
@DataClassName('TruthFile')
class TruthFiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer().references(NovelBooks, #id)();
  TextColumn get kind => text()();
  // 结构化 JSON，随 kind 不同结构不同。
  TextColumn get content => text().withDefault(const Constant('{}'))();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {bookId, kind},
  ];
}

/// 剧本。
@DataClassName('Script')
class Scripts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer().references(NovelBooks, #id)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  IntColumn get version => integer().withDefault(const Constant(1))();
  // 忠实度：严格保留 / 允许合理压缩。
  TextColumn get fidelityMode => text().withDefault(const Constant('严格保留'))();
  TextColumn get artStyle => text().nullable()();
  TextColumn get aspectRatio => text().withDefault(const Constant('16:9'))();
  TextColumn get language => text().withDefault(const Constant('zh'))();
  // 状态：草案 / 定稿。
  TextColumn get status => text().withDefault(const Constant('草案'))();
  // 结构化 JSON：{ scenes: [...] }。
  TextColumn get content => text().withDefault(const Constant('{}'))();
}

/// 场。
@DataClassName('Scene')
class Scenes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get scriptId => integer().references(Scripts, #id)();
  IntColumn get seq => integer()();
  TextColumn get location => text()();
  TextColumn get time => text()();
  // JSON 数组：出场人物名。
  TextColumn get characters => text().withDefault(const Constant('[]'))();
  TextColumn get summary => text().nullable()();
  TextColumn get action => text().withDefault(const Constant(''))();
  TextColumn get startState => text().nullable()();
  TextColumn get endState => text().nullable()();
  TextColumn get transition => text().nullable()();
}

/// 原子节拍（借鉴 Toonflow A2）。
@DataClassName('Beat')
class Beats extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sceneId => integer().references(Scenes, #id)();
  IntColumn get seq => integer()();
  // 类型：对白 / 动作 / 反应 / 信息 / 过渡 / 留白。
  TextColumn get type => text()();
  // 谁做 / 谁说。
  TextColumn get who => text().withDefault(const Constant(''))();
  TextColumn get content => text()();
  // 作用对象。
  TextColumn get object => text().nullable()();
  // 源剧情位置 E##。
  TextColumn get sourceRef => text()();
  IntColumn get estDurationMs => integer().withDefault(const Constant(0))();
  // JSON 数组：转折 / 峰值 / 信息增量 / 决策 / 沉默。
  TextColumn get tags => text().withDefault(const Constant('[]'))();
}

/// 资产（角色 / 场景 / 道具）。
@DataClassName('Asset')
class Assets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get scriptId => integer().references(Scripts, #id)();
  // 类型：角色 / 场景 / 道具。
  TextColumn get type => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  // 稳定标识（跨段引用不变）。
  TextColumn get stableId => text()();
  // 变体父资产 id（可空）。
  IntColumn get variantOf => integer().nullable()();
  // 外观锚点 JSON。
  TextColumn get appearanceAnchor => text().nullable()();
  // 版式：四视图 / 主视图 / 2x2。
  TextColumn get boardLayout => text().withDefault(const Constant('四视图'))();
  TextColumn get prompt => text().withDefault(const Constant(''))();
  TextColumn get imagePath => text().nullable()();
  // 状态：待生成 / 生成中 / 待验收 / 已采用 / 废弃。
  TextColumn get status => text().withDefault(const Constant('待生成'))();
}

/// 镜头 / 片段（借鉴 Toonflow A3 分段）。
@DataClassName('Shot')
class Shots extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get scriptId => integer().references(Scripts, #id)();
  // 全局段号 G01 / G02 ...
  TextColumn get globalSeq => text()();
  IntColumn get batch => integer().withDefault(const Constant(1))();
  // 目标模型版本，如 seedance 2.0 / 2.5。
  TextColumn get modelVersion => text().nullable()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  // 全局时间区间，如 00:00-00:12。
  TextColumn get globalTimeRange => text()();
  // 景别 / 主体等。
  TextColumn get shotType => text().nullable()();
  IntColumn get sceneId => integer().nullable()();
  // 最终生成提示词。
  TextColumn get prompt => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('待提示词'))();
  TextColumn get outputPath => text().nullable()();
  // 产物类型：image / video。
  TextColumn get outputType => text().withDefault(const Constant('image'))();
}

/// 镜头内画面（借鉴 Toonflow A4 出镜状态）。
@DataClassName('ShotFrame')
class ShotFrames extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get shotId => integer().references(Shots, #id)();
  IntColumn get seq => integer()();
  TextColumn get timeRange => text()();
  TextColumn get subject => text()();
  // 景别。
  TextColumn get shotSize => text()();
  // 角度。
  TextColumn get angle => text()();
  // 运镜。
  TextColumn get camera => text().withDefault(const Constant(''))();
  // 站位。
  TextColumn get blocking => text().withDefault(const Constant(''))();
  // 表演。
  TextColumn get performance => text().withDefault(const Constant(''))();
  // 台词原文。
  TextColumn get dialogue => text().nullable()();
}

/// 镜头-资产引用（参考图绑定）。
@DataClassName('AssetRef')
class AssetRefs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get shotId => integer().references(Shots, #id)();
  IntColumn get assetId => integer().references(Assets, #id)();
  // 角色参考 / 场景参考 / 道具参考 / 仅站位。
  TextColumn get role => text()();
  IntColumn get order => integer().withDefault(const Constant(0))();
}

/// 模型供应商配置（API Key 不入库，存安全存储）。
@DataClassName('ProviderConfig')
class ProviderConfigs extends Table {
  // 由用户/系统指定的稳定 id，如 deepseek。
  TextColumn get id => text()();
  // 分组：llm / image / video。
  TextColumn get group => text()();
  TextColumn get label => text().withLength(min: 1, max: 100)();
  TextColumn get baseUrl => text()();
  // 协议：openai-completions / openai-images / async-task。
  TextColumn get protocol => text()();
  // JSON 数组：模型列表 [{ id, label }]。
  TextColumn get models => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// 章节版本快照：每次修订前保存旧内容，支持回溯。
@DataClassName('ChapterRevision')
class ChapterRevisions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get chapterId => integer().references(Chapters, #id)();
  IntColumn get revision => integer()();
  TextColumn get content => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
