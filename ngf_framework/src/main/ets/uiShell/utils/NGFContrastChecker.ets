/**
 * NGF 对比度核验工具（P4）
 *
 * 把附件2 §1.3 的对比度要求变成**可计算、可单测**的能力：
 * 「文字与背景的对比度至少 4.5:1；字号大于 18dp/pt 时可放宽到 3:1」。
 *
 * ## 出处必须分开记
 *
 * - **比值阈值 4.5 / 3** 来自工信厅信管函〔2021〕67号 附件2 §1.3（中国官方规范，已逐字核验）。
 * - **相对亮度公式**来自 WCAG 2.x（国际标准）。附件2 只给阈值，**没有给公式**，
 *   所以公式不是"规范原文"，而是为落地阈值而引入的国际标准定义。
 *   已从两个 W3C 来源逐字核对：
 *   - `https://www.w3.org/WAI/GL/wiki/Relative_luminance`
 *   - `https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html`
 *   两处均给出 `L = 0.2126*R + 0.7152*G + 0.0722*B`，且通道线性化分段函数一致。
 *
 * ## 一个必须记录的引用陷阱：分段阈值有两个版本
 *
 * 两个 W3C 来源对 sRGB 线性化的分段点**不一致**：
 * - WAI GL Wiki（WCAG 2.x 旧定义）：`RsRGB <= 0.03928` 时用 `RsRGB/12.92`
 * - WCAG 2.1/2.2 Understanding（现行文档）：`RsRGB <= 0.04045` 时用 `RsRGB/12.92`
 *
 * 本实现采用**现行文档的 0.04045**（sRGB 规范的正确值；0.03928 是历史误差）。
 * 并且可以证明：对 8bit 颜色输入，两个阈值**给出完全相同的结果**——
 * 因为 `0.03928 * 255 = 10.0164`、`0.04045 * 255 = 10.3114`，
 * 区间 (10.0164, 10.3114) 内没有整数，所以任何 8bit 通道值都不会落在两个阈值之间。
 * 该结论由单测穷举 256 个通道值验证。
 */

import { NGF_INCLUSIVE_DESIGN_METRICS } from '../../deviceAwareness/contracts/NGFInclusiveDesignPolicy';

/** sRGB 8bit 颜色 */
export interface NGFColorRgb {
  r: number;
  g: number;
  b: number;
}

/** 现行 WCAG 2.1/2.2 文档使用的 sRGB 线性化分段阈值 */
export const NGF_SRGB_LINEAR_THRESHOLD: number = 0.04045;

/** WCAG 2.x 旧定义使用的分段阈值（历史误差值，仅用于对照，不参与计算） */
export const NGF_SRGB_LINEAR_THRESHOLD_LEGACY: number = 0.03928;

/**
 * 附件2 §1.3 的"大字号"分界：字号大于 18 dp/pt 时对比度要求从 4.5:1 放宽到 3:1。
 * 与 §1.1 的适老最小字号同值，但两者是**不同条款**，不要混为一谈。
 */
export const NGF_LARGE_TEXT_FONT_DP: number = 18;

/** 单次对比度核验结果 */
export interface NGFContrastCheckResult {
  /** 实际对比度（未取整，便于精确比较） */
  ratio: number;
  /** 该场景要求的最低对比度 */
  required: number;
  /** 是否达标 */
  passed: boolean;
  /** 前景色（通常是文字） */
  foreground: NGFColorRgb;
  /** 背景色 */
  background: NGFColorRgb;
}

/**
 * 解析 `#RGB` / `#RRGGBB` / `#AARRGGBB`（可带或不带 `#`）。
 *
 * **alpha 会被忽略**：NGF 与 ArkUI 的颜色资源大量使用 8 位 `#AARRGGBB` 写法，
 * 而对比度公式只对**不透明**颜色成立。若颜色带透明度，
 * 调用方必须自己先与背景做合成，否则算出的比值不代表实际观感。
 * 本函数不做合成，也不因 alpha 非 FF 而拒绝解析 —— 但调用方必须知道这一点。
 *
 * 非法输入返回 `undefined`，**不做静默兜底**，避免把错误颜色当成黑色通过核验。
 */
export function parseHexColor(hex: string): NGFColorRgb | undefined {
  let text: string = hex.trim();
  if (text.startsWith('#')) {
    text = text.substring(1);
  }
  if (text.length === 8) {
    text = text.substring(2);
  }
  if (text.length === 3) {
    const r3: string = text.substring(0, 1);
    const g3: string = text.substring(1, 2);
    const b3: string = text.substring(2, 3);
    text = r3 + r3 + g3 + g3 + b3 + b3;
  }
  if (text.length !== 6) {
    return undefined;
  }
  const value: number = Number.parseInt(text, 16);
  if (Number.isNaN(value)) {
    return undefined;
  }
  const lower: string = text.toLowerCase();
  const valid: string = '0123456789abcdef';
  for (let i = 0; i < lower.length; i++) {
    if (!valid.includes(lower.charAt(i))) {
      return undefined;
    }
  }
  const color: NGFColorRgb = {
    r: (value >> 16) & 0xFF,
    g: (value >> 8) & 0xFF,
    b: value & 0xFF
  };
  return color;
}

