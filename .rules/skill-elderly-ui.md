# 技能：适老化 UI/UX 改造

**适用场景**：把一个已经存在的普通版页面/应用，改造出**符合中国官方规范的适老版界面**，且**功能与普通版完全一致**。

**自动触发条件（满足任意一条即应主动阅读本文件）**：
- 用户提到"适老化""适老版""长辈版""老年模式""关怀版""亲情版""关爱版""大字号模式""无障碍适老化"
- 准备改造已有页面以适配老年用户；准备新增适老版入口、适老版开关或适老版页面
- 涉及 `NGFInclusiveDesignPolicy`、`NGFInclusiveDesignTokens`、`NGFAccessibleButton`、`NGFAccessibleListItem`、`NGFAccessibleFormField`、`NGFAccessibleDialogCloseButton`、`NGFAccessibilityLifecycleBinding`、`NGFContrastChecker`、`NGFElderlyModeNaming`
- 需要核对触控目标 44/48/60 dp/pt、字号 18/30 dp/pt、行距 1.3 倍、对比度 4.5:1 等适老化指标
- 需要证明"适老版与普通版功能一致"

---

## 1. 背景与依据

### 1.1 法规依据（唯一权威来源）

**工信厅信管函〔2021〕67号 附件2《移动互联网应用（APP）适老化通用设计规范》**
官方 URL：<https://www.miit.gov.cn/jgsj/xgj/wjfb/art/2021/art_81e8b738d6b24ad6a04f7ecb3f4e0702.html>
（成文 2021-04-06；完整引用链与核验过程见 `docs/NGF_ACCESSIBILITY_ELDERLY_DESIGN.md` §4.1）

本技能 §2.1 的全部数值均从该页面**逐字核验**取得，条款号与原文一一对应。

### 1.2 适老化 ≠ 无障碍（必须分清）

| | 适老化 | 无障碍 |
|---|---|---|
| 目标人群 | 老年用户（视力、触控精度、认知速度下降） | 残障用户（读屏、助听、开关控制等） |
| 主要手段 | 大字号、大触控目标、高对比、简化层级 | 语义树、朗读、焦点顺序、动作 |
| 本技能 | ✅ 覆盖 | 只覆盖"不得阻断"（§4.1），完整方法见 `skill-arkui-knowledge.md` 与设计文档 §3/§5 |

**两者是互补关系，不是替代关系。** 只做适老化不做无障碍，读屏用户仍然用不了。

---

## 2. 硬性要求与指标（可直接引用）

### 2.1 官方规范原文数值（**这 13 条可直接引用**）

| 条款 | 原文要求（逐字） | 落地字段 |
|---|---|---|
| §1.1 字型大小 | 「主要功能及主要界面的文字信息……最大字体不小于30 dp/pt，适老版界面及单独的适老版APP中的主要文字信息不小于18 dp/pt」 | `supportedMaxFontDp = 30`；`elderlyBodyFontDp = 18` |
| §1.2 行间距 | 「段落内文字的行距至少为1.3倍，且段落间距至少比行距大1.3倍」 | `minLineHeightRatio = 1.3`；`minParagraphSpacingRatio = 1.3` |
| §1.3 对比度 | 「对比度至少为4.5：1（字号大于18 dp/pt时文本及文本图像对比度至少为3：1）」 | `minTextContrastRatio = 4.5`；`minLargeTextContrastRatio = 3` |
| §1.4 颜色用途 | 「文本颜色不是作为传达信息、表明动作、提示响应等区分视觉元素的唯一手段」 | 非颜色冗余 |
| §1.5 验证码 | 非文本验证码「应提供可被不同类型感官（视觉、听觉等）接受的替代表现形式」 | 表单约束 |
| §2.1 组件焦点大小 | 「适老版界面中的主要组件可点击焦点区域尺寸不小于60 × 60dp/pt，其他页面下的主要组件可点击焦点区域尺寸不小于44 × 44dp/pt；单独的适老版APP中首页主要组件可点击焦点区域尺寸不小于48 × 48dp/pt」 | `elderlyPageTouchTargetDp = 60`；`standardPageTouchTargetDp = 44`；`standaloneElderlyHomeTouchTargetDp = 48` |
| §2.2 手势操作 | 「避免需3个或以上手指才能完成的复杂手势操作」 | `NGF_MAX_GESTURE_FINGER_COUNT = 2` |
| §2.3 充足操作时间 | 「应为用户的操作留下充足时间，在用户操作完毕前界面不发生变化」 | 超时/倒计时约束 |
| §2.4 浮窗 | 「关闭按钮只可在左上、右上、中央底部，且最小点击响应区域不能小于44×44dp/pt」 | `dialogCloseTargetDp = 44` + 位置白名单 |
| §3.1 提示机制 | 「应将『长辈版』作为标准功能名……同时设置『亲情版』、『关爱版』、『关怀版』等别名作为搜索关键字」 | `NGFElderlyModeNaming` |
| §4.1 辅助技术 | 「移动应用程序不应禁止或限制终端厂商已适配好的辅助设备（如读屏软件等）的接入与使用」 | 无障碍能力不得被框架阻断 |
| §5.1.1 禁止广告插件 | 「适老版界面、单独的适老版APP中严禁出现广告内容及插件」 | 产品治理约束 |
| §5.1.2 禁止诱导类按键 | 「移动应用程序中无诱导下载、诱导付款等诱导式按键」 | 产品治理约束 |

> ⚠️ **§2.4 原文勘误**：官方原文确为「44×44dp/pt dp/pt」（重复了 dp/pt），属原文笔误。
> 引用时写「44×44 dp/pt（原文如此）」。

### 2.2 NGF 工程基线（**不是标准原文，不得声称是**）

| 维度 | NGF 基线 | 与标准的关系 |
|---|---|---|
| 最小正文字号 | `ngfMinBodyFontVp = 16` | NGF 自定；标准只规定适老版 ≥18 |
| 推荐触控目标 | `ngfRecommendedTouchTargetVp = 48` | NGF 自定；与 §2.1 的 48 数值相同但用途不同 |
| 非文字对比度 | `minNonTextContrastRatio = 3` | NGF 自定；**不可**与 §1.3 的大字号 3:1 混为一谈 |
| 应用字体缩放上限 | `NGF_APP_FONT_SIZE_MAX_SCALE = 2` | 推导自 §1.1（见 §4.1） |

### 2.3 两个必须知道的引用陷阱

**陷阱一**：67号原文引用的 **YD/T1822-2008 已废止**（2012 版亦已废止，现行替代为 GB/Z 41284-2022）。
引用时必须保留原文表述并加注「原文如此，该行业标准已废止」。

**陷阱二**：附件2 **只给对比度阈值，没给计算公式**。公式来自 WCAG 2.x（国际标准），
且两个 W3C 来源的 sRGB 线性化分段阈值**不一致**（`0.03928` vs `0.04045`）。
NGF 采用现行文档的 `0.04045`，并已证明该分歧**对 8bit 输入无影响**。
引用时必须写清：**阈值来自中国规范，公式来自国际标准**。

---

