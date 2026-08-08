# NGF (Neon Genesis Framework)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![HarmonyOS SDK](https://img.shields.io/badge/HarmonyOS_SDK-26.0.0_(API_26)-blue.svg)](https://developer.harmonyos.com/)
[![Language](https://img.shields.io/badge/Language-ArkTS-orange.svg)]()

**🌐 Language / 语言:** English | [中文](README.md)

Welcome to **NGF (Neon Genesis Framework)**! This is an **out-of-the-box application development framework** built specifically for HarmonyOS Next.

Whether you want to build a beautiful native HarmonyOS application from scratch or use an AI assistant (Vibe Coding) to rapidly generate pages, NGF provides solid infrastructure (themes, multilingual support, storage, networking, navigation, and more), allowing you to **focus 90% of your effort on the business itself**.

---

## 🙋‍♂️ Developer Quick Start (For Developers)

NGF was designed from the outset to **become your own App at any time**.

1. **Clone and run the project**:
   Open the project with DevEco Studio and click Run. You will see a complete framework sample with 5 built-in demo tabs, including immersive navigation, frosted-glass effects, and demonstrations of all core capabilities.
2. **Turn it into your App**:
   - Read the [Productization and Release Guide](.rules/skill-app-release.md) and follow the steps to modify the `bundleName`, app name, and icon.
   - Delete the demo pages you do not need and start writing your own business logic!
3. **Use out-of-the-box capabilities**:
   No need to reinvent the wheel; directly import the tools you need from the framework:
   ```typescript
   import { logger, securityToolkit, FileUtils, ngfNetworkClient } from 'ngf_framework';
   ```

---

## 🤖 AI Assistant Quick Start (For AI Agents / Vibe Coding)

This project is extremely well suited for development with AI programming assistants (such as Cursor, Windsurf, Claude Code, and others). We have prepared detailed "behavioral guidelines" for Agents.

**As an AI assistant, before starting to write code, you must strictly read the rules in the following order**:

| Priority | File | Required Reading Reason |
|--------|------|--------|
| 1️⃣ | [AGENTS.md](AGENTS.md) | **Highest priority**: the project's absolute constitution! It contains directory structure analysis, import rules, and prohibitions. |
| 2️⃣ | [.rules/README.md](.rules/README.md) | **Skill index**: browse the various "superpowers" available to you, such as one-click page generation and component reuse. |
| 3️⃣ | [.rules/skill-scaffold-page.md](.rules/skill-scaffold-page.md) | **Rapid page creation**: when you receive a "create a new page" instruction, directly use the template code in this file. |
| 4️⃣ | [.rules/skill-component-reuse.md](.rules/skill-component-reuse.md) | **Reuse guide**: when developing features, learn how to call the existing dialogs, title bars, and core tools in the framework. |

> 💡 **Hint for Agents**: This project is a modular project (`ngf_framework` is the core library and `entry` is the business layer). When developing in `entry`, you must use `import { ... } from 'ngf_framework'` for imports.

---

## 📦 What Is Built into the Framework?

NGF uses a highly cohesive and loosely coupled layered architecture to encapsulate complex capabilities into simple APIs:

- 🎨 **UI and Theme (uiTheme & uiShell)**: Includes 20 semantic color Tokens, with full support for dark mode switching, an immersive top title bar (HDS), and frosted-glass effects.
- 🪟 **Multi-Window, Cards, and Floating Windows (platformOhos)**: Supports not only flexible in-app floating windows (SubWindow), but also system-level desktop shortcuts (Shortcuts), desktop service cards (Widgets), and independent macro-level multitons (Multiton). With powerful shell containers built in, pages can be quickly mounted independently through simple AppStorage and Want parameters, whether inside the app or launched directly from the desktop, and cold-start multitons automatically take over the framework's global initialization!
- 🌍 **Internationalization (i18n)**: Supports language switching and relative time formatting ("just now", "2 hours ago").
- 💾 **Data and Storage (data)**: Provides simple wrappers for a true LRU in-memory cache, Preferences, and relational databases (RDB).
- ⚙️ **Workflow and Tasks (workflow & systemTasks)**: Supports complex asynchronous task orchestration, as well as long-running background tasks with a keep-alive lock and persistent system notification bar.
- 📱 **Device Awareness (deviceAwareness)**: Supports foldable-device adaptation, one-hand/two-hand holding awareness, and detection of 13 hardware capabilities.
- 🛠️ **Comprehensive Toolbox (utils)**: Includes performance monitoring, SHA/AES encryption and decryption security suites, a unified logging system, and more.

---

## 📁 Minimal Project Structure

```text
NGF/
 ├── ngf_framework/src/main/ets/  # 🛠️ Framework core package (HAR), all core capabilities are here
 ├── entry/src/main/ets/          # 📱 Your business App (HAP), write your pages and logic here
 │    └── pages/ngf/              # Framework's built-in demo pages (can be deleted when productizing)
 ├── .rules/                      # 🤖 Working rules and skill library for AI assistants
 ├── AGENTS.md                    # 📜 Global development constraints and Agent constitution
 └── build-profile.json5          # ⚙️ HarmonyOS project configuration
```

---

## 📚 More Documentation

| Document | Description |
|------|------|
| [Detailed Internal Framework Architecture](ngf_framework/src/main/ets/README.md) | For hardcore developers who want to understand the underlying implementation of NGF |
| [Framework Productization Guide](.rules/skill-app-release.md) | How to change the package name, apply for a certificate, and publish to Huawei AppGallery |

---

## 📄 License

This project is open source under the [MIT License](LICENSE).

```
Copyright (c) 2026 DaLongzhuazi

Anyone who obtains a copy of this software and related documentation is hereby granted free of charge the unrestricted right to use, copy, modify, merge,
publish, distribute, sublicense, or sell copies of the software, provided that the above copyright notice and this license notice are included.
The software is provided "as is" without any warranty of any kind.
```

---
*This framework is developed and maintained by **DaLongzhuazi**, with the goal of making it easy for every developer to build outstanding native HarmonyOS applications.*
