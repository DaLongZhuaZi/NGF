# NGF 框架变更日志

所有重要的变更都会记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

---

## [Unreleased]

### API 23 适配 - 第一阶段和第二阶段

#### 新增

- **ErrorUtils 模块** (`utils/ErrorUtils.ets`)
  - 新增 `errorToString()` 函数，统一错误转换
  - 新增 `NGFErrorCategory` 枚举，定义错误分类
  - 新增 `formatErrorMessage()` 函数，格式化错误信息

- **INGFService 接口** (`core/contracts/INGFService.ets`)
  - 新增 `INGFService` 标记接口，所有 NGF 服务的基础接口
  - 新增 `INGFServiceMetadata` 接口，服务元数据定义
  - 新增 `INGFServiceState` 接口，服务状态定义
  - 新增 `NGFServiceLifecycleState` 枚举，服务生命周期状态

- **API 23 适配文档**
  - 新增 `docs/API23_Migration_Guide.md`，详细的迁移指南
  - 新增 `docs/CHANGELOG.md`，变更日志

#### 变更

##### API 废弃兼容

- **GlobalContext** (`GlobalContext.ets`)
  - 新增 `getNGFContext()` 函数（推荐用法）
  - 将 `getContext()` 标记为 `@deprecated`
  - 添加 JSDoc 注释说明 API 23 适配原因

- **EntryAbility** (`entryability/EntryAbility.ets`)
  - 移除 `getApplicationContext().setColorMode()` 废弃调用
  - 添加注释说明颜色模式由 ThemeManagerFacade 统一管理

##### 类型安全改进

- **UIContextManager** (`platformOhos/UIContextManager.ets`)
  - 导入 `UIContext` 类型 from '@kit.ArkUI'
  - `uiContext` 属性类型从 `Object` 改为 `UIContext`
  - `bindUIContext()` 参数类型从 `Object` 改为 `UIContext`
  - `getUIContext()` 返回类型从 `Object` 改为 `UIContext`
  - 添加私有构造函数确保单例模式

- **NGFServiceRegistration** (`core/contracts/NGFServiceRegistration.ets`)
  - `service` 属性类型从 `object` 改为 `INGFService`
  - 新增 `getMetadata()` 方法获取服务元数据
  - 消除 `as object` 类型断言的需求

##### 架构分层解耦

- **IStorageProvider** (`data/contracts/IStorageProvider.ets`)
  - 新增 `initialize(filesDir: string): void` 方法
  - 支持依赖注入，解耦对 platformOhos 层的直接依赖

- **SandboxManager** (`data/SandboxManager.ets`)
  - 移除对 `platformOhos/UIContextManager` 的导入
  - 移除对 `GlobalContext` 的导入
  - 新增 `filesDir` 私有属性
  - 新增 `initialize(filesDir: string)` 方法
  - 简化 `resolveFilesDir()` 方法实现
  - 添加私有构造函数

- **StorageProviderFacade** (`data/facades/StorageProviderFacade.ets`)
  - 使用 `ErrorUtils.errorToString` 替代私有方法
  - 移除对 `GlobalContext` 和 `UIContextManager` 的直接依赖
  - 新增 `initialize(filesDir: string)` 方法
  - 添加 JSDoc 注释

- **ISourceRepository** (`contentSource/contracts/ISourceRepository.ets`)
  - 新增 `initialize(filesDir: string): void` 方法

- **ISourceLoader** (`contentSource/contracts/ISourceLoader.ets`)
  - 新增 `initialize(filesDir: string): void` 方法

- **SourceRepositoryFacade** (`contentSource/facades/SourceRepositoryFacade.ets`)
  - 移除对 `GlobalContext` 的导入
  - 移除对 `UIContextManager` 的导入
  - 新增 `filesDir` 私有属性
  - 新增 `initialize(filesDir: string)` 方法
  - 简化 `resolveFilesDir()` 方法实现
  - 添加 JSDoc 注释

- **SourceLoaderFacade** (`contentSource/facades/SourceLoaderFacade.ets`)
  - 移除对 `GlobalContext` 的导入
  - 移除对 `UIContextManager` 的导入
  - 移除对 `util` 的未使用导入
  - 新增 `filesDir` 私有属性
  - 新增 `initialize(filesDir: string)` 方法
  - 简化 `resolveFilesDir()` 方法实现
  - 添加 JSDoc 注释

