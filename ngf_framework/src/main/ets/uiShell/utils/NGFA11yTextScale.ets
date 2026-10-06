/**
 * NGF 适老文本缩放器
 *
 * 把「适老档字号 / 行高」的换算规则抽出来，供**任意组件**复用，
 * 避免每个页面/组件各写一份 `isElderlyUi ? ... : ...` 的判断而逐渐漂移。
 *
 * ## 规则来源（工信厅信管函〔2021〕67号 附件2）
 *
 * | 方法 | 条款 | 适老档 | 普通档 |
 * |---|---|---|---|
 * | `font(n)` | §1.1 主要文字 ≥18 dp/pt | `max(18, n)` | `n`（**原样，零视觉回归**） |
 * | `lineHeight(f)` | §1.2 行距 ≥1.3 倍 | `f × 1.3` | **0** |
 * | `explicitLineHeight(f, normal)` | §1.2 | `f × 1.3` | `normal` |
 *
 * ## 为什么普通档的 `lineHeight` 返回 0
 *
 * ArkUI 的 `lineHeight(value)` 文档明确：「小于等于 0 时行高不受限、随字号自适应」，
 * 即**默认行为**。因此返回 0 对现有普通版是**完全透明**的 —— 不需要为普通档维护两套行高值。
 */

import {
  NGFDensityPolicy,
  NGFInclusiveDesignPolicy,
  NGFA11ySignalSource,
  NGF_INCLUSIVE_DESIGN_METRICS
} from '../../deviceAwareness/contracts/NGFInclusiveDesignPolicy';
import { ngfAccessibilityFacade } from '../../deviceAwareness/facades/AccessibilityFacade';

// 从本模块再导出，方便页面只引一个模块即可拿到"双信号 + 缩放器"这一整套。
export { NGFA11ySignalSource, resolveA11ySignalSource } from '../../deviceAwareness/contracts/NGFInclusiveDesignPolicy';

/** 附件2 §1.2 规定的行距倍数下限 */
export const NGF_A11Y_LINE_HEIGHT_RATIO: number = 1.3;

/** 适老文本缩放器：把规范数值换算成可直接下发的字号与行高 */
export class NGFA11yTextScale {
  /** 是否处于适老档（**任一信号为真**即为真：关怀模式 或 系统字体缩放 > 1） */
  readonly isElderly: boolean;
  /** 是否由**我们主动抬字号**；仅关怀模式需要（见下） */
  readonly boostFont: boolean;
  /** 当前系统字体缩放倍率，1 表示未放大 */
  readonly systemFontScale: number;
  readonly fromCareMode: boolean;
  readonly fromFontScale: boolean;

  constructor(
    isElderly: boolean,
    boostFont?: boolean,
    systemFontScale?: number,
    fromCareMode?: boolean,
    fromFontScale?: boolean
  ) {
    this.isElderly = isElderly;
    this.boostFont = boostFont !== undefined ? boostFont : isElderly;
    this.systemFontScale = systemFontScale !== undefined ? systemFontScale : 1;
    this.fromCareMode = fromCareMode !== undefined ? fromCareMode : isElderly;
    this.fromFontScale = fromFontScale !== undefined ? fromFontScale : false;
  }

  /**
   * 适老档字号：附件2 §1.1「适老版界面……主要文字信息不小于 18 dp/pt」。
   * 普通档**原样返回**，保证现有版式零回归。
   *
   * ⚠️ **只在 `boostFont` 为真时抬字号**（即仅关怀模式）。
   *
   * 原因：ArkUI 的 `fontSize(number)` 单位是 **fp**，会随系统字体缩放自动放大。
   * 若用户只调大了系统字体（`fromFontScale`），字号**已经被系统放大过一次**；
   * 我们再抬一次就是**双重放大**，容易把版式撑破。
   * 但行距（§1.2）与点击区（§2.1）是 **vp**，**不会**跟随系统缩放 ——
   * 所以这两个仍然要按 `isElderly` 补上。
   */
  font(normalFontSize: number): number {
    if (!this.boostFont) {
      return normalFontSize;
    }
    return Math.max(NGF_INCLUSIVE_DESIGN_METRICS.elderlyBodyFontDp, normalFontSize);
  }

  /**
   * 适老档行高：附件2 §1.2「段落内文字的行距至少为 1.3 倍」。
   * 普通档返回 **0**（SDK 语义 = 沿用默认行高，即不改变现有视觉）。
   */
  lineHeight(fontSize: number): number {
    if (!this.isElderly) {
      return 0;
    }
    return Math.round(fontSize * NGF_A11Y_LINE_HEIGHT_RATIO * 100) / 100;
  }

  /** 适老档行高（原本已有显式行高的文本用）；普通档保留页面原有行高值 */
  explicitLineHeight(fontSize: number, normalLineHeight: number): number {
    if (!this.isElderly) {
      return normalLineHeight;
    }
    return Math.round(fontSize * NGF_A11Y_LINE_HEIGHT_RATIO * 100) / 100;
  }

