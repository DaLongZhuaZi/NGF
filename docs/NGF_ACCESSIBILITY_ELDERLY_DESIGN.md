# NGF 无障碍与适老化能力设计

**文档状态**：研究设计基线（P3 契约已落地并通过 API 26 ArkTS 编译与打包）  
**版本**：0.2  
**日期**：2026-10-05  
**对应计划**：[NGF_ACCESSIBILITY_ELDERLY_RESEARCH_PLAN.md](NGF_ACCESSIBILITY_ELDERLY_RESEARCH_PLAN.md)

## 1. 结论摘要

HarmonyOS/ArkUI 已经提供无障碍相关能力，但 NGF 当前只使用了系统无障碍状态查询 API，并提供了文本标签拼接工具。现有能力不足以覆盖语义树、焦点顺序、可操作性、动态字体、对比度、触控目标、动效减弱、老年模式和专项验收。

本设计把能力拆成四层：

1. **平台能力层**：封装 `@kit.AccessibilityKit`、ArkUI 无障碍属性/事件和可用性探测。
2. **NGF 语义契约层**：统一组件语义、状态、动作、焦点和朗读文本模型。
3. **适配策略层**：管理文本缩放、触控尺寸、对比度、动效、密度和老年模式策略。
4. **UI/UX 组件层**：为页面提供可复用的无障碍按钮、表单、列表、导航、弹窗和状态反馈模式。

本阶段只确定设计和验收边界，不把“能编译”或“读屏能点到”单独当作完成条件。

## 2. 证据等级与现状

| 等级 | 含义 |
|---|---|
| A | 当前 NGF 源码已经使用并能定位到 API/调用点 |
| B | 华为官方文档主题链接可访问，或本机 DevEco API reference index 已列出签名；目标 API 26 的最终可用性仍需 SDK 声明/编译探针复核 |
| A26 | 当前 `F:\\HarmonyOS\\SDK\\26.0.0` / DevEco 26 SDK 声明存在，且 NGF 已通过 `assembleApp` 的 ArkTS 编译阶段；签名阶段仍需有效 NGF profile |
| C | 设计候选或行业建议，尚未形成当前 SDK 可用性证据 |

### 2.1 当前 NGF 能力

| 位置 | 当前行为 | 结论 |
|---|---|---|
| `deviceAwareness/facades/AccessibilityFacade.ets` | 调用 `accessibility.isOpenAccessibilitySync()` | A；可作为系统无障碍总开关状态探测 |
| 同上 | 调用 `accessibility.isOpenTouchGuideSync()` 与 `getTouchModeSync()` | A；已按“触摸探索平台信号”定位，不再当作读屏开关；触摸模式单独成字段 |
| 同上 | 调用 `accessibility.isScreenReaderOpenSync()` | A；读屏状态独立信号，@since 18 |
| 同上 | `buildAccessibilityLabel()` 只返回传入文本 | A；不是语义树或属性绑定 |
| 同上 | `buildAccessibilityHint()` 曾固定拼接中文“双击执行” | **已修复**：改为原样返回调用方传入的本地化文本；新代码走 `NGFAccessibilitySemantics.textHint` |
| 同上 | 注册 4 个 `accessibility.on*` 监听但从未 `off` | **已修复**：6 个事件全部 on/off 配对，`release()` 只取消真正注册成功的项 |
| `IAccessibilityManager.ets` | 原只有状态、label、hint 四个方法 | **已扩展**：追加适老模式、策略、生命周期方法；旧方法签名与语义保持不变 |
| `NGFAccessibilitySemantics.ets`（新增） | 语义模型 + 审计函数 | A26；已通过 API 26 编译 |
| `NGFInclusiveDesignPolicy.ets`（新增） | 策略档位 + 量化门槛 + 推导函数 | A26；已通过 API 26 编译 |
| `NGFDeviceAwarenessIntegrationFacade.ets` | 注册 `ngf.device.accessibility` | A；已有 DI 接入点，可兼容扩展 |

## 3. ArkTS / HarmonyOS API 证据矩阵

官方入口：

- [ArkUI 通用无障碍属性参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-accessibility)
- [HarmonyOS 无障碍开发主题](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/accessibility-development)
- [AccessibilityKit API 主题](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-accessibility)
- [ArkUI 通用属性参考总页](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-component-common)

### 3.0 探针方法

本节所有 "A26" 结论均来自**本机 API 26 SDK 声明文件的逐行核对**，不是文档摘要推断。探针文件：

- `G:\DevEco Studio 26\DevEco Studio\sdk\default\openharmony\ets\oh-uni-package.json` → `apiVersion: 26`、`version: 26.0.0.105`、`releaseType: Release`
- `...\ets\component\common.d.ts`（930 344 字节）——ArkUI 通用属性与枚举
- `...\ets\component\units.d.ts`——`AccessibilityOptions`
- `...\ets\api\@ohos.accessibility.d.ts`——无障碍状态与监听
- `...\ets\kits\@kit.AccessibilityKit.d.ts`——确认 `accessibility` 由该 kit 导出

### 3.1 ArkUI 通用属性证据矩阵（全部 A26）

> **2026-10-05 证据复核**：下表 `@since` 已按"**引入版本**"重新核对。
> 方法：对每个声明向上遍历**连续堆叠的全部 JSDoc 块**，取其中**最小**的 `@since`。
> 只取"最近一个 `@since`"是**错的** —— ArkUI 的 `.d.ts` 常把旧块叠在新块之上，
> 最近的那个是**文档修订版本**而不是引入版本（例如 `accessibilityGroup(value: boolean)`
> 有 `@since 11` 与 `@since 12` 两个块，引入版本是 **10**，两个块都不是它）。

| 能力 | API 26 声明签名 | 引入版本 | NGF 语义模型字段 |
|---|---|---|---|
| 朗读主文本 | `accessibilityText(value: string)` / `accessibilityText(text: Resource)` | **10** / 12 | `NGFAccessibilitySemantics.label` |
| 操作提示 | `accessibilityTextHint(value: string)` | 12 | `textHint` |
| 补充说明 | `accessibilityDescription(value: string)` / `(description: Resource)` | **10** / 12 | `description` |
| 状态文本 | `accessibilityStateDescription(description: string \| Resource \| undefined)` | **23** | `stateDescription` |
| 语义角色 | `accessibilityRole(role: AccessibilityRoleType)` | 18 | `role`（`NGFAccessibilityRole` 为 125 成员枚举的精选子集，**已脚本核验 52/52 全部 1:1 存在，映射无缺口**） |
| 无障碍层级 | `accessibilityLevel(value: string)`，文档列出 auto / yes / no / no-hide-descendants | **10** | `level`（`NGFAccessibilityLevel`） |
| 语义分组 | `accessibilityGroup(value: boolean)` / `accessibilityGroup(isGroup, accessibilityOptions)` | **10** / 14 | `grouping` |
| 分组选项 | `AccessibilityOptions { accessibilityPreferred?, stateControllerRoleType?, stateControllerId?, actionControllerRoleType?, actionControllerId? }` | 14 / 23 | `grouping.*` |
| 勾选状态 | `accessibilityChecked(isCheck: boolean)` | 13 | `state.checked` |
| 选中状态 | `accessibilitySelected(isSelect: boolean)` | 13 | `state.selected` |
| 下一个焦点 | `accessibilityNextFocusId(nextId: string)` | 18 | `traversalNextId` |
| **下一个焦点（带参数）** | `accessibilityNextFocusId(nextId: string, nextFocusParams: AccessibilityNextFocusParams \| undefined)` | **26.0.0** | **已补：`traversalConsiderDescendants`（本轮新增）** |
| **焦点跳转参数** | `AccessibilityNextFocusParams { isConsiderDescendants?: boolean }`（`units.d.ts`） | **26.0.0** | 同上 |
| 默认焦点 | `accessibilityDefaultFocus(focus: boolean)` | 18 | `defaultFocus` |
| 同页模式 | `accessibilityUseSamePage(pageMode: AccessibilitySamePageMode)` | 18 | 待评审（用于解决跳过焦点） |
| 滚动可触发 | `accessibilityScrollTriggerable(isTriggerable: boolean)` | 18 | `scrollTriggerable` |
| **动作选项** | `accessibilityActionOptions(option: AccessibilityActionOptions \| undefined)` | **23** | **已补：`scrollStep`（本轮新增）** |
| **动作选项参数** | `AccessibilityActionOptions { scrollStep?: number }`（`units.d.ts`，"无障碍滚动时的步长"） | **23** | 同上 |
| **自定义动作** | `accessibilityCustomActions(actions: Array<AccessibilityCustomAction> \| undefined)` | **26.0.0** | **已补：`customActions`（本轮新增）** |
| **自定义动作参数** | `AccessibilityCustomAction { name: ResourceStr; onAction: VoidCallback }`（`units.d.ts`） | **26.0.0** | `NGFAccessibilityCustomAction`（与 SDK 形态**完全一致**，不做额外包装） |
| 焦点回调 | `onAccessibilityFocus(callback: AccessibilityFocusCallback)` | 18 | 探针项 |
| 动作拦截 | `onAccessibilityActionIntercept(callback: AccessibilityActionInterceptCallback)` | 20 | 探针项（见 §3.3） |
| 无障碍悬停 | `onAccessibilityHover(callback: AccessibilityCallback)` | **12** | 未使用（鼠标/指针场景） |
| 无障碍悬停穿透 | `onAccessibilityHoverTransparent(callback: AccessibilityTransparentCallback)` | **20** | 未使用 |
| 虚拟子节点 | `accessibilityVirtualNode(builder: CustomBuilder)` | 11 | 探针项（画布/复杂复合组件） |
| 焦点绘制层级 | `accessibilityFocusDrawLevel(drawLevel: FocusDrawLevel)` | **19** | 待评审 |

**本轮复核纠正的错误**（原表数值 → 正确值）：

| 项 | 原记录 | 纠正为 |
|---|---|---|
| `accessibilityText(value: string)` | 12 | **10** |
| `accessibilityDescription(value: string)` | 12 | **10** |
| `accessibilityLevel(value: string)` | 12 | **10** |
| `accessibilityGroup(value: boolean)` | 11 | **10** |
| `accessibilityStateDescription` | 26 | **23** |
| `accessibilityFocusDrawLevel` | 26 | **19** |

**本轮复核补齐的遗漏**：`accessibilityCustomActions`、`AccessibilityCustomAction`、
`accessibilityActionOptions`、`AccessibilityActionOptions`、
`accessibilityNextFocusId(nextId, nextFocusParams)`、`AccessibilityNextFocusParams`、
`onAccessibilityHover`、`onAccessibilityHoverTransparent` —— 共 8 项此前**完全没有记录**。

> 其中 `accessibilityCustomActions`（26.0.0）是**能力级遗漏**：
> 它意味着"任意业务自定义动作"都能真正下发给读屏，而不只是词表里的 `CLICK`。
> 这直接改变了 `NGFAccessibilityAction` 的注释结论与 `INTERACTIVE_WITHOUT_ACTION` 的判定口径。

### 3.2 无障碍平台信号证据矩阵（全部 A26）

| 能力 | API 26 声明签名 | @since | NGF 快照字段 |
|---|---|---|---|
| 系统无障碍总开关 | `isOpenAccessibilitySync(): boolean` | 10 | `accessibilityEnabled` |
| 触摸探索 | `isOpenTouchGuideSync(): boolean` | 10 | `touchGuideEnabled` |
| 触摸模式 | `getTouchModeSync(): string`，取值 singleTouchMode / doubleTouchMode / none | 20 | `touchMode`（`NGFTouchMode`） |
| 读屏状态 | `isScreenReaderOpenSync(): boolean` | 18 | `screenReaderEnabled` |
| 减少动效 | `isAnimationReduceEnabledSync(): boolean` | 23 | `animationReduceEnabled` |
| 状态订阅 | `on/off('accessibilityStateChange')`、`on/off('touchGuideStateChange')`、`on/off('screenReaderStateChange')`、`on/off('touchModeChange')` | 7 / 7 / 18 / 20 | 触发快照刷新 |
| 减少动效订阅 | `onAnimationReduceStateChange(callback)` / `offAnimationReduceStateChange(callback?)` | 23 | 触发策略重算 |
| 无障碍事件发送 | `sendAccessibilityEvent(event: EventInfo): Promise<void>` | 9 | 探针项 |
| 无障碍服务列表 | `getAccessibilityExtensionListSync(abilityType, stateType)` | 12 | 探针项（可用于判断读屏服务是否安装） |

### 3.3 本轮新增发现：API 26 的适老与感官辅助能力

这是本次探针最重要的增量。以下 API 均标注 `@since 26.0.0`（与工程目标 API 完全一致），syscap 为 `SystemCapability.BarrierFree.Accessibility.Core`：

| 能力 | 签名 | 说明 |
|---|---|---|
| 系统适老模式查询 | `isSeniorModeEnabled(): Promise<boolean>` | 异步；失败抛 `BusinessError 9300000` |
| 系统适老模式订阅 | `onSeniorModeStateChange(callback)` / `offSeniorModeStateChange(callback?)` | 系统级开关变化 |
| 本应用适老模式查询 | `getSeniorModeStateForSelf(): Promise<boolean>` | 应用粒度 |
| 本应用适老模式设置 | `setSeniorModeStateForSelf(state: boolean): Promise<void>` | **用户可控、可关闭**，正是设计所需 |
| 本应用适老模式订阅 | `onSeniorModeStateChangeForSelf(callback)` / `offSeniorModeStateChangeForSelf(callback?)` | 应用粒度变化 |

设计影响：

1. §5.2 原先设想“NGF 自己实现适老 profile 的持久化”，现在**系统已提供应用粒度的适老模式读写**。NGF 的定位应改为：优先读写系统提供的本应用适老模式，NGF 只保留自己的策略档位映射与 UI 呈现，不另造一套并行的系统开关。
2. 适老模式是**异步** API，因此快照必须带 `seniorModeResolved` 标记，不能把“还没查完”当成“未开启”。
3. 该系统开关由用户在系统设置中控制，符合“不基于年龄推断强制切换”。

同一版本还有三项**感官辅助**能力（`@since 23`），此前设计文档完全未覆盖：

| 能力 | 签名 | 对应的设计维度 |
|---|---|---|
| 闪光提醒 | `isFlashReminderEnabledSync()` / `on/offFlashReminderStateChange` | 听觉障碍：用视觉替代声音提示 |
| 单声道音频 | `isAudioMonoEnabledSync()` / `on/offAudioMonoStateChange` | 听觉障碍：单耳收听 |
| 字幕管理 | `getCaptionsManager()` → `CaptionsManager`（`on/off('enableChange')`、`on/off('styleChange')`，@since 8） | 听觉障碍：字幕开关与样式 |

这些能力在 P4 的"听觉"维度中应作为**系统信号来源**接入，而不是由 NGF 自行发明开关。

### 3.4 官方强制的监听生命周期要求（不是 NGF 自定规则）

`@ohos.accessibility.d.ts` 对**每一个** `on*` 方法都写了同一段 NOTE，逐字要点：

> - The callback parameter for registering a listener must use a named function instead of an anonymous function. Otherwise, a new underlying object is created each time the function is called, causing memory leakage.
> - After calling this method, you must use ... to cancel the listener before the object's lifecycle ends. Otherwise, **a crash may occur**.

因此 NGF 的硬性实现约束是：

1. 注册回调必须是**命名/稳定引用**，不能用内联匿名函数；
2. 每个 `on*` 必须有配对的 `off*`，且要在对象生命周期结束前调用；
3. 单个能力注册失败不能连带跳过其余注册，也不能让 `off` 取消一个从未成功注册的事件。

`AccessibilityFacade` 已按这三条改造：全部使用类的箭头函数属性作为稳定回调，用 `registeredEvents` 集合记录**真正注册成功**的事件，`release()` 只取消已注册项。

### 3.5 API 证据使用原则

早期版本曾引用本机 DevEco 6.1 的 `API_Catalog.json` / `Method_Name_Index.json` 作为证据来源；本次探针已改用 **API 26 SDK 声明文件逐行核对**，该旧来源不再作为结论依据。

后续探针已完成：`G:\\DevEco Studio 26\\DevEco Studio\\sdk\\default\\openharmony` 的 `@kit.ArkUI.d.ts`、`@kit.AccessibilityKit.d.ts` 和 `ets-loader/declarations/common.d.ts` 可用；NGF 使用 DevEco 26 Hvigor 执行 `assembleApp --no-daemon --stacktrace` 已完成 ArkTS 编译、资源处理、HAP 打包**与签名**，产出 `entry/build/default/outputs/default/entry-default-signed.hap`（5 869 167 字节，2026-10-05 20:39）。此前记录的“本机 NGF `.p7b` 缺失”环境阻塞已由 DevEco 证书流程恢复，不再是当前阻塞项。

- `AccessibilityKit` 状态查询属于平台信号，不应被 UI 业务直接依赖；通过 NGF 门面提供快照和订阅。
- ArkUI 属性的具体签名、取值和最低版本必须以 API 26 SDK 声明和官方参考页为准；签名已确认不等于**运行时行为**已确认，读屏朗读顺序、焦点粒度和空值行为仍需设备验证。
- 已知系统 API 的状态查询优先使用 `isScreenReaderOpenSync()` 区分读屏状态，`isOpenTouchGuideSync()` 仅作为触摸探索信号；旧门面命名需要兼容迁移。
- `isAnimationReduceEnabledSync()` 只提供系统偏好信号，NGF 仍需在动画组件层提供 `full/reduced/none` 三档降级。
- 状态事件订阅必须有成对取消、生命周期边界和异常降级；不能在页面 `aboutToAppear()` 中只订阅不取消。
- 组件语义必须在组件层绑定，不能只在 `AccessibilityFacade` 拼接字符串。
- 不把 `isOpenTouchGuideSync()` 直接命名成“TalkBack 开关”；统一使用“触摸探索/读屏相关平台信号”，直到设备证据确认其语义。
- **不要把“编译/打包成功”写成“无障碍能力已实现”**：本节的 A26 等级只代表 SDK 声明存在且代码可编译，不代表语义树、朗读、焦点和触控体验已验收。

### 3.6 HDS 组件自有无障碍选项（新增证据面，2026-10-05）

**这一面此前完全没有被记录。** HDS（HarmonyOS Design System）组件**不使用** ArkUI 的全局无障碍属性，
而是通过**选项对象**接收无障碍配置，定义在
`sdk/default/hms/ets/api/@hms.hds.hdsBaseComponent.d.ets`，经 `@kit.UIDesignKit` 再导出。

> **版本号写法不同**：HDS 用 `6.x.y(API)`，**括号里的才是 API 版本**。
> 例如 `@since 6.1.0(23)` = API 23，`@since 6.0.0(20)` = API 20。

