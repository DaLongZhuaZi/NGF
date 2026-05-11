# NGF 框架现状与功能缺口分析

> 最后更新: 2026-05-08

## 一、框架概述

NGF (Neon Genesis Framework) 是一个面向 HarmonyOS Next 的可复用软件开发框架，采用分层架构设计，目标是为上层业务应用提供通用的基础设施能力，包括核心运行时、平台桥接、数据管理、内容处理、UI 壳层、主题、国际化、设备感知等。

**当前定位**: 框架骨架已建立、运行时兼容层待补完的阶段。已完成 API 23 适配。

## 二、当前架构分层

```
entry/src/main/ets/Framework/NGF/
├── core/                    # 核心层 - 契约、生命周期、DI、启动内核
├── platformOhos/            # 平台层 - HarmonyOS 窗口/上下文桥接
├── data/                    # 数据层 - 缓存、设置、存储、迁移
├── contentWorkflow/         # 工作流层 - 动作执行、重试、限流
├── contentSource/           # 内容源层 - 源注册、加载、仓储
├── uiShell/                 # UI 壳层 - 导航、页面策略、HDS 组件
├── uiTheme/                 # 主题层 - 颜色模式、主题管理
├── i18n/                    # 国际化层 - 语言、日期/数字格式
├── deviceAwareness/         # 设备感知层 - 握持、折叠、视觉效果
└── utils/                   # 工具层 - 日志、时间、错误处理
```

每层遵循统一模式: `contracts/` (接口) + `facades/` (门面实现) + `index.ets` (导出)

## 三、各层完成度评估

### 3.1 core (核心层) - 完成度: 95%

| 能力 | 状态 | 说明 |
|------|------|------|
| ILogger 契约 | 已完成 | 含 debug/info/warn/error/lifecycle/stateChange |
| IEventBus 契约 | 已完成 | pub/sub 模式，按事件名+监听器ID管理 |
| IErrorHandler 契约 | 已完成 | 含错误分级、恢复策略注册 |
| ILifecycleOrchestrator | 已完成 | 分阶段推进 (context_setup → core_services → ready) |
| IServiceContainer | 已完成 | registerSingleton/resolve/contains |
| IModuleBootstrap | 已完成 | 模块定义、引导结果、运行时快照 |
| INGFService | 已完成 | 服务标记接口，含生命周期状态枚举 |
| DependencyContainer | 已完成 | 真正的 DI 容器，支持 singleton/transient |
| StarterKernel | 已完成 | 单例启动内核，编排所有模块引导 |
| ModuleRegistry | 已完成 | 模块注册表，按阶段排序 |
| ModuleBootstrapCoordinator | 已完成 | 自动注册 8 个默认模块并按依赖顺序引导 |
| LoggerFacade | 已完成 | 实现 ILogger，桥接 utils/Logger |
| ServiceContainerFacade | 已完成 | 实现 IServiceContainer |
| NGFIntegrationFacadeBase | 已完成 | 抽象基类，统一 bootstrap + DI 注册 + AppStorage 同步 |

**已完成**:
- ✅ 服务生命周期管理 (DependencyContainer 自动调用 initialize/destroy)
- ✅ 模块启用/禁用配置 (IModuleConfig JSON 配置驱动的模块开关)

**缺口**:
- 缺少模块热重载/卸载能力

### 3.2 platformOhos (平台层) - 完成度: 75%

| 能力 | 状态 | 说明 |
|------|------|------|
| IPlatformWindowManager | 已完成 | 窗口绑定、系统栏、方向、快照 |
| IPlatformWindowController | 已完成 | 显示模式控制 |
| IPageWindowPolicyResolver | 已完成 | 页面级窗口策略解析 |
| IOhosContextBridge | 已完成 | AbilityContext 桥接 |
| UIContextManager | 已完成 | UIContext 绑定/清除 |
| IntegrationFacade | 已完成 | 含 4 个子 facade 的统一引导 |

