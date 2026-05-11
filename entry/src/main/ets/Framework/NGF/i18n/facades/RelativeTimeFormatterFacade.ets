import { logger } from '../../utils/Logger';
import { ngfI18nManagerFacade } from './I18nManagerFacade';
import {
  IRelativeTimeFormatter,
  NGFRelativeTimeResult,
  NGFRelativeTimeUnit
} from '../contracts/IRelativeTimeFormatter';

const TAG: string = 'NGFRelativeTimeFormatterFacade';

class RelativeTimeThreshold {
  readonly unit: NGFRelativeTimeUnit;
  readonly ms: number;

  constructor(unit: NGFRelativeTimeUnit, ms: number) {
    this.unit = unit;
    this.ms = ms;
  }
}

const THRESHOLDS: Array<RelativeTimeThreshold> = [
  new RelativeTimeThreshold(NGFRelativeTimeUnit.YEAR, 365 * 24 * 60 * 60 * 1000),
  new RelativeTimeThreshold(NGFRelativeTimeUnit.MONTH, 30 * 24 * 60 * 60 * 1000),
  new RelativeTimeThreshold(NGFRelativeTimeUnit.WEEK, 7 * 24 * 60 * 60 * 1000),
  new RelativeTimeThreshold(NGFRelativeTimeUnit.DAY, 24 * 60 * 60 * 1000),
  new RelativeTimeThreshold(NGFRelativeTimeUnit.HOUR, 60 * 60 * 1000),
  new RelativeTimeThreshold(NGFRelativeTimeUnit.MINUTE, 60 * 1000),
  new RelativeTimeThreshold(NGFRelativeTimeUnit.SECOND, 1000)
];

const DEFAULT_LOCALE: string = 'zh-CN';

export class RelativeTimeFormatterFacade implements IRelativeTimeFormatter {
  private readonly localeStrings: Map<string, Map<string, Array<string>>> = new Map<string, Map<string, Array<string>>>();

  constructor() {
    this.registerBuiltInLocales();
  }

  format(timestamp: number, locale?: string): NGFRelativeTimeResult {
    const resolvedLocale = locale !== undefined ? locale : ngfI18nManagerFacade.getCurrentLocale();
    const now = Date.now();
    const diff = now - timestamp;
    const isPast = diff >= 0;
    const absDiff = isPast ? diff : -diff;

    if (absDiff < 1000) {
      const text = this.getPluralString(resolvedLocale, 'just_now', 0);
      return new NGFRelativeTimeResult(0, NGFRelativeTimeUnit.SECOND, text, isPast);
    }

    for (let index = 0; index < THRESHOLDS.length; index++) {
      const threshold = THRESHOLDS[index];
      const value = Math.floor(absDiff / threshold.ms);
      if (value >= 1) {
        const key = isPast ? `${threshold.unit}_ago` : `${threshold.unit}_later`;
        const text = this.getPluralString(resolvedLocale, key, value);
        return new NGFRelativeTimeResult(value, threshold.unit, text, isPast);
      }
    }

    const text = this.getPluralString(resolvedLocale, 'just_now', 0);
    return new NGFRelativeTimeResult(0, NGFRelativeTimeUnit.SECOND, text, isPast);
  }

  formatToText(timestamp: number, locale?: string): string {
    return this.format(timestamp, locale).text;
  }

  addLocaleStrings(locale: string, strings: Map<string, Array<string>>): void {
    this.localeStrings.set(locale, strings);
    logger.info(TAG, `添加语言字符串: locale=${locale}, keys=${strings.size}`);
  }

  private getPluralString(locale: string, key: string, count: number): string {
    const strings = this.resolveLocaleStrings(locale);
    const forms = strings.get(key);
    if (forms === undefined) {
      return `${count} ${key}`;
    }
    const pluralIndex = this.getPluralIndex(locale, count);
    if (pluralIndex < forms.length) {
      const template = forms[pluralIndex];
      return this.replaceCount(template, count);
    }
    if (forms.length > 0) {
      return this.replaceCount(forms[0], count);
    }
    return `${count} ${key}`;
  }

  private resolveLocaleStrings(locale: string): Map<string, Array<string>> {
    const exact = this.localeStrings.get(locale);
    if (exact !== undefined) {
      return exact;
    }
    const baseLocale = locale.split('-')[0];
    const base = this.localeStrings.get(baseLocale);
    if (base !== undefined) {
      return base;
    }
    const fallback = this.localeStrings.get(DEFAULT_LOCALE);
    if (fallback !== undefined) {
      return fallback;
    }
    return new Map<string, Array<string>>();
  }

