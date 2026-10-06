# User Instruction Memory

This file records user instructions, preferences, and teachings for reference in future interactions.

## Format

### User Instruction Entry
User instruction entries should follow this format:

[User Instruction Summary]
- Date: [YYYY-MM-DD]
- Context: [Mentioned scenario or time]
- Instructions:
  - [Content of user teaching or instruction, described line by line]

### Project Knowledge Entry
Entries discovered by the Agent during task execution should follow this format:

[Project Knowledge Summary]
- Date: [YYYY-MM-DD]
- Context: Discovered by Agent while performing [specific task description]
- Category: [Operations & Deployment|Build Methods|Testing Methods|Troubleshooting & Debugging|Workflow & Collaboration|Environment Configuration]
- Instructions:
  - [Specific knowledge points, described line by line]

## Deduplication Strategy
- Before adding a new entry, check for similar or identical instructions.
- If a duplicate is found, skip the new entry or merge it with the existing one.
- When merging, update the context or date information.
- This helps avoid redundant entries and keeps the memory file tidy.

## Entries

[全部回答与思考使用中文]
- Date: 2026-10-04
- Context: 用户在本项目协作中明确要求
- Instructions:
  - 所有回答、思考过程、工具调用标题、代码注释、文档一律使用中文
  - 技术术语可保留英文

[APK 构建与发布走 CI，禁止本地构建]
- Date: 2026-10-04
- Context: 本项目为 Flutter Android APK，本地环境约 358 MiB 内存 + 2 CPU
- Category: Build Methods
- Instructions:
  - APK 构建一律走 GitHub Actions CI，push 后在 Actions 产出/下载 APK
  - 本地跑 `flutter build apk` 会失败或拖垮机器，本地只做 `flutter analyze` + `flutter test`
  - Release 签名在 CI 完成，签名材料走仓库 Secret：`KEYSTORE_BASE64` / `KEYSTORE_PASSWORD` / `KEY_ALIAS` / `KEY_PASSWORD`
  - CI 产物路径为 `app-release.apk` / `app-debug.apk`（单 ABI 单 APK，无 ABI 后缀）
  - ABI 只打 `arm64-v8a`：用 `defaultConfig.ndk.abiFilters`，CI 构建命令带 `-P disable-abi-filtering=true`。**禁止用 `splits.abi`**——Flutter Gradle 插件（`FlutterPlugin.kt` 的 `configureAbis()`）在未传 `-P split-per-abi` 时会把 `armeabi-v7a/arm64-v8a/x86_64` 写进 `defaultConfig.ndk.abiFilters`，与 `splits.abi` 互斥，configure 阶段报 `Conflicting configuration` 直接失败
  - CI 日志拉取（需 PAT，带 `actions: read` + `contents: read`）：
    1. `GET /repos/xfygl11/newmove/actions/runs?branch=main&per_page=40`，用每项的 `id`（不是 `run_number`）
    2. `GET /repos/{owner}/{repo}/actions/runs/{id}` 看 status/conclusion
    3. `curl -sL .../actions/runs/{id}/logs` 得 zip，解开后单步日志在 `Analyze, Test & Build APK/<步号>_<步名>.txt`
    4. `GET .../actions/runs/{id}/artifacts` 取 `archive_download_url` 下载 APK（zip 内含 `app-*.apk`）
  - 注意：token 必须直接内联到 `curl -H "Authorization: Bearer ..."`，本环境里赋给 shell 变量会被截断；unauthenticated 调用很快触发 403 rate limit
  - 未配置签名 Secret 时 CI 仍会绿，但只产出 `app-debug.apk`（约 131 MB），日志有 `::warning::未配置签名 Secret` 提示；`if-no-files-found: warn` 会掩盖缺失的 release APK