## 3. 核心架构：同一页面 + 适老呈现层

### 3.1 铁律：不得复制页面

适老版**不是另写一套页面**，而是**同一页面按策略切换呈现**。

```text
✗ 错误：ElderlyHomePage.ets 复制 HomePage.ets  → 业务逻辑两份，必然漂移
✓ 正确：HomePage.ets 内部按 tokens / uiContext 决定呈现  → 功能天然一致
```

**理由**：复制页面意味着路由、数据源、门面调用、错误处理全部要维护两份。
任何一次业务改动只要漏改一份，就出现"适老版少了个功能"——而这正是本技能要杜绝的。

**唯一例外**：结构差异过大、无法用同一布局承载的页面（例如首页要从"卡片网格"变成"单列大按钮"）。
破例时必须在该页面文件头注释里写明理由，并在 §6 的一致性清单里登记。

### 3.2 标准模式（页面级适配）—— **直接抄这个模板**

**这是当前推荐且真机验证过的模式。** 完整、可直接编译。

```typescript
import {
  NGFAccessibilityBindingListener,
  NGFAccessibilityLifecycleBinding,
  NGFA11yModifierSet,
  NGFA11yTextScale,
  NGFInclusiveDesignPolicy,
  NGFInclusiveDesignResolved,
  ngfAccessibilityFacade,
  resolveA11yTextScaleForCurrent
} from 'ngf_framework';

@Component
export struct MyPage {
  // ① 缩放器：用于「间距」（space 是构造参数，没有修饰器）
  @State private a11yScale: NGFA11yTextScale = resolveA11yTextScaleForCurrent();
  // ② 修饰器集：用于字号/行高/点击区。必须是 @State 字段，**不能是 getter**
  @State private a11yMods: NGFA11yModifierSet = new NGFA11yModifierSet(resolveA11yTextScaleForCurrent());
  private a11yBinding: NGFAccessibilityLifecycleBinding | null = null;

  aboutToAppear(): void {
    this.attachA11yBinding();
  }

  aboutToDisappear(): void {
    const binding: NGFAccessibilityLifecycleBinding | null = this.a11yBinding;
    if (binding !== null) { binding.detach(); this.a11yBinding = null; }
  }

  /** 订阅平台策略；与 aboutToDisappear 的 detach **严格成对**（官方硬性要求） */
  private attachA11yBinding(): void {
    if (this.a11yBinding !== null) { return; }
    const listener: NGFAccessibilityBindingListener = {
      onInclusiveDesignChanged: (_resolved: NGFInclusiveDesignResolved): void => {
        // 重新解析必须用 ForCurrent 版本 —— 它同时考虑关怀模式与系统字体缩放
        this.a11yScale = resolveA11yTextScaleForCurrent();
        // 修饰器集必须**新建实例**：命令式下发，只改内部字段不会重新下发
        this.a11yMods = new NGFA11yModifierSet(this.a11yScale);
      }
    };
    this.a11yBinding = new NGFAccessibilityLifecycleBinding(listener);
    this.a11yBinding.attach();
  }

  build() {
    Column({ space: this.a11yScale.paragraphSpacing(12, 18) }) {
      Text($r('app.string.page_title'))
        .attributeModifier(this.a11yMods.text(18))
        .fontWeight(FontWeight.Bold)
      Button($r('app.string.action_confirm'))
        .attributeModifier(this.a11yMods.button(16, 40))
        .onClick((): void => { /* ... */ })
      Toggle({ type: ToggleType.Switch })
        .attributeModifier(this.a11yMods.toggle(0))
    }
    .padding({ left: 16, right: 16 })
  }
}
```

**普通档零视觉回归**：所有修饰器在普通档都返回原值
（`font` 原样、`lineHeight` 返回 0 = 随字号自适应、点击区不抬）✓

> **注意**：`NGFAccessibilityLifecycleBinding` 的回调接口用的是**可选函数类型属性**，
> 不要写成"可选方法"（见 `.agent-rules/project-rules.md` PR-C001）。

**更完整的历史写法**（用 `NGFInclusiveDesignTokens` 一次性拿全部令牌）见
`entry/src/main/ets/pages/ngf/NGFAccessibilityShowcasePage.ets`；
新页面建议用上面的**缩放器 + 修饰器**写法，更直接、也更不容易漏。
### 3.3 功能一致性的三层保证

| 层 | 机制 | 怎么检查 |
|---|---|---|
| **1. 架构层** | 同一页面 + 策略切换 → 路由/数据源/业务调用完全复用 | 代码评审：适老版不得出现 `if (isElderly) { 另一套业务调用 }` |
| **2. 入口层** | 普通版每个功能入口在适老版**仍可达**（可改文案、位置、形态，**不可删**） | 逐条核对功能入口清单；删除任何入口必须在清单里写明理由并获确认 |
| **3. 可执行层** | `uitest dumpLayout` 导出两版**可点击节点清单**做差分 | 见下方命令；差异必须逐条说明 |

**第 3 层的可执行方法**（模拟器与真机均验证可行）：

```powershell
# <target> 换成实际设备：模拟器 127.0.0.1:5555 / 真机 192.168.0.36:35573
hdc -t <target> shell uitest dumpLayout -p /data/local/tmp/normal.json
hdc -t <target> file recv /data/local/tmp/normal.json ./normal.json
# 切到长辈版后再导出
hdc -t <target> shell uitest dumpLayout -p /data/local/tmp/elderly.json
hdc -t <target> file recv /data/local/tmp/elderly.json ./elderly.json
```

> ⚠️ **测量前先确认被测对象是正常的**：核对 dump 里确实含目标页面的标志文本
> （例如 `NGF MainMenuPage`）、且文本节点数量与预期相符。
> 2026-10-06 我因为量了一个**被自己改坏的页面**，得出了完全相反的结论。
> 另注意 `dumpLayout` 会包含**系统状态栏**节点（y 很小），统计时要排除。

然后对比两份 JSON 里 `attributes.clickable == "true"` 的节点集合。
**节点数量减少或语义消失 = 功能可能丢失**，必须逐条解释（例如"两个按钮合并成一个"是合法简化，
"删除按钮"不是）。

### 3.4 长内容不要靠"删功能"来简化

适老化的简化针对**视觉密度与操作步数**，不针对**功能集合**：
- ✅ 允许：把 10 个平铺入口收进"更多"，但"更多"里必须都在
- ✅ 允许：把长表单拆成多步，但总字段不变
- ❌ 禁止：因为"老年人用不到"而移除功能

---

## 4. 逐项改造方法

### 4.1 字号与字体缩放（§1.1）

**两件事，都要做**：

1. **页面内字号**从 tokens 取，不硬编码：
   ```typescript
   Text('内容').fontSize(this.tokens.bodyFontSize)          // 适老版自动 18，普通版 16
   Text('内容').lineHeight(this.tokens.bodyLineHeight)      // 自动 = 字号 × 1.3
   ```
