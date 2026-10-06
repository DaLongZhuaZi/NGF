# 技能：无障碍（Accessibility）适配

> **触发条件**：用户提到 无障碍 / 读屏 / 屏幕朗读 / 辅助工具 / accessibilityText / 无障碍焦点 /
> 屏幕阅读器 / TalkBack / 小艺朗读；新增或修改任何**可交互**组件；
> 需要让应用被辅助工具正确识别；准备做无障碍验收时。
>
> ⚠️ **无障碍 ≠ 适老化**。适老化看 `.rules/skill-elderly-ui.md`（字号/点击区/对比度）；
> 本技能管的是**让辅助工具能读懂界面**。两者经常同时做，但要求完全不同，不要混写。

---

## 1. 唯一的硬性标准：官方「三个前提」

来源：《支持无障碍》（ArkUI 开发指导）。原文：

> 一个辅助工具具备无障碍能力的前提：**所有可交互 UI 组件均能正确设置无障碍信息**，
> 即需要满足以下三点。
> 1. **可被无障碍服务识别** —— 通过 `accessibilityLevel` 设置某个组件是否可被识别。
> 2. **提供组件功能及操作信息** —— 通过 `accessibilityText`、`accessibilityDescription` 实现。
> 3. **支持传递组件实际状态与行为** —— 通过 `accessibilityChecked`、`accessibilityRole` 实现。

**判定口径是「所有可交互 UI 组件」** —— 不是「重要的那些」。
漏掉一个图标按钮，读屏用户就在那里遇到一个无法理解的黑洞。

---

## 2. 属性全表

| 属性 | @since | 作用 | 什么时候必须用 |
|---|---|---|---|
| `accessibilityText` | 8 | 为**无文本内容**的组件提供朗读文本 | **图标按钮、纯图片按钮**（最高频漏项） |
| `accessibilityDescription` | 8 | 补充说明（比 text 更长的描述） | 需要额外解释时 |
| `accessibilityLevel` | 8 | `'auto'`（默认）/ `'yes'` / `'no'` / `'no-hide-descendants'` | **装饰元素必须 `'no'`**，否则读屏会念一堆噪音 |
| `accessibilityGroup` | 8 | `true` 时组件与其子组件作为**一整个**可选组件 | 一组相关信息（如「2026年」「1月27日」「星期二」） |
| `accessibilityChecked` | **13** | **多选/二态三态**的勾选状态（Checkbox、Toggle） | 复选框、开关 |
| `accessibilitySelected` | **13** | **单选/互斥**的选中状态（List、Tabs） | 标签页、单选列表 |
| `accessibilityRole` | **18** | 显式声明组件角色 | 自定义组件、语义不明显的容器 |
| `accessibilityNextFocusId` | 11 | **自定义焦点移动顺序** | 布局顺序与阅读顺序不一致时 |
| `accessibilityVirtualNode` | 11 | 为**自绘制**组件提供虚拟无障碍节点 | Canvas 等自绘内容 |

### `accessibilityChecked` vs `accessibilitySelected`（官方对照表）

| | `accessibilityChecked` | `accessibilitySelected` |
|---|---|---|
| 常见场景 | 复选框、开关等二态/三态组件 | 单选列表、标签页等**互斥**选择 |
| 语义目标 | **控件物理状态**（开关是否打开） | **导航焦点项**（列表当前选中项） |
| 状态持久性 | 通常需显式保存（如表单提交） | **临时性**（随焦点移动变化） |
| 典型组件 | Checkbox、Toggle | List、Tabs |

> **选错的后果**：把 Tabs 的选中写成 `accessibilityChecked`，读屏会念成
> 「已勾选」而不是「已选中」——语义错位，用户会以为是复选框。

---

## 3. ⚠️ `accessibilityText` 的写法禁忌（官方明确）

### 3.1 只写**功能简述**，不要写操作引导

> `accessibilityText` 主要用于组件的**功能简述**，而不是具体的操作和提示信息。
> **不建议**在 `accessibilityText` 中添加冗长的信息，
> 例如添加「单指双击即可播放」这种操作引导、「当前场景不支持」等状态信息。

**原因**：读屏服务**自己会**播报可执行动作（「单指双击可执行」），
应用再写一遍就是**重复播报**，而且硬编码中文还违反 i18n。

