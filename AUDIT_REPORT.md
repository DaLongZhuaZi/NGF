# NGF 框架 ArkTS 合规审计报告

**审计日期**: 2026-06-12
**审计标准**: .rules/ 中的 skill-arkts-standards、skill-arkui-knowledge、skill-arkts-error-fixes、skill-arkts-runtime-fix、skill-arkts-debug
**审计范围**: ngf_framework/src/main/ets/ + entry/src/main/ets/ 全部模块

---

## 一、审计总览

| 严重度 | 违规类型 | 数量 | 影响范围 |
|--------|---------|------|---------|
| **P0** | 模板字面量 `` `${value}` `` | **1064** | 全部 Facade 文件 + entry 页面 |
| **P0** | `as` 类型断言 | **59** | framework Facade + entry 页面 |
| **P1** | `object` 结构化类型 | **7** (`: object`) + **7** (`as object`) | ActionExecutorFacade/ContentPipelineFacade/HttpClientFacade/TranslationResourceFacade/ModuleConfigFacade/WorkflowDefinitionFacade |
| **P1** | Object.entries + 动态索引 | **9** | ActionExecutor/DataFacade/ContentPipeline/HttpClientFacade/TranslationResourceFacade/SettingsManager/ModuleConfigFacade/WorkflowDefinitionFacade |
| **P1** | ForEach key 稳定性 | **1** | WorkflowVisualizer |
| **P1** | Integration Facade `as INGFService` 断言 | **47** | 所有 8 个 Integration Facade |
| **P2** | typeof 运行时检查 | **63** | JSON 解析后类型守卫、errorToString 类型窄化 |
| **P2** | null vs undefined | **364** | 单例模式、窗口/文件句柄、返回值等 |
| **P2** | for...of 循环 | **17** | 遍历 keys/strategyNames/sqls/entries 等 |

**合规项**: 无 `var`、无 `for...in`、无 `delete` 属性删除运算符（54 处 `delete` 均为 `Map.delete()`/`Set.delete()` 合法调用）、无 `catch(err: Type)` 类型标注、无显式 `any`/`unknown`

**已修复项**:
- `INGFService` 标记接口 — 已定义（`core/contracts/INGFService.ets`）
- `IServiceContainer` — 已改用 `INGFService | null`（`core/contracts/IServiceContainer.ets`）
- `NGFServiceRegistration` — 已改用 `INGFService`（`core/contracts/NGFServiceRegistration.ets`）
- `ErrorUtils.errorToString` — 已扩展签名为 `NGFCatchError`（`utils/ErrorUtils.ets`）

---

## 二、P0 违规详细分析

### 2.1 模板字面量 (1064 处：framework ~869 + entry ~199)

**规则**: ArkTS 禁止模板字面量，应使用字符串拼接 + 显式转换

**按模块分布（framework 层估算）**:

| 模块 | 典型文件 | 估算违规数 |
|------|---------|-----------|
| platformOhos | PlatformWindowManagerFacade.ets | ~50 |
| core | StarterKernel.ets + DependencyContainer.ets + ServiceContainerFacade.ets | ~30 |
| deviceAwareness | HoldingAwarenessFacade.ets | ~35 |
| contentSource | SourceRepositoryFacade.ets + SourceLoaderFacade.ets + HttpClientFacade.ets + ContentCacheFacade.ets | ~40 |
| contentWorkflow | WorkflowEngineFacade.ets + ActionExecutorFacade.ets + WorkflowPersistenceFacade.ets | ~30 |
| uiShell | NavigationShellFacade.ets + PagePolicyHostFacade.ets + OverlayManagerFacade.ets | ~20 |
| data | DataFacade.ets + CacheStoreFacade.ets + RelationalStoreFacade.ets + SettingsManager.ets | ~40 |
| utils | Logger.ets + FileUtils.ets + TimeUtils.ets + ErrorUtils.ets + CrashAnalyticsFacade.ets | ~25 |
| i18n | I18nManagerFacade.ets + TranslationResourceFacade.ets | ~10 |
| security | UserAuthenticationFacade.ets + KeyStoreManagerFacade.ets | ~5 |
| hardware | SensorManagerFacade.ets + LocationManagerFacade.ets | ~5 |
| systemTasks | TaskManagerFacade.ets + SystemIntegrationFacade.ets | ~10 |
| push/interconnect/media/network | 各 Facade | ~10 |
| entry 层 | MainMenuPage.ets + 各 Capabilities 页面 + EntryAbility + MultitonEntryAbility | ~199 |

