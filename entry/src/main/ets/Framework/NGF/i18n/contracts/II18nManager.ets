export enum NGFNumberStyle {
  DECIMAL = 'decimal',
  PERCENT = 'percent',
  CURRENCY = 'currency'
}

export enum NGFDateStyle {
  SHORT = 'short',
  MEDIUM = 'medium',
  LONG = 'long',
  FULL = 'full'
}

export interface II18nManager {
  getCurrentLocale(): string;
  setLocaleOverride(locale: string): void;
  clearLocaleOverride(): void;
  resolveString(key: string): string;
  resolveStringWithArgs(key: string, args: Array<string | number>): string;
  formatDate(date: Date, style: NGFDateStyle): string;
  formatNumber(value: number, style: NGFNumberStyle): string;
  onLocaleChanged(callback: (locale: string) => void): void;
  offLocaleChanged(callback: (locale: string) => void): void;
}
