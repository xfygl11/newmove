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
  - CI 产物路径已改为 `app-release-arm64-v8a.apk` / `app-debug-arm64-v8a.apk`（单 ABI）
  - CI 状态轮询：`curl -s -H "Accept: application/vnd.github+json" api.github.com/repos/xfygl11/newmove/commits/<sha>/check-runs`；遇 API rate limit 跳过，以本地验证为准

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