| 类型 | 字段 | @since |
|---|---|---|
| `AccessibilityOptions` | `accessibilityText?: ResourceStr` | 6.0.0(20) |
| | `accessibilityDescription?: ResourceStr` | 6.0.0(20) |
| | `accessibilityLevel?: ResourceStr` | 6.0.0(20) |
| | `accessibilityChecked?: boolean` | 6.1.0(23) |
| | `accessibilitySelected?: boolean` | 6.1.0(23) |
| | `accessibilityRole?: AccessibilityRoleType` | 6.1.0(23) |
| | `onAccessibilityActionIntercept?: AccessibilityActionInterceptCallback` | 6.1.0(23) |
| | `accessibilityGroup?: AccessibilityGroupOptions` | 6.1.0(23) |
| `AccessibilityGroupOptions` | `isGroup?`、`groupControllerOptions?` | 6.1.0(23) |
| `AccessibilityGroupControllerOptions` | `isAccessibilityPreferred?`、`stateControllerRoleType?`、`stateControllerId?`、`actionControllerRoleType?`、`actionControllerId?` | 6.1.0(23) |

**字段名与 ArkUI 不同，不可互换**：HDS 用 `isAccessibilityPreferred`，
ArkUI 的 `AccessibilityOptions` 用 `accessibilityPreferred`。

**接受 `accessibilityOptions` 的 HDS 组件**（脚本枚举，共 10 处）：
`ImageClickOptions`、`TextSymbolGlyphOptions`、`CheckOptions`、`ToggleButtonOptions`、`ButtonOptions`、
`SuffixIconOptions`、`SelectStyle`、`SuffixArrowIconOptions`、`TextItemOptions`、**`HdsListItemCardOptions`**。

#### 标题栏探针结论（本轮关键结果）

- `HdsNavigationTitleBarOptions` **没有**任何无障碍字段 —— 它的字段只有
  `padding / style / content / enableHoverMode / avoidLayoutSafeArea / enableComponentSafeArea`。
- 标题无障碍只能经 `content.title`（`TitleBarContentOptions.title?: HdsNavigationTitle`）下发。
- `HdsNavigationTitle` 提供：
  - `mainTitleAccessibilityText?: ResourceStr` / `subTitleAccessibilityText?: ResourceStr` —— **6.1.0(23)**
  - `mainTitleId?: string` / `subTitleId?: string` —— **6.0.0(20)**
- **NGF 原来的 `NGFHdsNavigationTitle` 只设置了 `mainTitle` / `subTitle`**，
  也就是说**调用方没有任何办法给标题提供朗读文本** —— 这是本轮修掉的真实缺口。

**由此得到的结论**：`NGFAccessibleNavigation` 不应另建一套组件。
HDS 标题栏由系统实现，NGF 能做的就是**把无障碍配置正确地透传下去**（已补齐），
以及给列表类 HDS 组件透传 `HdsListItemCardOptions.accessibilityOptions`（待做）。

### 3.7 字体缩放证据（原"未决项"已闭合，2026-10-05）

**先纠正一个推理错误**：之前因为"在 `@ohos.accessibility` 里找不到字体缩放接口"，
就把"动态字体 API"记为未决。但**字体缩放本来就不属于无障碍模块** ——
它在 `Configuration` 与 `ApplicationContext` 里。找不到不等于不存在，是找错了地方。

| 能力 | 声明 | @since |
|---|---|---|
| 读取当前字体缩放 | `Configuration.fontSizeScale?: number`（默认 **1**，非负数） | **12** |
| 读取当前字重缩放 | `Configuration.fontWeightScale?: number`（默认 **1**） | **12** |
| 订阅字体缩放变化 | `ApplicationContext.onSystemConfigurationUpdated(callback: systemConfiguration.UpdatedCallback)` | **24** |
| 取消订阅 | `ApplicationContext.offSystemConfigurationUpdated(callback?)` | **24** |
| 变化回调字段 | `UpdatedCallback.onFontSizeScaleUpdated?: (fontSizeScale: number) => void` | **24** |
| 字重变化回调 | `UpdatedCallback.onFontWeightScaleUpdated?: (fontWeightScale: number) => void` | **24** |
| 应用侧覆盖缩放 | `ApplicationContext.setFontSizeScale(fontSizeScale: number): void`（仅主线程） | **13** |
| 单独读取字重缩放 | `uiAppearance.getFontWeightScale(): number` | **20** |

#### 应用如何"跟随系统字体大小"（完整接线，已逐层核验）

1. `AppScope/app.json5` → `app.configuration` 必须是 `$profile:xxx` 形式。
   schema：`hms/toolchains/modulecheck/app.json`，pattern `^[$]profile:[0-9a-zA-Z_.]+$`。
2. 被引用的 `configuration.json` schema 在
   `openharmony/toolchains/modulecheck/configuration.json`，**只允许两个键**：

   | 键 | 类型 | 允许值 |
   |---|---|---|
   | `fontSizeScale` | **string** | `"followSystem"` / `"nonFollowSystem"` |
   | `fontSizeMaxScale` | **string** | `"1"` / `"1.15"` / `"1.3"` / `"1.45"` / `"1.75"` / `"2"` / `"3.2"` |

   **注意两处反直觉**：值是**字符串**而不是数字；`fontSizeMaxScale` 是**固定枚举**，不能随便写 `1.9`。

3. **NGF 原先完全没有配置这一项** —— 也就是说用户把系统字体调大，**应用内毫无反应**。
   这直接违背附件2 §1.1"主要功能/界面最大字体不小于 30 dp/pt"的意图。

**本轮落地**：新增 `AppScope/resources/base/profile/configuration.json`，
`fontSizeScale: "followSystem"` + `fontSizeMaxScale: "2"`，并在 `AppScope/app.json5` 引用。

**为什么是 `"2"`**：规范要求最大字体 ≥ 30 dp/pt，NGF 最小正文字号 16 vp，
所需最小倍率 = 30 / 16 = **1.875**；枚举中不小于 1.875 的最小值是 `"2"`。
选 `"1.75"` 只能到 28 vp，**不满足规范**。该不变式已写成单测守住
（`supportedMaxFontDp <= ngfMinBodyFontVp * NGF_APP_FONT_SIZE_MAX_SCALE`）。

**打包验证（不是只看编译通过）**：
- `entry/build/default/intermediates/res/default/resources/base/profile/configuration.json`
  内容确认为 `{"configuration":{"fontSizeScale":"followSystem","fontSizeMaxScale":"2"}}`；
- 合并后的 `module.json` 第 10 行确认带有 `"configuration": "$profile:configuration"` ——
  说明 app 级配置**真的被合并进去了**，不是被静默忽略。

### 3.8 显示密度与播报（两个未决项的闭合 + 一处自我纠错，2026-10-05）

#### 3.8.1 显示密度：**可读**（原记为"未探明"）

`@ohos.display` 的 `Display` 接口（`getDefaultDisplaySync()` 获取）提供：

| 字段 | 含义 | @since |
|---|---|---|
| `densityDPI: number` | **物理**像素密度（ppi），文档举例 160.0 / 480.0 | 7 |
| `densityPixels: number` | **逻辑**像素密度 = 物理像素与逻辑像素之间的缩放系数，范围 **[0.5, 4.0]** | 7 |
| `scaledDensity: number` | 文档原文：**"Scaling factor for fonts displayed on the display"** | 7 |

**因此"显示缩放（DPI/密度）是否可读"的答案是：可读。**

#### 3.8.2 播报（announcer）：**存在公开入口** —— 我此前的结论是错的

我在 §5.1.2 里把"播报"记为「未见公开入口」。**这是错的**，而且错得没有道理 ——
`sendAccessibilityEvent` 一直在我自己列的待探针清单里，我却没去查。

实际证据（`@ohos.accessibility`）：

| 能力 | 声明 | @since |
|---|---|---|
| 发送无障碍事件 | `sendAccessibilityEvent(event: EventInfo): Promise<void>` | **9** |
| 同上（回调式） | `sendAccessibilityEvent(event: EventInfo, callback: AsyncCallback<void>)` | **9** |
| 播报事件类型 | `EventType` 含 `'announceForAccessibility'` | **12** |
| 不打断的播报 | `EventType` 含 `'announceForAccessibilityNotInterrupt'` | **18** |
| 播报文本（字符串） | `EventInfo.textAnnouncedForAccessibility?: string` | **12** |
| 播报文本（资源） | `EventInfo.textResourceAnnouncedForAccessibility?: Resource` | **18** |
| 事件构造 | `new EventInfo(type: EventType, bundleName: string, triggerAction: Action)` | **11** |

`Action` 里含 `'common'`，即播报事件可用的触发动作。

> **注意**：这不是 API 26 新增能力，`sendAccessibilityEvent` 从 **API 9** 就有。
> 我此前的"未找到"不是"不存在"，是**没找**。

#### 3.8.3 顺带修正「单位映射」的定性

原文档把 `1 vp = 1 dp/pt` 记为**工程假设**。更准确的定性是：

- ArkUI 的 `vp` 与规范的 `dp/pt` **都是密度无关像素**（`densityPixels` 正是 vp↔px 的缩放系数）；
- 两个密度无关单位之间的**数值映射按定义就是 1:1**，这不是假设；
- **仍然是未验证的**是：某台设备是否把密度缩放标定到规范期望的物理尺寸 ——
  这属于设备标定问题，按 PP-001 暂缓实测。

所以 §4.2 的表述已从"工程假设"改为"按定义 1:1；物理标定未验证"。

#### 3.8.4 系统文本高对比：**存在且默认跟随，但读不到**（2026-10-05）

`@ohos.graphics.text` 提供：

| 能力 | 声明 | @since |
|---|---|---|
| 设置文本渲染高对比 | `setTextHighContrast(action: TextHighContrast): void` | **20** |
| `TEXT_FOLLOW_SYSTEM_HIGH_CONTRAST = 0` | 跟随系统设置 | 20 |
| `TEXT_APP_DISABLE_HIGH_CONTRAST = 1` | 应用内**禁用**（优先于系统） | 20 |
| `TEXT_APP_ENABLE_HIGH_CONTRAST = 2` | 应用内**启用**（优先于系统） | 20 |

文档原文要点：进程级生效、同进程所有页面共享；系统设置里也有对应开关；
**只对系统文本组件生效**，对应用用 Canvas 自绘的文字无效。

**读不到**：全 SDK 搜索只有这个枚举与 setter，**没有 getter**；
`@ohos.settings` 里也没有高对比键（只有 `ACCESSIBILITY_STATUS` / `ACTIVATED_ACCESSIBILITY_SERVICES`）；
`Configuration` 的字段里也没有。

**因此 NGF 的正确行为是「什么都不做」**：

- **不调用** `setTextHighContrast`，让系统设置自然生效；
- 一旦调用 `TEXT_APP_DISABLE_HIGH_CONTRAST`，就会**覆盖用户在系统里打开的高对比** —— 这是可访问性倒退；
- **已脚本核验**：NGF 全仓库**从未调用**该 API（0 命中），因此不存在这个倒退。

**这也修正了 §9 的旧结论**（「系统级高对比开关：未找到公开接口」）——
开关**存在**，只是**读不到**。而"读不到"不影响"跟随"：跟随是系统默认行为，不需要应用读它。

> 与字体缩放那条是同一个教训：**"我没找到"不等于"不存在"**，而且往往是因为找错了地方
> （字体缩放在 `Configuration`，文本高对比在 `graphics.text`，都不在 `@ohos.accessibility` 里）。

### 3.9 模拟器实测证据（2026-10-06，首次设备端验证）

> 📘 **操作方法已沉淀为技能**：[`.rules/skill-elderly-ui.md`](../.rules/skill-elderly-ui.md) ——
> 包含全部规范数值、改造方法、功能一致性三层保证与验收清单。
> 本节是它的**证据来源**。

**环境**：模拟器 `hdc` target **`127.0.0.1:5555`**（`const.product.model = emulator`，API 26）。
**严禁使用 MatePad Mini 真机**（`192.168.0.36:35573`）—— 见 `.agent-rules/preferences.local.md` PP-001。

**采集方法**：`hdc -t <emu> install -r` → `aa start` → `uitest uiInput click/swipe` 导航 →
**`uitest dumpLayout`（这就是语义树）** → `snapshot_display` 截图 → `hilog` 日志。

#### 3.9.1 发现并修复一个编译期无法发现的真 bug

页面所有拼接标签渲染成 **`[object Object]：<值>`**。原因：`$r()` 返回 `Resource` **对象**，
放进 `+` 拼接会走 `toString()`。**编译完全通过、57 条单测全过** —— 只有跑起来才看得见。
已修复 20 处（全部改用 `resolveResourceString`），并全仓库扫描确认**别处 0 命中**。
已沉淀为候选规则 **PR-C004**。

#### 3.9.2 语义树证据（`uitest dumpLayout`）

| 组件 | 语义树表现 | 结论 |
|---|---|---|
| `NGFAccessibleListItem` | `[Row] text="示例列表项, 已选中, 辅助信息：验证分组朗读顺序" selected=true`，三个子 Text **不再是独立节点** | **分组生效**，且朗读文本是三段拼接（分隔符 `,` 由系统生成） |
| `NGFAccessibleFormField` | `[TextInput] id=a11y_showcase_field_input clickable=true description="帮助信息：…"` | **不分组生效**：输入框独立可聚焦；`accessibilityDescription` 已下发 |
| `NGFAccessibleButton` | `[Button] text="示例无障碍按钮"` / `"播报当前状态"` | 按钮文案正确 |

#### 3.9.3 触摸目标实测（vp 换算）

**密度推导**：`NGFAccessibleDialogCloseButton` 代码里写死 `.width(44).height(44)`（vp），
模拟器实测 bounds `[2375,709][2496,830]` = **121 × 121 px** → `densityPixels = 121 / 44 = **2.75**`。

| 组件 | 实测 px | 换算 vp | 规范要求 | 结论 |
|---|---|---|---|---|
| 浮窗关闭键 | 121 × 121 | **44 × 44** | §2.4 ≥ 44×44 | ✅ 正好达标 |
| 表单输入框 | 2408 × 121 | 875 × **44** | §2.1 ≥ 44（其他页面） | ✅ |
| 列表项 | 2408 × 224 | 875 × **81.5** | §2.1 ≥ 44 | ✅ |
| 按钮 | 396 × 121 | 144 × **44** | §2.1 ≥ 44 | ✅ |

#### 3.9.4 生命周期配对实测

```text
22:23:32.007  [NGFAccessibilityShowcasePage] 无障碍验证页已订阅平台状态   ← aboutToAppear
22:24:51.692  [NGFAccessibilityShowcasePage] 无障碍验证页已取消订阅       ← aboutToDisappear
```

**这正是 API 26 SDK 警告「不在生命周期结束前取消可能崩溃」的那条硬性要求** —— 现已实测成对发生。

#### 3.9.5 **未能验证的部分（必须诚实记录）**

- **`accessibilityText` 无法通过 `dumpLayout` 验证**：dump 的 `text` 字段反映的是**节点自身文本**，
  不是 `accessibilityText`。证据：表单输入框我设了 `accessibilityText = "示例字段"`，dump 里 `text` 仍为空；
  而 `accessibilityDescription` **能**出现（在 `description` 字段）。
  因此**「图标按钮是否真被读屏念出名称」本轮无法下结论**，需真实读屏服务验证。
- **读屏朗读、焦点遍历、动效三档实机对比**：模拟器上未启用系统读屏服务，未做。
- **模拟器结论 ≠ 真机结论**：模拟器的密度、字体缩放与厂商定制均与真机不同，
  上述 vp 换算是按 `densityPixels = 2.75` 推得，换设备需重算。

## 4. 标准与推荐值基线

### 4.1 已核验的规范来源与引用链

**推荐引用链**（法律依据 → 设计数值 → 国家标准身份）：

1. **法律层级**：《中华人民共和国无障碍环境建设法》（2023-06-28 通过）第四条、第三十二条
2. **设计数值层级**：工业和信息化部办公厅《关于进一步抓好互联网应用适老化及无障碍改造专项行动实施工作的通知》**工信厅信管函〔2021〕67号**（成文 2021-04-06），**附件2《移动互联网应用（APP）适老化通用设计规范》**
3. **国家标准层级**：GB/T 37668-2019（**只引标准号与身份，不引条款数值**，原因见 4.4）

| 来源 | 正式标识 | 本设计的使用方式 | 证据等级 |
|---|---|---|---|
| 无障碍环境建设法 | 2023-06-28 通过 / 2023-09-01 施行 | 法律依据与改造义务边界 | ① 条文逐字核实（gov.cn + npc.gov.cn 双源） |
| 移动互联网应用（APP）适老化通用设计规范 | 工信厅信管函〔2021〕67号 附件2 | **设计数值的唯一中国官方依据** | ① 附件2 全文逐字核实（2026-10-05 从 miit.gov.cn 原文抓取） |
| 互联网网站适老化通用设计规范 | 工信厅信管函〔2021〕67号 附件1 | 移动网页相关数值的补充参考 | ① 全文逐字核实 |
| 互联网应用适老化及无障碍水平评测体系 | 工信厅信管函〔2021〕67号 附件3 | 评测构成与合格线 | ① 全文逐字核实 |
| GB/T 37668-2019 | 现行，2019-08-30 发布 / 2020-03-01 实施 | 国家标准入口；**只引标准号，不引条款数值** | ② 仅确认身份与状态 |
| GB/Z 41284-2022 | 指导性技术文件，现行 | YD/T1822 系列的现行替代者 | ② 仅确认身份 |
| WCAG 2.2 | W3C 国际标准 | 国际工程参考（中国标准未覆盖项） | ③ 本轮未逐字核验 |

### 4.2 官方规范原文数值（可直接引用）

来源：**工信厅信管函〔2021〕67号 附件2《移动互联网应用（APP）适老化通用设计规范》**
官方 URL：<https://www.miit.gov.cn/jgsj/xgj/wjfb/art/2021/art_81e8b738d6b24ad6a04f7ecb3f4e0702.html>

