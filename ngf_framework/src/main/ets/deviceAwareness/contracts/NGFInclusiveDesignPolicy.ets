/**
 * NGF 包容性设计策略契约（P3）
 *
 * 这一层把"无障碍/适老化"从一次性页面写法提升为可切换、可持久化、可断言的策略档位。
 *
 * ## 数值来源分级（务必区分，不要把 NGF 基线写成标准原文）
 *
 * **A. 官方规范原文数值**（2026-10-05 由 Agent 直接从工信部官网页面逐字抓取核验）
 *   来源：工业和信息化部办公厅《关于进一步抓好互联网应用适老化及无障碍改造专项行动实施工作的通知》
 *        工信厅信管函〔2021〕67号，成文 2021-04-06，附件2《移动互联网应用（APP）适老化通用设计规范》
 *        https://www.miit.gov.cn/jgsj/xgj/wjfb/art/2021/art_81e8b738d6b24ad6a04f7ecb3f4e0702.html
 *   - §1.1 最大字体不小于 30 dp/pt；适老版界面及单独适老版 APP 主要文字信息不小于 18 dp/pt
 *   - §1.2 段落内文字行距至少为 1.3 倍，且段落间距至少比行距大 1.3 倍
 *   - §1.3 对比度至少 4.5:1（字号大于 18 dp/pt 时至少 3:1）
 *   - §2.1 适老版界面主要组件点击焦点区域不小于 60×60 dp/pt；
 *          其他页面不小于 44×44 dp/pt；单独适老版 APP 首页不小于 48×48 dp/pt
 *   - §2.4 浮窗关闭按钮最小点击响应区域不小于 44×44 dp/pt，且只可在左上、右上、中央底部
 *
 * **B. NGF 工程基线**（本框架自定，可严于标准，但不得声称为标准原文）
 *   - 正文最小字号 16 vp
 *   - 常规触控目标建议 48 vp（严于标准 44 dp/pt 下限）
 *   - 非文本关键边界对比度 3:1（对齐 WCAG 2.2 AA 1.4.11，非中国标准条款）
 *
 * **C. 单位映射假设**：ArkUI 的 vp 与规范的 dp/pt 同属密度无关像素，
 *   NGF 按 1 vp = 1 dp/pt 做工程映射。这是工程假设，不是规范原文表述。
 *
 * ## 未取得原文的部分
 * GB/T 37668-2019 仍为现行，但修订计划 20252537-T-469 正在批准并将全部代替它；
 * 其条款原文本次未逐字获取（全文公开但阅读器需浏览器 JS/WASM），因此本文件不引用其条款数值。
 */

/** 文本缩放档位 */
export enum NGFTextScalePolicy {
  /** 跟随系统字体缩放，不做应用内额外放大 */
  SYSTEM = 'system',
  /** 应用内标准档：正文不低于 NGF 基线最小字号 */
  STANDARD = 'standard',
  /** 应用内增强/适老档：正文与关键操作字号一并提高，并按适老版界面数值要求 */
  ENHANCED = 'enhanced'
}

/** 触控目标档位 */
export enum NGFTouchTargetPolicy {
  STANDARD = 'standard',
  LARGE = 'large'
}

/**
 * 对比度档位。
 *
 * ## 与「系统文本高对比」的关系（重要，不要混淆）
 *
 * 系统另有一套**文本渲染高对比**开关（`@ohos.graphics.text.setTextHighContrast`，**@since 20**），
 * 取值 `TEXT_FOLLOW_SYSTEM_HIGH_CONTRAST` / `TEXT_APP_DISABLE_HIGH_CONTRAST` / `TEXT_APP_ENABLE_HIGH_CONTRAST`。
 *
 * - 系统那套是**进程级、只作用于系统文本组件**，且**没有 getter**（应用读不到当前状态）；
 * - 本枚举是 **NGF 应用内**的对比度策略，作用于 NGF 自己的组件与颜色令牌；
 * - **两者是互补关系，不是替代关系。**
 *
 * **NGF 的硬性约定：不要调用 `setTextHighContrast`。**
 * 不调用即自动跟随系统设置；一旦调用 `TEXT_APP_DISABLE_HIGH_CONTRAST`，
 * 就会覆盖用户在系统里打开的高对比 —— 那是可访问性倒退。
 * （已核验：NGF 全仓库从未调用该 API。）
 */
