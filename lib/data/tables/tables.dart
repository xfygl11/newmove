import 'package:drift/drift.dart';

import '../../core/status_constants.dart';

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
  // P3-15 作品类型：长篇 / 短篇 / 剧本 / 影游，默认「长篇」。
  TextColumn get workType => text().withDefault(const Constant('长篇'))();
  // M17 T19.5：每章目标字数，供写作与定稿字数门槛使用；0 表示不设门槛。
  IntColumn get targetWords => integer().withDefault(const Constant(2000))();
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
  // 状态：草案 / 定稿。
  TextColumn get status => text().withDefault(const Constant('草案'))();
  // 结构化 JSON：{ scenes: [...] }。
  TextColumn get content => text().withDefault(const Constant('{}'))();
  // M16 分集：集序号（空表示不参与分集）。
  IntColumn get episodeNo => integer().nullable()();
  // 目标总时长（毫秒）；0 表示由内容自然节奏决定，不做总量偏差校验。
  IntColumn get targetDurationMs => integer().withDefault(const Constant(0))();
  // 目标模型版本（'2.0' / '2.5'）；决定单段时长上限与批次容量的回落值。
  TextColumn get modelVersion => text().nullable()();
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
  // JSON 数组：[{speaker, type, text}]，type ∈ 对白/OS/VO。
  TextColumn get dialogue => text().withDefault(const Constant('[]'))();
  // JSON 对象：{ music: [...], sfx: [...] }。
  TextColumn get sound => text().withDefault(const Constant('{}'))();
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
  // JSON 数组：本段包含的节拍引用 E##。
  TextColumn get beatRefs => text().withDefault(const Constant('[]'))();
  // JSON 对象：{ characters: [...], scenes: [...], props: [...] } 的出镜状态。
  TextColumn get assetStates => text().withDefault(const Constant('{}'))();
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

/// 视频生成任务（异步提交 → 轮询 → 回填；taskId 持久化支持断点续跑）。
@DataClassName('VideoTask')
class VideoTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get shotId => integer().references(Shots, #id)();
  // 供应商返回的任务 ID。
  TextColumn get taskId => text()();
  // 供应商配置 id（恢复轮询时定位供应商与 Key）。
  TextColumn get providerId => text()();
  // 状态：排队 / 生成中 / 成功 / 失败。
  TextColumn get status =>
      text().withDefault(const Constant(VideoTaskStatuses.queued))();
  // 提交时的参数快照（模型/时长/画幅/分辨率/参考数），重试与详情展示用。
  TextColumn get paramsJson => text().withDefault(const Constant('{}'))();
  TextColumn get error => text().nullable()();
  // 成功任务的产物路径（媒体历史：保留每次生成，可回退选择）。
  TextColumn get outputPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
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
  // 供应商说明（借鉴 Toonflow provider readme，展示在设置卡片）。
  TextColumn get readme => text().nullable()();
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

/// 剧本版本快照：每次重新改编前保存旧内容，支持回溯。
@DataClassName('ScriptRevision')
class ScriptRevisions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get scriptId => integer().references(Scripts, #id)();
  IntColumn get version => integer()();
  TextColumn get content => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 镜头产物版本快照（M14 T16.6）：重新导演 / 重新生成分镜图 / 生成视频后，
/// 把当时的完整产物快照存档。`state` 只有 `current` 与 `superseded` 两态，
/// 同一镜头至多一条 `current`；实体的 `status` 字段承担「待验收 / 已采用」生命周期，
/// 快照表不重复建模。
@DataClassName('ShotRevision')
class ShotRevisions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get shotId => integer().references(Shots, #id)();
  IntColumn get revision => integer()();
  // current / superseded
  TextColumn get state => text().withDefault(const Constant('current'))();
  // 快照类型：direction / image / video。
  TextColumn get kind => text()();
  // 该镜头当时的完整产物（prompt / status / outputPath / 帧 / 参考绑定）。
  TextColumn get snapshot => text().withDefault(const Constant('{}'))();
  // 摘要，供列表页展示不必解包 snapshot。
  TextColumn get summary => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 资产产物版本快照（M14 T16.6）。语义同 ShotRevisions。
@DataClassName('AssetRevision')
class AssetRevisions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get assetId => integer().references(Assets, #id)();
  IntColumn get revision => integer()();
  // current / superseded
  TextColumn get state => text().withDefault(const Constant('current'))();
  // 快照类型：prompt / image / edit。
  TextColumn get kind => text()();
  // 该资产当时的完整产物（name / prompt / imagePath / appearanceAnchor / variantOf）。
  TextColumn get snapshot => text().withDefault(const Constant('{}'))();
  TextColumn get summary => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 生成尝试台账（M14 T16.5.4，对齐 Toonflow 8 列）：每次消耗算力的调用都落一行。
/// 提示词、参数、引用与授权在调用前写入，之后的编辑不回写这一行，
/// 因此可以事后查证「当时到底用的是什么提示词和参考图」。
@DataClassName('GenerationAttempt')
class GenerationAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  // 归属项目，便于全库备份与按项目清理。
  IntColumn get projectId => integer().nullable()();
  // 对象类型：novel_plan / novel_write / novel_review / novel_settle /
  // script_adapt / skeleton_extract / asset_extract / shot_image / shot_video。
  TextColumn get subjectType => text()();
  // 对象 id（生成前不存在的对象为 null）。
  IntColumn get subjectId => integer().nullable()();
  // 对象的可读名（如「第 3 章」「G02」「主角」）。
  TextColumn get subjectLabel => text().withDefault(const Constant(''))();
  // 本次实际使用的完整提示词（裁剪后）。
  TextColumn get prompt => text()();
  // JSON：{ model, providerName, temperature, maxToken, size, ... }。
  TextColumn get params => text().withDefault(const Constant('{}'))();
  // JSON 数组，按传入顺序：[{ assetId, name, role, variantOf }]。
  TextColumn get refs => text().withDefault(const Constant('[]'))();
  // JSON：调用前的对象状态快照（如镜头当前 status / outputPath）。
  TextColumn get before => text().withDefault(const Constant('{}'))();
  // 本次为对象的第几次尝试。
  IntColumn get attemptNo => integer().withDefault(const Constant(1))();
  // 授权范围：本次确认允许的最大执行次数（1 = 单个，N = 批量）。
  IntColumn get grantLimit => integer().withDefault(const Constant(1))();
  // 授权对象指纹（数量 / 提示词 / 模式 / 引用顺序的摘要），用于临执行复核比对。
  TextColumn get grantFingerprint => text().withDefault(const Constant(''))();
  // pending / running / succeeded / failed / cancelled。
  TextColumn get status => text().withDefault(const Constant('pending'))();
  // 实际落盘的文件路径（图片或视频）。
  TextColumn get resultPath => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
