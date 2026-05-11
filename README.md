# NGF (Neon Genesis Framework)

面向 HarmonyOS Next 的可复用软件开发框架，采用 10 层分层架构，提供从核心启动、数据管理、国际化到 UI 壳层的完整基础设施。

## 项目定位

NGF 是一个**框架工程**，不是单一业务 App。所有能力以"可复用、低耦合、可扩展"为目标设计，遵循 `contracts/` + `facades/` + `index.ets` 统一模式，每层通过 DI 容器 + 服务注册实现松耦合依赖。

## 技术栈

| 项目 | 版本 |
|------|------|
| HarmonyOS SDK | 6.1.0 (API 23) |
| 构建工具 | hvigorw |
| 开发语言 | ArkTS (Stage 模式) |
| UI 框架 | ArkUI + HDS (HarmonyOS Design System) |
| 运行时 | HarmonyOS |

## 架构总览

```
┌─────────────────────────────────────────────────────────┐
│                    EntryAbility                         │
│  ngfStarterKernel.bootstrap() → 8 模块按依赖顺序启动     │
├──────────┬──────────┬──────────┬──────────┬──────────────┤
│  core    │ platform │  data    │ workflow │ contentSource│
│  95%     │  75%     │  90%     │  85%     │  85%         │
├──────────┼──────────┼──────────┼──────────┼──────────────┤
│ uiShell  │ uiTheme  │   i18n   │ device   │    utils     │
│  90%     │  90%     │  85%     │  85%     │    98%       │
└──────────┴──────────┴──────────┴──────────┴──────────────┘
```

## 10 层架构详解

| 层 | 职责 | 完成度 | 核心能力 |
|---|------|--------|----------|
| **core** | DI 容器、生命周期编排、事件总线、错误处理、模块注册 | 95% | StarterKernel、DependencyContainer、ModuleBootstrapCoordinator、8 个默认模块自动注册 |
| **platformOhos** | 窗口管理、上下文桥接、系统栏控制 | 75% | WindowStage 管理、PageWindowPolicy、UIContextManager |
| **data** | 缓存、设置、存储、数据库迁移、数据同步 | 90% | RDB + Preferences + LRU 缓存 + 同步队列 + 冲突策略 |
| **contentWorkflow** | 工作流引擎、动作执行、重试/限流策略 | 85% | DSL 工作流定义（串行+条件分支）、状态持久化 |
| **contentSource** | 内容源注册、加载、仓储、网络、健康检查 | 85% | HTTP 客户端、二级缓存（内存LRU+磁盘）、内容管道、源健康检查 |
| **uiShell** | 导航壳层、路由拦截、深链接、页面状态 | 90% | NavigationShell、RouteInterceptor、DeepLink、PageStateStore |
| **uiTheme** | 主题模式、语义色、字体缩放 | 90% | 20 个语义色 Token、4 级字体缩放、AUTO/LIGHT/DARK 主题 |
| **i18n** | 国际化、翻译资源、相对时间 | 85% | 翻译资源管理、多语言相对时间（zh/en/ja）、日期/数字格式 |
| **deviceAwareness** | 握持感知、设备适配、视觉效果、能力检测 | 85% | 握持感知、折叠屏适配、HDS 视觉效果、13 项硬件能力检测 |
| **utils** | 日志、性能监控、安全工具、文件操作 | 98% | Logger + LogCollector、PerformanceMonitor、SecurityToolkit（SHA/AES-GCM）、FileUtils |

## 启动流程

```
EntryAbility.onCreate()
  → setContext(abilityContext)
  → uiContextManager.bindAbilityContext()
  → ngfStarterKernel.bootstrap()
      → context_setup: 注册核心服务到 DependencyContainer
      → core_services: ModuleBootstrapCoordinator 按依赖顺序引导 8 个模块
      → ready: 发布 CORE_READY 事件
  → ThemeManagerFacade.initializeDefaults()
  → I18nManagerFacade.initializeDefaults()
  → HoldingAwarenessFacade.initialize()
  → VisualEffectsFacade.initialize()
```

## 模块注册表

8 个默认模块在 `core_services` 阶段按优先级自动引导：

