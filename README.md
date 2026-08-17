# NGF (Neon Genesis Framework)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![HarmonyOS SDK](https://img.shields.io/badge/HarmonyOS_SDK-26.0.0_(API_26)-blue.svg)](https://developer.harmonyos.com/)
[![Language](https://img.shields.io/badge/Language-ArkTS-orange.svg)]()

**🌐 语言 / Language:** 中文 | [English](README.en.md)

欢迎来到 **NGF (Neon Genesis Framework)**！这是一个专为 HarmonyOS Next 打造的**开箱即用的应用开发框架**。

无论你是想从零开始开发一款精美的鸿蒙原生应用，还是想借助 AI 助手（Vibe Coding）极速生成页面，NGF 都为你准备好了坚实的基础设施（主题、多语言、存储、网络、导航等），让你能够**将 90% 的精力集中在业务本身**。

---

## 🙋‍♂️ 开发者快速上手 (For Developers)

NGF 的设计初衷是**“随时可以变成你自己的 App”**。

1. **克隆项目并运行**：
   使用 DevEco Studio 打开项目，点击运行，你将看到一个内置了 5 个演示 Tab 的完整框架示例，包含了沉浸式导航、毛玻璃效果和所有核心能力的演示。
2. **把它变成你的 App**：
   - 阅读 [业务化与发布指南](.rules/skill-app-release.md)，按照步骤修改 `bundleName`、应用名称和图标。
   - 删除不需要的演示页面，开始编写你自己的业务逻辑！
3. **调用开箱即用的能力**：
   不需要自己造轮子，直接从框架导入你需要的工具：
   ```typescript
   import { logger, securityToolkit, FileUtils, ngfNetworkClient } from 'ngf_framework';
   ```

---

## 🤖 AI 助手快速上手 (For AI Agents / Vibe Coding)

本项目极其适合结合 AI 编程助手（如 Cursor、Windsurf、Claude Code 等）进行开发。我们为 Agent 准备了详尽的“行为准则”。

**作为 AI 助手，在开始编写代码前，你必须严格按照以下顺序阅读规则**：

| 优先级 | 文件 | 必读原因 |
|--------|------|--------|
| 1️⃣ | [AGENTS.md](AGENTS.md) | **最高优先级**：项目的绝对宪法！包含目录结构解析、导包规则、禁止事项。 |
| 2️⃣ | [.rules/README.md](.rules/README.md) | **技能索引**：查阅你可以使用的各种“超能力”（如一键生成页面、复用组件等）。 |
| 3️⃣ | [.rules/skill-scaffold-page.md](.rules/skill-scaffold-page.md) | **极速建页**：收到“新建页面”指令时，直接套用此文件中的模板代码。 |
| 4️⃣ | [.rules/skill-component-reuse.md](.rules/skill-component-reuse.md) | **复用指南**：开发功能时，查阅如何调用框架里现成的弹窗、标题栏和核心工具。 |

> 💡 **给 Agent 的提示**：本项目是一个模块化工程（`ngf_framework` 为核心库，`entry` 为业务层），在 `entry` 中开发时，必须使用 `import { ... } from 'ngf_framework'` 进行导包。

---

## 📦 框架内置了什么？

NGF 采用高内聚低耦合的分层架构，将复杂的能力封装成了简单的 API：

- 🎨 **UI 与主题 (uiTheme & uiShell)**：内置 20 个语义色 Token，完美支持深色模式切换、沉浸式顶部标题栏（HDS）和毛玻璃特效。
- 🪟 **多窗口、卡片与悬浮窗 (platformOhos)**：不仅支持灵活的应用内悬浮窗 (SubWindow)，还支持系统级桌面快捷方式 (Shortcuts)、桌面服务卡片 (Widgets) 以及独立的宏观多实例 (Multiton)。内置了强大的壳层容器，无论是在应用内还是直接从桌面唤起，通过简单的 AppStorage 和 Want 传参即可极速完成页面的独立挂载，且冷启动多实例时会自动接管框架的全局初始化！
- 🌍 **国际化 (i18n)**：支持多语言切换、相对时间格式化（“刚刚”、“2小时前”）。
- 💾 **数据与存储 (data)**：提供真 LRU 内存缓存、偏好设置 (Preferences) 和关系型数据库 (RDB) 的极简封装。
- ⚙️ **工作流与任务 (workflow & systemTasks)**：支持复杂的异步任务编排，以及带保活锁和常驻系统通知栏的后台长时任务。
- 📱 **设备感知 (deviceAwareness)**：支持折叠屏适配、单手/双手握持感知、13项硬件能力探测。
- 🛠️ **全能工具箱 (utils)**：内置性能监控、SHA/AES 加解密安全套件、统一日志系统等。

---

## 📁 极简项目结构

```text
NGF/
 ├── ngf_framework/src/main/ets/  # 🛠️ 框架核心包 (HAR)，所有核心能力都在这里
 ├── entry/src/main/ets/          # 📱 你的业务 App (HAP)，在这里写你的页面和逻辑
 │    └── pages/ngf/              # 框架自带的演示页面（业务化时可删除）
 ├── .rules/                      # 🤖 给 AI 助手看的工作规则和技能库
 ├── AGENTS.md                    # 📜 全局开发约束与 Agent 宪法
 └── build-profile.json5          # ⚙️ 鸿蒙工程配置
```

---

## 🔧 CI 云端构建（GitHub Actions）

本仓库内置三个 workflow（位于 `.github/workflows/`），实现"push 即云端出包"的 HAP 流水线，体验与 Android APK 的 CI 一致：

| Workflow | 触发方式 | 作用 |
|---|---|---|
| `docker-image.yml` | 手动（workflow_dispatch） | 一次性构建含 API 26 command-line-tools 的 CI 镜像并推送 ghcr.io |
| `build.yml` | push `main`/`master`、PR | debug 模式构建**未签名** HAP 并上传 artifact（`hap-unsigned`） |
| `sign-and-release.yml` | push `v*` tag | 构建 → hap-sign-tool 签名 → 发布 GitHub Release（需配置 Secrets） |

### 首次接入（一次性，约 15 分钟）

1. **准备 CI 镜像**（方案：自建 Docker 镜像，API 版本完全可控）：
   1. 获取与本工程 API 26 匹配的 **Linux (x86-64)** 版 command-line-tools zip。两种来源任选：
      - **社区镜像（推荐，链接稳定公开）**：[jerry-271828/harmonyos-commandline-tools](https://github.com/jerry-271828/harmonyos-commandline-tools) 的 `v26.0.0.461` release，zip 被切成两个分片（`clt.zip.part00` / `clt.zip.part01`），把两个分片 URL **以空格分隔**一起填入即可，Dockerfile 会自动拼接；
      - **华为官方**：[「获取命令行工具」](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-commandline-get)页面下载（链接带时效签名，需先转存到可直链处）；
   2. 把 zip 上传到任意可直链下载的位置（GitHub Release 附件、对象存储等）；
   3. 在仓库 Settings → Secrets and variables → Actions 添加 secret `CLT_ZIP_URL`（zip 直链）；
   4. 手动运行一次 **Build CI image** workflow，产出 `ghcr.io/<owner>/harmonyos-ci:api26`。此后 `build.yml` 默认使用该锁定 tag，构建环境可复现。
2. **完成**：之后每次 push 主分支 / PR 都会自动构建，在 Action 页面下载 `hap-unsigned` artifact（含 `entry-default-unsigned.hap`，可在 DevEco Studio 中重新签名后安装）。

> **签名说明**：`build-profile.json5` 中的 `signingConfigs` 指向开发者本机证书路径，CI 会自动执行 `.github/scripts/strip_signing.py` 剥离该配置并产出**未签名** HAP，不影响本机签名构建。第一阶段 CI 不引入签名；本仓库无 git 子模块，若未来引入，请在 checkout 步骤开启 `submodules: recursive`。

### 配置签名与自动 Release（可选）

push `v*` tag 会触发 `sign-and-release.yml`。所需 Secrets（证书/密钥文件 **base64 编码后**存放，绝不入库；`.gitignore` 已拦截所有证书类文件）：

| Secret | 内容 |
|---|---|
| `SIGNING_CERT` | `.cer` 公钥证书，base64（建议 `base64 -w 0` 生成单行） |
| `SIGNING_PROFILE` | `.p7b` 签名 Profile，base64 |
| `SIGNING_KEY` | `.p12` 密钥库文件，base64 |
| `SIGNING_KEY_ALIAS` | 密钥别名（明文） |
| `KEYSTORE_PASSWORD` / `KEY_PASSWORD` | 密钥库 / 密钥口令（明文） |
| `CLT_ZIP_URL` | （供 `docker-image.yml`）command-line-tools zip 直链 |

未配置签名 Secrets 时，tag 构建会**跳过签名并输出指引**，不会报红失败。

---

## 📚 更多文档

| 文档 | 说明 |
|------|------|
| [框架内部架构详解](ngf_framework/src/main/ets/README.md) | 给想深入了解 NGF 底层实现的硬核开发者阅读 |
| [框架业务化指南](.rules/skill-app-release.md) | 如何修改包名、申请证书并上架到华为应用市场 |

---

## 📄 许可证 (License)

本项目基于 [MIT License](LICENSE) 开源。

```
Copyright (c) 2026 DaLongzhuazi

特此免费授予任何获得本软件及相关文档副本的人无限制使用、复制、修改、合并、
发布、分发、再许可或销售该软件副本的权利，但须满足上述版权声明及本许可证声明。
本软件按「原样」提供，不作任何形式的保证。
```

---
*本框架由 **DaLongzhuazi** 开发维护，致力于让每一位开发者都能轻松构建卓越的 HarmonyOS 原生应用。*
