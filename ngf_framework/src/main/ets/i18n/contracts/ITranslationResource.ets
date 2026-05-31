/**
 * 翻译资源加载结果
 */
export class NGFTranslationLoadResult {
  readonly locale: string;
  readonly keyCount: number;
  readonly success: boolean;

  constructor(locale: string, keyCount: number, success: boolean) {
    this.locale = locale;
    this.keyCount = keyCount;
    this.success = success;
  }
}

/**
 * 缺失键报告
 */
export class NGFMissingKeyReport {
  readonly key: string;
  readonly locale: string;
  readonly timestamp: number;

  constructor(key: string, locale: string, timestamp: number) {
    this.key = key;
    this.locale = locale;
    this.timestamp = timestamp;
  }
}

/**
 * 翻译资源管理接口
 */
export interface ITranslationResource {
  loadTranslations(locale: string, jsonContent: string): NGFTranslationLoadResult;
  unloadTranslations(locale: string): void;
  translate(key: string, defaultValue: string): string;
  hasKey(key: string): boolean;
  listLocales(): Array<string>;
  getMissingKeys(): Array<NGFMissingKeyReport>;
  clearMissingKeys(): void;
}
