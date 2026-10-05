# AGENTS.md

本文件是 AI 协作开发本项目的规范。所有参与本仓库开发的 AI Agent（含本会话）必须遵守。

---

## 1. 项目概述

一款 **Android APK 本地端**应用，整合「AI 写小说」与「小说 → 动漫」全流程：

```text
AI 写小说 → 小说改写动漫剧本 → 提取剧本骨架 → 生成动漫资产图片 → 生成动漫镜头
```

- 技术栈：**Flutter + Dart**（已确认，见 `docs/01`）。
- **不使用本地 AI 模型**，全部通过云端 AI API 端点（LLM 走 OpenAI 兼容协议，图片/视频走供应商异步任务 API）。
- 数据**本地存储**（SQLite + 应用私有目录），不上传云端服务器。
- 借鉴开源项目：Toonflow（剧本→镜头流程与 Skills）、InkOS（AI 写小说多 Agent 与 TruthFiles 权威状态机制）。
- 关键决策已全部确认（见 `docs/01` 第 7 节）：镜头产物 = 分镜图先行确认 + 视频生成；AI 写小说 = 人机协作（逐章确认）；里程碑 M0–M7 全量交付（含视频）。

详细设计见 `docs/`：

| 文档 | 内容 |
|---|---|
| `docs/01-项目概述与借鉴分析.md` | 定位、借鉴分析（对齐源码）、技术选型、已确认关键决策 |
| `docs/02-系统架构设计.md` | 分层架构、模块、数据模型、AI 接入、Pipeline |
| `docs/03-核心流程与Prompt设计.md` | 五大流程、Agent 职责、Prompt/Skill 规则 |
| `docs/04-开发计划与任务.md` | 里程碑 M0–M7 与任务拆解 |
| `docs/05-UI设计与手机适配.md` | 页面清单与线框、全局组件规范、状态徽章、手机适配原则 |

---

## 2. 核心开发原则（ACT 模式）

> 最好的代码是压根没写的代码。

动手写代码前，先停在第一个成立的台阶上：

1. 这东西真需要做吗？（YAGNI）
2. 仓库里已有现成工具/写法吗？有就复用，别重造。
3. 标准库/Dart SDK 能做吗？能做就用。
4. 已引入的依赖能解决吗？能就用。
5. 到这一步，才写能跑的最少代码。

**不省的事：** 搞懂问题、信任边界入参校验、防数据丢失的错误处理、安全（API Key、敏感数据）、以及用户明确点名要的东西。

**规则：**
- 没明确要的抽象不做；能不引新依赖就不引。
- 没人要的样板代码不写；删比加好，文件越少越好。
- 修 bug 修根因不修症状；改公共函数前 grep 所有调用方。
- 有意的简化用 `// ACT: ...` 注释标明已知上限和以后怎么升级。
- **只实现用户当前明确要求的内容**，不主动扩展功能、不加占位文案、不加示例数据。
- **按用户指定阶段推进**，完成当前要求并验证后停止，等下一步指令。

---

## 3. 代码风格（Flutter / Dart）

### 命名

| 类型 | 规范 | 示例 |
|---|---|---|
| 文件/目录 | `snake_case` | `novel_service.dart`、`truth_files/` |
| 类/枚举/类型 | `PascalCase` | `NovelService`、`AssetType` |
| 变量/函数/方法 | `lowerCamelCase` | `chapterCount`、`generateChapter()` |
| 常量 | `lowerCamelCase` 或 `SCREAMING_SNAKE_CASE`（仅纯字面量） | `defaultTimeout` |
| Widget 类 | `PascalCase`（类）+ snake_case 文件名 | `novel_editor_page.dart` 内 `NovelEditorPage` |

### 结构

- 遵循 Flutter 官方风格，用 `dart format` 格式化，每行不超过 100 字符。
- 优先使用 `const` 构造；Widget 拆分小而聚焦。
- 状态管理用 Riverpod：Provider 放 `providers/`，异步用 `FutureProvider`/`AsyncNotifier`。
- 数据层用 Drift，实体定义放 `data/tables/`，DAO 放 `data/daos/`。

### 目录约定（分层）

```text
lib/
  main.dart
  app.dart                      # 根 Widget + 路由
  core/                         # 通用：网络、存储、工具、常量
    network/                    # Dio 封装、SSE 流式解析
    storage/                    # 数据库、文件、安全存储
  features/                     # 按业务域分包
    project/                    # 项目列表
    novel/                      # AI 写小说（章节/设定工坊/TruthFiles）
    script/                     # 剧本
    skeleton/                   # 骨架（节拍/分段/出镜状态）
    asset/                      # 资产图片
    shot/                       # 分镜/镜头（分镜图 + 视频模板）
    pipeline/                   # 阶段编排
    task/                       # 任务中心（生成任务队列 UI）
    settings/                   # 设置（技能管理/备份）
    provider_config/            # 模型供应商配置
  widgets/                      # 全局组件（确认 Sheet/提案卡/状态徽章等，见 docs/05）
  data/                         # 共享数据层（表、DAO、Repository）
  domain/                       # 领域模型（如与表模型分层）
  agent/                        # Agent 定义与 Skill 加载
  skills/                       # 内置 Prompt/Skill 资源（assets 打包）
```

### UI 实现规范

- 页面清单、线框与导航按 `docs/05` 落地；三 Tab 全局导航，项目内以五阶段步骤条为流程导航。
- 全局组件复用 `widgets/`：生成确认 Sheet（固定方案 → 授权 → 临执行复核）、AI 提案卡、状态徽章、空/载/错三态。
- 深色主题优先（Material 3 seed），主操作沉底；页面细节以 `docs/05` 为准。

---

## 4. AI 接入约定

- LLM 统一走 OpenAI 兼容 `/v1/chat/completions` + SSE 流式；**不要在业务代码里硬编码某家 SDK**，统一经 `core/network/` 的 `LlmProviderAdapter`。
- 图片/视频生成走 `ImageProviderAdapter` / `VideoProviderAdapter`，异步任务统一进**生成任务队列**。
- 视频协议由 `ProviderConfig.protocol` 字段路由：
  - `async-task`（默认）：`POST {base}/video/generateVideo` + `POST {base}/video/getVideoStatus`，借鉴 Toonflow Seedance 三步流。
  - `openai-videos`（Agnes AI）：`POST {base}/videos` + `GET {host}/agnesapi?video_id=&model_name=`（轮询端点在 host 根路径，去掉 `/v1` 前缀）。
  - 新增协议时在 `VideoProviderAdapter` 按 protocol 分支实现，`ShotService` 透传 `protocol` + `model`。