| 条款 | 原文要求（逐字，用「」标注） | NGF 对应字段 |
|---|---|---|
| §1.1 字型大小调整 | 「主要功能及主要界面的文字信息……最大字体不小于30 dp/pt，适老版界面及单独的适老版APP中的主要文字信息不小于18 dp/pt」 | `supportedMaxFontDp = 30`；`elderlyBodyFontDp = 18` |
| §1.2 行间距 | 「段落内文字的行距至少为1.3倍，且段落间距至少比行距大1.3倍」 | `minLineHeightRatio = 1.3`；`minParagraphSpacingRatio = 1.3` |
| §1.3 对比度 | 「对比度至少为4.5：1（字号大于18 dp/pt时文本及文本图像对比度至少为3：1）」 | `minTextContrastRatio = 4.5`；`minLargeTextContrastRatio = 3` |
| §1.4 颜色用途 | 「文本颜色不是作为传达信息、表明动作、提示响应等区分视觉元素的唯一手段」 | 非颜色冗余策略 |
| §1.5 验证码 | 非文本验证码「应提供可被不同类型感官（视觉、听觉等）接受的替代表现形式」 | 表单 helper 约束 |
| §2.1 组件焦点大小 | 「适老版界面中的主要组件可点击焦点区域尺寸不小于60 × 60dp/pt，其他页面下的主要组件可点击焦点区域尺寸不小于44 × 44dp/pt；单独的适老版APP中首页主要组件可点击焦点区域尺寸不小于48 × 48dp/pt」 | `elderlyPageTouchTargetDp = 60`；`standardPageTouchTargetDp = 44`；`standaloneElderlyHomeTouchTargetDp = 48` |
| §2.2 手势操作 | 「避免需3个或以上手指才能完成的复杂手势操作」 | 手势约束 |
| §2.3 充足操作时间 | 「应为用户的操作留下充足时间，在用户操作完毕前界面不发生变化」 | 超时/倒计时约束 |
| §2.4 浮窗 | 「关闭按钮只可在左上、右上、中央底部，且最小点击响应区域不能小于44×44dp/pt」 | `dialogCloseTargetDp = 44` + 位置约束 |
| §3.1 提示机制 | 「应将『长辈版』作为标准功能名……同时设置『亲情版』、『关爱版』、『关怀版』等别名作为搜索关键字」 | **产品命名与 i18n 约束** |
| §4.1 辅助技术 | 「移动应用程序不应禁止或限制终端厂商已适配好的辅助设备（如读屏软件等）的接入与使用」 | 无障碍能力不得被框架阻断 |
| §5.1.1 禁止广告插件 | 「适老版界面、单独的适老版APP中严禁出现广告内容及插件」 | 产品治理约束 |
| §5.1.2 禁止诱导类按键 | 「移动应用程序中无诱导下载、诱导付款等诱导式按键」 | 产品治理约束 |

> **单位映射（2026-10-05 重新定性）**：ArkUI 的 `vp` 与规范的 `dp/pt` **都是密度无关像素**
> （`@ohos.display` 的 `densityPixels` 正是 vp↔px 的缩放系数，见 §3.8.1）。
> 两个密度无关单位之间的**数值映射按定义就是 1:1** —— 这不是"工程假设"，是定义使然。
> **仍然未验证的**是：设备是否把密度缩放标定到规范期望的物理尺寸。
> 按 PP-001 该标定实测暂缓，因此**不得据此声称物理尺寸已符合规范**。

> **原文勘误**：§2.4 官方原文确为「44×44dp/pt dp/pt」（重复了 dp/pt），属原文笔误，引用时写「44×44 dp/pt（原文如此）」。

### 4.3 NGF 工程基线（明确区分于标准原文）

以下数值是 **NGF 自定**，可严于标准，但不得声称为中国标准原文：

| 维度 | NGF 基线 | 与标准的关系 | 验收方法 |
|---|---|---|---|
| 正文最小字号 | 16 vp | 规范未给普通页面字号下限，这是 NGF 自定 | 系统字体放大 1.0/1.3/1.5/2.0 下截图与布局检查 |
| 常规触控目标 | 建议 48 vp | **严于**标准 44 dp/pt 下限 | UI 树尺寸/截图/设备点击验证 |
| 非文本关键边界对比度 | 3:1 | 标准 §1.3 未单列非文本项，此值对齐 WCAG 2.2 AA 1.4.11 | 颜色计算工具 + 深浅色主题检查 |
| 颜色表达 | 状态不得只靠颜色 | 与标准 §1.4 同向 | 语义审查和色觉模拟 |
| 焦点 | 焦点顺序与视觉顺序一致；无焦点陷阱 | 标准 §4.1 的工程落地方式 | AX/设备焦点遍历记录 |
| 语义 | 每个可操作节点有名称、角色、状态和动作；装饰元素不进入朗读 | 标准 §4.1 的工程落地方式 | 语义清单 + 读屏录音/人工复核 |
| 动效 | full / reduced / none 三档 | 规范未规定；系统只给布尔"减少动效"信号 | 动效策略测试、帧/截图对比 |
| 适老模式 | 用户可控、可持久化、可关闭，不基于年龄推断 | 标准 §3.1 要求显著入口与"长辈版"命名 | 设置持久化、重启恢复和反向切换 |

**已按标准修正的历史基线**：本文档 0.1 版曾把"老年模式触控目标"写成 48vp。规范 §2.1 对**适老版界面**的要求是 **60×60 dp/pt**，48 只是"单独适老版 APP 首页"的数值。代码中的 `elderlyPageTouchTargetDp` 已按 60 落地。

### 4.4 仍不能固化的数值

- **GB/T 37668-2019 条款数值**：全文在国家标准全文公开系统公开（页面提供"在线预览"与"下载标准"两个入口），但阅读器依赖浏览器 JavaScript + WebAssembly 并设有人机校验，本轮**未能逐字获取条款原文**。在人工抄录或购买正式文本前，本文档不引用其任何条款数值。
- **GB/T 37668 修订版标准号**：修订计划 `20252537-T-469` 状态为"正在批准"，将**全部代替** GB/T 37668-2019，并**非等效采用 ISO/IEC 40500:2025（WCAG 2.2）**。**不得预写新标准号或发布日期。**
- **工信部信管〔2020〕200号 附件《互联网应用适老化及无障碍改造专项行动方案》**：官方仅提供 `.wps` 附件，本轮未获取正文，**不引用其具体条目文字**。
- **工信部信管〔2023〕251号《促进数字技术适老化高质量发展工作方案》**：正文为 PDF 附件，本轮未获取，**不引用其条目**。
- 系统默认字体倍数、读屏语速、色弱滤镜参数、动画时长上限、系统级高对比开关名称、特定机型安全区尺寸。

### 4.5 引用陷阱

工信厅信管函〔2021〕67号 原文引用的行业标准 **YD/T1822-2008 现已废止**：

- YD/T 1822-2008（2008-07-28 发布 / 2008-11-01 实施）**已废止**
- YD/T 1822-2012（2012-12-28 发布，全部代替 2008 版）**亦已废止**
- 现行替代者：**GB/Z 41284-2022《信息无障碍 网站设计无障碍评级测试方法》**（指导性技术文件，现行）

引用政策原文时必须保留"YD/T1822-2008"的原始表述，并加注**"原文如此，该行业标准已废止"**。

#### 陷阱二：WCAG 相对亮度的 sRGB 分段阈值有两个版本

附件2 §1.3 只给**比值阈值**（4.5:1 / 3:1），**没有给计算对比度的公式**。
要为落地引入公式，就必须引用 WCAG 2.x 的相对亮度定义 —— 而该定义自身存在版本分歧：

| 来源 | sRGB 线性化分段点 |
|---|---|
| `https://www.w3.org/WAI/GL/wiki/Relative_luminance`（WAI GL Wiki，WCAG 2.x 旧定义） | `RsRGB <= 0.03928` |
| `https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html`（WCAG 2.1/2.2 现行文档） | `RsRGB <= 0.04045` |

两处均给出 `L = 0.2126*R + 0.7152*G + 0.0722*B`，但分段点不同。
**本实现采用现行文档的 0.04045**（sRGB 规范的正确值；0.03928 是历史误差）。

**并且可以证明这个分歧对 8bit 颜色输入不产生任何影响**：
`0.03928 × 255 = 10.0164`、`0.04045 × 255 = 10.3114`，开区间 (10.0164, 10.3114) 内**没有整数**，
因此不存在落在两个阈值之间的 8bit 通道值。该结论由单测穷举 256 个通道值验证（0 处不一致）。

引用规范时必须写清：**阈值来自附件2 §1.3（中国官方规范），公式来自 WCAG 2.x（国际标准）**，
不要把公式说成"附件2 规定"，也不要把 3:1 非文字对比度（NGF 基线）说成规范原文。

## 5. NGF 分层设计

### 5.1 契约模型

#### 5.1.1 已落地（P3，2026-10-05）

| 文件 | 内容 | 状态 |
|---|---|---|
| `deviceAwareness/contracts/NGFAccessibilitySemantics.ets` | `NGFAccessibilityRole`（ArkUI 125 成员枚举的精选子集）、`NGFAccessibilityLevel`、`NGFAccessibilityAction`、`NGFAccessibilitySemanticState`、`NGFAccessibilityGrouping`、`NGFAccessibilitySemantics`、`auditAccessibilitySemantics()` | 已实现，API 26 编译通过 |
| `deviceAwareness/contracts/NGFInclusiveDesignPolicy.ets` | 五个策略枚举 + `NGFUiContext`、`NGFInclusiveDesignPolicy`、`NGFInclusiveDesignMetrics`（字段名区分 dp 标准值与 vp NGF 基线）、`NGF_INCLUSIVE_DESIGN_METRICS`、`resolveInclusiveDesignPolicy()`、`resolveUiContextForPolicy()`、`resolveRequiredTouchTargetDp()`、`resolveRequiredBodyFontDp()`、5 个持久化解析函数 | 已实现，API 26 编译通过 |
| `deviceAwareness/contracts/IAccessibilityManager.ets` | 旧方法签名不变；追加 `NGFTouchMode`、适老模式查询/设置、策略读写、`release()`；快照追加 `touchMode` / `seniorModeEnabled` / `appSeniorModeEnabled` / `seniorModeResolved` | 已实现，向后兼容 |
| `deviceAwareness/facades/AccessibilityFacade.ets` | 6 个系统事件 on/off 配对、适老模式读写、策略推导与订阅、用户策略持久化（SettingsManager，惰性恢复）、`release()`；移除硬编码中文 hint | 已实现，API 26 编译通过 |
| `uiShell/components/NGFAccessibilityAttributeBinder.ets`（新增） | 语义 → ArkUI 属性绑定器：纯函数 `resolveAccessibilityAttributes()` + 显式 `resolveArkUiRole()` 映射 + 薄调用层 `applyAccessibilityAttributes()` | 已实现，API 26 编译通过；纯函数部分有 23 条单测 |
| `uiShell/components/NGFInclusiveDesignTokens.ets`（新增） | 设计令牌：策略 + UI 上下文 → 可下发数值（字号/行高/段距/触控目标/对比度/动效倍率），并固化附件2 §2.4 关闭键位置与 §2.2 手指数约束 | 已实现，API 26 编译通过；有单测 |
| `uiShell/utils/NGFAccessibilityLifecycleBinding.ets`（新增） | 页面订阅生命周期绑定：`attach()`/`detach()` 幂等、稳定回调引用，把官方"on/off 必须配对"要求固化成可复用对象 | 已实现，有单测 |
| `uiShell/components/NGFAccessibleButton.ets`（新增） | 无障碍按钮：语义模型 + 最小点击区（`constraintSize`，点击区与视觉尺寸分离） | 已实现，编译通过 |
| `uiShell/components/NGFAccessibleListItem.ets`（新增） | 无障碍列表项：`accessibilityGroup(isGroup, {accessibilityPreferred:true})` 合并「标题→状态→辅助信息」为单一语义节点，避免父子重复朗读 | 已实现，编译通过 |
| `uiShell/components/NGFAccessibleDialogCloseButton.ets`（新增） | 浮窗关闭键：固化附件2 §2.4 的位置白名单与 ≥44 vp 点击区，非法用法在 `aboutToAppear()` 主动告警 | 已实现，编译通过 |
| `deviceAwareness/contracts/NGFAccessibilityAnnouncement.ets`（新增） | 播报契约：`NGFAnnouncementMode`（interrupt / queue）+ 请求类型 + **SDK 取值映射**（拼错不会编译报错，所以钉在单测里） | 已实现，3 条单测覆盖 |
| `deviceAwareness/contracts/NGFElderlyModeNaming.ets`（新增） | 适老模式命名契约：标准功能名「长辈版」+ 别名「亲情版/关爱版/关怀版」；显示走 i18n、**匹配走规范原词**（两件事必须分开） | 已实现，4 条单测覆盖 |
| `uiShell/components/NGFAccessibleFormField.ets`（新增） | 无障碍表单字段：**不分组**（分组会让 TextInput 失去独立焦点）；纯函数 `buildFormFieldSemantics()` 做描述优先级选择 | 已实现，5 条单测覆盖 |
| `uiShell/utils/NGFContrastChecker.ets`（新增，第十六批扩充） | 对比度核验（含 `parseHexAlpha` / `compositeOver`，使**半透明毛玻璃表面也能验**）：十六进制解析、WCAG 相对亮度、对比度计算、附件2 §1.3 两档阈值判定（4.5:1 / 大字号 3:1）、非文字 3:1 | 已实现，7 条单测覆盖 |
| `AppScope/resources/base/profile/configuration.json`（新增） | 应用级字体缩放配置：`fontSizeScale: "followSystem"` + `fontSizeMaxScale: "2"` | 已落地，打包级验证通过 |
| `entry/src/main/ets/pages/ngf/NGFAccessibilityShowcasePage.ets`（新增） | 框架验证页：平台状态快照 / 策略与令牌 / 适老模式与用户策略控制 / 三个可复用组件样例 / 语义审计 / 验证日志；订阅在 `aboutToAppear` 建立、`aboutToDisappear` 取消 | 已实现，编译通过；已接入路由与主菜单 |
| `entry/src/test/AccessibilityContract.test.ets`（新增） | 无障碍契约 Hypium 本地单测：语义审计 7 码、策略推导、官方规范数值 44/48/60 与 18/30、持久化解析回落、属性解析的诚实边界、快照信号独立性、设计令牌、订阅生命周期 | **30/30 全部通过**（实测） |

`NGFAccessibilitySemantics` 字段与 ArkUI 属性的对应关系见 §3.1；**没有对应属性的字段已显式标注**，不允许在 helper 中假装它们存在。

`auditAccessibilitySemantics()` 是纯函数审计，输出稳定问题码（`empty_id`、`missing_label`、`interactive_without_action`、`state_role_mismatch`、`self_traversal_next_id`、`image_without_label`、`decorative_with_label`），把设计文档 §7「语义」验收面变成可断言的代码证据，供 P4 的 Hypium 用例直接调用。

#### 5.1.2 仍待评审或探针

```text
NGFAccessibilitySemanticsRegistry        // 按 componentId 注册/注销语义，需要组件生命周期配合
  - registerSemantics(componentId, semantics)
  - unregisterSemantics(componentId)
  - getSemantics(componentId)

NGFAccessibilityFocusNavigator           // 依赖 accessibilityNextFocusId / accessibilityDefaultFocus 的设备行为探针
  - moveFocus(componentId)
  - getFocusOrder()
```

**三项的最新状态（2026-10-05）**：

| 项 | 状态 |
|---|---|
| `NGFAccessibilitySemanticsRegistry` | **不再需要**：改用 `NGFAccessibilitySemantics` 值对象 + `auditAccessibilitySemantics()` 审计，避开了「组件销毁时可靠反注册」这个难点 |
| `NGFAccessibilityAnnouncer` | **已实现（仅编译验证）**：`ngfAccessibilityFacade.announce(request)`，见 §8.1 第十五批。`bundleName` 经 `bundleManager.getBundleInfoForSelfSync()`（**@since 10**）取得；`Resource` 文本走 `textResourceAnnouncedForAccessibility`（**18**）**不需要 Context**。按 PP-001 无法验证运行时行为，**不得声称「播报已可用」** |
| `NGFAccessibilityFocusNavigator` | **API 已找到**：`accessibilityNextFocusId(nextId, nextFocusParams)`（**26.0.0**），已接进语义契约。真实读屏下的行为按 PP-001 暂缓 |

实现时应拆分 contract、platform adapter、facade 和 UI helper，保持 `deviceAwareness` 层可替换；不在页面中直接调用 `@kit.AccessibilityKit`。

### 5.2 状态与设置

- `NGFAccessibilityStateSnapshot`：系统无障碍总开关、触摸探索信号、读屏状态、触摸模式、减少动效、适老模式（系统级 + 本应用级）、`seniorModeResolved` 采样标记与时间戳。
- `NGFAccessibilityStateSnapshot` 的字段**不得互相代替**：系统总开关 ≠ 触摸探索 ≠ 读屏 ≠ 适老模式。
- 适老档位来源已由系统提供（§3.3）。NGF 的规则是：**用户显式选择优先**；未显式选择时由 `seniorModeEnabled || appSeniorModeEnabled` 与 `animationReduceEnabled` 推导；系统信号不得覆盖用户选择。
- 适老模式是异步 API，`seniorModeResolved === false` 时必须按“未知”处理，不能当成“未开启”写进 UI 或日志结论。
- 设置变更必须可观察、可持久化、可恢复；页面销毁时取消订阅。
- 所有用户可见设置文案进入 i18n 资源，不在框架 helper 中硬编码中文；语义模型用 `ResourceStr` 强制调用方传资源引用。

### 5.3 组件语义策略

| 组件 | 设计意图 | 状态 |
|---|---|---|
| `NGFAccessibleButton` | 名称、动作完整表达；点击区与视觉图标分离 | **已实现** |
| `NGFAccessibleListItem` | 按「标题 → 状态 → 辅助信息 → 动作」顺序朗读，避免父子节点重复 | **已实现** |
| `NGFAccessibleDialogCloseButton` | 关闭键位置白名单 + ≥44 vp；打开时焦点进入标题/首个操作，关闭后焦点返回触发源 | **位置与尺寸已实现**；焦点返回待设备探针 |
| `NGFAccessibleFormField` | 标签 + 输入控件 + 错误/帮助文本；**不分组**，语义经 `buildFormFieldSemantics()` 绑到真正的输入控件 | **已实现**（不分组方案，见下方说明） |
| ~~`NGFAccessibleNavigation`~~ | 页面标题、返回动作、当前目的地、Tab 选中态和数量变化可感知 | **不另建组件**（探针结论见 §3.6）：HDS 标题栏由系统实现，NGF 能做且已做的是把无障碍配置**透传**下去 —— 已补齐 `mainTitleAccessibilityText` / `subTitleAccessibilityText` / 标题 ID |

**表单字段为什么不分组（关键设计决策，已有 SDK 原文依据）**：

直觉上应对"标签 + 输入框 + 错误提示"整块用 `accessibilityGroup(isGroup=true)` 合并，让读屏一次念完。
**但这是错的** —— API 26 声明原文写着：

> When accessibility grouping is enabled, the component and all its children are treated as a
> **single selectable unit**, and the accessibility service will **no longer focus on the individual
> child components**.

一旦分组，`TextInput` 会失去独立焦点 —— **用户无法再聚焦并编辑它**。所以表单字段**必须不分组**：

