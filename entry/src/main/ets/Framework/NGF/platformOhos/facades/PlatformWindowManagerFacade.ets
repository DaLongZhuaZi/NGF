import { window } from '@kit.ArkUI';
import { logger } from '../../utils/Logger';
import { NGFDisplayMode } from '../contracts/IPlatformWindowController';
import {
  IPlatformWindowManager,
  IPlatformWindowSnapshotObserver,
  NGFPageWindowProfile,
  NGFWindowAvoidAreaSnapshot,
  NGFWindowMonitorStorageKey,
  NGFWindowOrientationPreference,
  NGFWindowRectSnapshot,
  NGFWindowRuntimeSnapshot,
  NGFWindowStatus,
  NGFWindowSystemBarPolicy,
  NGFWindowSystemBarStyle,
  NGFWindowAvoidAreaType
} from '../contracts/IPlatformWindowManager';
import { ngfPageWindowPolicyResolverFacade } from './PageWindowPolicyResolverFacade';

const TAG: string = 'NGFPlatformWindowManagerFacade';

class NGFOhosSystemBarPropertiesAdapter implements window.SystemBarProperties {
  statusBarColor?: string;
  isStatusBarLightIcon?: boolean;
  statusBarContentColor?: string;
  navigationBarColor?: string;
  isNavigationBarLightIcon?: boolean;
  navigationBarContentColor?: string;
  enableStatusBarAnimation?: boolean;
  enableNavigationBarAnimation?: boolean;

  constructor(style: NGFWindowSystemBarStyle) {
    this.statusBarColor = style.statusBarColor;
    this.isStatusBarLightIcon = style.isStatusBarLightIcon;
    this.statusBarContentColor = style.statusBarContentColor;
    this.navigationBarColor = style.navigationBarColor;
    this.isNavigationBarLightIcon = style.isNavigationBarLightIcon;
    this.navigationBarContentColor = style.navigationBarContentColor;
    this.enableStatusBarAnimation = style.enableStatusBarAnimation;
    this.enableNavigationBarAnimation = style.enableNavigationBarAnimation;
  }
}

export class PlatformWindowManagerFacade implements IPlatformWindowManager {
  private static readonly MANUAL_PAGE_NAME: string = 'ngf.window.manual';
  private windowStage: window.WindowStage | null = null;
  private mainWindow: window.Window | null = null;
  private activePageName: string = '';
  private activeMode: NGFDisplayMode = NGFDisplayMode.DEFAULT;
  private pageProfiles: Map<string, NGFPageWindowProfile> = new Map<string, NGFPageWindowProfile>();
  private observers: Map<string, IPlatformWindowSnapshotObserver> = new Map<string, IPlatformWindowSnapshotObserver>();
  private snapshot: NGFWindowRuntimeSnapshot = new NGFWindowRuntimeSnapshot();
  private readonly windowSizeChangeCallback: Callback<window.Size> = (_size: window.Size): void => {
    this.refreshSnapshot('window_size_change');
  };
  private readonly avoidAreaChangeCallback: Callback<window.AvoidAreaOptions> =
    (_options: window.AvoidAreaOptions): void => {
      this.refreshSnapshot('avoid_area_change');
    };
  private readonly windowStatusChangeCallback: Callback<window.WindowStatusType> =
    (_status: window.WindowStatusType): void => {
      this.refreshSnapshot('window_status_change');
    };
  private readonly windowStageEventCallback: Callback<window.WindowStageEventType> =
    (eventType: window.WindowStageEventType): void => {
      logger.info(TAG, `窗口阶段事件: type=${String(eventType)}`);
      this.bindMainWindowFromStage('window_stage_event');
      this.refreshSnapshot('window_stage_event');
    };

  bindWindowStage(windowStage: window.WindowStage): void {
    if (this.windowStage === windowStage) {
      logger.debug(TAG, '绑定窗口阶段已跳过: 相同实例');
      this.bindMainWindowFromStage('bind_same_stage');
      this.refreshSnapshot('bind_same_stage');
      return;
    }

    this.unregisterWindowStageListeners();
    this.unregisterWindowListeners();
    this.windowStage = windowStage;
    this.registerWindowStageListeners(windowStage);
    this.bindMainWindowFromStage('bind_window_stage');
    if (this.activePageName.length > 0) {
      this.applyResolvedProfile(this.activePageName, 'bind_window_stage');
      return;
    }
    this.refreshSnapshot('bind_window_stage');
  }

