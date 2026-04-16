import { BusinessError } from '@kit.BasicServicesKit';
import { uiContextManager } from '../../Framework/Managers/UIContextManager';
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
import { HdsComponentsShowcasePage } from './HdsComponentsShowcasePage';
import { HdsLayoutsShowcasePage } from './HdsLayoutsShowcasePage';
import { HdsMotionShowcasePage } from './HdsMotionShowcasePage';
import { NGFHdsDemoRouteName } from './HdsDemoRoutes';

const TAG: string = 'NGFStarterMainMenuPage';

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

  private handleEnterLegacyMainMenuTap(): void {
    const router = this.getUIContext()?.getRouter();
    if (!router) {
      this.appendLog('无法获取Router，无法跳转到旧版主页面');
      return;
    }

    router.replaceUrl({
      url: 'pages/MainMenuPage'
    }).then((): void => {
      this.appendLog('已切换到旧版 MainMenuPage');
    }).catch((error: BusinessError): void => {
      this.appendLog(`跳转旧版主页面失败: ${error.code}`);
    });
  }

  private handleOpenHdsDemoTap(routeName: string, label: string): void {
    try {
      this.pathStack.pushPathByName(routeName, new NGFHdsDemoRouteParam(routeName, TAG));
      this.starter.logger.info(TAG, `open HDS demo: route=${routeName}, label=${label}`);
      this.appendLog(`已打开 ${label}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.appendLog(`打开 ${label} 失败: ${message}`);
    }
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
    Navigation(this.pathStack) {
      Scroll() {
        Column({ space: 12 }) {
          this.buildHeaderCard()
          this.buildHdsDemoCard()
          this.buildActionCard()
          this.buildStatusCard()
          this.buildModuleDetailCard()
          this.buildLogCard()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Auto)
      .backgroundColor($r('app.color.background_primary'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .title('NGF MainMenuPage')
    .navDestination(this.buildNavDestination)
    .mode(NavigationMode.Stack)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_primary'))
  }

  @Builder
  private buildNavDestination(name: string, _param: Object): void {
    if (name === NGFHdsDemoRouteName.COMPONENTS) {
      HdsComponentsShowcasePage()
    } else if (name === NGFHdsDemoRouteName.LAYOUTS) {
      HdsLayoutsShowcasePage()
    } else if (name === NGFHdsDemoRouteName.MOTION) {
      HdsMotionShowcasePage()
    }
  }

  @Builder
  private buildHeaderCard(): void {
    Column({ space: 8 }) {
      Text('NGF MainMenuPage')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text('API 21 轻核心入口（日志 / 事件 / 生命周期 / DI）')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
      Text(this.statusMessage)
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
  private buildHdsDemoCard(): void {
    Column({ space: 10 }) {
      Text('官方 HDS / ArkUI 示例页')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Text('基于 MainMenuPage 的 NavPathStack + navDestination 架构，接入多个官方 SDK 组件示例。')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))

      Button('HDS 组件示例页')
        .width('100%')
        .height(42)
        .backgroundColor($r('app.color.button_primary'))
        .fontColor($r('app.color.text_white'))
        .onClick((): void => {
          this.handleOpenHdsDemoTap(NGFHdsDemoRouteName.COMPONENTS, 'HDS 组件示例页');
        })

      Button('HDS 布局示例页')
        .width('100%')
        .height(42)
        .backgroundColor($r('app.color.button_secondary'))
        .fontColor($r('app.color.text_white'))
        .onClick((): void => {
          this.handleOpenHdsDemoTap(NGFHdsDemoRouteName.LAYOUTS, 'HDS 布局示例页');
        })

      Button('HDS 动效示例页')
        .width('100%')
        .height(42)
        .backgroundColor($r('app.color.button_success'))
        .fontColor($r('app.color.text_white'))
        .onClick((): void => {
          this.handleOpenHdsDemoTap(NGFHdsDemoRouteName.MOTION, 'HDS 动效示例页');
        })
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(14)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildActionCard(): void {
    Column({ space: 10 }) {
      Text('快速操作')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Button('初始化核心服务')
        .width('100%')
        .height(42)
        .backgroundColor($r('app.color.button_primary'))
        .fontColor($r('app.color.text_white'))
        .onClick((): void => {
          this.handleBootstrapTap();
        })

      Button('发布演示事件')
        .width('100%')
        .height(42)
        .backgroundColor($r('app.color.button_secondary'))
        .fontColor($r('app.color.text_white'))
        .onClick((): void => {
          this.handlePublishDemoEventTap();
        })

      Button('推进生命周期')
        .width('100%')
        .height(42)
        .backgroundColor($r('app.color.button_success'))
        .fontColor($r('app.color.text_white'))
        .onClick((): void => {
          this.handleAdvanceLifecycleTap();
        })

      Button('触发演示错误')
        .width('100%')
        .height(42)
        .backgroundColor($r('app.color.button_warning'))
        .fontColor($r('app.color.text_white'))
        .onClick((): void => {
          this.handleSimulateErrorTap();
        })

      Button('切换旧版 MainMenuPage')
        .width('100%')
        .height(42)
        .backgroundColor($r('app.color.button_inactive'))
        .fontColor($r('app.color.text_white'))
        .onClick((): void => {
          this.handleEnterLegacyMainMenuTap();
        })
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(14)
    .border({ width: 1, color: $r('app.color.panel_border') })
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