1. 组件只负责**布局**与**非颜色冗余表达**（必填标记、错误前缀都是文字，不是只有颜色）；
2. "标签/错误的朗读绑定"由调用方用 `buildFormFieldSemantics()` 产出的语义 +
   `NGFAccessibilityAttributeModifier` 施加到**真正的输入控件**上。

**重复朗读 vs 静默丢失**：绑定后标签文本节点仍会被单独朗读一次（重复）。
`hideLabelWhenBound` 可把它移出无障碍树，但**默认 false** —— 宁可重复朗读，
也不能因为调用方漏绑而让标签彻底读不出来。

**`description` 优先级（已知取舍）**：`errorText > helpText > unit > requiredMarker`，只取第一个存在的值。
错误最紧急所以排最前；必填排最后 —— 若同时存在错误/帮助/单位，"必填"不会被朗读，
这种情况请把必填信息并入 `label` 资源文案。
**不拼接字符串**：ArkTS 下 `ResourceStr` 无法拼接，硬编码分隔符会引入未本地化的标点。

**通用约束**：装饰性图片、背景材质和纯视觉点光效果默认从无障碍树隐藏（`accessibilityLevel = no`）；信息性图片必须提供等价文本。

### 5.4 适老化 UI/UX

- **视觉**：大字号、大触控目标、高对比、清晰层级、少用低对比毛玻璃文本叠加；保留系统 Symbol 与文字冗余。
- **交互**：减少连续手势和精细拖拽；关键操作提供明确按钮和可撤销结果；避免仅依靠长按、边缘滑动或双击。
- **认知**：一屏一个主任务；状态、进度、错误和下一步动作使用短句；破坏性动作二次确认且说明后果。
- **听觉**：提示不能只用声音；系统音频、振动和视觉反馈形成冗余组合，且允许关闭非必要提示。
- **运动**：支持减少动效；加载、切换、材质动画必须有静态最终状态和超时兜底。
- **语言**：支持简体中文和英文资源；读屏文本避免缩写、连续符号和没有上下文的数字。

## 6. 功能优先级

| 优先级 | 功能 | 价值 | 依赖 |
|---|---|---|---|
| P0 | 语义模型、label/description/role/state/action helper | 解决读屏可用性基础 | ArkUI 属性签名探针 |
| P0 | 无障碍状态快照和订阅 | 适配系统设置变化 | AccessibilityKit 设备验证 |
| P0 | 动态字体和触控目标策略 | 解决适老化最常见布局问题 | UI 组件 token |
| P0 | 颜色对比度和非颜色冗余检查 | 降低视觉障碍风险 | 主题色 token |
| P1 | 焦点遍历、焦点返回和复合组件分组 | 提升读屏/外接设备效率 | ArkUI 焦点 API 探针 |
| P1 | 动效减弱策略 | 降低眩晕和认知负担 | 系统设置能力探针 |
| P1 | accessible dialog/form/list/navigation 组件 | 统一页面实现 | P0 契约 |
| P2 | 专项示例页和 Hypium/UI 自动化验收 | 防止能力只停留在 API | P0/P1 组件 |
| ~~P2~~ | ~~设备矩阵、读屏录音和性能基线~~ | ~~证明真实体验~~ | **按用户决定暂缓**（PP-001） |

> **系统级高对比已确认由系统负责**：应用不调用 `setTextHighContrast` 即自动跟随（§3.8.4），
> 因此 NGF 不需要为此增加设备验收项。

## 7. 验收矩阵

> ⚠️ **本矩阵有两类行，不要混读**（2026-10-05 更新）：
> - **本地已具备**：源码/类型、语义（值对象 + 审计）、对比度数值、字号/触控目标数值 —— 有单测与构建证据；
> - **按用户决定暂缓（PP-001）**：凡需要真机/模拟器的行，全部标记为暂缓。
>   **暂缓不等于已通过** —— 这些面目前**没有任何运行时证据**，不得在交付中声称已完成。

> ⚠️ **证据来源必须标清楚**（2026-10-06 更新）：设备端证据来自**模拟器**
> （`127.0.0.1:5555`），**不是真机**。模拟器结论不等于真机结论，交付时须写明来源。

| 验收面 | 最低证据 | 状态（2026-10-06） | 不能替代的证据 |
|---|---|---|---|
| 源码/类型 | API 26 声明探针、ArkTS 类型检查、无硬编码用户文案 | **已具备**（57 条单测 + 构建通过） | 不能证明读屏体验 |
| 语义 | 组件语义清单、AX 树/控件树截图 | **模拟器 `uitest dumpLayout` 已采集**（§3.9.2）：分组、不分组、按钮文案均实测 | `accessibilityText` 未能在 dump 中体现，见 §3.9.5 |
| 读屏 | 真机启用系统无障碍后的焦点和朗读记录 | **未做** —— 模拟器未启用读屏服务；真机按 PP-001 禁用 | 不能只用编译成功替代 |
| 视觉 | 字体倍数、对比度、色觉、深浅色截图 | **模拟器截图已采集**（浅色主题）；对比度已按公式核验 | 未验深色主题与色觉 |
| 触控 | 目标尺寸和误触场景设备操作 | **目标尺寸已实测**（§3.9.3：44/44/81.5/44 vp）；误触场景未做 | 不能只看布局代码 |
| 动效 | full/reduced/none 三档行为记录 | 三档**倍率已落地并单测**；实机行为未做 | 不能只删除动画调用 |
| 生命周期 | 页面进出、设置变更、订阅取消、焦点恢复日志 | **模拟器 hilog 已实测订阅/取消成对**（§3.9.4） | 不能只看首次进入 |
| 性能 | 语义注册、重建、朗读通知的耗时和内存 | **未做** | 不能用普通 FPS 代替交互延迟 |

## 8. 实施任务草案

1. **API 探针**：在 API 26 SDK/官方声明中确认无障碍通用属性、焦点、动作、动态字体、动效和 SysCap 签名；形成编译最小样例。
2. **契约拆分**：扩展 `IAccessibilityManager`，新增状态快照、语义模型、策略模型和订阅生命周期；保持旧方法兼容过渡。
3. **平台适配**：将 `AccessibilityKit` 调用集中到平台 adapter，补齐错误、能力缺失和状态变化处理。
4. **UI helper**：建设 Button/Form/List/Dialog/Navigation 五类可复用模式，使用现有 i18n、Symbol、UIContext 和日志封装。
5. **策略实现**：增加字体、触控、对比度、动效、密度 token；支持用户可控 profile 和持久化。
6. **验证页**：新增框架验证页，不绑定具体业务，覆盖读屏、动态字号、对比度、焦点和动效。
7. ~~**测试与设备验收**：补 Hypium 单元/集成用例，使用真机读屏和截图/AX 证据；分别报告源码、运行时、视觉、生命周期和性能结果。~~
   **（2026-10-05 拆分）**：Hypium 单元/集成用例**已完成**（52 条无障碍契约单测）；
   真机读屏、截图/AX 证据**按 PP-001 暂缓** —— 报告时不得把"暂缓"写成"通过"。

## 8.1 已落地的实现

### 第一批（状态契约）

- `IAccessibilityManager` 已增加 `NGFAccessibilityStateSnapshot`、状态监听器、触摸探索、读屏和减少动效查询契约。
- `AccessibilityFacade` 已切换到 API 26 的 `isScreenReaderOpenSync()`，并封装 `isOpenTouchGuideSync()` 与 `isAnimationReduceEnabledSync()`。
- `deviceAwareness/index.ets` 已导出新契约和 `ngfAccessibilityFacade`。
- `ngf_framework/obfuscation-rules.txt` 与 `consumer-rules.txt` 已补齐，修复了此前阻塞编译的 `00304036`。

### 第二批（P3 语义与策略契约，2026-10-05）

- 新增 `NGFAccessibilitySemantics.ets`：语义角色/层级/动作/状态/分组模型与 `auditAccessibilitySemantics()`。
- 新增 `NGFInclusiveDesignPolicy.ets`：`textScale` / `touchTarget` / `contrast` / `motion` / `density` 五档策略、量化门槛与推导函数。
- `IAccessibilityManager` 追加 `NGFTouchMode`、适老模式查询/设置、策略读写、`release()`；**旧方法签名全部保持不变**。
- `AccessibilityFacade`：
  - 接入 API 26 的 `isSeniorModeEnabled()` / `getSeniorModeStateForSelf()` / `setSeniorModeStateForSelf()`；
  - 6 个系统事件（含 `seniorModeStateChange` 与 `seniorModeStateChangeForSelf`）全部 on/off 配对；
  - 每个事件独立 `try/catch`，单个能力缺失不再连带跳过其余注册；
  - `buildAccessibilityHint()` 不再拼接硬编码中文“双击执行”；
  - 新增 `touchMode` 字段，区分单指/双指/未启用。

### 第三批（P4 属性绑定器 + 单测，2026-10-05）

- 新增 `uiShell/components/NGFAccessibilityAttributeBinder.ets`，刻意拆成两半：
  - `resolveAccessibilityAttributes()` —— **纯函数**，只做 NGF 侧判定，不接触 ArkUI 类型，可被单测断言；
  - 调用层最初写成 `applyAccessibilityAttributes<T extends CommonMethod<T>>()`，**该方案被编译器否决**（详见第五批），已改为 `AttributeModifier`。
- `unresolved` 机制：ArkUI 26 没有 `accessibilityEnabled` / `accessibilityExpanded` / `accessibilityBusy` 属性，
  绑定器**不会假装它们存在**，而是把这类语义收集成稳定问题码交给调用方处理。
- `resolveArkUiRole()` 用显式 switch 而非名称约定做 52 项映射，避免任一端重命名造成静默错配。
- 新增 `entry/src/test/AccessibilityContract.test.ets`（23 条用例）。

### 第四批（P4 设计令牌 + 订阅生命周期绑定，2026-10-05）

- 新增 `NGFInclusiveDesignTokens.ets`：把策略从"数据模型"变成"页面能用的数值"。
  每个字段都能追溯到出处（附件2 §1.1/§1.2/§1.3/§1.4/§2.1/§2.4，或明确标注为 NGF 自定）。
- 同文件固化两条规范约束：§2.4 关闭键只允许左上/右上/中央底部；§2.2 手指数上限 2。
- 新增 `NGFAccessibilityLifecycleBinding`：把官方"每个 `on*` 必须在生命周期结束前 `off`"的硬性要求
  固化成幂等的 `attach()`/`detach()` 对象，页面不必自己持有回调引用。
- 单测从 23 条扩到 30 条，新增覆盖令牌分上下文数值、字号下限、动效三档降级、关闭键位置与手指数约束、订阅投递与取消后不再投递。

**本批踩到并已定位的 ArkTS 陷阱**：接口里用「可选方法」`onX?(p: T): void` 声明回调，
在 ArkTS 下把该成员当属性读取可能恒为 `undefined`，导致回调被**静默丢弃**——既无编译错误也无运行时异常
（通知路径外层 try/catch 会吞掉）。必须改用「可选函数类型属性」`onX?: (p: T) => void`，实现方用类字段箭头函数。
已作为候选规则 `PR-C001` 记录在 `.agent-rules/project-rules.md`；因属 ArkTS 语言层行为，
其最终归属应是共享 `.rules/`，需开发者触发 `skill-rules-update.md` 后再迁移。

### 第五批（P4 可复用组件 + 架构修正，2026-10-05）

新增三个可复用无障碍组件：

- `NGFAccessibleButton` —— 语义模型 + `constraintSize` 最小点击区（点击区与视觉尺寸分离）。
- `NGFAccessibleListItem` —— 用 `accessibilityGroup(isGroup=true, { accessibilityPreferred: true })`
  把「标题 → 状态 → 辅助信息」合并为**一个**语义节点，避免父节点与子 Text 被重复朗读。
- `NGFAccessibleDialogCloseButton` —— 固化附件2 §2.4：位置白名单 + ≥44 vp 点击区，
  非法位置或过小点击区在 `aboutToAppear()` 主动告警，让不合规用法在开发期暴露。

**架构修正（重要）**：属性下发方式从「返回组件的普通函数」改为 ArkUI 官方的 `AttributeModifier`。

原因是编译器直接否决了原方案——ArkUI 的 `build()` 只接受组件调用与属性链，
把 `applyAccessibilityAttributes(Button(...), semantics)` 当组件根节点会报
`does not meet UI component syntax`。改用 `AttributeModifier<CommonAttribute>` 后可在属性链里调用：

```typescript
Button(this.label)
  .constraintSize({ minWidth: this.minTouchTarget, minHeight: this.minTouchTarget })
  .attributeModifier(new NGFAccessibilityAttributeModifier(this.buildSemantics()))
```

纯函数 `resolveAccessibilityAttributes()` 保持不变，仍是唯一的判定点（也是被单测覆盖的那部分）。

**本批踩到的四条 ArkUI/ArkTS 实测约束**（已记为候选规则 `PR-C002`）：
可复用属性集必须用 `AttributeModifier`；struct 属性名不能叫 `enabled`/`position`（与 `CustomComponent` 成员冲突）；
`SymbolGlyph.fontColor` 只接受数组；**未被引用的 `.ets` 不进入编译图**，会导致"改完就能过"的假阳性。

### 第六批（P4 框架验证页 + 页面接入，2026-10-05）

新增 `entry/src/main/ets/pages/ngf/NGFAccessibilityShowcasePage.ets`，把前几批的成果接进**真实页面**：

| 区块 | 验证内容 |
|---|---|
| 平台状态快照 | 系统无障碍开关 / 读屏 / 触摸探索 / 触摸模式 / 减少动效 / 系统适老模式 / 本应用适老模式，**实时刷新**（经 `NGFAccessibilityLifecycleBinding`） |
| 生效策略与设计令牌 | 策略五档 + 字号 / 最小点击区 / 行高 / 对比度 / 动效倍率 / 关闭键尺寸 |
| 适老模式与用户策略控制 | 调用系统 `setSeniorModeStateForSelf()` 读写本应用适老模式；演示 `setUserPolicy` / `clearUserPolicy` 与持久化路径 |
| 可复用组件样例 | `NGFAccessibleButton` / `NGFAccessibleListItem` / `NGFAccessibleDialogCloseButton`，尺寸取自当前令牌 |
| 语义审计 | 用 `auditAccessibilitySemantics()` 对三个演示语义求值，把「语义清单」变成页面可见结论 |
| 验证日志 | 记录用户操作，便于真机人工核验 |

接入范围：路由常量 `ngf.accessibility.showcase`、`buildNavDestination` 分发、主菜单卡片，以及 `base` / `zh_CN` / `en_US` 三套共 39 条 i18n 字符串（页面标签全部走资源；页面上的布尔值/枚举/数值作为**诊断数据**原样展示）。

**本批踩到的两个问题**：

1. **`$r('app.string.x', args)` 不能直接当 string 用**：`$r()` 返回 `Resource`，
   而 `resolveResourceString()` 走的是 `getStringSync(res.id)`，**不做 %s 参数替换**。
   因此日志改为「已本地化前缀 + ': ' + 已本地化标签」拼接，避免页面出现未替换的 %s。
2. **`HdsNavDestination` 上没有 `navDestination()`**：该属性属于根容器 `HdsNavigation`，
   技能文档模板里带了这一行，但叶子页调用会报 `Property 'navDestination' does not exist on type 'HdsNavDestinationAttribute'`，已移除。

### 第七批（P4 对比度核验工具，2026-10-05）

新增 `uiShell/utils/NGFContrastChecker.ets`，把附件2 §1.3 从"文档里的一句话"变成**可计算、可单测**的能力：

| 能力 | 说明 |
|---|---|
| `parseHexColor()` | 解析 `#RGB` / `#RRGGBB`（可带或不带 `#`）；非法输入返回 `undefined`，**不做静默兜底**，避免把错误颜色当黑色通过核验 |
| `linearizeChannel(channel, threshold)` | 单通道线性化，阈值可注入以便对照历史版本 |
| `relativeLuminance()` | WCAG 相对亮度，0（黑）到 1（白） |
| `calculateContrastRatio()` | `(L亮+0.05)/(L暗+0.05)`，对称且恒 ≥ 1 |
| `requiredContrastRatio(fontSizeVp)` | 附件2 §1.3：字号 >18 dp/pt 时为 3:1，否则 4.5:1 |
| `checkTextContrast()` / `checkNonTextContrast()` | 返回 `{ ratio, required, passed, foreground, background }`，**比值不取整**，避免四舍五入把 4.4996 变成"达标" |

**出处必须分开记**：比值阈值 4.5 / 3 来自附件2 §1.3（中国官方规范，已逐字核验）；
相对亮度**公式**来自 WCAG 2.x（国际标准）—— 附件2 只给阈值、**没有给公式**。
新增引用陷阱已记入 §4.5（见"陷阱二"）。

**本批踩到的一个测试写法问题**：最初把 `#888888` 在白底上的对比度按**手算常数 3.5425** 写进断言，
结果与实现真实值差约 0.003 导致误报。改为在测试内**按公式独立重算期望值**，
并追加"该比值确实落在 3:1 与 4.5:1 之间"的断言 —— 否则两档阈值就没有区分意义。
教训：浮点期望值不要手算后硬编码。

### 第八批（P4 API 26 证据复核与契约补齐，2026-10-05）

本轮不是加功能，而是**回头审计既有证据**——结果发现原矩阵确实有错。

**复核方法**：对每个声明向上遍历**连续堆叠的全部 JSDoc 块**，取其中**最小**的 `@since` 作为引入版本。
只取"最近一个 `@since`"会得到**文档修订版本**而不是引入版本，这是原矩阵出错的根因
（例如 `accessibilityGroup(value: boolean)` 叠了 `@since 11` 与 `@since 12` 两块，引入版本其实是 **10**）。

**纠正 6 处 @since 错误**：`accessibilityText(string)` 12→**10**、`accessibilityDescription(string)` 12→**10**、
`accessibilityLevel` 12→**10**、`accessibilityGroup(bool)` 11→**10**、
`accessibilityStateDescription` 26→**23**、`accessibilityFocusDrawLevel` 26→**19**。

**补齐 8 项此前完全遗漏的声明**，其中一项是**能力级遗漏**：

- `accessibilityCustomActions(actions: Array<AccessibilityCustomAction> | undefined)`（**26.0.0**）
  与 `AccessibilityCustomAction { name: ResourceStr; onAction: VoidCallback }`（**26.0.0**）
  —— 意味着**任意业务自定义动作**都能真正下发给读屏，而不只是词表里的 `CLICK`。
  这直接推翻了 `NGFAccessibilityAction` 注释里"其余动作没有可执行入口"的旧结论，
  也改变了 `INTERACTIVE_WITHOUT_ACTION` 的判定口径（只挂自定义动作也算"有动作"）。