  clearWindowStage(): void {
    this.unregisterWindowStageListeners();
    this.unregisterWindowListeners();
    this.windowStage = null;
    this.mainWindow = null;
    this.snapshot = new NGFWindowRuntimeSnapshot();
    this.snapshot.reason = 'clear_window_stage';
    this.snapshot.updatedAt = Date.now();
    this.syncSnapshotToStorage(this.snapshot);
    this.notifyObservers(this.snapshot);
    logger.info(TAG, '清除窗口阶段');
  }

  setDisplayMode(mode: NGFDisplayMode): void {
    this.activeMode = mode;
    const profile = this.buildFallbackProfile(
      this.activePageName.length > 0 ? this.activePageName : PlatformWindowManagerFacade.MANUAL_PAGE_NAME,
      mode
    );
    logger.info(TAG, `设置显示模式: mode=${mode}`);
    this.applyProfile(profile, 'manual_display_mode');
  }

  registerPageProfile(profile: NGFPageWindowProfile): void {
    this.pageProfiles.set(profile.pageName, profile.copy());
    logger.info(TAG, `注册页面配置: page=${profile.pageName}, mode=${profile.displayMode}`);
  }

  resolvePageProfile(pageName: string): NGFPageWindowProfile | null {
    const profile = this.pageProfiles.get(pageName);
    if (profile) {
      return profile.copy();
    }

    if (pageName === PlatformWindowManagerFacade.MANUAL_PAGE_NAME && this.activePageName === pageName) {
      return this.buildFallbackProfile(pageName, this.activeMode);
    }

    const resolvedSpec = ngfPageWindowPolicyResolverFacade.resolve(pageName);
    if (resolvedSpec) {
      return this.buildFallbackProfile(pageName, resolvedSpec.fallbackMode);
    }
    return this.buildFallbackProfile(pageName, NGFDisplayMode.DEFAULT);
  }

  activatePage(pageName: string): void {
    this.activePageName = pageName;
    this.applyResolvedProfile(pageName, 'activate_page');
  }

  reapplyActivePage(delayMs: number): void {
    if (this.activePageName.length <= 0) {
      logger.warn(TAG, '重新应用活跃页面已跳过: 无活跃页面');
      return;
    }

    if (delayMs <= 0) {
      this.applyResolvedProfile(this.activePageName, 'reapply_active_page');
      return;
    }

    setTimeout((): void => {
      this.applyResolvedProfile(this.activePageName, 'reapply_active_page_delayed');
    }, delayMs);
  }

  getActivePageName(): string {
    return this.activePageName;
  }

  getCurrentSnapshot(): NGFWindowRuntimeSnapshot {
    return this.snapshot.copy();
  }

  subscribe(listenerId: string, observer: IPlatformWindowSnapshotObserver): void {
    this.observers.set(listenerId, observer);
    logger.info(TAG, `订阅窗口观察者: listenerId=${listenerId}`);
    try {
      observer.onWindowSnapshotChanged(this.snapshot.copy());
    } catch (error) {
      logger.warn(
        TAG,
        `订阅观察者初始化失败: listenerId=${listenerId}, error=${this.errorToString(error as Object | string | number | boolean)}`
      );
    }
  }

  unsubscribe(listenerId: string): void {
    this.observers.delete(listenerId);
    logger.info(TAG, `取消订阅窗口观察者: listenerId=${listenerId}`);
  }

  isReady(): boolean {
    return this.mainWindow !== null;
  }

  private applyResolvedProfile(pageName: string, reason: string): void {
    const profile = this.resolvePageProfile(pageName);
    if (!profile) {
      logger.warn(TAG, `应用已解析配置未命中: page=${pageName}`);
      return;
    }
    this.applyProfile(profile, reason);
  }

