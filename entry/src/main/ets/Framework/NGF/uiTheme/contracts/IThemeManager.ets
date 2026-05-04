export enum NGFThemeMode {
  LIGHT = 'light',
  DARK = 'dark',
  AUTO = 'auto'
}

export interface IThemeManager {
  getCurrentTheme(): NGFThemeMode;
  setThemeOverride(mode: NGFThemeMode): void;
  clearThemeOverride(): void;
  isDarkMode(): boolean;
  onThemeChanged(callback: (mode: NGFThemeMode) => void): void;
  offThemeChanged(callback: (mode: NGFThemeMode) => void): void;
}
