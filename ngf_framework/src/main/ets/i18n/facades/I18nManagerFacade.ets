import { i18n } from '@kit.LocalizationKit';
import { common } from '@kit.AbilityKit';
import { intl } from '@kit.LocalizationKit';
import { logger } from '../../utils/Logger';
import { uiContextManager } from '../../platformOhos/UIContextManager';
import { II18nManager, ITypeSafeI18nManager, NGFDateStyle, NGFNumberStyle } from '../contracts/II18nManager';

const TAG: string = 'NGFI18nManagerFacade';
const STORAGE_KEY_LOCALE_OVERRIDE: string = 'ngf_current_locale';
const STORAGE_KEY_SYSTEM_LOCALE: string = 'ngf_system_locale';

type LocaleChangedCallback = (locale: string) => void;

class I18nManagerFacade implements II18nManager {
  private static instance: I18nManagerFacade | null = null;
  private readonly callbacks: Array<LocaleChangedCallback> = [];
  private isApplyingLocale: boolean = false;

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
    const systemLocale = i18n.System.getSystemLocaleInstance().toString();
    AppStorage.setOrCreate<string>(STORAGE_KEY_SYSTEM_LOCALE, systemLocale);
    this.applySystemLocale(systemLocale);
    logger.info(TAG, `语言覆盖已清除，系统语言: ${systemLocale}`);
    this.notifyCallbacks(systemLocale);
  }

  resolveString(key: string | Resource): string {
    return this.resolveStringWithArgs(key, []);
  }

  resolveStringWithArgs(key: string | Resource, args: Array<string | number>): string {
    try {
      const rawContext = uiContextManager.getAbilityContext();
      if (rawContext === null) {
        logger.warn(TAG, `解析字符串失败: 无能力上下文`);
        return typeof key === 'string' ? key : 'Resource';
      }

      const abilityContext = rawContext as common.UIAbilityContext;
      let result: string;
      
      if (typeof key === 'string') {
        const normalizedKey = key.trim();
        if (normalizedKey.length <= 0) {
          return '';
        }
        if (args.length > 0) {
          result = abilityContext.resourceManager.getStringByNameSync(normalizedKey, ...args);
        } else {
          result = abilityContext.resourceManager.getStringByNameSync(normalizedKey);
        }
      } else {
        if (args.length > 0) {
          result = abilityContext.resourceManager.getStringSync(key, ...args);
        } else {
          result = abilityContext.resourceManager.getStringSync(key);
        }
      }
      return result;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `解析字符串错误: error=${message}`);
      return typeof key === 'string' ? key : 'Resource';
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
      const options: intl.NumberOptions = { style: style };
      if (style === NGFNumberStyle.CURRENCY) {
        const inferredCurrency: string = this.inferCurrencyFromLocale(locale);
        options.currency = inferredCurrency;
        options.currencyDisplay = 'symbol';
      }
      const numberFormatter = new intl.NumberFormat(locale, options);
      return numberFormatter.format(value);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `格式化数字错误: ${message}`);
      return `${value}`;
    }
  }

  handleSystemLocaleChanged(language: string): void {
    AppStorage.setOrCreate<string>(STORAGE_KEY_SYSTEM_LOCALE, language);
    const override = AppStorage.get<string>(STORAGE_KEY_LOCALE_OVERRIDE);
    if (this.isApplyingLocale) {
      logger.info(TAG, '系统语言变更回调(应用内部触发，跳过二次应用): language=' + language);
      return;
    }
    if (!override || override.length === 0) {
      this.applySystemLocale(language);
    }
    const currentLocale = this.getCurrentLocale();
    logger.info(TAG, `系统语言变更: language=${language}, 实际=${currentLocale}`);
    this.notifyCallbacks(currentLocale);
  }

  initializeDefaults(): void {
    PersistentStorage.persistProp<string>(STORAGE_KEY_LOCALE_OVERRIDE, '');
    PersistentStorage.persistProp<string>(STORAGE_KEY_SYSTEM_LOCALE, i18n.System.getSystemLocaleInstance().toString());
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
      const systemLocale = i18n.System.getSystemLocaleInstance().toString();
      this.applySystemLocale(systemLocale);
      logger.info(TAG, `国际化默认值已初始化, 系统语言: ${systemLocale}`);
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
    if (this.isApplyingLocale) {
      return;
    }
    this.isApplyingLocale = true;
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
    } finally {
      this.isApplyingLocale = false;
    }
  }

  /**
   * 检测当前语言是否为 RTL（从右到左）布局语言
   * Phase F2：接口预埋，基于 locale 代码判断
   */
  isRtl(): boolean {
    const locale = this.getCurrentLocale();
    const rtlLanguages: Array<string> = ['ar', 'he', 'fa', 'ur', 'ps', 'sd', 'ku', 'dv'];
    const langCode = locale.split('-')[0].toLowerCase();
    for (let i = 0; i < rtlLanguages.length; i++) {
      if (rtlLanguages[i] === langCode) {
        logger.debug(TAG, `RTL 语言检测: locale=${locale}, isRtl=true`);
        return true;
      }
    }
    return false;
  }

  /**
   * 获取当前布局方向字符串
   * @returns 'RTL' 或 'LTR'
   */
  getLayoutDirection(): string {
    return this.isRtl() ? 'RTL' : 'LTR';
  }

  /**
   * 获取与当前布局方向匹配的 TextAlign
   * RTL 返回 TextAlign.End，LTR 返回 TextAlign.Start
   */
  getTextAlign(): TextAlign {
    return this.isRtl() ? TextAlign.End : TextAlign.Start;
  }

  /**
   * 获取与当前布局方向匹配的 FlexDirection
   * RTL 返回 FlexDirection.RowReverse，LTR 返回 FlexDirection.Row
   */
  getFlexDirection(): FlexDirection {
    return this.isRtl() ? FlexDirection.RowReverse : FlexDirection.Row;
  }

  private inferCurrencyFromLocale(locale: string): string {
    const langCode = locale.split('-')[0].toLowerCase();
    const regionParts: Array<string> = locale.split('-');
    const region: string = regionParts.length > 1 ? regionParts[1].toUpperCase() : '';
    if (region === 'CN' || langCode === 'zh') {
      return 'CNY';
    }
    if (region === 'US' || langCode === 'en') {
      return 'USD';
    }
    if (region === 'JP' || langCode === 'ja') {
      return 'JPY';
    }
    if (region === 'KR' || langCode === 'ko') {
      return 'KRW';
    }
    if (region === 'GB') {
      return 'GBP';
    }
    if (region === 'EU' || langCode === 'de' || langCode === 'fr' || langCode === 'it' || langCode === 'es') {
      return 'EUR';
    }
    return 'CNY';
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

export class TypeSafeI18nFacade<TKey extends string> implements ITypeSafeI18nManager<TKey> {
  private readonly inner: II18nManager;

  constructor(inner: II18nManager) {
    this.inner = inner;
  }

  resolveString(key: TKey | Resource): string {
    return this.inner.resolveString(key);
  }

  resolveStringWithArgs(key: TKey | Resource, args: Array<string | number>): string {
    return this.inner.resolveStringWithArgs(key, args);
  }
}

export function createTypeSafeI18n<TKey extends string>(): ITypeSafeI18nManager<TKey> {
  return new TypeSafeI18nFacade<TKey>(ngfI18nManagerFacade);
}