- 供应商配置（Base URL / API Key / 模型）由用户配置，存安全存储，**API Key 严禁落明文 DB、严禁打印日志**。
- 一键预设：`AgnesPresets`（`lib/features/provider_config/agnes_presets.dart`）可一键创建 Agnes AI 的 LLM/图片/视频 3 个供应商条目（协议分别为 `openai-chat` / `openai-images` / `openai-videos`），Base URL 固定 `https://apihub.agnes-ai.cn/v1`。
- Agent 系统提示词从 `skills/` 资源加载，与业务代码分离；修改 Prompt 不触碰业务逻辑。

### 图片生成与风格约定（M15）

- **临时故障自动重试**：`ImageProviderAdapter._withRetry` 只对 `408/429/500/502/503/504` 与网络超时重发（默认 2 次，指数退避 2/4 秒，尊重供应商 `Retry-After` 并夹在 1–30 秒），4xx 参数错误立刻失败——重试只会白烧算力。每次重发前检查 `CancelToken`，取消不会被重试吞掉。
- **错误必须走 `ImageGenerationException`**：`toString()` 即中文原因（状态码 + 归类 + 供应商消息截 300 字 + 已重试次数）。禁止把裸 `DioException` `$e` 吐给用户或写进台账——503 的响应体常带 base64 片段和超长英文堆栈。
- **尺寸透传**：`ActiveImage.imageSize` 取该供应商已勾选模型的 `imageSizes` 第一项（无声明回落 `1024x1024`），`ShotService` / `AssetService` 生成时一律传 `size: image.imageSize`。供应商声明的尺寸档位（如 Agnes `1K/2K/3K/4K`）与像素值都合法，不要写死像素串。请求体只发 `model/prompt/n/size/response_format`，不要夹带 `stream`/`format`/`images`。
- **单一风格字段**：图片与视频共用 `Scripts.artStyle`，未设置或空白时经 `script_models.dart` 的 `defaultArtStyle` / `effectiveArtStyle` 回落默认值，**禁止在业务代码里再写一份字面量**。编辑入口在剧本详情页「画面风格」，保存后资产图与视频提示词统一按新风格执行。
- **资产提示词按模板生成**：`assets/skills/asset/asset_design.md` 给出角色四视图 / 场景主视图 / 道具 2x2 三套逐字模板与负向约束，LLM 只替换占位符，不自创散文；变体复用父资产模板 + `AssetService.variantPromptSuffix`，提示词里不写引用标记（父资产图由 App 自动上传）。
- **变体提示词常量单一来源**：`AssetService.variantPromptSuffix` 同时用于落库与确认框 `promptPreview`，改文案只改这一处。

### 集与时长预算约定（M16）

- **一集 = 剧本表一行**：分集不加新表，`Scripts.episodeNo` / `targetDurationMs` / `modelVersion` 三列承载集元数据（schema v9）。`episodeNo` 空表示不参与分集；`targetDurationMs` 为 0 表示由内容自然节奏决定，此时跳过总量偏差校验。
- **单段时长上限三级回落**：选中视频模型的 `ProviderModel.supportedDurations` 最大值 → 剧本 `modelVersion`（`2.0` = 15000ms / `2.5` = 30000ms）→ 通用默认 15000ms。禁止在业务代码里写死 `'15s'` / `'30s'` 字面量。
- **分段预算只走 `SegmentBudget`**：`lib/features/shot/segment_budget.dart` 是时长与容量校验的唯一入口，纯函数、不写库。`maxSegmentMs` / `maxBatchSegments`（2.0 = 6 段 / 2.5 = 3 段）/ `theoreticalMinSegments`（`⌈目标/上限⌉`，只作下限提示）/ `validate()`。别的服务需要判定时长合法性必须调它，不自算。
- **五条校验码稳定不变**：`over_limit` / `dialogue_overflow`（error）、`total_mismatch` / `too_few_segments` / `batch_too_large`（warn）。新增校验码先在本约定里登记再实现。`dialogue_overflow` 用 `beatRefs` 回溯 `Beats.estDurationMs` 求和，与 A3.2 对白硬门槛对齐——禁止靠快语速解决，禁止删词改词。
- **10% 呼吸余量**：`mergeBudgetMs = maxSegmentMs × 0.9` 是合并节拍时的预算上限，`maxSegmentMs` 是生成时长硬上限；两个数字都透传给提取 prompt（`skeleton_service.extract`），避免自然朗读时间被压缩到必须靠异常快语速完成。
- **error 阻塞视频提交，不阻塞骨架提取**：`ShotService.submitVideo` 在临执行复核前跑 `validate`，`error` 项写入 `ConfirmSheet` 的 `note`，用户明确确认后放行；`warn` 项只提示。提取是生成前动作，允许带冲突落库后由用户调整。
- **A7 衔接与时长预算是两个独立面板**：`ShotService.listTransitionIssues` 负责画面区分度（主体相同且景别差 <2 档且角度差 <90°），`SegmentBudget.validate` 负责时长与容量。都只提示不改数据，UI 上并列展示，不合并成一条。

### 产物可回溯约定（M17）