| # | 模块名 | 优先级 | 依赖 | 注册的服务 |
|---|--------|--------|------|-----------|
| 1 | `ngf.platform.ohos` | 10 | 无 | window_manager, window_controller, page_policy_resolver, context_bridge |
| 2 | `ngf.uiTheme.core` | 15 | platform | theme_manager, color_token_provider, font_scale_manager |
| 3 | `ngf.i18n.core` | 15 | platform | i18n_manager, translation_resource, relative_time |
| 4 | `ngf.data.core` | 20 | platform | data_facade, settings_store, cache_store, storage_provider, db_migrator, relational_store, sync_manager |
| 5 | `ngf.device.awareness` | 25 | platform | holding_awareness, adaptation, visual_effects, adaptive_layout, capability_detector |
| 6 | `ngf.workflow.core` | 30 | data | workflow_engine, action_executor, retry_policy, rate_limit_policy, definition_manager, persistence |
| 7 | `ngf.content_source.core` | 40 | data, workflow | source_repository, source_loader, source_registry, http_client, content_cache, content_pipeline, health_checker |
| 8 | `ngf.ui_shell.core` | 50 | platform | navigation_shell, page_policy_host, route_interceptor, deep_link, page_state_store |

## 演示页面

启动入口: `pages/ngf/MainMenuPage`，包含 4 个 Tab 页签：

### Tab 0 - 框架
- 框架状态概览（核心就绪、生命周期、模块启动报告）
- 快速操作（初始化核心、发布事件、推进生命周期、触发错误）
- 窗口监控（窗口状态、显示模式、快照数据）
- 运行日志

### Tab 1 - 功能演示
| 页面 | 覆盖功能 |
|------|----------|
| **安全与性能** | SHA256/384/512 哈希、AES-GCM 加解密、性能打点、内存快照 |
| **数据与存储** | FileUtils 文件读写、目录操作、ContentCache LRU 缓存 |
| **流程编排** | 工作流 DSL 注册与执行（含条件分支）、状态持久化 |
| **设备与显示** | 多语言相对时间、13 项硬件能力检测、4 级字体缩放 |

### Tab 2 - 设备
- 握持感知状态、设备信息、折叠屏状态、视觉效果参数

### Tab 3 - 设置
- 主题切换（AUTO/LIGHT/DARK）、语言切换、视觉效果开关、关于信息

### HDS 展示页面
| 页面 | 验证内容 |
|------|----------|
| 官方 HDS Navigation 示例 | 单根导航架构、Material 等级、hdsEffect 光效 |
| HDS 综合融合示例 | 组件+布局+动效单页融合、SegmentButton、Swiper 轮播 |

## 工具集 (utils)

```typescript
// 日志
import { logger } from '../../Framework/NGF/utils/Logger';
logger.info(TAG, 'message');

// 性能监控
import { performanceMonitor } from '../../Framework/NGF/utils/PerformanceMonitor';
performanceMonitor.mark('start');
performanceMonitor.mark('end');
const result = performanceMonitor.measure('name', 'start', 'end');
const snapshot = performanceMonitor.snapshotMemory();

// 安全工具
import { securityToolkit, NGFHashAlgorithm } from '../../Framework/NGF/utils/SecurityToolkit';
const hash = await securityToolkit.shaHash('input', NGFHashAlgorithm.SHA256);
const key = securityToolkit.generateRandomBase64(16);
const iv = securityToolkit.generateRandomBase64(12);
const encrypted = await securityToolkit.aesEncrypt('plain', key, iv);
const decrypted = await securityToolkit.aesDecrypt(encrypted.data, key, iv);

// 文件操作
import { FileUtils } from '../../Framework/NGF/utils/FileUtils';
FileUtils.writeText('path.txt', 'content');
const content = FileUtils.readText('path.txt');
const entries = FileUtils.listDirectory('');
```

## 项目结构