❌ `.accessibilityText('播放，图片，单指双击即可执行')`
✅ `.accessibilityText($r('app.string.a11y_play'))` → 播报「播放，图片，单指双击可执行」（由系统补全动作部分）

### 3.2 有文本又设 text → **只播报 text**

> 如果组件已有文本内容，同时又设置了 `accessibilityText` 属性，
> 此时**仅播报 `accessibilityText` 的内容**。

**后果**：给一个已经有文字的按钮再加 `accessibilityText`，
如果写得不完整，反而**丢失**了原有文本信息。

**规则**：**有可见文本的组件不要设 `accessibilityText`** —— 让它自然朗读；
只有**无文本**的组件（图标/图片按钮）才需要设。

### 3.3 必须走 i18n

`accessibilityText` 支持字符串或资源引用，**必须用资源引用**（见 `skill-i18n.md`）。

---

## 4. 分组策略（`accessibilityGroup`）

官方示例：三个 `Text`（「2026年」「1月27日」「星期二」）不分组时是**3 个独立焦点**，
用户难以感知完整信息；加 `.accessibilityGroup(true)` 后：

- 该 Column **整体可聚焦** ✓
- 子 Text 的文本**自动拼接**成「2026年1月27日星期二」✓
- 单个 Text **不再单独聚焦** ✓

> **合并规则**：启用分组后，若组件**没有**通用文本属性且**未设**无障碍文本，
> 则默认拼接**子组件的通用文本属性**作为合并文本；
> 此时**不使用**子组件的无障碍文本。

**什么时候分组**：一组语义上属于**同一个信息单元**的内容。
**什么时候不分组**：每个子项都是**独立可操作**的（如列表项）。

---

## 5. 官方「使用建议」三条

1. **优先级控制** —— 通过 `accessibilityLevel` 确保**关键操作**可被识别。
2. **语义化描述** —— 为**图标、图片等非文本元素**添加 `accessibilityText` 和 `accessibilityDescription`。
3. **分组优化** —— 对复杂布局使用 `accessibilityGroup` **减少冗余播报**。

---

## 6. NGF 框架已提供的能力（**优先复用，不要另造**）

| 能力 | 位置 | 用途 |
|---|---|---|
| `NGFAccessibilitySemantics` | `deviceAwareness/contracts/NGFAccessibilitySemantics.ets` | **完整语义模型**：53 个角色 + 4 个等级 + 动作 + 状态 + 分组 |
| `NGFAccessibilityAttributeModifier` | `uiShell/components/NGFAccessibilityAttributeBinder.ets` | **`AttributeModifier<CommonAttribute>`** —— 一行把整套语义下发到组件 |
| `resolveAccessibilityAttributes()` | 同上 | 语义 → ArkUI 属性值的解析（含未解析项提示） |
| `auditAccessibilitySemantics()` | `NGFAccessibilitySemantics.ets` | **自审工具**：检查语义是否完整（可交互但无标签等） |
| `resolveArkUiRole()` | `NGFAccessibilityAttributeBinder.ets` | NGF 角色 → ArkUI `AccessibilityRoleType` |
| `ngfAccessibilityFacade` | `deviceAwareness/facades/AccessibilityFacade.ets` | 读屏/触摸探索状态查询与订阅、`announce()` 播报 |
| `NGFAccessibilityLifecycleBinding` | `uiShell/utils/NGFAccessibilityLifecycleBinding.ets` | 订阅生命周期（on/off 严格配对） |
| 可复用组件 | `uiShell/components/NGFAccessible*.ets` | Button / ListItem / FormField / DialogCloseButton（**已内置语义**） |

**系统能力接入**（已在 `AccessibilityFacade` 完成，页面不需要重复做）：
`isOpenAccessibility` / `isOpenTouchGuide` / `isScreenReaderOpen` 状态读取，
`accessibilityStateChange` / `touchGuideStateChange` / `screenReaderStateChange` /
`onAnimationReduceStateChange` 事件订阅，`sendAccessibilityEvent` 播报。

---

## 7. 逐项改造方法

### 7.1 图标按钮（最高频漏项）