2. **应用必须跟随系统字体**（否则用户把系统字体调大，应用内毫无反应）：
   - `AppScope/app.json5` → `"configuration": "$profile:configuration"`
   - `AppScope/resources/base/profile/configuration.json`：
     ```json
     { "configuration": { "fontSizeScale": "followSystem", "fontSizeMaxScale": "2" } }
     ```
   - **为什么是 "2"**：§1.1 要求最大字体 ≥30 dp/pt，NGF 最小正文 16 vp → 所需倍率 30/16 = **1.875**；
     `fontSizeMaxScale` 是**枚举字符串**（`"1"|"1.15"|"1.3"|"1.45"|"1.75"|"2"|"3.2"`），
     不小于 1.875 的最小值是 `"2"`。**选 `"1.75"` 只能到 28 vp，不达标。**

### 4.2 行距与段距（§1.2）

```typescript
Text('正文')
  .fontSize(this.tokens.bodyFontSize)
  .lineHeight(this.tokens.bodyLineHeight)          // 字号 × 1.3
Column({ space: this.tokens.paragraphSpacing })    // 段距 ≥ 行距 × 1.3
```

### 4.3 对比度（§1.3）

**判定规则**：字号 >18 dp/pt → 3:1；否则 4.5:1。

```typescript
import { parseHexColor, checkTextContrast, parseHexAlpha, compositeOver } from 'ngf_framework';

// 不透明颜色直接算
const fg = parseHexColor('#1C2430');
const bg = parseHexColor('#FFFFFF');
// checkTextContrast(fg, bg, this.tokens.bodyFontSize).passed

// ⚠️ 半透明（毛玻璃）必须先合成，不能直接算
const overlay = parseHexColor('#CCFFFFFF');
const alpha = parseHexAlpha('#CCFFFFFF');            // ≈ 0.8
const effective = compositeOver(overlay, alpha, backdrop);
```

**半透明表面必须对最暗与最亮两种极端背景各验一次** —— 实际背景可能是渐变或图片。

#### ⚠️ 最容易踩的坑：表面材质失效会让对比度**整体崩塌**（见 PR-006 / PR-007）

**症状**：卡片看起来「没有背景」，文字直接压在沉浸式渐变上；实测对比度只有 **1.5 ~ 2.3 : 1**。

**根因**：组件把表面交给**系统材质**（`.systemMaterial(...)`），同时把背景 / 边框 / 模糊 / 阴影
**全部置空**（返回 `Color.Transparent` / `undefined`）。一旦系统材质在该组件上不生效
（**API 调整后，除 HDS 底栏外的普通组件都不生效**），组件就变成**全透明**。

**正确做法**：普通组件**一律不使用系统材质**，改用**普通玻璃模糊材质**：

```typescript
Column() { /* ... */ }
  .backgroundColor($r('app.color.panel_background'))                    // 面板底色
  .backgroundEffect(new NGFMaterialBackgroundEffectOptions(             // 玻璃模糊
    32, 1.24, 1.05, '#10FFFFFF'))
  .border({ width: 1, color: $r('app.color.glass_border_light') })
  .shadow({ radius: 12, color: '#180F172A', offsetX: 0, offsetY: 6 })
// ✗ 不要再加 .systemMaterial(...)
```

**只有 HDS 底栏例外** —— 它走 `barFloatingStyle({ systemMaterialEffect: ... })`，是另一套 API。

#### ⚠️ 适老指标必须在**目标设备**上实测（见 PR-009）

**模拟器结论不能替代真机结论。** 实测差异：
- 模拟器 `127.0.0.1:5555` → `densityPixels = 2.75`
- MatePad Mini `192.168.0.36:35573` → `densityPixels = **2.393**`

同一个百分比宽度、同一段代码，在两台设备上算出的 **vp 值不同**。
本项目的两个缺口（标签栏每项 53 vp、设置页 Toggle 36×20 vp）**只在真机上暴露**。

**密度反推法**（设备不提供 `wm density` 时）：
找一个代码里**写死尺寸**的元素（例如 `constraintSize` 60 vp 的 Toggle），
用 `实测 px ÷ 已知 vp` 得到 `densityPixels`。

**测量时要排除被视口裁切的节点** —— 否则会把「滚到屏幕外只剩 3px 的卡片」
误判成「字号过小」。

**怎么验证**（不能靠肉眼）：

```powershell
hdc -t <emu> shell snapshot_display -f /data/local/tmp/s.jpeg
hdc -t <emu> file recv /data/local/tmp/s.jpeg ./s.jpeg
```

然后用**声明色值**对**实测背景**算比值 —— **不要用截图里的极值像素**：
JPEG 会把极值外推，对深色文字会**高估**对比度。用像素法只做「背景是什么颜色」的判断。

**⚠️ 更隐蔽的变体：决策逻辑被复制到多处**

如果「用不用系统材质」这个判断在**多个页面各写了一份**，那么改令牌层**不会生效**，
而且**不会有任何报错** —— 表现就是"某些页面还是全透明、文字不可读"。

**排查方法**：全仓库搜这类开关的实现体，确认只有一处。

```powershell
# 例：搜材质判断的实现体，命中数应为 0（说明都委托给了令牌层）
Get-ChildItem -Recurse -File -Include '*.ets' 'entry/src','ngf_framework/src' |
  Select-String -Pattern 'systemMaterialState !== uiMaterial'
```

**通用原则**：**同一个决策只允许一处实现。** 新增此类开关前，先确认是否已有单一来源；
有则委托，没有则先建单一来源，再让各处引用。

**同类坑：标题栏底色**。若标题栏文字被硬编码为白色，其底色必须是**深色或透明**；
传浅色会让白字不可读 —— 而这条回退路径在系统材质正常时**永远不会被执行**，所以能藏很久。

### 4.4 触控目标（§2.1）

**三种场景，数值不同**：

| 场景 | 下限 | 取法 |
|---|---|---|
| 适老版界面 | **60 × 60** | `this.tokens.minTouchTarget`（`NGFUiContext.ELDERLY_PAGE`） |
| 其他页面 | **44 × 44** | `this.tokens.minTouchTarget`（`NGFUiContext.STANDARD_PAGE`） |
| 单独的适老版 APP 首页 | **48 × 48** | `NGFUiContext.STANDALONE_ELDERLY_HOME` |

**点击区与视觉尺寸分离** —— 视觉上可以紧凑，点击区必须够大：

```typescript
Button('确定')
  .constraintSize({ minWidth: this.tokens.minTouchTarget, minHeight: this.tokens.minTouchTarget })
```

### 4.5 非颜色冗余（§1.4）

**颜色不能是唯一区分手段。** 每条都要有文字/图标/形状冗余：

| 场景 | ✗ 只靠颜色 | ✓ 冗余表达 |
|---|---|---|
| 必填 | 红色星号 | 文字「必填」 |
| 错误 | 红框 | 文字前缀「错误：」+ 错误说明 |
| 选中 | 高亮色 | 勾选图标 + 文字「已选中」 |
| 状态 | 绿/红点 | 文字状态 + 系统 Symbol |

