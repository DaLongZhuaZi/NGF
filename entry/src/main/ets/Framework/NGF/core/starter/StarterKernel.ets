import { ILogger } from '../contracts/ILogger';
import { IEventBus, NGFEventListener, NGFEventPayload } from '../contracts/IEventBus';
import { IErrorHandler, NGFErrorContext, NGFErrorSeverity } from '../contracts/IErrorHandler';
import { ILifecycleOrchestrator, NGFPhaseState } from '../contracts/ILifecycleOrchestrator';
import {
  NGFFrameworkRuntimeSnapshot,
  NGFModuleBootstrapReport,
  NGFModuleRuntimeSnapshot
} from '../contracts/IModuleBootstrap';
import { IServiceContainer } from '../contracts/IServiceContainer';
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
      this.logger.warn(LOG_TAG, 'publish ignored: eventName is empty');
      return;
    }

    const listeners = this.listenersByEvent.get(normalizedEventName);
    if (!listeners) {
      this.logger.debug(LOG_TAG, `publish skipped: event=${normalizedEventName}, listeners=0`);
      return;
    }

    this.logger.debug(LOG_TAG, `publish event: event=${normalizedEventName}, listeners=${listeners.size}`);
    listeners.forEach((listener: NGFEventListener) => {
      try {
        listener(payload);
      } catch (error) {
        this.logger.warn(LOG_TAG, `event listener failed: event=${normalizedEventName}, error=${this.errorToString(error as Object | string | number | boolean)}`);
      }
    });
  }

  subscribe(eventName: string, listenerId: string, listener: NGFEventListener): boolean {
    const normalizedEventName = eventName.trim();
    const normalizedListenerId = listenerId.trim();
    if (normalizedEventName.length <= 0 || normalizedListenerId.length <= 0) {
      this.logger.warn(LOG_TAG, `subscribe ignored: event=${normalizedEventName}, listenerId=${normalizedListenerId}`);
      return false;
    }

    const listeners = this.ensureListeners(normalizedEventName);
    if (listeners.has(normalizedListenerId)) {
      this.logger.debug(LOG_TAG, `subscribe skipped: event=${normalizedEventName}, listenerId=${normalizedListenerId}`);
      return false;
    }

    listeners.set(normalizedListenerId, listener);
    this.logger.info(LOG_TAG, `subscribe listener: event=${normalizedEventName}, listenerId=${normalizedListenerId}`);
    return true;
  }

  unsubscribe(eventName: string, listenerId: string): boolean {
    const normalizedEventName = eventName.trim();
    const normalizedListenerId = listenerId.trim();
    const listeners = this.listenersByEvent.get(normalizedEventName);
    if (!listeners || !listeners.has(normalizedListenerId)) {
      this.logger.debug(LOG_TAG, `unsubscribe skipped: event=${normalizedEventName}, listenerId=${normalizedListenerId}`);
      return false;
    }

    listeners.delete(normalizedListenerId);
    if (listeners.size === 0) {
      this.listenersByEvent.delete(normalizedEventName);
    }
    this.logger.info(LOG_TAG, `unsubscribe listener: event=${normalizedEventName}, listenerId=${normalizedListenerId}`);
    return true;
  }

  clear(eventName: string): void {
    const normalizedEventName = eventName.trim();
    const hadListeners = this.listenersByEvent.delete(normalizedEventName);
    this.logger.info(LOG_TAG, `clear event listeners: event=${normalizedEventName}, cleared=${hadListeners}`);
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
    this.logger.lifecycle(LOG_TAG, 'starter initialization reset');
  }

  beginPhase(phaseName: string): void {
    const previousPhase = this.currentPhase;
    const normalized = this.normalizePhaseName(phaseName);
    this.currentPhase = normalized;
    this.progress = this.resolveProgress(normalized, false);
    this.completed = false;
    this.logger.stateChange(LOG_TAG, previousPhase, this.currentPhase, `progress=${this.progress}`);
  }

  completePhase(phaseName: string): void {
    const previousPhase = this.currentPhase;
    const normalized = this.normalizePhaseName(phaseName);
    this.currentPhase = normalized;
    this.progress = this.resolveProgress(normalized, true);
    this.logger.stateChange(LOG_TAG, previousPhase, `${this.currentPhase}:completed`, `progress=${this.progress}`);
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
    this.logger.warn(LOG_TAG, `phase failed: from=${previousPhase}, to=${this.currentPhase}, reason=${reason}`);
  }

  markCompleted(): void {
    const previousPhase = this.currentPhase;
    this.currentPhase = 'completed';
    this.progress = 100;
    this.completed = true;
    this.logger.stateChange(LOG_TAG, previousPhase, this.currentPhase, 'progress=100');
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
    this.logger.info(LOG_TAG, `register service: token=${token}, implementation=${implementationName}`);
  }

  resolve(token: string): string {
    const implementationName = this.registrations.get(token);
    if (implementationName) {
      this.logger.debug(LOG_TAG, `resolve service hit: token=${token}, implementation=${implementationName}`);
      return implementationName;
    }
    this.logger.warn(LOG_TAG, `resolve service missed: token=${token}`);
    return '';
  }

  contains(token: string): boolean {
    const exists = this.registrations.has(token);
    this.logger.debug(LOG_TAG, `contains service: token=${token}, exists=${exists}`);
    return exists;
  }
}

