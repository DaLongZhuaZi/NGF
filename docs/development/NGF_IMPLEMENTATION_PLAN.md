# NGF Implementation Plan

> 最后更新: 2026-05-08

## 1. 当前定位

NGF 当前处于"框架骨架已建立、核心引导链路已通、各层门面待补真实实现"的阶段。

## 2. 已完成项 (Phase A~C 回顾)

### Phase A: 兼容基础设施补齐 - 已完成

- GlobalContext.ets
- UIContextManager.ets
- SettingsManager.ets / SandboxManager.ets
- DependencyContainer.ets (支持 singleton/transient)
- ServiceContainerFacade.ets
- Logger.ets / LogCollector.ets / ErrorUtils.ets
- WindowManager 能力已整合到 platformOhos 层

### Phase B: 统一启动与上下文接线 - 已完成

- EntryAbility 中绑定 AbilityContext 并调用 ngfStarterKernel.bootstrap()
- UIContextManager 统一管理 UIContext 绑定/清除
- 模块集成 Facade 纳入 ModuleBootstrapCoordinator 统一初始化
- 8 个默认模块按依赖顺序自动引导: platform → theme/i18n → data → device → workflow → source → uiShell

### Phase C: 真实服务容器与模块注册 - 已完成

- DependencyContainer 支持真正的实例解析 (非仅返回字符串)
- INGFService 标记接口定义服务生命周期状态
- NGFModuleDefinition 支持模块名、阶段、顺序、依赖、服务令牌
- ModuleRegistry 支持按阶段列出、按名称解析
- ModuleBootstrapCoordinator 自动注册默认模块并按依赖拓扑排序引导
- StarterKernel 统一编排 context_setup → core_services → ready

### API 23 适配 - 已完成

- 私有构造函数确保单例模式正确
- 颜色模式由 ThemeManagerFacade 统一管理
- 废弃接口迁移 (getContext → getHostContext, animateTo → UIContext.animateTo)

## 3. 当前各层完成度

| 层 | 完成度 | 核心状态 |
|---|--------|---------|
| core | 85% | 契约完整，DI + 模块注册 + 启动编排已通 |
| platformOhos | 75% | 窗口管理 + 上下文桥接已通 |
| data | 70% | 门面骨架完整，缺 RDB/Preferences 真实实现 |
| contentWorkflow | 60% | 门面骨架完整，缺工作流 DSL 和具体实现 |
| contentSource | 55% | 门面骨架完整，缺 HTTP 客户端和缓存策略 |
| uiShell | 75% | HDS 导航 + 沉浸式组件已通 |
| uiTheme | 70% | 颜色模式管理已通，缺 Token 体系 |
| i18n | 60% | 语言切换已通，缺翻译资源管理 |
| deviceAwareness | 65% | 握持/折叠/视觉效果已通，缺断点实现 |
| utils | 80% | 日志/时间/错误工具已通 |

## 4. 下一阶段目标 (Phase D)

目标: 补全框架核心能力，让各层从"骨架门面"变成"可用实现"。

### 4.1 高优先级

1. **服务生命周期管理** - DependencyContainer 在 resolve 时自动调用 initialize()，在 clear 时调用 destroy()
2. **HTTP 客户端抽象** - IHttpClient 接口 + 基于 @ohos.net.http 的实现，含拦截器、超时、重试
3. **RDB 数据库实现** - 基于 @ohos.data.relationalStore 的 IDbMigrator 实现
4. **Preferences 实现** - 基于 @ohos.data.preferences 的 ISettingsStore 实现
5. **单元测试** - 针对 core 契约和 Starter 的 hypium 测试

### 4.2 中优先级

6. **内容缓存策略** - 内存 LRU + 磁盘持久化的二级缓存
7. **内容解析管道** - fetch → parse → transform → cache 的 Pipeline 模式
8. **路由拦截器** - 页面跳转前的鉴权/参数校验中间件
9. **颜色 Token 体系** - 语义化颜色变量 (primary, surface, onSurface 等)
10. **翻译资源管理** - 翻译文件加载、键值查找、缺失键报告
11. **工作流 DSL** - JSON 定义的工作流步骤描述

### 4.3 低优先级

12. **自适应布局组件** - 基于断点的响应式容器
13. **深链接支持** - URL scheme → 页面路由映射
14. **页面状态保存/恢复** - 页面重建时的状态恢复
15. **通用页面模板** - 列表页、表单页、详情页模板
16. **性能监控** - FPS、内存、启动耗时
17. **安全工具** - 加密、哈希、安全存储

## 5. Phase E: 框架库化 (远期)

目标: 将 NGF 从嵌入式框架打包为可独立分发的 HAR 模块。

- 抽取为独立 HAR 模块，定义清晰的公共 API 边界
- 消除对 AppStorage 的直接依赖，改为可选注入
- 输出 API 文档与接入指南
- 建立版本发布与兼容性策略

## 6. 说明

- 本计划以当前仓库结构为基础，不强行推翻既有目录。
- 每个 Phase 的验收标准是: 该阶段能力可在演示页中被验证，且不破坏已有模块。
- 后续所有新增实现都应继续保持 NGF 的"框架工程"视角，避免写死单一业务逻辑。
