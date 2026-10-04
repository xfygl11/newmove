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

[Git 提交时用 -F 文件避免 zsh 报错]
- Date: 2026-10-04
- Context: 提交信息含反引号或 `<` 等字符时
- Category: Workflow & Collaboration
- Instructions:
  - zsh 对 commit message 中的反引号/`<` 会报错
  - 改为先把提交信息写入文件，再执行 `git commit -F <文件>`
  - 临时提交信息文件不要随代码提交，用 `git add -A -- . ':!.git_commit_msg.txt'` 排除

[核心测试命令]
- Date: 2026-10-04
- Context: 每次改动后最小验证
- Category: Testing Methods
- Instructions:
  - 跑核心测试（约 35 秒）：`/opt/flutter/bin/flutter test test/novel_service_test.dart test/backup_service_test.dart test/daos_test.dart test/truth_file_store_test.dart`
  - 全量 `flutter test` 曾超时，优先跑核心四个文件
  - 当前基线：18/18 通过，`flutter analyze` 零问题

[纯 Dart 语义与依赖 API 的本地验证方法]
- Date: 2026-10-04
- Context: 代码调研时需确认 Dart switch 语义与 dio 超时语义，避免凭记忆误判
- Category: Testing Methods
- Instructions:
  - 验证纯 Dart 语言行为/最小样例时，直接跑 `/opt/flutter/bin/cache/dart-sdk/bin/dart <file>`（秒级，不需要 flutter 完整环境，也不受 358 MiB 内存限制影响）
  - 第三方包的 API 语义一律去 `~/.pub-cache/hosted/pub.dev/<pkg>-<version>/` grep 源码确认，不要凭记忆下结论；例如 dio 5.11.1 中 `receiveTimeout` 同时覆盖「建连 + 首字节」以及「数据传输中每两个字节事件的间隔」，而 `connectTimeout` 默认 null（无限制）
  - Dart 非空 `switch case` 分支即使不写 `break`，CFE 也不会 fall-through（运行时验证：case 体末尾隐式跳出），analyzer 3.13 也不会报 `flow_control_transfer_required_in_switch`；不要把「case 缺 break」当成缺陷上报

[借鉴项目缓存位置（做功能/流程比对时直接用）]
- Date: 2026-10-04
- Context: 用户说明「借鉴项目还在缓存目录」，本项目需求比对与借鉴分析依赖这两个开源项目源码
- Category: Environment Configuration
- Instructions:
  - Toonflow 在 `/tmp/opencode/Toonflow-app`（commit `f37b772`，646 文件，官方最新，无子模块，已核实远端/本地文件数一致）
  - InkOS 在 `/tmp/opencode/inkos`（commit `8fc2ae5`，792 文件）
  - 做功能对齐、流程比对、深查借鉴机制时直接读这两个目录，无需重新下载
  - `/tmp/opencode` 属临时目录，若目录缺失则按远端仓库重新克隆；两个项目均为只读参考，不要在其内部修改代码
  - 比对结论与「采纳/不采纳」决策记录在 `docs/01` 第 8 节，任务化条目在 `docs/04` 第 8.y 节（M14）

[后续开发需同步更新 AGENTS.md 与 docs]
- Date: 2026-10-04
- Context: 用户要求
- Category: Workflow & Collaboration
- Instructions:
  - 每次新增/修改功能都要及时同步 `AGENTS.md` 与 `docs/02-系统架构设计.md`、`docs/04-开发计划与任务.md`
  - `AGENTS.md` 是 AI 协作规范，`docs/` 是详细设计，三者需保持一致

[按阶段推进，完成当前要求后等待下一步指令]
- Date: 2026-10-04
- Context: 用户多次以「继续」推进
- Instructions:
  - 只实现用户当前明确要求的内容，不主动扩展功能、不加占位数据
  - 完成当前要求并验证后停止，等待下一步指令，不擅自扩大范围