```
entry/src/main/ets/
├── Framework/NGF/
│   ├── core/                    # 核心层 (95%)
│   │   ├── contracts/           # ILogger, IEventBus, IErrorHandler, ILifecycleOrchestrator...
│   │   ├── facades/             # LoggerFacade, ServiceContainerFacade, ModuleConfigFacade
│   │   ├── starter/             # StarterKernel, ModuleRegistry, ModuleBootstrapCoordinator
│   │   └── index.ets
│   ├── platformOhos/            # 平台层 (75%)
│   │   ├── contracts/           # IPlatformWindowController, IPageWindowPolicyResolver...
│   │   ├── facades/             # PlatformWindowControllerFacade, OhosContextBridgeFacade...
│   │   └── index.ets
│   ├── data/                    # 数据层 (90%)
│   │   ├── contracts/           # IDataFacade, ISettingsStore, ICacheStore, ISyncManager...
│   │   ├── facades/             # DataFacade, SettingsStoreFacade, SyncManagerFacade...
│   │   └── index.ets
│   ├── contentWorkflow/         # 工作流层 (85%)
│   │   ├── contracts/           # IWorkflowEngine, IWorkflowDefinitionManager, IWorkflowPersistence...
│   │   ├── facades/             # WorkflowEngineFacade, WorkflowDefinitionFacade...
│   │   └── index.ets
│   ├── contentSource/           # 内容源层 (85%)
│   │   ├── contracts/           # ISourceRepository, IHttpClient, IContentCache, IContentPipeline...
│   │   ├── facades/             # SourceRepositoryFacade, ContentCacheFacade, HttpClientFacade...
│   │   └── index.ets
│   ├── uiShell/                 # UI 壳层 (90%)
│   │   ├── contracts/           # INavigationShell, IRouteInterceptor, IDeepLinkHandler...
│   │   ├── components/          # NGFImmersiveTopChrome, HdsNavigationSupport
│   │   ├── facades/             # NavigationShellFacade, RouteInterceptorFacade...
│   │   └── index.ets
│   ├── uiTheme/                 # 主题层 (90%)
│   │   ├── contracts/           # IThemeManager, IColorTokenProvider, IFontScaleManager
│   │   ├── facades/             # ThemeManagerFacade, FontScaleManagerFacade...
│   │   └── index.ets
│   ├── i18n/                    # 国际化层 (85%)
│   │   ├── contracts/           # II18nManager, ITranslationResource, IRelativeTimeFormatter
│   │   ├── facades/             # I18nManagerFacade, RelativeTimeFormatterFacade...
│   │   └── index.ets
│   ├── deviceAwareness/         # 设备感知层 (85%)
│   │   ├── contracts/           # IHoldingAwarenessManager, IDeviceAdaptationManager, IDeviceCapabilityDetector...
│   │   ├── facades/             # HoldingAwarenessFacade, DeviceCapabilityDetectorFacade...
│   │   └── index.ets
│   ├── utils/                   # 工具集 (98%)
│   │   ├── Logger.ets           # 日志系统
│   │   ├── PerformanceMonitor.ets # 性能监控
│   │   ├── SecurityToolkit.ets  # SHA/AES-GCM 安全工具
│   │   ├── FileUtils.ets        # 文件读写
│   │   ├── TimeUtils.ets        # 时间工具
│   │   └── index.ets
│   └── index.ets                # 顶层统一导出
└── pages/ngf/
    ├── MainMenuPage.ets         # 主入口 (4 Tab)
    ├── HdsDemoRoutes.ets        # 路由常量
    ├── NGFHdsTabRoutes.ets      # Tab 配置
    ├── NGFPageWindowSupport.ets # 窗口策略
    ├── HdsNavigationOfficialShowcasePage.ets  # HDS 官方示例
    ├── HdsIntegratedShowcasePage.ets          # HDS 综合示例
    ├── NGFDeviceAwarenessPage.ets             # 设备感知页
    ├── NGFSettingsPage.ets                    # 设置页
    ├── NGFDemoSecurityPerfPage.ets            # 安全与性能演示
    ├── NGFDemoDataStoragePage.ets             # 数据与存储演示
    ├── NGFDemoWorkflowPage.ets                # 流程编排演示
    └── NGFDemoDeviceDisplayPage.ets           # 设备与显示演示
```

## 设计模式

### 统一分层模式
每层遵循 `contracts/` + `facades/` + `index.ets` 结构：
- **contracts/** — 纯接口、枚举、数据类（零依赖）
- **facades/** — 默认实现，继承 `NGFIntegrationFacadeBase`
- **index.ets** — 公开 API 导出

### 集成门面模式
每个集成门面统一实现三步生命周期：
1. `getServiceRegistrations()` — 声明服务注册项
2. `bootstrap()` — 自动注册到 DI 容器 + ServiceContainer
3. `syncAppStorage()` — 同步状态到 AppStorage

### 模块启动模式
`ModuleBootstrapCoordinator` 管理模块依赖图，按拓扑排序自动引导。模块通过 `NGFModuleDefinition` 声明依赖和服务令牌，启动结果通过事件总线广播。

## 构建

```bash
hvigorw assembleHap            # Debug 构建
hvigorw assembleHap --release  # Release 构建
hvigorw clean                  # 清理
```

## 文档

| 文档 | 说明 |
|------|------|
| [框架 README](entry/src/main/ets/Framework/NGF/README.md) | 框架内部架构详解 |
| [框架状态分析](docs/NGF_FRAMEWORK_STATUS.md) | 各层完成度与功能缺口 |
| [实施计划](docs/development/NGF_IMPLEMENTATION_PLAN.md) | 开发路线图 |
| [API 23 迁移指南](docs/API23_Migration_Guide.md) | API 23 适配说明 |
| [变更日志](docs/CHANGELOG.md) | 版本变更记录 |
| [AGENTS.md](AGENTS.md) | 代理工作规范 |

## 许可证

本项目为内部框架工程项目。
