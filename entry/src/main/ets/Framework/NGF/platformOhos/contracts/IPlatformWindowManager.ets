import { window } from '@kit.ArkUI';
import { NGFDisplayMode } from './IPlatformWindowController';

export enum NGFWindowOrientationPreference {
  UNSPECIFIED = 'unspecified',
  PORTRAIT = 'portrait',
  LANDSCAPE = 'landscape'
}

export enum NGFWindowStatus {
  UNDEFINED = 'undefined',
  FULL_SCREEN = 'full_screen',
  MAXIMIZE = 'maximize',
  MINIMIZE = 'minimize',
  FLOATING = 'floating',
  SPLIT_SCREEN = 'split_screen'
}

export enum NGFWindowAvoidAreaType {
  SYSTEM = 'system',
  CUTOUT = 'cutout',
  SYSTEM_GESTURE = 'system_gesture',
  KEYBOARD = 'keyboard',
  NAVIGATION_INDICATOR = 'navigation_indicator'
}

export class NGFWindowMonitorStorageKey {
  static readonly READY: string = 'ngf_window_ready';
  static readonly ACTIVE_PAGE: string = 'ngf_window_active_page';
  static readonly DISPLAY_MODE: string = 'ngf_window_display_mode';
  static readonly STATUS: string = 'ngf_window_status';
  static readonly SNAPSHOT_JSON: string = 'ngf_window_snapshot_json';
  static readonly UPDATED_AT: string = 'ngf_window_snapshot_updated_at';
}

export class NGFWindowRectSnapshot {
  left: number;
  top: number;
  width: number;
  height: number;

  constructor(left: number = 0, top: number = 0, width: number = 0, height: number = 0) {
    this.left = left;
    this.top = top;
    this.width = width;
    this.height = height;
  }

  copy(): NGFWindowRectSnapshot {
    return new NGFWindowRectSnapshot(this.left, this.top, this.width, this.height);
  }
}

export class NGFWindowAvoidAreaSnapshot {
  type: NGFWindowAvoidAreaType;
  visible: boolean;
  leftRect: NGFWindowRectSnapshot;
  topRect: NGFWindowRectSnapshot;
  rightRect: NGFWindowRectSnapshot;
  bottomRect: NGFWindowRectSnapshot;

  constructor(type: NGFWindowAvoidAreaType) {
    this.type = type;
    this.visible = false;
    this.leftRect = new NGFWindowRectSnapshot();
    this.topRect = new NGFWindowRectSnapshot();
    this.rightRect = new NGFWindowRectSnapshot();
    this.bottomRect = new NGFWindowRectSnapshot();
  }

  copy(): NGFWindowAvoidAreaSnapshot {
    const snapshot = new NGFWindowAvoidAreaSnapshot(this.type);
    snapshot.visible = this.visible;
    snapshot.leftRect = this.leftRect.copy();
    snapshot.topRect = this.topRect.copy();
    snapshot.rightRect = this.rightRect.copy();
    snapshot.bottomRect = this.bottomRect.copy();
    return snapshot;
  }
}

export class NGFWindowSystemBarStyle {
  enabled: boolean;
  statusBarColor: string;
  statusBarContentColor: string;
  navigationBarColor: string;
  navigationBarContentColor: string;
  isStatusBarLightIcon: boolean;
  isNavigationBarLightIcon: boolean;
  enableStatusBarAnimation: boolean;
  enableNavigationBarAnimation: boolean;

  constructor() {
    this.enabled = false;
    this.statusBarColor = '';
    this.statusBarContentColor = '';
    this.navigationBarColor = '';
    this.navigationBarContentColor = '';
    this.isStatusBarLightIcon = false;
    this.isNavigationBarLightIcon = false;
    this.enableStatusBarAnimation = false;
    this.enableNavigationBarAnimation = false;
  }

  copy(): NGFWindowSystemBarStyle {
    const style = new NGFWindowSystemBarStyle();
    style.enabled = this.enabled;
    style.statusBarColor = this.statusBarColor;
    style.statusBarContentColor = this.statusBarContentColor;
    style.navigationBarColor = this.navigationBarColor;
    style.navigationBarContentColor = this.navigationBarContentColor;
    style.isStatusBarLightIcon = this.isStatusBarLightIcon;
    style.isNavigationBarLightIcon = this.isNavigationBarLightIcon;
    style.enableStatusBarAnimation = this.enableStatusBarAnimation;
    style.enableNavigationBarAnimation = this.enableNavigationBarAnimation;
    return style;
  }
}

export class NGFWindowSystemBarPolicy {
  statusBarVisible: boolean;
  navigationBarVisible: boolean;
  navigationIndicatorVisible: boolean;
  enableAnimation: boolean;
  style: NGFWindowSystemBarStyle;

  constructor(
    statusBarVisible: boolean,
    navigationBarVisible: boolean,
    navigationIndicatorVisible: boolean,
    enableAnimation: boolean,
    style: NGFWindowSystemBarStyle
  ) {
    this.statusBarVisible = statusBarVisible;
    this.navigationBarVisible = navigationBarVisible;
    this.navigationIndicatorVisible = navigationIndicatorVisible;
    this.enableAnimation = enableAnimation;
    this.style = style;
  }