- **产物文件必须唯一命名，禁止覆盖写**：`AssetFileStore` / `ShotFileStore` / `VideoFileStore` 的 `save` 与 `saveFromPath` 一律写 `前缀_${id}_${时间戳}.扩展名`。同名覆盖会让 `ShotRevisions` / `AssetRevisions` / `VideoTasks.outputPath` 里的历史路径全部指向同一个文件，「历史版本切换」形同虚设——这是 M14 版本快照与 M8 视频多任务的失效根因。历史文件不主动清理，随对象删除走既有 `delete`。
- **历史版本数据源固定**：视频历史走 `VideoTasks`（每次成功任务一条，`outputPath` 指向独立文件）；分镜图与资产图历史走 `ShotRevisions` / `AssetRevisions` 里 `kind == 'image'` 的快照，快照 JSON 含 `imagePath`。切换版本 = 把对象当前指针改回快照里的路径并补写一条快照，不重建对象。
- **本地替换图片先查长度再复制**：与视频侧 `replaceVideo` 一致，先 `File.length()` 判 100MB 上限再 `copy`，禁止先 `readAsBytes()` 再判大小（超大文件会全量载入内存）。`Assets` / `Shots` 的图片侧 store 都需要 `saveFromPath`，路径由服务内部生成，不接收外部文件名。
- **生成台账只读不写**：`GenerationAttempts` 由 `AttemptRecorder` 写入，台账查看页只读。回写只允许 `status` / `resultPath` / `errorMessage` / `subjectId` / `subjectLabel` / `projectId` 六列，**绝不回写提示词、参数、引用、授权指纹**——那是当次执行的证据。
- **章节字数门槛只提示不阻塞**：`ChapterWordGate` 是目标字数校验的唯一入口（`lib/features/novel/chapter_word_gate.dart`，纯函数、不写库），下限 `0.8 × targetWords`、上限 `1.3 × targetWords`，常量单一来源，禁止在 UI 里再写字面量。`NovelBooks.targetWords` 为空或 0 时跳过校验。定稿前不达标弹确认提示，用户可放行。
- **审校 `scope` 三值**：`local` / `structural` / `unknown`。`unknown` 表示问题需要更大范围判断才能定位，UI 展示独立 Chip，不落到 `local` 分支。新增取值先在 `review.md` 与 `ReviewIssue` 登记。

### 数据与备份约定（M11 P2 追加）

- 全库备份：`BackupService.exportAll()` 导出所有项目为单 zip（`scope: full`），`importProject` 兼容全库包与单项目包；导入前经 `findConflicts` 做同名项目检测，冲突时弹窗确认。
- 章节导入/导出：章节编辑器支持导出 Markdown / HTML；书架页支持导入 `.md/.html/.txt` 为草稿章节（H1 提取标题，HTML 剥标签）。

### P3 功能追加（M12 P3）

- 多 Agent 协作写章（P3-13）：`NovelService.planChapter()` 先调 Planner Agent 生成本章规划（目标/关键事件/结尾变化/伏笔操作），再将规划注入 `writeChapter` 的 prompt；章节编辑器底部工具栏提供「规划后写」按钮，Writer 按 Planner 产出严格写正文，而非自由发挥。规划 Skill 文件：`assets/skills/novel/chapter_planning.md`。
- 多作品类型（P3-15）：`NovelBooks` 表新增 `workType` 字段（默认「长篇」，可选「长篇/短篇/剧本/影游」），schema 升级到 v6；创建作品对话框提供类型下拉，非默认类型在书架页以徽章展示；`generateSetup` 将 workType 注入 Planner prompt。
- 伏笔池管理（P3-14）：`hook_manager_page.dart` 独立页面（路由 `/novel/:projectId/hooks`），支持新增/编辑/回收/删除伏笔条目；书架页「伏笔」按钮 + 设定工坊「管理」卡片为入口；数据存 `hooks` TruthFile，与 Settler 定稿共用。

### 健壮性约定（M13）