**典型违规模式**:

```typescript
// 违规
logger.info(TAG, `缓存写入: key=${key}, ttlMs=${ttlMs}`);
logger.error(TAG, `RDB 初始化异常: ${message}`);
const path = `${baseDir}/${filePath}`;
const label = `v${this.versionName} (${this.versionCode})`;

// 修复
logger.info(TAG, '缓存写入: key=' + key + ', ttlMs=' + String(ttlMs));
logger.error(TAG, 'RDB 初始化异常: ' + message);
const path = baseDir + '/' + filePath;
const label = 'v' + this.versionName + ' (' + String(this.versionCode) + ')';
```

**批量修复方案**: 使用正则全局替换，分三步：
1. 简单插值 `` `text${var}` `` → `'text' + var`
2. 多插值 `` `${a}text${b}` `` → `String(a) + 'text' + String(b)`
3. 带表达式 `` `${obj.method()}` `` → `obj.method().toString()`

### 2.2 `as` 类型断言 (59 处)

**实际分类**:

#### 模式 A: `JSON.parse(...) as XXX` (35 处)

**影响文件**: DataFacade(7)、ActionExecutorFacade(6)、WorkflowEngineFacade(3)、ContentPipelineFacade(2)、WorkflowPersistenceFacade(1)、SourceRegistryFacade(1)、SourceRepositoryFacade(1)、ContinuationManagerFacade(1)、SystemIntegrationFacade(2)、ModuleConfigFacade(1)、TranslationResourceFacade(1)、WorkflowDefinitionFacade(1)、HttpClientFacade(1)、entry MainMenuPage(2)、test 文件(2)、HoldingAwarenessFacade(1，bundleInfo)

```typescript
// 违规
const parsed = JSON.parse(actionJson) as Partial<NGFHttpActionEnvelope>;

// 修复: 创建类型安全的解析辅助方法
private parseHttpActionEnvelope(json: string): NGFHttpActionEnvelope {
  const parsed: Object = JSON.parse(json);
  const envelope = new NGFHttpActionEnvelope();
  const keys = Object.keys(parsed);
  for (let i = 0; i < keys.length; i++) {
    const key = keys[i];
    if (key === 'url') {
      envelope.url = String(parsed[key]);
    }
  }
  return envelope;
}
```

**注意**: 这是最复杂的修复项。每个 `JSON.parse as` 都需要对应的解析方法。建议按模块逐步替换。

#### 模式 B: `Object.entries(...) as [K, V][]` (9 处)

**影响文件**: ActionExecutorFacade(2)、HttpClientFacade(1)、ContentPipelineFacade(2)、WorkflowDefinitionFacade(1)、TranslationResourceFacade(1)、SettingsManager(1)、ModuleConfigFacade(1)

```typescript
// 违规
const entries = Object.entries(mapping) as [string, string][];

// 修复: 使用 Object.keys() + 显式属性访问
const keys = Object.keys(mapping);
for (let i = 0; i < keys.length; i++) {
  const key = keys[i];
  // ...
}
```

#### 模式 C: `as object` 断言 (7 处)

**影响文件**: HttpClientFacade(1, `response.header as object`)、TranslationResourceFacade(1)、ModuleConfigFacade(1)、WorkflowDefinitionFacade(1)、ActionExecutorFacade(3)

```typescript
// 违规 — 均为 JSON.parse(...) as object
const parsed = JSON.parse(jsonContent) as object;

// 修复: 为解析结果定义明确类型，或使用 Object 后接 Object.keys 逐属性提取
```

#### 模式 D: Map.get() 返回值断言 (3 处)

