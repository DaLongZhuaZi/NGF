export enum NGFThemeMode {
  LIGHT = 'light',
  DARK = 'dark',
  AUTO = 'auto'
}

export class NGFThemePack {
  name: string;
  primaryColor: string;
  backgroundColor: string;
  textColor: string;
  accentColor: string;

  constructor(
    name: string,
    primaryColor: string,
    backgroundColor: string,
    textColor: string,
    accentColor: string
  ) {
    this.name = name;
    this.primaryColor = primaryColor;
    this.backgroundColor = backgroundColor;
    this.textColor = textColor;
    this.accentColor = accentColor;
  }
}

export interface IThemeManager {
  getCurrentTheme(): NGFThemeMode;
  setThemeOverride(mode: NGFThemeMode): void;
  clearThemeOverride(): void;
  isDarkMode(): boolean;
  onThemeChanged(callback: (mode: NGFThemeMode) => void): void;
  offThemeChanged(callback: (mode: NGFThemeMode) => void): void;
  loadThemePack(pack: NGFThemePack): void;
  applyThemePack(): void;
}
