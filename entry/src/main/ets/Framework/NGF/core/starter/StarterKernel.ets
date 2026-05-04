import { ILogger } from '../contracts/ILogger';
import { IEventBus, NGFEventListener, NGFEventPayload } from '../contracts/IEventBus';
import { IErrorHandler, NGFErrorContext, NGFErrorSeverity, NGFRecoveryHandler } from '../contracts/IErrorHandler';
import { ILifecycleOrchestrator, NGFPhaseState } from '../contracts/ILifecycleOrchestrator';
import {
  NGFFrameworkRuntimeSnapshot,
  NGFModuleBootstrapReport,
  NGFModuleRuntimeSnapshot
} from '../contracts/IModuleBootstrap';
import { IServiceContainer } from '../contracts/IServiceContainer';
import { ContainerLifecycle, DependencyContainer } from '../DependencyContainer';
import { ngfLoggerFacade } from '../facades/LoggerFacade';
import { NGFModuleBootstrapCoordinator, ngfModuleBootstrapCoordinator } from './ModuleBootstrapCoordinator';
import { NGFModuleRegistry, ngfModuleRegistry } from './ModuleRegistry';

const LOG_TAG: string = 'NGFStarterCore';
const MAX_RECENT_ERROR_RECORDS: number = 50;

export class NGFStarterServiceToken {
  static readonly LOGGER: string = 'ngf.core.logger';
  static readonly EVENT_BUS: string = 'ngf.core.event_bus';
  static readonly ERROR_HANDLER: string = 'ngf.core.error_handler';
  static readonly LIFECYCLE: string = 'ngf.core.lifecycle';
  static readonly SERVICE_CONTAINER: string = 'ngf.core.service_container';
  static readonly MODULE_REGISTRY: string = 'ngf.core.module_registry';
  static readonly MODULE_BOOTSTRAP_COORDINATOR: string = 'ngf.core.module_bootstrap_coordinator';
}

export class NGFStarterEventName {
  static readonly CORE_READY: string = 'ngf.starter.core.ready';
  static readonly CORE_STATE_CHANGED: string = 'ngf.starter.core.state_changed';
  static readonly CORE_ERROR: string = 'ngf.starter.core.error';
  static readonly CORE_MODULES_BOOTSTRAPPED: string = 'ngf.starter.core.modules_bootstrapped';
  static readonly DEMO_EVENT: string = 'ngf.starter.demo.event';
}

class NGFStarterCoreStateEnvelope {
  phaseName: string;
  progress: number;
  isCompleted: boolean;
  timestamp: number;

  constructor(phaseName: string, progress: number, isCompleted: boolean, timestamp: number) {
    this.phaseName = phaseName;
    this.progress = progress;
    this.isCompleted = isCompleted;
    this.timestamp = timestamp;
  }
}

class NGFStarterErrorRecord {
  errorName: string;
  message: string;
  severity: NGFErrorSeverity;
  category: string;
  code: string;
  source: string;
  timestamp: number;

  constructor(
    errorName: string,
    message: string,
    severity: NGFErrorSeverity,
    category: string,
    code: string,
    source: string,
    timestamp: number
  ) {
    this.errorName = errorName;
    this.message = message;
    this.severity = severity;
    this.category = category;
    this.code = code;
    this.source = source;
    this.timestamp = timestamp;
  }
}

class NGFStarterEventBus implements IEventBus {
  private readonly logger: ILogger;
  private readonly listenersByEvent: Map<string, Map<string, NGFEventListener>> = new Map<string, Map<string, NGFEventListener>>();

  constructor(logger: ILogger) {
    this.logger = logger;
  }

