# NGF 框架 API 23 适配迁移指南

> **版本**: API 23 (HarmonyOS 6.0.1)  
> **日期**: 2026-05-07  
> **状态**: 第一阶段完成

---

## 目录

1. [概述](#概述)
2. [破坏性变更](#破坏性变更)
3. [迁移步骤](#迁移步骤)
4. [API 变更详情](#api-变更详情)
5. [架构改进](#架构改进)
6. [常见问题](#常见问题)

---

## 概述

本文档指导开发者将 NGF 框架从 API 21 迁移到 API 23。本次适配主要解决：

- **废弃 API 兼容性**: 移除或替换已废弃的 API 调用
- **架构分层**: 修复 data 层对 platformOhos 层的反向依赖
- **类型安全**: 改进类型定义，消除不安全的类型断言
- **代码质量**: 提取公共工具，修复单例模式

---

## 破坏性变更

### 1. 全局上下文获取方式变更

**变更前**:
```typescript
import { getContext } from '../GlobalContext';
const context = getContext();
```

**变更后**:
```typescript
import { getNGFContext } from '../GlobalContext';
const context = getNGFContext();
```

> ⚠️ `getContext()` 仍可用但标记为 `@deprecated`，将在未来版本移除。

### 2. Data 层初始化方式变更

**变更前**:
```typescript
// SandboxManager 自动从 UIContextManager 获取 filesDir
const cacheDir = SandboxManager.getInstance().getDirectory('cache');
```

**变更后**:
```typescript
// 需要先初始化，传入 filesDir
const filesDir = abilityContext.filesDir;
SandboxManager.getInstance().initialize(filesDir);
const cacheDir = SandboxManager.getInstance().getDirectory('cache');
```

### 3. ContentSource 层初始化方式变更

**变更前**:
```typescript
// 自动从 GlobalContext 获取 filesDir
ngfSourceRepositoryFacade.readIndexJson();
```

**变更后**:
```typescript
// 需要先初始化
const filesDir = abilityContext.filesDir;
ngfSourceRepositoryFacade.initialize(filesDir);
ngfSourceRepositoryFacade.readIndexJson();
```

---

## 迁移步骤

### 步骤 1: 更新 EntryAbility

在 `EntryAbility.onCreate()` 中添加初始化代码：

```typescript
import { SandboxManager } from '../Framework/NGF/data/SandboxManager';
import { ngfStorageProviderFacade } from '../Framework/NGF/data/facades/StorageProviderFacade';
import { ngfSourceRepositoryFacade } from '../Framework/NGF/contentSource/facades/SourceRepositoryFacade';
import { ngfSourceLoaderFacade } from '../Framework/NGF/contentSource/facades/SourceLoaderFacade';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // ... 现有代码 ...
    
    // API 23 适配：初始化 Data 层和 ContentSource 层
    const filesDir = this.context.filesDir;
    SandboxManager.getInstance().initialize(filesDir);
    ngfStorageProviderFacade.initialize(filesDir);
    ngfSourceRepositoryFacade.initialize(filesDir);
    ngfSourceLoaderFacade.initialize(filesDir);
    
    // ... 其余代码 ...
  }
}
```

### 步骤 2: 替换 getContext() 调用

全局替换 `getContext()` 为 `getNGFContext()`：

```bash
# 在项目根目录执行
sed -i "s/getContext()/getNGFContext()/g" entry/src/main/ets/**/*.ets
```

### 步骤 3: 更新自定义代码

如果您有自定义代码使用了以下类，需要相应更新：

| 类名 | 变更 |
|------|------|
| `SandboxManager` | 添加 `initialize(filesDir)` 调用 |
| `StorageProviderFacade` | 添加 `initialize(filesDir)` 调用 |
| `SourceRepositoryFacade` | 添加 `initialize(filesDir)` 调用 |
| `SourceLoaderFacade` | 添加 `initialize(filesDir)` 调用 |

---

## API 变更详情

### 新增 API

#### ErrorUtils 模块

```typescript
import { errorToString, NGFErrorCategory, formatErrorMessage } from '../Framework/NGF/utils/ErrorUtils';

// 统一错误转换
const errorMessage = errorToString(error);

// 格式化错误信息
const formattedError = formatErrorMessage(error, NGFErrorCategory.STORAGE, 'CacheManager');
```

#### INGFService 接口

```typescript
import { INGFService, NGFServiceLifecycleState } from '../Framework/NGF/core';

// 实现服务接口
class MyService implements INGFService {
  readonly serviceId: string = 'my.custom.service';
  
  initialize(): void {
    // 初始化逻辑
  }
  
  destroy(): void {
    // 清理逻辑
  }
}
```

### 修改的 API

#### GlobalContext

| 方法 | 状态 | 说明 |
|------|------|------|
| `getContext()` | `@deprecated` | 请使用 `getNGFContext()` |
| `getNGFContext()` | 新增 | 推荐用法 |

#### UIContextManager

| 方法 | 变更 |
|------|------|
| `bindUIContext(context: UIContext)` | 参数类型从 `Object` 改为 `UIContext` |
| `getUIContext(): UIContext \| null` | 返回类型从 `Object` 改为 `UIContext` |

#### IStorageProvider

| 方法 | 变更 |
|------|------|
| `initialize(filesDir: string): void` | 新增必需方法 |

#### ISourceRepository / ISourceLoader

| 方法 | 变更 |
|------|------|
| `initialize(filesDir: string): void` | 新增必需方法 |

---

## 架构改进

### 分层原则修复

**修复前**:
```
data 层 → platformOhos/UIContextManager (直接依赖，违反分层)
contentSource 层 → GlobalContext (直接依赖)
```

**修复后**:
```
data 层 → IStorageProvider (通过接口)
contentSource 层 → ISourceRepository/ISourceLoader (通过接口)
```

### 服务注册改进

**修复前**:
```typescript
new NGFServiceRegistration(
  NGFStarterServiceToken.LOGGER,
  'LoggerFacade',
  ngfLoggerFacade as object  // 不安全的类型断言
)
```

**修复后**:
```typescript
// 服务类实现 INGFService 接口
class LoggerFacade implements INGFService {
  readonly serviceId: string = 'ngf.logger';
  // ...
}

// 注册时无需类型断言
new NGFServiceRegistration(
  NGFStarterServiceToken.LOGGER,
  'LoggerFacade',
  ngfLoggerFacade  // 类型安全
)
```

---

## 常见问题

### Q1: 为什么需要初始化 Data 层？

**A**: 为了遵循分层原则，data 层不再直接依赖 platformOhos 层获取 filesDir。通过依赖注入方式，使架构更清晰，测试更友好。

### Q2: getContext() 还能用吗？

**A**: 可以，但已标记为 `@deprecated`，建议尽快迁移到 `getNGFContext()`。将在下一主版本移除。

### Q3: 如何更新现有代码？

**A**: 参考 [迁移步骤](#迁移步骤) 章节，主要修改点：
1. EntryAbility 中添加初始化代码
2. 替换 getContext() 调用
3. 如有自定义服务，实现 INGFService 接口

### Q4: UIContextManager 的类型变更有什么影响？

**A**: 正面影响：
- 获得完整的类型检查和 IDE 提示
- 可以直接使用 UIContext 的新方法（如 `animateTo()`、`getPromptAction()`）
- 更好的代码可读性

### Q5: 是否需要修改 build-profile.json5？

**A**: 建议更新 targetSdkVersion：

```json5
{
  "apiType": "stageMode",
  "buildOption": {
    // ...
  },
  "targets": [
    {
      "name": "default",
      "runtimeOS": "HarmonyOS",
      "targetSdkVersion": "6.0.1(23)"  // 从 6.0.1(21) 更新
    }
  ]
}
```

---

## 参考文档

- [HarmonyOS API 23 发布说明](https://developer.harmonyos.com/)
- [NGF 框架设计文档](./Framework_Design.md)
- [CHANGELOG](./CHANGELOG.md)

---

**维护者**: NGF 框架团队  
**最后更新**: 2026-05-07