```typescript
NGFAccessibleFormField({
  label: $r('app.string.field_name'),
  requiredMarker: $r('app.string.required'),   // 文字，不是星号
  isRequired: true,
  errorText: hasError ? $r('app.string.field_error') : undefined,
  errorPrefix: hasError ? $r('app.string.error_prefix') : undefined,
  minTouchTarget: this.tokens.minTouchTarget
}) {
  TextInput({ /* ... */ })
    .attributeModifier(new NGFAccessibilityAttributeModifier(
      buildFormFieldSemantics({ /* ... */ })
    ))
}
```

### 4.6 手势与操作时间（§2.2 / §2.3）

- 任何手势**不得超过 2 指**（`isGestureFingerCountAllowed(n)` 可直接断言）
- 禁止倒计时自动跳转、自动关闭；必须等用户操作完成（§2.3）
- 超时类交互改为**显式确认**

### 4.7 浮窗关闭键（§2.4）

> ⚠️ **先查清楚内置关闭键是否真的够大。** ArkUI/HDS 的 `showClose: true` 位置合规（右上），
> 但设备实测尺寸只有 **40×40 vp**，**低于 §2.4 的 44×44**。
> 适老版应关掉内置键，改用 `NGFAccessibleDialogCloseButton` 自己给一个 ≥44 的。
> 另注意 `SheetOptions.showClose` 的 SDK 默认是 **true**，若被显式改成 `false`，
> 浮窗会**完全没有关闭键** —— 只能拖拽关闭，对老年用户尤其不友好。


```typescript
import { NGFDialogClosePosition, isDialogClosePositionAllowed, resolveDialogCloseAlignment } from 'ngf_framework';

// 位置只允许三种
NGFAccessibleDialogCloseButton({
  closePosition: NGFDialogClosePosition.TOP_RIGHT,   // TOP_LEFT / TOP_RIGHT / BOTTOM_CENTER
  label: $r('app.string.dialog_close'),
  minTouchTarget: this.tokens.dialogCloseTarget      // 44
})
```

组件会在 `aboutToAppear()` 对**非法位置**和**过小点击区**主动告警。

### 4.7b 系统关怀模式接入（HarmonyOS API 26.0.0）⚠️ **最容易被漏掉的一步**（见 PR-008）

**关怀模式 = 长辈模式 = 关爱版 = 大字版**，是同一套系统能力，SDK 里对应 `SeniorMode*` 接口。

**两套 API，先想清楚你的应用属于哪种：**

| 你的应用 | 用哪套 | 要不要声明 metadata |
|---|---|---|
| **没有**应用内开关，纯跟随系统 | `isSeniorModeEnabled()` + `onSeniorModeStateChange()` | **不声明** |
| **有**应用内独立开关 | `getSeniorModeStateForSelf()` + `setSeniorModeStateForSelf()` + `onSeniorModeStateChangeForSelf()` | **必须声明** `independent_control` |

**声明写法**（`module.json5` 的 **module 级** `metadata`）：

```json5
{
  "module": {
    "metadata": [
      { "name": "senior_mode", "value": "independent_control" }
    ]
  }
}
```

**不声明的后果**：应用**不会**出现在
「设置 > 关怀和无障碍 > 关怀模式 > 应用管理」里 ——
用户只能进应用内翻开关，正是"每个 App 都要单独找设置"的老问题。

> ⚠️ **注意**：这 4 个 `ForSelf` 接口都是 **@since 26.0.0**。
> 而 SDK 的 JSDoc **没有提 metadata 要求** —— 只在官方指南里写了，
> 所以**光看 SDK 声明会漏掉这一步**。

**验证三步**（缺一不可）：
1. 打包产物解压后 `module.json` 含该 metadata；
2. 设备 `hdc shell bm dump -n <bundleName>` 能读到；
3. 开关往返时 hilog 出现 `SetSeniorModeStateForApp enabled, state: 0/1` 与
   `seniorModeStateForApp from db: {"<bundle>_0":true/false}`。

**策略合成**：系统信号与应用内信号应当 **OR** ——
`seniorModeEnabled || appSeniorModeEnabled`，任一为真即进入适老档。

### 4.7c ArkUI 官方「适老化」能力（**与关怀模式是两个独立信号**，见 PR-011）

⚠️ **最容易混淆的一点**：HarmonyOS 里有**两套独立的适老信号**，
触发条件和能拿到的能力都不同，**不要以为配了一个就全有了**。

| | **关怀模式（长辈模式）** | **ArkUI 适老化（系统字体缩放）** |
|---|---|---|
| 信号源 | `accessibility.isSeniorModeEnabled()` | `Configuration.fontSizeScale > 1` |
| 触发 | 用户在系统设置开关怀模式 | 用户把**系统字体**调大 |
| 拿到什么 | 你自己实现的适老呈现层 | **系统自动的**长按放大弹窗 |
| 前提 | `module.json5` 声明 metadata | `app.json5` 配 `configuration` |

#### ① 让应用跟随系统字体：`configuration` 标签

`app.json5`（**app 级，不是 module 级**）：

```json5
{
  "app": {
    "configuration": "$profile:configuration"
  }
}
```

`AppScope/resources/base/profile/configuration.json`：

```json
{
  "configuration": {
    "fontSizeScale": "followSystem",
    "fontSizeMaxScale": "2"
  }
}
```

| 键 | 取值 | 缺省 |
|---|---|---|
| `fontSizeScale` | `followSystem` / `nonFollowSystem` | **`nonFollowSystem`** |
| `fontSizeMaxScale` | `1` / `1.15` / `1.3` / `1.45` / `1.75` / `2` / `3.2` | `3.2` |

> ⚠️ **缺省是「不跟随系统」** —— 不配这个标签，应用字体**完全不受**系统字体设置影响。

**怎么选 `fontSizeMaxScale`**：附件2 §1.1 要求「主要功能/界面最大字体不小于 30 dp/pt」。
若最小正文字号是 16 vp，则所需倍率 = 30 / 16 = 1.875 → 枚举里不小于它的最小值是 **"2"**
（选 "1.75" 只能到 28 vp，**不满足规范**）。

**运行时 API**（SDK 已确认）：

| API | @since | 用途 |
|---|---|---|
| `Configuration.fontSizeScale` | **12** | 读当前缩放 |
| `ApplicationContext.setFontSizeScale(n)` | **13** | 应用内覆盖 |
| `ApplicationContext.onSystemConfigurationUpdated(cb)` | **24** | 订阅变化 |

SDK JSDoc 原文：当 `configuration` 配为 `followSystem` 且此处设置的值超过
`fontSizeMaxScale` 时，**以 `fontSizeMaxScale` 为准**。

#### ①b ⚠️ 系统**不会**自动放大第三方应用的界面

**这是最容易误解的一点。** 开了系统关怀模式后，第三方应用**不会**被系统自动放大 ——
关怀模式给应用的是一个**信号**，**放大必须由应用自己实现**。

| 系统提供 | 谁来实现放大 |
|---|---|
| 关怀模式**信号**（`isSeniorModeEnabled`） | **应用自己**（NGF 已实现） |
| 长按放大**弹窗** | 系统，但触发条件是**系统字体 > 1 倍**（**另一个设置**，不是关怀模式） |