**影响文件**: PlatformWindowManagerFacade(1, `subWindows.get(name) as window.Window`)、ContinuationManagerFacade(1, `receivedData.get(pageId) as NGFContinuationPageState`)、ModuleConfigFacade(1, `configMap.get(key) as boolean`)

```typescript
// 违规
return this.subWindows.get(name) as window.Window;

// 修复: 使用空值检查
const windowInstance = this.subWindows.get(name);
if (windowInstance !== undefined) {
  return windowInstance;
}
return undefined; // 或修改返回类型为 window.Window | undefined
```

#### 模式 E: entry 层 catch 块中 `error as Object | string | number | boolean` (13 处)

**影响文件**: MainMenuPage(8)、NGFCapabilitiesDatabasePage(5)

**注意**: framework 层的 errorToString 已支持 `NGFCatchError` 类型，可直接传入 catch 变量无需 `as`。但 entry 层仍有 13 处显式 `as` 断言。

```typescript
// 违规
errorToString(error as Object | string | number | boolean)

// 修复: ErrorUtils.errorToString 已支持 NGFCatchError，直接传入即可
errorToString(error)
```

#### 模式 F: 其他运行时断言 (~1 处)

- `getRecentOperatingHandStatus() as number` (HoldingAwarenessFacade)

---

## 三、P1 违规详细分析

### 3.1 `object` 结构化类型（7 处 `: object` 类型标注 + 7 处 `as object`）

**现状**: `IServiceContainer` 和 `NGFServiceRegistration` 已修复为使用 `INGFService`，但以下文件仍直接使用 `object` 类型：

| 文件 | `: object` 用法 |
|------|---------------|
| ActionExecutorFacade.ets | `params?: object` 参数类型、`resolveJsonPath(obj: object)`、`objectToStringMap(source: object)`、`findJsonField(source: object)` |
| ContentPipelineFacade.ets | `parseJsonObject(json: string): object` 返回值 |
| HttpClientFacade.ets | `stringifyHeaders(header: object)` 参数 |

**修复方向**: 为 `object` 用法定义更具体的接口或使用 `Map<string, string>` 替代。

### 3.2 Integration Facade `as INGFService` 断言 (47 处)

**现状**: `NGFServiceRegistration` 构造函数已要求 `INGFService` 类型参数，但各 Facade 实例**未实现** `INGFService` 接口，因此每个 Integration Facade 在注册服务时仍需 `as INGFService` 断言。

**影响文件**: 所有 8 个 Integration Facade
- NGFDataIntegrationFacade (8 处)
- NGFContentSourceIntegrationFacade (7 处)
- NGFContentWorkflowIntegrationFacade (6 处)
- NGFPlatformOhosIntegrationFacade (6 处)
- NGFDeviceAwarenessIntegrationFacade (6 处)
- NGFUiShellIntegrationFacade (7 处)
- NGFUIThemeIntegrationFacade (4 处)
- NGFI18nIntegrationFacade (3 处)

```typescript
// 当前 — 各 Facade 未 implements INGFService，需 as 断言
new NGFServiceRegistration('ngf.data.data_facade', 'DataFacade', ngfDataFacade as INGFService)

// 修复: 让所有 Facade 实现 INGFService 接口
export class DataFacade implements INGFService {
  readonly serviceId: string = 'ngf.data.data_facade';
  // ...
}
// 注册时无需断言
new NGFServiceRegistration('ngf.data.data_facade', 'DataFacade', ngfDataFacade)
```

### 3.3 ForEach key 稳定性 (1 处)

```typescript
// 违规 - NGFWorkflowVisualizer.ets:44
ForEach(this.workflows, (wfName: string) => { ... }, (item: string) => item)
// 如果列表中有重复名称会导致 key 冲突

// 修复
ForEach(this.workflows, (wfName: string, index: number) => { ... },
  (item: string, index: number): string => 'wf_' + String(index) + '_' + item)
```

**注意**: NGFWorkflowVisualizer.ets 本身也有模板字面量违规（97、105、110、115、118 行等）。

### 3.4 对象字面量缺少显式类型上下文

需逐一排查 Facade 文件中的对象字面量返回值。