[Flutter / Dart 命令路径]
- Date: 2026-10-04
- Context: 本机 flutter 不以 root 常态可用
- Category: Environment Configuration
- Instructions:
  - 必须用绝对路径调用：`/opt/flutter/bin/flutter`、`/opt/flutter/bin/dart`
  - 以 root 跑会出现 "Woah! You appear to be trying to run flutter as root" 提示，属预期非错误
  - 格式化命令：`/opt/flutter/bin/dart format lib/`
  - **禁止无差别跑 `dart format` 做「改后格式化」或「校验格式」**（2026-10-06 实测）：本环境 formatter 是新 tall 风格，仓库提交基线是 old short 风格，`dart format -o none --set-exit-if-changed assets lib/features test` 报 44 个文件需改动，其中大量从未碰过的旧文件（`asset_detail_page.dart`、`shot_service.dart`、`sse_parser_test.dart` 等），基线已失效——它无法区分「我的改动没格式化」和「全仓库都过不了」。手改代码要直接按仓库既有缩进写，新代码用 old short 风格；误跑 formatter 后用 `git checkout -- <file>` 回退再手工重贴逻辑改动

[核心测试命令]
- Date: 2026-10-05
- Context: 每次改动后最小验证
- Category: Testing Methods
- Instructions:
  - 跑核心测试（约 35 秒）：`/opt/flutter/bin/flutter test test/novel_service_test.dart test/backup_service_test.dart test/daos_test.dart test/truth_file_store_test.dart test/revision_and_attempt_test.dart`
  - 全量 `/opt/flutter/bin/flutter test` 约 10 分钟（加 `--concurrency=1`）、峰值约 1.9 GiB，用 background terminal 跑
  - 单文件快速迭代（约 1–2 分钟）：`/opt/flutter/bin/flutter test test/gates_test.dart --no-pub --concurrency=1`
   - 当前基线：M14 + M15 + M18-B + M19 全量落地（含 T21.6 校验留痕、T21.11 提示词三级覆盖与五个 Agent 接入 resolver、T21.12/T21.13 结构化字段含镜头级服装覆盖、T21.14 下游失效、T21.15 章节维护提醒），schema v12，全量 379 例全通过，`/opt/flutter/bin/flutter analyze` 零问题（`flutter` 需用绝对路径 `/opt/flutter/bin/flutter`）
    - M20 技术债轮已落地：T20.22（`StatusKinds` 完备性守卫测试 + 补登章节「审校中」与伏笔五个标签 + 新增 `contains`/`all` 只读接口）、T20.24（`SkillLoader` 集成测试，正向遍历 `allSlots` + 反向守卫 `assets/skills` 无孤立文件）、T20.29（启用 `prefer_const_constructors` 等三条 lint，`dart fix` 自动修 105 处 + 7 处 `unnecessary_const`）、T20.30（docs/02 §3.1/§3.2 回填 19 表拓扑与缺失字段，docs/05 新增 §13 实现状态对照，AGENTS.md「15 处」改 16）；早期里程碑 T0–T8 勾选补齐（T7.4 / T8.2 附落地修正），T16.9.4 勾选（`Scripts.aspectRatio`/`language` schema v8 已删，`version` 并非死字段）
     - **M21 已落地（2026-10-06）**：T22.1–T22.9 画风词表化（`ArtStyleCatalog` 16 条三族 + 存短名）与作品形式进基础设置（`workForms` 必填 + `genreContext` 非默认才输出），无 schema 变更；全量 **442 例**全通过（基线 428 + 13 画风 + 1 作品形式），`flutter analyze` 零问题
      - **M22 已落地（2026-10-06）**：T23.1–T23.7 质量门加固，新增 3 个门文件（`shot_gate.dart` / `skeleton_gate.dart` / `script_gate.dart`）+ `PromptGate` 五门 + `SegmentBudget.under_limit`，共 15 个新校验码；删除 `SkeletonIssue`，骨架体检统一走 `GateIssue`；无 schema 变更；全量 **487 例**全通过，`flutter analyze` 零问题
      - **M23 已落地（2026-10-06）**：T24.1–T24.8 角色画像补全 + 提示词可追溯，schema v13→v14（additive：`createTable(promptOverrideVersions)` + `addColumn(projects, useProjectPrompts)`）；新增 `CharacterGate`（`tier_missing`/`tier_cap`/`evidence_unverified`）+ `CharacterTiers` 闭集分档 + `CharacterSpec` 五个可选字段；新增 `novel/voice_design.md` skill（`allSlots` 13→14）+ `NovelAgents.designVoice`；`PromptOverrideDao.upsert` 事务化并在改正文前存档旧 body，「回退」= 取历史版本 body 再 upsert；`useProjectPrompts` 写 0/1、**`null` 等价开启**，`PromptResolver.resolve`/`findOverride` 共用 `projectPromptsEnabled` 门控；`CascadeDao.deleteProjectCascade` 补清项目级版本存档；全量 **542 例**全通过，`flutter analyze` 零问题
      - **drift 数据行类的命名陷阱**：`@DataClassName('X')` 的行类在 `app_database.g.dart`（不是 `tables.g.dart`），要用就得 import `package:newmove/data/app_database.dart`；直接用表名 `PromptOverrideVersions` 作类型会得到带 `Column<String>` getter 的表对象，比较与传参全报错。**用 edit 工具做 `replaceAll` 改类型名时要防 `PromptOverrideVersionsCompanion` 被连带改成 `PromptOverrideVersionssCompanion`**
      - **`ReviewIssue._locateQuote` 有前缀降级**（从 `len-1` 缩到 4 字为止），所以写「长引文未命中」类测试时选一个前 4 字都不在正文里的长串，否则会被降级匹配命中、门不响
  - **`flutter analyze` 与 `flutter test` 不要放在两个后台终端里并发跑**：本环境内存紧张，并发时会把 analyze 顶到 OOM（exit code -1 + `killed_by_timeout`，且输出 0 字节）。串行跑，先 analyze（约 25 秒）再 test
  - 单文件 test 加 `| tail -N` 会等到进程结束才输出，运行期间日志一直是 0 字节；要观察进度就别加 tail
  - 全量测试偶发 `<某文件>: loading <该文件>` 失败而其余 480+ 例全绿（2026-10-06 实测：`backup_service_test.dart`）——是该文件的编译 isolate 被内存顶掉，不是代码问题。判定方式：单独重跑该文件，通过即为环境抖动，无需改代码