**缺口**:
- 缺少窗口生命周期事件的事件总线集成
- 缺少多窗口/分屏场景的策略支持
- 缺少窗口尺寸/位置的编程式控制接口

### 3.3 data (数据层) - 完成度: 90%

| 能力 | 状态 | 说明 |
|------|------|------|
| IDataFacade | 已完成 | 通用数据查询结果封装 |
| ISettingsStore | 已完成 | 设置读写契约 |
| ICacheStore | 已完成 | 缓存管理契约 |
| IStorageProvider | 已完成 | 存储提供者契约 |
| IDbMigrator | 已完成 | 数据库迁移契约 |
| ISyncManager | 已完成 | 数据同步契约 |
| SettingsManager | 已完成 | 设置管理单例 |
| SandboxManager | 已完成 | 沙箱存储管理 |
| IntegrationFacade | 已完成 | 含 7 个子 facade |

**已完成**:
- ✅ RDB 数据库实现 (RelationalStoreFacade + DbMigrator 真实 RDB 迁移)
- ✅ Preferences 持久化 (SettingsManager 基于 @ohos.data.preferences)
- ✅ 数据同步机制 (ISyncManager + SyncManagerFacade 离线队列 + 冲突策略)

**缺口**:
- 缺少数据加密/脱敏能力
- 缺少大数据量的分页/流式读取

### 3.4 contentWorkflow (工作流层) - 完成度: 85%

| 能力 | 状态 | 说明 |
|------|------|------|
| IWorkflowEngine | 已完成 | 工作流执行引擎契约 |
| IActionExecutor | 已完成 | 动作执行器契约 |
| IRetryPolicy | 已完成 | 重试策略契约 |
| IRateLimitPolicy | 已完成 | 限流策略契约 |
| IWorkflowPersistence | 已完成 | 工作流持久化契约 |
| IntegrationFacade | 已完成 | 含 6 个子 facade |

**已完成**:
- ✅ 工作流 DSL (IWorkflowDefinitionManager 支持 JSON 定义的多步骤串行工作流 + 条件分支)
- ✅ 工作流持久化 (IWorkflowPersistence + WorkflowPersistenceFacade 基于 SettingsManager 的状态保存/恢复)

**缺口**:
- 缺少并行步骤编排
- 缺少循环、超时等控制流
- 缺少工作流可视化调试工具

### 3.5 contentSource (内容源层) - 完成度: 85%

| 能力 | 状态 | 说明 |
|------|------|------|
| ISourceRegistry | 已完成 | 内容源注册契约 |
| ISourceLoader | 已完成 | 内容源加载契约 |
| ISourceRepository | 已完成 | 内容源仓储契约 |
| ISourceHealthChecker | 已完成 | 内容源健康检查契约 |
| IntegrationFacade | 已完成 | 含 7 个子 facade |

**已完成**:
- ✅ HTTP 客户端抽象 (IHttpClient + HttpClientFacade 基于 @ohos.net.http)
- ✅ 内容二级缓存 (IContentCache + ContentCacheFacade 内存 LRU + 磁盘持久化)
- ✅ 内容解析管道 (IContentPipeline 支持 fetch/parse/transform/cache 步骤)
- ✅ 内容源健康检查 (ISourceHealthChecker + SourceHealthCheckerFacade 含延迟阈值降级检测)

**缺口**:
- 缺少内容源的配置化管理 (JSON/YAML 配置驱动)

### 3.6 uiShell (UI 壳层) - 完成度: 90%

| 能力 | 状态 | 说明 |
|------|------|------|
| INavigationShell | 已完成 | 导航壳层契约 |
| IPagePolicyHost | 已完成 | 页面策略宿主契约 |
| IPageStateStore | 已完成 | 页面状态存储契约 |
| HdsNavigationSupport | 已完成 | HDS 标题栏工厂、沉浸式底板 |
| NGFImmersiveTopChrome | 已完成 | 沉浸式顶部 Chrome 组件 |
| NGFHdsTabsFactory | 已完成 | HDS Tabs 工厂 |
| IntegrationFacade | 已完成 | 含 5 个子 facade |