所以「开了关怀模式 → 系统自动把应用放大」这个预期**不成立**。
验证应用是否真的响应了关怀模式，**必须量字号**，不能靠感觉。

#### ①c ⚠️ 应用内开关**不要和系统设置打架**

**设计原则：系统信号优先，应用内开关让位。**
系统关怀模式是用户对**整个设备**的选择，应用不应与之争抢。

**三处必查的冲突**（2026-10-06 在 NGF 实际审计出来的）：

| # | 冲突 | 现象 |
|---|---|---|
| 1 | 开关 `isOn` 绑生效状态，但 `.enabled()` 只判断「已解析」 | 系统开启时把开关拨到关 → 界面仍适老 → **开关立刻弹回开**，用户以为开关坏了 |
| 2 | 切换处理函数在系统接管时仍写入 | 与系统做**无意义争抢**（官方：「重新开启系统关怀模式时，原先被关闭的App会同步恢复开启」） |
| 3 | 状态文字在「系统开 + 应用开关也开」时显示「已开启」 | 掩盖**真正控制方是系统**（开关已锁定）这一事实 |

**正确写法**：

```ts
@State private appSeniorMode: boolean = ...;     // 应用内开关
@State private systemSeniorMode: boolean = ...;  // 系统信号（必须分开！）

Toggle({ type: ToggleType.Switch, isOn: this.isElderlyUi })   // 显示生效状态
  .enabled(this.seniorModeResolved && !this.systemSeniorMode)  // 系统接管时禁用

private handleToggleSeniorMode(isOn: boolean): void {
  if (this.systemSeniorMode) {
    return;   // 系统接管时不写入，避免无意义争抢
  }
  ngfAccessibilityFacade.setAppSeniorMode(isOn)...
}

// 状态文字：系统接管时**一律**显示「由系统控制」，无论应用内开关如何
```

**状态文字必须显示「生效状态 + 来源」**（PR-013）：

| 情况 | 显示 |
|---|---|
| 应用内开关开 | 已开启 |
| **仅系统关怀模式开** | **已生效 · 由系统关怀模式开启** |
| 都没开 | 已关闭 |

> 只显示应用内开关会出现**「显示已关闭、界面却是大字」的自相矛盾**，
> 用户会以为功能坏了。

#### ② 长按放大弹窗（系统自动提供，不需要写代码）

> ## ⛔ **NGF 已评估并决定不采用此功能 —— 不要再为它投入时间**
>
> **结论（2026-10-06，用户决策）**：**支持面太窄，不实用。**
>
> 三条同时成立的苛刻条件使它性价比极低：
> 1. **触发条件是「系统字体 > 1 倍」**，**不是关怀模式** ——
>    应用**自己**把字放大（`a11yScale.font()`）**不算数**，
>    因为该机制读的是 `fontSizeScale` 这个**配置值**，不是「界面看起来多大」。
> 2. **组件白名单很窄**（见下），本项目底栏是自定义 `@Builder`，**本来就不在白名单里**。
> 3. 要满足条件 1 只能让用户**再去系统设置里调字体**，
>    而应用**不能**用 `setFontSizeScale()` 去"制造"它
>    （会**切断** `followSystem` 与订阅能力，见 ①）。
>
> **NGF 的取舍**：走 **① 的 `followSystem` + 自己的适老呈现层** ——
> 关怀模式一开即生效，不依赖用户额外调字体。
>
> **本节以下内容仅作为「若将来确有必要」的参考**，不要当成待办。

**机制**：系统字体 **> 1 倍**时，长按组件 → 弹出放大弹窗，组件在屏幕中央放大显示。
字体恢复 1 倍后自动复原。

**支持「长按触发」的组件**（白名单）：
`SideBarContainer`、**底部页签 tabBar**、`Navigation`、`NavDestination`、`Tabs`

**系统字体放大即自动放大的组件**：
`PickerDialog` `Button` `Menu` `Stepper` `bindSheet` `TextInput` `TextArea`
`Search` `SelectionMenu` `Chip` `Dialog` `Slider` `Progress` `Badge`

**限制**：
- 系统字体 > 2 倍时，弹窗内容（icon + 文字）放大倍数**固定为 2 倍**
- **底部页签的弹窗只适用于 `BottomTabBarStyle`**

> 🔴 **这条对本项目特别重要（PR-012）**：用 `@Builder` 自定义 `tabBar` 的页面
> **拿不到**官方的适老化弹窗。若底栏点击区不满足 §2.1，
> **官方解法是改用 `BottomTabBarStyle`**，而不是自己去改宽度
> （本项目曾用 `.barWidth()` 强行拉宽，导致底栏错位，见 PR-010）。

#### ②b 🧪 怎么验证「长按放大弹窗」真的生效（自查步骤）

**最关键的一点：触发条件是「系统字体 > 1 倍」，不是关怀模式。**
只开关怀模式**不会**触发长按放大 —— 这是最容易白测半天的地方。

> ⚠️ **「应用自己把字放大」不算数。** 触发条件读的是 **`fontSizeScale`**
> （系统/应用的字体缩放配置），不是「界面看起来多大」。
> 关怀模式**不会**改 `fontSizeScale`（实测仍为 1），
> 所以靠 `a11yScale.font()` 自己放大的应用，**长按放大永远不会触发**。
> 我们的自放大行为**不是「不行」，而是「不算数」** —— 它不阻止任何东西，只是不满足那个条件。

**完整生效条件（三条缺一不可）：**

| # | 条件 | 本项目 |
|---|---|---|
| 1 | `app.json5` 配 `configuration` → `$profile:xxx`，且 profile 里 `fontSizeScale: "followSystem"` | ✅ 已配 |
| 2 | **系统字体 > 1 倍**（系统设置里调大字体，不是关怀模式） | ❌ 当前 1× |
| 3 | 组件在适老化白名单里（见下表） | ⚠️ 底栏不在 |

**⚠️ 不要用 `setFontSizeScale()` 去「制造」条件 2** —— 官方原文：

> 开发者可以使用 `setFontSizeScale` 设置应用字体大小。
> **设置后，应用字体将不跟随系统变化，不再支持订阅系统字体大小变化。**

即它会**切断** `followSystem` 与订阅能力，代价大于收益。

**两种效果，测法不同：**

| 效果 | 触发条件 | 怎么测 |
|---|---|---|
| **自动放大** | 系统字体 > 1 倍 | 直接看：`Button` `Menu` `Dialog` `bindSheet` `TextInput` `TextArea` `Search` `Slider` `Progress` `Chip` `Stepper` `PickerDialog` `SelectionMenu` `Badge` 会自己变大 |
| **长按放大弹窗** | 系统字体 > 1 倍 **且长按** | 长按下列组件：`SideBarContainer`、底部页签 `tabBar`、`Navigation`、`NavDestination`、`Tabs` |

**步骤：**