```ts
// ❌ 读屏只会念「图片，单指双击可执行」
Image($r('app.media.play')).width(60).height(60).onClick(() => { /* ... */ })

// ✅
Image($r('app.media.play'))
  .width(60).height(60)
  .accessibilityText($r('app.string.a11y_play'))   // 只写功能名
  .accessibilityLevel('yes')
  .onClick(() => { /* ... */ })
```

**排查方法**：搜所有 `SymbolGlyph(` / `Image(` 且带 `.onClick(` 的节点。

### 7.2 纯装饰元素

```ts
// 分割线、背景图、纯装饰图标 —— 读屏不该念它们
Divider().accessibilityLevel('no')
Image($r('app.media.decor')).accessibilityLevel('no')
```

**用 `'no-hide-descendants'`** 当整个子树都是装饰时。

### 7.3 成组信息

```ts
Column() {
  Text('2026年'); Text('1月27日'); Text('星期二')
}
.accessibilityGroup(true)   // 合成一个焦点，读「2026年1月27日星期二」
```

### 7.4 状态类组件

```ts
// 开关 / 复选框 → accessibilityChecked
Toggle({ type: ToggleType.Switch, isOn: this.on })
  .accessibilityChecked(this.on)

// 标签页 / 单选列表 → accessibilitySelected
Column() { /* 标签内容 */ }
  .accessibilitySelected(this.selectedIndex === i)
```

### 7.5 用框架语义模型（推荐，尤其组件多时）

```ts
import { NGFAccessibilityAttributeModifier, NGFAccessibilitySemantics } from 'ngf_framework';

private get playSemantics(): NGFAccessibilitySemantics { /* 构造一次，缓存 */ }

Image($r('app.media.play'))
  .attributeModifier(new NGFAccessibilityAttributeModifier(this.playSemantics))
```

> ⚠️ 与 `skill-elderly-ui.md` §4.7c③b 同一条硬约束：
> **修饰器必须是 `@State` 字段或缓存实例，禁止在 `build()` 路径里用 getter 现场构造** ——
> 那会让整页渲染异常（实测文本从 21 条掉到 7 条）。

### 7.6 焦点顺序（布局顺序 ≠ 阅读顺序时）

```ts
Text('第一步').id('step1').accessibilityNextFocusId('step3')
Text('第二步').id('step2')
Text('第三步').id('step3')
```

---

## 8. 常见错误

| 错误 | 后果 | 正确做法 |
|---|---|---|
| 图标按钮无 `accessibilityText` | 读屏念「图片，单指双击可执行」，用户不知功能 | 补功能简述 |
| `accessibilityText` 写「单指双击即可播放」 | **重复播报**（系统自己会念动作） | 只写功能名 |
| 已有文本的按钮又设 `accessibilityText` | **仅播报 text**，可能丢信息 | 有文本就不设 |
| 装饰元素不设 `accessibilityLevel('no')` | 读屏噪音，用户要划很多次 | 装饰一律 `'no'` |
| Tabs 选中用 `accessibilityChecked` | 念成「已勾选」，语义错位 | 用 `accessibilitySelected` |
| `accessibilityText` 硬编码中文 | 违反 i18n，英文环境仍是中文 | 用 `$r()` |
| 自绘组件不设 `accessibilityVirtualNode` | 读屏完全读不到 | 提供虚拟节点 |

---

## 8b. ⚠️ 怎么审计：`dumpLayout` 的能与不能（**实测确认**）

**`dumpLayout` 只能验证「可见文本」，验证不了 `accessibilityText`。**

2026-10-06 实测（真机 MatePad Mini / API 26）：
给 `Toggle` 加上 `.accessibilityText($r('app.string.settings_keep_screen_on'))` 后，
`dumpLayout` 里该节点的 `text` / `originalText` / `description` **仍全为空** ✗；
而普通 `Text` 节点的内容会出现在 `text` 与 `originalText` 里 ✓。

`dumpLayout` 暴露的无障碍相关属性：`accessibilityId`、`description`、`hint`、
`checkable`、`checked`、`selected`、`clickable`、`enabled`、`text`、`originalText`。

### 能可靠做的审计

