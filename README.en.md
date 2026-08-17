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

## 🔧 Cloud CI Builds (GitHub Actions)

Three workflows under `.github/workflows/` provide a push-to-build HAP pipeline, just like Android APK CI — **no DevEco Studio required**, with automatic build and automatic release on push. See the detailed [CI Build Guide](docs/CI_Guide.en.md) / [CI 构建指南](docs/CI_Guide.md):

| Workflow | Trigger | Purpose |
|---|---|---|
| `docker-image.yml` | Manual (workflow_dispatch) | One-time build of the API 26 CI image (command-line-tools) pushed to ghcr.io |
| `build.yml` | push `main`/`master`, PR | Debug build of an **unsigned** HAP uploaded as artifact (`hap-unsigned`); **auto-publishes a rolling `nightly` Release on push** |
| `sign-and-release.yml` | push `v*` tag | Build → sign with hap-sign-tool → publish a GitHub Release (secrets required) |

### First-time setup (one-time, ~15 minutes)

1. **Prepare the CI image**:
   1. Obtain the **Linux (x86-64)** command-line-tools zip matching API 26, from either source:
      - **Community mirror (recommended, stable public links)**: the `v26.0.0.461` release of [jerry-271828/harmonyos-commandline-tools](https://github.com/jerry-271828/harmonyos-commandline-tools) ships the zip split into two parts (`clt.zip.part00` / `clt.zip.part01`); pass **both URLs separated by a space** and the Dockerfile concatenates them automatically;
      - **Official**: download from the ["Obtaining Command Line Tools"](https://developer.huawei.com/consumer/en/doc/harmonyos-guides/ide-commandline-get) page (links are short-lived; re-host the zip first);
   2. Upload the zip somewhere directly fetchable (a GitHub Release asset, object storage, etc.);
   3. Add the repository secret `CLT_ZIP_URL` (direct zip URL) under Settings → Secrets and variables → Actions;
   4. Manually run the **Build CI image** workflow once, producing `ghcr.io/<owner>/harmonyos-ci:api26`. `build.yml` then uses that pinned tag, keeping builds reproducible.
2. **Done**: every push to the main branches now **builds automatically and auto-publishes a rolling `nightly` Release** (PRs build only, without releasing); download the `hap-unsigned` artifact / asset from the Action or Releases page (contains `entry-default-unsigned.hap`, installable after re-signing in DevEco Studio).

> **Signing note**: `signingConfigs` in `build-profile.json5` points to developer-local certificate paths; CI strips it automatically via `.github/scripts/strip_signing.py` and produces **unsigned** HAPs — local signed builds are unaffected. This repo has no git submodules; if one is added later, enable `submodules: recursive` in the checkout step.

### Optional: signing & versioned Release

> The unsigned **rolling `nightly` Release is already enabled by default** (updated on every push). This section covers **signed + versioned** releases triggered by `v*` tags.

Pushing a `v*` tag triggers `sign-and-release.yml`. Required secrets (certificate/key files stored **base64-encoded**, never committed; `.gitignore` already blocks certificate file types):

| Secret | Content |
|---|---|
| `SIGNING_CERT` | `.cer` certificate, base64 (single line via `base64 -w 0`) |
| `SIGNING_PROFILE` | `.p7b` signing profile, base64 |
| `SIGNING_KEY` | `.p12` keystore file, base64 |
| `SIGNING_KEY_ALIAS` | Key alias (plain text) |
| `KEYSTORE_PASSWORD` / `KEY_PASSWORD` | Keystore / key passwords (plain text) |
| `CLT_ZIP_URL` | (for `docker-image.yml`) command-line-tools zip direct URL |

When signing secrets are not configured, tag builds **skip signing with a guidance notice** instead of failing.

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