export enum NGFContrastPolicy {
  STANDARD = 'standard',
  ENHANCED = 'enhanced'
}

/**
 * 动效档位。
 * 注意：系统只提供"是否开启减少动效"的布尔信号，
 * 三档拆分是 NGF 的应用内降级策略，不是系统能力，也不是规范条款。
 */
export enum NGFMotionPolicy {
  FULL = 'full',
  REDUCED = 'reduced',
  NONE = 'none'
}

/** 密度档位（适老模式使用更宽松的间距与更大的点击区） */
export enum NGFDensityPolicy {
  STANDARD = 'standard',
  ELDERLY = 'elderly'
}

/**
 * UI 上下文。
 *
 * 附件2 的数值是**按上下文分档**的，不是按用户档位分档的：
 * 同一个应用里，"适老版界面"与"其他页面"适用不同的点击区下限。
 * 因此这里用上下文而不是策略档位来取具体数值。
 */
export enum NGFUiContext {
  /** 普通页面：主要组件点击区下限 44×44 dp/pt */
  STANDARD_PAGE = 'standard_page',
  /** 内嵌适老版界面：主要组件点击区下限 60×60 dp/pt */
  ELDERLY_PAGE = 'elderly_page',
  /** 单独的适老版 APP 首页：主要组件点击区下限 48×48 dp/pt */
  STANDALONE_ELDERLY_HOME = 'standalone_elderly_home'
}

/** 策略组合 */
export interface NGFInclusiveDesignPolicy {
  textScale: NGFTextScalePolicy;
  touchTarget: NGFTouchTargetPolicy;
  contrast: NGFContrastPolicy;
  motion: NGFMotionPolicy;
  density: NGFDensityPolicy;
}

/** 策略输入：用户显式选择优先，其次由系统信号推导 */
export interface NGFInclusiveDesignPolicyInput {
  /** 用户显式选择；存在时优先于系统推导，不做覆盖 */
  userPolicy?: NGFInclusiveDesignPolicy;
  /** 系统"减少动效"信号 */
  animationReduceEnabled: boolean;
  /** 系统/本应用"适老模式"信号 */
  seniorModeEnabled: boolean;
  /**
   * 系统字体缩放倍率（1 表示未放大）。
   *
   * **这是与"关怀模式"完全独立的第二个适老信号**（见 PR-011）：
   * - 关怀模式：用户在系统设置里开关怀模式；
   * - 字体缩放：用户把**系统字体**调大（`app.json5` 配 `configuration` 后生效）。
   *
   * 两者**互不替代**：只调大字体、没开关怀模式的用户，
   * 同样需要更大的点击区与更宽的行距，否则会出现「字变大了、按钮没变大」。
   */
  systemFontScale: number;
}

/**
 * 适老信号来源：说明**为什么**进入了适老档。
 *
 * 两个信号对字号的处理**不同**，所以必须区分：
 * - `fromFontScale`：系统已按 fp 自动放大了字号，**我们不应再抬一次**（会双重放大）；
 *   但仍需补上 **行距 1.3 倍**与 **60vp 点击区**。
 * - `fromCareMode`：系统不会自动放大，**需要我们把字号抬到 §1.1 的 18 dp**。
 */
export interface NGFA11ySignalSource {
  fromCareMode: boolean;
  fromFontScale: boolean;
  /** 任一为真即进入适老档 */
  isElderly: boolean;
  /** 是否由我们主动抬字号（仅关怀模式需要） */
  boostFont: boolean;
  /** 当前系统字体缩放倍率，1 表示未放大 */
  systemFontScale: number;
}

/**
 * 可量化门槛。
 * 字段名带 `Dp` 的是**规范原文数值**，带 `Vp` 的是 **NGF 自有基线**，
 * 便于在评审和测试中一眼区分来源。
 */
