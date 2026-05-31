import { logger } from '../../utils/Logger';

const TAG: string = 'NGFPageTransitionManager';

/**
 * 页面转场类型
 */
export enum NGFPageTransitionType {
  /** 从右侧滑入（默认） */
  SLIDE = 'slide',
  /** 淡入淡出 */
  FADE = 'fade',
  /** 从中心缩放弹出 */
  SCALE = 'scale',
  /** 从底部滑入 */
  SLIDE_UP = 'slide_up'
}

/**
 * 转场配置
 */
export class NGFPageTransitionConfig {
  readonly type: NGFPageTransitionType;
  readonly duration: number;
  readonly curve: Curve;

  constructor(
    type: NGFPageTransitionType = NGFPageTransitionType.SLIDE,
    duration: number = 300,
    curve: Curve = Curve.EaseOut
  ) {
    this.type = type;
    this.duration = duration;
    this.curve = curve;
  }
}

/**
 * 页面转场管理接口
 */
export interface IPageTransitionManager {
  setGlobalTransition(type: NGFPageTransitionType): void;
  setGlobalTransitionConfig(config: NGFPageTransitionConfig): void;
  getGlobalTransitionConfig(): NGFPageTransitionConfig;
  buildEnterTransition(config?: NGFPageTransitionConfig): TransitionEffect;
  buildExitTransition(config?: NGFPageTransitionConfig): TransitionEffect;
}
