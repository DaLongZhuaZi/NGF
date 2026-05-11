/**
 * 相对时间单位
 */
export enum NGFRelativeTimeUnit {
  SECOND = 'second',
  MINUTE = 'minute',
  HOUR = 'hour',
  DAY = 'day',
  WEEK = 'week',
  MONTH = 'month',
  YEAR = 'year'
}

/**
 * 相对时间格式化结果
 */
export class NGFRelativeTimeResult {
  readonly value: number;
  readonly unit: NGFRelativeTimeUnit;
  readonly text: string;
  readonly isPast: boolean;

  constructor(value: number, unit: NGFRelativeTimeUnit, text: string, isPast: boolean) {
    this.value = value;
    this.unit = unit;
    this.text = text;
    this.isPast = isPast;
  }
}

/**
 * 相对时间格式化器接口
 */
export interface IRelativeTimeFormatter {
  format(timestamp: number, locale?: string): NGFRelativeTimeResult;
  formatToText(timestamp: number, locale?: string): string;
  addLocaleStrings(locale: string, strings: Map<string, Array<string>>): void;
}