**已完成**:
- ✅ 路由拦截器 (IRouteInterceptor + RouteInterceptorFacade 支持拦截/重定向/参数修改)
- ✅ 深链接支持 (IDeepLinkHandler URL scheme → 页面路由映射，含路径参数和查询参数解析)
- ✅ 页面状态保存/恢复 (IPageStateStore + PageStateStoreFacade 基于 SettingsManager 的状态持久化)

**缺口**:
- 缺少页面转场动画的统一管理
- 缺少通用的列表页、表单页、详情页模板组件

### 3.7 uiTheme (主题层) - 完成度: 90%

| 能力 | 状态 | 说明 |
|------|------|------|
| IThemeManager | 已完成 | 主题模式管理 (SYSTEM/LIGHT/DARK) |
| IFontScaleManager | 已完成 | 动态字体缩放管理 |
| 系统颜色模式监听 | 已完成 | onConfigurationUpdate 集成 |
| IntegrationFacade | 已完成 | 含 3 个子 facade |

**已完成**:
- ✅ 颜色 Token 体系 (IColorTokenProvider 20 个语义化颜色，light/dark 自动切换)
- ✅ 动态字体大小调节 (IFontScaleManager 4 级预设 + 自定义缩放 0.5x-2.0x)

**缺口**:
- 缺少自定义主题包/主题切换能力
- 缺少组件级主题覆盖机制

### 3.8 i18n (国际化层) - 完成度: 85%

| 能力 | 状态 | 说明 |
|------|------|------|
| II18nManager | 已完成 | 语言、日期格式、数字格式管理 |
| ITranslationResource | 已完成 | 翻译资源管理 |
| IRelativeTimeFormatter | 已完成 | 相对时间格式化 (zh/en/ja) |
| 系统语言监听 | 已完成 | onConfigurationUpdate 集成 |
| IntegrationFacade | 已完成 | 含 3 个子 facade |

**已完成**:
- ✅ 翻译资源管理 (ITranslationResource JSON 翻译文件加载、键值查找、缺失键报告)
- ✅ 相对时间格式化 (IRelativeTimeFormatter 支持 zh/en/ja，含复数形式)

**缺口**:
- 缺少 RTL (从右到左) 布局支持
- 缺少翻译键值的类型安全检查

### 3.9 deviceAwareness (设备感知层) - 完成度: 85%

| 能力 | 状态 | 说明 |
|------|------|------|
| IHoldingAwarenessManager | 已完成 | 握持姿态感知 |
| IDeviceAdaptationManager | 已完成 | 设备类型、折叠状态、屏幕方向 |
| IVisualEffectsManager | 已完成 | 视觉效果能力检测与配置 |
| IDeviceCapabilityDetector | 已完成 | 硬件能力检测 (摄像头/传感器/NFC 等) |
| IntegrationFacade | 已完成 | 含 5 个子 facade |

**已完成**:
- ✅ 自适应布局断点系统 (IAdaptiveLayout 基于 XS/SM/MD/LG 断点的响应式配置)
- ✅ 设备能力检测 (IDeviceCapabilityDetector 13 项硬件能力检测)

**缺口**:
- 缺少无障碍 (Accessibility) 能力封装

### 3.10 utils (工具层) - 完成度: 98%

| 能力 | 状态 | 说明 |
|------|------|------|
| Logger | 已完成 | 多级日志、hilog 桥接、环形缓冲收集器 |
| LogCollector | 已完成 | 环形缓冲、过滤、统计、监听 |
| TimeUtils | 已完成 | 时间格式化 |
| ErrorUtils | 已完成 | 错误转换、分类、格式化 |
| FileUtils | 已完成 | 文件读写、目录操作、复制/移动/删除 |

