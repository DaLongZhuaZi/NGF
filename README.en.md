# NGF (Neon Genesis Framework)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![HarmonyOS SDK](https://img.shields.io/badge/HarmonyOS_SDK-6.1.0_(API_23)-blue.svg)](https://developer.harmonyos.com/)
[![Language](https://img.shields.io/badge/Language-ArkTS-orange.svg)]()

**🌐 Language / 语言:** English | [中文](README.md)

A reusable software development framework for HarmonyOS Next, featuring a 10-layer architecture that provides complete infrastructure from core bootstrapping and data management to internationalization and UI shell.

## Project Orientation

NGF is a **framework project**, not a single business app. All capabilities are designed with reusability, low coupling, and extensibility in mind, following a unified `contracts/` + `facades/` + `index.ets` pattern where each layer achieves loose coupling through a DI container and service registration.

---

## 🤖 Vibe Coding Friendly

This project is purpose-built for AI-assisted development workflows — Cursor, GitHub Copilot, Windsurf, Claude Code, and similar tools. Every pattern, contract, and facade is clearly documented and annotated so that LLMs can accurately understand and generate code that conforms to the framework conventions.

**🚀 Quick Start for AI Developers / LLMs**

Before starting any development task, read in this order:

| Step | File | Why It Matters |
|------|------|----------------|
| 1️⃣ | [AGENTS.md](AGENTS.md) | **Highest priority**: project-wide conventions, ArkTS constraints, layering principles, and prohibited patterns. All agents must read this. |
| 2️⃣ | [.rules/README.md](.rules/README.md) | Rules library index: discover what skill-rule files are available. |
| 3️⃣ | [.rules/skill-hds-page-design.md](.rules/skill-hds-page-design.md) | **Read before creating any new page**: immersive top bar, safe area, material/light-effect standard patterns. |
| 4️⃣ | [.rules/skill-manager-apis.md](.rules/skill-manager-apis.md) | **Read before using theme/i18n/visual-effects/holding-awareness**: reactive binding and listener lifecycle pairing patterns. |
| 5️⃣ | [.rules/skill-rules-update.md](.rules/skill-rules-update.md) | **Read when distilling new experience**: rules library update workflow (manually triggered by the developer). |

> **Note**: Rule files are not auto-triggered. Read the relevant skill file before starting the appropriate task. `AGENTS.md` takes precedence over the rules library; the rules library provides concrete skill supplements to `AGENTS.md`.

---

## Tech Stack

| Item | Version |
|------|---------|
| HarmonyOS SDK | 6.1.0 (API 23) |
| Build Tool | hvigorw |
| Language | ArkTS (Stage Mode) |
| UI Framework | ArkUI + HDS (HarmonyOS Design System) |
| Runtime | HarmonyOS |

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    EntryAbility                         │
│  ngfStarterKernel.bootstrap() → 8 modules boot by dep  │
├──────────┬──────────┬──────────┬──────────┬─────────────┤
│  core    │ platform │  data    │ workflow │contentSource│
│  95%     │  75%     │  90%     │  85%     │  85%        │
├──────────┼──────────┼──────────┼──────────┼─────────────┤
│ uiShell  │ uiTheme  │   i18n   │ device   │   utils     │
│  90%     │  90%     │  85%     │  85%     │   98%       │
└──────────┴──────────┴──────────┴──────────┴─────────────┘
```

## 10-Layer Architecture

| Layer | Responsibility | Completion | Key Capabilities |
|-------|---------------|------------|------------------|
| **core** | DI container, lifecycle orchestration, event bus, error handling, module registration | 95% | StarterKernel, DependencyContainer, ModuleBootstrapCoordinator, 8 default modules auto-registered |
| **platformOhos** | Window management, context bridging, system bar control | 75% | WindowStage management, PageWindowPolicy, UIContextManager |
| **data** | Cache, settings, storage, DB migration, data sync | 90% | RDB + Preferences + LRU cache + sync queue + conflict strategy |
| **contentWorkflow** | Workflow engine, action execution, retry/rate-limit policies | 85% | DSL workflow definition (serial + conditional branching), state persistence |
| **contentSource** | Content source registration, loading, repository, networking, health check | 85% | HTTP client, two-tier cache (memory LRU + disk), content pipeline, source health check |
| **uiShell** | Navigation shell, route interception, deep linking, page state | 90% | NavigationShell, RouteInterceptor, DeepLink, PageStateStore |
| **uiTheme** | Theme modes, semantic colors, font scaling | 90% | 20 semantic color tokens, 4-level font scaling, AUTO/LIGHT/DARK themes |
| **i18n** | Internationalization, translation resources, relative time | 85% | Translation resource management, multi-language relative time (zh/en/ja), date/number formatting |
| **deviceAwareness** | Holding awareness, device adaptation, visual effects, capability detection | 85% | Holding awareness, foldable adaptation, HDS visual effects, 13-item hardware capability detection |
| **utils** | Logging, performance monitoring, security tools, file operations | 98% | Logger + LogCollector, PerformanceMonitor, SecurityToolkit (SHA/AES-GCM), FileUtils |

## Boot Flow

```
EntryAbility.onCreate()
  → setContext(abilityContext)
  → uiContextManager.bindAbilityContext()
  → ngfStarterKernel.bootstrap()
      → context_setup: register core services to DependencyContainer
      → core_services: ModuleBootstrapCoordinator bootstraps 8 modules by dependency order
      → ready: publishes CORE_READY event
  → ThemeManagerFacade.initializeDefaults()
  → I18nManagerFacade.initializeDefaults()
  → HoldingAwarenessFacade.initialize()
  → VisualEffectsFacade.initialize()
```

## Module Registry

8 default modules auto-bootstrap during the `core_services` phase by priority:

| # | Module Name | Priority | Dependencies | Registered Services |
|---|-------------|----------|--------------|---------------------|
| 1 | `ngf.platform.ohos` | 10 | None | window_manager, window_controller, page_policy_resolver, context_bridge |
| 2 | `ngf.uiTheme.core` | 15 | platform | theme_manager, color_token_provider, font_scale_manager |
| 3 | `ngf.i18n.core` | 15 | platform | i18n_manager, translation_resource, relative_time |
| 4 | `ngf.data.core` | 20 | platform | data_facade, settings_store, cache_store, storage_provider, db_migrator, relational_store, sync_manager |
| 5 | `ngf.device.awareness` | 25 | platform | holding_awareness, adaptation, visual_effects, adaptive_layout, capability_detector |
| 6 | `ngf.workflow.core` | 30 | data | workflow_engine, action_executor, retry_policy, rate_limit_policy, definition_manager, persistence |
| 7 | `ngf.content_source.core` | 40 | data, workflow | source_repository, source_loader, source_registry, http_client, content_cache, content_pipeline, health_checker |
| 8 | `ngf.ui_shell.core` | 50 | platform | navigation_shell, page_policy_host, route_interceptor, deep_link, page_state_store |

## Demo Pages

Entry point: `pages/ngf/MainMenuPage` with 4 tabs:

### Tab 0 - Framework
- Framework status overview (core readiness, lifecycle, module bootstrap reports)
- Quick actions (initialize core, publish event, advance lifecycle, simulate error)
- Window monitoring (window state, display mode, snapshot data)
- Runtime logs

### Tab 1 - Feature Demos
| Page | Covered Features |
|------|-----------------|
| **Security & Performance** | SHA256/384/512 hashing, AES-GCM encrypt/decrypt, performance marks, memory snapshots |
| **Data & Storage** | FileUtils read/write, directory listing, ContentCache LRU operations |
| **Workflow Orchestration** | Workflow DSL registration & execution (with conditional branching), state persistence |
| **Device & Display** | Multi-language relative time, 13-item hardware capability detection, 4-level font scaling |

### Tab 2 - Device
- Holding awareness state, device info, foldable status, visual effects parameters

### Tab 3 - Settings
- Theme switching (AUTO/LIGHT/DARK), language switching, visual effects toggles, about info

### HDS Showcase Pages
| Page | Verified Capabilities |
|------|----------------------|
| Official HDS Navigation | Single-root navigation architecture, Material levels, hdsEffect point lights |
| HDS Integrated Showcase | Component + layout + motion single-page fusion, SegmentButton, Swiper carousel |

## Utilities (utils)

```typescript
// Logging
import { logger } from '../../Framework/NGF/utils/Logger';
logger.info(TAG, 'message');

// Performance Monitoring
import { performanceMonitor } from '../../Framework/NGF/utils/PerformanceMonitor';
performanceMonitor.mark('start');
performanceMonitor.mark('end');
const result = performanceMonitor.measure('name', 'start', 'end');
const snapshot = performanceMonitor.snapshotMemory();

// Security Toolkit
import { securityToolkit, NGFHashAlgorithm } from '../../Framework/NGF/utils/SecurityToolkit';
const hash = await securityToolkit.shaHash('input', NGFHashAlgorithm.SHA256);
const key = securityToolkit.generateRandomBase64(16);
const iv = securityToolkit.generateRandomBase64(12);
const encrypted = await securityToolkit.aesEncrypt('plain', key, iv);
const decrypted = await securityToolkit.aesDecrypt(encrypted.data, key, iv);

// File Operations
import { FileUtils } from '../../Framework/NGF/utils/FileUtils';
FileUtils.writeText('path.txt', 'content');
const content = FileUtils.readText('path.txt');
const entries = FileUtils.listDirectory('');
```

## Project Structure

```
entry/src/main/ets/
├── Framework/NGF/
│   ├── core/                    # Core Layer (95%)
│   │   ├── contracts/           # ILogger, IEventBus, IErrorHandler, ILifecycleOrchestrator...
│   │   ├── facades/             # LoggerFacade, ServiceContainerFacade, ModuleConfigFacade
│   │   ├── starter/             # StarterKernel, ModuleRegistry, ModuleBootstrapCoordinator
│   │   └── index.ets
│   ├── platformOhos/            # Platform Layer (75%)
│   │   ├── contracts/           # IPlatformWindowController, IPageWindowPolicyResolver...
│   │   ├── facades/             # PlatformWindowControllerFacade, OhosContextBridgeFacade...
│   │   └── index.ets
│   ├── data/                    # Data Layer (90%)
│   │   ├── contracts/           # IDataFacade, ISettingsStore, ICacheStore, ISyncManager...
│   │   ├── facades/             # DataFacade, SettingsStoreFacade, SyncManagerFacade...
│   │   └── index.ets
│   ├── contentWorkflow/         # Workflow Layer (85%)
│   │   ├── contracts/           # IWorkflowEngine, IWorkflowDefinitionManager, IWorkflowPersistence...
│   │   ├── facades/             # WorkflowEngineFacade, WorkflowDefinitionFacade...
│   │   └── index.ets
│   ├── contentSource/           # Content Source Layer (85%)
│   │   ├── contracts/           # ISourceRepository, IHttpClient, IContentCache, IContentPipeline...
│   │   ├── facades/             # SourceRepositoryFacade, ContentCacheFacade, HttpClientFacade...
│   │   └── index.ets
│   ├── uiShell/                 # UI Shell Layer (90%)
│   │   ├── contracts/           # INavigationShell, IRouteInterceptor, IDeepLinkHandler...
│   │   ├── components/          # NGFImmersiveTopChrome, HdsNavigationSupport
│   │   ├── facades/             # NavigationShellFacade, RouteInterceptorFacade...
│   │   └── index.ets
│   ├── uiTheme/                 # Theme Layer (90%)
│   │   ├── contracts/           # IThemeManager, IColorTokenProvider, IFontScaleManager
│   │   ├── facades/             # ThemeManagerFacade, FontScaleManagerFacade...
│   │   └── index.ets
│   ├── i18n/                    # i18n Layer (85%)
│   │   ├── contracts/           # II18nManager, ITranslationResource, IRelativeTimeFormatter
│   │   ├── facades/             # I18nManagerFacade, RelativeTimeFormatterFacade...
│   │   └── index.ets
│   ├── deviceAwareness/         # Device Awareness Layer (85%)
│   │   ├── contracts/           # IHoldingAwarenessManager, IDeviceAdaptationManager, IDeviceCapabilityDetector...
│   │   ├── facades/             # HoldingAwarenessFacade, DeviceCapabilityDetectorFacade...
│   │   └── index.ets
│   ├── utils/                   # Utilities (98%)
│   │   ├── Logger.ets           # Logging system
│   │   ├── PerformanceMonitor.ets # Performance monitoring
│   │   ├── SecurityToolkit.ets  # SHA/AES-GCM security tools
│   │   ├── FileUtils.ets        # File I/O
│   │   ├── TimeUtils.ets        # Time utilities
│   │   └── index.ets
│   └── index.ets                # Top-level re-export
└── pages/ngf/
    ├── MainMenuPage.ets         # Main entry (4 tabs)
    ├── HdsDemoRoutes.ets        # Route constants
    ├── NGFHdsTabRoutes.ets      # Tab configuration
    ├── NGFPageWindowSupport.ets # Window policy support
    ├── HdsNavigationOfficialShowcasePage.ets  # Official HDS demo
    ├── HdsIntegratedShowcasePage.ets          # Integrated HDS demo
    ├── NGFDeviceAwarenessPage.ets             # Device awareness page
    ├── NGFSettingsPage.ets                    # Settings page
    ├── NGFDemoSecurityPerfPage.ets            # Security & performance demo
    ├── NGFDemoDataStoragePage.ets             # Data & storage demo
    ├── NGFDemoWorkflowPage.ets                # Workflow orchestration demo
    └── NGFDemoDeviceDisplayPage.ets           # Device & display demo
```

## Design Patterns

### Unified Layering Pattern
Each layer follows the `contracts/` + `facades/` + `index.ets` structure:
- **contracts/** — Pure interfaces, enums, data classes (zero dependencies)
- **facades/** — Default implementations inheriting `NGFIntegrationFacadeBase`
- **index.ets** — Public API exports

### Integration Facade Pattern
Each integration facade implements a unified 3-step lifecycle:
1. `getServiceRegistrations()` — Declare service registration items
2. `bootstrap()` — Auto-register to DI container + ServiceContainer
3. `syncAppStorage()` — Sync state to AppStorage

### Module Bootstrap Pattern
`ModuleBootstrapCoordinator` manages the module dependency graph, bootstrapping modules in topological order. Modules declare dependencies and service tokens via `NGFModuleDefinition`, and bootstrap results are broadcast through the event bus.

## Build

```bash
hvigorw assembleHap            # Debug build
hvigorw assembleHap --release  # Release build
hvigorw clean                  # Clean
```

## Documentation

| Document | Description |
|----------|-------------|
| [AGENTS.md](AGENTS.md) | **Agent working guidelines (highest priority — all AI agents must read)** |
| [.rules/ Library](.rules/README.md) | AI skill rules: HDS page design, manager APIs, rules rolling update |
| [Framework README](entry/src/main/ets/Framework/NGF/README.md) | Internal framework architecture |
| [Framework Status Analysis](docs/NGF_FRAMEWORK_STATUS.md) | Layer completion & feature gaps |
| [Implementation Plan](docs/development/NGF_IMPLEMENTATION_PLAN.md) | Development roadmap |
| [API 23 Migration Guide](docs/API23_Migration_Guide.md) | API 23 adaptation notes |
| [Changelog](docs/CHANGELOG.md) | Version change log |

## License

This project is licensed under the [MIT License](LICENSE).

```
Copyright (c) 2026 DaLongzhuazi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

*NGF is developed and maintained by **DaLongzhuazi** as a general-purpose framework infrastructure for the HarmonyOS Next ecosystem.*