✅ **统计「可点击但**既无可见文本、也无 description/hint**」的节点** ——
这些是**确定**读屏无法理解的（因为可见文本就是读屏默认朗读的内容）。
判定要**沿子树收集文本**：`Button` 自己的 `text` 是空的，文字在子 `Text` 里。

✅ 统计 `checkable` / `checked` / `selected` 是否符合组件语义。

### 做不了、别假装做了的审计

❌ **验证 `accessibilityText` 是否生效** —— dump 里看不到。
❌ **判断「某节点读屏会念什么」** —— 例如 `SwiperIndicator` 在 dump 里
`text=""`，但 ArkUI **可能**自动播报「第 1 页，共 2 页」；
仅凭 dump 不能断言它坏了，**必须真实读屏实测**。

### 必须排除的误报

| 误报源 | 排除方法 |
|---|---|
| **滚动条** | 极窄（宽 < 40px）的 `Button` |
| **系统状态栏** | `y < 110`（应用内容之外） |
| **HDS 浮动底栏的背景容器** | `Tabs > Stack`，`clickable=true` 但**无子节点**；这是 HDS 内部行为，应用侧改不了 |
| **有 `accessibilityText` 的节点** | dump 里同样是空的 —— **无法与「真的没标注」区分** ✗ |

> **结论**：`dumpLayout` 能给出**下界**（确定有问题的），
> 给不出**上界**（不能证明都没问题）。真正的无障碍验收**必须用读屏服务实测**。

## 8c. ⚠️ 「显示与功能脱节」的经典 bug（见 PR-016）

**症状**：用户点了设置，功能**确实生效**（选中态、主题颜色都变了），
但**那一行显示的值不变** —— 用户会以为「选项没有和功能联系起来」。

**根因**：`@Builder` 用**位置参数传基本类型**时，ArkUI **不建立状态依赖** ——
里面的文本停在首次构建的结果。

```ts
// ✗ 传基本类型 → 永不刷新
@Builder private buildSettingRow(label: ResourceStr, value: ResourceStr): void {
  Row() { Text(label); Text(value) }
}

// ✓ 传对象（按引用）→ 状态变化会刷新
export interface NGFSettingsRowParams { label: ResourceStr; value: ResourceStr; }
@Builder private buildSettingRow(params: NGFSettingsRowParams): void {
  Row() { Text(params.label); Text(params.value) }
}
this.buildSettingRow({ label: $r('...'), value: this.currentTheme })
```

**证据**：2026-10-06 真机实测 —— 点「深色」后
`accessibilitySelected` 已变 `true` ✓ 但该行仍显示「跟随系统」✗；改对象参数后恢复 ✓。

> **做无障碍验收时顺带查这个**：给控件加 `accessibilitySelected` 之后，
> 一定要**同时**确认旁边的**显示值**也跟着变 —— 两者脱节就是本问题。

### 8c.2 第二类：「标签 + 数值」没分组 → 读屏读到两个孤立节点（见 PR-017）

**症状**：设备页、设置页的信息行，读屏依次念出「推荐停靠」…「右侧」…「握持侧」…「未握持」，
用户**不知道哪个值属于哪个标签**。

**修复**：容器末尾加 `.accessibilityGroup(true)` —— 官方会把子文本**拼接**成一个节点播报。

```ts
Row() { Text(params.label); Text(params.value) }
.width('100%')
.accessibilityGroup(true)     // 读屏拼成「推荐停靠 右侧」
```

**⚠️ 例外**：容器内**有** `Button`/`Toggle` 等可交互子组件时**禁止分组** ——
分组后子组件不再可单独聚焦，**交互会废掉**。
判据：只有 `Text` → 可分组；有交互组件 → 不可分组。

**本仓库已分组的 12 处**：`buildSettingRow` / `buildInfoRow` / `buildLinkRow` /
`buildPerfInfoRow` / `buildHeaderGlassChip` / `buildMetricPill` / `buildCapabilityCard` /
`buildResultStat` / `buildStrategyRule` / `buildMaterialApiMetric` / `buildMaterialApiLine` / 空态面板。

> ⚠️ **`dumpLayout` 验证不了分组** —— 它 dump 的是**渲染树**，分组作用于**无障碍树**；
> 分组后 dump 里**仍然**能看到子 Text 节点。只能靠**读屏实测**。

