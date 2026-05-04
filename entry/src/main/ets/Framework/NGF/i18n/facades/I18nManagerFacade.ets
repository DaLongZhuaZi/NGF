import { i18n } from '@kit.LocalizationKit';
import { common } from '@kit.AbilityKit';
import { logger } from '../../utils/Logger';
import { uiContextManager } from '../../platformOhos/UIContextManager';
import { II18nManager, NGFDateStyle, NGFNumberStyle } from '../contracts/II18nManager';

const TAG: string = 'NGFI18nManagerFacade';
const STORAGE_KEY_LOCALE_OVERRIDE: string = 'ngf_current_locale';
const STORAGE_KEY_SYSTEM_LOCALE: string = 'ngf_system_locale';

type LocaleChangedCallback = (locale: string) => void;

class I18nManagerFacade implements II18nManager {
  private static instance: I18nManagerFacade | null = null;
  private readonly callbacks: Array<LocaleChangedCallback> = [];

  static getInstance(): I18nManagerFacade {
    if (!I18nManagerFacade.instance) {
      I18nManagerFacade.instance = new I18nManagerFacade();
    }
    return I18nManagerFacade.instance;
  }

  getCurrentLocale(): string {
    const override = AppStorage.get<string>(STORAGE_KEY_LOCALE_OVERRIDE);
    if (override !== undefined && override !== null && override.length > 0) {
      return override;
    }
    const systemLocale = AppStorage.get<string>(STORAGE_KEY_SYSTEM_LOCALE);
    if (systemLocale !== undefined && systemLocale !== null && systemLocale.length > 0) {
      return systemLocale;
    }
    return i18n.System.getSystemLocaleInstance().toString();
  }

  setLocaleOverride(locale: string): void {
    const normalized = locale.trim();
    if (normalized.length <= 0) {
      logger.warn(TAG, '设置语言覆盖忽略: locale为空');
      return;
    }
    AppStorage.setOrCreate<string>(STORAGE_KEY_LOCALE_OVERRIDE, normalized);
    this.applySystemLocale(normalized);
    logger.info(TAG, `语言覆盖已设置: ${normalized}`);
    this.notifyCallbacks(normalized);
  }

  clearLocaleOverride(): void {
    AppStorage.setOrCreate<string>(STORAGE_KEY_LOCALE_OVERRIDE, '');
    const systemLocale = this.getSystemLocale();
    this.applySystemLocale(systemLocale);
    logger.info(TAG, `语言覆盖已清除，系统语言: ${systemLocale}`);
    this.notifyCallbacks(systemLocale);
  }

  resolveString(key: string): string {
    return this.resolveStringWithArgs(key, []);
  }

  resolveStringWithArgs(key: string, args: Array<string | number>): string {
    const normalizedKey = key.trim();
    if (normalizedKey.length <= 0) {
      return '';
    }

    try {
      const rawContext = uiContextManager.getAbilityContext();
      if (rawContext === null) {
        logger.warn(TAG, `解析字符串失败: 无能力上下文, key=${normalizedKey}`);
        return normalizedKey;
      }

      const abilityContext = rawContext as common.UIAbilityContext;
      let result: string;
      if (args.length > 0) {
        result = abilityContext.resourceManager.getStringByNameSync(normalizedKey, ...args);
      } else {
        result = abilityContext.resourceManager.getStringByNameSync(normalizedKey);
      }
      return result;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `解析字符串错误: key=${normalizedKey}, error=${message}`);
      return normalizedKey;
    }
  }

  formatDate(date: Date, style: NGFDateStyle): string {
    try {
      const locale = this.getCurrentLocale();
      const options = { dateStyle: style } as Intl.DateTimeFormatOptions;
      const dateFormatter = new Intl.DateTimeFormat(locale, options);
      return dateFormatter.format(date);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `格式化日期错误: ${message}`);
      return date.toISOString();
    }
  }

  formatNumber(value: number, style: NGFNumberStyle): string {
    try {
      const locale = this.getCurrentLocale();
      const options = { style: style } as Intl.NumberFormatOptions;
      const numberFormatter = new Intl.NumberFormat(locale, options);
      return numberFormatter.format(value);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `格式化数字错误: ${message}`);
      return `${value}`;
    }
  }

  handleSystemLocaleChanged(language: string): void {
    AppStorage.setOrCreate<string>(STORAGE_KEY_SYSTEM_LOCALE, language);
    const currentLocale = this.getCurrentLocale();
    logger.info(TAG, `系统语言变更: language=${language}, 实际=${currentLocale}`);
    this.notifyCallbacks(currentLocale);
  }

  initializeDefaults(): void {
    if (AppStorage.get<string>(STORAGE_KEY_LOCALE_OVERRIDE) === undefined) {
      AppStorage.setOrCreate<string>(STORAGE_KEY_LOCALE_OVERRIDE, '');
    }
    if (AppStorage.get<string>(STORAGE_KEY_SYSTEM_LOCALE) === undefined) {
      const systemLocale = i18n.System.getSystemLocaleInstance().toString();
      AppStorage.setOrCreate<string>(STORAGE_KEY_SYSTEM_LOCALE, systemLocale);
    }
    const savedOverride = AppStorage.get<string>(STORAGE_KEY_LOCALE_OVERRIDE);
    if (savedOverride !== undefined && savedOverride !== null && savedOverride.length > 0) {
      this.applySystemLocale(savedOverride);
      logger.info(TAG, `国际化默认值已初始化, 恢复语言覆盖: ${savedOverride}`);
    } else {
      logger.info(TAG, `国际化默认值已初始化, 系统语言: ${i18n.System.getSystemLocaleInstance().toString()}`);
    }
  }

  onLocaleChanged(callback: LocaleChangedCallback): void {
    for (let i = 0; i < this.callbacks.length; i++) {
      if (this.callbacks[i] === callback) {
        return;
      }
    }
    this.callbacks.push(callback);
  }

  offLocaleChanged(callback: LocaleChangedCallback): void {
    for (let i = this.callbacks.length - 1; i >= 0; i--) {
      if (this.callbacks[i] === callback) {
        this.callbacks.splice(i, 1);
        return;
      }
    }
  }

  private applySystemLocale(locale: string): void {
    try {
      const context = uiContextManager.getFullAbilityContext();
      if (context) {
        context.getApplicationContext().setLanguage(locale);
        logger.info(TAG, `应用语言已设置: ${locale}`);
      } else {
        logger.warn(TAG, `设置语言失败: 无能力上下文`);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `设置应用语言失败 (可能不支持运行时切换): ${message}`);
    }
  }

  private getSystemLocale(): string {
    const systemLocale = AppStorage.get<string>(STORAGE_KEY_SYSTEM_LOCALE);
    if (systemLocale !== undefined && systemLocale !== null && systemLocale.length > 0) {
      return systemLocale;
    }
    return i18n.System.getSystemLocaleInstance().toString();
  }

  private notifyCallbacks(locale: string): void {
    for (let i = 0; i < this.callbacks.length; i++) {
      try {
        this.callbacks[i](locale);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        logger.error(TAG, `语言回调错误: ${message}`);
      }
    }
  }
}

export const ngfI18nManagerFacade: I18nManagerFacade = I18nManagerFacade.getInstance();