1. 系统**设置** → 显示和亮度 → **字体和显示大小**（或「字体大小」）→ 调大（如 1.75×）
2. **回到应用**（不要杀进程）
3. 确认应用读到了新值（两种方式任选）：
   - **应用内**：NGF 设置页有「**系统字体缩放**」读数行，
     显示 `1.75 × · 长按放大可触发` 即就绪
   - **命令行**：
     ```powershell
     hdc -t <target> shell "hilog -x | grep '字体缩放' | tail -n 3"
     ```
     应出现 `系统字体缩放=1.75（>1，适老化长按放大弹窗应可触发）`
4. **长按**页面标题栏 / 导航区（`HdsNavigation` / `HdsNavDestination` 包着 `Navigation` / `NavDestination`）
5. 应弹出放大弹窗，组件在屏幕中央放大显示；松手关闭

**⚠️ 已知限制（本项目）**：

| 位置 | 会弹窗？ |
|---|---|
| **底栏页签** | ❌ **不会** —— 本项目底栏是自定义 `@Builder` `tabBar`，而官方弹窗**只对 `BottomTabBarStyle` 生效** |
| 页面标题栏 / 导航区 | ✅ 应该会（`HdsNavigation` / `HdsNavDestination`） |

**其他限制**：
- 系统字体 **> 2 倍**时，弹窗内容（icon + 文字）放大倍数**固定为 2 倍**
- `app.json5` 必须配 `configuration` 且 `fontSizeScale: followSystem`（缺省是 `nonFollowSystem`，**不配就永远不触发**）

#### ③ NGF 已经把两个信号包装好了 —— **页面只需一行**

> 🔴 **写适老页面时不要自己判断 `policy.density`，也不要自己读 `fontSizeScale`。**
> NGF 已把「关怀模式 + 系统字体缩放」合成好，直接用下面的 API。

```ts
// 页面/组件里唯一需要写的初始化
@State private a11yScale: NGFA11yTextScale = resolveA11yTextScaleForCurrent();

// 订阅变化（必须与 detach 成对）
//
// ⚠️ 门面在构造函数里注册的监听**可能失败**（UIAbilityContext 尚未就绪），
//    必须在读取路径上**惰性补订阅**（PR-014）。
//    NGF 的 AccessibilityFacade 已按 ensureUserPolicyRestored / ensureSystemListeners 实现；
//    自己写门面时照抄这个模式。
private a11yBinding: NGFAccessibilityLifecycleBinding | null = null;

aboutToAppear(): void {
  if (this.a11yBinding === null) {
    const listener: NGFAccessibilityBindingListener = {
      onInclusiveDesignChanged: (_resolved: NGFInclusiveDesignResolved): void => {
        // 注意：重新解析要用 ForCurrent 版本，不要用 resolved.policy
        this.a11yScale = resolveA11yTextScaleForCurrent();
      }
    };
    this.a11yBinding = new NGFAccessibilityLifecycleBinding(listener);
    this.a11yBinding.attach();
  }
}

aboutToDisappear(): void {
  const binding: NGFAccessibilityLifecycleBinding | null = this.a11yBinding;
  if (binding !== null) { binding.detach(); this.a11yBinding = null; }
}
```

**然后用缩放器下发所有数值**（不要写 `isElderly ? A : B`）：

| 场景 | 写法 |
|---|---|
| 字号 | `.fontSize(this.a11yScale.font(16))` |
| 行高 | `.lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))` |
| 已有显式行高 | `.lineHeight(this.a11yScale.explicitLineHeight(this.a11yScale.font(16), 20))` |
| 点击区 | `.height(a11yTouchTarget(this.a11yScale.isElderly, 40))` |
| 段落间距 | `Column({ space: this.a11yScale.paragraphSpacing(12, 18) })` |
| 组内间距 | `Column({ space: this.a11yScale.groupSpacing(8) })` |

**叶子组件**（被多次复用的子组件）用**原始类型 `@Prop`**，**不要传类实例**：

```ts
@Prop isElderly: boolean = false;   // 布局是否适老
@Prop boostFont: boolean = true;    // 是否由我们抬字号（= 关怀模式）
// ...
.fontSize(a11yFontFor(this.isElderly, 14, this.boostFont))
.height(a11yTouchTarget(this.isElderly, 40))
```

> ⚠️ **`isElderly` 与 `boostFont` 是两个不同的概念，不要合并成一个布尔**：
> - `isElderly`（= 关怀模式 **或** 字体缩放 > 1）→ 决定**布局**（行距、点击区、间距）
> - `boostFont`（= **仅**关怀模式）→ 决定**是否由我们抬字号**
>
> 原因：ArkUI 的 `fontSize(number)` 单位是 **fp**，系统字体缩放时**已经放大过一次**；
> 我们再抬一次就是**双重放大**，会把版式撑破。
> 但行距/点击区是 **vp**，**不会**跟随系统缩放，所以仍要按 `isElderly` 补上。

**`NGFA11yTextScale` 上可用的成员**：

| 成员 | 含义 |
|---|---|
| `isElderly` | 是否适老布局（任一信号为真） |
| `boostFont` | 是否由我们抬字号（仅关怀模式） |
| `systemFontScale` | 当前系统字体缩放倍率（1 = 未放大） |
| `fromCareMode` / `fromFontScale` | 分别是哪个信号触发的（便于诊断） |
| `font(n)` / `lineHeight(f)` / `explicitLineHeight(f, normal)` | 字号与行高 |
| `paragraphSpacing(normal, bodyFontSize)` / `groupSpacing(n)` | 段落间距 / 组内间距 |

**门面侧的诊断 API**：`ngfAccessibilityFacade.getA11ySignalSource()`、
`getSystemFontScale()`、`addFontScaleListener()` / `removeFontScaleListener()`。

#### ③b 基础组件一行接入：`NGFA11yModifierSet`（**推荐写法**）

**问题**：每个组件都要记「要改哪几个属性、适老档改成多少」，容易漏。
**方案**：NGF 提供 `AttributeModifier` 修饰器 —— **一个组件一行**，属性由框架决定。

> **为什么用 `AttributeModifier` 而不是 `@Extend` / `@Styles`**：
> `@Extend(Text)` 和 `@Styles` **不能跨文件导入**（ArkTS 限制），
> 只能在声明文件里用，**无法成为可复用的框架能力**。
> `AttributeModifier<T>`（**@since 11/12**）是**类**，可以正常导出导入 ✓

**用法（唯一推荐写法）**：