export interface NGFInclusiveDesignMetrics {
  // ---------- A. 规范原文（工信厅信管函〔2021〕67号 附件2） ----------
  /** 其他页面主要组件点击焦点区域下限（dp/pt）—— §2.1 */
  standardPageTouchTargetDp: number;
  /** 适老版界面主要组件点击焦点区域下限（dp/pt）—— §2.1 */
  elderlyPageTouchTargetDp: number;
  /** 单独适老版 APP 首页主要组件点击焦点区域下限（dp/pt）—— §2.1 */
  standaloneElderlyHomeTouchTargetDp: number;
  /** 适老版界面及单独适老版 APP 主要文字下限（dp/pt）—— §1.1 */
  elderlyBodyFontDp: number;
  /** 主要功能及主要界面必须支持的**最大**字体下限（dp/pt）—— §1.1 */
  supportedMaxFontDp: number;
  /** 段落内文字行距下限（倍数）—— §1.2 */
  minLineHeightRatio: number;
  /** 段落间距相对行距的下限倍数 —— §1.2 */
  minParagraphSpacingRatio: number;
  /** 普通文本对比度下限 —— §1.3 */
  minTextContrastRatio: number;
  /** 大文本（字号大于 18 dp/pt）对比度下限 —— §1.3 */
  minLargeTextContrastRatio: number;
  /** 浮窗关闭按钮点击响应区域下限（dp/pt）—— §2.4 */
  dialogCloseTargetDp: number;

  // ---------- B. NGF 工程基线（非规范原文） ----------
  /** NGF 正文最小字号基线（vp） */
  ngfMinBodyFontVp: number;
  /** NGF 建议的常规触控目标（vp），严于标准 44 dp/pt 下限 */
  ngfRecommendedTouchTargetVp: number;
  /** 非文本关键边界对比度基线（对齐 WCAG 2.2 AA 1.4.11，非中国标准条款） */
  minNonTextContrastRatio: number;
}

/**
 * NGF 门槛常量。
 * 规范原文数值与 NGF 基线在同一对象内，但字段命名与注释已明确区分来源。
 */
/**
 * 应用级字体缩放上限，对应 `AppScope/resources/base/profile/configuration.json`
 * 里的 `fontSizeMaxScale`（该键在 SDK schema 中是**枚举字符串**：
 * `"1" / "1.15" / "1.3" / "1.45" / "1.75" / "2" / "3.2"`，本常量对应其中的 **"2"**）。
 *
 * ## 为什么是 2 而不是更小
 *
 * 附件2 §1.1 要求"主要功能/界面最大字体不小于 30 dp/pt"。
 * NGF 的最小正文字号是 16 vp（`ngfMinBodyFontVp`），因此所需最小倍率 = 30 / 16 = **1.875**。
 * 枚举中不小于 1.875 的最小值是 **"2"** —— 选 `"1.75"` 只能到 28 vp，**不满足规范**。
 *
 * 该不变式由单测守住：`supportedMaxFontDp <= ngfMinBodyFontVp * NGF_APP_FONT_SIZE_MAX_SCALE`。
 *
 * ## 证据链
 *
 * - `app.json5` 的 `app.configuration` 必须是 `$profile:xxx` 形式
 *   （schema：`hms/toolchains/modulecheck/app.json`，pattern `^[$]profile:[0-9a-zA-Z_.]+$`）；
 * - 被引用的 `configuration.json` schema 在
 *   `openharmony/toolchains/modulecheck/configuration.json`；
 * - 运行时读取：`Configuration.fontSizeScale`（**@since 12**）；
 *   订阅变化：`ApplicationContext.onSystemConfigurationUpdated({ onFontSizeScaleUpdated })`（**@since 24**）；
 *   应用侧覆盖：`ApplicationContext.setFontSizeScale()`（**@since 13**）。
 */
export const NGF_APP_FONT_SIZE_MAX_SCALE: number = 2;

export const NGF_INCLUSIVE_DESIGN_METRICS: NGFInclusiveDesignMetrics = {
  standardPageTouchTargetDp: 44,
  elderlyPageTouchTargetDp: 60,
  standaloneElderlyHomeTouchTargetDp: 48,
  elderlyBodyFontDp: 18,
  supportedMaxFontDp: 30,
  minLineHeightRatio: 1.3,
  minParagraphSpacingRatio: 1.3,
  minTextContrastRatio: 4.5,
  minLargeTextContrastRatio: 3,
  dialogCloseTargetDp: 44,
  ngfMinBodyFontVp: 16,
  ngfRecommendedTouchTargetVp: 48,
  minNonTextContrastRatio: 3
};