  private applyProfile(profile: NGFPageWindowProfile, reason: string): void {
    this.activeMode = profile.displayMode;
    this.activePageName = profile.pageName;
    if (!this.mainWindow) {
      logger.warn(TAG, `应用配置已延迟: page=${profile.pageName}, 窗口未就绪`);
      this.refreshSnapshot(`${reason}_deferred`);
      return;
    }

    const currentWindow = this.mainWindow;
    try {
      let operation: Promise<void> = currentWindow.setWindowLayoutFullScreen(profile.layoutFullScreen);
      operation = operation.then((): Promise<void> => {
        return currentWindow.setSpecificSystemBarEnabled(
          'status',
          profile.systemBarPolicy.statusBarVisible,
          profile.systemBarPolicy.enableAnimation
        );
      });
      operation = operation.then((): Promise<void> => {
        return currentWindow.setSpecificSystemBarEnabled(
          'navigation',
          profile.systemBarPolicy.navigationBarVisible,
          profile.systemBarPolicy.enableAnimation
        );
      });
      operation = operation.then((): Promise<void> => {
        return currentWindow.setSpecificSystemBarEnabled(
          'navigationIndicator',
          profile.systemBarPolicy.navigationIndicatorVisible,
          profile.systemBarPolicy.enableAnimation
        );
      });
      if (profile.systemBarPolicy.style.enabled) {
        operation = operation.then((): Promise<void> => {
          return currentWindow.setWindowSystemBarProperties(
            new NGFOhosSystemBarPropertiesAdapter(profile.systemBarPolicy.style)
          );
        });
      }
      operation = operation.then((): Promise<void> => {
        return currentWindow.setPreferredOrientation(this.toOrientation(profile.orientation));
      });
      operation.then((): void => {
        logger.info(TAG, `应用配置成功: page=${profile.pageName}, mode=${profile.displayMode}`);
        this.refreshSnapshot(reason);
      }, (error: Object | string | number | boolean): void => {
        logger.error(TAG, `应用配置失败: page=${profile.pageName}, error=${this.errorToString(error)}`);
        this.refreshSnapshot(`${reason}_failed`);
      });
    } catch (error) {
      logger.error(
        TAG,
        `应用配置抛出异常: page=${profile.pageName}, error=${this.errorToString(error as Object | string | number | boolean)}`
      );
      this.refreshSnapshot(`${reason}_threw`);
    }
  }

  private bindMainWindowFromStage(reason: string): void {
    if (!this.windowStage) {
      logger.warn(TAG, '从阶段绑定主窗口已跳过: 无窗口阶段');
      return;
    }

    try {
      const nextWindow = this.windowStage.getMainWindowSync();
      if (this.mainWindow && this.mainWindow === nextWindow) {
        logger.debug(TAG, `从阶段绑定主窗口复用现有窗口: reason=${reason}`);
        return;
      }

      this.unregisterWindowListeners();
      this.mainWindow = nextWindow;
      this.registerWindowListeners(nextWindow);
      logger.info(TAG, `从阶段绑定主窗口成功: reason=${reason}`);
    } catch (error) {
      logger.error(
        TAG,
        `从阶段绑定主窗口失败: ${this.errorToString(error as Object | string | number | boolean)}`
      );
      this.mainWindow = null;
    }
  }

  private registerWindowStageListeners(windowStage: window.WindowStage): void {
    try {
      windowStage.on('windowStageEvent', this.windowStageEventCallback);
      logger.info(TAG, '注册窗口阶段事件监听器');
    } catch (error) {
      logger.warn(
        TAG,
        `注册窗口阶段监听器失败: ${this.errorToString(error as Object | string | number | boolean)}`
      );
    }
  }

  private unregisterWindowStageListeners(): void {
    if (!this.windowStage) {
      return;
    }
    try {
      this.windowStage.off('windowStageEvent', this.windowStageEventCallback);
      logger.info(TAG, '注销窗口阶段事件监听器');
    } catch (error) {
      logger.warn(
        TAG,
        `注销窗口阶段监听器失败: ${this.errorToString(error as Object | string | number | boolean)}`
      );
    }
  }

  private registerWindowListeners(mainWindow: window.Window): void {
    try {
      mainWindow.on('windowSizeChange', this.windowSizeChangeCallback);
    } catch (error) {
      logger.warn(TAG, `注册窗口大小变化监听失败: ${this.errorToString(error as Object | string | number | boolean)}`);
    }
    try {
      mainWindow.on('avoidAreaChange', this.avoidAreaChangeCallback);
    } catch (error) {
      logger.warn(TAG, `注册避让区域变化监听失败: ${this.errorToString(error as Object | string | number | boolean)}`);
    }
    try {
      mainWindow.on('windowStatusChange', this.windowStatusChangeCallback);
    } catch (error) {
      logger.warn(TAG, `注册窗口状态变化监听失败: ${this.errorToString(error as Object | string | number | boolean)}`);
    }
    logger.info(TAG, '注册窗口监听器完成');
  }