[Flutter 3.47 Dialog / widget test 踩坑记录]
- Date: 2026-10-05
- Context: 排查「添加 Agnes AI 预设」对话框 BOTTOM OVERFLOWED BY 8.9 PIXELS 斜纹水印时
- Category: Troubleshooting & Debugging
- Instructions:
  - Flutter 3.47 的 `showDialog` **已无 `resizeToAvoidBottomInset` 参数**，`Dialog` widget 也不含该字段；键盘弹出时 `Dialog.build` 把 `MediaQuery.viewInsetsOf(context)` 直接加到外边距上，再对子树 `removeViewInsets`。弹框内容偏高时正确做法是给 content 包 `SingleChildScrollView`，不要找 inset 开关
  - 底部斜纹水印是 debug 版 `OverflowError` 的渲染标记，release APK 不会出现；`framework.dart` 的 `_dependents.isEmpty` 断言同样是 debug-only 树一致性告警
  - widget test 里对话框含 `TextField` 时 **不能 `pumpAndSettle`**（caret 闪烁 timer 永不 settle），改用固定帧 `pump(Duration(milliseconds: 150))` 循环
  - `tester.scrollUntilVisible` 的 `scrollable` 形参必须命中 `Scrollable` widget，传 `find.byType(ListView)` 会抛 `ListView is not a subtype of Scrollable`
  - widget test 结束时用 `pumpWidget(SizedBox.shrink())` + `pump(Duration(milliseconds: 1))` 卸载树并 flush drift 流订阅的内部计时器，否则会报 pending timer