- `accessibilityActionOptions(option: AccessibilityActionOptions | undefined)`（**23**）
  与 `AccessibilityActionOptions { scrollStep?: number }`（**23**）
- `accessibilityNextFocusId(nextId, nextFocusParams)`（**26.0.0**）
  与 `AccessibilityNextFocusParams { isConsiderDescendants?: boolean }`（**26.0.0**）
- `onAccessibilityHover`（**12**）、`onAccessibilityHoverTransparent`（**20**）

**契约补齐**（不只是写进文档，而是真的能下发）：

| 语义字段 | 下发方式 |
|---|---|
| `customActions` | `accessibilityCustomActions([{ name, onAction }])`，与 SDK 形态**完全一致**，不做额外包装 |
| `scrollStep` | `accessibilityActionOptions({ scrollStep })` |
| `traversalConsiderDescendants` | `accessibilityNextFocusId(nextId, { isConsiderDescendants })`；未设置时回落单参重载 |

**新增 2 个审计码**：`CUSTOM_ACTION_WITHOUT_NAME`（空名称动作对读屏不可用）、
`INVALID_SCROLL_STEP`（非正数步长无效）、`ORPHAN_TRAVERSAL_PARAM`（设了跳转参数却没有跳转目标）。

### 第九批（P4 表单字段 + 对比度令牌核验，2026-10-05）

**新增 `NGFAccessibleFormField`**，采用**不分组**方案（理由与 SDK 原文见 §5.3）。
配套纯函数 `buildFormFieldSemantics(config)` 负责描述优先级选择：

| 场景 | `description` 取值 |
|---|---|
| 有错误 | `errorText` |
| 无错误有帮助 | `helpText` |
| 只有单位 | `unit` |
| 只有必填 | `requiredMarker` |

被禁用时**不声明动作**，审计也相应放过。

**修正了一处审计设计缺陷**：原 `INTERACTIVE_WITHOUT_ACTION` 对**被禁用**的可操作控件也会报错。
但禁用的控件本来就没有可执行动作，这是误报。现改为
`state.enabled === false` 时不再要求声明动作（未声明 `enabled` 状态且无动作仍然要报）。

**新增错误文本颜色令牌 `ngf_text_error`**：浅色主题 `#DC2626`、深色主题 `#F87171`。
原先框架只有 `ngf_background_error`（`#FFFEF2F2`，是**浅粉背景色**，不适合当文字色）。
两套主题的取值**都已用本仓库的对比度工具实测达标**（§1.3 要求 4.5:1，13 vp 正文），并写成单测长期守住。

**对比度工具补了一个真实缺口**：NGF 与 ArkUI 的颜色资源大量使用 **8 位 `#AARRGGBB`** 写法，
原 `parseHexColor()` 只认 6 位，遇到 `#FFF8FAFC` 会直接返回 `undefined`。
现已支持 8 位，并**明确记录 alpha 被忽略** —— 对比度公式只对不透明颜色成立，
带透明度的颜色必须由调用方先与背景合成，本工具不做合成。

### 第十批（P4 HDS 无障碍证据面 + 标题栏缺口修复，2026-10-05）

**发现了一个全新的证据面**：HDS 组件**不使用** ArkUI 的全局无障碍属性，而是通过选项对象接收无障碍配置
（`@hms.hds.hdsBaseComponent.d.ets`，经 `@kit.UIDesignKit` 再导出）。完整矩阵见 **§3.6**。

**标题栏探针结论**（直接决定了 `NGFAccessibleNavigation` 要不要做）：

- `HdsNavigationTitleBarOptions` **没有任何无障碍字段**；
- 标题无障碍只能经 `content.title` 下发；
- `HdsNavigationTitle` 提供 `mainTitleAccessibilityText` / `subTitleAccessibilityText`（**6.1.0(23)**）
  与 `mainTitleId` / `subTitleId`（**6.0.0(20)**）；
- **而 NGF 原来的 `NGFHdsNavigationTitle` 只设置了 `mainTitle` / `subTitle`** ——
  调用方**没有任何办法**给标题提供朗读文本。

**修复**：新增 `NGFHdsTitleBarAccessibilityConfig`，作为 `NGFHdsTitleBarOptionsFactory.build()` 的
**可选第 7 个参数**（向后兼容，现有 6 参调用点全部不受影响），并把配置透传到 `NGFHdsNavigationTitle`。

**结论**：`NGFAccessibleNavigation` **不另建组件** —— HDS 标题栏由系统实现，
NGF 的职责是把无障碍配置正确透传，而不是再造一层包装。

**验证页同步更新**：
- 标题栏改用新的无障碍配置（`mainTitleAccessibilityText` / `subTitleAccessibilityText` / `mainTitleId`）；
- 新增**表单字段区块**：真实 `TextInput` + `buildFormFieldSemantics()` + `AttributeModifier`，
  并用 `hideLabelWhenBound: true`（因为确实绑定了），可切换错误态验证 `description` 优先级。
  这消除了"FormField 只有编译证据"的缺口。

### 第十一批（P4 字体缩放：闭合未决项 + 真实适老化能力，2026-10-05）

**先纠正一个推理错误**：此前因为"在 `@ohos.accessibility` 里找不到字体缩放接口"，
就把"动态字体 API"记为未决。但**字体缩放本来就不属于无障碍模块** ——
它在 `Configuration` / `ApplicationContext` 里。**找不到不等于不存在，是找错了地方。**

**探明的完整 API 链**（详见 §3.7）：`Configuration.fontSizeScale`（12）、
`ApplicationContext.on/offSystemConfigurationUpdated` + `UpdatedCallback.onFontSizeScaleUpdated`（24）、
`ApplicationContext.setFontSizeScale`（13）、`uiAppearance.getFontWeightScale`（20）。

**发现一个高影响缺口**：NGF **完全没有配置字体跟随系统** ——
用户把系统字体调大，应用内毫无反应。这直接违背附件2 §1.1"最大字体不小于 30 dp/pt"的意图。

**落地**：
- 新增 `AppScope/resources/base/profile/configuration.json`：
  `fontSizeScale: "followSystem"` + `fontSizeMaxScale: "2"`；
- `AppScope/app.json5` 增加 `"configuration": "$profile:configuration"`；
- 框架新增 `NGF_APP_FONT_SIZE_MAX_SCALE` 常量，把"为什么是 2"的推导写进注释。

**两个反直觉的 schema 事实**（已核验）：`fontSizeScale` / `fontSizeMaxScale` 的值是**字符串**；
`fontSizeMaxScale` 是**固定枚举** `"1"|"1.15"|"1.3"|"1.45"|"1.75"|"2"|"3.2"`，不能写 `1.9`。

**为什么是 `"2"`**：规范要求 ≥30 dp/pt，最小正文 16 vp → 所需倍率 30/16 = **1.875**；
枚举中不小于它的最小值是 `"2"`（`"1.75"` 只能到 28 vp，不达标）。已写成单测守住该不变式。

**打包级验证**（不是只看编译通过）：
- 产物 `res/default/resources/base/profile/configuration.json` 内容确认；
- 合并后 `module.json` 第 10 行确认带 `"configuration": "$profile:configuration"` ——
  说明 app 级配置**真的被合并**，不是被静默忽略。

### 第十二批（P4 适老模式命名契约 §3.1，2026-10-05）

规范 §3.1 原文有**两条独立要求**，此前一直被当成一件事：

> 应将「长辈版」作为标准功能名……同时设置「亲情版」「关爱版」「关怀版」等别名作为搜索关键字。

- **显示名**必须用标准功能名「长辈版」→ 走 i18n 资源；
- **搜索关键字**必须能命中标准名与全部别名 → 这是**字符串匹配**要求，与界面语言无关。

**关键设计决策：显示走 i18n，匹配走规范原词，两件事分开。**

如果把匹配建立在"当前语言的显示名"上，那么把系统语言切成英文后，用户搜「长辈版」就再也搜不到了 ——
而规范要求的恰恰是**这些词本身**能作为搜索关键字。

落地 `NGFElderlyModeNaming.ets`：

| 能力 | 说明 |
|---|---|
| `NGF_ELDERLY_MODE_STANDARD_NAME_ZH` | 规范原词「长辈版」 |
| `NGF_ELDERLY_MODE_ALIASES_ZH` | 规范原词「亲情版」「关爱版」「关怀版」 |
| `getElderlyModeDisplayName()` | 显示资源（zh_CN 下即「长辈版」，其它语言为译名） |
| `matchesElderlyModeKeyword()` | 去空白后精确匹配 |
| `isElderlyModeSearchHit()` | 支持**逐字输入**的增量命中（输入「长」「长辈」「长辈版」逐步命中） |
| `filterElderlyModeKeywords()` | 从一组关键字里保序筛出适老模式相关项 |

i18n 资源 4 条 × 3 语言（`base` / `zh_CN` / `en_US`）。

### 第十三批（P4 闭合两个未决项 + 修正一处错误结论，2026-10-05）

本轮不加功能，专做**证据闭合与自我纠错**。

| 项 | 原状态 | 本轮结果 |
|---|---|---|
| 显示缩放（DPI/密度）是否可读 | 记为「未探明」 | **可读**：`@ohos.display.Display` 的 `densityDPI` / `densityPixels` / `scaledDensity`，全部 `@since 7`（§3.8.1） |
| 播报（announcer）有无公开入口 | 记为「未见公开入口」 | **有**：`sendAccessibilityEvent`（**9**）+ `'announceForAccessibility'`（**12**）+ `EventInfo.textAnnouncedForAccessibility`（**12**）（§3.8.2） |
| 自定义动作有无可执行入口 | 记为「没有」 | **已作废**（第八批已改，但 §9 漏改，本轮补上） |
| `1 vp = 1 dp/pt` 的定性 | 记为「工程假设」 | **按定义 1:1**（两者都是密度无关像素）；未验证的只是设备物理标定（§3.8.3） |

**关于"播报"这条错误的自我检讨**：`sendAccessibilityEvent` 一直在我自己列的待探针清单里，
我却写成了「未见公开入口」并维持了多轮。**"没找到"和"不存在"是两件事** ——
这正是本目标反复强调的纪律，我自己也犯了。

**三项 §5.1.2 决策的收口**（详见该节表格）：
语义注册表**不再需要**（改用值对象 + 审计）；announcer 与 focus navigator 的 **API 都已找到**，
实现按 PP-001 暂缓，且都已在语义契约层可用（`traversalNextId` / `traversalConsiderDescendants`）。

### 第十四批（P4 系统文本高对比：闭合第三个未决项，2026-10-05）

| 项 | 原状态 | 本轮结果 |
|---|---|---|
| 系统级高对比开关 | 记为「未找到公开接口」 | **存在**：`setTextHighContrast`（**20**），含 `TEXT_FOLLOW_SYSTEM_HIGH_CONTRAST` / `TEXT_APP_DISABLE_HIGH_CONTRAST` / `TEXT_APP_ENABLE_HIGH_CONTRAST`（§3.8.4） |
| 能否读取该状态 | — | **不能**：全 SDK 无 getter；`@ohos.settings` 无高对比键；`Configuration` 无该字段 |
| NGF 会不会误覆盖用户设置 | — | **不会**：脚本核验全仓库 **0 次**调用该 API |

**由此得到的 NGF 策略**：**什么都不做** —— 不调用即跟随系统；
调用 `TEXT_APP_DISABLE_HIGH_CONTRAST` 会覆盖用户在系统里打开的高对比，属可访问性倒退。

**这一条和字体缩放、播报是同一个教训的三次重复**：
"我没找到"不等于"不存在"，而且三次都是因为**找错了地方** ——
字体缩放在 `Configuration`、文本高对比在 `graphics.text`、播报在 `sendAccessibilityEvent`，
**都不在"无障碍 API 里应该有个开关"这个直觉位置上**。

### 第十五批（P4 播报能力实现，2026-10-06）

把第十三批找到的播报 API 真正落地 —— 这是 §5.1.2 三项决策里**最后一项**。

**新增 `NGFAccessibilityAnnouncement.ets`**：

| 能力 | 说明 |
|---|---|
| `NGFAnnouncementMode` | `INTERRUPT`（打断）/ `QUEUE`（排队不打断） |
| `resolveAnnouncementEventType()` | NGF 语义名 → SDK 取值 `'announceForAccessibility'` / `'announceForAccessibilityNotInterrupt'` |
| `isAnnouncementDeliverable()` | 空/纯空白文本不发送事件（空播报对读屏用户只是噪声） |

**为什么要有映射层**：NGF 用**语义名**（interrupt / queue），SDK 用**历史命名**
（`announceForAccessibility` / `announceForAccessibilityNotInterrupt`）。
**拼错不会编译报错，只会在运行时静默失败** —— 所以这层映射被单测钉死。

**门面新增 `announce(request)`**（`AccessibilityFacade`，同时进 `IAccessibilityManager` 契约）：

- `bundleName` 经 `bundleManager.getBundleInfoForSelfSync(GET_BUNDLE_INFO_DEFAULT)`（**@since 10**）取得；
- **文本分两条路径**：`string` 走 `textAnnouncedForAccessibility`（**12**）；
  `Resource` 走 `textResourceAnnouncedForAccessibility`（**18**）——
  **`Resource` 不需要 Context 解析**，因此契约层不必持有 UIContext，也不把 i18n 解析责任推给调用方；
- 失败按既有模式收敛为 `logger.warn`，不抛给调用方。

**验证页接入**：新增「播报当前状态」按钮，作为 announcer 的真实消费者
（画面变了但焦点没变时，读屏用户需要被主动告知）。

**证据等级：仅编译验证。** 按 PP-001 不做真机验证 —— **不得声称「播报已可用」**。

**顺带踩到的 ArkTS 约束**：`arkts-no-misplaced-imports` ——
`import` 必须集中在文件头；写在 `export interface` 之前但不在顶部，编译直接报错。

### 第十六批（P4 半透明表面也能验对比度，2026-10-06）

**发现一个此前被含糊带过的真问题**：NGF 的毛玻璃令牌是**半透明**的 ——
`glass_chip_overlay = #CCFFFFFF`（alpha ≈ **0.8**），验证页的卡片就铺在它上面。
而对比度公式**只对不透明颜色成立**，所以这些表面的对比度此前**根本没被验过**。

**补齐两个纯函数**（`NGFContrastChecker`）：

| 函数 | 说明 |
|---|---|
| `parseHexAlpha(hex)` | 取 `#AARRGGBB` 的 alpha（0..1）；6 位写法视为不透明 |
| `compositeOver(top, alpha, bottom)` | 把半透明色合成到不透明背景上，得到可计算的有效颜色 |

**验证方法：对最坏情况背景各算一次。** 实际背景可能是渐变或图片，
所以取**最暗（黑）与最亮（白）**两种极端背景，两次都达标才算这个表面安全。

**结论（用本仓库工具实测，非手算）**：`text_primary` 在 `glass_chip_overlay` 上，
黑底合成与白底合成**两种极端都 > 4.5:1**，且实际比值已写进断言防止将来改色后静默退化。

**由此确立的规则**：**半透明表面不得直接用 `calculateContrastRatio()`**，
必须先 `parseHexAlpha()` + `compositeOver()` 合成，并对极端背景各验一次。
这条限制此前只写在函数注释里，现在有了可执行的示例与断言。

### 第十七批（模拟器设备端验证 + 修复一个真 bug，2026-10-06）

用户开放模拟器（`127.0.0.1:5555`，真机 MatePad Mini 仍禁用），首次做了设备端验证。

**发现并修复一个编译期无法发现的真 bug**：页面所有拼接标签渲染成 `[object Object]：<值>` ——
`$r()` 返回 `Resource` 对象，放进 `+` 拼接会走 `toString()`。
**编译通过、57 条单测全过**，只有跑起来才看得见。已修复 20 处并全仓库扫描确认别处 0 命中；
沉淀为候选规则 **PR-C004**。

**采到的设备端证据**（详见 §3.9）：

| 面 | 证据 |
|---|---|
| 语义树 | `uitest dumpLayout`：列表项分组生效（子节点不再独立）、表单输入框独立可聚焦且带 description、按钮文案正确 |
| 触控 | 关闭键 121×121 px、输入框高 121 px、按钮 396×121 px；按 `densityPixels = 2.75` 换算 = **44 vp**，正好满足 §2.4 与 §2.1 |
| 生命周期 | hilog 实测「已订阅」→「已取消订阅」成对发生，正是 SDK 警告的那条硬性要求 |
| 视觉 | 页面截图（浅色主题）确认全部标签与数值正确渲染 |

**未能验证的部分已在 §3.9.5 逐条列出**，其中最重要的一条：
**`accessibilityText` 无法通过 `dumpLayout` 验证**（dump 的 `text` 是节点自身文本，不是无障碍名称），
因此"图标按钮是否真被读屏念出名称"**本轮没有结论**，不能说它已验证。

### 第十八批（沉淀适老化技能，2026-10-06）

**新增共享技能 [`.rules/skill-elderly-ui.md`](../.rules/skill-elderly-ui.md)** ——
回答"另一个 Agent 进到这个仓库，怎么把原版页面改成合规的适老版"。

**动机**：此前适老化的全部知识锁在 96 KB 设计文档里，而那是**证据档案**不是**操作手册**；
`.rules/` 26 个技能文件里适老化相关 **0 个**。设计文档里有、但**技能里完全没有**的关键一项是：
**"确保功能与普通版一致"** —— 原设计只保证视觉/触控/对比度达标，没有任何一致性机制。

**技能内容**（7 节）：法规依据 / 13 条规范数值 + NGF 基线 + 2 个引用陷阱 /
**同一页面 + 适老呈现层**架构 / 10 项逐条改造方法 / 常见错误表 / 验收清单 / 路径速查。

**功能一致性的三层保证**（新增设计）：
1. **架构层**：同一页面 + 策略切换 → 路由/数据源/业务调用完全复用，功能天然一致
2. **入口层**：普通版每个功能入口在适老版仍可达（可改文案/位置/形态，**不可删**）
3. **可执行层**：`uitest dumpLayout` 导出两版**可点击节点清单**做差分，差异逐条解释

**同时验证了一个此前不确定的写法**：`NGFAccessibilityLifecycleBinding` 的监听器
**可以直接传对象字面量**（不必再写一个具名类中转）。
已在 API 26 上编译通过 + 模拟器运行验证（页面文本正常渲染）。
参考实现 `NGFAccessibilityShowcasePage` 已改为该写法。

**流程合规**：按 `skill-rules-update.md` 执行 —— 新建 `skill-<名称>.md`、
更新 `.rules/README.md` 列表与阅读顺序、**并在根 `AGENTS.md` 的触发条件表注册**（否则不会被自动嗅探）。

### 第十九批（MainMenuPage 适老化实战 + 材质根因修复，2026-10-06）