- **宽容 JSON 解析**：解析 AI 输出 / 落库 JSON 一律走 `lib/core/json_values.dart` 的 `jsonString` / `jsonStringOrNull` / `jsonInt` / `jsonBool` / `jsonList` / `jsonMap`，**禁止对外部数据直接 `as` 强转**（LLM 常把数字写成字符串、布尔写成 `"true"`，强转会抛 TypeError 让整段生成结果解析失败）。Agent 剥 JSON 包裹统一用同文件的 `extractJsonObject(reply)`：支持 ```` ```json ```` 代码块与前后解释文字；解析失败必须抛 `FormatException`，禁止返回空 Map（空结果会让上游删旧数据后插入零条，造成静默数据丢失）。
- **网络层**：供应商响应先做 `is List` / `is Map` 类型守卫再取字段；SSE 用 `utf8.decode(bytes, allowMalformed: true)`；错误提示截断按实际长度判断，勿直接 `substring(0, N)`。
- **列表页加载**：异步数据在 `initState` 加载一次 + `_loading`/`_error`/`_reload` 状态；禁止 `build` 里 `FutureBuilder(future: _load())`。
- **await 后 Toast**：任何 `_toast` 类方法必须首行 `if (!mounted) return;`，长耗时 AI 调用期间用户可能已离开页面（"Looking up a deactivated widget's ancestor is unsafe"）。同理，弹窗 / 导航 / Controller 持有也需检查。
- **压缩包导入**：解压条目名一律经 `BackupService._resolveMediaPath` 解析——拒绝绝对路径、`..`/`.`/空段，并校验解析后绝对路径前缀（防 zip slip 越界写文件）。任何接收用户提供的 zip/文件名并落盘的路径都必须做同等校验。
- **APK 体积**：`build.gradle.kts` 的 `defaultConfig` 用 `ndk.abiFilters = ["arm64-v8a"]` 只打单 ABI，FFmpeg 用 `ffmpeg_kit_flutter_new_min_gpl`；CI 构建命令带 `-P disable-abi-filtering=true`，产物为 `app-{release,debug}.apk`。**不要用 `splits.abi`**：Flutter Gradle 插件在未传 `-P split-per-abi` 时会把 `armeabi-v7a/arm64-v8a/x86_64` 写进 `defaultConfig.ndk.abiFilters`，与 `splits.abi` 互斥，Gradle configure 阶段直接报 `Conflicting configuration` 使 CI 构建失败。

 ### 数据完整性、上下文预算与执行约定（M14，已完成）

  > M14 任务清单见 `docs/04` 第 8.y 节（T16.1–T16.9），架构约定见 `docs/02` 6.5–6.9，
  > 全量复研结论见 `docs/01` 第 8 节。**M13 全量扫描未覆盖以下问题，动手前先读这三处。**
  >
  > **落地位置（新增代码必须对齐，不得另起一套）**：
  > - 事务化与级联删除：`lib/data/daos/cascade_dao.dart` 的 `CascadeDao`。新增删除或重建路径必须走它。
  > - 文本导入与字数：`lib/core/text/chapter_import.dart` 的 `ChapterImport`（大小上限 / 编码探测 / HTML 清洗 / 标题提取 / 字数）。
  > - 上下文预算：`lib/features/novel/context_budget.dart` 的 `ContextBudget`（token 估算 / TruthFile 裁剪 / 原文切片）；`ActiveLlm` 暴露 `contextTokens` / `budgetTokens`。所有 LLM 调用点必须传入预算。
  > - 统一确认：`lib/widgets/confirm_sheet.dart` 的 `ConfirmSheet`（`.confirm` 决定是否弹框，`.show` 渲染七项，主按钮两阶段实现临执行复核，`gate` 参数写清阶段门）。所有消耗算力的入口必须走它。
  > - 状态徽章：`lib/widgets/status_badge.dart` 的 `StatusBadge` + `StatusKinds`（单一状态表）。
  > - 协议常量：`lib/core/network/protocols.dart` 的 `Protocols`（`require` 未知协议抛错）。
  > - 产物版本快照：`lib/data/daos/revision_dao.dart` 的 `RevisionDao`（`ShotRevisions` / `AssetRevisions`，`state` 只 `current` / `superseded` 两态，同一对象同 kind 至多一条 `current`）。重新导演 / 出图 / 换视频必须存快照。
  > - 生成尝试台账：`lib/data/daos/generation_attempt_dao.dart` 的 `GenerationAttemptDao` + `AttemptRecorder`（对象类型走 `AttemptSubjects` 常量）。生成前写 `prompt` / `params` / `refs` / `before` 快照，`finish` 只回写 `status` / `resultPath` / `errorMessage`，**绝不回写提示词与参数**。所有 AI 入口必须登记。
  > - TruthFile 乐观锁：`TruthFileStore.write(kind, content, {int? expectedRevision})`。读改写路径（Settler 固化五个 `_applyX`）必须传 `expectedRevision`，不匹配抛 `ConcurrentWriteConflict` 而非静默覆盖；`readRow` 取含 revision 的行。
  > - Hook 状态机：`HookStates`（`open` / `progressing` / `deferred` / `resolved` / `superseded` + `transitions` 表 + `allows`）。`_applyHooks` 校验转移，非法转移不阻塞固化而是记入 `rejectedTransitions`。
  > - 变体父校验：`AssetDao.insert` / `updateById` 校验 `variantOf` 存在且同 `scriptId`，`deleteById` 先解绑子变体再删。
  > - 测试：`test/import_and_protocols_test.dart`、`test/context_budget_test.dart`、`test/revision_and_attempt_test.dart`（快照 / 台账 / 乐观锁 / HookStates / variantOf / 级联）。
  > - 结构化审校：`lib/features/novel/novel_models.dart` 的 `ReviewIssue`（`code` 稳定机器码 / `quote` 正文原样引用 / `handling` 处置建议）+ `ReviewIssue.verifyQuotes`。审校产出一律经本地正文重新裁切引用（精确匹配 → 忽略空白 → 前缀降级），**不采信 LLM 自报的位置与引文**；未命中标 `quoteVerified = false` 但保留条目，不删除、不阻塞其它问题呈现。定位按点击时正文重新裁切，不沿用审校时偏移。
  > - 死字段清理：`Scripts.aspectRatio` / `Scripts.language` 已删（schema v8，`onUpgrade` 走 `m.dropColumn`）。两列从无读取方，`aspectRatio` 从未进入图片或视频生成（合成固定 1280x720）。新增供应商能力透传需按 `size` 参数映射，另行规划。
  >
  > **测试**：`test/novel_service_test.dart` 覆盖 `verifyQuotes` 五例（精确 / 忽略空白 / 伪造 / 过短 / 前缀降级），`test/daos_test.dart` 覆盖 schema v8 与剧本表列集。

- **多表写必须事务化**：全库当前仅 `backup_service.dart:337` 一处 `transaction`，五个 service 的多表写全部裸写，中间态（JSON 解码抛错、磁盘满、进程被杀）永久落库且无回滚。DAO 层提供「按父 id 重建」复合方法并内置事务，业务层不直接拼 `deleteByX` + 多次 `insert`。
- **删除顺序最下游先行**：`VideoTasks → AssetRefs → ShotFrames → Shots → Beats → Scenes`。`skeleton_service.dart:69-70` 先删 Beats 再删 Shots 违反此序，任一镜头有下游数据时删除抛冲突而 Beats 已不可恢复。
- **写顺序先删后改**：`script_service.dart:110-118` 先 `updateRow` 写新正文再删场次，失败后正文新版 + 场次旧版错位。凡「父行更新 + 子表重建」一律先完成删除插入、成功后再更新父行版本。
- **删除入口必须级联**：`project_dao.dart:40` 裸 delete 且 `tables.dart` 15 处 `references()` 全无 `onDelete`（Drift 默认 `NO ACTION`），删除任何创建过书籍的项目必然抛 `FOREIGN KEY constraint failed`。统一走 `deleteProjectCascade`，表定义显式 `KeyAction.cascade` + 迁移。
- **LLM 上下文必须预算内构造**：现状全量拼接、`model_presets.dart` 的 `maxToken` 零使用方。统一走 `ContextBudget`；TruthFile 标 `protection: protected | compressible`（用户意图/角色锁/规则永不压缩），裁剪按「伏笔只留 open、摘要只留近 N 章、角色只留本章出场」执行，被裁条目写入台账供查证。
- **确认与执行分离**：统一 `ConfirmSheet`（对象/数量/完整提示词/参数/参考文件与用途顺序/执行次数/费用，费用不可查时明确「未知」）；授权后提交前重读数据比对，节点/提示词/模式/引用/数量任一变化则差异高亮重新授权。生成前保存提示词、参数、引用与授权快照，后续编辑不回写这次尝试。阶段门纪律：确认简报 ≠ 确认剧本 ≠ 确认资产 ≠ 验收生成结果，允许小样 ≠ 允许批量生产。
- **取消需透传 Dio**：`GenerationCancelToken` 包装为 `dio.CancellationToken` 并透传适配器，每个 await 之后检查，不只判 for 循环顶部。
- **轮询需 per-task 超时且去重锁下沉**：`task_page.dart:111-125` 的全局 `_polling` + 串行 await，任一请求半连接不返回则全局永久停刷。超时下沉到 `pollVideoTask` 内部按 taskId 串行化。
- **状态需僵尸检测**：`shot_service.dart:616-628` 对网络异常保持「生成中」无最大时长，供应商删任务后永久挂起。`updatedAt` 超阈值自动置失败；供应商配置变更后在途任务置失败。
- **状态常量需统一且覆盖全枚举**：`task_page.dart:380-399` 的 `_TaskBadge` 只识别 8 个状态中的 2 个，6 个落灰色 default 使「已完成」与「排队中」外观一致。抽统一 `StatusBadge` + 单一状态常量类。状态迁移需幂等：`shot_service.dart:147-154` 重新导演无条件写 `awaitingImage` 会把已出视频镜头降级，对应视频任务仍「已完成」。
- **文件校验需在读取前**：`shot_service.dart:721-722` 先 `readAsBytes()` 再判 100MB，超大文件先全量载入内存致 OOM（本机环境 358 MiB）。任何「读整个文件再校验」改为先 `File.length()` 或流式分块。
- **用户文本不得拼进命令串**：`shot_compose_service.dart:52` 把剧本标题（`script_detail_page.dart:247`）拼进 FFmpeg 命令串，标题含 `"` 时输出路径可控。文件名白名单过滤 `[^\w\-]` → `_`，输出路径由服务内部生成，用 `executeWithArguments` 数组传参。同步长任务用 `FFmpegSession` + 进度回调 + `cancelExecution` + `Isolate.run`；`apad` 必须带 `whole_dur`（默认无限补静音致成片尾部黑帧）；成功后删临时文件。
 - **协议常量需统一枚举**：`agnes_presets.dart` 的 `openai-chat` / `openai-images` / `openai-videos` 与适配器实际分支不一致，LLM 侧 `protocol` 是死字段，图片/视频侧不匹配会静默落到默认分支。统一枚举 + 适配器显式分支 + 未知协议抛错，不得静默降级。

