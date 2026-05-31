/**
 * 字体缩放级别
 */
export enum NGFFontScaleLevel {
  SMALL = 'small',
  NORMAL = 'normal',
  LARGE = 'large',
  EXTRA_LARGE = 'extra_large'
}

/**
 * 字体缩放配置
 */
export class NGFFontScaleConfig {
  readonly level: NGFFontScaleLevel;
  readonly scale: number;

  constructor(level: NGFFontScaleLevel, scale: number) {
    this.level = level;
    this.scale = scale;
  }
}

/**
 * 字体缩放管理器接口
 */
export interface IFontScaleManager {
  getCurrentScale(): number;
  getCurrentLevel(): NGFFontScaleLevel;
  setFontScaleLevel(level: NGFFontScaleLevel): void;
  setCustomScale(scale: number): void;
  resetToSystem(): void;
  getScaleForLevel(level: NGFFontScaleLevel): number;
  onScaleChanged(callback: (scale: number) => void): void;
  offScaleChanged(callback: (scale: number) => void): void;
}
