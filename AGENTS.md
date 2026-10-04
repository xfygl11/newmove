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

### 数据与备份约定（M11 P2 追加）

- 全库备份：`BackupService.exportAll()` 导出所有项目为单 zip（`scope: full`），`importProject` 兼容全库包与单项目包；导入前经 `findConflicts` 做同名项目检测，冲突时弹窗确认。
- 章节导入/导出：章节编辑器支持导出 Markdown / HTML；书架页支持导入 `.md/.html/.txt` 为草稿章节（H1 提取标题，HTML 剥标签）。

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