[后台测试进程与本机能存（踩坑记录）]
- Date: 2026-10-05
- Context: 全量测试期间可用内存只剩 335 MB，4 个 80–95 分钟前遗留的 `flutter_tester`（PPID=1，各约 150–180 MB）在占内存
- Category: Troubleshooting & Debugging
- Instructions:
  - 跑全量测试前先看 `free -m` 与 `ps -eo pid,ppid,stat,etime,rss,cmd --sort=-rss | grep flutter_tester`；本环境约 8 GiB，opencode 本体长期占约 700 MB
  - `flutter test` 被中断后子进程 `flutter_tester` 会被 init 收养（PPID=1）成孤儿且不会自动退出；按具体 PID 逐个 `kill <pid>` 释放，不要用 pkill 按进程名批量杀
  - 全量测试加 `--concurrency=1` 把并行套件数压到 1 降低同时段内存占用

[drift 2.35 更新语义与 Companion 限制（踩坑记录）]
- Date: 2026-10-04
- Context: 给 `GenerationAttemptDao.finishAttempt` 增加可选回写字段时发现
- Category: Build & Compilation
- Instructions:
  - **更新时 `Value(null)` 是显式置 NULL，不是「跳过该列」**：`finishAttempt` 里写 `subjectId: Value(null)` 会把已有关联 id 清成空值，导致 `listBySubject` 查不到行。可选字段必须写成 `subjectId == null ? const Value.absent() : Value(subjectId)`
  - `Companion` 字段全是 `final`，**没有 setter**，不能 `companion.x = ...` 分步赋值；有默认值的列参数类型是 `Value<T>?` 但默认值是 `const Value.absent()`，传 `null` 会报类型错误，只能用 `const Value.absent()`
  - `Companion` 上**没有 `count()` 方法**，统计用 `select().get().length`
  - `GeneratedCompanion` 不是类，需要降级写入时用具体类型的 Companion（如 `ShotRevisionsCompanion`）
  - 带默认值的列在 `Companion.insert` 里参数类型是 `Value<String>`（要包 `Value(...)`），无默认值的必填列直接收 `String`；nullable 且非必填（如 `subjectLabel`）传 `String?` 时必须用 `Value.absent()` 分支，否则报 `String? → String` 不匹配
  - **2.35.1 的 `get()` 不接受 `limit` 参数**：`query.get(limit: n)` 直接报 `undefined_named_parameter`；限制条数要先 `query.limit(n)`（来自 `LimitContainerMixin`）再 `query.get()`
  - 条件 where 链要写成 `final q = select(t); if (x != null) q.where(...); q.orderBy(...); q.limit(n); return q.get();`——`where` / `orderBy` 都返回新 statement，链式调用会丢掉后面的子句；`const IsNull(false)` 这类写法不合法
  - **改 `tables.dart` / DAO 后必须重跑 `dart run build_runner build`，且提交前要 `git diff` 核对生成的 `app_database.g.dart` 与源文件一致**：build_runner 是增量 + 缓存的，若先前在带 `KeyAction.cascade` 的版本上生成过、随后又 revert 了源文件，`.g.dart` 会残留 16 处 `ON DELETE CASCADE`（本次 M18-B 实际踩到），会把 v11 迁移推给不存在的表重建。核对方式：源文件 `grep -c KeyAction.cascade` 为 0 时，`.g.dart` 里 `ON DELETE CASCADE` 也必须为 0
  - 生成的 `.g.dart` 是 `part of` 源文件，**不继承源文件的 import**：列默认值要引用自定义常量（如 `Constant(VideoTaskStatuses.queued)`）时，必须在**真正 import 该文件的库文件**（`app_database.dart`）里加 import，否则 `.g.dart` 报 `invalid_constant` + `undefined_identifier`。同理 `tables.dart` 自己的 import 只对它自己生效

