# NGF (Neon Genesis Framework)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![HarmonyOS SDK](https://img.shields.io/badge/HarmonyOS_SDK-6.1.0_(API_23)-blue.svg)](https://developer.harmonyos.com/)
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

## 📚 更多文档

| 文档 | 说明 |
|------|------|
| [框架内部架构详解](entry/src/main/ets/Framework/NGF/README.md) | 给想深入了解 NGF 底层实现的硬核开发者阅读 |
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