### 可靠性接线约定（M18，阻断级已完成）

  > 审计与任务清单见 `docs/06-全量审计报告.md` 与 `docs/04` §8.bb M18。
  > M18 的核心教训：**M17 交付的产物可回溯在分镜链路一行未执行**——
  > `revisionDao` / `attemptDao` 是可选构造参数 + 内部 `if (dao == null) return`
  > + 五处 `catch (_) {}` 无日志，三道防线同时失效而 231 例测试全绿。
  > 根因是「可靠性能力」被写成了「可选增强」，编译期没有防线。

  - **可靠性依赖必须 `required`**：`ShotService` / `AssetService` / `NovelService` /
    `ScriptService` / `SkeletonService` 的 `revisionDao` / `attemptDao` 一律 `required`，
    字段无 `?`，内部不再判空短路。改依赖顺序不可反：**先把参数改 `required`
    再补 provider 注入**，让编译期强制暴露所有漏注入点——这正是当初分镜链路漏掉
    `revisionDao` / `attemptDao` 而无人发现的原因。
  - **台账项目归属由 bookId 解析，不由调用点传**：`GenerationAttemptDao.projectOfBook`
    是唯一解析入口，`AttemptRecorder.start` 只收 `bookId`。`finishAttempt`
    不接受 `projectId`——台账写入只发生一次，事后回写会造成「项目迁移后台账失联」。
    新增登记点必须走 `bookId`，禁止自己拼 bookId → projectId。
  - **静默 catch 一律留痕不阻塞**：辅助能力（快照、台账）失败不阻塞主流程，但必须
    走 `lib/core/app_log.dart` 的 `appLog(tag, message, {error, stackTrace})`
    （`dart:developer.log` level 900，release 也输出到 logcat，消息截断 300 字符）。
    禁止裸 `catch (_) {}`——那是把可靠性功能降级成装饰性功能。
    `appLog` 只记 tag + 异常类型 + 截断消息，**禁止传提示词、正文、API Key**。
  - **Settler 固化必须整段事务化**：`TruthFileStore.applyDelta` 包
    `attachedDatabase.transaction`，五类 `_applyX` 与 authorIntent / currentFocus 同处一个
    事务；中途抛错（非法状态转移、并发写冲突、内容损坏）整段回滚。
    除 revision 外 TruthFile 无「定稿完成」痕迹，半套固化会让下一章写作基于残缺真相继续跑。
  - **TruthFile 写入一律带锁**：`write(kind, content, {expectedRevision})` 的所有调用点
    必须传 `expectedRevision`（读同一行后再写）。新增写入口先取 `readRow(kind)` 再写，
    禁止绕过 `expectedRevision` 的裸 `write`。
  - **LLM 输出状态值一律归一化再判**：`HookStates` 校验路径统一
    `(v?.toString() ?? '').trim()`，禁止 `as String`。LLM 回 `{"status":1}` 时强转抛
    `TypeError` 会吞掉整轮固化（facts / characters / resources / summary 全部不落库）；
    归一化后非法值进 `HookStates.allows` 判定，被拒转移记入 `rejectedTransitions`，不阻塞其余固化。
  - **`deleteAssetCascade` 必须删 `assetRevisions`**：该表有指向 `Assets` 的外键，
    库已开 `PRAGMA foreign_keys = ON`；只删 `assets` 会让任何出过图的资产删除直接抛
    `FOREIGN KEY constraint failed`。删除顺序照 `CascadeDao` 文件头注释的拓扑序。
  - **备份包必须流式解析，禁止 `decodeBytes` 全量驻留**：`BackupService._openArchive`
    用 `ZipDecoder().decodeStream(InputFileStream)` 只解析中央目录、条目内容按需解压，
    用完 `archive.clearSync()`。PNG/MP4 几乎不可压缩，压缩包大小 ≈ 解压后大小，
    旧的 `readAsBytes` + `decodeBytes` 让两份全量字节同时驻留，500MB 包在
    358MiB 预算上是必然 OOM。
  - **解压前双重校验**：`maxImportBytes`（包体 500MB）与 `maxExtractedBytes`
    （解压后 2GB）两个常量单一来源。`_guardExtractedSize` 按中央目录声明的
    `ArchiveFile.size` 累加判断，校验必须在写出任何文件之前完成——否则 zip bomb
    已经落盘才报错，用户看到的是几个 GB 的垃圾文件。
  - **`backup.json` 走宽容解析**：`_decodeBackupJson` 统一把非法 UTF-8 / 非法 JSON /
    顶层非对象都收敛成 `FormatException('备份包已损坏：…')`，UI 层只需处理一种异常。
    用户提供的包任何脏数据都不该以未捕获异常结束。

  - **Manifest 必须自带 `INTERNET` 权限**：`android/app/src/main/AndroidManifest.xml`
    的 `uses-permission` 不能只存在于 `src/debug/` 与 `src/profile/`——Release 构建的
    manifest merger 拿不到 debug 变体，联网权限会整段丢失。改 manifest 后必须
    确认 release 产物也能联网。