[纯 Dart 语义与依赖 API 的本地验证方法]
- Date: 2026-10-05
- Context: 代码调研时需确认 Dart switch 语义与 dio 超时语义，避免凭记忆误判
- Category: Testing Methods
- Instructions:
  - 验证纯 Dart 语言行为/最小样例时，直接跑 `/opt/flutter/bin/cache/dart-sdk/bin/dart <file>`（秒级，不需要 flutter 完整环境，也不受 358 MiB 内存限制影响）
  - 第三方包的 API 语义一律去 `~/.pub-cache/hosted/pub.dev/<pkg>-<version>/` grep 源码确认，不要凭记忆下结论；例如 dio 5.11.1 中 `receiveTimeout` 同时覆盖「建连 + 首字节」以及「数据传输中每两个字节事件的间隔」，而 `connectTimeout` 默认 null（无限制）
  - Dart 非空 `switch case` 分支即使不写 `break`，CFE 也不会 fall-through（运行时验证：case 体末尾隐式跳出），analyzer 3.13 也不会报 `flow_control_transfer_required_in_switch`；不要把「case 缺 break」当成缺陷上报
  - **字符串插值 `$id_` 会把 `id_` 当成一个完整标识符**（贪婪匹配下划线），报 `undefined_identifier`；标识符后面紧跟 `_` 或 `.` 之外字符时必须写 `${id}`
  - `file_picker` 13.1 的 `FilePicker.pickFiles` 返回 `Future<List<PlatformFile>>`（**非空**），`result?.single.path` 会报 `invalid_null_aware_operator`；先 `if (result.isEmpty) return;` 再取 `result.single.path`（`path` 本身仍是 `String?`）
  - 单测里 mock path_provider 的模式见 `test/backup_service_test.dart`：继承 `PathProviderPlatform` + `MockPlatformInterfaceMixin`，覆盖 `getApplicationDocumentsPath` 指向临时目录，再 `PathProviderPlatform.instance = ...`；`tearDown` 里删临时目录

[借鉴项目缓存位置（做功能/流程比对时直接用）]
- Date: 2026-10-04
- Context: 用户说明「借鉴项目还在缓存目录」，本项目需求比对与借鉴分析依赖这两个开源项目源码
- Category: Environment Configuration
- Instructions:
  - Toonflow 在 `/tmp/opencode/Toonflow-app`（commit `f37b772`，646 文件，官方最新，无子模块，已核实远端/本地文件数一致）
  - InkOS 在 `/tmp/opencode/inkos`（commit `8fc2ae5`，792 文件）
  - M19 外部对标 5 仓在 `/tmp/opencode/`：`shuohao-skills`（最核心，管线同构，52 道纯函数质量门）、`AIComicBuilder`（55 条迁移 = 领域能力清单，`src/lib/ai/prompts/registry.ts` 是 16 提示词 / 73 插槽）、`goink`（`internal/mcp_tools/rw_tools.go`）、`manga-gen`（`backend/services/gemini.py`）、`NarrativeSteward`（观察项）
  - 做功能对齐、流程比对、深查借鉴机制时直接读这两个目录，无需重新下载
  - `/tmp/opencode` 属临时目录，若目录缺失则按远端仓库重新克隆；两个项目均为只读参考，不要在其内部修改代码
  - 比对结论与「采纳/不采纳」决策记录在 `docs/01` 第 8 节，任务化条目在 `docs/04` 第 8.y 节（M14）

[工作流约定：同步文档 + 按阶段推进 + Git 提交]
- Date: 2026-10-05
- Context: 用户要求
- Category: Workflow & Collaboration
- Instructions:
  - 每次新增/修改功能都要及时同步 `AGENTS.md` 与 `docs/02-系统架构设计.md`、`docs/04-开发计划与任务.md`；`AGENTS.md` 是 AI 协作规范，`docs/` 是详细设计，三者需保持一致
  - 只实现用户当前明确要求的内容，不主动扩展功能、不加占位数据；完成当前要求并验证后停止，等待下一步指令，不擅自扩大范围
  - 文档先于代码：用户给出的方向先完整更新到 `docs/`，再按文档动手实现
  - zsh 对 commit message 中的反引号/`<` 会报错：先把提交信息写入文件，再 `git commit -F <文件>`；临时提交信息文件不要随代码提交，用 `git add -A -- . ':!.git_commit_msg.txt'` 排除