**已完成**:
- ✅ 性能监控 (PerformanceMonitor 打点、测量、内存快照、hilog 输出)
- ✅ 安全工具 (SecurityToolkit SHA256/384/512 哈希、AES-GCM 加密/解密、随机数生成)
- ✅ 文件操作工具 (FileUtils 文本/二进制读写、目录遍历、复制/移动/删除)

**缺口**:
- 缺少正则/字符串处理工具集

## 四、演示与验证页

当前已有的演示页面:

| 页面 | 文件 | 验证能力 |
|------|------|----------|
| MainMenuPage | pages/ngf/MainMenuPage.ets | 核心启动、事件、生命周期、DI、HDS 导航、4 Tab 切换 |
| HdsNavigationOfficialShowcasePage | pages/ngf/HdsNavigationOfficialShowcasePage.ets | 官方 HDS Navigation 组件 |
| HdsIntegratedShowcasePage | pages/ngf/HdsIntegratedShowcasePage.ets | 组件、布局、动效融合 |
| NGFDeviceAwarenessPage | pages/ngf/NGFDeviceAwarenessPage.ets | 设备感知能力 |
| NGFSettingsPage | pages/ngf/NGFSettingsPage.ets | 设置管理 |
| NGFDemoSecurityPerfPage | pages/ngf/NGFDemoSecurityPerfPage.ets | SHA 哈希、AES-GCM 加解密、性能打点、内存快照 |
| NGFDemoDataStoragePage | pages/ngf/NGFDemoDataStoragePage.ets | FileUtils 文件读写、目录操作、ContentCache LRU 缓存 |
| NGFDemoWorkflowPage | pages/ngf/NGFDemoWorkflowPage.ets | 工作流 DSL 执行、条件分支、状态持久化 |
| NGFDemoDeviceDisplayPage | pages/ngf/NGFDemoDeviceDisplayPage.ets | 多语言相对时间、设备能力检测、字体缩放控制 |

MainMenuPage 采用 4 Tab 布局: 框架 / 功能 / 设备 / 设置，"功能" Tab 包含 4 个演示入口卡片。

**剩余缺口**:
- 缺少网络请求演示 (HttpClient)
- 缺少错误恢复策略演示
- 缺少数据同步机制演示 (SyncManager)

## 五、作为可复用框架的完整缺口清单

### 5.1 基础设施层缺口 (高优先级)

| # | 缺失能力 | 所属层 | 重要程度 | 说明 |
|---|---------|--------|---------|------|
| 1 | ~~HTTP 网络请求抽象~~ | contentSource | 高 | ✅ 已完成: IHttpClient + HttpClientFacade |
| 2 | ~~RDB 数据库实现~~ | data | 高 | ✅ 已完成: RelationalStoreFacade + DbMigrator |
| 3 | ~~Preferences 实现~~ | data | 高 | ✅ 已完成: SettingsManager + @ohos.data.preferences |
| 4 | ~~服务生命周期管理~~ | core | 高 | ✅ 已完成: DependencyContainer 自动调用 |
| 5 | ~~模块启用/禁用配置~~ | core | 中 | ✅ 已完成: IModuleConfig JSON 配置 + bootstrap 检查 |

### 5.2 数据与内容层缺口 (中高优先级)

| # | 缺失能力 | 所属层 | 重要程度 | 说明 |
|---|---------|--------|---------|------|
| 6 | ~~内容缓存策略~~ | contentSource | 高 | ✅ 已完成: IContentCache 内存 LRU + 磁盘持久化 |
| 7 | ~~内容解析管道~~ | contentSource | 中 | ✅ 已完成: IContentPipeline 管道模式 |
| 8 | ~~数据同步机制~~ | data | 中 | ✅ 已完成: ISyncManager + SyncManagerFacade 离线队列 + 冲突策略 |
| 9 | ~~工作流 DSL~~ | contentWorkflow | 中 | ✅ 已完成: IWorkflowDefinitionManager 多步骤串行 + 条件分支 |
| 10 | ~~工作流持久化~~ | contentWorkflow | 中 | ✅ 已完成: IWorkflowPersistence + WorkflowPersistenceFacade |
| 11 | ~~内容源健康检查~~ | contentSource | 中 | ✅ 已完成: ISourceHealthChecker + SourceHealthCheckerFacade 延迟阈值降级 |