  /**
   * 组内间距（标签/值、图标/文字这类**紧耦合**元素之间）。
   *
   * 适老档按比例放大（×1.6）让呼吸感更足，但**不套用段落间距** ——
   * 附件2 §1.2 的「段落间距」针对的是**独立段落**；
   * 若把标签与值之间也拉到 30 vp，卡片会被撑得过高、一屏信息量骤降，
   * 反而背离 §2.3「充足操作时间」的意图（减少操作负担 ≠ 减少可见信息）。
   */
  groupSpacing(normalSpacing: number): number {
    if (!this.isElderly) {
      return normalSpacing;
    }
    return Math.round(normalSpacing * 1.6);
  }

  /**
   * 适老档段落间距：附件2 §1.2「段落间距至少比行距大 1.3 倍」。
   * 普通档原样返回。
   */
  paragraphSpacing(normalSpacing: number, bodyFontSize: number): number {
    if (!this.isElderly) {
      return normalSpacing;
    }
    const required: number = Math.round(
      bodyFontSize * NGF_A11Y_LINE_HEIGHT_RATIO * NGF_A11Y_LINE_HEIGHT_RATIO * 100) / 100;
    return Math.max(normalSpacing, required);
  }
}

/**
 * 适老字号（模块级）。
 *
 * 与 `NGFA11yTextScale.font()` 同一规则，但**不需要持有实例** ——
 * 供叶子组件使用：它们从父组件接收一个 `@Prop isElderly: boolean`（原始类型，安全），
 * 而不是接收 `NGFA11yTextScale` 实例（ArkTS 的 `@Prop` 会深拷贝对象，
 * 类实例经拷贝后原型可能丢失、方法不可用）。
 */
export function a11yFontFor(isElderly: boolean, normalFontSize: number, boostFont?: boolean): number {
  // 未显式传 boostFont 时按 isElderly 处理（兼容旧调用）。
  const boost: boolean = boostFont !== undefined ? boostFont : isElderly;
  if (!boost) {
    return normalFontSize;
  }
  return Math.max(NGF_INCLUSIVE_DESIGN_METRICS.elderlyBodyFontDp, normalFontSize);
}

/**
 * 适老行高（模块级）。普通档返回 **0** —— SDK 语义：≤0 时行高随字号自适应（即默认行为）。
 */
export function a11yLineHeightFor(isElderly: boolean, fontSize: number): number {
  if (!isElderly) {
    return 0;
  }
  return Math.round(fontSize * NGF_A11Y_LINE_HEIGHT_RATIO * 100) / 100;
}

/**
 * 适老显式行高（模块级）：原本已有显式行高的文本用，普通档保留原值。
 */
export function a11yExplicitLineHeightFor(isElderly: boolean, fontSize: number, normalLineHeight: number): number {
  if (!isElderly) {
    return normalLineHeight;
  }
  return Math.round(fontSize * NGF_A11Y_LINE_HEIGHT_RATIO * 100) / 100;
}

/**
 * 组内间距（模块级）。规则同 `NGFA11yTextScale.groupSpacing()`。
 */
export function a11yGroupSpacingFor(isElderly: boolean, normalSpacing: number): number {
  if (!isElderly) {
    return normalSpacing;
  }
  return Math.round(normalSpacing * 1.6);
}

/**
 * 适老点击区：附件2 §2.1「适老版界面中的主要组件可点击焦点区域尺寸不小于60×60dp/pt」。
 * 普通档**原样返回**（不影响现有版式）。
 *
 * 独立函数而不是类方法，是为了让没有持有缩放器实例的地方（例如纯函数式布局计算）也能用。
 */
export function a11yTouchTarget(isElderly: boolean, normalSize: number): number {
  if (!isElderly) {
    return normalSize;
  }
  return Math.max(NGF_INCLUSIVE_DESIGN_METRICS.elderlyPageTouchTargetDp, normalSize);
}

/**
 * 由策略解析出文本缩放器。
 *
 * 判定依据是 `density === ELDERLY`（经 `resolveUiContextForPolicy`），
 * 与 `NGFInclusiveDesignTokens` 用的是**同一套**上下文推导，不会出现两处判断不一致。
 *
 * @param policy 已解析的包容性设计策略
 * @param signal 适老信号来源；**建议传**，否则无法区分两个信号，
 *               `boostFont` 会保守地跟随 `isElderly`（可能对字体缩放档双重放大）
 */
export function resolveA11yTextScale(
  policy: NGFInclusiveDesignPolicy,
  signal?: NGFA11ySignalSource
): NGFA11yTextScale {
  const elderly: boolean = policy.density === NGFDensityPolicy.ELDERLY;
  if (signal !== undefined) {
    return new NGFA11yTextScale(elderly, signal.boostFont, signal.systemFontScale,
      signal.fromCareMode, signal.fromFontScale);
  }
  // 兼容旧调用：无法区分信号时，保守地认为需要抬字号。
  return new NGFA11yTextScale(elderly, elderly, 1, elderly, false);
}

/**
 * 直接从门面读取当前适老信号并解析缩放器。
 *
 * **页面/组件应优先用这个** —— 它同时考虑关怀模式与系统字体缩放（PR-011），
 * 而不会出现「只调大系统字体的用户拿不到适老布局」。
 */
export function resolveA11yTextScaleForCurrent(): NGFA11yTextScale {
  return resolveA11yTextScale(ngfAccessibilityFacade.getPolicy(),
    ngfAccessibilityFacade.getA11ySignalSource());
}