  private unregisterWindowListeners(): void {
    if (!this.mainWindow) {
      return;
    }
    try {
      this.mainWindow.off('windowSizeChange', this.windowSizeChangeCallback);
    } catch (error) {
      logger.warn(TAG, `注销窗口大小变化监听失败: ${this.errorToString(error as Object | string | number | boolean)}`);
    }
    try {
      this.mainWindow.off('avoidAreaChange', this.avoidAreaChangeCallback);
    } catch (error) {
      logger.warn(TAG, `注销避让区域变化监听失败: ${this.errorToString(error as Object | string | number | boolean)}`);
    }
    try {
      this.mainWindow.off('windowStatusChange', this.windowStatusChangeCallback);
    } catch (error) {
      logger.warn(TAG, `注销窗口状态变化监听失败: ${this.errorToString(error as Object | string | number | boolean)}`);
    }
  }

  private refreshSnapshot(reason: string): void {
    const nextSnapshot = new NGFWindowRuntimeSnapshot();
    nextSnapshot.activePageName = this.activePageName;
    nextSnapshot.displayMode = this.activeMode;
    nextSnapshot.reason = reason;
    nextSnapshot.updatedAt = Date.now();

    const profile = this.activePageName.length > 0 ? this.resolvePageProfile(this.activePageName) : null;
    if (profile) {
      nextSnapshot.orientation = profile.orientation;
      nextSnapshot.systemBarPolicy = profile.systemBarPolicy.copy();
    }

    const currentWindow = this.mainWindow;
    if (!currentWindow) {
      this.snapshot = nextSnapshot;
      this.syncSnapshotToStorage(nextSnapshot);
      this.notifyObservers(nextSnapshot);
      return;
    }

    nextSnapshot.isWindowReady = true;
    nextSnapshot.orientation = this.safeGetPreferredOrientation(currentWindow);
    nextSnapshot.status = this.safeGetWindowStatus(currentWindow);
    nextSnapshot.isFocused = this.safeIsFocused(currentWindow);
    nextSnapshot.isLayoutFullScreen = this.safeIsImmersiveLayout(currentWindow);

    const properties = this.safeGetWindowProperties(currentWindow);
    if (properties) {
      nextSnapshot.windowRect = this.toRectSnapshot(properties.windowRect);
      nextSnapshot.drawableRect = this.toRectSnapshot(properties.drawableRect);
      if (properties.globalDisplayRect) {
        nextSnapshot.globalDisplayRect = this.toRectSnapshot(properties.globalDisplayRect);
      }
      nextSnapshot.isFullScreen = properties.isFullScreen;
      nextSnapshot.isLayoutFullScreen = properties.isLayoutFullScreen;
      nextSnapshot.displayId = properties.displayId !== undefined ? properties.displayId : -1;
      nextSnapshot.windowId = properties.id;
      nextSnapshot.windowName = properties.name !== undefined ? properties.name : '';
    }

    const systemBarStyle = this.safeGetSystemBarStyle(currentWindow);
    if (systemBarStyle.enabled) {
      nextSnapshot.systemBarPolicy.style = systemBarStyle;
    }
    nextSnapshot.avoidAreas = this.collectAvoidAreas(currentWindow);

    this.snapshot = nextSnapshot;
    this.syncSnapshotToStorage(nextSnapshot);
    this.notifyObservers(nextSnapshot);
  }

  private safeGetWindowProperties(mainWindow: window.Window): window.WindowProperties | null {
    try {
      return mainWindow.getWindowProperties();
    } catch (error) {
      logger.warn(TAG, `获取窗口属性失败: ${this.errorToString(error as Object | string | number | boolean)}`);
      return null;
    }
  }