### 网络、状态与校验约定（M18-B，严重级）

  - **Dio 只从 `createDio()` 造**：`lib/core/network/dio_factory.dart` 是唯一基线，
    `defaultConnectTimeout = Duration(seconds: 15)`。Dio 的 `connectTimeout` 默认
    为 0（禁用），`sendTimeout` / `receiveTimeout` 从 TCP+TLS 握手完成之后才计时，
    弱网半连接下请求会无限期挂起而 per-request 超时不生效。新增网络调用点一律
    `createDio()`，禁止再写裸 `Dio()`——那样迟早会漏掉新的调用点。per-request 的
    `sendTimeout` / `receiveTimeout` 可以继续覆盖，但不得覆盖 `connectTimeout`。
  - **视频任务取消要真正中断请求**：`ShotService` 按 `taskId` 持有
    `GenerationCancelToken`（`_videoCancelTokens`），`submitVideo` / `pollVideoTask`
    全程透传 dio `CancelToken`，`VideoProviderAdapter` 每个 `await` 后走静态
    `_throwIfCancelled`。`cancelVideoTask` 必须**先** `cancel()` **再**写库状态——
    顺序反了的话 Dio 请求会一直挂着直到 5 分钟 `receiveTimeout`。
    `GenerationCancelToken` 留在 features 层（`shot_service.dart`），适配器只收
    dio 的 `CancelToken`，由 service 传 `cancelToken?.dioToken` 桥接，
    core/network 不得反向 import features。
  - **卡死状态按「状态本身是否瞬态」判断，不按 updatedAt 超时**：资产出图是
    同步调用（`AssetService.generate` 内 `await` 到底），`生成中` 只存在于一调用
    生命周期内，所以库里出现的每一条都意味着进程中途被杀，一律改回 `待生成`
    （`AssetDao.flipStatus`，资产页 `initState` 触发）。视频任务相反——生成是
    供应商侧异步任务，中途有真实进度，仍按 `updatedAt` 超时判僵尸。
    DAO 不绑定状态词表，状态值由调用方传入。
  - **状态常量放 core，不放 features**：`lib/core/status_constants.dart` 的
    `VideoTaskStatuses`（含 `inProgress` / `terminal` 列表）是唯一来源，
    `tables.dart` 列默认值、DAO 查询、service 写入、UI 判断、`StatusKinds` 五处
    必须同源——data 层不能反向 import features，所以这类跨层共享的状态表一律
    放 core。新增状态词表照此办理，禁止在业务代码里写字面量。
  - **外部 JSON 解析必须容错且保留「未知」语义**：`jsonIntOrNull` 把不可解析
    收敛为 `null` 而不是 0（0 表示「明确没有」，两者含义相反）；列表型能力字段
    过滤后为空同样视为 `null`，空列表会让 UI 把「能力未知」当成「明确没有」。
    `ProviderModelCodec.decode` 逐条 try/catch，单条损坏只丢自己——整组包在
    一个 try 里，一次 `TypeError` 会让三个 `ActiveX` provider 全部失效，
    用户看到「请配置供应商」而它是配置好的、开着 Key 的。
  - **Base URL 必须 https**：`validateBaseUrl`（`provider_edit_sheet.dart`）要求
    https，本机回环（localhost / 127.0.0.1 / ::1）放行以支持本地调试。
    明文 http 会让 Bearer API Key 在链路上被截走。新增接受 URL 的输入框复用此函数。
  - **检查更新必须手动触发**：`provider_config_page.dart` 用 `Notifier` + sealed
    `UpdateCheckStatus`（Idle / Loading / Done / Unavailable），build 阶段不发
    网络请求，用户点「检查更新」才拉取。禁止改回 `AsyncNotifier` + `ref.watch`——
    那会把自动拉取写死进依赖图。离线/无网给可读原因，不返回占位版本号冒充
    「已是最新」。
  - **T20.10（FK 级联）已决策推迟**：drift 2.35.1 没有 `migrateTables`，
    16 处 `references()` 补 `KeyAction.cascade` 需手写 15 张表的表重建 SQL，
    且本环境无模拟器，`if (from < 11)` 迁移分支不会被任何测试覆盖。
    当前所有删除路径都已走 `CascadeDao`，表定义层缺兜底不构成缺陷，
    而生产存量数据迁错不可恢复。前置条件：升级带 `migrateTables` 的 drift，
     且具备模拟器或存量样本库后再做。禁止在验证条件不满足时提交表重建迁移。