  copy(): NGFWindowSystemBarPolicy {
    return new NGFWindowSystemBarPolicy(
      this.statusBarVisible,
      this.navigationBarVisible,
      this.navigationIndicatorVisible,
      this.enableAnimation,
      this.style.copy()
    );
  }
}

export class NGFPageWindowProfile {
  pageName: string;
  displayMode: NGFDisplayMode;
  orientation: NGFWindowOrientationPreference;
  layoutFullScreen: boolean;
  systemBarPolicy: NGFWindowSystemBarPolicy;
  reapplyDelayMs: number;

  constructor(
    pageName: string,
    displayMode: NGFDisplayMode,
    orientation: NGFWindowOrientationPreference,
    layoutFullScreen: boolean,
    systemBarPolicy: NGFWindowSystemBarPolicy,
    reapplyDelayMs: number
  ) {
    this.pageName = pageName;
    this.displayMode = displayMode;
    this.orientation = orientation;
    this.layoutFullScreen = layoutFullScreen;
    this.systemBarPolicy = systemBarPolicy;
    this.reapplyDelayMs = reapplyDelayMs;
  }

  copy(): NGFPageWindowProfile {
    return new NGFPageWindowProfile(
      this.pageName,
      this.displayMode,
      this.orientation,
      this.layoutFullScreen,
      this.systemBarPolicy.copy(),
      this.reapplyDelayMs
    );
  }
}

export class NGFWindowRuntimeSnapshot {
  activePageName: string;
  displayMode: NGFDisplayMode;
  orientation: NGFWindowOrientationPreference;
  status: NGFWindowStatus;
  isWindowReady: boolean;
  isFocused: boolean;
  isFullScreen: boolean;
  isLayoutFullScreen: boolean;
  displayId: number;
  windowId: number;
  windowName: string;
  windowRect: NGFWindowRectSnapshot;
  drawableRect: NGFWindowRectSnapshot;
  globalDisplayRect: NGFWindowRectSnapshot;
  systemBarPolicy: NGFWindowSystemBarPolicy;
  avoidAreas: Array<NGFWindowAvoidAreaSnapshot>;
  updatedAt: number;
  reason: string;

  constructor() {
    this.activePageName = '';
    this.displayMode = NGFDisplayMode.DEFAULT;
    this.orientation = NGFWindowOrientationPreference.UNSPECIFIED;
    this.status = NGFWindowStatus.UNDEFINED;
    this.isWindowReady = false;
    this.isFocused = false;
    this.isFullScreen = false;
    this.isLayoutFullScreen = false;
    this.displayId = -1;
    this.windowId = -1;
    this.windowName = '';
    this.windowRect = new NGFWindowRectSnapshot();
    this.drawableRect = new NGFWindowRectSnapshot();
    this.globalDisplayRect = new NGFWindowRectSnapshot();
    this.systemBarPolicy = new NGFWindowSystemBarPolicy(true, true, true, false, new NGFWindowSystemBarStyle());
    this.avoidAreas = [];
    this.updatedAt = 0;
    this.reason = 'init';
  }

  copy(): NGFWindowRuntimeSnapshot {
    const snapshot = new NGFWindowRuntimeSnapshot();
    snapshot.activePageName = this.activePageName;
    snapshot.displayMode = this.displayMode;
    snapshot.orientation = this.orientation;
    snapshot.status = this.status;
    snapshot.isWindowReady = this.isWindowReady;
    snapshot.isFocused = this.isFocused;
    snapshot.isFullScreen = this.isFullScreen;
    snapshot.isLayoutFullScreen = this.isLayoutFullScreen;
    snapshot.displayId = this.displayId;
    snapshot.windowId = this.windowId;
    snapshot.windowName = this.windowName;
    snapshot.windowRect = this.windowRect.copy();
    snapshot.drawableRect = this.drawableRect.copy();
    snapshot.globalDisplayRect = this.globalDisplayRect.copy();
    snapshot.systemBarPolicy = this.systemBarPolicy.copy();
    const nextAreas: Array<NGFWindowAvoidAreaSnapshot> = [];
    for (let index = 0; index < this.avoidAreas.length; index++) {
      nextAreas.push(this.avoidAreas[index].copy());
    }
    snapshot.avoidAreas = nextAreas;
    snapshot.updatedAt = this.updatedAt;
    snapshot.reason = this.reason;
    return snapshot;
  }
}

export interface IPlatformWindowSnapshotObserver {
  onWindowSnapshotChanged(snapshot: NGFWindowRuntimeSnapshot): void;
}

export interface IPlatformWindowManager {
  bindWindowStage(windowStage: window.WindowStage): void;
  clearWindowStage(): void;
  setDisplayMode(mode: NGFDisplayMode): void;
  registerPageProfile(profile: NGFPageWindowProfile): void;
  resolvePageProfile(pageName: string): NGFPageWindowProfile | null;
  activatePage(pageName: string): void;
  reapplyActivePage(delayMs: number): void;
  getActivePageName(): string;
  getCurrentSnapshot(): NGFWindowRuntimeSnapshot;
  subscribe(listenerId: string, observer: IPlatformWindowSnapshotObserver): void;
  unsubscribe(listenerId: string): void;
  isReady(): boolean;
}
