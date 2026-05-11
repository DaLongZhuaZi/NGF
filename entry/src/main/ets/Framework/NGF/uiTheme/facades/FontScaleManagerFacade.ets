import { logger } from '../../utils/Logger';
import { IFontScaleManager, NGFFontScaleConfig, NGFFontScaleLevel } from '../contracts/IFontScaleManager';

const TAG: string = 'NGFFontScaleManagerFacade';
const STORAGE_KEY_FONT_SCALE: string = 'ngf_font_scale_level';
const STORAGE_KEY_FONT_SCALE_CUSTOM: string = 'ngf_font_scale_custom';

const SCALE_CONFIGS: Array<NGFFontScaleConfig> = [
  new NGFFontScaleConfig(NGFFontScaleLevel.SMALL, 0.85),
  new NGFFontScaleConfig(NGFFontScaleLevel.NORMAL, 1.0),
  new NGFFontScaleConfig(NGFFontScaleLevel.LARGE, 1.15),
  new NGFFontScaleConfig(NGFFontScaleLevel.EXTRA_LARGE, 1.3)
];

type ScaleChangedCallback = (scale: number) => void;

export class FontScaleManagerFacade implements IFontScaleManager {
  private readonly callbacks: Array<ScaleChangedCallback> = [];
  private currentScale: number = 1.0;
  private currentLevel: NGFFontScaleLevel = NGFFontScaleLevel.NORMAL;
  private isCustom: boolean = false;

  constructor() {
    this.initializeFromStorage();
  }

  getCurrentScale(): number {
    return this.currentScale;
  }

  getCurrentLevel(): NGFFontScaleLevel {
    return this.currentLevel;
  }

  setFontScaleLevel(level: NGFFontScaleLevel): void {
    this.currentLevel = level;
    this.isCustom = false;
    this.currentScale = this.getScaleForLevel(level);
    this.saveToStorage();
    logger.info(TAG, `设置字体缩放级别: level=${level}, scale=${this.currentScale}`);
    this.notifyCallbacks(this.currentScale);
  }

  setCustomScale(scale: number): void {
    const clamped = this.clampScale(scale);
    this.currentScale = clamped;
    this.isCustom = true;
    this.currentLevel = this.resolveLevelFromScale(clamped);
    this.saveToStorage();
    logger.info(TAG, `设置自定义字体缩放: scale=${clamped}`);
    this.notifyCallbacks(this.currentScale);
  }

  resetToSystem(): void {
    this.currentScale = 1.0;
    this.currentLevel = NGFFontScaleLevel.NORMAL;
    this.isCustom = false;
    this.saveToStorage();
    logger.info(TAG, '重置字体缩放为系统默认');
    this.notifyCallbacks(this.currentScale);
  }

  getScaleForLevel(level: NGFFontScaleLevel): number {
    for (let index = 0; index < SCALE_CONFIGS.length; index++) {
      if (SCALE_CONFIGS[index].level === level) {
        return SCALE_CONFIGS[index].scale;
      }
    }
    return 1.0;
  }

  onScaleChanged(callback: ScaleChangedCallback): void {
    for (let i = 0; i < this.callbacks.length; i++) {
      if (this.callbacks[i] === callback) {
        return;
      }
    }
    this.callbacks.push(callback);
  }

  offScaleChanged(callback: ScaleChangedCallback): void {
    for (let i = this.callbacks.length - 1; i >= 0; i--) {
      if (this.callbacks[i] === callback) {
        this.callbacks.splice(i, 1);
        return;
      }
    }
  }

  private initializeFromStorage(): void {
    try {
      const storedLevel = AppStorage.get<string>(STORAGE_KEY_FONT_SCALE);
      const storedCustom = AppStorage.get<number>(STORAGE_KEY_FONT_SCALE_CUSTOM);

      if (storedCustom !== undefined && storedCustom !== null && storedCustom > 0) {
        this.currentScale = this.clampScale(storedCustom);
        this.isCustom = true;
        this.currentLevel = this.resolveLevelFromScale(this.currentScale);
        logger.info(TAG, `从存储恢复自定义字体缩放: scale=${this.currentScale}`);
      } else if (storedLevel !== undefined && storedLevel !== null && storedLevel.length > 0) {
        this.currentLevel = storedLevel as NGFFontScaleLevel;
        this.currentScale = this.getScaleForLevel(this.currentLevel);
        logger.info(TAG, `从存储恢复字体缩放级别: level=${this.currentLevel}`);
      } else {
        this.currentScale = 1.0;
        this.currentLevel = NGFFontScaleLevel.NORMAL;
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `初始化字体缩放失败: ${message}`);
      this.currentScale = 1.0;
      this.currentLevel = NGFFontScaleLevel.NORMAL;
    }
  }

  private saveToStorage(): void {
    if (this.isCustom) {
      AppStorage.setOrCreate<string>(STORAGE_KEY_FONT_SCALE, '');
      AppStorage.setOrCreate<number>(STORAGE_KEY_FONT_SCALE_CUSTOM, this.currentScale);
    } else {
      AppStorage.setOrCreate<string>(STORAGE_KEY_FONT_SCALE, this.currentLevel);
      AppStorage.setOrCreate<number>(STORAGE_KEY_FONT_SCALE_CUSTOM, 0);
    }
  }

  private clampScale(scale: number): number {
    if (scale < 0.5) {
      return 0.5;
    }
    if (scale > 2.0) {
      return 2.0;
    }
    return scale;
  }

  private resolveLevelFromScale(scale: number): NGFFontScaleLevel {
    let closest: NGFFontScaleLevel = NGFFontScaleLevel.NORMAL;
    let minDiff: number = Number.MAX_VALUE;
    for (let index = 0; index < SCALE_CONFIGS.length; index++) {
      const config = SCALE_CONFIGS[index];
      const diff = Math.abs(config.scale - scale);
      if (diff < minDiff) {
        minDiff = diff;
        closest = config.level;
      }
    }
    return closest;
  }

  private notifyCallbacks(scale: number): void {
    for (let i = 0; i < this.callbacks.length; i++) {
      try {
        this.callbacks[i](scale);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        logger.error(TAG, `字体缩放回调错误: ${message}`);
      }
    }
  }
}

export const ngfFontScaleManagerFacade: FontScaleManagerFacade = new FontScaleManagerFacade();