class NGFStarterErrorHandler implements IErrorHandler {
  private readonly logger: ILogger;
  private readonly eventBus: IEventBus;
  private readonly strategyNames: Set<string> = new Set<string>();
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
      return true;
    } catch (error) {
      this.logger.error(LOG_TAG, `error handling failed: ${this.errorToString(error as Object | string | number | boolean)}`);
      return false;
    }
  }

  registerRecoverStrategy(strategyName: string): boolean {
    const normalized = strategyName.trim();
    if (normalized.length <= 0) {
      this.logger.warn(LOG_TAG, 'registerRecoverStrategy ignored: strategyName is empty');
      return false;
    }
    if (this.strategyNames.has(normalized)) {
      this.logger.debug(LOG_TAG, `registerRecoverStrategy skipped: strategy=${normalized}`);
      return false;
    }
    this.strategyNames.add(normalized);
    this.logger.info(LOG_TAG, `register recover strategy: strategy=${normalized}`);
    return true;
  }

  getRecentErrorCount(): number {
    const count = this.recentErrors.length;
    this.logger.debug(LOG_TAG, `getRecentErrorCount: count=${count}`);
    return count;
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
    this.logger.lifecycle(LOG_TAG, 'NGF starter core constructed');
  }

  static getInstance(): NGFStarterKernel {
    if (!NGFStarterKernel.instance) {
      NGFStarterKernel.instance = new NGFStarterKernel();
      NGFStarterKernel.instance.logger.lifecycle(LOG_TAG, 'NGF starter singleton created');
    }
    return NGFStarterKernel.instance;
  }

  bootstrap(): boolean {
    if (this.bootstrapped) {
      this.logger.debug(LOG_TAG, 'bootstrap skipped: already bootstrapped');
      return true;
    }

    try {
      this.logger.lifecycle(LOG_TAG, 'bootstrap start');
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
      this.logger.lifecycle(LOG_TAG, 'NGF starter core bootstrapped');

      const readyPayload = new NGFEventPayload(
        'ngf_core_ready',
        this.toStateEnvelopeJson(this.lifecycle.getCurrentState()),
        Date.now()
      );
      this.eventBus.publish(NGFStarterEventName.CORE_READY, readyPayload);
      return true;
    } catch (error) {
      const message = this.errorToString(error as Object | string | number | boolean);
      this.logger.error(LOG_TAG, `bootstrap failed: ${message}`);
      this.lifecycle.failPhase(this.lifecycle.getCurrentState().phaseName, message);
      this.publishCurrentState();
      const context = new NGFErrorContext('system', 'NGF_STARTER_BOOTSTRAP_FAILED', LOG_TAG);
      void this.errorHandler.handle('StarterBootstrapFailed', message, NGFErrorSeverity.CRITICAL, context);
      this.bootstrapped = false;
      return false;
    }
  }

  isBootstrapped(): boolean {
    this.logger.debug(LOG_TAG, `isBootstrapped=${this.bootstrapped}`);
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
    this.logger.debug(LOG_TAG, `publishCurrentState: phase=${currentState.phaseName}, progress=${currentState.progress}, completed=${currentState.isCompleted}`);
    this.eventBus.publish(NGFStarterEventName.CORE_STATE_CHANGED, payload);
  }

  private publishModuleBootstrapReport(report: NGFModuleBootstrapReport): void {
    this.lastModuleBootstrapReport = report;
    const payload = new NGFEventPayload(
      'ngf_core_modules_bootstrapped',
      this.toModuleBootstrapReportJson(report),
      Date.now()
    );
    this.logger.info(LOG_TAG, `publishModuleBootstrapReport: total=${report.totalCount}, success=${report.successCount}, failure=${report.failureCount}`);
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