##### 单例模式修复

- **DependencyContainer** (`core/DependencyContainer.ets`)
  - 添加 `private constructor()` 确保单例模式

- **ModuleRegistry** (`core/starter/ModuleRegistry.ets`)
  - 添加 `private constructor()` 确保单例模式

- **SettingsManager** (`data/SettingsManager.ets`)
  - 添加 `private constructor()` 确保单例模式

##### 类型安全修复

- **DeviceAdaptationFacade** (`deviceAwareness/facades/DeviceAdaptationFacade.ets`)
  - 修复 `instance` 静态属性类型：`NGFDeviceAdaptationManager` → `NGFDeviceAdaptationManager | null = null`
  - 添加 API 23 适配注释

##### 导出更新

- **core/index.ets**
  - 导出 `INGFService` 接口
  - 导出 `INGFServiceMetadata` 接口
  - 导出 `INGFServiceState` 接口
  - 导出 `NGFServiceLifecycleState` 枚举

- **utils/index.ets**
  - 导出 `errorToString` 函数
  - 导出 `NGFErrorCategory` 枚举
  - 导出 `formatErrorMessage` 函数

#### 修复

- 修复 data 层对 platformOhos 层的反向依赖问题
- 修复 contentSource 层对 GlobalContext 的直接依赖问题
- 修复多个单例类构造函数未标记为 private 的问题
- 修复 DeviceAdaptationFacade 静态属性未正确初始化的问题
- 修复 StorageProviderFacade 中 errorToString 方法重复定义的问题

#### 移除

- 移除 EntryAbility 中对 `getApplicationContext().setColorMode()` 的废弃调用
- 移除 SandboxManager 中对 `platformOhos/UIContextManager` 的直接依赖
- 移除 StorageProviderFacade 中对 `platformOhos/UIContextManager` 的直接依赖
- 移除 SourceRepositoryFacade 中对 `GlobalContext` 和 `UIContextManager` 的依赖
- 移除 SourceLoaderFacade 中对 `GlobalContext`、`UIContextManager` 和 `util` 的依赖

---

## 迁移指南

### 破坏性变更

本次更新包含以下破坏性变更，需要开发者进行相应修改：

1. **全局上下文获取方式变更**
   - `getContext()` → `getNGFContext()`
   - `getContext()` 已标记为 `@deprecated`

2. **Data 层初始化方式变更**
   - 需要调用 `SandboxManager.getInstance().initialize(filesDir)`
   - 需要调用 `StorageProviderFacade.initialize(filesDir)`

3. **ContentSource 层初始化方式变更**
   - 需要调用 `SourceRepositoryFacade.initialize(filesDir)`
   - 需要调用 `SourceLoaderFacade.initialize(filesDir)`

详细迁移步骤请参考 [API23_Migration_Guide.md](./API23_Migration_Guide.md)

---

## 统计

### 变更文件数

- 新增文件：4
- 修改文件：17
- 删除文件：0
- **总计：21**

### 代码行数变化

- 新增代码：约 500 行
- 删除代码：约 200 行
- **净增：约 300 行**

### 修复问题数

- API 废弃兼容：3
- 类型安全改进：4
- 架构分层解耦：6
- 单例模式修复：3
- 代码复用改进：2
- **总计：18**

---

## 兼容性

### 最低支持版本

- HarmonyOS API 21 (6.0.1)

### 推荐目标版本

- HarmonyOS API 23 (6.0.1)

### 已知问题

- 部分 IntegrationFacade 仍使用 `as object` 断言，将在后续版本中修复
- 需要更新 EntryAbility 添加初始化代码，否则 Data 层和 ContentSource 层无法正常工作

---

## 贡献者

感谢以下贡献者参与本次 API 23 适配工作：

- NGF 框架团队

---

## 参考

- [HarmonyOS 开发者文档](https://developer.harmonyos.com/)
- [ArkTS 语言规范](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/arkts-overview-0000001536812757-V3)
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)

---

**发布日期**: 2026-05-07  
**版本状态**: Unreleased (开发中)