```ts
import { NGFA11yModifierSet, NGFA11yTextScale, resolveA11yTextScaleForCurrent } from 'ngf_framework';

// ① 缩放器：用于「间距」这类没有修饰器的场景
@State private a11yScale: NGFA11yTextScale = resolveA11yTextScaleForCurrent();

// ② 修饰器集：必须用 @State 字段持有（原因见下方红框）
@State private a11yMods: NGFA11yModifierSet =
  new NGFA11yModifierSet(resolveA11yTextScaleForCurrent());

// ③ 策略变化时**新建实例**替换（只改内部字段不会重新下发）
private attachA11yBinding(): void {
  if (this.a11yBinding !== null) { return; }
  const listener: NGFAccessibilityBindingListener = {
    onInclusiveDesignChanged: (_r: NGFInclusiveDesignResolved): void => {
      this.a11yScale = resolveA11yTextScaleForCurrent();
      this.a11yMods = new NGFA11yModifierSet(this.a11yScale);
    }
  };
  this.a11yBinding = new NGFAccessibilityLifecycleBinding(listener);
  this.a11yBinding.attach();
}

build() {
  Column({ space: this.a11yScale.groupSpacing(8) }) {
    Text('标题').attributeModifier(this.a11yMods.text(16))
    Span('强调').attributeModifier(this.a11yMods.span(14))
    SymbolGlyph($r('sys.symbol.house')).attributeModifier(this.a11yMods.icon(24))
    Button('确定').attributeModifier(this.a11yMods.button(16, 40))
    Toggle({ type: ToggleType.Switch }).attributeModifier(this.a11yMods.toggle(0))
    Image($r('app.media.x')).attributeModifier(this.a11yMods.image(32))
    TextInput({ placeholder: '输入' }).attributeModifier(this.a11yMods.textInput(16, 40))
  }
}
```

> ✅ **真机已验证可用**（2026-10-06，MatePad Mini / API 26）：
> `Text('语言设置').attributeModifier(this.a11yMods.text(18))` 实测渲染高度
> **56px = 23.4vp = 18 × 1.3**，`fontSize` 与 `lineHeight` 都正确下发 ✓
> （同次测量页面文本 21 条，渲染正常）
>
> 🔴 **硬约束 1：修饰器集必须是 `@State` 字段，禁止在 `build()` 路径里构造。**
>
> **错误写法（会炸页面）**：
> ```ts
> // ✗ 绝不要这样写 —— 会让整页渲染异常
> private get a11y(): NGFA11yModifierSet { return new NGFA11yModifierSet(this.a11yScale); }
> ```
> 2026-10-06 实测：用 getter 形式后**设置页整页渲染异常** ——
> 文本从 **21 条掉到 7 条**、大片空白；移除该 getter 后**立即恢复**。
> **在 build 路径里现场构造对象会破坏渲染。**
>
> > 📌 这个坑我踩过两次：先用 getter 炸了页面，又**基于坏页面**误判
> > 「`AttributeModifier` 不生效」。改用 `@State` 字段重做实验后确认**可用**。
> > **教训：测量前先确认页面本身是正常的**（看文本总数、看截图），
> > 否则量到的是坏页面的数据。
>
> 🔴 **硬约束 2：实例必须被**替换**，只改内部字段不会重新下发。**
>
> `AttributeModifier` 是**命令式**下发属性的：
> - 实例**被替换** → ArkUI 重新执行 `applyNormalAttribute` ✓
> - 实例不变、只改内部字段 → **不会重新下发** ✗

**备选写法（不想用修饰器时）**：取值交给框架，下发用普通属性 ——
**但要连写两行，且容易漏掉其中一个**，所以不如修饰器：

```ts
Text('标题')
  .fontSize(this.a11yMods.text(16).fontSize)
  .lineHeight(this.a11yMods.text(16).lineHeight)
```

**修饰器一览**（`NGFA11yModifierSet` 的方法）：

| 方法 | 目标组件 | 适老档自动做的事 |
|---|---|---|
| `text(n)` | `Text` | 字号抬到 §1.1 的 18；行高按 §1.2 的 1.3 倍 |
| `textWithLineHeight(n, lh)` | `Text`（原有显式行高） | 同上，普通档保留原行高 |
| `span(n)` | `Span` | 字号（行高由外层 Text 控制） |
| `icon(n)` | `SymbolGlyph` | 尺寸 ×1.3 |
| `button(n, target)` | `Button` | 字号 + 点击区 ≥60（§2.1） |
| `toggle(target)` | `Toggle` | 点击区 ≥60 |
| `image(n)` | `Image` | 宽高 ×1.3 |
| `textInput(n, h)` | `TextInput` | 字号 + 高度 |

**⚠️ 间距没有修饰器，必须留在构造处**：

`List({ space })` / `Column({ space })` / `Row({ space })` 里的 `space` 是
**构造函数参数**，`ListAttribute` / `FlexAttribute` 上**没有** `space()`（实测编译报错）。
所以间距用缩放器直接算：

```ts
Column({ space: this.a11yScale.groupSpacing(8) })            // 组内间距
Column({ space: this.a11yScale.paragraphSpacing(12, 18) })   // 段落间距（§1.2）
List({ space: this.a11yScale.groupSpacing(8) })
```

#### ④ 无障碍属性（ArkUI 通用属性）

| 属性 | 作用 |
|---|---|
| `accessibilityText` | 无障碍朗读文本（图标按钮必配） |
| `accessibilityDescription` | 补充说明 |
| `accessibilityLevel` | 是否可被无障碍服务识别（`'yes'`/`'no'`/`'no-hide-descendants'`） |
| `accessibilityGroup` | 分组：组件与其子组件作为**一整个**可选组件 |
| `accessibilityNextFocusId` | **自定义焦点移动顺序**（浏览顺序控制） |

一个辅助工具具备无障碍能力的**三个前提**：
1. **可被识别** —— 用 `accessibilityLevel` 控制；
2. **提供功能与操作信息** —— 用 `accessibilityText` / `accessibilityDescription`；
3. 组件状态可被正确读出。

> **`accessibilityGroup` 的合并规则**：启用分组后，若组件**没有**通用文本属性且
> **未设**无障碍文本，则默认拼接子组件的通用文本属性作为合并文本；
> 此时**不使用**子组件的无障碍文本。

### 4.8 长辈版命名（§3.1）

**显示走 i18n，匹配走规范原词 —— 两件事必须分开。**

```typescript
import { getElderlyModeDisplayName, getElderlyModeAliasDisplayNames, isElderlyModeSearchHit } from 'ngf_framework';

// 显示：走 i18n（zh_CN 下即「长辈版」）
Text(getElderlyModeDisplayName())
// 搜索匹配：用规范原词，切英文后搜「长辈版」仍要能命中
if (isElderlyModeSearchHit(userInput)) { /* 命中适老模式 */ }
```

**为什么不能把匹配建立在"当前语言的显示名"上**：把系统语言切成英文后，
用户搜「长辈版」就再也搜不到了 —— 而规范要求的恰恰是这些词本身能作为搜索关键字。

### 4.9 辅助技术不得阻断（§4.1）

- **不要**调用 `setTextHighContrast()` 覆盖系统高对比 —— 不调用即自动跟随，调用会覆盖用户的系统设置
- 不要禁用系统读屏、放大镜等辅助功能
- 无障碍语义按 `skill-arkui-knowledge.md` 与设计文档 §3 处理

### 4.10 广告与诱导按键（§5.1.1 / §5.1.2）

**适老版界面与单独的适老版 APP 中严禁出现广告内容及插件**；全应用不得有诱导下载/诱导付款按键。
这是**产品治理约束**，实现前需与产品确认，不能只靠代码。

---

## 5. 常见错误与正确写法