  private safeGetSystemBarStyle(mainWindow: window.Window): NGFWindowSystemBarStyle {
    const style = new NGFWindowSystemBarStyle();
    try {
      const properties = mainWindow.getWindowSystemBarProperties();
      style.enabled = true;
      style.statusBarColor = properties.statusBarColor ? properties.statusBarColor : '';
      style.statusBarContentColor = properties.statusBarContentColor ? properties.statusBarContentColor : '';
      style.navigationBarColor = properties.navigationBarColor ? properties.navigationBarColor : '';
      style.navigationBarContentColor = properties.navigationBarContentColor ? properties.navigationBarContentColor : '';
      style.isStatusBarLightIcon = properties.isStatusBarLightIcon ? properties.isStatusBarLightIcon : false;
      style.isNavigationBarLightIcon = properties.isNavigationBarLightIcon ? properties.isNavigationBarLightIcon : false;
      style.enableStatusBarAnimation = properties.enableStatusBarAnimation ? properties.enableStatusBarAnimation : false;
      style.enableNavigationBarAnimation =
        properties.enableNavigationBarAnimation ? properties.enableNavigationBarAnimation : false;
    } catch (error) {
      logger.warn(TAG, `获取窗口系统栏属性失败: ${this.errorToString(error as Object | string | number | boolean)}`);
    }
    return style;
  }

  private safeGetPreferredOrientation(mainWindow: window.Window): NGFWindowOrientationPreference {
    try {
      return this.fromOrientation(mainWindow.getPreferredOrientation());
    } catch (error) {
      logger.warn(TAG, `获取首选方向失败: ${this.errorToString(error as Object | string | number | boolean)}`);
      return NGFWindowOrientationPreference.UNSPECIFIED;
    }
  }

  private safeGetWindowStatus(mainWindow: window.Window): NGFWindowStatus {
    try {
      return this.fromWindowStatus(mainWindow.getWindowStatus());
    } catch (error) {
      logger.warn(TAG, `获取窗口状态失败: ${this.errorToString(error as Object | string | number | boolean)}`);
      return NGFWindowStatus.UNDEFINED;
    }
  }

  private safeIsFocused(mainWindow: window.Window): boolean {
    try {
      return mainWindow.isFocused();
    } catch (error) {
      logger.warn(TAG, `获取焦点状态失败: ${this.errorToString(error as Object | string | number | boolean)}`);
      return false;
    }
  }

  private safeIsImmersiveLayout(mainWindow: window.Window): boolean {
    try {
      return mainWindow.isImmersiveLayout();
    } catch (error) {
      logger.warn(TAG, `获取沉浸式布局状态失败: ${this.errorToString(error as Object | string | number | boolean)}`);
      return false;
    }
  }

  private collectAvoidAreas(mainWindow: window.Window): Array<NGFWindowAvoidAreaSnapshot> {
    const snapshots: Array<NGFWindowAvoidAreaSnapshot> = [];
    snapshots.push(this.safeGetAvoidArea(mainWindow, window.AvoidAreaType.TYPE_SYSTEM, NGFWindowAvoidAreaType.SYSTEM));
    snapshots.push(this.safeGetAvoidArea(mainWindow, window.AvoidAreaType.TYPE_CUTOUT, NGFWindowAvoidAreaType.CUTOUT));
    snapshots.push(
      this.safeGetAvoidArea(
        mainWindow,
        window.AvoidAreaType.TYPE_SYSTEM_GESTURE,
        NGFWindowAvoidAreaType.SYSTEM_GESTURE
      )
    );
    snapshots.push(this.safeGetAvoidArea(mainWindow, window.AvoidAreaType.TYPE_KEYBOARD, NGFWindowAvoidAreaType.KEYBOARD));
    snapshots.push(
      this.safeGetAvoidArea(
        mainWindow,
        window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR,
        NGFWindowAvoidAreaType.NAVIGATION_INDICATOR
      )
    );
    return snapshots;
  }

  private safeGetAvoidArea(
    mainWindow: window.Window,
    areaType: window.AvoidAreaType,
    snapshotType: NGFWindowAvoidAreaType
  ): NGFWindowAvoidAreaSnapshot {
    const snapshot = new NGFWindowAvoidAreaSnapshot(snapshotType);
    try {
      const area = mainWindow.getWindowAvoidArea(areaType);
      snapshot.visible = area.visible;
      snapshot.leftRect = this.toRectSnapshot(area.leftRect);
      snapshot.topRect = this.toRectSnapshot(area.topRect);
      snapshot.rightRect = this.toRectSnapshot(area.rightRect);
      snapshot.bottomRect = this.toRectSnapshot(area.bottomRect);
    } catch (error) {
      logger.warn(TAG, `获取窗口避让区域失败: type=${snapshotType}, error=${this.errorToString(error as Object | string | number | boolean)}`);
    }
    return snapshot;
  }