### 5.3 UI 与交互层缺口 (中优先级)

| # | 缺失能力 | 所属层 | 重要程度 | 说明 |
|---|---------|--------|---------|------|
| 12 | ~~路由拦截器~~ | uiShell | 中 | ✅ 已完成: IRouteInterceptor + RouteInterceptorFacade |
| 13 | ~~深链接支持~~ | uiShell | 中 | ✅ 已完成: IDeepLinkHandler URL → 路由映射 |
| 14 | ~~页面状态保存/恢复~~ | uiShell | 中 | ✅ 已完成: IPageStateStore + PageStateStoreFacade |
| 15 | ~~自适应布局组件~~ | deviceAwareness | 中 | ✅ 已完成: IAdaptiveLayout 断点响应式配置 |
| 16 | 通用页面模板 | uiShell | 低 | 列表页、表单页、详情页、设置页模板 |
| 17 | ~~颜色 Token 体系~~ | uiTheme | 中 | ✅ 已完成: IColorTokenProvider 20 个语义化颜色 |
| 18 | ~~动态字体大小调节~~ | uiTheme | 中 | ✅ 已完成: IFontScaleManager 4 级预设 + 自定义 0.5x-2.0x |
| 19 | 自定义主题包 | uiTheme | 低 | 运行时切换主题包能力 |

### 5.4 质量与工具层缺口 (中低优先级)

| # | 缺失能力 | 所属层 | 重要程度 | 说明 |
|---|---------|--------|---------|------|
| 20 | 单元测试框架 | core | 高 | 针对 core 契约和 Starter 的 hypium 测试 |
| 21 | ~~性能监控~~ | utils | 中 | ✅ 已完成: PerformanceMonitor 打点/测量/内存快照 |
| 22 | ~~安全工具~~ | utils | 中 | ✅ 已完成: SecurityToolkit SHA + AES-GCM + 随机数 |
| 23 | ~~翻译资源管理~~ | i18n | 中 | ✅ 已完成: ITranslationResource JSON 翻译加载 + 缺失键报告 |
| 24 | ~~相对时间格式化~~ | i18n | 中 | ✅ 已完成: IRelativeTimeFormatter zh/en/ja + 复数 |
| 25 | ~~设备能力检测~~ | deviceAwareness | 中 | ✅ 已完成: IDeviceCapabilityDetector 13 项硬件能力 |
| 26 | ~~文件操作工具~~ | utils | 中 | ✅ 已完成: FileUtils 文本/二进制读写 + 目录操作 |
| 27 | 无障碍封装 | deviceAwareness | 低 | 语义化组件、读屏适配 |

### 5.5 工程化缺口 (低优先级)

| # | 缺失能力 | 说明 |
|---|---------|------|
| 28 | 独立 HSP/HAR 模块化 | 将 NGF 打包为可独立分发的 HAR 库 |
| 29 | API 文档生成 | 从 JSDoc/注释自动生成 API 参考 |
| 30 | CLI 脚手架 | 生成新模块/页面/服务的命令行工具 |
| 31 | 变更日志自动化 | 基于 conventional commits 的 CHANGELOG |

## 六、推荐实施路线

### Phase 1: 核心补全 ✅ 已完成

目标: 让 NGF 从"骨架"变成"可用的框架核心"。