### 本地质量门与提示词约定（M19）

  > 复研依据见 `docs/01` §11（GitHub 外部对标：shuohao-skills / AIComicBuilder /
  > goink），任务清单见 `docs/04` §8.cc M19。
  > 核心原则沿用它的一句话：**能检查的东西全部落到代码里，不靠提示词碰运气**——
  > 本地机械校验放在消耗算力之前拦下，比写进 prompt 靠模型自觉可靠得多。

  - **质量门一律走 `ChapterWordGate` / `SegmentBudget` 范式**：纯函数、不写库、
    常量单一来源、返回结构化结果、UI 只提示不阻塞。门 id / `code` 是稳定机器码，
    是日志与下游对账的凭据，**稳定不动**；新增校验码先在本文档登记再实现（对齐
    既有五条校验码约定）。禁止为了让测试通过而调阈值——阈值要有实测依据，改之前
    先记录实测值。
  - **缺字段的旧数据照常通过，门明说跳过而不报错**：新增值类型（`variantOf`、
    集时长预算、结构化镜头字段等）时，不存在的字段走「跳过」分支并在结果里标记
    `skipped`，不能报错——否则每一份额量升级前的存量数据一次升级就全红。
   - **角色提示词雷同门只查描述性字段**：Jaccard 阈值 0.75，双方词元数 < 6 返回 0
     （短语级比较无意义）。**CJK 必须逐字切词元**，字母数字连续串算一个词元——
     中文没有词边界，整段提示词按 `[^a-z]+` 切只会得到五六个长串，词集合没有
     区分度，门永远不响（实测：5 字段外观锚点按长串切只得 5 个词元，低于阈值）。
     对比对象是 `appearanceAnchor` 的 JSON 值，**不是全量 prompt**——四视图排版
     模板是大段固定文本，真实角色之间本来就有 80% 以上重合，查全量 prompt 会全红。
     量测依据：区分良好的角色约 0.1，仅改年龄与一个手别描述的近克隆约 0.80。
   - **时长估算与切段预算是两件事**：`DurationGate` 负责「写完剧本就知道这集会
     超时多少」（对白按字符数 ÷ 语速 4.5 + 非对白节拍回落 2.5 秒，去空白、
     标点算时间，总量容差 ±15%），`SegmentBudget` 负责按目标时长切段与容量
     校验。两者不合并、不互相调用私有实现。对白节拍一律按字符折算，**不采信
     `Beats.estDurationMs`**——那是 LLM 自己填的粗估，长句超时正源于此。
   - **空景与画风的反向校验由门负责，不靠模型自觉**：场景 / 道具提示词须含
     空景标记（`empty scene` / `no people` / `无人物` / `无人` 任一），道具另须
     含手部排除标记（`手部` / `无手` / `hands` / `fingers` 任一）——最常见的
     道具污染是一只握着道具的手。`Assets` 表**没有 `negativePrompt` 列**，负向
     约束以中文内联写在 `prompt` 里，所以门只能扫 `prompt` 文本。场景提示词出现
     本项目角色名即报警（图像模型会把它认识的东西画进去），命中前先看否定语境
     窗口，「不能出现佐藤」不算报警。**画风门是互斥族校验，不是「出现画风词
     就报警」**：`effectiveArtStyle` 会把画风写进每个资产的 prompt，正常全批同族；
     只有跨族（写实 / 动漫 / 三维 三族之一同时出现两个）才报警。`Beats` / `Shots`
     正文不查角色名，正文本来就该出现角色名。
   - **实测提示词规则只进 `assets/skills/`，不进业务代码**：角色参考图与分镜的
     提示词写法（几何化正面、一致性清单按视图取层、不链式参考、多人同框不用拼接
     参考图、细节图补年龄、写光的效果不写光源、视频侧不写角色姓名而分镜图侧相反
     要直呼其名、构图量化字段、视角写法、时代与材质等）全部落在 skill prompt 里。
     业务代码只负责拼接、落库、校验，不复述提示词规则。
   - **体检模式一律只读不改**：`listTransitionIssues` / 骨架源剧情账本校验 /
     `GateIssueList` 面板都只提示，不自动修数据，不改库。修数据必须走
     显式用户动作 + `ConfirmSheet`。
    - **本地校验失败要留痕，且留痕必须由用户显式触发**：走 `AttemptRecorder` +
      `GenerationAttempts` 既有表结构，`subjectType = AttemptSubjects.validate`
      （`data/daos/generation_attempt_dao.dart`），摘要写 `prompt`、门名与逐条
      问题写 `params`，有 error 级问题时状态记 `failed`。门在 `build()` 里跑，
      **禁止自动落库**——否则每次重绘写一条，台账被刷爆；只允许经
      `GateIssueList` 的「记一次」按钮显式触发。写入失败只
      `appLog('gate_record', …)` 并返回 false，不阻塞。
    - **M19 校验码登记表**（新增校验码先登记再实现，对齐既有五条 `SegmentBudget`
     校验码约定）：
     - `DurationGate`（`lib/features/script/duration_gate.dart`）：
       `line_too_long`（error，单句台词 > 35 字，一口说不完）、
       `total_over_budget` / `total_under_budget`（warn，节拍自然时长与
       `Scripts.targetDurationMs` 偏差 > 15%；目标为 0 时跳过）。
     - `PromptGate`（`lib/features/asset/prompt_gate.dart`）：
       `prompt_similar`（warn，两个角色外观锚点 Jaccard >= 0.75）、
       `scene_not_empty`（error，场景 / 道具提示词无空景标记）、
       `prop_has_hand`（error，道具提示词无手部排除标记）、
       `scene_named_character`（warn，场景提示词出现角色名）、
       `style_conflict`（warn，同批资产跨画风族）。
     - `CostumeGate`（`lib/features/shot/costume_gate.dart`，镜头级服装覆盖）：
       `costume_unknown`（warn，覆盖套名不在该资产 `costumeSets` 清单里，
       模型自创套名会让分镜图画出资产图里没有的第四套衣服）、
       `costume_orphan`（warn，覆盖的角色不在本镜头 `AssetRefs` 里，条目无效）、
       `costume_duplicate`（warn，同一镜头同一角色给了多套服装，无法判定穿哪套）。
       三条全 warn：门能指出问题所在，但改数据要用户显式动作（改覆盖或重导）。
      - 统一结果类型 `GateIssue` / `GateSeverity` 在 `lib/core/gate_issue.dart`，
        `noteLine` 给确认框 `note` 用；与 `SegmentBudgetIssue` 同型但字段语义不同，
        不合并。
    - **下游产物失效标记必须覆盖 `Scenes` 表行，不能覆盖 `Scripts.content`**：
      场次编辑走 `updateScene` 只写 `Scenes` 表，而提案确认只改 `content` 里的
      `proposals`、不重写场次行，不该让下游失效。指纹按 `seq` 升序参与、剔除
      行 id 与 `scriptId`，所以「内容未变但重插一遍」不会误报失效。
      首次写指纹只落值不标记——没有旧指纹可比，说明这些产物在本次升级之前
      就已生成，按「存量视为有效」处理。指纹不漂移时整段跳过，包括不更新剧本行，
      避免空写制造无意义变更。
      `isStale` 用 `integer().withDefault(0)` 而不是 `boolean()`，与代码库既有
      风格一致；非 0 即失效。清除点只有三处：`AssetService.generate` 出图成功、
      `ShotService` 出图成功、`ShotService` 视频轮询完成。`confirmVideo` 只是
      确认动作、不是生成，不清标记。
    - **drift 2.35.1 不能用 `key` / `text` 做列 getter 名**：`ColumnParser` 会抛
      `FunctionExpressionInvocationImpl is not a subtype of MethodInvocation`，
      并把整个 `app_database.g.dart` 退化成空 schema（20661 行变成 19 行）。
      `PromptOverrides` 因此用 `slotKey` / `body`。改列名后必须确认生成文件
      行数恢复，再跑 analyze。
    - **`PromptOverrides` 覆盖按整段替换，不做局部合并**：局部合并需要插槽解析，
      语义太脆。三级顺序 项目级 > 全局级 > 内置 skill 原文，由
      `lib/agent/prompt_resolver.dart` 的 `PromptResolver.resolve` 统一解析，
       `allSlots` 常量与 `assets/skills/` 目录一一对应（12 个）。
       覆盖列为空串时视为未覆盖、继续回落。项目删除时
       `CascadeDao.deleteProjectCascade` 按 `projectId` 清项目级覆盖，
       `scope='global'` 的行 `projectId` 为 null 天然被谓词排除、不误删。
        表不加 unique key：`projectId` 在 `scope='global'` 时为 null，SQLite 里
        NULL 互不相等会让 unique 约束形同虚设，所以 DAO 走显式查再插/改的 upsert。
     - **Agent 提示词一律经 `PromptResolver`，项目归属统一走 `bookId`**：五个 Agent
       类（`ShotAgents` / `AssetAgents` / `SkeletonAgents` / `NovelAgents` /
       `ScriptAgents`）禁止直接 `SkillLoader.load`，必须经构造器注入的
       `PromptResolver`（`required this.resolver`，不留可选短路）。项目归属统一由
       `resolveByBook(relativePath, {bookId})` → `PromptOverrideDao.projectOfBook`
       解析，调用点不自拼 `bookId → projectId`。中转键用 `bookId` 而不是
       `scriptId`：五个 service 的调用点都直接持有 `bookId`，而
       `adaptChapters` 首次改编时剧本尚未落库、没有可用 `scriptId`；走 `bookId`
       全链路可用且省一次查询。`bookId` 为空时跳过项目级，只走全局与内置。
    - **结构化字段是段级不是帧级，且必须显式写回**：`Shots` 表的九个摄影字段
      （`composition` / `lens` / `cameraPosition` / `eyeline` / `focus` / `stability`
      / `blocking` / `dialogueStartRatio` / `dialogueEndRatio`）落在
      `ShotDraft`（段级）而不是 `ShotFrameDraft`（帧级）——构图、焦距、机位、
      视线、焦点、稳定性都是段级摄影参数，帧只是段内时间切片。段级 `blocking`
      写人物在该段时长内的移动轨迹，帧级 `blocking` 写首帧站位，两个字段同名但
      语义不同，skill 里显式要求不重复。重导时九个字段一律**显式写回**（空也写
      null），否则重新导演后上一轮的构图会残留。
    - **闭集词表字段与占位词一律解析为 null，不写「未知」进库**：`bodyType` 走
      `BodyTypes.all` 闭集（瘦长 / 匀称 / 结实 / 魁梧 / 丰腴 / 娇小），不在词表
      内的词返回 null；镜头摄影字段的占位词（无 / 未指定 / 同上 / - / N/A）同样
      返回 null。库里的 null 表示「未指定」，UI 整行跳过——写「未知」进库会让 UI
      渲染出「体型：未知」这种对用户没有信息的行。数值字段同理：`heightCm` 夹在
      80-230、对白占比夹在 0-100，越界与不可解析一律视为未指定。空数组同样返回
      null：`costumeSets` 全空时不能存 `[]`，否则 UI 会显示「0 套服装」。
    - **章节维护提醒是确认框不是只读列表，且相似度复用 `PromptGate.jaccard`**：
      `ChapterMaintainGate`（`lib/features/novel/chapter_maintain_gate.dart`）在 AI
      写作完成后触发（不是「正文一落盘」——手动编辑也走 `_save`，那是用户自己的
      文字，提示核对没有意义），阈值 500 字，四项目清单对应 TruthFile 四类状态
      （角色状态 / 场景状态 / 伏笔进展 / 道具状态）。清单是**可勾选**的，勾完显示
      「已全部核对」，未勾完显示「稍后再核对」——两种情况都能关闭，只提示不阻塞。
      相似度比较对象是「新写内容」与「续写前的既有正文」；词元数不足时返回
      **null 而不是 0**——0 会被误判为「完全无关」而错误触发全量重写建议；首次
      写作无既有正文时跳过相似度检查、只做清单提示。阈值 0.35 与 `PromptGate`
      的 0.75（查雷同）是同一量尺上的反向用法。



