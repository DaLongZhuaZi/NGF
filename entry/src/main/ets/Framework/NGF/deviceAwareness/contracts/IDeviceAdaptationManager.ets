export enum NGFDeviceType {
  PHONE = 'phone',
  TABLET = 'tablet',
  FOLDABLE = 'foldable',
  TWO_IN_ONE = 'two_in_one'
}

export enum NGFScreenOrientation {
  PORTRAIT = 'portrait',
  LANDSCAPE = 'landscape'
}

export enum NGFBreakpoint {
  XS = 'xs',
  SM = 'sm',
  MD = 'md',
  LG = 'lg'
}

export enum NGFFoldStatus {
  UNKNOWN = 0,
  EXPANDED = 1,
  FOLDED = 2,
  HALF_FOLDED = 3
}

export interface NGFDeviceInfo {
  deviceType: NGFDeviceType;
  orientation: NGFScreenOrientation;
  breakpoint: NGFBreakpoint;
  screenWidth: number;
  screenHeight: number;
  screenWidthPx: number;
  screenHeightPx: number;
  density: number;
  isTablet: boolean;
  isFoldable: boolean;
  foldStatus: NGFFoldStatus;
  isLandscape: boolean;
}

export type NGFDeviceChangeListener = (deviceInfo: NGFDeviceInfo) => void;

export interface IDeviceAdaptationManager {
  getDeviceInfo(): NGFDeviceInfo;
  addListener(listener: NGFDeviceChangeListener): void;
  removeListener(listener: NGFDeviceChangeListener): void;
  isPhonePortrait(): boolean;
  isTabletOrLarger(): boolean;
  isLandscape(): boolean;
  getCurrentBreakpoint(): NGFBreakpoint;
  isBreakpointGreaterOrEqual(targetBreakpoint: NGFBreakpoint): boolean;
  destroy(): void;
}