## 8d. 🔴 ArkUI 属性签名的**三个硬约束**（都是实测踩出来的）

### 8d.1 `accessibilityText` / `accessibilityDescription` **不接受 `ResourceStr` 联合类型**

SDK（`common.d.ts`）里是**两个独立重载**，**不是**一个联合类型参数：

```ts
accessibilityText(value: string): T;      // 重载 1
accessibilityText(text: Resource): T;     // 重载 2
accessibilityDescription(value: string): T;
accessibilityDescription(description: Resource): T;
```

**后果**：把 `ResourceStr`（= `string | Resource`）**直接**传进去会重载解析失败，
编译报 `Type 'string' is not assignable to type 'Resource'`。

| 写法 | 结果 |
|---|---|
| `.accessibilityText('播放')` | ✅ 走重载 1 |
| `.accessibilityText($r('app.string.a11y_play'))` | ✅ 走重载 2 |
| `.accessibilityText(someResourceStr)` | ❌ **编译失败** |
| `.accessibilityText(this.methodReturningResourceStr())` | ❌ **编译失败** |
| `.accessibilityText(resolveResourceString(ctx, res))` | ✅ 先解析成 string |

**正确写法（动态值）** —— 与框架内部处理 `textHint` 的方式一致：

```ts
.accessibilityText(resolveResourceString(this.getUIContext().getHostContext(), getElderlyModeDisplayName()))
.accessibilityDescription(resolveResourceString(this.getUIContext().getHostContext(), this.describeState()))
```

> 框架内部（`NGFAccessibilityAttributeBinder`）用 `typeof x === 'string'` 分支
> 来同时满足两个重载 —— 那是**修饰器**场景（能拿到 instance）；
> **页面属性链**场景拿不到 instance，只能**先解析成 string**。

### 8d.2 `@Builder` 只有**按引用（传对象）**传参才建立状态依赖

见 **§8c / PR-016**。位置参数传基本类型 → 内部文本**永不刷新**。

### 8d.3 分组容器内**有交互子组件时禁止分组**

见 **§8c.2 / PR-017**。分组会把子树当**一个**节点，子组件不再可单独聚焦。

---

## 8e. 全量检查器：`scripts/a11y_scan.js`

```bash
node scripts/a11y_scan.js
```

**覆盖 5 类绑定错误**（每一类都在本项目真实发生过）：

| # | 代码 | 检查 |
|---|---|---|
| 1 | `ICON_WITHOUT_LABEL` | 图标/图片无 `accessibilityText` 且未标 `accessibilityLevel('no')` |
| 2 | `CONTAINER_WITHOUT_LABEL` | 可点击容器无 `Text` 子节点也无 `accessibilityText` |
| 3 | `TOGGLE_WITHOUT_LABEL` | `Toggle` 无 `accessibilityText` |
| 4 | `BUILDER_POSITIONAL_PARAM` | `@Builder` 用位置参数渲染文本（PR-016） |
| 5 | `A11Y_TEXT_RESOURCESTR` | `accessibilityText` 传了声明返回 `ResourceStr` 的方法 |

**检查器自身的三个坑（已修，别改回去）**：
1. ❌ **不能用「下一行是否以 `.` 开头」取属性链** —— 多行属性参数
   （`.fontColor([a` / `? x : y])`）的续行不以 `.` 开头，会漏掉链尾的
   `.accessibilityLevel('no')` → **误报**。要用**缩进深度**。
2. ❌ **容器形态的属性链写在块结束的 `}` 之后**，且缩进与组件行**相同** ——
   直接对 `}` 行取链会立刻中断。要从**组件行的缩进**重新收集。
3. ❌ **不能只看「参数是不是方法调用」** —— 返回 `string` 的方法合法。
   必须**查该方法在本文件里的声明返回类型**是否为 `ResourceStr`。

### 它能证明什么、不能证明什么

**能**：给出**下界** —— 报出来的基本是真问题。
**不能**：给出**上界** —— **没报不等于没问题**。

**三样东西静态查不到，`dumpLayout` 也查不到，只能靠读屏实测**：
1. `accessibilityText` 是否真的被播报 —— `dumpLayout` 里 `text`/`originalText`/`description` 都是空的
2. `accessibilityGroup(true)` 是否生效 —— `dumpLayout` dump 的是**渲染树**，
   分组作用于**无障碍树**，分组后 dump 里**仍然**能看到子 Text 节点