---

## 5. 数据与状态约定

- 所有结构化数据落 Drift（SQLite），文件（图片/视频/正文）存应用私有目录，路径入表。
- 每个生成阶段的产物**持久化 + 版本化**，支持断点续跑与人工介入修改；修改上游对象时展示下游**影响面**（对齐 `docs/05` 第 7 节）。
- 生成类操作（消耗算力）**默认需用户确认**：固定方案（对象/数量/完整提示词/参数/参考文件/执行次数）→ 授权 → **临执行复核**（提交前重读数据，变化则差异高亮重新授权）；费用不可查时明确「未知」。
- 区分「用户事实 / AI 提案 / 未知」，AI 产出不得冒充用户已确认的事实；AI 产出一律先走**提案卡**，用户确认后才落库。

---

## 6. 验证要求

- 每次改动后做最小验证：`flutter analyze` 无新增错误，涉及数据层改动跑 `dart test`（如已建测试）。
- **禁止为了通过检查而写无关测试或跳过类型检查**；只报告实际完成的验证。
- 涉及 AI 调用的功能，用「配置临时供应商 + 手动冒烟」验证连通与解析，不 mock 掉真实协议边界。
- **APK 构建一律走 GitHub Actions CI（push 后在 Actions 产出/下载 APK），禁止在本地构建**：本地环境约 358 MiB 内存 + 2 CPU，跑 `flutter build apk` 会失败或拖垮机器。本地验证只做 `flutter analyze` + `flutter test`。
- 发布前 Release 签名流程也在 CI 完成（签名材料走仓库 Secret：`KEYSTORE_BASE64` / `KEYSTORE_PASSWORD` / `KEY_ALIAS` / `KEY_PASSWORD`）。

---

## 7. 输出要求

- 所有回答与思考使用**中文**。
- 默认用 **Dart** 编写代码（除非明确要求其他语言）。
- 提供最小可运行实现，除非用户要求完整实现。
- 引用代码用 `file:line` 形式；改动前先读相关代码，改动后说明影响面。
- 不确定的边界先确认再动手，不擅自扩大范围或假设需求。

---

## 8. 安全红线

- API Key、用户小说正文、生成的资产/镜头均属敏感数据，**不得上传到任何非用户指定的服务器**。
- 网络请求仅发送执行生成所需的提示词/参考图到用户配置的供应商端点。
- 禁止在日志、崩溃上报、调试输出中泄露 API Key 或正文内容。
- 发布前做隐私自检：权限最小化、无多余网络权限滥用。
