# NGF Framework

NGF (Neon Genesis Framework) 是面向 HarmonyOS Next 的可复用软件开发框架。

## 架构分层

```
NGF/
├── core/                # 核心层: 契约、DI、生命周期、启动内核
│   ├── contracts/       # ILogger, IEventBus, IErrorHandler, ILifecycleOrchestrator,
│   │                    # IServiceContainer, IModuleBootstrap, INGFService
│   ├── facades/         # LoggerFacade, ServiceContainerFacade, NGFIntegrationFacadeBase
│   └── starter/         # StarterKernel, ModuleRegistry, ModuleBootstrapCoordinator
│
├── platformOhos/        # 平台层: HarmonyOS 窗口/上下文桥接
│   ├── contracts/       # IPlatformWindowManager, IPlatformWindowController,
│   │                    # IPageWindowPolicyResolver, IOhosContextBridge
│   └── facades/         # PlatformWindowManagerFacade, OhosContextBridgeFacade, ...
│
├── data/                # 数据层: 缓存、设置、存储、迁移
│   ├── contracts/       # IDataFacade, ISettingsStore, ICacheStore, IStorageProvider, IDbMigrator
│   └── facades/         # DataFacade, SettingsStoreFacade, CacheStoreFacade, ...
│
├── contentWorkflow/     # 工作流层: 动作执行、重试、限流
│   ├── contracts/       # IWorkflowEngine, IActionExecutor, IRetryPolicy, IRateLimitPolicy
│   └── facades/         # WorkflowEngineFacade, ActionExecutorFacade, ...
│
├── contentSource/       # 内容源层: 源注册、加载、仓储
│   ├── contracts/       # ISourceRegistry, ISourceLoader, ISourceRepository
│   └── facades/         # SourceRegistryFacade, SourceLoaderFacade, SourceRepositoryFacade
│
├── uiShell/             # UI 壳层: 导航、页面策略、HDS 组件
│   ├── contracts/       # INavigationShell, IPagePolicyHost
│   ├── facades/         # NavigationShellFacade, PagePolicyHostFacade
│   └── components/      # HdsNavigationSupport, NGFImmersiveTopChrome, NGFHdsTabsFactory
│
├── uiTheme/             # 主题层: 颜色模式管理
│   ├── contracts/       # IThemeManager
│   └── facades/         # ThemeManagerFacade
│
├── i18n/                # 国际化层: 语言、日期/数字格式
│   ├── contracts/       # II18nManager
│   └── facades/         # I18nManagerFacade
│
├── deviceAwareness/     # 设备感知层: 握持、折叠、视觉效果
│   ├── contracts/       # IHoldingAwarenessManager, IDeviceAdaptationManager, IVisualEffectsManager
│   └── facades/         # HoldingAwarenessFacade, DeviceAdaptationFacade, VisualEffectsFacade
│
├── utils/               # 工具层: 日志、时间、错误处理
│   ├── Logger.ets       # 多级日志 (hilog 桥接)
│   ├── LogCollector.ets # 环形缓冲日志收集器
│   ├── TimeUtils.ets    # 时间格式化
│   └── ErrorUtils.ets   # 错误转换/分类
│
├── DependencyContainer.ets  # DI 容器 (singleton/transient)
└── index.ets            # 统一导出
```

## 启动流程

```
EntryAbility.onCreate()
  → setContext(abilityContext)
  → uiContextManager.bindAbilityContext()
  → ngfStarterKernel.bootstrap()
      → context_setup: 注册核心服务到 DependencyContainer
      → core_services: ModuleBootstrapCoordinator 按依赖顺序引导 8 个模块
          1. ngf.platform.ohos (order=10)
          2. ngf.uiTheme.core (order=15, depends: platform)
          3. ngf.i18n.core (order=15, depends: platform)
          4. ngf.data.core (order=20, depends: platform)
          5. ngf.device.awareness (order=25, depends: platform)
          6. ngf.workflow.core (order=30, depends: data)
          7. ngf.content_source.core (order=40, depends: data, workflow)
          8. ngf.ui_shell.core (order=50, depends: platform)
      → ready: 发布 CORE_READY 事件
  → ThemeManagerFacade.initializeDefaults()
  → I18nManagerFacade.initializeDefaults()
  → HoldingAwarenessFacade.initialize()
  → VisualEffectsFacade.initialize()
```

## 模式约定

每层遵循统一模式:
- **contracts/**: 纯接口/枚举/数据类，定义该层的抽象契约
- **facades/**: 契约的默认实现，继承 `NGFIntegrationFacadeBase` 统一引导
- **index.ets**: 导出该层的公共 API

集成 Facade 通过 `NGFIntegrationFacadeBase` 统一:
1. `getServiceRegistrations()` 返回服务注册列表
2. `bootstrap()` 自动注册到 DependencyContainer + ServiceContainer
3. `syncAppStorage()` 同步引导状态到 AppStorage

## 详细文档

- [框架现状与功能缺口分析](../../../../docs/NGF_FRAMEWORK_STATUS.md)
- [实施计划](../../../../docs/development/NGF_IMPLEMENTATION_PLAN.md)
- [API 23 迁移指南](../../../../docs/API23_Migration_Guide.md)