  private buildFallbackProfile(pageName: string, mode: NGFDisplayMode): NGFPageWindowProfile {
    const style = this.createDefaultStyleForMode(mode);
    const policy = this.createSystemBarPolicyForMode(mode, style);
    return new NGFPageWindowProfile(
      pageName,
      mode,
      NGFWindowOrientationPreference.UNSPECIFIED,
      this.isLayoutFullScreenMode(mode),
      policy,
      0
    );
  }

  private createDefaultStyleForMode(mode: NGFDisplayMode): NGFWindowSystemBarStyle {
    const style = new NGFWindowSystemBarStyle();
    style.enabled = true;
    style.enableStatusBarAnimation = true;
    style.enableNavigationBarAnimation = true;
    switch (mode) {
      case NGFDisplayMode.FULL_IMMERSIVE:
      case NGFDisplayMode.IMMERSIVE_WITH_BARS:
      case NGFDisplayMode.STATUS_SAFE_BOTTOM_IMMERSIVE:
        style.statusBarColor = '#00000000';
        style.navigationBarColor = '#00000000';
        style.statusBarContentColor = '#FFFFFFFF';
        style.navigationBarContentColor = '#FFFFFFFF';
        style.isStatusBarLightIcon = true;
        style.isNavigationBarLightIcon = true;
        return style;
      case NGFDisplayMode.DEFAULT:
      default:
        style.statusBarColor = '#FFF8FAFC';
        style.navigationBarColor = '#FFF8FAFC';
        style.statusBarContentColor = '#FF0F172A';
        style.navigationBarContentColor = '#FF0F172A';
        style.isStatusBarLightIcon = false;
        style.isNavigationBarLightIcon = false;
        return style;
    }
  }

  private createSystemBarPolicyForMode(mode: NGFDisplayMode, style: NGFWindowSystemBarStyle): NGFWindowSystemBarPolicy {
    switch (mode) {
      case NGFDisplayMode.FULL_IMMERSIVE:
        return new NGFWindowSystemBarPolicy(false, false, false, false, style);
      case NGFDisplayMode.IMMERSIVE_WITH_BARS:
        return new NGFWindowSystemBarPolicy(true, true, true, false, style);
      case NGFDisplayMode.STATUS_SAFE_BOTTOM_IMMERSIVE:
        return new NGFWindowSystemBarPolicy(true, false, false, false, style);
      case NGFDisplayMode.DEFAULT:
      default:
        return new NGFWindowSystemBarPolicy(true, true, true, false, style);
    }
  }

  private isLayoutFullScreenMode(mode: NGFDisplayMode): boolean {
    switch (mode) {
      case NGFDisplayMode.FULL_IMMERSIVE:
      case NGFDisplayMode.IMMERSIVE_WITH_BARS:
      case NGFDisplayMode.STATUS_SAFE_BOTTOM_IMMERSIVE:
        return true;
      case NGFDisplayMode.DEFAULT:
      default:
        return false;
    }
  }

  private toRectSnapshot(rect: window.Rect): NGFWindowRectSnapshot {
    return new NGFWindowRectSnapshot(rect.left, rect.top, rect.width, rect.height);
  }

  private toOrientation(preference: NGFWindowOrientationPreference): window.Orientation {
    switch (preference) {
      case NGFWindowOrientationPreference.PORTRAIT:
        return window.Orientation.PORTRAIT;
      case NGFWindowOrientationPreference.LANDSCAPE:
        return window.Orientation.LANDSCAPE;
      case NGFWindowOrientationPreference.UNSPECIFIED:
      default:
        return window.Orientation.UNSPECIFIED;
    }
  }

