import { ConfigurationConstant } from '@kit.AbilityKit';
import { logger } from '../../utils/Logger';
import { IThemeManager, NGFThemeMode } from '../contracts/IThemeManager';

const TAG: string = 'NGFThemeManagerFacade';
const STORAGE_KEY_THEME_OVERRIDE: string = 'ngf_current_theme';
const STORAGE_KEY_SYSTEM_COLOR_MODE: string = 'ngf_system_color_mode';
const STORAGE_KEY_IS_DARK: string = 'ngf_is_dark_mode';

type ThemeChangedCallback = (mode: NGFThemeMode) => void;

class ThemeManagerFacade implements IThemeManager {
  private static instance: ThemeManagerFacade | null = null;
  private readonly callbacks: Array<ThemeChangedCallback> = [];

  static getInstance(): ThemeManagerFacade {
    if (!ThemeManagerFacade.instance) {
      ThemeManagerFacade.instance = new ThemeManagerFacade();
    }
    return ThemeManagerFacade.instance;
  }

  getCurrentTheme(): NGFThemeMode {
    const stored = AppStorage.get<string>(STORAGE_KEY_THEME_OVERRIDE);
    if (stored === undefined || stored === null || stored.length <= 0) {
      return NGFThemeMode.AUTO;
    }
    if (stored === NGFThemeMode.LIGHT) {
      return NGFThemeMode.LIGHT;
    }
    if (stored === NGFThemeMode.DARK) {
      return NGFThemeMode.DARK;
    }
    return NGFThemeMode.AUTO;
  }

  setThemeOverride(mode: NGFThemeMode): void {
    AppStorage.setOrCreate<string>(STORAGE_KEY_THEME_OVERRIDE, mode);
    const isDark = this.resolveIsDark(mode);
    AppStorage.setOrCreate<boolean>(STORAGE_KEY_IS_DARK, isDark);
    logger.info(TAG, `主题覆盖已设置: mode=${mode}, isDark=${isDark}`);
    this.notifyCallbacks(mode);
  }

  clearThemeOverride(): void {
    AppStorage.setOrCreate<string>(STORAGE_KEY_THEME_OVERRIDE, NGFThemeMode.AUTO);
    const isDark = this.resolveIsDark(NGFThemeMode.AUTO);
    AppStorage.setOrCreate<boolean>(STORAGE_KEY_IS_DARK, isDark);
    logger.info(TAG, '主题覆盖已清除，恢复为自动模式');
    this.notifyCallbacks(NGFThemeMode.AUTO);
  }

  isDarkMode(): boolean {
    const override = this.getCurrentTheme();
    return this.resolveIsDark(override);
  }

  onThemeChanged(callback: ThemeChangedCallback): void {
    for (let i = 0; i < this.callbacks.length; i++) {
      if (this.callbacks[i] === callback) {
        return;
      }
    }
    this.callbacks.push(callback);
  }

  offThemeChanged(callback: ThemeChangedCallback): void {
    for (let i = this.callbacks.length - 1; i >= 0; i--) {
      if (this.callbacks[i] === callback) {
        this.callbacks.splice(i, 1);
        return;
      }
    }
  }

  handleSystemColorModeChanged(colorMode: number): void {
    AppStorage.setOrCreate<number>(STORAGE_KEY_SYSTEM_COLOR_MODE, colorMode);
    const currentTheme = this.getCurrentTheme();
    const isDark = this.resolveIsDark(currentTheme);
    AppStorage.setOrCreate<boolean>(STORAGE_KEY_IS_DARK, isDark);
    logger.info(TAG, `系统颜色模式变更: colorMode=${colorMode}, 实际深色=${isDark}`);
    this.notifyCallbacks(currentTheme);
  }

  initializeDefaults(): void {
    if (AppStorage.get<string>(STORAGE_KEY_THEME_OVERRIDE) === undefined) {
      AppStorage.setOrCreate<string>(STORAGE_KEY_THEME_OVERRIDE, NGFThemeMode.AUTO);
    }
    if (AppStorage.get<number>(STORAGE_KEY_SYSTEM_COLOR_MODE) === undefined) {
      AppStorage.setOrCreate<number>(STORAGE_KEY_SYSTEM_COLOR_MODE, ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    }
    if (AppStorage.get<boolean>(STORAGE_KEY_IS_DARK) === undefined) {
      AppStorage.setOrCreate<boolean>(STORAGE_KEY_IS_DARK, false);
    }
    logger.info(TAG, '主题默认值已初始化');
  }

  private resolveIsDark(mode: NGFThemeMode): boolean {
    if (mode === NGFThemeMode.DARK) {
      return true;
    }
    if (mode === NGFThemeMode.LIGHT) {
      return false;
    }
    // AUTO: follow system
    const systemColorMode = AppStorage.get<number>(STORAGE_KEY_SYSTEM_COLOR_MODE);
    if (systemColorMode === undefined || systemColorMode === null) {
      return false;
    }
    return systemColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  private notifyCallbacks(mode: NGFThemeMode): void {
    for (let i = 0; i < this.callbacks.length; i++) {
      try {
        this.callbacks[i](mode);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        logger.error(TAG, `主题回调错误: ${message}`);
      }
    }
  }
}

export const ngfThemeManagerFacade: ThemeManagerFacade = ThemeManagerFacade.getInstance();
