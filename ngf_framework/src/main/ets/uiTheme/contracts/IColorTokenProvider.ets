/**
 * 语义化颜色 Token 枚举
 */
export enum NGFColorToken {
  PRIMARY = 'primary',
  ON_PRIMARY = 'on_primary',
  PRIMARY_CONTAINER = 'primary_container',
  ON_PRIMARY_CONTAINER = 'on_primary_container',
  SECONDARY = 'secondary',
  ON_SECONDARY = 'on_secondary',
  SECONDARY_CONTAINER = 'secondary_container',
  ON_SECONDARY_CONTAINER = 'on_secondary_container',
  TERTIARY = 'tertiary',
  ON_TERTIARY = 'on_tertiary',
  SURFACE = 'surface',
  ON_SURFACE = 'on_surface',
  SURFACE_VARIANT = 'surface_variant',
  ON_SURFACE_VARIANT = 'on_surface_variant',
  BACKGROUND = 'background',
  ON_BACKGROUND = 'on_background',
  ERROR_COLOR = 'error',
  ON_ERROR = 'on_error',
  OUTLINE = 'outline',
  OUTLINE_VARIANT = 'outline_variant'
}

/**
 * 颜色值 (包含 light/dark 两个模式的值)
 */
export class NGFColorValue {
  readonly token: NGFColorToken;
  readonly light: string;
  readonly dark: string;

  constructor(token: NGFColorToken, light: string, dark: string) {
    this.token = token;
    this.light = light;
    this.dark = dark;
  }
}

/**
 * 颜色 Token 提供者接口
 */
export interface IColorTokenProvider {
  resolveColor(token: NGFColorToken): string;
  resolveColorValue(token: NGFColorToken): NGFColorValue;
  registerColor(value: NGFColorValue): void;
  registerDefaults(): void;
}