  private fromOrientation(orientation: window.Orientation): NGFWindowOrientationPreference {
    switch (orientation) {
      case window.Orientation.PORTRAIT:
      case window.Orientation.PORTRAIT_INVERTED:
      case window.Orientation.AUTO_ROTATION_PORTRAIT:
      case window.Orientation.USER_ROTATION_PORTRAIT:
      case window.Orientation.USER_ROTATION_PORTRAIT_INVERTED:
      case window.Orientation.AUTO_ROTATION_PORTRAIT_RESTRICTED:
        return NGFWindowOrientationPreference.PORTRAIT;
      case window.Orientation.LANDSCAPE:
      case window.Orientation.LANDSCAPE_INVERTED:
      case window.Orientation.AUTO_ROTATION_LANDSCAPE:
      case window.Orientation.USER_ROTATION_LANDSCAPE:
      case window.Orientation.USER_ROTATION_LANDSCAPE_INVERTED:
      case window.Orientation.AUTO_ROTATION_LANDSCAPE_RESTRICTED:
        return NGFWindowOrientationPreference.LANDSCAPE;
      case window.Orientation.UNSPECIFIED:
      case window.Orientation.AUTO_ROTATION:
      case window.Orientation.AUTO_ROTATION_RESTRICTED:
      case window.Orientation.AUTO_ROTATION_UNSPECIFIED:
      case window.Orientation.FOLLOW_DESKTOP:
      case window.Orientation.LOCKED:
      default:
        return NGFWindowOrientationPreference.UNSPECIFIED;
    }
  }

  private fromWindowStatus(status: window.WindowStatusType): NGFWindowStatus {
    switch (status) {
      case window.WindowStatusType.FULL_SCREEN:
        return NGFWindowStatus.FULL_SCREEN;
      case window.WindowStatusType.MAXIMIZE:
        return NGFWindowStatus.MAXIMIZE;
      case window.WindowStatusType.MINIMIZE:
        return NGFWindowStatus.MINIMIZE;
      case window.WindowStatusType.FLOATING:
        return NGFWindowStatus.FLOATING;
      case window.WindowStatusType.SPLIT_SCREEN:
        return NGFWindowStatus.SPLIT_SCREEN;
      case window.WindowStatusType.UNDEFINED:
      default:
        return NGFWindowStatus.UNDEFINED;
    }
  }

  private syncSnapshotToStorage(snapshot: NGFWindowRuntimeSnapshot): void {
    AppStorage.setOrCreate(NGFWindowMonitorStorageKey.READY, snapshot.isWindowReady);
    AppStorage.setOrCreate(NGFWindowMonitorStorageKey.ACTIVE_PAGE, snapshot.activePageName);
    AppStorage.setOrCreate(NGFWindowMonitorStorageKey.DISPLAY_MODE, snapshot.displayMode);
    AppStorage.setOrCreate(NGFWindowMonitorStorageKey.STATUS, snapshot.status);
    AppStorage.setOrCreate(NGFWindowMonitorStorageKey.UPDATED_AT, snapshot.updatedAt);
    AppStorage.setOrCreate(NGFWindowMonitorStorageKey.SNAPSHOT_JSON, this.serializeSnapshot(snapshot));
  }

  private notifyObservers(snapshot: NGFWindowRuntimeSnapshot): void {
    this.observers.forEach((observer: IPlatformWindowSnapshotObserver, listenerId: string) => {
      try {
        observer.onWindowSnapshotChanged(snapshot.copy());
      } catch (error) {
        logger.warn(TAG, `通知观察者失败: listenerId=${listenerId}, error=${this.errorToString(error as Object | string | number | boolean)}`);
      }
    });
  }

  private serializeSnapshot(snapshot: NGFWindowRuntimeSnapshot): string {
    try {
      const serialized = JSON.stringify(snapshot);
      if (serialized === undefined) {
        return '{}';
      }
      return serialized;
    } catch (error) {
      logger.warn(TAG, `序列化快照失败: ${this.errorToString(error as Object | string | number | boolean)}`);
      return '{}';
    }
  }

  private errorToString(error: Object | string | number | boolean): string {
    if (typeof error === 'string') {
      return error;
    }
    if (typeof error === 'number' || typeof error === 'boolean') {
      return String(error);
    }
    if (error instanceof Error) {
      return error.message;
    }
    return String(error);
  }
}

export const ngfPlatformWindowManagerFacade = new PlatformWindowManagerFacade();