1. ✅ **服务生命周期管理** - DependencyContainer 自动调用 initialize()/destroy()
2. ✅ **HTTP 客户端抽象** - IHttpClient + HttpClientFacade (基于 @ohos.net.http)
3. ✅ **RDB 实现** - RelationalStoreFacade + DbMigrator (基于 @ohos.data.relationalStore)
4. ✅ **Preferences 实现** - SettingsManager (基于 @ohos.data.preferences)

### Phase 2: 内容能力 ✅ 已完成

5. ✅ **内容缓存策略** - IContentCache 内存 LRU + 磁盘持久化
6. ✅ **内容解析管道** - IContentPipeline fetch → parse → transform → cache
7. ✅ **工作流 DSL** - IWorkflowDefinitionManager JSON 定义的多步骤串行工作流 + 条件分支
8. ✅ **路由拦截器** - IRouteInterceptor + IRouteInterceptorManager 拦截/重定向/参数修改

### Phase 3: 体验完善 ✅ 已完成

9. ✅ **颜色 Token 体系** - IColorTokenProvider 20 个语义化颜色 light/dark 自动切换
10. ✅ **自适应布局组件** - IAdaptiveLayout 基于 XS/SM/MD/LG 断点的响应式配置
11. ✅ **深链接支持** - IDeepLinkHandler URL scheme → 页面路由映射
12. ✅ **翻译资源管理** - ITranslationResource JSON 翻译文件加载 + 缺失键报告

### Phase 4: 质量保障 ✅ 已完成

13. **单元测试** - core + data + contentSource 关键路径 (待实施)
14. ✅ **性能监控** - PerformanceMonitor 打点/测量/内存快照/hilog 输出
15. ✅ **安全工具** - SecurityToolkit SHA 哈希 + AES-GCM 加解密 + 随机数

### Phase 5: 能力补全 ✅ 已完成

16. ✅ **数据同步机制** - ISyncManager + SyncManagerFacade 离线队列 + 冲突策略
17. ✅ **工作流持久化** - IWorkflowPersistence + WorkflowPersistenceFacade 状态保存/恢复
18. ✅ **页面状态保存/恢复** - IPageStateStore + PageStateStoreFacade 持久化
19. ✅ **内容源健康检查** - ISourceHealthChecker + SourceHealthCheckerFacade 延迟阈值降级

### Phase 6: 收尾完善 ✅ 已完成

20. ✅ **相对时间格式化** - IRelativeTimeFormatter zh/en/ja 多语言 + 复数形式
21. ✅ **动态字体大小调节** - IFontScaleManager 4 级预设 + 自定义缩放 0.5x-2.0x
22. ✅ **文件操作工具** - FileUtils 文本/二进制读写、目录遍历、复制/移动/删除
23. ✅ **设备能力检测** - IDeviceCapabilityDetector 13 项硬件能力检测

## 七、当前优势

1. **架构分层清晰** - 9 层职责明确，contracts/facades 模式统一
2. **DI 容器可用** - DependencyContainer 支持 singleton/transient，ModuleBootstrapCoordinator 支持依赖排序
3. **启动编排完整** - StarterKernel 从 context_setup → core_services → ready 的完整引导链路
4. **HDS 集成良好** - 沉浸式导航、玻璃效果、官方组件接入
5. **API 23 适配完成** - 已处理废弃接口、单例模式修正、颜色模式管理
6. **日志体系成熟** - 多级日志 + 环形缓冲收集器 + 过滤/统计
7. **窗口管理统一** - platformOhos 层统一管理窗口策略、系统栏、安全区
8. **数据层完备** - RDB + Preferences + 缓存 + 同步队列 + 冲突策略
9. **内容能力强** - HTTP 客户端 + 二级缓存 + 解析管道 + 健康检查 + 工作流 DSL + 持久化
10. **国际化完善** - 翻译资源 + 相对时间格式化 (zh/en/ja) + 多语言复数支持
11. **设备感知全面** - 握持/折叠/断点/自适应布局/视觉效果/硬件能力检测