/** 默认（未设置用户策略时）的回落档位 */
export const NGF_INCLUSIVE_DESIGN_POLICY_DEFAULT: NGFInclusiveDesignPolicy = {
  textScale: NGFTextScalePolicy.SYSTEM,
  touchTarget: NGFTouchTargetPolicy.STANDARD,
  contrast: NGFContrastPolicy.STANDARD,
  motion: NGFMotionPolicy.FULL,
  density: NGFDensityPolicy.STANDARD
};

/** 复制一份策略，避免调用方与门面共享同一可变对象引用 */
function clonePolicy(policy: NGFInclusiveDesignPolicy): NGFInclusiveDesignPolicy {
  const copy: NGFInclusiveDesignPolicy = {
    textScale: policy.textScale,
    touchTarget: policy.touchTarget,
    contrast: policy.contrast,
    motion: policy.motion,
    density: policy.density
  };
  return copy;
}

/**
 * 推导有效策略。
 *
 * 规则（与设计文档 §5.2 一致）：
 * 1. 用户显式选择优先，系统信号不得覆盖；
 * 2. 未显式选择时，系统"减少动效"只影响 motion 档位；
 * 3. **任一适老信号为真**（关怀模式 或 系统字体缩放 > 1）时，
 *    提升字号/触控/对比度/密度档位。
 *
 * 适老信号来自系统设置或本应用显式设置，**不基于年龄推断**。
 * 两个信号的合成规则见 `resolveA11ySignalSource()`。
 */
export function resolveInclusiveDesignPolicy(input: NGFInclusiveDesignPolicyInput): NGFInclusiveDesignPolicy {
  const userPolicy: NGFInclusiveDesignPolicy | undefined = input.userPolicy;
  if (userPolicy !== undefined) {
    return clonePolicy(userPolicy);
  }
  const senior: boolean = resolveA11ySignalSource(input).isElderly;
  const resolved: NGFInclusiveDesignPolicy = {
    textScale: senior ? NGFTextScalePolicy.ENHANCED : NGFTextScalePolicy.SYSTEM,
    touchTarget: senior ? NGFTouchTargetPolicy.LARGE : NGFTouchTargetPolicy.STANDARD,
    contrast: senior ? NGFContrastPolicy.ENHANCED : NGFContrastPolicy.STANDARD,
    motion: input.animationReduceEnabled ? NGFMotionPolicy.REDUCED : NGFMotionPolicy.FULL,
    density: senior ? NGFDensityPolicy.ELDERLY : NGFDensityPolicy.STANDARD
  };
  return resolved;
}

/**
 * 归一化适老信号：把"关怀模式"与"系统字体缩放"两个**独立**信号合成一个判定。
 *
 * ## 为什么不能只看关怀模式
 *
 * HarmonyOS 有两套互不替代的适老能力（见 PR-011）：
 * 用户可能**只调大了系统字体**而没开关怀模式 —— 此时系统按 fp 自动放大了文字，
 * 但**点击区、行距、段距都是 vp，不会跟着变**，结果就是「字变大了、按钮没变大」。
 *
 * ## 为什么必须区分两个信号
 *
 * `fromFontScale` 时字号**已经**被系统放大过，我们若再调 `font()` 就是**双重放大**；
 * `fromCareMode` 时系统不会放大，必须由我们抬到 §1.1 的 18 dp。
 * 因此 `boostFont` 只对关怀模式为真。
 */
export function resolveA11ySignalSource(input: NGFInclusiveDesignPolicyInput): NGFA11ySignalSource {
  const fromCareMode: boolean = input.seniorModeEnabled;
  const scale: number = input.systemFontScale;
  const fromFontScale: boolean = scale > 1;
  return {
    fromCareMode: fromCareMode,
    fromFontScale: fromFontScale,
    isElderly: fromCareMode || fromFontScale,
    // 🔴 只有**系统没有放大**时才由我们抬字号。
    //
    // 因为 ArkUI 的 `fontSize(number)` 单位是 **fp**，会随系统字体缩放自动放大：
    // - 关怀模式 ON + 系统字体 1×  → 系统不放大 → **我们抬** ✓
    // - 关怀模式 OFF + 系统字体 1.75× → 系统已放大 → **我们不抬** ✓
    // - 关怀模式 ON + 系统字体 1.75× → 系统已放大 → **我们仍不抬** ✓（否则双重放大）
    //
    // 早期实现写成 `boostFont: fromCareMode`，在「关怀模式 + 系统字体也放大」时
    // 会**双重放大**（我们抬到 18，再被系统乘 1.75 → 31.5）。
    boostFont: fromCareMode && !fromFontScale,
    systemFontScale: scale
  };
}

