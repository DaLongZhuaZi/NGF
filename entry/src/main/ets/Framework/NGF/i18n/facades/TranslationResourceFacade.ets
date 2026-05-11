import { logger } from '../../utils/Logger';
import {
  ITranslationResource,
  NGFMissingKeyReport,
  NGFTranslationLoadResult
} from '../contracts/ITranslationResource';
import { ngfI18nManagerFacade } from './I18nManagerFacade';

const TAG: string = 'NGFTranslationResourceFacade';

export class TranslationResourceFacade implements ITranslationResource {
  private readonly translations: Map<string, Map<string, string>> = new Map<string, Map<string, string>>();
  private readonly missingKeys: Array<NGFMissingKeyReport> = [];
  private readonly reportedMissingKeys: Set<string> = new Set<string>();

  loadTranslations(locale: string, jsonContent: string): NGFTranslationLoadResult {
    const normalizedLocale = locale.trim();
    if (normalizedLocale.length <= 0) {
      logger.warn(TAG, '加载翻译忽略: locale 为空');
      return new NGFTranslationLoadResult('', 0, false);
    }

    try {
      const parsed = JSON.parse(jsonContent) as object;
      const entries = Object.entries(parsed) as [string, string][];
      const localeMap = new Map<string, string>();
      for (let index = 0; index < entries.length; index++) {
        const entry = entries[index];
        localeMap.set(entry[0], entry[1]);
      }
      this.translations.set(normalizedLocale, localeMap);
      logger.info(TAG, `加载翻译资源: locale=${normalizedLocale}, keys=${localeMap.size}`);
      return new NGFTranslationLoadResult(normalizedLocale, localeMap.size, true);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `加载翻译资源失败: locale=${normalizedLocale}, error=${message}`);
      return new NGFTranslationLoadResult(normalizedLocale, 0, false);
    }
  }

  unloadTranslations(locale: string): void {
    const normalizedLocale = locale.trim();
    if (this.translations.has(normalizedLocale)) {
      this.translations.delete(normalizedLocale);
      logger.info(TAG, `卸载翻译资源: locale=${normalizedLocale}`);
    }
  }

  translate(key: string, defaultValue: string): string {
    const normalizedKey = key.trim();
    if (normalizedKey.length <= 0) {
      return '';
    }

    const currentLocale = ngfI18nManagerFacade.getCurrentLocale();
    const value = this.resolveFromLocale(currentLocale, normalizedKey);
    if (value !== null) {
      return value;
    }

    const baseLocale = this.extractBaseLocale(currentLocale);
    if (baseLocale !== currentLocale) {
      const baseValue = this.resolveFromLocale(baseLocale, normalizedKey);
      if (baseValue !== null) {
        return baseValue;
      }
    }

    this.reportMissing(normalizedKey, currentLocale);

    if (defaultValue.length > 0) {
      return defaultValue;
    }
    return normalizedKey;
  }

  hasKey(key: string): boolean {
    const normalizedKey = key.trim();
    if (normalizedKey.length <= 0) {
      return false;
    }
    const currentLocale = ngfI18nManagerFacade.getCurrentLocale();
    if (this.resolveFromLocale(currentLocale, normalizedKey) !== null) {
      return true;
    }
    const baseLocale = this.extractBaseLocale(currentLocale);
    return this.resolveFromLocale(baseLocale, normalizedKey) !== null;
  }

  listLocales(): Array<string> {
    const locales: Array<string> = [];
    const keys = this.translations.keys();
    for (const key of keys) {
      locales.push(key);
    }
    return locales;
  }

  getMissingKeys(): Array<NGFMissingKeyReport> {
    const copied: Array<NGFMissingKeyReport> = [];
    for (let index = 0; index < this.missingKeys.length; index++) {
      copied.push(this.missingKeys[index]);
    }
    return copied;
  }

  clearMissingKeys(): void {
    this.missingKeys.length = 0;
    this.reportedMissingKeys.clear();
    logger.info(TAG, '清除缺失键报告');
  }

  private resolveFromLocale(locale: string, key: string): string | null {
    const localeMap = this.translations.get(locale);
    if (localeMap === undefined) {
      return null;
    }
    const value = localeMap.get(key);
    return value !== undefined ? value : null;
  }

  private extractBaseLocale(locale: string): string {
    const dashIndex = locale.indexOf('-');
    if (dashIndex > 0) {
      return locale.substring(0, dashIndex);
    }
    return locale;
  }

  private reportMissing(key: string, locale: string): void {
    const reportKey = `${locale}:${key}`;
    if (this.reportedMissingKeys.has(reportKey)) {
      return;
    }
    this.reportedMissingKeys.add(reportKey);
    this.missingKeys.push(new NGFMissingKeyReport(key, locale, Date.now()));
    logger.debug(TAG, `缺失翻译键: key=${key}, locale=${locale}`);
  }
}

export const ngfTranslationResourceFacade: TranslationResourceFacade = new TranslationResourceFacade();
