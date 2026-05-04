import { hdsEffect, hdsMaterial, HdsNavigation, HdsNavigationTitleMode } from '@kit.UIDesignKit';
import { uiContextManager } from '../../Framework/NGF/platformOhos/UIContextManager';
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
  dependencyText: string;
  serviceTokenText: string;
  statusText: string;
  messageText: string;

  constructor(
    id: number,
    moduleName: string,
    phaseName: string,
    dependencyText: string,
    serviceTokenText: string,
    statusText: string,
    messageText: string
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
      hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
      pointLightOptions
    );
    return new hdsEffect.HdsEffectBuilder()
      .pressShadow(hdsEffect.PressShadowType.BLEND_GRADIENT)
      .pointLight(pointLightEffect)
      .buildEffect();
  }

  static buildTabItemGlowEffect(): VisualEffect {
    const pointLightOptions = new NGFMainMenuPointLightOptions($r('app.color.button_primary'), 0.46, 24, 0.32);
    const pointLightEffect = new NGFMainMenuPointLightEffect(
      hdsEffect.PointLightSourceType.BRIGHT,
      hdsEffect.PointLightIlluminatedType.BORDER,
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
  @State private statusMessage: string = '等待核心启动';
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
  @StorageProp('ngf_window_ready') private windowReady: boolean = false;
  @StorageProp('ngf_window_active_page') private windowActivePage: string = '';
  @StorageProp('ngf_window_display_mode') private windowDisplayMode: string = 'default';
  @StorageProp('ngf_window_status') private windowStatus: string = 'undefined';
  @StorageProp('ngf_window_snapshot_updated_at') private windowSnapshotUpdatedAt: number = 0;
  @StorageProp('ngf_window_snapshot_json') private windowSnapshotJson: string = '{}';

  private readonly scroller: Scroller = new Scroller();
  private readonly tabsController: TabsController = new TabsController();
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
    this.statusMessage = this.isCoreReady ? '轻核心框架已就绪' : '轻核心框架启动失败';
    this.syncModuleBootstrapReport();
    this.syncFrameworkRuntimeSnapshot();
    NGFPageWindowSupport.apply(NGFPageWindowName.MAIN_MENU);
    this.attachStarterEventListeners();
    this.appendLog(this.statusMessage);
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
          this.appendLog(`生命周期状态: ${state.phaseName}, progress=${state.progress}`);
        }
      }
    );

    const errorSubscribed = this.starter.eventBus.subscribe(
      NGFStarterEventName.CORE_ERROR,
      this.errorListenerId,
      (_payload: NGFEventPayload): void => {
        this.lastEventType = 'ngf_core_error';
        this.statusMessage = `错误计数: ${this.starter.errorHandler.getRecentErrorCount()}`;
        this.appendLog(this.statusMessage);
      }
    );

    const demoSubscribed = this.starter.eventBus.subscribe(
      NGFStarterEventName.DEMO_EVENT,
      this.demoListenerId,
      (_payload: NGFEventPayload): void => {
        this.demoEventCount = this.demoEventCount + 1;
        this.lastEventType = NGFStarterEventName.DEMO_EVENT;
        this.appendLog(`收到演示事件: count=${this.demoEventCount}`);
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
          this.statusMessage = `模块启动: success=${summary.successCount}/${summary.totalCount}`;
          this.appendLog(`模块启动完成: phase=${summary.phaseName}, success=${summary.successCount}, failure=${summary.failureCount}`);
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
    this.statusMessage = this.isCoreReady ? '核心服务重新确认成功' : '核心服务启动失败';
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
      this.appendLog('生命周期已完成，无需推进');
      return;
    }

    if (this.nextPhaseIndex >= this.phaseOrder.length) {
      this.starter.lifecycle.markCompleted();
      this.lifecycleState = this.starter.lifecycle.getCurrentState();
      this.publishLifecycleState();
      this.appendLog('生命周期已标记为完成');
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
    this.appendLog(`推进生命周期阶段: ${phaseName}`);
  }

  private handleSimulateErrorTap(): void {
    const context = new NGFErrorContext('starter', 'NGF_STARTER_DEMO_ERROR', TAG);
    void this.starter.errorHandler.handle(
      'StarterDemoError',
      '这是用于验证错误链路的示例异常',
      NGFErrorSeverity.MEDIUM,
      context
    ).then((success: boolean) => {
      if (success) {
        this.appendLog('已提交演示错误到核心错误处理器');
      }
    });
  }

  private handleOpenHdsDemoTap(routeName: string, label: string): void {
    try {
      this.pathStack.pushPathByName(routeName, new NGFHdsDemoRouteParam(routeName, TAG));
      this.starter.logger.info(TAG, `打开HDS演示: route=${routeName}, label=${label}`);
      this.appendLog(`已打开 ${label}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.appendLog(`打开 ${label} 失败: ${message}`);
    }
  }

  private handleFeatureActionTap(actionKey: string, label: string): void {
    if (actionKey === NGFMainMenuActionKey.OPEN_OFFICIAL_NAVIGATION ||
      actionKey === NGFMainMenuActionKey.OPEN_HDS_SHOWCASE) {
      this.handleOpenHdsDemoTap(actionKey, label);
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

    this.appendLog(`未识别的主页操作: ${actionKey}`);
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
    this.appendLog(`已同步模块启动结果: phase=${summary.phaseName}, success=${summary.successCount}, failure=${summary.failureCount}`);
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

  private appendLog(message: string): void {
    const now = new Date();
    const timeText = `${this.pad2(now.getHours())}:${this.pad2(now.getMinutes())}:${this.pad2(now.getSeconds())}`;
    const nextId = this.logs.length > 0 ? this.logs[this.logs.length - 1].id + 1 : 1;
    const nextLogs: Array<NGFStarterLogEntry> = [];
    for (let i = 0; i < this.logs.length; i++) {
      nextLogs.push(this.logs[i]);
    }
    nextLogs.push(new NGFStarterLogEntry(nextId, `${timeText}  ${message}`));
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

        Tabs({ barPosition: BarPosition.End, index: this.selectedTabIndex, controller: this.tabsController }) {
          TabContent() {
            Scroll(this.scroller) {
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
              .padding({ left: 16, right: 16, top: NGF_MAIN_MENU_CONTENT_TOP_INSET, bottom: 76 })
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring, new NGFMainMenuEdgeEffectOptions(true))
            .backgroundColor('#00000000')
          }
          .tabBar(null)

          TabContent() {
            Scroll() {
              NGFDeviceAwarenessPage()
            }
            .width('100%')
            .height('100%')
            .padding({ top: NGF_MAIN_MENU_CONTENT_TOP_INSET, bottom: 76 })
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring, new NGFMainMenuEdgeEffectOptions(true))
            .backgroundColor($r('app.color.background_primary'))
          }
          .tabBar(null)

          TabContent() {
            Scroll() {
              NGFSettingsPage()
            }
            .width('100%')
            .height('100%')
            .padding({ top: NGF_MAIN_MENU_CONTENT_TOP_INSET, bottom: 76 })
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring, new NGFMainMenuEdgeEffectOptions(true))
            .backgroundColor($r('app.color.background_primary'))
          }
          .tabBar(null)
        }
        .width('100%')
        .height('100%')
        .barHeight(0)
        .barWidth(0)
        .scrollable(true)
        .animationDuration(300)
        .animationMode(AnimationMode.CONTENT_FIRST)
        .onChange((index: number): void => {
          this.selectedTabIndex = index;
        })

        this.buildFloatingTabBar()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background_primary'))
    }
    .titleBar(NGFHdsTitleBarOptionsFactory.build(
      'NGF MainMenuPage',
      'NGF 运行框架主入口 / HDS 根导航容器',
      $r('app.color.background_primary'),
      hdsMaterial.MaterialLevel.EXQUISITE,
      false,
      false
    ))
    .titleMode(HdsNavigationTitleMode.FULL)
    .hideBackButton(true)
    .navDestination(this.buildNavDestination)
    .mode(NavigationMode.Stack)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_primary'))
  }

  @Builder
  private buildTabItem(title: string, symbolName: string, tabIndex: number): void {
    Column({ space: 4 }) {
      SymbolGlyph($r(symbolName))
        .fontSize(this.selectedTabIndex === tabIndex ? 24 : 22)
        .fontWeight(this.selectedTabIndex === tabIndex ? FontWeight.Bold : FontWeight.Normal)
        .fontColor([this.selectedTabIndex === tabIndex
          ? $r('app.color.button_primary')
          : $r('app.color.text_secondary')])
      Text(title)
        .fontSize(11)
        .fontColor(this.selectedTabIndex === tabIndex
          ? $r('app.color.button_primary')
          : $r('app.color.text_secondary'))
        .fontWeight(this.selectedTabIndex === tabIndex ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('33.33%')
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
        this.animateTabGlow(0.96);
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedTabIndex = -1;
        this.animateTabGlow(0.88);
        if (event.type === TouchType.Up) {
          this.tabsController.changeIndex(tabIndex);
        }
      }
    })
  }

  private animateTabGlow(target: number): void {
    const uiContext: UIContext | undefined = this.getUIContext();
    if (uiContext) {
      uiContext.animateTo({
        duration: 200,
        curve: Curve.EaseOut
      }, (): void => {
        this.tabGlowStrength = target;
      });
    }
  }

  @Builder
  private buildFloatingTabBar(): void {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {}
        .width('76%')
        .height(40)
        .borderRadius(40)
        .backgroundColor($r('app.color.glow_circle_blue'))
        .opacity(this.tabGlowStrength * 0.18)
        .position({ left: '18%', bottom: 32 })
        .shadow({
          radius: 48,
          color: $r('app.color.glow_circle_blue_shadow'),
          offsetX: 0,
          offsetY: 6
        })
        .animation({ duration: 250, curve: Curve.EaseInOut })

      Column() {}
        .width('52%')
        .height(32)
        .borderRadius(32)
        .backgroundColor($r('app.color.glow_circle_cyan'))
        .opacity(this.tabGlowStrength * 0.14)
        .position({ left: '30%', bottom: 36 })
        .shadow({
          radius: 38,
          color: $r('app.color.glow_circle_cyan_shadow'),
          offsetX: 0,
          offsetY: 4
        })
        .animation({ duration: 250, curve: Curve.EaseInOut })

      Row() {
        this.buildTabItem('框架', 'sys.symbol.house', 0)
        this.buildTabItem('设备', 'sys.symbol.phone_fill', 1)
        this.buildTabItem('设置', 'sys.symbol.gearshape', 2)
      }
      .width('88%')
      .height(56)
      .backgroundColor('#1A1A2E66')
      .backgroundBlurStyle(BlurStyle.BACKGROUND_ULTRA_THICK, {
        colorMode: ThemeColorMode.SYSTEM,
        adaptiveColor: AdaptiveColor.DEFAULT,
        scale: 1.0
      })
      .backgroundEffect(new NGFMainMenuBackgroundEffectOptions(28, 1.18, 1.06, $r('app.color.glass_bg_effect')))
      .visualEffect(NGFMainMenuGlassEffectFactory.buildTabBarEffect(this.pressedTabIndex >= 0))
      .borderRadius(28)
      .shadow({
        radius: 28,
        color: '#1A1A2E44',
        offsetX: 0,
        offsetY: 6
      })
      .animation({ duration: 200, curve: Curve.EaseOut })
    }
    .width('100%')
    .height(96)
    .position({ left: 0, bottom: 16 })
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

        Text('API 23 轻核心入口（日志 / 事件 / 生命周期 / DI / WindowStage 统一窗口管理）')
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
            this.buildHeaderGlassChip('生命周期', `${this.lifecycleState.phaseName} · ${this.lifecycleState.progress}%`)
            this.buildHeaderGlassChip('模块', `${this.moduleSuccessCount}/${this.moduleTotalCount}`)
          }
          .width('100%')

          Row({ space: 10 }) {
            this.buildHeaderGlassChip('窗口', `${this.windowDisplayMode} · ${this.windowStatus}`)
            this.buildHeaderGlassChip('事件', `${this.demoEventCount}`)
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
  private buildHeaderGlassChip(label: string, value: string): void {
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
    title: string,
    subtitle: string,
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
    .backgroundColor('#00000000')
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
        Text('官方 HDS / ArkUI 示例页')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_white'))

        Text('基于 MainMenuPage 的 NavPathStack + navDestination 架构，统一接入官方 HDS Navigation 示例与单页融合示例。')
          .fontSize(13)
          .lineHeight(20)
          .fontColor($r('app.color.text_glass_body'))

        Text('旧的 HDS 组件页、布局页和动效页已删除，并重组为一个完全遵循 HDSNavigation 视觉模式的综合示例页。')
          .fontSize(13)
          .lineHeight(20)
          .fontColor($r('app.color.text_glass_body'))

        this.buildFeatureActionButton(
          'OFFICIAL',
          '官方 HDS Navigation 示例页',
          '验证统一主栈、官方目的地与多功能顶栏页面结构。',
          '#173887',
          '#2C61F4',
          '#6F8FFFFF',
          NGFMainMenuActionKey.OPEN_OFFICIAL_NAVIGATION
        )
        this.buildFeatureActionButton(
          'INTEGRATED',
          'HDS 综合融合示例页',
          '在同一页面内融合组件、布局与动效验证能力。',
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
        Text('快速操作')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_white'))

        Text('把高频调试动作收束成统一光效按钮，便于在沉浸式主页中快速验证核心链路。')
          .fontSize(13)
          .lineHeight(20)
          .fontColor($r('app.color.text_glass_hint'))

        this.buildFeatureActionButton(
          'CORE',
          '初始化核心服务',
          '重新确认容器、日志、事件总线和基础能力是否就绪。',
          '#155E75',
          '#0891B2',
          '#5FDBFFFF',
          NGFMainMenuActionKey.BOOTSTRAP
        )
        this.buildFeatureActionButton(
          'EVENT',
          '发布演示事件',
          '向核心事件总线发送演示消息，检查链路与日志反馈。',
          '#1D4ED8',
          '#2563EB',
          '#79A6FFFF',
          NGFMainMenuActionKey.PUBLISH_EVENT
        )
        this.buildFeatureActionButton(
          'LIFECYCLE',
          '推进生命周期',
          '模拟框架分阶段推进，观察状态卡片与日志变化。',
          '#0F766E',
          '#14B8A6',
          '#5EF2E2FF',
          NGFMainMenuActionKey.ADVANCE_LIFECYCLE
        )
        this.buildFeatureActionButton(
          'ERROR',
          '触发演示错误',
          '验证错误处理器、错误计数与统一日志采集效果。',
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
  private buildStatusCard(): void {
    Column({ space: 8 }) {
      Text('运行状态')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Text(`核心状态: ${this.isCoreReady ? 'ready' : 'not_ready'}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text(`生命周期: ${this.lifecycleState.phaseName}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text(`进度: ${this.lifecycleState.progress}%`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text(`已完成: ${this.lifecycleState.isCompleted ? 'true' : 'false'}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text(`事件计数: ${this.demoEventCount}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text(`最新事件: ${this.lastEventType}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text(`错误计数: ${this.starter.errorHandler.getRecentErrorCount()}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text(`模块阶段: ${this.modulePhaseName}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text(`模块成功: ${this.moduleSuccessCount}/${this.moduleTotalCount}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text(`模块失败: ${this.moduleFailureCount}`)
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
      Text('窗口监控')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Text(`窗口就绪: ${this.windowReady ? 'true' : 'false'}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text(`当前页面: ${this.windowActivePage.length > 0 ? this.windowActivePage : '-'}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text(`显示模式: ${this.windowDisplayMode}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text(`窗口状态: ${this.windowStatus}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
      Text(`最近更新: ${this.resolveWindowUpdatedAtText()}`)
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
      Text('模块明细')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      if (this.moduleDetails.length <= 0) {
        Text('当前暂无模块运行时快照')
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
              Text(`阶段: ${entry.phaseName}`)
                .width('100%')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
              Text(`状态: ${entry.statusText}`)
                .width('100%')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
              Text(`依赖: ${entry.dependencyText}`)
                .width('100%')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
              Text(`服务: ${entry.serviceTokenText}`)
                .width('100%')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
              Text(`消息: ${entry.messageText}`)
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
      Text('运行日志')
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
}