  private getPluralIndex(locale: string, count: number): number {
    const baseLocale = locale.split('-')[0];
    if (baseLocale === 'zh' || baseLocale === 'ja' || baseLocale === 'ko') {
      return 0;
    }
    if (count === 1) {
      return 0;
    }
    return 1;
  }

  private replaceCount(template: string, count: number): string {
    const countStr = String(count);
    let result = '';
    for (let i = 0; i < template.length; i++) {
      if (template[i] === '{' && i + 1 < template.length && template[i + 1] === '}') {
        result += countStr;
        i += 1;
      } else {
        result += template[i];
      }
    }
    return result;
  }

  private registerBuiltInLocales(): void {
    const zhStrings = new Map<string, Array<string>>();
    zhStrings.set('just_now', ['刚刚']);
    zhStrings.set('second_ago', ['{}秒前']);
    zhStrings.set('minute_ago', ['{}分钟前']);
    zhStrings.set('hour_ago', ['{}小时前']);
    zhStrings.set('day_ago', ['{}天前']);
    zhStrings.set('week_ago', ['{}周前']);
    zhStrings.set('month_ago', ['{}个月前']);
    zhStrings.set('year_ago', ['{}年前']);
    zhStrings.set('second_later', ['{}秒后']);
    zhStrings.set('minute_later', ['{}分钟后']);
    zhStrings.set('hour_later', ['{}小时后']);
    zhStrings.set('day_later', ['{}天后']);
    zhStrings.set('week_later', ['{}周后']);
    zhStrings.set('month_later', ['{}个月后']);
    zhStrings.set('year_later', ['{}年后']);
    this.localeStrings.set('zh-CN', zhStrings);
    this.localeStrings.set('zh', zhStrings);

    const enStrings = new Map<string, Array<string>>();
    enStrings.set('just_now', ['just now']);
    enStrings.set('second_ago', ['{} second ago', '{} seconds ago']);
    enStrings.set('minute_ago', ['{} minute ago', '{} minutes ago']);
    enStrings.set('hour_ago', ['{} hour ago', '{} hours ago']);
    enStrings.set('day_ago', ['{} day ago', '{} days ago']);
    enStrings.set('week_ago', ['{} week ago', '{} weeks ago']);
    enStrings.set('month_ago', ['{} month ago', '{} months ago']);
    enStrings.set('year_ago', ['{} year ago', '{} years ago']);
    enStrings.set('second_later', ['in {} second', 'in {} seconds']);
    enStrings.set('minute_later', ['in {} minute', 'in {} minutes']);
    enStrings.set('hour_later', ['in {} hour', 'in {} hours']);
    enStrings.set('day_later', ['in {} day', 'in {} days']);
    enStrings.set('week_later', ['in {} week', 'in {} weeks']);
    enStrings.set('month_later', ['in {} month', 'in {} months']);
    enStrings.set('year_later', ['in {} year', 'in {} years']);
    this.localeStrings.set('en-US', enStrings);
    this.localeStrings.set('en', enStrings);

    const jaStrings = new Map<string, Array<string>>();
    jaStrings.set('just_now', ['たった今']);
    jaStrings.set('second_ago', ['{}秒前']);
    jaStrings.set('minute_ago', ['{}分前']);
    jaStrings.set('hour_ago', ['{}時間前']);
    jaStrings.set('day_ago', ['{}日前']);
    jaStrings.set('week_ago', ['{}週間前']);
    jaStrings.set('month_ago', ['{}ヶ月前']);
    jaStrings.set('year_ago', ['{}年前']);
    jaStrings.set('second_later', ['{}秒後']);
    jaStrings.set('minute_later', ['{}分後']);
    jaStrings.set('hour_later', ['{}時間後']);
    jaStrings.set('day_later', ['{}日後']);
    jaStrings.set('week_later', ['{}週間後']);
    jaStrings.set('month_later', ['{}ヶ月後']);
    jaStrings.set('year_later', ['{}年後']);
    this.localeStrings.set('ja', jaStrings);
    this.localeStrings.set('ja-JP', jaStrings);

    logger.info(TAG, '内置语言字符串已注册: zh, en, ja');
  }
}

export const ngfRelativeTimeFormatterFacade: RelativeTimeFormatterFacade = new RelativeTimeFormatterFacade();
