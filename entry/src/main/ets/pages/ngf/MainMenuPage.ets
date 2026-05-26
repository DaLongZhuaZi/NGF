import { hdsEffect, hdsMaterial, HdsNavigation, HdsNavigationTitleMode, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';
import window from '@ohos.window';
import { uiContextManager } from '../../Framework/NGF/platformOhos/UIContextManager';
import { resolveResourceString } from '../../Framework/NGF/i18n/index';
import { NGFErrorContext, NGFErrorSeverity } from '../../Framework/NGF/core/contracts/IErrorHandler';
import { NGFEventPayload } from '../../Framework/NGF/core/contracts/IEventBus';
import { NGFLogLevel } from '../../Framework/NGF/core/contracts/ILogger';
import { NGFPhaseState } from '../../Framework/NGF/core/contracts/ILifecycleOrchestrator';
import {
  NGFFrameworkRuntimeSnapshot,
  NGFModuleBootstrapReport,
  NGFModuleRuntimeSnapshot
} from '../../Framework/NGF/core/contracts/IModuleBootstrap';
import { NGFStarterEventName, ngfStarterKernel } from '../../Framework/NGF/core/starter/index';
import { HdsIntegratedShowcasePage } from './HdsIntegratedShowcasePage';
import {
  HdsNavigationOfficialEffectPage,
  HdsNavigationOfficialMaterialPage,
  HdsNavigationOfficialOverviewPage,
  HdsNavigationOfficialShowcasePage
} from './HdsNavigationOfficialShowcasePage';
import { NGFHdsDemoRouteName } from './HdsDemoRoutes';
import { NGFHdsTitleBarOptionsFactory } from '../../Framework/NGF/uiShell/components/HdsNavigationSupport';
import { NGFPageWindowName, NGFPageWindowSupport } from './NGFPageWindowSupport';
import { NGFDeviceAwarenessPage } from './NGFDeviceAwarenessPage';
import { NGFSettingsPage } from './NGFSettingsPage';
import { NGFDemoSecurityPerfPage } from './NGFDemoSecurityPerfPage';
import { NGFDemoDataStoragePage } from './NGFDemoDataStoragePage';
import { NGFDemoWorkflowPage } from './NGFDemoWorkflowPage';
import { NGFDemoDeviceDisplayPage } from './NGFDemoDeviceDisplayPage';
import { NGFSystemResourcePreviewPage } from './SystemResourcePreviewPage';
import { NGFTaskManagerPage } from './NGFTaskManagerPage';
import { NGFCapabilitiesTabContent } from './NGFCapabilitiesTabContent';
import { NGFCapabilitiesNetworkPage } from './NGFCapabilitiesNetworkPage';
import { NGFCapabilitiesDatabasePage } from './NGFCapabilitiesDatabasePage';
import { NGFCapabilitiesWebBridgePage } from './NGFCapabilitiesWebBridgePage';
import { NGFCapabilitiesSecurityPage } from './NGFCapabilitiesSecurityPage';
import { NGFCapabilitiesHardwarePage } from './NGFCapabilitiesHardwarePage';
import { NGFCapabilitiesMediaPage } from './NGFCapabilitiesMediaPage';
import { NGFDemoErrorRecoveryPage } from './NGFDemoErrorRecoveryPage';
import { NGFDemoSyncManagerPage } from './NGFDemoSyncManagerPage';

const TAG: string = 'NGFStarterMainMenuPage';
const NGF_MAIN_MENU_TITLE_BAR_UNDERLAY_HEIGHT: number = 188;
const NGF_MAIN_MENU_CONTENT_TOP_INSET: number = 112;
const NGF_MAIN_MENU_HEADER_HEIGHT: number = 356;
const NGF_MAIN_MENU_HEADER_CONTENT_TOP_PADDING: number = 54;

class NGFMainMenuActionKey {
  static readonly OPEN_OFFICIAL_NAVIGATION: string = NGFHdsDemoRouteName.OFFICIAL_NAVIGATION;
  static readonly OPEN_HDS_SHOWCASE: string = NGFHdsDemoRouteName.SHOWCASE;
  static readonly BOOTSTRAP: string = 'action.bootstrap';
  static readonly PUBLISH_EVENT: string = 'action.publish_event';
  static readonly ADVANCE_LIFECYCLE: string = 'action.advance_lifecycle';
  static readonly SIMULATE_ERROR: string = 'action.simulate_error';
  static readonly DEMO_SECURITY_PERF: string = NGFHdsDemoRouteName.DEMO_SECURITY_PERF;
  static readonly DEMO_DATA_STORAGE: string = NGFHdsDemoRouteName.DEMO_DATA_STORAGE;
  static readonly DEMO_WORKFLOW: string = NGFHdsDemoRouteName.DEMO_WORKFLOW;
  static readonly DEMO_DEVICE_DISPLAY: string = NGFHdsDemoRouteName.DEMO_DEVICE_DISPLAY;
  static readonly SYSTEM_RESOURCE_PREVIEW: string = NGFHdsDemoRouteName.SYSTEM_RESOURCE_PREVIEW;
  static readonly DEMO_TASK_MANAGER: string = NGFHdsDemoRouteName.TASK_MANAGER;
  static readonly DEMO_ERROR_RECOVERY: string = NGFHdsDemoRouteName.DEMO_ERROR_RECOVERY;
  static readonly DEMO_SYNC_MANAGER: string = NGFHdsDemoRouteName.DEMO_SYNC_MANAGER;
}

class NGFStarterLogEntry {
  id: number;
  text: string;

  constructor(id: number, text: string) {
    this.id = id;
    this.text = text;
  }
}

class NGFStarterStatePayload {
  phaseName: string;
  progress: number;
  isCompleted: boolean;

  constructor(phaseName: string, progress: number, isCompleted: boolean) {
    this.phaseName = phaseName;
    this.progress = progress;
    this.isCompleted = isCompleted;
  }
}

class NGFStarterDemoPayload {
  sequence: number;
  source: string;
  timestamp: number;

  constructor(sequence: number, source: string, timestamp: number) {
    this.sequence = sequence;
    this.source = source;
    this.timestamp = timestamp;
  }
}

class NGFStarterModuleBootstrapSummary {
  phaseName: string;
  totalCount: number;
  successCount: number;
  failureCount: number;

  constructor(phaseName: string, totalCount: number, successCount: number, failureCount: number) {
    this.phaseName = phaseName;
    this.totalCount = totalCount;
    this.successCount = successCount;
    this.failureCount = failureCount;
  }
}

class NGFStarterModuleDetailEntry {
  id: number;
  moduleName: string;
  phaseName: string;
  dependencyText: ResourceStr;
  serviceTokenText: ResourceStr;
  statusText: ResourceStr;
  messageText: ResourceStr;

  constructor(
    id: number,
    moduleName: string,
    phaseName: string,
    dependencyText: ResourceStr,
    serviceTokenText: ResourceStr,
    statusText: ResourceStr,
    messageText: ResourceStr
  ) {
    this.id = id;
    this.moduleName = moduleName;
    this.phaseName = phaseName;
    this.dependencyText = dependencyText;
    this.serviceTokenText = serviceTokenText;
    this.statusText = statusText;
    this.messageText = messageText;
  }
}

class NGFHdsDemoRouteParam {
  routeName: string;
  source: string;

  constructor(routeName: string, source: string) {
    this.routeName = routeName;
    this.source = source;
  }
}

class NGFMainMenuPointLightOptions implements hdsEffect.PointLightOptions {
  color?: ResourceColor;
  intensity?: number;
  height?: Dimension;
  bloom?: number;

  constructor(color: ResourceColor, intensity: number, height: Dimension, bloom: number) {
    this.color = color;
    this.intensity = intensity;
    this.height = height;
    this.bloom = bloom;
  }
}

class NGFMainMenuPointLightEffect implements hdsEffect.PointLightEffect {
  sourceType?: hdsEffect.PointLightSourceType;
  illuminatedType?: hdsEffect.PointLightIlluminatedType;
  options?: hdsEffect.PointLightOptions;

  constructor(
    sourceType: hdsEffect.PointLightSourceType,
    illuminatedType: hdsEffect.PointLightIlluminatedType,
    options: hdsEffect.PointLightOptions
  ) {
    this.sourceType = sourceType;
    this.illuminatedType = illuminatedType;
    this.options = options;
  }
}

class NGFMainMenuBackgroundEffectOptions implements BackgroundEffectOptions {
  radius: number;
  saturation?: number;
  brightness?: number;
  color?: ResourceColor;
  adaptiveColor?: AdaptiveColor;

  constructor(radius: number, saturation: number, brightness: number, color: ResourceColor) {
    this.radius = radius;
    this.saturation = saturation;
    this.brightness = brightness;
    this.color = color;
    this.adaptiveColor = AdaptiveColor.DEFAULT;
  }
}

class NGFMainMenuEdgeEffectOptions implements EdgeEffectOptions {
  alwaysEnabled: boolean;

  constructor(alwaysEnabled: boolean) {
    this.alwaysEnabled = alwaysEnabled;
  }
}

class NGFMainMenuGlassEffectFactory {
  static buildHeroSurfaceEffect(): VisualEffect {
    const pointLightOptions = new NGFMainMenuPointLightOptions($r('app.color.glass_surface_overlay'), 0.38, 34, 0.26);
    const pointLightEffect = new NGFMainMenuPointLightEffect(
      hdsEffect.PointLightSourceType.SOFT,
      hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
      pointLightOptions
    );
    return new hdsEffect.HdsEffectBuilder()
      .pointLight(pointLightEffect)
      .buildEffect();
  }

  static buildHeroChipEffect(): VisualEffect {
    const pointLightOptions = new NGFMainMenuPointLightOptions($r('app.color.glass_chip_overlay'), 0.24, 26, 0.18);
    const pointLightEffect = new NGFMainMenuPointLightEffect(
      hdsEffect.PointLightSourceType.BRIGHT,
      hdsEffect.PointLightIlluminatedType.BORDER,
      pointLightOptions
    );
    return new hdsEffect.HdsEffectBuilder()
      .pointLight(pointLightEffect)
      .buildEffect();
  }

  static buildActionButtonEffect(): VisualEffect {
    const pointLightOptions = new NGFMainMenuPointLightOptions($r('app.color.glass_action_overlay'), 0.32, 28, 0.24);
    const pointLightEffect = new NGFMainMenuPointLightEffect(
      hdsEffect.PointLightSourceType.SOFT,
      hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
      pointLightOptions
    );
    return new hdsEffect.HdsEffectBuilder()
      .pointLight(pointLightEffect)
      .buildEffect();
  }

  static buildTabBarEffect(pressed: boolean): VisualEffect {
    const pointLightOptions = new NGFMainMenuPointLightOptions(
      $r('app.color.glass_surface_overlay'),
      pressed ? 0.52 : 0.34,
      pressed ? 38 : 30,
      pressed ? 0.36 : 0.24
    );
    const pointLightEffect = new NGFMainMenuPointLightEffect(
      pressed ? hdsEffect.PointLightSourceType.BRIGHT : hdsEffect.PointLightSourceType.SOFT,
      hdsEffect.PointLightIlluminatedType.CONTENT,
      pointLightOptions
    );
    return new hdsEffect.HdsEffectBuilder()
      .pressShadow(hdsEffect.PressShadowType.BLEND_GRADIENT)
      .pointLight(pointLightEffect)
      .buildEffect();
  }

  static buildTabItemGlowEffect(active: boolean): VisualEffect {
    if (!active) {
      return new hdsEffect.HdsEffectBuilder().buildEffect();
    }
    const pointLightOptions = new NGFMainMenuPointLightOptions($r('app.color.button_primary'), 0.58, 30, 0.45);
    const pointLightEffect = new NGFMainMenuPointLightEffect(
      hdsEffect.PointLightSourceType.BRIGHT,
      hdsEffect.PointLightIlluminatedType.CONTENT,
      pointLightOptions
    );
    return new hdsEffect.HdsEffectBuilder()
      .pointLight(pointLightEffect)
      .buildEffect();
  }
}

@Entry
@Component
struct NGFStarterMainMenuPage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private isCoreReady: boolean = false;
  @State private lifecycleState: NGFPhaseState = new NGFPhaseState('not_started', 0, false);
  @State private demoEventCount: number = 0;
  @State private lastEventType: string = '-';
  @State private statusMessage: ResourceStr = $r('app.string.ui_str_2001');
  @State private logs: Array<NGFStarterLogEntry> = [];
  @State private modulePhaseName: string = '-';
  @State private moduleTotalCount: number = 0;
  @State private moduleSuccessCount: number = 0;
  @State private moduleFailureCount: number = 0;
  @State private moduleDetails: Array<NGFStarterModuleDetailEntry> = [];
  @State private nextPhaseIndex: number = 0;
  @State private selectedTabIndex: number = 0;
  @State private pressedTabIndex: number = -1;
  @State private tabGlowStrength: number = 0.88;
  @State private bottomInsetVp: number = 0;
  @State private topInsetVp: number = NGF_MAIN_MENU_CONTENT_TOP_INSET;
  @StorageProp('ngf_window_ready') private windowReady: boolean = false;
  @StorageProp('ngf_window_active_page') private windowActivePage: string = '';
  @StorageProp('ngf_window_display_mode') private windowDisplayMode: string = 'default';
  @StorageProp('ngf_window_status') private windowStatus: string = 'undefined';
  @StorageProp('ngf_window_snapshot_updated_at') private windowSnapshotUpdatedAt: number = 0;
  @StorageProp('ngf_window_snapshot_json') private windowSnapshotJson: string = '{}';

  private readonly scroller0: Scroller = new Scroller();
  private readonly scroller1: Scroller = new Scroller();
  private readonly scroller2: Scroller = new Scroller();
  private readonly scroller3: Scroller = new Scroller();
  private readonly scroller4: Scroller = new Scroller();
  private readonly tabsController: HdsTabsController = new HdsTabsController();
  private readonly starter = ngfStarterKernel;
  private readonly phaseOrder: Array<string> = ['context_setup', 'core_services', 'ready'];
  private readonly stateListenerId: string = 'NGFStarterMainMenuPage_State';
  private readonly errorListenerId: string = 'NGFStarterMainMenuPage_Error';
  private readonly demoListenerId: string = 'NGFStarterMainMenuPage_Demo';
  private readonly moduleListenerId: string = 'NGFStarterMainMenuPage_Modules';
  private eventsAttached: boolean = false;

  aboutToAppear(): void {
    const uiContext = this.getUIContext();
    if (uiContext) {
      uiContextManager.bindUIContext(uiContext);
    }
    this.starter.logger.setLevel(NGFLogLevel.DEBUG);
    this.isCoreReady = this.starter.bootstrap();
    this.lifecycleState = this.starter.lifecycle.getCurrentState();
    this.statusMessage = this.isCoreReady ? $r('app.string.ui_str_2002') : $r('app.string.ui_str_2003');
    this.syncModuleBootstrapReport();
    this.syncFrameworkRuntimeSnapshot();
    NGFPageWindowSupport.apply(NGFPageWindowName.MAIN_MENU);
    this.attachStarterEventListeners();
    this.appendLog(this.statusMessage);
    this.readBottomInset();
  }

  private readBottomInset(): void {
    const uiCtx = this.getUIContext();
    if (!uiCtx) {
      return;
    }
    const hostCtx = uiCtx.getHostContext();
    if (!hostCtx) {
      return;
    }
    window.getLastWindow(hostCtx).then((lastWindow: window.Window): void => {
      const bottomArea: window.AvoidArea = lastWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      this.bottomInsetVp = uiCtx.px2vp(bottomArea.bottomRect.height);
      const topArea: window.AvoidArea = lastWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const statusBarHeightVp = uiCtx.px2vp(topArea.topRect.height);
      // TitleBar FULL mode: status bar + large title + subtitle + margins (≈144vp)
      this.topInsetVp = statusBarHeightVp + 108;
    }).catch((_err: Error): void => {
      this.bottomInsetVp = 0;
      this.topInsetVp = NGF_MAIN_MENU_CONTENT_TOP_INSET;
    });
  }

  aboutToDisappear(): void {
    this.detachStarterEventListeners();
    uiContextManager.clearUIContext();
  }

  private attachStarterEventListeners(): void {
    if (this.eventsAttached) {
      return;
    }

    const stateSubscribed = this.starter.eventBus.subscribe(
      NGFStarterEventName.CORE_STATE_CHANGED,
      this.stateListenerId,
      (payload: NGFEventPayload): void => {
        const state = this.parseStatePayload(payload.payloadJson);
        if (state) {
          this.lifecycleState = state;
          this.lastEventType = payload.payloadType;
          this.syncFrameworkRuntimeSnapshot();
          this.appendLog($r('app.string.ui_str_2004', state.phaseName, state.progress));
        }
      }
    );

    const errorSubscribed = this.starter.eventBus.subscribe(
      NGFStarterEventName.CORE_ERROR,
      this.errorListenerId,
      (_payload: NGFEventPayload): void => {
        this.lastEventType = 'ngf_core_error';
        this.statusMessage = $r('app.string.ui_str_2005', this.starter.errorHandler.getRecentErrorCount());
        this.appendLog(this.statusMessage);
      }
    );

    const demoSubscribed = this.starter.eventBus.subscribe(
      NGFStarterEventName.DEMO_EVENT,
      this.demoListenerId,
      (_payload: NGFEventPayload): void => {
        this.demoEventCount = this.demoEventCount + 1;
        this.lastEventType = NGFStarterEventName.DEMO_EVENT;
        this.appendLog($r('app.string.ui_str_2006', this.demoEventCount));
      }
    );

    const moduleSubscribed = this.starter.eventBus.subscribe(
      NGFStarterEventName.CORE_MODULES_BOOTSTRAPPED,
      this.moduleListenerId,
      (payload: NGFEventPayload): void => {
        const summary = this.parseModuleBootstrapReport(payload.payloadJson);
        if (summary) {
          this.applyModuleBootstrapSummary(summary);
          this.syncFrameworkRuntimeSnapshot();
          this.lastEventType = payload.payloadType;
          this.statusMessage = $r('app.string.ui_str_2007', summary.successCount, summary.totalCount);
          this.appendLog($r('app.string.ui_str_2008', summary.phaseName, summary.successCount, summary.failureCount));
        }
      }
    );

    this.eventsAttached = stateSubscribed || errorSubscribed || demoSubscribed || moduleSubscribed;
  }

  private detachStarterEventListeners(): void {
    if (!this.eventsAttached) {
      return;
    }
    this.starter.eventBus.unsubscribe(NGFStarterEventName.CORE_STATE_CHANGED, this.stateListenerId);
    this.starter.eventBus.unsubscribe(NGFStarterEventName.CORE_ERROR, this.errorListenerId);
    this.starter.eventBus.unsubscribe(NGFStarterEventName.DEMO_EVENT, this.demoListenerId);
    this.starter.eventBus.unsubscribe(NGFStarterEventName.CORE_MODULES_BOOTSTRAPPED, this.moduleListenerId);
    this.eventsAttached = false;
  }

  private handleBootstrapTap(): void {
    this.isCoreReady = this.starter.bootstrap();
    this.lifecycleState = this.starter.lifecycle.getCurrentState();
    this.syncModuleBootstrapReport();
    this.syncFrameworkRuntimeSnapshot();
    this.statusMessage = this.isCoreReady ? $r('app.string.ui_str_2009') : $r('app.string.ui_str_2010');
    this.appendLog(this.statusMessage);
  }

  private handlePublishDemoEventTap(): void {
    const payloadData = new NGFStarterDemoPayload(
      this.demoEventCount + 1,
      TAG,
      Date.now()
    );
    const payload = new NGFEventPayload(
      'ngf_demo_event',
      this.toJson(payloadData),
      Date.now()
    );
    this.starter.eventBus.publish(NGFStarterEventName.DEMO_EVENT, payload);
  }

  private handleAdvanceLifecycleTap(): void {
    if (this.lifecycleState.isCompleted) {
      this.appendLog($r('app.string.ui_str_2011'));
      return;
    }

    if (this.nextPhaseIndex >= this.phaseOrder.length) {
      this.starter.lifecycle.markCompleted();
      this.lifecycleState = this.starter.lifecycle.getCurrentState();
      this.publishLifecycleState();
      this.appendLog($r('app.string.ui_str_2012'));
      return;
    }

    const phaseName = this.phaseOrder[this.nextPhaseIndex];
    this.starter.lifecycle.beginPhase(phaseName);
    this.starter.lifecycle.completePhase(phaseName);
    this.nextPhaseIndex = this.nextPhaseIndex + 1;

    if (this.nextPhaseIndex >= this.phaseOrder.length) {
      this.starter.lifecycle.markCompleted();
    }

    this.lifecycleState = this.starter.lifecycle.getCurrentState();
    this.publishLifecycleState();
    this.appendLog($r('app.string.ui_str_2013', phaseName));
  }

  private handleSimulateErrorTap(): void {
    const context = new NGFErrorContext('starter', 'NGF_STARTER_DEMO_ERROR', TAG);
    void this.starter.errorHandler.handle(
      'StarterDemoError',
      resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.ui_str_2014')),
      NGFErrorSeverity.MEDIUM,
      context
    ).then((success: boolean) => {
      if (success) {
        this.appendLog($r('app.string.ui_str_2015'));
      }
    });
  }

  private handleOpenHdsDemoTap(routeName: string, label: string): void {
    try {
      this.pathStack.pushPathByName(routeName, new NGFHdsDemoRouteParam(routeName, TAG));
      this.starter.logger.info(TAG, `打开HDS演示: route=${routeName}, label=${label}`);
      this.appendLog($r('app.string.ui_str_2016', label));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.appendLog($r('app.string.ui_str_2017', label, message));
    }
  }

  private handleFeatureActionTap(actionKey: string, label: ResourceStr): void {
    const labelStr = resolveResourceString(this.getUIContext().getHostContext(), label);
    if (actionKey === NGFMainMenuActionKey.OPEN_OFFICIAL_NAVIGATION ||
      actionKey === NGFMainMenuActionKey.OPEN_HDS_SHOWCASE) {
      this.handleOpenHdsDemoTap(actionKey, labelStr);
      return;
    }

    if (actionKey === NGFMainMenuActionKey.DEMO_SECURITY_PERF ||
      actionKey === NGFMainMenuActionKey.DEMO_DATA_STORAGE ||
      actionKey === NGFMainMenuActionKey.DEMO_WORKFLOW ||
      actionKey === NGFMainMenuActionKey.DEMO_DEVICE_DISPLAY ||
      actionKey === NGFMainMenuActionKey.SYSTEM_RESOURCE_PREVIEW ||
      actionKey === NGFMainMenuActionKey.DEMO_TASK_MANAGER ||
      actionKey === NGFMainMenuActionKey.DEMO_ERROR_RECOVERY ||
      actionKey === NGFMainMenuActionKey.DEMO_SYNC_MANAGER) {
      this.handleOpenHdsDemoTap(actionKey, labelStr);
      return;
    }

    if (actionKey === NGFHdsDemoRouteName.CAPABILITY_NETWORK ||
        actionKey === NGFHdsDemoRouteName.CAPABILITY_RDB ||
        actionKey === NGFHdsDemoRouteName.CAPABILITY_WEB_BRIDGE ||
        actionKey === NGFHdsDemoRouteName.CAPABILITY_SECURITY ||
        actionKey === NGFHdsDemoRouteName.CAPABILITY_HARDWARE ||
        actionKey === NGFHdsDemoRouteName.CAPABILITY_MEDIA) {
      this.handleOpenHdsDemoTap(actionKey, labelStr);
      return;
    }

    if (actionKey === NGFMainMenuActionKey.BOOTSTRAP) {
      this.handleBootstrapTap();
      return;
    }
    if (actionKey === NGFMainMenuActionKey.PUBLISH_EVENT) {
      this.handlePublishDemoEventTap();
      return;
    }
    if (actionKey === NGFMainMenuActionKey.ADVANCE_LIFECYCLE) {
      this.handleAdvanceLifecycleTap();
      return;
    }
    if (actionKey === NGFMainMenuActionKey.SIMULATE_ERROR) {
      this.handleSimulateErrorTap();
      return;
    }

    this.appendLog($r('app.string.ui_str_2018', actionKey));
  }

  private publishLifecycleState(): void {
    const state = this.starter.lifecycle.getCurrentState();
    const payload = new NGFEventPayload(
      'ngf_core_state',
      this.toJson(new NGFStarterStatePayload(state.phaseName, state.progress, state.isCompleted)),
      Date.now()
    );
    this.starter.eventBus.publish(NGFStarterEventName.CORE_STATE_CHANGED, payload);
  }

  private parseStatePayload(payloadJson: string): NGFPhaseState | null {
    if (payloadJson.trim().length <= 0) {
      return null;
    }
    try {
      const parsed = JSON.parse(payloadJson) as NGFStarterStatePayload;
      const phaseName = parsed.phaseName && typeof parsed.phaseName === 'string' ? parsed.phaseName : 'not_started';
      const progress = parsed.progress && typeof parsed.progress === 'number' ? parsed.progress : 0;
      const isCompleted = parsed.isCompleted && typeof parsed.isCompleted === 'boolean' ? parsed.isCompleted : false;
      return new NGFPhaseState(phaseName, progress, isCompleted);
    } catch {
      return null;
    }
  }

  private syncModuleBootstrapReport(): void {
    const report = this.starter.getLastModuleBootstrapReport();
    if (!report) {
      return;
    }
    const summary = new NGFStarterModuleBootstrapSummary(
      report.phaseName,
      report.totalCount,
      report.successCount,
      report.failureCount
    );
    this.applyModuleBootstrapSummary(summary);
    this.appendLog($r('app.string.ui_str_2019', summary.phaseName, summary.successCount, summary.failureCount));
  }

  private syncFrameworkRuntimeSnapshot(): void {
    const snapshot = this.starter.getFrameworkRuntimeSnapshot();
    this.applyFrameworkRuntimeSnapshot(snapshot);
  }

  private parseModuleBootstrapReport(payloadJson: string): NGFStarterModuleBootstrapSummary | null {
    if (payloadJson.trim().length <= 0) {
      return null;
    }

    try {
      const parsed = JSON.parse(payloadJson) as NGFModuleBootstrapReport;
      const phaseName = parsed.phaseName && typeof parsed.phaseName === 'string' ? parsed.phaseName : 'core_services';
      const totalCount = parsed.totalCount && typeof parsed.totalCount === 'number' ? parsed.totalCount : 0;
      const successCount = parsed.successCount && typeof parsed.successCount === 'number' ? parsed.successCount : 0;
      const failureCount = parsed.failureCount && typeof parsed.failureCount === 'number' ? parsed.failureCount : 0;
      return new NGFStarterModuleBootstrapSummary(phaseName, totalCount, successCount, failureCount);
    } catch {
      return null;
    }
  }

  private applyModuleBootstrapSummary(summary: NGFStarterModuleBootstrapSummary): void {
    this.modulePhaseName = summary.phaseName;
    this.moduleTotalCount = summary.totalCount;
    this.moduleSuccessCount = summary.successCount;
    this.moduleFailureCount = summary.failureCount;
  }

  private applyFrameworkRuntimeSnapshot(snapshot: NGFFrameworkRuntimeSnapshot): void {
    this.isCoreReady = snapshot.coreReady;
    this.lifecycleState = new NGFPhaseState(
      snapshot.lifecyclePhaseName,
      snapshot.lifecycleProgress,
      snapshot.lifecycleCompleted
    );
    this.moduleTotalCount = snapshot.moduleCount;
    this.moduleSuccessCount = snapshot.successfulModuleCount;
    this.moduleFailureCount = snapshot.failedModuleCount;
    this.moduleDetails = this.buildModuleDetailEntries(snapshot.modules);
  }

  private buildModuleDetailEntries(modules: Array<NGFModuleRuntimeSnapshot>): Array<NGFStarterModuleDetailEntry> {
    const entries: Array<NGFStarterModuleDetailEntry> = [];
    for (let index = 0; index < modules.length; index++) {
      const moduleSnapshot = modules[index];
      const dependencyText = this.joinText(moduleSnapshot.dependencies);
      const serviceTokenText = this.joinText(moduleSnapshot.serviceTokens);
      const statusText = this.resolveModuleStatusText(moduleSnapshot);
      entries.push(
        new NGFStarterModuleDetailEntry(
          index + 1,
          moduleSnapshot.moduleName,
          moduleSnapshot.phaseName,
          dependencyText,
          serviceTokenText,
          statusText,
          moduleSnapshot.lastMessage
        )
      );
    }
    return entries;
  }

  private joinText(values: Array<string>): string {
    if (values.length <= 0) {
      return '-';
    }
    let result = '';
    for (let index = 0; index < values.length; index++) {
      if (index > 0) {
        result = `${result}, `;
      }
      result = `${result}${values[index]}`;
    }
    return result;
  }

  private resolveModuleStatusText(snapshot: NGFModuleRuntimeSnapshot): string {
    if (!snapshot.hasBootstrapResult) {
      return snapshot.isBootstrapped ? 'ready_without_report' : 'not_bootstrapped';
    }
    if (snapshot.lastSuccess) {
      return snapshot.isBootstrapped ? 'bootstrapped' : 'reported_success_but_not_ready';
    }
    return 'bootstrap_failed';
  }

  private appendLog(message: ResourceStr): void {
    const msgStr = typeof message === "string" ? message : '';
    const now = new Date();
    const timeText = `${this.pad2(now.getHours())}:${this.pad2(now.getMinutes())}:${this.pad2(now.getSeconds())}`;
    const nextId = this.logs.length > 0 ? this.logs[this.logs.length - 1].id + 1 : 1;
    const nextLogs: Array<NGFStarterLogEntry> = [];
    for (let i = 0; i < this.logs.length; i++) {
      nextLogs.push(this.logs[i]);
    }
    nextLogs.push(new NGFStarterLogEntry(nextId, `${timeText}  ${msgStr}`));
    while (nextLogs.length > 12) {
      nextLogs.shift();
    }
    this.logs = nextLogs;
  }

  private pad2(value: number): string {
    if (value >= 10) {
      return `${value}`;
    }
    return `0${value}`;
  }

  private toJson(value: NGFStarterDemoPayload | NGFStarterStatePayload): string {
    try {
      const serialized = JSON.stringify(value);
      if (serialized === undefined) {
        return '{}';
      }
      return serialized;
    } catch {
      return '{}';
    }
  }

  build() {
    HdsNavigation(this.pathStack) {
      Stack({ alignContent: Alignment.TopStart }) {
        this.buildTitleBarUnderlay()

        HdsTabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
          TabContent() {
            Scroll(this.scroller0) {
              Column({ space: 12 }) {
                this.buildHeaderCard()
                this.buildHdsDemoCard()
                this.buildActionCard()
                this.buildStatusCard()
                this.buildWindowMonitorCard()
                this.buildModuleDetailCard()
                this.buildLogCard()
              }
              .width('100%')
              .padding({
                left: 16,
                right: 16,
                top: this.topInsetVp,
                bottom: 76
              })
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring, new NGFMainMenuEdgeEffectOptions(true))
            .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.PARENT_FIRST })
            .backgroundColor($r('app.color.background_transparent'))
          }
          .tabBar(this.buildTabItem($r('app.string.tab_framework'), 'sys.symbol.house', 0))

          TabContent() {
            Scroll(this.scroller1) {
              Column({ space: 12 }) {
                this.buildDemoTaskManagerCard()
                this.buildDemoSecurityPerfCard()
                this.buildDemoDataStorageCard()
                this.buildDemoWorkflowCard()
                this.buildDemoDeviceDisplayCard()
                this.buildSystemResourcePreviewCard()
                this.buildDemoErrorRecoveryCard()
                this.buildDemoSyncManagerCard()
              }
              .width('100%')
              .padding({
                left: 16,
                right: 16,
                top: this.topInsetVp,
                bottom: 76
              })
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring, new NGFMainMenuEdgeEffectOptions(true))
            .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.PARENT_FIRST })
            .backgroundColor($r('app.color.background_transparent'))
          }
          .tabBar(this.buildTabItem($r('app.string.tab_features'), 'sys.symbol.more', 1))

          TabContent() {
            Scroll(this.scroller2) {
              Column({ space: 12 }) {
                NGFCapabilitiesTabContent({
                  onActionTap: (actionKey: string, label: ResourceStr) => {
                    this.handleFeatureActionTap(actionKey, label);
                  }
                })
              }
              .width('100%')
              .padding({
                left: 16,
                right: 16,
                top: this.topInsetVp,
                bottom: 76
              })
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring, new NGFMainMenuEdgeEffectOptions(true))
            .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.PARENT_FIRST })
            .backgroundColor($r('app.color.background_transparent'))
          }
          .tabBar(this.buildTabItem($r('app.string.tab_capabilities'), 'sys.symbol.grid', 2))

          TabContent() {
            Scroll(this.scroller3) {
              Column({ space: 12 }) {
                NGFDeviceAwarenessPage()
              }
              .width('100%')
              .padding({
                left: 16,
                right: 16,
                top: this.topInsetVp,
                bottom: 76
              })
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring, new NGFMainMenuEdgeEffectOptions(true))
            .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.PARENT_FIRST })
            .backgroundColor($r('app.color.background_transparent'))
          }
          .tabBar(this.buildTabItem($r('app.string.tab_device'), 'sys.symbol.scroll_vertical', 3))

          TabContent() {
            Scroll(this.scroller4) {
              Column({ space: 12 }) {
                NGFSettingsPage()
              }
              .width('100%')
              .padding({
                left: 16,
                right: 16,
                top: this.topInsetVp,
                bottom: 76
              })
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring, new NGFMainMenuEdgeEffectOptions(true))
            .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.PARENT_FIRST })
            .backgroundColor($r('app.color.background_transparent'))
          }
          .tabBar(this.buildTabItem($r('app.string.tab_settings'), 'sys.symbol.gearshape', 4))
        }
        .width('100%')
        .height('100%')
        .barMode(BarMode.Fixed)
        .barOverlap(true)
        .barFloatingStyle({
          adaptToHandedness: true,
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.IMMERSIVE,
            materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
          },
          thermoCtrl: true,
          barOpacity: 0.95,
          barBottomMargin: this.bottomInsetVp
        })
        .scrollable(true)
        .onChange((index: number): void => {
          this.selectedTabIndex = index;
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background_primary'))
    }
    .titleBar(NGFHdsTitleBarOptionsFactory.build(
      'NGF MainMenuPage',
      $r('app.string.ui_str_2020'),
      $r('app.color.background_primary'),
      hdsMaterial.MaterialLevel.EXQUISITE,
      true,
      false
    ))
    .titleMode(HdsNavigationTitleMode.FREE)
    .hideBackButton(true)
    .navDestination(this.buildNavDestination)
    .mode(NavigationMode.Stack)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_primary'))
    .bindToScrollable([this.scroller0, this.scroller1, this.scroller2, this.scroller3, this.scroller4])
  }

  @Builder
  private buildTabItem(title: ResourceStr, symbolName: string, tabIndex: number): void {
    Column({ space: 4 }) {
      SymbolGlyph($r(symbolName))
        .fontSize(this.selectedTabIndex === tabIndex ? 24 : 22)
        .fontWeight(this.selectedTabIndex === tabIndex ? FontWeight.Bold : FontWeight.Normal)
        .fontColor([this.selectedTabIndex === tabIndex
          ? $r('app.color.button_primary')
          : $r('app.color.text_secondary')])
        .symbolEffect(new BounceSymbolEffect(EffectScope.WHOLE, EffectDirection.UP), this.selectedTabIndex === tabIndex)
      Text(title)
        .fontSize(11)
        .fontColor(this.selectedTabIndex === tabIndex
          ? $r('app.color.button_primary')
          : $r('app.color.text_secondary'))
        .fontWeight(this.selectedTabIndex === tabIndex ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .scale(this.pressedTabIndex === tabIndex
      ? { x: 0.92, y: 0.92 }
      : { x: 1, y: 1 })
    .opacity(this.pressedTabIndex === tabIndex ? 0.8 : 1)
    .animation({ duration: 180, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent): void => {
      if (event.type === TouchType.Down) {
        this.pressedTabIndex = tabIndex;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedTabIndex = -1;
        if (event.type === TouchType.Up) {
          this.tabsController.changeIndex(tabIndex);
        }
      }
    })
  }


  @Builder
  private buildTitleBarUnderlay(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {}
        .width('100%')
        .height(NGF_MAIN_MENU_TITLE_BAR_UNDERLAY_HEIGHT)
        .linearGradient({
          angle: 150,
          colors: [
            ['#07101E', 0],
            ['#0C2341', 0.38],
            ['#143964', 0.72],
            ['#0A1626', 1]
          ]
        })

      Column() {}
        .width(176)
        .height(176)
        .borderRadius(176)
        .backgroundColor($r('app.color.glow_circle_blue'))
        .opacity(0.22)
        .margin({ left: 192, top: 12 })
        .shadow({ radius: 82, color: $r('app.color.glow_circle_blue_shadow'), offsetX: 10, offsetY: 6 })

      Column() {}
        .width(148)
        .height(148)
        .borderRadius(148)
        .backgroundColor($r('app.color.glow_circle_cyan'))
        .opacity(0.18)
        .margin({ left: 18, top: 28 })
        .shadow({ radius: 74, color: $r('app.color.glow_circle_cyan_shadow'), offsetX: -8, offsetY: 8 })

      Column() {}
        .width('86%')
        .height(1)
        .backgroundColor($r('app.color.glass_divider'))
        .opacity(0.52)
        .margin({ left: 16, top: 94 })

      Column() {}
        .width('100%')
        .height(NGF_MAIN_MENU_TITLE_BAR_UNDERLAY_HEIGHT)
        .backgroundEffect(new NGFMainMenuBackgroundEffectOptions(42, 1.24, 1.05, $r('app.color.glass_bg_effect')))
        .visualEffect(NGFMainMenuGlassEffectFactory.buildHeroSurfaceEffect())
    }
    .width('100%')
    .height(NGF_MAIN_MENU_TITLE_BAR_UNDERLAY_HEIGHT)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  @Builder
  private buildNavDestination(name: string, _param: Object): void {
    if (name === NGFHdsDemoRouteName.SHOWCASE) {
      HdsIntegratedShowcasePage()
    } else if (name === NGFHdsDemoRouteName.OFFICIAL_NAVIGATION) {
      HdsNavigationOfficialShowcasePage()
    } else if (name === NGFHdsDemoRouteName.OFFICIAL_NAVIGATION_OVERVIEW) {
      HdsNavigationOfficialOverviewPage()
    } else if (name === NGFHdsDemoRouteName.OFFICIAL_NAVIGATION_MATERIAL) {
      HdsNavigationOfficialMaterialPage()
    } else if (name === NGFHdsDemoRouteName.OFFICIAL_NAVIGATION_EFFECT) {
      HdsNavigationOfficialEffectPage()
    } else if (name === NGFHdsDemoRouteName.DEMO_SECURITY_PERF) {
      NGFDemoSecurityPerfPage()
    } else if (name === NGFHdsDemoRouteName.DEMO_DATA_STORAGE) {
      NGFDemoDataStoragePage()
    } else if (name === NGFHdsDemoRouteName.DEMO_WORKFLOW) {
      NGFDemoWorkflowPage()
    } else if (name === NGFHdsDemoRouteName.DEMO_DEVICE_DISPLAY) {
      NGFDemoDeviceDisplayPage()
    } else if (name === NGFHdsDemoRouteName.SYSTEM_RESOURCE_PREVIEW) {
      NGFSystemResourcePreviewPage()
    } else if (name === NGFHdsDemoRouteName.TASK_MANAGER) {
      NGFTaskManagerPage()
    } else if (name === NGFHdsDemoRouteName.CAPABILITY_NETWORK) {
      NGFCapabilitiesNetworkPage()
    } else if (name === NGFHdsDemoRouteName.CAPABILITY_RDB) {
      NGFCapabilitiesDatabasePage()
    } else if (name === NGFHdsDemoRouteName.CAPABILITY_WEB_BRIDGE) {
      NGFCapabilitiesWebBridgePage()
    } else if (name === NGFHdsDemoRouteName.CAPABILITY_SECURITY) {
      NGFCapabilitiesSecurityPage()
    } else if (name === NGFHdsDemoRouteName.CAPABILITY_HARDWARE) {
      NGFCapabilitiesHardwarePage()
    } else if (name === NGFHdsDemoRouteName.CAPABILITY_MEDIA) {
      NGFCapabilitiesMediaPage()
    } else if (name === NGFHdsDemoRouteName.DEMO_ERROR_RECOVERY) {
      NGFDemoErrorRecoveryPage()
    } else if (name === NGFHdsDemoRouteName.DEMO_SYNC_MANAGER) {
      NGFDemoSyncManagerPage()
    }
  }

  @Builder
  private buildHeaderCard(): void {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column() {}
        .width('100%')
        .height(NGF_MAIN_MENU_HEADER_HEIGHT)
        .linearGradient({
          angle: 145,
          colors: [
            ['#070E1D', 0],
            ['#0B1E37', 0.32],
            ['#13345E', 0.68],
            ['#08111F', 1]
          ]
        })
        .borderRadius(30)

      Column() {}
        .width(196)
        .height(196)
        .borderRadius(196)
        .backgroundColor($r('app.color.glow_circle_purple'))
        .opacity(0.32)
        .margin({ left: 12, top: 26 })
        .shadow({ radius: 78, color: $r('app.color.glow_circle_purple_shadow'), offsetX: -12, offsetY: 10 })

      Column() {}
        .width(164)
        .height(164)
        .borderRadius(164)
        .backgroundColor($r('app.color.glow_circle_green'))
        .opacity(0.28)
        .margin({ left: 180, top: 54 })
        .shadow({ radius: 72, color: $r('app.color.glow_circle_green_shadow'), offsetX: 14, offsetY: -8 })

      Column() {}
        .width('82%')
        .height(1)
        .backgroundColor($r('app.color.glass_divider_strong'))
        .opacity(0.45)
        .margin({ left: 18, top: 106 })

      Column({ space: 14 }) {
        Text('NGF MainMenuPage')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_glass_value'))

        Text($r('app.string.ui_str_2025'))
          .fontSize(14)
          .lineHeight(21)
          .fontColor($r('app.color.text_glass_subtitle'))

        Text(this.statusMessage)
          .fontSize(13)
          .lineHeight(20)
          .fontColor($r('app.color.text_glass_status'))
          .maxLines(2)

        Column({ space: 10 }) {
          Row({ space: 10 }) {
            this.buildHeaderGlassChip($r('app.string.ui_str_2026'), `${this.lifecycleState.phaseName} · ${this.lifecycleState.progress}%`)
            this.buildHeaderGlassChip($r('app.string.ui_str_2027'), `${this.moduleSuccessCount}/${this.moduleTotalCount}`)
          }
          .width('100%')

          Row({ space: 10 }) {
            this.buildHeaderGlassChip($r('app.string.ui_str_2028'), `${this.windowDisplayMode} · ${this.windowStatus}`)
            this.buildHeaderGlassChip($r('app.string.ui_str_2029'), `${this.demoEventCount}`)
          }
          .width('100%')
        }
        .width('100%')
      }
      .width('100%')
      .padding({ top: NGF_MAIN_MENU_HEADER_CONTENT_TOP_PADDING, right: 20, bottom: 24, left: 20 })
      .backgroundEffect(new NGFMainMenuBackgroundEffectOptions(44, 1.28, 1.06, $r('app.color.glass_bg_effect_strong')))
      .borderRadius(30)
      .border({ width: 1, color: $r('app.color.glass_border_strong') })
      .shadow({ radius: 18, color: $r('app.color.card_shadow'), offsetX: 0, offsetY: 10 })
      .visualEffect(NGFMainMenuGlassEffectFactory.buildHeroSurfaceEffect())
    }
    .width('100%')
    .height(NGF_MAIN_MENU_HEADER_HEIGHT)
  }

  @Builder
  private buildHeaderGlassChip(label: ResourceStr, value: ResourceStr): void {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_glass_label'))

      Text(value)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_glass_value'))
        .maxLines(2)
    }
    .width('48%')
    .padding({ top: 10, right: 12, bottom: 10, left: 12 })
    .backgroundEffect(new NGFMainMenuBackgroundEffectOptions(20, 1.18, 1.03, $r('app.color.glass_bg_effect_light')))
    .borderRadius(18)
    .border({ width: 1, color: $r('app.color.glass_border_light') })
    .shadow({ radius: 8, color: $r('app.color.circle_shadow_light'), offsetX: 0, offsetY: 4 })
    .visualEffect(NGFMainMenuGlassEffectFactory.buildHeroChipEffect())
  }

  @Builder
  private buildFeatureActionButton(
    badge: string,
    title: ResourceStr,
    subtitle: ResourceStr,
    accentStart: string,
    accentEnd: string,
    glowColor: string,
    actionKey: string
  ): void {
    Button() {
      Stack({ alignContent: Alignment.Start }) {
        Column() {}
          .width(108)
          .height(108)
          .borderRadius(108)
          .backgroundColor(glowColor)
          .opacity(0.24)
          .margin({ left: 216, top: -18 })
          .shadow({ radius: 34, color: glowColor, offsetX: 0, offsetY: 10 })

        Row({ space: 12 }) {
          Column({ space: 6 }) {
            Text(badge)
              .fontSize(10)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_glass_badge'))

            Text(title)
              .width('100%')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_white'))
              .maxLines(2)

            Text(subtitle)
              .width('100%')
              .fontSize(12)
              .lineHeight(18)
              .fontColor($r('app.color.text_glass_desc'))
              .maxLines(2)
          }
          .width('82%')
          .alignItems(HorizontalAlign.Start)

          Text('›')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_glass_arrow'))
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .linearGradient({
        angle: 140,
        colors: [
          [accentStart, 0],
          [accentEnd, 1]
        ]
      })
      .backgroundEffect(new NGFMainMenuBackgroundEffectOptions(24, 1.2, 1.05, $r('app.color.glass_bg_effect')))
      .borderRadius(22)
      .border({ width: 1, color: $r('app.color.glass_border_light') })
      .shadow({ radius: 14, color: $r('app.color.card_shadow_light'), offsetX: 0, offsetY: 8 })
      .visualEffect(NGFMainMenuGlassEffectFactory.buildActionButtonEffect())
    }
    .width('100%')
    .padding(0)
    .backgroundColor($r('app.color.background_transparent'))
    .buttonStyle(ButtonStyleMode.NORMAL)
    .onClick((): void => {
      this.handleFeatureActionTap(actionKey, title);
    })
  }

  @Builder
  private buildHdsDemoCard(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {}
        .width(146)
        .height(146)
        .borderRadius(146)
        .backgroundColor($r('app.color.glow_circle_indigo'))
        .opacity(0.22)
        .margin({ left: 198, top: -18 })
        .shadow({ radius: 52, color: $r('app.color.glow_circle_indigo_shadow'), offsetX: 10, offsetY: 12 })

      Column({ space: 12 }) {
        Text($r('app.string.ui_str_2030'))
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_white'))

        Text($r('app.string.ui_str_2031'))
          .fontSize(13)
          .lineHeight(20)
          .fontColor($r('app.color.text_glass_body'))

        Text($r('app.string.ui_str_2032'))
          .fontSize(13)
          .lineHeight(20)
          .fontColor($r('app.color.text_glass_body'))

        this.buildFeatureActionButton(
          'OFFICIAL',
          $r('app.string.ui_str_2033'),
          $r('app.string.ui_str_2034'),
          '#173887',
          '#2C61F4',
          '#6F8FFFFF',
          NGFMainMenuActionKey.OPEN_OFFICIAL_NAVIGATION
        )
        this.buildFeatureActionButton(
          'INTEGRATED',
          $r('app.string.ui_str_2035'),
          $r('app.string.ui_str_2036'),
          '#0D4B59',
          '#1698A6',
          '#59D9F4FF',
          NGFMainMenuActionKey.OPEN_HDS_SHOWCASE
        )
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(18)
    }
    .width('100%')
    .linearGradient({
      angle: 145,
      colors: [
        ['#08111F', 0],
        ['#122746', 0.48],
        ['#091624', 1]
      ]
    })
    .backgroundEffect(new NGFMainMenuBackgroundEffectOptions(36, 1.24, 1.06, $r('app.color.glass_bg_effect')))
    .borderRadius(26)
    .border({ width: 1, color: $r('app.color.glass_border_subtle') })
    .shadow({ radius: 16, color: $r('app.color.card_shadow_light'), offsetX: 0, offsetY: 10 })
    .visualEffect(NGFMainMenuGlassEffectFactory.buildHeroSurfaceEffect())
  }

  @Builder
  private buildActionCard(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {}
        .width(152)
        .height(152)
        .borderRadius(152)
        .backgroundColor($r('app.color.glow_circle_sky'))
        .opacity(0.18)
        .margin({ left: 210, top: -12 })
        .shadow({ radius: 48, color: $r('app.color.glow_circle_sky_shadow'), offsetX: 8, offsetY: 10 })

      Column({ space: 12 }) {
        Text($r('app.string.ui_str_2037'))
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_white'))

        Text($r('app.string.ui_str_2038'))
          .fontSize(13)
          .lineHeight(20)
          .fontColor($r('app.color.text_glass_hint'))

        this.buildFeatureActionButton(
          'CORE',
          $r('app.string.ui_str_2039'),
          $r('app.string.ui_str_2040'),
          '#155E75',
          '#0891B2',
          '#5FDBFFFF',
          NGFMainMenuActionKey.BOOTSTRAP
        )
        this.buildFeatureActionButton(
          'EVENT',
          $r('app.string.ui_str_2041'),
          $r('app.string.ui_str_2042'),
          '#1D4ED8',
          '#2563EB',
          '#79A6FFFF',
          NGFMainMenuActionKey.PUBLISH_EVENT
        )
        this.buildFeatureActionButton(
          'LIFECYCLE',
          $r('app.string.ui_str_2043'),
          $r('app.string.ui_str_2044'),
          '#0F766E',
          '#14B8A6',
          '#5EF2E2FF',
          NGFMainMenuActionKey.ADVANCE_LIFECYCLE
        )
        this.buildFeatureActionButton(
          'ERROR',
          $r('app.string.ui_str_2045'),
          $r('app.string.ui_str_2046'),
          '#9A3412',
          '#F97316',
          '#FFB37DFF',
          NGFMainMenuActionKey.SIMULATE_ERROR
        )
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(18)
    }
    .width('100%')
    .linearGradient({
      angle: 145,
      colors: [
        ['#09111D', 0],
        ['#10263A', 0.5],
        ['#0A1828', 1]
      ]
    })
    .backgroundEffect(new NGFMainMenuBackgroundEffectOptions(36, 1.22, 1.05, $r('app.color.glass_bg_effect')))
    .borderRadius(26)
    .border({ width: 1, color: $r('app.color.glass_border_medium') })
    .shadow({ radius: 16, color: $r('app.color.card_shadow_light'), offsetX: 0, offsetY: 10 })
    .visualEffect(NGFMainMenuGlassEffectFactory.buildHeroSurfaceEffect())
  }

  @Builder
  private buildDemoSecurityPerfCard(): void {
    this.buildFeatureActionButton(
      'SECURITY',
      $r('app.string.ui_str_2047'),
      $r('app.string.ui_str_2048'),
      '#0D4B59',
      '#14B8A6',
      '#5EEAD4FF',
      NGFMainMenuActionKey.DEMO_SECURITY_PERF
    )
  }

  @Builder
  private buildDemoDataStorageCard(): void {
    this.buildFeatureActionButton(
      'STORAGE',
      $r('app.string.ui_str_2049'),
      $r('app.string.ui_str_2050'),
      '#78350F',
      '#F59E0B',
      '#FCD34DFF',
      NGFMainMenuActionKey.DEMO_DATA_STORAGE
    )
  }

  @Builder
  private buildDemoWorkflowCard(): void {
    this.buildFeatureActionButton(
      'WORKFLOW',
      $r('app.string.ui_str_2051'),
      $r('app.string.ui_str_2052'),
      '#312E81',
      '#6366F1',
      '#A5B4FCFF',
      NGFMainMenuActionKey.DEMO_WORKFLOW
    )
  }

  @Builder
  private buildDemoDeviceDisplayCard(): void {
    this.buildFeatureActionButton(
      'DEVICE',
      $r('app.string.ui_str_2053'),
      $r('app.string.ui_str_2054'),
      '#14532D',
      '#22C55E',
      '#86EFACFF',
      NGFMainMenuActionKey.DEMO_DEVICE_DISPLAY
    )
  }

  @Builder
  private buildSystemResourcePreviewCard(): void {
    this.buildFeatureActionButton(
      'SYMBOL',
      $r('app.string.ui_str_2055'),
      $r('app.string.ui_str_2056'),
      '#1E3A8A',
      '#7C3AED',
      '#C4B5FDFF',
      NGFMainMenuActionKey.SYSTEM_RESOURCE_PREVIEW
    )
  }

  @Builder
  private buildDemoErrorRecoveryCard(): void {
    this.buildFeatureActionButton(
      'ERROR',
      $r('app.string.demo_error_recovery_title'),
      $r('app.string.demo_error_recovery_desc'),
      '#881337',
      '#F43F5E',
      '#FDA4AFFF',
      NGFMainMenuActionKey.DEMO_ERROR_RECOVERY
    )
  }

  @Builder
  private buildDemoSyncManagerCard(): void {
    this.buildFeatureActionButton(
      'SYNC',
      $r('app.string.demo_sync_title'),
      $r('app.string.demo_sync_desc'),
      '#1E3A8A',
      '#3B82F6',
      '#93C5FDFF',
      NGFMainMenuActionKey.DEMO_SYNC_MANAGER
    )
  }

  @Builder
  private buildStatusCard(): void {
    Column({ space: 8 }) {
      Text($r('app.string.ui_str_2057'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Text($r('app.string.ui_str_2058', this.isCoreReady ? 'ready' : 'not_ready'))
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2059', this.lifecycleState.phaseName))
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2060', this.lifecycleState.progress))
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2061', this.lifecycleState.isCompleted ? 'true' : 'false'))
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2062', this.demoEventCount))
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2063', this.lastEventType))
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2005', this.starter.errorHandler.getRecentErrorCount()))
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2064', this.modulePhaseName))
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2065', this.moduleSuccessCount, this.moduleTotalCount))
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2066', this.moduleFailureCount))
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(14)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildWindowMonitorCard(): void {
    Column({ space: 8 }) {
      Text($r('app.string.ui_str_2067'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Text($r('app.string.ui_str_2068', this.windowReady ? 'true' : 'false'))
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2069', this.windowActivePage.length > 0 ? this.windowActivePage : '-'))
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2070', this.windowDisplayMode))
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2071', this.windowStatus))
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2072', this.resolveWindowUpdatedAtText()))
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text(this.windowSnapshotJson)
        .width('100%')
        .fontSize(11)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(6)
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(14)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  private resolveWindowUpdatedAtText(): string {
    if (this.windowSnapshotUpdatedAt <= 0) {
      return '-';
    }
    const date = new Date(this.windowSnapshotUpdatedAt);
    return `${this.pad2(date.getHours())}:${this.pad2(date.getMinutes())}:${this.pad2(date.getSeconds())}`;
  }

  @Builder
  private buildModuleDetailCard(): void {
    Column({ space: 8 }) {
      Text($r('app.string.ui_str_2073'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      if (this.moduleDetails.length <= 0) {
        Text($r('app.string.ui_str_2074'))
          .width('100%')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
      } else {
        Column({ space: 8 }) {
          ForEach(this.moduleDetails, (entry: NGFStarterModuleDetailEntry) => {
            Column({ space: 4 }) {
              Text(`${entry.id}. ${entry.moduleName}`)
                .width('100%')
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
              Text($r('app.string.ui_str_2075', entry.phaseName))
                .width('100%')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
              Text($r('app.string.ui_str_2076', entry.statusText))
                .width('100%')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
              Text($r('app.string.ui_str_2077', entry.dependencyText))
                .width('100%')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
              Text($r('app.string.ui_str_2078', entry.serviceTokenText))
                .width('100%')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
              Text($r('app.string.ui_str_2079', entry.messageText))
                .width('100%')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
            }
            .width('100%')
            .padding(10)
            .backgroundColor($r('app.color.background_secondary'))
            .borderRadius(10)
          }, (entry: NGFStarterModuleDetailEntry): string => `starter_module_${entry.id}`)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(14)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildLogCard(): void {
    Column({ space: 8 }) {
      Text($r('app.string.ui_str_2080'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Column({ space: 4 }) {
        ForEach(this.logs, (entry: NGFStarterLogEntry) => {
          Text(entry.text)
            .width('100%')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Start)
        }, (entry: NGFStarterLogEntry): string => `starter_log_${entry.id}`)
      }
      .width('100%')
      .padding(10)
      .backgroundColor($r('app.color.background_secondary'))
      .borderRadius(10)
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(14)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildDemoTaskManagerCard(): void {
    Row() {
      Column({ space: 6 }) {
        Text($r('app.string.task_manager_title'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Text($r('app.string.task_manager_desc'))
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.arrow_right'))
        .fontSize(20)
        .fontColor([$r('app.color.text_secondary')])
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(14)
    .border({ width: 1, color: $r('app.color.panel_border') })
    .onClick(() => {
      this.handleFeatureActionTap(NGFMainMenuActionKey.DEMO_TASK_MANAGER, $r('app.string.task_manager_route_label'));
    })
  }
}