### 3.5 AppStorage 泛型调用 (20 处)

**影响文件**: NavigationShellFacade、EncryptedSettingsStoreFacade、FontScaleManagerFacade、ThemeManagerFacade、PageTransitionManagerFacade、I18nManagerFacade、DbMigratorFacade

```typescript
// 当前
AppStorage.get<NavPathStack>('GlobalNavStack')

// 建议: 使用 @StorageLink 或初始化时注册
```

---

## 四、P2 违规（改进建议）

### 4.1 typeof 运行时检查 (63 处)

其中约 30 处为 `errorToString`/`normalizeError` 中的 error 类型窄化（已统一到 `ErrorUtils` 但各 Facade 仍有私有副本），其余为 JSON 解析后类型守卫和 `dataPreferences.ValueType` 类型检查。

**注意**: `typeof` 在 ArkTS 表达式上下文中是允许的，仅禁止在类型上下文使用。此处为运行时必要用法，建议降低优先级。

### 4.2 null vs undefined (364 处)

ArkTS 中 `null` 和 `undefined` 均为合法类型，不构成编译错误。但大量 `| null = null` 模式（尤其是单例 `private static instance: XXX | null = null`）可考虑统一为 `| undefined = undefined`。

**主要类别**:
- 单例模式 `| null = null`：~15 处
- 窗口/文件句柄 `| null = null`：~10 处
- 返回值 `| null`：~30 处
- errorToString 参数 `| null`：~8 处（已随 NGFCatchError 统一）
- 其他 `| null` 类型声明和判空检查：~300 处

**优先级建议**: 仅迁移新增代码和主动重构区域，不建议批量全量替换。

### 4.3 for...of 循环 (17 处：framework 16 + entry 1)

**影响文件**:

| 文件 | for...of 处数 |
|------|-------------|
| StarterKernel.ets | 1 |
| NetworkManagerFacade.ets | 2 |
| RdbManagerFacade.ets | 1 |
| EventBusFacade.ets | 1 |
| ErrorHandlerFacade.ets | 1 |
| WorkflowPersistenceFacade.ets | 2 |
| ComponentThemeOverrideFacade.ets | 1 |
| PageStateStoreFacade.ets | 2 |
| DeepLinkFacade.ets | 1 |
| TranslationResourceFacade.ets | 1 |
| ModuleConfigFacade.ets | 1 |
| WorkflowDefinitionFacade.ets | 1 |
| SourceHealthCheckerFacade.ets | 1 |
| NGFCapabilitiesDatabasePage.ets | 1 |

**注意**: ArkTS 支持 `for...of` 遍历数组（官方文档明确列出为支持的循环语句），此条为项目 .rules 规则中的风格偏好，非 ArkTS 编译约束。建议按团队规范统一，但不构成编译风险。

---

## 五、优化执行方案（按优先级排序）

### Phase 1: 基础设施修复（1-2 天）

1. ~~**修改 `ErrorUtils.errorToString` 签名**~~ — ✅ 已完成（`NGFCatchError` 类型别名已定义）
2. ~~**定义 `INGFService` 标记接口**~~ — ✅ 已完成（`core/contracts/INGFService.ets` 已存在）
3. ~~**修复 `IServiceContainer` / `NGFServiceRegistration` 的 `object` 用法**~~ — ✅ 已完成（已改用 `INGFService`）
4. **消除 entry 层 `error as Object | string | number | boolean`** — 13 处，改为直接传 `error` 给 `errorToString()`
5. **让所有 Facade 实现 `INGFService` 接口** — 消除 47 处 `as INGFService` 断言
6. **创建 `NGFJsonParse` 工具类** — 提供 `safeParse<T>(json: string, typeGuard: (obj: Object) => boolean): T | undefined` 方法

### Phase 2: 批量修复模板字面量（3-5 天）

按照模块优先级逐个替换（framework ~869 处 + entry ~199 处）：