3. 焦点顺序、朗读停顿等运行时行为

> ✅ **唯一能在 dump 里验证的无障碍属性是 `accessibilitySelected`** ——
> 它显示为节点的 `selected` 字段（2026-10-06 实测确认）。

---

## 9. 验收清单

**三个前提（官方硬性）**
- [ ] 所有**可交互**组件都能被识别（`accessibilityLevel` 不是 `'no'`）
- [ ] 所有**无文本**的可交互组件都有 `accessibilityText`（**图标按钮重点排查**）
- [ ] 状态类组件传了 `accessibilityChecked` / `accessibilitySelected`

**语义质量**
- [ ] `accessibilityText` **只写功能简述**，无操作引导（「双击…」「点击…」）
- [ ] 有可见文本的组件**没有**多余 `accessibilityText`
- [ ] 所有 `accessibilityText` 走 `$r()` 资源；
      **动态值必须先 `resolveResourceString()` 解析成 string**（§8d.1，联合类型编译不过）
- [ ] `Toggle` 都有 `accessibilityText`（**标签是兄弟节点时必查**）
- [ ] 装饰元素已 `accessibilityLevel('no')`
- [ ] 成组信息已 `accessibilityGroup(true)`（**「标签 + 数值」行必查** —— 见 §8c.2 / PR-017）
- [ ] 需要分组的容器内**没有** `Button`/`Toggle`（有则**不可**分组，否则交互失效）
- [ ] 自定义/自绘组件有 `accessibilityRole` 或 `accessibilityVirtualNode`

**系统接入**
- [ ] 读屏开启时界面可用（`ngfAccessibilityFacade.isScreenReaderEnabled()`）
- [ ] 触摸探索开启时不误触（`isTouchGuideEnabled()`）
- [ ] 页面订阅与取消订阅成对（`NGFAccessibilityLifecycleBinding`）
- [ ] 关键状态变化有播报（`ngfAccessibilityFacade.announce()`）

**工程**
- [ ] `node scripts/a11y_scan.js` 无输出（**注意：只代表下界，不能证明"都没问题"**）
- [ ] `auditAccessibilitySemantics()` 对该页语义扫描无 ERROR
- [ ] 单测覆盖新增语义（`entry/src/test/AccessibilityContract.test.ets`）

---

## 10. 关键文件路径速查

| 文件 | 说明 |
|---|---|
| `ngf_framework/src/main/ets/deviceAwareness/contracts/NGFAccessibilitySemantics.ets` | 语义模型 + `auditAccessibilitySemantics()` |
| `ngf_framework/src/main/ets/uiShell/components/NGFAccessibilityAttributeBinder.ets` | `NGFAccessibilityAttributeModifier` + `resolveAccessibilityAttributes()` |
| `ngf_framework/src/main/ets/deviceAwareness/facades/AccessibilityFacade.ets` | `ngfAccessibilityFacade` |
| `ngf_framework/src/main/ets/uiShell/utils/NGFAccessibilityLifecycleBinding.ets` | 订阅生命周期绑定 |
| `ngf_framework/src/main/ets/uiShell/components/NGFAccessible*.ets` | 4 个已内置语义的可复用组件 |
| `entry/src/test/AccessibilityContract.test.ets` | 无障碍契约单测（75 个用例） |
| `entry/src/main/ets/pages/ngf/NGFAccessibilityShowcasePage.ets` | 参考实现 |
| `docs/NGF_ACCESSIBILITY_ELDERLY_DESIGN.md` | 完整证据链与验收矩阵 |

---

## 11. 官方文档

- [支持无障碍（ArkUI 开发指导）](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/arkts-universal-attributes-accessibility)
- [无障碍属性 API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-accessibility)
- [Accessibility Kit（无障碍服务）](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/accessibility-arkts)

> 文档站是 Angular SPA，`web_fetch` 只能拿到空壳；
> 取原文请用 OpenHarmony 文档镜像的 raw markdown：
> `https://raw.githubusercontent.com/openharmony/docs/master/zh-cn/application-dev/ui/arkts-universal-attributes-accessibility.md`