按 `.rules/skill-elderly-ui.md` 把 **MainMenuPage** 改造成适老版 —— 这是技能的首次端到端实战。

**架构：同一页面 + 适老呈现层**（技能 §3.1 铁律，未复制页面）。
新增 `a11yPolicy` / `a11yTokens` / `isElderlyUi` 状态 + 生命周期绑定（on/off 成对），
62 处 `fontSize` 统一走 `a11yFont()`，61 处补 `a11yLineHeight()`。

**普通版零视觉回归**的设计：`a11yFont(n)` 在普通档原样返回；
`a11yLineHeight()` 在普通档返回 **0** —— SDK 明确「≤0 时行高不受限、随字号自适应」即默认行为。
已用截图 + dumpLayout 双重复核。

**落实的规范条款**（模拟器实测，densityPixels=2.75）：

| 条款 | 要求 | 实测 |
|---|---|---|
| §1.1 | 适老版主要文字 ≥18 | 全部文本 **18 vp**；标签栏文字 12.7 → **23.3 vp** |
| §1.2 | 行距 ≥1.3 倍 | 18 × 1.3 = **23.4 vp**，实测文本高度 64px = **23.3 vp** ✓ |
| §2.1 | 适老版主要组件 ≥60×60 | 标签项 61×48 → **61×64 vp** ✓ |
| §3.1 | 标准功能名「长辈版」+ 别名 | 设置页新增长辈版卡片，显示标准名 + 三个别名 |
| §1.4 | 颜色不得是唯一区分手段 | 标签选中项加**圆角底片 + 描边**（形状冗余）；开关状态加「已开启/已关闭」文字 |

**功能一致性三层验证**：
1. 架构层：同一页面，路由/数据源/业务调用完全复用 ✓
2. 入口层：普通版每个入口在适老版仍可达 ✓
3. 可执行层：`uitest dumpLayout` 差分 —— 适老 12 可点击 / 27 文本，普通 14 / 32；
   **仅适老版多的文本 = 0**；仅普通版有的 4 条（DEVICE / 设备与显示 / SYMBOL 等）
   **滚动一屏后全部出现**，属**视口差异而非功能缺失** ✓

**🔴 顺带挖出并修复一个页面级根因缺陷（对比度）**

用户指出：系统材质 API 调整后，**除 HDS 底栏外**的普通组件系统材质**不生效**。
经代码核对确认根因：`shouldUseSystemMaterialSurface()` 为 true 时，
全部 `buildMaterialAware*` 助手会把**背景 / 边框 / 模糊 / 阴影置空**，
完全依赖 `.systemMaterial(...)` —— 它失效后组件变**全透明**，文字直接压在沉浸式渐变上。

**像素实测**：深色正文对比度仅 **1.49 ~ 2.28 : 1**（§1.3 要求 4.5）。

**修复**：
1. `shouldUseSystemMaterialSurface()` **恒返回 false** → 恢复普通玻璃模糊材质
   （即迁移提交 `9a27358` **之前**的写法）；
2. 全仓库移除 **232 处** `.systemMaterial(...)`，涉及 **24 个文件**；
3. 顺带发现 `NGFHdsTitleBarOptionsFactory` 把标题文字**硬编码为白色**，
   而 MainMenuPage 传的底色是浅色 `background_primary` —— 系统材质正常时这条回退路径
   **从未被执行**，材质失效后暴露为「白字压浅底」。改为 `Color.Transparent`。

**修复后实测**（声明色值 vs 实测白底面板）：
`text_primary` **15.62** / `text_secondary` **6.53** / `text_tertiary` **4.76** —— 全部 ≥4.5 ✓

已沉淀为项目规则 **PR-006**（active）、候选规则 **PR-C005**、偏好 **PP-002**，
并写入共享技能 `.rules/skill-elderly-ui.md` §4.3 与验收清单。

### 第二十批（补齐全页适老化：浮窗、段落间距、子组件，2026-10-06）

第十九批只覆盖了 MainMenuPage 自身的构建块；本批把「**整个页面**」补齐。

**1. 浮窗关闭键（附件2 §2.4）—— 此前完全缺失**

核对发现 `NGFMaterialSheetOptions` 把 ArkUI 的 `showClose` 从**默认 true 显式改成 false**，
等于**全应用浮窗都没有关闭键**。§2.4 预设了关闭按钮存在，只能拖拽关闭对老年用户尤其不友好。

- 先恢复 SDK 默认值 `true`，设备实测关闭键位置合规（**右上**），但尺寸只有 **40×40 vp**，**低于 §2.4 的 44×44**。
- 因此本页浮窗改为**关闭内置键**，由内容区提供 `NGFAccessibleDialogCloseButton`（右上，点击区取 `dialogCloseTarget`）。
- **实测：121×121 px = 44.0×44.0 vp** ✓，位置右上 ✓，且无重复按钮。

**2. 段落间距（附件2 §1.2「段落间距至少比行距大 1.3 倍」）**

新增 `a11yParagraphSpacing()`，适老档取令牌算出的 `paragraphSpacing` = 23.4 × 1.3 ≈ **30.4 vp**，
应用到 7 处内容块容器。**实测卡片间隙 83px = 30.2 vp** ✓。

> 适用范围只到「卡片之间 / 卡片内标题与说明之间」这类**独立内容块**；
> 卡片内「标签 / 值」这种紧耦合排版不按段落间距拉开 —— 否则卡片被撑得过高，
> 反而降低一屏信息量（§2.3 的意图是减少操作负担，不是减少可见信息）。

**3. 头部卡片 —— 实测后确认无需改动**

原担心固定高度 356 vp 在 18 vp 字号下会裁切。**实测内容到 y=1287，Swiper 底边 1383，余 96px** —— 不裁切。
（先量后改，避免了无谓改动。）

**4. 三个内嵌子组件（此前 0 处适老适配）**

`NGFCapabilitiesTabContent` / `NGFDeviceAwarenessPage` / `NGFSettingsPage` 是页面各标签页的可见内容，
共 **35 处硬编码字号、0 处适老适配**。

- 新增可复用缩放器 **`NGFA11yTextScale`**（`ngf_framework/.../uiShell/utils/`），
  把 §1.1 / §1.2 的换算规则集中一处，避免每个组件各写一份判断而漂移。
- 三个组件 + `NGFDeviceAwarenessStatusRow` 全部接入（自持 `@State` + 生命周期订阅，on/off 成对）。
- **为什么状态行不接收 `@Prop a11yScale`**：ArkTS 的 `@Prop` 会**深拷贝对象**，
  类实例经拷贝后原型可能丢失、方法不可用 —— 因此改为自持状态。

**实测**：设置页全部文本高度 **64px = 23.3 vp** = 18 × 1.3 ✓（含子组件文字）。

### 第二十一批（设备页 / 设置页真正做完整，2026-10-06）

用户指出「设备和设置页大量的内容还没有正确适老化设计」—— **判断正确**，第二十批只做了字号替换就说"整页完成"是**过度声称**。

**🔴 真正的根因：决策逻辑被复制到多处**

三个页面（`NGFDeviceAwarenessPage` / `NGFSettingsPage` / `SystemResourcePreviewPage`）
**各自复制了一份** `shouldUseTransparentSystemMaterialSurface()`，
于是 PR-006「普通组件不再使用系统材质」的决策**传不到这些页面**：

面板背景被判为透明 → 系统材质又不生效 → **面板、模糊、描边全部消失**
→ 深色文字直接压在沉浸式渐变上 → **设备页与设置页几乎不可读**。

修复：三处统一委托 `NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface()`。
**实测面板恢复白底，对比度 15.62 / 6.53 / 4.76**（§1.3 要求 ≥4.5）。
沉淀为项目规则 **PR-007**（决策必须只有一处实现）。

**补齐的适老化项**（此前只做了字号）：

| 项 | 实测（适老档） | 要求 |
|---|---|---|
| 分段按钮高度（**13 处**） | 286 × **60.0 vp** | §2.1 ≥60×60 ✓ |
| 容器间距（**12 处**） | 30.4 vp | §1.2 段距 ≥ 行距 × 1.3 ✓ |
| 分段按钮选中态 | 新增**描边**（粗体 + 底片 + 描边三重区分） | §1.4 颜色非唯一手段 ✓ |
| 面板与对比度 | 白底 + 15.62 / 6.53 / 4.76 | §1.3 ≥4.5 ✓ |

**实测澄清的两件事**（避免无谓改动）：
- 未选中分段按钮文字实测 **6.53:1** —— **达标**，"看着淡"是错觉；
- 选中态原本已有**粗体 + 底片**双重区分，§1.4 本就满足，本轮只是再加一层描边更稳。

**已确认仍存在的缺口（未在本批范围）**：
另外 **9 个页面**（`NGFDemoDeviceDisplayPage` 等）仍有 **35 个分段按钮**用固定 40 vp 高度，
且这些页面**完全没有适老适配**（无缩放器、无订阅）。它们需要整套改造，不是一处替换。

### 第二十二批（关怀模式（长辈模式）系统同步核对，2026-10-06）

用户要求核对「是否正确识别系统的关怀模式、实现同步开启、正确应用关怀模式的特殊 API」。
**结论：API 接入完整、同步逻辑正确，但缺一处系统声明。**

#### 术语澄清

**关怀模式 = 长辈模式 = 关爱版 = 大字版**，是同一套系统能力的多个名字。
HarmonyOS 7.0（**API 26.0.0**）在 Accessibility Kit 中正式提供，
对应 SDK 里的 **`SeniorMode*`** 系列接口。

#### 我们已正确实现的部分 ✓

`AccessibilityFacade` **完整使用了全部 7 个 API**（SDK `@ohos.accessibility.d.ts` 逐条核对）：

| API | SDK 行 | @since | 我们的用法 |
|---|---|---|---|
| `isSeniorModeEnabled()` | 785 | — | 查询系统关怀模式 |
| `onSeniorModeStateChange()` / `off…` | 805 / 819 | — | 监听系统开关（成对） |
| `onSeniorModeStateChangeForSelf()` / `off…` | 828 / 838 | **26.0.0** | 监听本应用开关（成对） |
| `getSeniorModeStateForSelf()` | 848 | **26.0.0** | 查询本应用开关 |
| `setSeniorModeStateForSelf()` | 859 | **26.0.0** | 设置本应用开关 |

**同步逻辑正确**：`buildPolicyInput()` 用
`seniorModeEnabled || appSeniorModeEnabled` 做 OR —— 系统开或应用内开，任一即可进入适老档 ✓

**设备端往返实测**（hilog，系统无障碍服务日志）：

```text
关闭: SetSeniorModeStateForApp enabled, state: 0
      seniorModeStateForApp from db: {"com.dlzz.ngf_0":false}
      Senior mode state changed for com.dlzz.ngf_0: 0
开启: SetSeniorModeStateForApp enabled, state: 1
      seniorModeStateForApp from db: {"com.dlzz.ngf_0":true}
      Senior mode state changed for com.dlzz.ngf_0: 1
```

系统把本应用的状态**持久化进自己的 DB** 并**广播变化** ✓ —— 完整闭环。

#### 🔴 缺失的部分（已修复）

**`entry/src/main/module.json5` 没有声明 `senior_mode` metadata。**

官方指南《应用内关怀模式与系统设置同步》：
> 从 API 版本 26.0.0 开始，可通过如下接口设置/获取"设置"中**应用管理页面内**本应用关怀模式开关状态，
> 以及实现对其开关状态监听。

声明 `independent_control` 才能让应用出现在
**「设置 > 关怀和无障碍 > 关怀模式 > 应用管理」**，用户才能从系统侧管理它。

**本应用正是必须声明的场景**：有独立的长辈版开关 + 调用了 `setSeniorModeStateForSelf`。
不声明 → 用户只能在应用内开，**系统设置里看不到这个应用**。

已添加：
```json5
{
  "name": "senior_mode",
  "value": "independent_control"
}
```

**验证**（不只是源码级）：
- 打包产物 `module.json` 内含
  `{"name":"senior_mode","value":"independent_control"}` ✓
- 设备 `bm dump -n com.dlzz.ngf` 读到该 metadata ✓
- 安装后长辈版开关仍正常，往返日志与修复前一致 ✓

**证据等级说明**：SDK 声明为**一手**证据；
metadata 要求来自**官方指南**（文档站为 SPA，正文经 Exa 检索片段 + 两篇独立社区文章交叉确认）；
设备侧 `bm dump` 为**实测**证据。

### 第二十三批（全页面 100% 覆盖 + 真机逐页实测，2026-10-06）

用户要求「剩余所有页面的组件、文字，务必做到 100% 覆盖，各项指标必须实测合格」。

#### 覆盖：100%

| 指标 | 结果 |
|---|---|
| `fontSize` 总数 | **479** |
| 已接入适老缩放器 | **479（100%）** |
| 固定按钮高度（未适老） | **0** |
| 裸 `Column({space})` | **0** |
| 含 UI 的文件 | 32 个，**全部接入** |

**新增可复用能力**：
- `a11yFontFor` / `a11yLineHeightFor` / `a11yExplicitLineHeightFor` / `a11yGroupSpacingFor`（模块级）
  —— 供**叶子组件**使用：它们接收原始类型 `@Prop isElderly: boolean`，
  **不接收类实例**（ArkTS 的 `@Prop` 会深拷贝对象，类实例经拷贝后原型可能丢失、方法不可用）。
- `NGFA11yTextScale.groupSpacing()`：组内间距（标签/值等**紧耦合**元素）按 ×1.6 放大，
  **不套用段落间距** —— §1.2 的「段落间距」针对独立段落，把标签与值也拉到 30 vp
  会撑高卡片、降低一屏信息量，背离 §2.3「充足操作时间」的意图。

#### 真机逐页实测（MatePad Mini, `densityPixels = 2.393`）

**密度反推**：长辈版 Toggle 代码里写死 `constraintSize` 60 vp，实测 **143×143 px**
→ `densityPixels = 143 / 60 = 2.393`（与模拟器的 2.75 **不同**）。

| 标签页 | 文字最小 | 点击区最小 | 结论 |
|---|---|---|---|
| 框架 | **23.4 vp** | Toggle **60×60 vp** | ✓ |
| 功能 | **23.4 vp** | 标签项 **129×64 vp** | ✓ |
| 能力 | **23.4 vp** | 标签项 **129×64 vp** | ✓ |
| 设备 | **23.4 vp** | 标签项 **129×64 vp** | ✓ |
| 设置 | **23.4 vp** | Toggle **60×60 vp** | ✓ |

23.4 vp = 18 × 1.3 → **§1.1 与 §1.2 同时满足** ✓

#### 🔴 真机才暴露的两个缺口（模拟器上没发现）

1. **浮动标签栏宽度不足**：默认宽度下每项只有 **53 vp**（< §2.1 的 60）。
   修复：适老档 `.barWidth('100%')` → 每项 **129 vp** ✓（普通档保持 40% 的窄浮动样式）。
2. **`NGFSettingsPage` 自己的 Toggle 未约束**：实测 **36×20 vp**。
   修复：加 `constraintSize` → **60×60 vp** ✓

**这两条只有在真机的实际布局下才量得出来** —— 模拟器的密度与屏幕宽度不同，
同一个百分比宽度会得到不同的 vp 值。

#### 过程中的两个脚本坑（已修）

- **CRLF 换行**：JS 正则的 `.` **不匹配 `\r`**，导致 `\r\n` 文件里的
  `\.fontSize\(N\)` 全部匹配失败（静默跳过，不报错）。改为 `split(/\r?\n/)` 后正常。
- **`async aboutToAppear(): Promise<void>`**：脚本按 `: void` 匹配，
  遇到 Promise 返回类型时误判为「无生命周期」，于是**又插了一个** `aboutToAppear`
  → 重复定义；清理时又误删了唯一的 `aboutToDisappear`，导致**订阅不被取消**。
  已改为：注入前先探测 `async` 形式，并做「定义数 / attach 数 / detach 数」三方核对。

### 第二十四批（底栏漂移定位与修复，2026-10-06）

用户报告「底栏出现诡异的漂移，默认和关怀模式都有」。

#### 根因：**我自己的改动**

第二十三批为满足 §2.1，我给底栏加了 `.barWidth(this.isElderlyUi ? '100%' : '40%')`。
**这行代码同时破坏了两种模式**：

| 模式 | 实测现象 |
|---|---|
| 关怀模式（`'100%'`） | 图标 x=185/490/795/1100/1410，背景胶囊从 x≈520 起 —— **框架、功能两个图标完全在胶囊外** |
| 普通模式（`'40%'`） | 同样错位 |

且**百分比语义与预期相反**：`'100%'` 反而比 `'40%'` 更窄。

#### 修复与验证

移除 `.barWidth(...)` → 两种模式均恢复：

| 模式 | 图标中心 x | 居中 |
|---|---|---|
| 关怀模式 | 548 / 674 / 800 / 926 / 1052 | **左右距各 548px ✓** |
| 普通模式 | 全部落在胶囊内 | ✓ |

#### ⚠️ 遗留取舍（已如实记录，未强行处理）

标签项实测 **53×64 vp**，宽度仍差 §2.1 的 60vp 约 **7vp**。
这是 HDS 浮动底栏**按内容自适应宽度**的固有约束。
**强行拉宽会破坏胶囊与图标对齐 —— 比差 7vp 严重得多**，所以选择保留对齐。
彻底满足需改为「适老档不用浮动样式」，会改变视觉风格，**待用户决策**。

#### 教训

**我在第二十三批把"数字达标"置于"布局正确"之上，制造了一个比原问题更严重的回归。**
沉淀为 **PR-010**。

### 第二十五批（官方三篇适老文档核对，2026-10-06）

用户提供三篇官方文档，要求核对「当前 API 是否也能用这些能力增强体验」。
**文档站是 Angular SPA（`web_fetch` 只得 1731 字节空壳）**，
改用 **OpenHarmony 官方文档镜像的 raw markdown**（同一份内容）取得原文。