  publish(eventName: string, payload: NGFEventPayload): void {
    const normalizedEventName = eventName.trim();
    if (normalizedEventName.length <= 0) {
      this.logger.warn(LOG_TAG, '发布已忽略：事件名为空');
      return;
    }

    const listeners = this.listenersByEvent.get(normalizedEventName);
    if (!listeners) {
      this.logger.debug(LOG_TAG, `发布已跳过：事件=${normalizedEventName}, 监听器=0`);
      return;
    }

    this.logger.debug(LOG_TAG, `发布事件：事件=${normalizedEventName}, 监听器=${listeners.size}`);
    listeners.forEach((listener: NGFEventListener) => {
      try {
        listener(payload);
      } catch (error) {
        this.logger.warn(LOG_TAG, `事件监听器执行失败：事件=${normalizedEventName}, 错误=${this.errorToString(error as Object | string | number | boolean)}`);
      }
    });
  }

  subscribe(eventName: string, listenerId: string, listener: NGFEventListener): boolean {
    const normalizedEventName = eventName.trim();
    const normalizedListenerId = listenerId.trim();
    if (normalizedEventName.length <= 0 || normalizedListenerId.length <= 0) {
      this.logger.warn(LOG_TAG, `订阅已忽略：事件=${normalizedEventName}, 监听器ID=${normalizedListenerId}`);
      return false;
    }

    const listeners = this.ensureListeners(normalizedEventName);
    if (listeners.has(normalizedListenerId)) {
      this.logger.debug(LOG_TAG, `订阅已跳过：事件=${normalizedEventName}, 监听器ID=${normalizedListenerId}`);
      return false;
    }

    listeners.set(normalizedListenerId, listener);
    this.logger.info(LOG_TAG, `订阅监听器：事件=${normalizedEventName}, 监听器ID=${normalizedListenerId}`);
    return true;
  }

  unsubscribe(eventName: string, listenerId: string): boolean {
    const normalizedEventName = eventName.trim();
    const normalizedListenerId = listenerId.trim();
    const listeners = this.listenersByEvent.get(normalizedEventName);
    if (!listeners || !listeners.has(normalizedListenerId)) {
      this.logger.debug(LOG_TAG, `取消订阅已跳过：事件=${normalizedEventName}, 监听器ID=${normalizedListenerId}`);
      return false;
    }

    listeners.delete(normalizedListenerId);
    if (listeners.size === 0) {
      this.listenersByEvent.delete(normalizedEventName);
    }
    this.logger.info(LOG_TAG, `取消订阅监听器：事件=${normalizedEventName}, 监听器ID=${normalizedListenerId}`);
    return true;
  }

  clear(eventName: string): void {
    const normalizedEventName = eventName.trim();
    const hadListeners = this.listenersByEvent.delete(normalizedEventName);
    this.logger.info(LOG_TAG, `清除事件监听器：事件=${normalizedEventName}, 已清除=${hadListeners}`);
  }

