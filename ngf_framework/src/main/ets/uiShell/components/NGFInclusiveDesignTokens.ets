/**
 * NGF 包容性设计令牌（P4）
 *
 * 把 `NGFInclusiveDesignPolicy` 从"数据模型"变成"页面真正能用的数值"。
 *
 * ## 每个数值都能追溯到出处
 *
 * | 字段 | 来源 |
 * |---|---|
 * | `bodyFontSize` | 工信厅信管函〔2021〕67号 附件2 §1.1（适老版 ≥18 dp/pt）；普通页面回落 NGF 基线 16 vp |
 * | `maxSupportedFontSize` | 附件2 §1.1（主要功能/界面最大字体不小于 30 dp/pt） |
 * | `bodyLineHeight` | 附件2 §1.2（行距至少 1.3 倍） |
 * | `paragraphSpacing` | 附件2 §1.2（段落间距至少比行距大 1.3 倍） |
 * | `minTouchTarget` | 附件2 §2.1（适老版 60 / 其他页面 44 / 独立适老版首页 48 dp/pt） |
 * | `dialogCloseTarget` | 附件2 §2.4（浮窗关闭按钮 ≥44×44 dp/pt） |
 * | `textContrastRatio` / `largeContrastRatio` | 附件2 §1.3（4.5:1；字号 >18 时 3:1） |
 * | `requireNonColorRedundancy` | 附件2 §1.4（颜色不得是唯一区分手段） |
 * | `motionDurationScale` / `allowDecorativeMotion` | **NGF 自定**：规范未规定动效，系统只给布尔"减少动效"信号 |
 *
 * 单位映射：ArkUI 的 `vp` 与规范的 `dp/pt` 按 1:1 做工程映射（工程假设，非规范原文）。
 */

import {
  NGF_INCLUSIVE_DESIGN_METRICS,
  NGFInclusiveDesignMetrics,
  NGFInclusiveDesignPolicy,
  NGFMotionPolicy,
  NGFUiContext,
  resolveRequiredBodyFontDp,
  resolveRequiredTouchTargetDp
} from '../../deviceAwareness/contracts/NGFInclusiveDesignPolicy';

/** 浮窗关闭键允许的位置。附件2 §2.4 只允许这三处。 */
export enum NGFDialogClosePosition {
  TOP_LEFT = 'top_left',
  TOP_RIGHT = 'top_right',
  BOTTOM_CENTER = 'bottom_center'
}

/** 附件2 §2.4 允许的关闭键位置集合 */
export const NGF_DIALOG_CLOSE_ALLOWED_POSITIONS: Array<NGFDialogClosePosition> = [
  NGFDialogClosePosition.TOP_LEFT,
  NGFDialogClosePosition.TOP_RIGHT,
  NGFDialogClosePosition.BOTTOM_CENTER
];

/** 附件2 §2.2：避免需 3 个或以上手指才能完成的复杂手势，故上限为 2 */
export const NGF_MAX_GESTURE_FINGER_COUNT: number = 2;

/** 关闭键位置是否合规 */
export function isDialogClosePositionAllowed(position: NGFDialogClosePosition): boolean {
  return NGF_DIALOG_CLOSE_ALLOWED_POSITIONS.includes(position);
}

/** 手势手指数是否合规 */
export function isGestureFingerCountAllowed(fingerCount: number): boolean {
  return fingerCount >= 1 && fingerCount <= NGF_MAX_GESTURE_FINGER_COUNT;
}

/** 解析后的设计令牌，单位均为 vp，除非另有说明 */
export interface NGFInclusiveDesignTokens {
  /** 正文最小字号（vp） */
  bodyFontSize: number;
  /** 主要功能/界面必须支持到的最大字号（vp）—— 低于它说明字体缩放能力不足 */
  maxSupportedFontSize: number;
  /** 正文行高（vp），已按规范行距倍数算出 */
  bodyLineHeight: number;
  /** 段落间距下限（vp），已按"段距 ≥ 行距 × 1.3"算出 */
  paragraphSpacing: number;
  /** 主要组件最小点击区边长（vp），随 UI 上下文取 44 / 48 / 60 */
  minTouchTarget: number;
  /** 浮窗关闭键最小点击区边长（vp） */
  dialogCloseTarget: number;
  /** 普通文本对比度下限 */
  textContrastRatio: number;
  /** 大文本（字号大于 18 vp）对比度下限 */
  largeTextContrastRatio: number;
  /** 是否要求非颜色冗余表达（规范 §1.4） */
  requireNonColorRedundancy: boolean;
  /** 动效时长倍率：1 = 正常，0.5 = 减弱，0 = 关闭 */
  motionDurationScale: number;
  /** 是否允许非必要装饰动效 */
  allowDecorativeMotion: boolean;
}

/** 令牌解析输入 */
export interface NGFInclusiveDesignTokenInput {
  /** 当前生效策略 */
  policy: NGFInclusiveDesignPolicy;
  /** 当前 UI 上下文（决定触控与字号档位） */
  context: NGFUiContext;
  /** 页面自身基准正文字号（vp）；缺省或低于规范下限时取下限 */
  baseBodyFontSize?: number;
}

/** 保留两位小数，避免浮点尾差进入布局与断言 */
function round2(value: number): number {
  return Math.round(value * 100) / 100;
}

/**
 * 由策略 + UI 上下文解析出可下发到组件的设计令牌。
 * **纯函数**，不依赖 ArkUI 运行时，可直接单测。
 */
export function resolveInclusiveDesignTokens(input: NGFInclusiveDesignTokenInput): NGFInclusiveDesignTokens {
  const metrics: NGFInclusiveDesignMetrics = NGF_INCLUSIVE_DESIGN_METRICS;

  const fontFloor: number = resolveRequiredBodyFontDp(input.context);
  const requested: number | undefined = input.baseBodyFontSize;
  const bodyFontSize: number = requested !== undefined && requested > fontFloor ? requested : fontFloor;

  const bodyLineHeight: number = round2(bodyFontSize * metrics.minLineHeightRatio);
  const paragraphSpacing: number = round2(bodyLineHeight * metrics.minParagraphSpacingRatio);

  const motion: NGFMotionPolicy = input.policy.motion;
  let motionDurationScale: number = 1;
  if (motion === NGFMotionPolicy.REDUCED) {
    motionDurationScale = 0.5;
  } else if (motion === NGFMotionPolicy.NONE) {
    motionDurationScale = 0;
  }

  const tokens: NGFInclusiveDesignTokens = {
    bodyFontSize: bodyFontSize,
    maxSupportedFontSize: metrics.supportedMaxFontDp,
    bodyLineHeight: bodyLineHeight,
    paragraphSpacing: paragraphSpacing,
    minTouchTarget: resolveRequiredTouchTargetDp(input.context),
    dialogCloseTarget: metrics.dialogCloseTargetDp,
    textContrastRatio: metrics.minTextContrastRatio,
    largeTextContrastRatio: metrics.minLargeTextContrastRatio,
    requireNonColorRedundancy: true,
    motionDurationScale: motionDurationScale,
    allowDecorativeMotion: motion === NGFMotionPolicy.FULL
  };
  return tokens;
}