1. utils/ (~25 处) — 最独立、影响最小
2. core/ (~30 处) — 框架核心
3. security/hardware/push/interconnect/media/network (~20 处) — 最少
4. i18n/ (~10 处)
5. systemTasks/ (~10 处)
6. uiShell/ (~20 处) — UI 层
7. contentWorkflow/ (~30 处) — 工作流
8. contentSource/ (~40 处) — 内容源
9. data/ (~40 处) — 数据层
10. deviceAwareness/ (~35 处) — 设备感知
11. platformOhos/ (~50 处) — 平台层（最大单文件）
12. entry/ (~199 处) — 入口层

### Phase 3: 消除 `as` 类型断言（3-5 天）

1. Phase 1 的 Facade 实现 INGFService 已覆盖 47 处 `as INGFService` + 7 处 `as object`
2. Phase 1 的 entry errorToString 修复已覆盖 13 处 catch 相关断言
3. 为每个 `JSON.parse as` (35 处) 创建对应解析方法
4. 替换 `Object.entries as` (9 处) 为 Map 或 Object.keys + 显式属性访问
5. 修复 Map.get() 返回值断言 (3 处) — 改用空值检查

### Phase 4: P1 优化（1-2 天）

1. ForEach key 稳定性修复 (1 处)
2. `: object` 类型标注替换为具体接口 (7 处)
3. 对象字面量类型上下文补充

### Phase 5: P2 优化（可选）

1. null → undefined 迁移（仅限新增代码和主动重构区域，不建议全量替换 364 处）
2. for...of → for-index 循环（17 处，非编译约束，按团队规范决定）
3. typeof → instanceof 类型守卫（63 处，大部分为运行时必要用法，低优先级）

---

## 六、合规良好的文件

以下文件完全或基本符合 ArkTS 规范：

- `utils/StringUtils.ets` — 无任何违规
- `utils/index.ets` — 纯导出
- `core/contracts/INGFService.ets` — 已修复，使用标记接口
- `core/contracts/IServiceContainer.ets` — 已修复，使用 INGFService
- `core/contracts/NGFServiceRegistration.ets` — 已修复，使用 INGFService
- `utils/ErrorUtils.ets` — 已修复，定义 NGFCatchError 类型
- 所有 `contracts/` 目录下的接口定义文件 — 基本合规
- `data/CacheStoreFacade.ets` — 仅模板字面量违规，逻辑结构清晰
- `utils/LogCollector.ets` — 仅 P2 问题

---

## 七、规则合规检查清单

| 规则 | 状态 | 说明 |
|------|------|------|
| 禁止 `any`/`unknown` | ✅ 合规 | 无显式 `any` 或 `unknown` |
| 禁止 `as` 类型断言 | ❌ 59 处 | 需系统性修复（含 47 处 as INGFService、35 处 JSON.parse as、9 处 Object.entries as、7 处 as object、13 处 entry error as、3 处 Map.get as） |
| 禁止结构化类型 | ⚠️ 7 处 `: object` | IServiceContainer/NGFServiceRegistration 已修复；ActionExecutorFacade/ContentPipelineFacade/HttpClientFacade 仍有 `object` 类型参数 |
| 禁止动态属性访问 | ⚠️ 9 处 | 仅 Object.entries 场景 |
| 对象字面量显式类型 | ⚠️ 少量 | 需逐一排查 |
| 禁止模板字面量 | ❌ 1064 处 | 最大量违规（framework 869 + entry 199） |
| 禁止 `var` | ✅ 合规 | 无 `var` |
| 禁止 catch 类型注解 | ✅ 合规 | 全部 `catch(err)` 无类型标注 |
| 禁止 `delete` 属性运算符 | ✅ 合规 | 54 处 `delete` 均为 `Map.delete()`/`Set.delete()` 合法调用 |
| 禁止 `for...in` | ✅ 合规 | 无 `for...in` |
| 禁止命名空间运行时值 | ✅ 合规 | 无 |
| ForEach key 稳定性 | ⚠️ 1 处 | NGFWorkflowVisualizer 需修复 |
| ArkUI 修饰符完整名称 | ✅ 合规 | 未发现简写 |
| V1/V2 装饰器不混用 | ✅ 合规 | 未发现混用 |