  private ensureListeners(eventName: string): Map<string, NGFEventListener> {
    const existing = this.listenersByEvent.get(eventName);
    if (existing) {
      return existing;
    }
    const created = new Map<string, NGFEventListener>();
    this.listenersByEvent.set(eventName, created);
    return created;
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

class NGFStarterLifecycleOrchestrator implements ILifecycleOrchestrator {
  private readonly logger: ILogger;
  private currentPhase: string = 'not_started';
  private progress: number = 0;
  private completed: boolean = false;
  private readonly phaseOrder: string[] = ['context_setup', 'core_services', 'ready'];

  constructor(logger: ILogger) {
    this.logger = logger;
  }

  startInitialization(): void {
    this.currentPhase = 'not_started';
    this.progress = 0;
    this.completed = false;
    this.logger.lifecycle(LOG_TAG, '启动器初始化已重置');
  }

  beginPhase(phaseName: string): void {
    const previousPhase = this.currentPhase;
    const normalized = this.normalizePhaseName(phaseName);
    this.currentPhase = normalized;
    this.progress = this.resolveProgress(normalized, false);
    this.completed = false;
    this.logger.stateChange(LOG_TAG, previousPhase, this.currentPhase, `进度=${this.progress}`);
  }

  completePhase(phaseName: string): void {
    const previousPhase = this.currentPhase;
    const normalized = this.normalizePhaseName(phaseName);
    this.currentPhase = normalized;
    this.progress = this.resolveProgress(normalized, true);
    this.logger.stateChange(LOG_TAG, previousPhase, `${this.currentPhase}:completed`, `进度=${this.progress}`);
  }

  failPhase(phaseName: string, reason: string): void {
    const previousPhase = this.currentPhase;
    const normalized = this.normalizePhaseName(phaseName);
    this.currentPhase = normalized;
    this.completed = false;
    this.progress = Math.max(0, this.resolveProgress(normalized, false));
    if (reason.trim().length > 0) {
      this.currentPhase = `${normalized}:failed`;
    }
    this.logger.warn(LOG_TAG, `阶段失败：从=${previousPhase}, 到=${this.currentPhase}, 原因=${reason}`);
  }

  markCompleted(): void {
    const previousPhase = this.currentPhase;
    this.currentPhase = 'completed';
    this.progress = 100;
    this.completed = true;
    this.logger.stateChange(LOG_TAG, previousPhase, this.currentPhase, '进度=100');
  }

  getCurrentState(): NGFPhaseState {
    return new NGFPhaseState(this.currentPhase, this.progress, this.completed);
  }

  isCompleted(): boolean {
    return this.completed;
  }

  private normalizePhaseName(phaseName: string): string {
    const normalized = phaseName.trim().toLowerCase();
    if (normalized.length <= 0) {
      return 'not_started';
    }
    return normalized;
  }

  private resolveProgress(phaseName: string, isPhaseCompleted: boolean): number {
    if (phaseName === 'not_started') {
      return 0;
    }
    if (phaseName === 'completed') {
      return 100;
    }

    const index = this.phaseOrder.indexOf(phaseName);
    if (index < 0) {
      return this.progress;
    }

    const totalPhases = this.phaseOrder.length;
    if (isPhaseCompleted) {
      return Math.floor(((index + 1) * 100) / totalPhases);
    }
    return Math.floor((index * 100) / totalPhases);
  }
}

class NGFStarterServiceContainer implements IServiceContainer {
  private readonly logger: ILogger;
  private readonly registrations: Map<string, string> = new Map<string, string>();

  constructor(logger: ILogger) {
    this.logger = logger;
  }

  registerSingleton(token: string, implementationName: string): void {
    this.registrations.set(token, implementationName);
    this.logger.info(LOG_TAG, `注册服务：令牌=${token}, 实现=${implementationName}`);
  }

  resolve(token: string): string {
    const implementationName = this.registrations.get(token);
    if (implementationName) {
      this.logger.debug(LOG_TAG, `解析服务命中：令牌=${token}, 实现=${implementationName}`);
      return implementationName;
    }
    this.logger.warn(LOG_TAG, `解析服务未命中：令牌=${token}`);
    return '';
  }

  contains(token: string): boolean {
    const exists = this.registrations.has(token);
    this.logger.debug(LOG_TAG, `查询服务：令牌=${token}, 存在=${exists}`);
    return exists;
  }

  registerInstance(token: string, instance: object): void {
    const normalizedToken = token.trim();
    if (normalizedToken.length <= 0) {
      this.logger.warn(LOG_TAG, '注册实例已忽略：令牌为空');
      return;
    }
    const container = DependencyContainer.getInstance();
    if (!container.isRegistered(normalizedToken)) {
      container.register(normalizedToken, (): object => {
        return instance;
      }, ContainerLifecycle.SINGLETON);
    }
    this.logger.info(LOG_TAG, `注册服务实例：令牌=${normalizedToken}`);
  }

  resolveInstance(token: string): object | null {
    const normalizedToken = token.trim();
    const container = DependencyContainer.getInstance();
    const resolved = container.resolve(normalizedToken);
    if (resolved) {
      this.logger.debug(LOG_TAG, `解析实例命中：令牌=${normalizedToken}`);
      return resolved;
    }
    this.logger.warn(LOG_TAG, `解析实例未命中：令牌=${normalizedToken}`);
    return null;
  }
}

class NGFStarterErrorHandler implements IErrorHandler {
  private readonly logger: ILogger;
  private readonly eventBus: IEventBus;
  private readonly recoveryStrategies: Map<string, NGFRecoveryHandler> = new Map<string, NGFRecoveryHandler>();
  private readonly recentErrors: Array<NGFStarterErrorRecord> = [];

  constructor(logger: ILogger, eventBus: IEventBus) {
    this.logger = logger;
    this.eventBus = eventBus;
  }

  async handle(
    errorName: string,
    message: string,
    severity: NGFErrorSeverity,
    context: NGFErrorContext
  ): Promise<boolean> {
    try {
      const now = Date.now();
      const record = new NGFStarterErrorRecord(
        errorName,
        message,
        severity,
        context.category,
        context.code,
        context.source,
        now
      );
      this.pushRecord(record);
      this.logger.error(context.source, `${errorName}: ${message}`);

      const payload = new NGFEventPayload('ngf_core_error', this.toJson(record), now);
      this.eventBus.publish(NGFStarterEventName.CORE_ERROR, payload);

      if (severity === NGFErrorSeverity.HIGH || severity === NGFErrorSeverity.CRITICAL) {
        const recovered = await this.tryRecover(errorName, message, severity, context);
        if (recovered) {
          this.logger.info(context.source, `恢复成功：错误=${errorName}`);
        }
      }
      return true;
    } catch (error) {
      this.logger.error(LOG_TAG, `错误处理失败：${this.errorToString(error as Object | string | number | boolean)}`);
      return false;
    }
  }

  registerRecoverStrategy(strategyName: string, handler: NGFRecoveryHandler): boolean {
    const normalized = strategyName.trim();
    if (normalized.length <= 0) {
      this.logger.warn(LOG_TAG, '注册恢复策略已忽略：策略名为空');
      return false;
    }
    if (this.recoveryStrategies.has(normalized)) {
      this.logger.debug(LOG_TAG, `注册恢复策略已跳过：策略=${normalized}`);
      return false;
    }
    this.recoveryStrategies.set(normalized, handler);
    this.logger.info(LOG_TAG, `注册恢复策略：策略=${normalized}`);
    return true;
  }

  getRecentErrorCount(): number {
    const count = this.recentErrors.length;
    this.logger.debug(LOG_TAG, `获取最近错误数：数量=${count}`);
    return count;
  }

  private async tryRecover(
    errorName: string,
    message: string,
    severity: NGFErrorSeverity,
    context: NGFErrorContext
  ): Promise<boolean> {
    const strategyNames = this.recoveryStrategies.keys();
    for (const strategyName of strategyNames) {
      const handler = this.recoveryStrategies.get(strategyName);
      if (handler) {
        try {
          this.logger.info(LOG_TAG, `尝试恢复策略：${strategyName}`);
          const result = await handler(errorName, message, severity, context);
          if (result) {
            return true;
          }
        } catch (recoveryError) {
          this.logger.warn(LOG_TAG, `恢复策略失败：${strategyName}, 错误=${this.errorToString(recoveryError as Object | string | number | boolean)}`);
        }
      }
    }
    return false;
  }

  private pushRecord(record: NGFStarterErrorRecord): void {
    this.recentErrors.push(record);
    if (this.recentErrors.length > MAX_RECENT_ERROR_RECORDS) {
      this.recentErrors.shift();
    }
  }

  private toJson(record: NGFStarterErrorRecord): string {
    try {
      const serialized = JSON.stringify(record);
      if (serialized === undefined) {
        return '{}';
      }
      return serialized;
    } catch {
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

export class NGFStarterKernel {
  private static instance: NGFStarterKernel | null = null;

  readonly logger: ILogger;
  readonly eventBus: IEventBus;
  readonly errorHandler: IErrorHandler;
  readonly lifecycle: ILifecycleOrchestrator;
  readonly serviceContainer: IServiceContainer;
  readonly moduleRegistry: NGFModuleRegistry;
  readonly moduleBootstrapCoordinator: NGFModuleBootstrapCoordinator;
  private bootstrapped: boolean = false;
  private lastModuleBootstrapReport: NGFModuleBootstrapReport | null = null;

  private constructor() {
    this.logger = ngfLoggerFacade;
    this.eventBus = new NGFStarterEventBus(this.logger);
    this.errorHandler = new NGFStarterErrorHandler(this.logger, this.eventBus);
    this.lifecycle = new NGFStarterLifecycleOrchestrator(this.logger);
    this.serviceContainer = new NGFStarterServiceContainer(this.logger);
    this.moduleRegistry = ngfModuleRegistry;
    this.moduleBootstrapCoordinator = ngfModuleBootstrapCoordinator;
    this.logger.lifecycle(LOG_TAG, 'NGF 启动器核心已构建');
  }

  static getInstance(): NGFStarterKernel {
    if (!NGFStarterKernel.instance) {
      NGFStarterKernel.instance = new NGFStarterKernel();
      NGFStarterKernel.instance.logger.lifecycle(LOG_TAG, 'NGF 启动器单例已创建');
    }
    return NGFStarterKernel.instance;
  }

  bootstrap(): boolean {
    if (this.bootstrapped) {
      this.logger.debug(LOG_TAG, '引导已跳过：已完成引导');
      return true;
    }

    try {
      this.logger.lifecycle(LOG_TAG, '引导开始');
      this.lifecycle.startInitialization();
      this.publishCurrentState();

      this.lifecycle.beginPhase('context_setup');
      this.publishCurrentState();
      this.registerCoreServices();
      this.lifecycle.completePhase('context_setup');
      this.publishCurrentState();

      this.lifecycle.beginPhase('core_services');
      this.publishCurrentState();
      const moduleReport = this.moduleBootstrapCoordinator.bootstrapPhase('core_services');
      this.publishModuleBootstrapReport(moduleReport);
      if (!moduleReport.success) {
        throw new Error(`module bootstrap failed: success=${moduleReport.successCount}, failure=${moduleReport.failureCount}`);
      }
      this.lifecycle.completePhase('core_services');
      this.publishCurrentState();

      this.lifecycle.beginPhase('ready');
      this.publishCurrentState();
      this.lifecycle.completePhase('ready');
      this.lifecycle.markCompleted();
      this.publishCurrentState();

      this.bootstrapped = true;
      this.logger.lifecycle(LOG_TAG, 'NGF 启动器核心引导完成');

      const readyPayload = new NGFEventPayload(
        'ngf_core_ready',
        this.toStateEnvelopeJson(this.lifecycle.getCurrentState()),
        Date.now()
      );
      this.eventBus.publish(NGFStarterEventName.CORE_READY, readyPayload);
      return true;
    } catch (error) {
      const message = this.errorToString(error as Object | string | number | boolean);
      this.logger.error(LOG_TAG, `引导失败：${message}`);
      this.lifecycle.failPhase(this.lifecycle.getCurrentState().phaseName, message);
      this.publishCurrentState();
      const context = new NGFErrorContext('system', 'NGF_STARTER_BOOTSTRAP_FAILED', LOG_TAG);
      void this.errorHandler.handle('StarterBootstrapFailed', message, NGFErrorSeverity.CRITICAL, context);
      this.bootstrapped = false;
      return false;
    }
  }

  isBootstrapped(): boolean {
    this.logger.debug(LOG_TAG, `是否已引导=${this.bootstrapped}`);
    return this.bootstrapped;
  }

  getLastModuleBootstrapReport(): NGFModuleBootstrapReport | null {
    return this.lastModuleBootstrapReport;
  }

  getFrameworkRuntimeSnapshot(): NGFFrameworkRuntimeSnapshot {
    const lifecycleState = this.lifecycle.getCurrentState();
    const modules = this.moduleBootstrapCoordinator.listModuleSnapshots();
    let bootstrappedModuleCount: number = 0;
    let successfulModuleCount: number = 0;
    let failedModuleCount: number = 0;

    for (let index = 0; index < modules.length; index++) {
      const moduleSnapshot: NGFModuleRuntimeSnapshot = modules[index];
      if (moduleSnapshot.isBootstrapped) {
        bootstrappedModuleCount += 1;
      }
      if (moduleSnapshot.hasBootstrapResult) {
        if (moduleSnapshot.lastSuccess) {
          successfulModuleCount += 1;
        } else {
          failedModuleCount += 1;
        }
      }
    }

    return new NGFFrameworkRuntimeSnapshot(
      this.bootstrapped,
      lifecycleState.phaseName,
      lifecycleState.progress,
      lifecycleState.isCompleted,
      modules.length,
      bootstrappedModuleCount,
      successfulModuleCount,
      failedModuleCount,
      modules,
      Date.now()
    );
  }

  private registerCoreServices(): void {
    this.serviceContainer.registerSingleton(NGFStarterServiceToken.LOGGER, 'NGFLoggerFacade');
    this.serviceContainer.registerSingleton(NGFStarterServiceToken.EVENT_BUS, 'NGFStarterEventBus');
    this.serviceContainer.registerSingleton(NGFStarterServiceToken.ERROR_HANDLER, 'NGFStarterErrorHandler');
    this.serviceContainer.registerSingleton(NGFStarterServiceToken.LIFECYCLE, 'NGFStarterLifecycleOrchestrator');
    this.serviceContainer.registerSingleton(NGFStarterServiceToken.SERVICE_CONTAINER, 'NGFStarterServiceContainer');
    this.serviceContainer.registerSingleton(NGFStarterServiceToken.MODULE_REGISTRY, 'NGFModuleRegistry');
    this.serviceContainer.registerSingleton(NGFStarterServiceToken.MODULE_BOOTSTRAP_COORDINATOR, 'NGFModuleBootstrapCoordinator');
  }

  private publishCurrentState(): void {
    const currentState = this.lifecycle.getCurrentState();
    const payload = new NGFEventPayload(
      'ngf_core_state',
      this.toStateEnvelopeJson(currentState),
      Date.now()
    );
    this.logger.debug(LOG_TAG, `发布当前状态：阶段=${currentState.phaseName}, 进度=${currentState.progress}, 已完成=${currentState.isCompleted}`);
    this.eventBus.publish(NGFStarterEventName.CORE_STATE_CHANGED, payload);
  }

  private publishModuleBootstrapReport(report: NGFModuleBootstrapReport): void {
    this.lastModuleBootstrapReport = report;
    const payload = new NGFEventPayload(
      'ngf_core_modules_bootstrapped',
      this.toModuleBootstrapReportJson(report),
      Date.now()
    );
    this.logger.info(LOG_TAG, `发布模块引导报告：总数=${report.totalCount}, 成功=${report.successCount}, 失败=${report.failureCount}`);
    this.eventBus.publish(NGFStarterEventName.CORE_MODULES_BOOTSTRAPPED, payload);
  }

  private toStateEnvelopeJson(state: NGFPhaseState): string {
    const envelope = new NGFStarterCoreStateEnvelope(state.phaseName, state.progress, state.isCompleted, Date.now());
    try {
      const serialized = JSON.stringify(envelope);
      if (serialized === undefined) {
        return '{}';
      }
      return serialized;
    } catch {
      return '{}';
    }
  }

  private toModuleBootstrapReportJson(report: NGFModuleBootstrapReport): string {
    try {
      const serialized = JSON.stringify(report);
      if (serialized === undefined) {
        return '{}';
      }
      return serialized;
    } catch {
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

export const ngfStarterKernel: NGFStarterKernel = NGFStarterKernel.getInstance();