/** 单通道线性化；`threshold` 可注入以便对照两个历史版本 */
/**
 * 解析 `#AARRGGBB` 的 alpha 分量，返回 0..1。
 *
 * 6 位写法（`#RRGGBB`）视为完全不透明，返回 **1**。
 * 非法输入返回 **1** —— 与"忽略 alpha"的旧行为保持一致，不引入新的静默失败点。
 *
 * **为什么要单独有这个函数**：`parseHexColor()` 会丢弃 alpha，
 * 而半透明颜色**不能直接算对比度**（对比度公式只对不透明颜色成立）。
 * NGF 自己的毛玻璃令牌就是半透明的（如 `glass_chip_overlay = #CCFFFFFF`，alpha ≈ 0.8），
 * 所以必须先把 alpha 取出来，再用 `compositeOver()` 合成到实际背景上。
 */
export function parseHexAlpha(hex: string): number {
  let text: string = hex.trim();
  if (text.startsWith('#')) {
    text = text.substring(1);
  }
  if (text.length !== 8) {
    return 1;
  }
  const alpha: number = Number.parseInt(text.substring(0, 2), 16);
  if (Number.isNaN(alpha)) {
    return 1;
  }
  return alpha / 255;
}

/**
 * 把半透明色**合成**到不透明背景上，得到可用于对比度计算的有效颜色。
 *
 * `result = top * alpha + bottom * (1 - alpha)`（逐通道，四舍五入）。
 *
 * 用法：半透明前景/背景都必须先合成，再送进 `calculateContrastRatio()`。
 * 由于实际背景可能是渐变或图片，**建议对最坏情况的背景各算一次**
 * （最暗与最亮），两次都达标才能认为安全。
 */
export function compositeOver(top: NGFColorRgb, alpha: number, bottom: NGFColorRgb): NGFColorRgb {
  const a: number = alpha < 0 ? 0 : (alpha > 1 ? 1 : alpha);
  const result: NGFColorRgb = {
    r: Math.round(top.r * a + bottom.r * (1 - a)),
    g: Math.round(top.g * a + bottom.g * (1 - a)),
    b: Math.round(top.b * a + bottom.b * (1 - a))
  };
  return result;
}

export function linearizeChannel(channel8bit: number, threshold: number): number {
  const srgb: number = channel8bit / 255;
  if (srgb <= threshold) {
    return srgb / 12.92;
  }
  return Math.pow((srgb + 0.055) / 1.055, 2.4);
}

/** 相对亮度，取值 0（最暗黑）到 1（最亮白） */
export function relativeLuminance(color: NGFColorRgb): number {
  const r: number = linearizeChannel(color.r, NGF_SRGB_LINEAR_THRESHOLD);
  const g: number = linearizeChannel(color.g, NGF_SRGB_LINEAR_THRESHOLD);
  const b: number = linearizeChannel(color.b, NGF_SRGB_LINEAR_THRESHOLD);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/** 对比度 = (L亮 + 0.05) / (L暗 + 0.05)，对称且恒 ≥ 1 */
export function calculateContrastRatio(a: NGFColorRgb, b: NGFColorRgb): number {
  const la: number = relativeLuminance(a);
  const lb: number = relativeLuminance(b);
  const lighter: number = la > lb ? la : lb;
  const darker: number = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/** 该字号下要求的最低对比度（附件2 §1.3） */
export function requiredContrastRatio(fontSizeVp: number): number {
  if (fontSizeVp > NGF_LARGE_TEXT_FONT_DP) {
    return NGF_INCLUSIVE_DESIGN_METRICS.minLargeTextContrastRatio;
  }
  return NGF_INCLUSIVE_DESIGN_METRICS.minTextContrastRatio;
}

/** 文字对比度核验（附件2 §1.3） */
export function checkTextContrast(
  foreground: NGFColorRgb,
  background: NGFColorRgb,
  fontSizeVp: number
): NGFContrastCheckResult {
  const ratio: number = calculateContrastRatio(foreground, background);
  const required: number = requiredContrastRatio(fontSizeVp);
  const result: NGFContrastCheckResult = {
    ratio: ratio,
    required: required,
    passed: ratio >= required,
    foreground: foreground,
    background: background
  };
  return result;
}

/**
 * 非文字对比度核验（图标、控件边界等）。
 * 使用 NGF 基线值 3:1，**注意**：该 3:1 与 §1.3 的大字号 3:1 数值相同但用途不同，
 * 不可把非文字对比度当成"规范原文已规定"来引用。
 */
export function checkNonTextContrast(
  foreground: NGFColorRgb,
  background: NGFColorRgb
): NGFContrastCheckResult {
  const ratio: number = calculateContrastRatio(foreground, background);
  const required: number = NGF_INCLUSIVE_DESIGN_METRICS.minNonTextContrastRatio;
  const result: NGFContrastCheckResult = {
    ratio: ratio,
    required: required,
    passed: ratio >= required,
    foreground: foreground,
    background: background
  };
  return result;
}