| ✗ 错误 | ✓ 正确 | 为什么 |
|---|---|---|
| 复制一份 `ElderlyXxxPage.ets` | 同一页面按 tokens 切换呈现 | 复制必然导致功能漂移 |
| 硬编码 `fontSize(18)` | `fontSize(this.tokens.bodyFontSize)` | 硬编码后普通版也跟着变，且无法随系统字体缩放 |
| `$r('app.string.x') + '：' + value` | 先 `resolveResourceString` 再拼接 | `$r()` 返回 `Resource` 对象，直接拼接会渲染成 `[object Object]`（见 PR-C004） |
| 只设 `fontSize` 不管 `lineHeight` | 同时设 `lineHeight(tokens.bodyLineHeight)` | §1.2 要求行距 ≥1.3 倍 |
| 用红色表示错误 | 文字前缀 + 颜色 | §1.4 颜色不能是唯一手段 |
| 用星号 `*` 表示必填 | 文字「必填」 | 同上 |
| 半透明背景直接算对比度 | 先 `compositeOver` 合成 | 对比度公式只对不透明颜色成立 |
| 把 `accessibilityGroup(true)` 套在含 `TextInput` 的容器上 | 不分组，语义绑到输入控件 | 分组会让输入框**失去独立焦点、无法编辑** |
| 搜索匹配用本地化显示名 | 用 `isElderlyModeSearchHit()`（规范原词） | 切语言后搜不到 |
| 在适老版里"简化"掉功能 | 只简化视觉密度与步数 | 功能一致性是本技能的硬要求 |

---

## 6. 验收清单

改造完成后**逐项确认**：

**指标类**
- [ ] 适老版主要文字 ≥ **18 dp/pt**；主要功能/界面最大字体 ≥ **30 dp/pt**
- [ ] 应用已配置 `fontSizeScale: followSystem` + `fontSizeMaxScale: "2"`，且**打包后产物里确认存在**
- [ ] 行距 ≥ **1.3 倍**；段距 ≥ 行距 × **1.3**
- [ ] 正文对比度 ≥ **4.5:1**；字号 >18 时 ≥ **3:1**；半透明表面已对极端背景各验一次
- [ ] **普通组件没有使用 `.systemMaterial(...)`**（用玻璃模糊材质代替）；HDS 底栏除外
- [ ] 标题栏底色是深色或透明（不是浅色）—— `NGFHdsTitleBarOptionsFactory` 硬编码白字，浅底会不可读（见 PR-C005）
- [ ] **关怀模式**：有独立开关的应用已在 `module.json5` 声明 `senior_mode: independent_control`，
      且 `bm dump` 能在设备上读到
- [ ] **跟随系统字体**：`app.json5` 配了 `configuration` 指向 profile，
      且 profile 里 `fontSizeScale: "followSystem"`、`fontSizeMaxScale` ≥ 1.875
      （**不配 = 不跟随系统，长按放大弹窗永远不会出现**）
- [ ] **底栏点击区**：若用 `@Builder` 自定义 `tabBar`，注意**拿不到官方适老化弹窗**；
      不满足 §2.1 时应改用 `BottomTabBarStyle`，**不要用 `.barWidth()` 硬拉**（见 PR-010）
- [ ] **基础组件**：`Text`/`Button`/`Toggle`/`Image`/`SymbolGlyph`/`TextInput` 用了
      `.attributeModifier(this.a11yMods.xxx(...))`（**`@State` 字段持有，不是 getter**）；
      容器间距用 `groupSpacing()` / `paragraphSpacing()`
- [ ] **无障碍属性**：图标按钮配了 `accessibilityText`；
      纯装饰元素用 `accessibilityLevel('no')` 排除；成组信息用 `accessibilityGroup(true)`
- [ ] 适老版主要组件点击区 ≥ **60×60**；其他页面 ≥ **44×44**；独立适老首页 ≥ **48×48**
- [ ] 无 ≥3 指手势；无倒计时自动跳转
- [ ] 浮窗关闭键 ≥ **44×44** 且位置在左上/右上/中央底部
- [ ] 功能名用「长辈版」，搜索可命中「亲情版」「关爱版」「关怀版」

**一致性类**
- [ ] 适老版**没有**复制页面文件（除 §3.1 登记的破例）
- [ ] 普通版每个功能入口在适老版仍可达（入口清单逐条核对）
- [ ] `uitest dumpLayout` 两版可点击节点差分已做，差异逐条有解释

**治理类**
- [ ] 适老版无广告内容及插件（§5.1.1）
- [ ] 无诱导下载/付款按键（§5.1.2）
- [ ] 未调用 `setTextHighContrast()` 覆盖系统高对比
- [ ] 所有面向用户的文案走 i18n（见 `skill-i18n.md`）

---

## 7. 关键文件路径速查

| 文件 | 说明 |
|------|------|
| `ngf_framework/src/main/ets/deviceAwareness/contracts/NGFInclusiveDesignPolicy.ets` | 策略模型 + `NGF_INCLUSIVE_DESIGN_METRICS`（13 条规范数值）+ `NGF_APP_FONT_SIZE_MAX_SCALE` |
| `ngf_framework/src/main/ets/deviceAwareness/facades/AccessibilityFacade.ets` | `ngfAccessibilityFacade`：策略读取、适老模式、播报、订阅 |
| `ngf_framework/src/main/ets/uiShell/components/NGFInclusiveDesignTokens.ets` | `resolveInclusiveDesignTokens()` + §2.2/§2.4 约束 |
| `ngf_framework/src/main/ets/uiShell/components/NGFAccessible*.ets` | 四个可复用组件（Button / ListItem / FormField / DialogCloseButton） |
| `ngf_framework/src/main/ets/uiShell/utils/NGFContrastChecker.ets` | 对比度核验（含半透明合成） |
| `ngf_framework/src/main/ets/deviceAwareness/contracts/NGFElderlyModeNaming.ets` | 长辈版命名与搜索匹配 |
| `ngf_framework/src/main/ets/uiShell/utils/NGFAccessibilityLifecycleBinding.ets` | 订阅生命周期绑定（on/off 配对） |
| `AppScope/app.json5` + `AppScope/resources/base/profile/configuration.json` | 字体跟随系统 |
| `docs/NGF_ACCESSIBILITY_ELDERLY_DESIGN.md` | 完整证据链（§3 API 证据 / §4 标准数值 / §7 验收矩阵） |
| `ngf_framework/src/main/ets/uiShell/utils/NGFA11yTextScale.ets` | **适老缩放器**：`resolveA11yTextScaleForCurrent()`、`a11yTouchTarget()`、`a11yFontFor()`、行高/段距/组距 |
| `ngf_framework/src/main/ets/uiShell/utils/NGFA11yAttributeModifiers.ets` | **基础组件修饰器框架**：`NGFA11yModifierSet` + 8 个 `AttributeModifier` |
| `.agent-rules/project-rules.md` | 项目规则 **PR-006 ~ PR-015**（材质、决策单一来源、关怀模式 metadata、设备实测、barWidth 禁用、双信号、BottomTabBarStyle、状态显示、惰性补订阅、开关让位系统） |
| `entry/src/main/ets/pages/ngf/NGFAccessibilityShowcasePage.ets` | 参考实现（**已在真机 MatePad Mini 验证**） |