/** 由策略推导默认 UI 上下文：适老档对应适老版界面，其余按普通页面 */
export function resolveUiContextForPolicy(policy: NGFInclusiveDesignPolicy): NGFUiContext {
  return policy.density === NGFDensityPolicy.ELDERLY
    ? NGFUiContext.ELDERLY_PAGE
    : NGFUiContext.STANDARD_PAGE;
}

/** 取指定上下文下主要组件的点击焦点区域下限（dp/pt） */
export function resolveRequiredTouchTargetDp(context: NGFUiContext): number {
  if (context === NGFUiContext.ELDERLY_PAGE) {
    return NGF_INCLUSIVE_DESIGN_METRICS.elderlyPageTouchTargetDp;
  }
  if (context === NGFUiContext.STANDALONE_ELDERLY_HOME) {
    return NGF_INCLUSIVE_DESIGN_METRICS.standaloneElderlyHomeTouchTargetDp;
  }
  return NGF_INCLUSIVE_DESIGN_METRICS.standardPageTouchTargetDp;
}

/**
 * 取指定上下文下主要文字的下限（dp/pt）。
 *
 * 规范只对"适老版界面/单独适老版 APP"给出 18 dp/pt；
 * 普通页面没有标准下限，此时返回 NGF 自有基线并需按 NGF 基线对待。
 */
export function resolveRequiredBodyFontDp(context: NGFUiContext): number {
  if (context === NGFUiContext.STANDARD_PAGE) {
    return NGF_INCLUSIVE_DESIGN_METRICS.ngfMinBodyFontVp;
  }
  return NGF_INCLUSIVE_DESIGN_METRICS.elderlyBodyFontDp;
}

/**
 * 把持久化的字符串收敛回枚举。
 *
 * 不用强制类型断言，是因为存档可能来自旧版本或被外部改写；
 * 未知值必须回落到明确默认值，而不是让一个非法字符串进入策略。
 */
export function parseTextScalePolicy(raw: string, fallback: NGFTextScalePolicy): NGFTextScalePolicy {
  if (raw === NGFTextScalePolicy.SYSTEM) {
    return NGFTextScalePolicy.SYSTEM;
  }
  if (raw === NGFTextScalePolicy.STANDARD) {
    return NGFTextScalePolicy.STANDARD;
  }
  if (raw === NGFTextScalePolicy.ENHANCED) {
    return NGFTextScalePolicy.ENHANCED;
  }
  return fallback;
}

export function parseTouchTargetPolicy(raw: string, fallback: NGFTouchTargetPolicy): NGFTouchTargetPolicy {
  if (raw === NGFTouchTargetPolicy.STANDARD) {
    return NGFTouchTargetPolicy.STANDARD;
  }
  if (raw === NGFTouchTargetPolicy.LARGE) {
    return NGFTouchTargetPolicy.LARGE;
  }
  return fallback;
}

export function parseContrastPolicy(raw: string, fallback: NGFContrastPolicy): NGFContrastPolicy {
  if (raw === NGFContrastPolicy.STANDARD) {
    return NGFContrastPolicy.STANDARD;
  }
  if (raw === NGFContrastPolicy.ENHANCED) {
    return NGFContrastPolicy.ENHANCED;
  }
  return fallback;
}

export function parseMotionPolicy(raw: string, fallback: NGFMotionPolicy): NGFMotionPolicy {
  if (raw === NGFMotionPolicy.FULL) {
    return NGFMotionPolicy.FULL;
  }
  if (raw === NGFMotionPolicy.REDUCED) {
    return NGFMotionPolicy.REDUCED;
  }
  if (raw === NGFMotionPolicy.NONE) {
    return NGFMotionPolicy.NONE;
  }
  return fallback;
}

export function parseDensityPolicy(raw: string, fallback: NGFDensityPolicy): NGFDensityPolicy {
  if (raw === NGFDensityPolicy.STANDARD) {
    return NGFDensityPolicy.STANDARD;
  }
  if (raw === NGFDensityPolicy.ELDERLY) {
    return NGFDensityPolicy.ELDERLY;
  }
  return fallback;
}