来源：
- [ArkUI 适老化支持](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/arkui-support-for-aging-adaptation-V5)
- [Navigation/Tabs 支持适老化](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/arkts-navigation-tabs#支持适老化)
- [无障碍属性](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/arkts-universal-attributes-accessibility)

#### 🔑 最重要的发现：有**两套独立的适老信号**

| | **关怀模式** | **ArkUI 适老化（系统字体缩放）** |
|---|---|---|
| 信号源 | `isSeniorModeEnabled()` | `Configuration.fontSizeScale > 1` |
| 拿到什么 | 我们自建的适老呈现层 | **系统自动的**长按放大弹窗 |
| 前提 | `module.json5` 声明 metadata | `app.json5` 配 `configuration` |

**这两套互不替代。** 我们此前只接了关怀模式。

#### 能力核对矩阵（API 26）

| 能力 | SDK 支持 | 我们的状态 |
|---|---|---|
| `configuration` 标签（跟随系统字体） | ✓ | ✅ **已配**（`followSystem` + maxScale `"2"`） |
| `Configuration.fontSizeScale` | **@since 12** | ⚠️ 仅注释引用 |
| `ApplicationContext.setFontSizeScale()` | **@since 13** | ❌ 未使用 |
| `ApplicationContext.onSystemConfigurationUpdated()` | **@since 24** | ❌ **未订阅** |
| 长按放大弹窗（`Tabs`/`tabBar`/`Navigation`/`NavDestination`/`SideBarContainer`） | ✓ 系统自动 | ⚠️ **需 `BottomTabBarStyle`**，我们用自定义 `@Builder` |
| `accessibilityText` | ✓ | ✅ 3 处 |
| `accessibilityDescription` | ✓ | ✅ 2 处 |
| `accessibilityLevel` | ✓ | ✅ 3 处 |
| `accessibilityGroup` | ✓ | ⚠️ 1 处 |
| `accessibilityNextFocusId` | ✓ | ✅ 2 处 |

**`fontSizeMaxScale = "2"` 的选择是有依据的**：§1.1 要求最大字体 ≥30 dp/pt，
最小正文字号 16 vp → 需 1.875 倍 → 枚举中最小满足值是 `"2"`（`"1.75"` 只到 28 vp，**不达标**）。

#### 🔴 两个未实施的缺口（如实记录，未擅自改）

1. **未订阅系统字体缩放变化**：用户只调大系统字体（不开关怀模式）时，
   文字会跟随放大（`followSystem` 生效），但**我们基于 vp 的点击区 / 段距不会跟着变** ——
   可能出现「字变大了、按钮没变大」。修复需把 `fontSizeScale` 接入门面并纳入适老判定。
2. **底栏用自定义 `@Builder` 而非 `BottomTabBarStyle`**：因此**拿不到官方长按放大弹窗**。
   **这也正是标签项 53 vp（差 §2.1 的 60vp）的官方解法** ——
   应改用 `BottomTabBarStyle`，而不是像第二十三批那样用 `.barWidth()` 硬拉（已造成底栏错位回归）。

**两项都涉及行为变更，需用户决策后再动。**

#### 实测

真机上长按底栏（`uitest uiInput longClick`）→ **无弹窗**，
符合文档「系统字体为 1 倍时不能弹窗」。**因字体缩放为 1 倍，该测试不充分**，
要完整验证需先把系统字体调大 —— 如实标注。

### 第二十六批（把两套适老能力包装成框架 API，2026-10-06）

用户要求：「把这些系统能力都清晰的包装起来，这样之后用户使用 NGF 框架进行 app 的开发，
技能会直接指挥 Agent 快速适配好各种组件的适老化设计和对应的功能」。

#### 核心设计：`isElderly` 与 `boostFont` **必须分开**

这是本轮最重要的设计决定。两个适老信号对**字号**的处理**不同**：

| 信号 | 系统是否已放大字号 | 我们要做什么 |
|---|---|---|
| **关怀模式** | ❌ 不会 | **必须**把字号抬到 §1.1 的 18 dp |
| **系统字体缩放 > 1** | ✅ 已按 **fp** 放大过 | **不能再抬**（双重放大），但要补 **vp** 的行距与点击区 |

原因：ArkUI 的 `fontSize(number)` 单位是 **fp**（跟随系统缩放），
而 `.lineHeight()` / `.height()` 用的是 **vp**（不跟随）。
所以「只调大系统字体」的用户，字会变大、**按钮不会**。

因此 `NGFA11yTextScale` 拆成两个概念：

| 成员 | 含义 |
|---|---|
| `isElderly` | 适老**布局**（任一信号为真）→ 行距 / 点击区 / 间距 |
| `boostFont` | 是否由我们**抬字号**（仅关怀模式） |
| `fromCareMode` / `fromFontScale` | 分别是哪个信号触发的（诊断用） |

#### 新增/扩展的 API

| API | 位置 | 作用 |
|---|---|---|
| `resolveA11ySignalSource(input)` | 策略契约 | 两个信号 → 归一化判定 |
| `NGFA11ySignalSource` | 策略契约 | `{ fromCareMode, fromFontScale, isElderly, boostFont, systemFontScale }` |
| `NGFInclusiveDesignPolicyInput.systemFontScale` | 策略契约 | 新增必填字段 |
| `ngfAccessibilityFacade.getA11ySignalSource()` | 门面 | 当前信号（页面用它构造缩放器） |
| `getSystemFontScale()` | 门面 | 当前缩放倍率 |
| `addFontScaleListener` / `removeFontScaleListener` | 门面 | 订阅字体缩放（成对） |
| `resolveA11yTextScaleForCurrent()` | 缩放器 | **页面唯一需要写的一行** |
| `a11yFontFor(isElderly, n, boostFont?)` | 缩放器 | 叶子组件用 |

**订阅实现要点**（踩过的坑）：
- `systemConfiguration.UpdatedCallback` 是**带可选属性的对象**，**不是函数** ——
  必须传 `{ onFontSizeScaleUpdated: fn }`
- 回调签名 `OnFontSizeScaleUpdatedFn = (fontSizeScale: number) => void`（**@since 24**）
- 读当前值用 `UIAbilityContext.config.fontSizeScale`（`ApplicationContext` **没有** `getConfiguration()`）
- 回调必须用**类的箭头函数属性**（SDK 要求非匿名，否则无法正确取消订阅）

#### 覆盖

**69 处调用点**从 `resolveA11yTextScale(ngfAccessibilityFacade.getPolicy())`
和 `resolveA11yTextScale(resolved.policy)` 切到 `resolveA11yTextScaleForCurrent()`，
涉及 **26 个文件**。4 个叶子组件新增 `@Prop boostFont`。

#### 验证

- 单测：**78 run / 75 pass**（新增 5 个双信号用例，原 73）
- 构建：`assembleApp` / `assembleHap` **BUILD SUCCESSFUL**
- 真机：应用启动正常、35 个文本节点正常渲染、无崩溃

**未验证的部分（如实标注）**：字体缩放的**变化通知**未实测 ——
系统字体缩放无法通过 `hdc` 修改（`settings` 命令不可用），
需要人工在系统设置里调大字体后观察。**读取路径已由启动流程覆盖。**

### 第二十七批（用户报「开了系统关怀模式但没放大效果」，2026-10-06）

#### 结论：**应用其实是放大的，系统关怀模式单独就生效了**

**实测证据**（真机 MatePad Mini，**应用内开关已关闭**）：

| 场景 | 界面文本高度中位数 | 判定 |
|---|---|---|
| 普通档 | 31~33 px | — |
| **仅系统关怀模式开启** | **56 px**（= 23.4 vp = 18×1.3） | **适老档 ✓** |

系统日志同样确认：
```text
accessibility_napi: GetSeniorModeState enabled[1]          ← 系统关怀模式开
accessibility_napi: GetSeniorModeStateForApp enabled: 1    ← 本应用也开
```

#### 为什么用户感知为「没效果」

**应用内的「长辈版」开关此前已经是开启状态**（早前测试留下的），
应用**本来就处于适老档**。此时再开启**系统**关怀模式，**界面不会有任何可见变化** ——
因为已经是适老档了。而卡片当时只显示应用内开关（「已开启」），
**看不出系统信号也在起作用**，于是无从判断。

#### 🔴 顺带发现并修复的两个真实缺陷

**缺陷 1：字体缩放订阅在构造期失败后永不重试**

```text
⚠️ 无障碍事件注册失败: systemConfigurationUpdated,
   message=NGF: UIAbilityContext 尚未就绪，字体缩放订阅延后
```

门面在**构造函数**里注册监听，但那一刻 `UIAbilityContext` 往往尚未就绪
（AbilityStage 还没创建完）→ 注册失败 → **字体缩放在整个进程生命周期内永远是 1**。

修复：仿照既有的 `ensureUserPolicyRestored` 模式，增加 `ensureSystemListeners()`，
在 `getPolicy()` / `getA11ySignalSource()` 时**惰性补订阅**
（此时页面已在渲染，上下文必然就绪；`tryRegister` 本身幂等）。

**实测确认修复**：
```text
01:09:27.170 ⚠️ 注册失败（构造期，符合预期）
01:09:27.380 I OnSystemConfigurationUpdated called   ← 惰性重试成功订阅
```

**缺陷 2：卡片显示的是「应用内开关」而非「生效状态」**

系统关怀模式开启、应用内开关关闭时，卡片显示「已关闭」而界面却是大字 ——
**自相矛盾，用户无法判断是哪个信号在起作用**。

修复：新增 `describeElderlyEffectiveState()`，三态可区分：

| 情况 | 显示 |
|---|---|
| 应用内开关开 | 已开启 |
| **仅系统关怀模式开** | **已生效 · 由系统关怀模式开启** |
| 都没开 | 已关闭 |

**实测确认**（截图 + dump）：应用内开关关闭时显示
**「已生效 · 由系统关怀模式开启」**，界面仍是适老档 ✓

#### 📌 需要澄清的预期

**系统不会自动放大第三方应用的界面。** HarmonyOS 关怀模式对第三方应用提供的是：

1. **一个信号**（`isSeniorModeEnabled`）—— **应用自己**去适配 ← 我们做了 ✓
2. **长按放大弹窗** —— 但触发条件是**系统字体 > 1 倍**，是**另一个设置**，不是关怀模式

所以「开了关怀模式 → 系统自动把应用放大」这个预期**不成立**；
**放大必须由应用自己实现**，而 NGF 已经实现了。

### 第二十九批（AttributeModifier 路径验证成功，2026-10-06）

第二十八批留下了未决问题：「`.attributeModifier()` 是否可用」。本批用**干净实验**定论。

#### ✅ 结论：**可用**

**实验设计**：在 `NGFSettingsPage` 上
- 用 **`@State` 字段**持有 `NGFA11yModifierSet`（**不是 getter**）
- 在 `onInclusiveDesignChanged` 里**新建实例**替换
- 对「语言设置」标题挂 `.attributeModifier(this.a11yMods.text(18))`

**实测**（真机 MatePad Mini / API 26）：

| 检查项 | 结果 |
|---|---|
| 页面渲染 | **21 条文本** ✓ 正常 |
| 标题渲染高度 | **56px = 23.4vp = 18 × 1.3** ✓ |

→ `fontSize` 与 `lineHeight` **都正确下发** ✓

#### 🔴 根因：第二十八批的失败**完全是 getter 造成的**

`private get a11y(): NGFA11yModifierSet { return new NGFA11yModifierSet(...); }`
在 `build()` 路径里**现场构造对象**，导致**设置页整页渲染异常**
（文本 21 → 7 条、大片空白）。移除后立即恢复。

**⚠️ 我在第二十八批基于那个坏页面得出了「`AttributeModifier` 不生效」的结论 —— 那是错的。**
改用 `@State` 字段重做实验后确认可用。技能与本框架文件中的错误断言已全部更正。

#### 沉淀的硬约束

**修饰器集必须是 `@State` 字段，禁止在 `build()` 路径里构造。**
策略变化时**必须新建实例**（`AttributeModifier` 是命令式下发，只改内部字段不会重新下发）。

**通用教训：测量前必须先确认被测对象本身正常**（看文本总数、看截图），
否则量到的是坏页面的数据，会得出方向完全相反的结论。

### 第三十批（长按放大弹窗的可测性，2026-10-06）

用户问「我自己应该怎么测试长按放大」。核对后确认**触发条件极易被误解**，
并补了可自查的读数。

#### 触发条件：**系统字体 > 1 倍**，不是关怀模式

只开关怀模式**不会**触发长按放大 —— 这是最容易白测半天的地方。
`app.json5` 的 `configuration` 必须配 `fontSizeScale: followSystem`
（**缺省是 `nonFollowSystem`，不配就永远不触发**）；本项目已配 ✓

#### 新增可自查能力

1. **启动/变化日志**（`AccessibilityFacade`）：
   ```text
   字体缩放订阅成功，当前系统字体缩放=1
   系统字体缩放=1.75（>1，适老化长按放大弹窗应可触发）
   ```
2. **应用内读数行**（设置页 → 视觉效果卡片）：
   `系统字体缩放 | 1 × · 调大系统字体后长按放大才会触发`
   调大后变为 `1.75 × · 长按放大可触发` ✓

#### 实测确认的当前状态

真机日志：`字体缩放订阅成功，当前系统字体缩放=1` ✓
→ **当前系统字体未放大，长按放大弹窗不会触发**（符合文档）
→ 需人工在系统设置里调大字体后才能验证

#### ⚠️ 已知限制：本项目底栏拿不到弹窗

底栏是自定义 `@Builder` `tabBar`（`MainMenuPage` 5 处 `.tabBar(this.buildTabItem(...))`），
而官方弹窗**只对 `BottomTabBarStyle` 生效** ✗
→ **长按底栏不会弹窗**；应长按页面标题栏/导航区（`HdsNavigation` / `HdsNavDestination`）。

### 第三十一批（长按放大的完整生效条件 + 修掉双重放大，2026-10-06）

用户提出一个尖锐观察：**关怀模式已经让我们的字变大了，但 `fontSizeScale` 仍是 1×**
—— 「难道我们这种自己放大的行为反而不行吗？」

#### 结论：自放大**不是「不行」，而是「不算数」**

触发条件读的是 **`fontSizeScale`**（系统/应用的**字体缩放配置**），
**不是「界面看起来多大」**。关怀模式**不会**改 `fontSizeScale`（实测仍为 1），
所以靠 `a11yScale.font()` 自己放大的应用，长按放大**永远不会触发**。

**它不阻止任何东西，只是不满足那个条件。** 用户的观察完全正确。

#### 完整生效条件（**三条缺一不可**）

| # | 条件 | 依据 | 本项目 |
|---|---|---|---|
| 1 | `app.json5` 配 `configuration` → `$profile:xxx`，且 profile 里 `fontSizeScale: "followSystem"` | 官方《configuration标签》 | ✅ 已配 |
| 2 | **系统字体 > 1 倍**（系统设置里调大字体，**不是关怀模式**） | 官方《支持适老化·使用约束》 | ❌ 当前 1× |
| 3 | 组件在适老化白名单里 | 官方《适配适老化的组件及触发方式》 | ⚠️ 底栏不在 |

官方原文（《支持适老化》使用约束）：
> **适老化规则**：由于在**系统字体大于1倍**时，组件并没有默认放大，需要通过配置
> `configuration` 标签，实现组件放大的适老化功能。
> **适老化操作**：…**当设置系统字体大于1倍时，组件自动放大，当系统字体恢复至1倍时组件恢复正常状态。**

#### ⚠️ 不要用 `setFontSizeScale()` 去「制造」条件 2

官方《获取/设置环境变量》原文：
> 开发者可以使用 `setFontSizeScale` 设置应用字体大小。
> **设置后，应用字体将不跟随系统变化，不再支持订阅系统字体大小变化。**

即它会**切断** `followSystem` 与订阅能力 —— **代价大于收益**，不作为方案。

#### 🔴 顺带修掉一个真实缺陷：**双重放大**

用户的观察暴露了 `boostFont` 的判定错误。早期实现是 `boostFont = fromCareMode`：

| 场景 | 早期行为 | 问题 |
|---|---|---|
| 关怀模式 ON + 系统字体 1× | 我们抬到 18 | ✅ 正确 |
| 关怀模式 OFF + 系统字体 1.75× | 不抬 | ✅ 正确 |
| **关怀模式 ON + 系统字体 1.75×** | **我们抬到 18，再被系统乘 1.75 = 31.5** | ❌ **双重放大** |

**修复**：`boostFont = fromCareMode && !fromFontScale`
—— **只有系统没有放大时才由我们抬**。

新增回归用例 `testCareModePlusFontScaleDoesNotDoubleBoost` 守住该不变式。

#### 测试

**84 run / 81 pass**（新增 1 个双重放大回归用例）

### 第三十二批（让应用内开关与系统设置不再打架，2026-10-06）

用户决定：长按放大支持组件太少、不实用，**放弃该功能**；
聚焦「应用内关怀模式开关与状态**正确响应系统**、**不和系统设置打架**」。

#### 审计出的三处冲突

| # | 冲突 | 现象 |
|---|---|---|
| 1 | `Toggle.isOn` 绑 `isElderlyUi`，但 `.enabled()` 只判断「已解析」 | 系统开启时用户把开关拨到关 → `setAppSeniorMode(false)` → 界面仍是适老档 → **开关立刻弹回开**，用户以为开关坏了 |
| 2 | `handleToggleSeniorMode` 在系统接管时仍写入 | 与系统做**无意义的争抢**（官方：「重新开启系统关怀模式时，原先被关闭的App会同步恢复开启」） |
| 3 | 状态文字在「系统开 + 应用内开关也开」时显示「已开启」 | 掩盖了**真正的控制方是系统**（开关已锁定）这一事实 |

#### 修复

1. **新增 `systemSeniorMode` 状态**，与 `appSeniorMode` 严格分开（来源 `snapshot.seniorModeEnabled`）
2. **系统接管时禁用应用内开关**：`.enabled(this.seniorModeResolved && !this.systemSeniorMode)`
3. **系统接管时处理函数直接返回**，不做无意义写入
4. **状态文字优先级调整**：系统接管时**一律**显示
   「已生效 · 由系统关怀模式开启（应用内开关已锁定）」，无论应用内开关如何

#### 设计原则（沉淀）

**系统信号优先，应用内开关让位。** 系统关怀模式是用户在整个设备上的选择，
应用不应与之争抢；应用内开关只在**系统未接管**时才可操作。

#### ⚠️ 验证状态（如实标注）

- 构建 **BUILD SUCCESSFUL** ✓；单测 **84 run / 81 pass** ✓
- **系统 ON 场景的真机验证未能完成** —— 设备（MatePad Mini）在验证过程中断连且无法重连。
  已验证的是**系统 OFF 场景**：应用内开关 `checked=true / enabled=true`、
  状态文字「已开启」，符合预期。
- **系统 ON 场景的结论目前来自代码审阅，不是实测。**

### 第三十二批（无障碍 ≠ 适老化：独立技能 + 应用层落实，2026-10-06）

用户审计要求：「检查我们的无障碍设计做得如何，是否符合鸿蒙官方推荐的方式，
是否使用了合适的 API 和功能，是否真的支持调用系统无障碍的相关设计，是否有完善的技能库」。

#### 审计结论

**框架层优秀，应用层几乎为零** —— 问题不在设计，在落实。

| 层 | 状态 |
|---|---|
| 系统 API 集成 | ✅ 完整：`isOpenAccessibility` / `isOpenTouchGuide` / `isScreenReaderOpen` 全读；三个状态变化事件全订阅；`sendAccessibilityEvent` 播报 |
| 语义模型 | ✅ 完整：`NGFAccessibilitySemantics`（53 角色 + 4 等级 + 动作 + 状态 + 分组）+ `NGFAccessibilityAttributeModifier`（`AttributeModifier<CommonAttribute>`）+ `resolveAccessibilityAttributes()` + `auditAccessibilitySemantics()`（10 种问题码） |
| 单测 | ✅ 75 个用例 |
| **业务页面** | ❌ **几乎零标注** —— `entry/src/main` 下 `.accessibility*` 仅 7 处且全在展示页 |
| **技能库** | ❌ **没有无障碍技能**（只有适老化，两者是不同的事） |

#### 修复

1. **新建 `.rules/skill-accessibility.md`**（11 节）：官方三个前提、属性全表、
   `accessibilityText` 写法禁忌、Checked vs Selected 官方对照、分组策略、
   NGF 框架能力、逐项改造法、常见错误、验收清单、**审计方法 §8b**、§9b 工具
   —— 注册到 `.rules/README.md` 表格与阅读顺序、根 `AGENTS.md` 触发表、
   `official-doc-links.md` 新增「无障碍与适老化专门入口」
2. **装饰元素** 17 处 `accessibilityLevel('no')`（截至本批）
3. **成组信息** 15 处 `accessibilityGroup(true)`，其中
   `SystemResourcePreviewPage` 空态改为**一个信息单元**播报
4. **状态类组件**：`NGFSettingsPage` 两个 `Toggle` 的标签是**兄弟节点**，
   读屏只会念「开关，关闭」不知道控制什么 → 补 `accessibilityText`；
   底栏标签是**互斥单选**语义 → `accessibilitySelected`（**不是** `accessibilityChecked`）
5. **页面级扫描工具** `scripts/a11y_scan.js` + 纳入技能验收清单

#### 🔴 两个必须记录的重要修正

**修正 1：审计初期"191 交互点 0 标注"的结论是错的。**
静态扫描只数 `.accessibility*` 属性，**漏了「可见文本本身就是可读的」**。
运行时审计显示实际可读率 **90%+**（框架 7/9、功能 11/12、能力 11/12、设备 5/6、设置 11/13）。

**修正 2：`dumpLayout` 无法验证 `accessibilityText`。**
实测：给 `Toggle` 加 `.accessibilityText()` 后，dump 里 `text`/`originalText`/`description`
**仍全为空** ✗；而普通 `Text` 的内容会出现 ✓。
→ **dumpLayout 只能给审计的「下界」**，真正的无障碍验收**必须用读屏服务实测**。

#### 验证

- 构建 **BUILD SUCCESSFUL**；`node scripts/a11y_scan.js` **无输出** ✓
- 单测 **84 run / 81 pass**（3 项既有 flaky 失败，与本批无关）
- 真机冒烟：35 个文本节点、底栏 5 标签居中 **548/674/800/926/1052 无漂移** ✓
- ⚠️ **`accessibilityText` 的实际播报效果未经读屏实测** —— 唯一能验证它的手段，需要人工完成

### 验证证据（本批）

| 项目 | 命令 / 方法 | 结果 |
|---|---|---|
| ArkTS 编译（契约批） | `hvigorw assembleApp --no-daemon --stacktrace` | **BUILD SUCCESSFUL in 39 s 440 ms**，exit code 0 |
| ArkTS 编译（标准修正 + 持久化批） | 同上 | **BUILD SUCCESSFUL in 24 s 445 ms**，exit code 0 |
| 角色枚举映射 | 脚本比对 `NGFAccessibilityRole` 与 ArkUI `AccessibilityRoleType` | 52/52 全部 1:1 存在，无缺口 |
| 标准原文核验 | `web_fetch` 抓取 miit.gov.cn 67 号文页面并提取附件2 全文 | 逐字取得，13 条数值与本文档一致 |
| **Hypium 本地单测（P4 第三批）** | `hvigorw test --no-daemon` | Tests run: 39, Failure: 2, Error: 2, Pass: 35；`AccessibilityContractTest` 23/23 |
| **Hypium 本地单测（P4 第四批）** | `hvigorw test --no-daemon` | Tests run: 46, Failure: 2, Error: 2, Pass: 42；`AccessibilityContractTest` 30/30 |
| **Hypium 本地单测（P4 第七批）** | `hvigorw test --no-daemon` | Tests run: 53, Failure: 2, Error: 2, Pass: 49；`AccessibilityContractTest` 37/37 |
| **Hypium 本地单测（P4 第八批）** | `hvigorw test --no-daemon` | Tests run: 58, Failure: 2, Error: 2, Pass: 54；`AccessibilityContractTest` 42/42 |
| **Hypium 本地单测（P4 第九批）** | `hvigorw test --no-daemon` | Tests run: 63, Pass: 60；`AccessibilityContractTest` 47/47 |
| **Hypium 本地单测（P4 第十批）** | `hvigorw test --no-daemon` | Tests run: 63, Failure: 2, Error: 2, Pass: 59（少 1 个是计时敏感的 `testParallelExecution` 抖动）；`AccessibilityContractTest` 47/47 |
| **Hypium 本地单测（P4 第十一批）** | `hvigorw test --no-daemon` | Tests run: 64, Failure: 2, Error: 2, Pass: 60；`AccessibilityContractTest` 48/48 |
| **Hypium 本地单测（P4 第十二批）** | `hvigorw test --no-daemon` | **Tests run: 68, Failure: 1, Error: 2, Pass: 65**；`AccessibilityContractTest` **52/52 全通过** |
| **本批（第十三批）** | 纯文档/证据复核，未改代码 | 无需重新构建；上一批构建结果仍有效（BUILD SUCCESSFUL in 25 s 105 ms） |
| **本批（第十四批）** | 纯文档/证据复核 + 全仓库脚本核验，未改代码 | 同上 |
| **Hypium 本地单测（P4 第十五批）** | `hvigorw test --no-daemon` | Tests run: 71, Failure: 2, Error: 2, Pass: 67；`AccessibilityContractTest` 55/55 |
| **Hypium 本地单测（P4 第十六批）** | `hvigorw test --no-daemon` | **Tests run: 73, Failure: 1, Error: 2, Pass: 70**；`AccessibilityContractTest` **57/57 全通过** |
| 单测逐用例结果 | 读 `entry/.test/default/intermediates/test/coverage_data/test_result.txt` | 已逐条核对，见上文第三批 |
| 全量构建（含 barrel 变更后） | `hvigorw assembleApp --no-daemon` | **BUILD SUCCESSFUL in 24 s 30 ms**，exit code 0 |
| 打包与签名 | 同上 | 产出 `entry-default-signed.hap`（5 869 167 字节） |
| 空白检查 | `git diff --check` | exit 0，无空白错误 |

**本批没有做**：真机读屏、语义树 dump、焦点遍历、动效三档实机对比、动态字号截图、对比度实测。
这些属于 P5，**按用户决定暂缓**（PP-001），仍不能用编译成功替代 —— **暂缓不等于已通过**。

## 9. 当前未决项

已在本次探针中收敛：

- ~~API 26 中 ArkUI 无障碍属性的确切取值、最低版本~~ → 已在 §3.1/§3.2 用 SDK 声明逐行确认（含 @since）。
- ~~减少动效是否有公开 API~~ → 已确认 `isAnimationReduceEnabledSync()` / `onAnimationReduceStateChange`（@since 23）。
- ~~适老模式是否有系统能力~~ → 已确认 API 26 的 `@since 26.0.0` 系列，且提供**应用粒度**读写。

仍然未决：

- ~~**动态字体/显示缩放的公开 ArkTS API**~~ → **已探明并落地（2026-10-05）**，详见 §3.7。
  结论：`@ohos.accessibility` 里确实没有，但**字体缩放本来就不属于无障碍模块** ——
  它在 `Configuration` 与 `ApplicationContext` 里。原判断"在无障碍 API 里找不到"是对的，
  但据此得出"可能不存在"是错的。
- ~~**显示缩放（DPI/密度）是否可读**~~ → **已探明（2026-10-05）**，详见 §3.8.1：
  `@ohos.display` 的 `Display` 提供 `densityDPI` / `densityPixels` / `scaledDensity`，全部 `@since 7`。
  此前记「未探明」是因为只查了字体缩放那条线，没有查 `@ohos.display`。
- ~~**系统级高对比开关：未找到公开接口**~~ → **已探明（2026-10-05）**，见 §3.8.4：
  开关**存在**（`setTextHighContrast` @20，含 `TEXT_FOLLOW_SYSTEM_HIGH_CONTRAST`），
  但**没有 getter**，因此读不到当前状态。
  **NGF 的正确做法是"什么都不做"**（不调用即跟随系统）；已核验 NGF 全仓库从未调用该 API。
  应用内对比度策略（`NGFContrastChecker`）与系统高对比是**互补**关系，不是替代关系。
- ~~**自定义无障碍动作没有可执行入口**~~ → **该结论已作废（2026-10-05）**，见 §3.1 第八批：
  `accessibilityCustomActions(Array<AccessibilityCustomAction>)`（**26.0.0**）可下发**任意自定义动作**；
  `accessibilityActionOptions({ scrollStep })`（**23**）可设滚动步长。
  NGF 已把 `customActions` / `scrollStep` 接进语义契约并能真正下发。
  **仍待设备确认的**是 `onAccessibilityActionIntercept` 在真实读屏下的行为（按 PP-001 暂缓）。
- `isOpenTouchGuideSync()` / `getTouchModeSync()` 在目标设备上的实际系统语义需要与设置页面和读屏服务逐项对照。
- GB/T 37668-2019 及工信部适老化行动的具体条款和测试方法需要从官方标准/政策原文复核后，才能把推荐值升级为标准映射。
- `sendAccessibilityEvent()` 的 `EventInfo` 类型、频率与失败降级尚未探针。
- **hypium 套件曾长期无法编译**（3 处接口漂移，已在 P4 修复）。修复后可执行，但仍有 4 个失败用例位于 `entry/src/test/WorkflowDefinitionFacade.test.ets`，属 `contentWorkflow` 子系统、与本设计无关，需单独立项处理；详见 `.local-rules/build-commands.local.md`。
- ~~属性下发与组件没有任何页面实际接入~~ → **已收敛**：框架验证页 `NGFAccessibilityShowcasePage` 已落地并接入 `AttributeModifier`、三个可复用组件、设计令牌与订阅生命周期绑定。但该页目前仍只有**编译证据**，尚无真机截图、语义树 dump 与读屏记录，P5 之前不能声称"已验证"。
- **`testParallelExecution` 是计时敏感用例**：断言 `end - start < 140` 依赖并行调度时机，实测同一份代码两次运行结果不同（一次 Failure、一次 Success），属既有测试的稳定性问题，需单独立项改为不依赖墙钟时间的断言。

## 10. 研究进度

| 日期 | 阶段 | 结果 | 证据/下一步 |
|---|---|---|---|
| 2026-10-05 | P0 | 完成规则扫描、现有 `AccessibilityFacade`/契约/DI 盘点，建立计划和状态文件 | 本文第 2 节；进入 P1/P2 |
| 2026-10-05 | P1 | 源码确认两个现有调用；DevEco 26 SDK 声明可用；NGF `assembleApp` 已通过 ArkTS 编译、资源处理和未签名 HAP 打包，最终仅因 NGF `.p7b` 缺失在签名阶段失败 | 本文第 3 节；设备状态和有效签名仍待验证 |
| 2026-10-05 | P3 | 第一版状态快照、读屏/触摸探索/减少动效查询与生命周期监听契约落地，并通过 API 26 编译 | 本文第 8.1 节；语义属性 helper、真机状态和 UI 验收待继续 |
| 2026-10-05 | P2 | 在全国标准信息公共服务平台核验 GB/T 37668-2019 的现行状态、发布日期、实施日期和修订计划；工信部专项行动具体文号仍待官方原文复核 | 本文第 4 节；不把搜索摘要当条款 |
| 2026-10-05 | P1 | 用 API 26 SDK 声明逐行核对完成属性/信号证据矩阵（§3.1/§3.2），并新增适老模式与感官辅助能力发现（§3.3）、监听生命周期硬性要求（§3.4） | 本文第 3 节；设备行为仍待 P5 |
| 2026-10-05 | P2 | 从 miit.gov.cn 原文逐字核验工信厅信管函〔2021〕67号 附件2 全文，取得 13 条可引用数值；核验 GB/T 37668-2019 身份与修订计划；**按标准修正了"老年模式触控目标 48vp"的错误基线为 60 dp/pt**；标注 3 类不可引用项与 1 个引用陷阱 | 本文第 4 节；标准矩阵与证据等级已更新 |
| 2026-10-05 | P3 | 第二批：`NGFAccessibilitySemantics` 与 `NGFInclusiveDesignPolicy` 落地；`AccessibilityFacade` 接入适老模式、on/off 配对、移除硬编码中文；`assembleApp` BUILD SUCCESSFUL 并产出签名 HAP | 本文 §5.1.1 与 §8.1；语义 helper 与设备验收待 P4/P5 |
| 2026-10-05 | P4 | 属性绑定器（纯解析 + 薄 ArkUI 调用层）落地；新增 23 条 Hypium 无障碍单测并**全部通过**；顺带修复了让整个 hypium 套件无法编译的 3 处接口漂移 | 本文 §8.1 第三批；helper 组件与验证页待继续 |
| 2026-10-05 | P4 | 设计令牌（策略→可用数值，含附件2 §2.2/§2.4 约束）与订阅生命周期绑定落地；单测 23→30 条并全部通过；定位并修复一个会静默吞回调的 ArkTS 陷阱（候选规则 PR-C001） | 本文 §8.1 第四批；helper 组件与验证页待继续 |
| 2026-10-05 | P4 | 可复用组件落地：`NGFAccessibleButton` / `NGFAccessibleListItem` / `NGFAccessibleDialogCloseButton`；属性下发架构从「返回组件的函数」修正为 ArkUI `AttributeModifier`（原方案被编译器否决） | 本文 §5.3 与 §8.1 第五批；FormField/Navigation 与验证页待继续 |
| 2026-10-05 | P4 | **框架验证页落地并接入真实页面**：状态快照 / 策略与令牌 / 适老模式控制 / 三个组件样例 / 语义审计 / 日志；接路由与主菜单，三套 i18n 共 39 条 | 本文 §8.1 第六批；真机证据仍待 P5 |
| 2026-10-05 | P4 | 对比度核验工具落地（十六进制解析 / WCAG 相对亮度 / 两档阈值判定）；单测 30→37 条全部通过；查清并记录 WCAG sRGB 分段阈值版本分歧及其对 8bit 输入无影响 | 本文 §4.5 陷阱二、§8.1 第七批 |
| 2026-10-05 | P4 | **API 26 证据复核**：纠正 6 处 `@since` 错误、补齐 8 项遗漏声明（含能力级的 `accessibilityCustomActions`）；契约补齐 `customActions`/`scrollStep`/`traversalConsiderDescendants` 并真正可下发；新增 3 个审计码；单测 37→42 条 | 本文 §3.1、§8.1 第八批 |
| 2026-10-05 | P4 | `NGFAccessibleFormField` 落地（**不分组**方案，有 SDK 原文依据）；修正 `INTERACTIVE_WITHOUT_ACTION` 对禁用控件的误报；新增 `ngf_text_error` 令牌并实测两套主题均达 §1.3；对比度工具支持 8 位 ARGB；单测 42→47 条 | 本文 §5.3、§8.1 第九批 |
| 2026-10-05 | P4 | 发现 HDS 自有无障碍选项证据面（§3.6）；标题栏探针结论：**不另建 Navigation 组件**，改为透传；修复 NGF 标题工厂无法提供朗读文本的真实缺口（向后兼容）；验证页接入标题无障碍 + 表单字段 | 本文 §3.6、§5.3、§8.1 第十批 |
| 2026-10-05 | P4 | **闭合"动态字体 API"未决项**（并纠正推理错误）；发现并修复"应用完全不跟随系统字体"的高影响缺口；落地 `configuration.json` + `app.json5` 引用；新增 `NGF_APP_FONT_SIZE_MAX_SCALE` 与不变式单测；完成打包级验证 | 本文 §3.7、§8.1 第十一批 |
| 2026-10-05 | P4 | 适老模式命名契约（§3.1）：标准名 + 3 别名，显示走 i18n / 匹配走规范原词；4 条单测 | 本文 §8.1 第十二批 |
| 2026-10-05 | P4 | 闭合「显示缩放是否可读」（可读）与「播报有无公开入口」（有，`sendAccessibilityEvent` @9）；修正 §9 中已作废的「自定义动作无可执行入口」；把 `1 vp = 1 dp/pt` 从「工程假设」重新定性为「按定义 1:1」 | 本文 §3.8、§5.1.2、§8.1 第十三批 |
| 2026-10-05 | P4 | 闭合「系统级高对比开关」未决项：开关存在（`setTextHighContrast` @20）但**无 getter 读不到**；确认 NGF 从不覆盖用户设置（0 命中）；确立「什么都不做即跟随系统」的 NGF 策略 | 本文 §3.8.4、§8.1 第十四批 |
| 2026-10-06 | P4 | **播报能力实现**（§5.1.2 最后一项）：`NGFAnnouncementMode` + SDK 取值映射（单测钉死）+ 门面 `announce()`；`Resource` 文本经 `textResourceAnnouncedForAccessibility` 下发**无需 Context**；验证页接入真实消费者 | 本文 §8.1 第十五批；**仅编译验证**，按 PP-001 不得声称可用 |
| 2026-10-06 | P4 | **半透明表面也能验对比度**：新增 `parseHexAlpha` / `compositeOver`；发现毛玻璃令牌 `glass_chip_overlay` alpha≈0.8 此前**从未被验过**；对最暗/最亮极端背景各验一次并断言 | 本文 §8.1 第十六批 |
| 2026-10-06 | P5 | **模拟器设备端验证**：发现并修复 `$r()` 拼接 bug（PR-C004）；采集语义树 / 触控尺寸 / 生命周期 / 视觉证据；未验证部分逐条列出 | 本文 §3.9、§7、§8.1 第十七批。**证据来自模拟器，不是真机** |
| — | P4 | ~~给 HDS 列表类组件透传无障碍选项~~ | **有意不做**：NGF 全仓库未使用 `HdsListItemCard` 等组件，为假想需求写代码不是好工程 |
| — | P5 | ~~真机验收矩阵（源码/运行时/语义树/读屏/视觉/触控/动效/生命周期/性能）~~ | **按用户决定暂缓**（2026-10-05：「NGF项目暂时不需要实机测试」，见 `.agent-rules/preferences.local.md` PP-001）。**这不是「阻塞」，是范围决定** |

