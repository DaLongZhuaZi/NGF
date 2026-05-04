import { logger } from '../../utils/Logger';
import {
  IModuleBootstrap,
  NGFModuleBootstrapReport,
  NGFModuleBootstrapResult,
  NGFModuleDefinition,
  NGFModuleRuntimeSnapshot
} from '../contracts/IModuleBootstrap';
import { ngfContentSourceIntegrationFacade } from '../../contentSource/facades/NGFContentSourceIntegrationFacade';
import { ngfContentWorkflowIntegrationFacade } from '../../contentWorkflow/facades/NGFContentWorkflowIntegrationFacade';
import { ngfDataIntegrationFacade } from '../../data/facades/NGFDataIntegrationFacade';
import { ngfPlatformOhosIntegrationFacade } from '../../platformOhos/facades/NGFPlatformOhosIntegrationFacade';
import { ngfUiShellIntegrationFacade } from '../../uiShell/facades/NGFUiShellIntegrationFacade';
import { ngfUIThemeIntegrationFacade } from '../../uiTheme/facades/NGFUIThemeIntegrationFacade';
import { ngfI18nIntegrationFacade } from '../../i18n/facades/NGFI18nIntegrationFacade';
import { ngfDeviceAwarenessIntegrationFacade } from '../../deviceAwareness/facades/NGFDeviceAwarenessIntegrationFacade';
import { NGFModuleRegistration, NGFModuleRegistry, ngfModuleRegistry } from './ModuleRegistry';

const TAG: string = 'NGFModuleBootstrapCoordinator';
const CORE_SERVICES_PHASE: string = 'core_services';

export class NGFModuleBootstrapCoordinator {
  private static instance: NGFModuleBootstrapCoordinator | null = null;
  private readonly registry: NGFModuleRegistry;
  private defaultModulesRegistered: boolean = false;
  private readonly lastResultsByModule: Map<string, NGFModuleBootstrapResult> = new Map<string, NGFModuleBootstrapResult>();
  private readonly lastReportsByPhase: Map<string, NGFModuleBootstrapReport> = new Map<string, NGFModuleBootstrapReport>();

  private constructor(registry: NGFModuleRegistry) {
    this.registry = registry;
  }

  static getInstance(): NGFModuleBootstrapCoordinator {
    if (!NGFModuleBootstrapCoordinator.instance) {
      NGFModuleBootstrapCoordinator.instance = new NGFModuleBootstrapCoordinator(ngfModuleRegistry);
    }
    return NGFModuleBootstrapCoordinator.instance;
  }

  ensureDefaultModulesRegistered(): void {
    if (this.defaultModulesRegistered) {
      return;
    }

    this.registerPlatformModule();
    this.registerThemeModule();
    this.registerI18nModule();
    this.registerDataModule();
    this.registerDeviceAwarenessModule();
    this.registerWorkflowModule();
    this.registerSourceModule();
    this.registerUiShellModule();
    this.defaultModulesRegistered = true;
    logger.info(TAG, '默认模块已注册');
  }

  bootstrapPhase(phaseName: string): NGFModuleBootstrapReport {
    this.ensureDefaultModulesRegistered();
    const modules = this.registry.listModulesByPhase(phaseName);
    const results: Array<NGFModuleBootstrapResult> = [];
    let successCount: number = 0;
    let failureCount: number = 0;

    for (let index = 0; index < modules.length; index++) {
      const moduleRegistration = modules[index];
      const result = this.bootstrapModule(moduleRegistration);
      results.push(result);
      this.lastResultsByModule.set(result.moduleName, result);
      if (result.success) {
        successCount += 1;
      } else {
        failureCount += 1;
      }
    }

    const report = new NGFModuleBootstrapReport(
      phaseName,
      failureCount === 0,
      modules.length,
      successCount,
      failureCount,
      results,
      Date.now()
    );
    this.lastReportsByPhase.set(phaseName, report);
    logger.info(TAG, `引导阶段完成：阶段=${phaseName}, 总数=${report.totalCount}, 成功=${report.successCount}, 失败=${report.failureCount}`);
    return report;
  }

  getLatestPhaseReport(phaseName: string): NGFModuleBootstrapReport | null {
    const normalizedPhase = phaseName.trim();
    const report = this.lastReportsByPhase.get(normalizedPhase);
    if (!report) {
      logger.debug(TAG, `获取最新阶段报告未命中：阶段=${normalizedPhase}`);
      return null;
    }
    return report;
  }

  getLatestModuleResult(moduleName: string): NGFModuleBootstrapResult | null {
    const normalizedModuleName = moduleName.trim();
    const result = this.lastResultsByModule.get(normalizedModuleName);
    if (!result) {
      logger.debug(TAG, `获取最新模块结果未命中：模块=${normalizedModuleName}`);
      return null;
    }
    return result;
  }

  listModuleSnapshots(): Array<NGFModuleRuntimeSnapshot> {
    this.ensureDefaultModulesRegistered();
    const registrations = this.registry.listAllModules();
    const snapshots: Array<NGFModuleRuntimeSnapshot> = [];
    for (let index = 0; index < registrations.length; index++) {
      snapshots.push(this.toRuntimeSnapshot(registrations[index]));
    }
    logger.debug(TAG, `列出模块快照：数量=${snapshots.length}`);
    return snapshots;
  }

  private bootstrapModule(registration: NGFModuleRegistration): NGFModuleBootstrapResult {
    const moduleName = registration.definition.moduleName;
    const dependencyMessage = this.validateDependencies(registration.definition);
    if (dependencyMessage.length > 0) {
      logger.warn(TAG, `引导模块被阻止：模块=${moduleName}, 原因=${dependencyMessage}`);
      return new NGFModuleBootstrapResult(moduleName, false, dependencyMessage, Date.now());
    }

    try {
      const success = registration.runtime.bootstrap();
      const message = success ? 'bootstrapped' : 'bootstrap returned false';
      if (success) {
        logger.info(TAG, `引导模块成功：模块=${moduleName}`);
      } else {
        logger.warn(TAG, `引导模块失败：模块=${moduleName}`);
      }
      return new NGFModuleBootstrapResult(moduleName, success, message, Date.now());
    } catch (error) {
      const message = this.errorToString(error as Object | string | number | boolean);
      logger.error(TAG, `引导模块异常：模块=${moduleName}, 错误=${message}`);
      return new NGFModuleBootstrapResult(moduleName, false, message, Date.now());
    }
  }

  private validateDependencies(definition: NGFModuleDefinition): string {
    for (let index = 0; index < definition.dependencies.length; index++) {
      const dependencyName = definition.dependencies[index];
      const dependencyRegistration = this.registry.resolveModule(dependencyName);
      if (!dependencyRegistration) {
        return `dependency missing: ${dependencyName}`;
      }
      if (!dependencyRegistration.runtime.isBootstrapped()) {
        return `dependency not bootstrapped: ${dependencyName}`;
      }
    }
    return '';
  }

  private registerPlatformModule(): void {
    const dependencies: Array<string> = [];
    const serviceTokens: Array<string> = [];
    serviceTokens.push('ngf.platform.window_manager');
    serviceTokens.push('ngf.platform.window_controller');
    serviceTokens.push('ngf.platform.page_policy_resolver');
    serviceTokens.push('ngf.platform.context_bridge');
    this.registerDefaultModule(
      new NGFModuleDefinition('ngf.platform.ohos', CORE_SERVICES_PHASE, 10, dependencies, serviceTokens),
      ngfPlatformOhosIntegrationFacade
    );
  }

  private registerThemeModule(): void {
    const dependencies: Array<string> = [];
    dependencies.push('ngf.platform.ohos');
    const serviceTokens: Array<string> = [];
    serviceTokens.push('ngf.theme.theme_manager');
    this.registerDefaultModule(
      new NGFModuleDefinition('ngf.uiTheme.core', CORE_SERVICES_PHASE, 15, dependencies, serviceTokens),
      ngfUIThemeIntegrationFacade
    );
  }

  private registerI18nModule(): void {
    const dependencies: Array<string> = [];
    dependencies.push('ngf.platform.ohos');
    const serviceTokens: Array<string> = [];
    serviceTokens.push('ngf.i18n.i18n_manager');
    this.registerDefaultModule(
      new NGFModuleDefinition('ngf.i18n.core', CORE_SERVICES_PHASE, 15, dependencies, serviceTokens),
      ngfI18nIntegrationFacade
    );
  }

  private registerDataModule(): void {
    const dependencies: Array<string> = [];
    dependencies.push('ngf.platform.ohos');
    const serviceTokens: Array<string> = [];
    serviceTokens.push('ngf.data.data_facade');
    serviceTokens.push('ngf.data.settings_store');
    serviceTokens.push('ngf.data.cache_store');
    serviceTokens.push('ngf.data.storage_provider');
    serviceTokens.push('ngf.data.db_migrator');
    this.registerDefaultModule(
      new NGFModuleDefinition('ngf.data.core', CORE_SERVICES_PHASE, 20, dependencies, serviceTokens),
      ngfDataIntegrationFacade
    );
  }

  private registerDeviceAwarenessModule(): void {
    const dependencies: Array<string> = [];
    dependencies.push('ngf.platform.ohos');
    const serviceTokens: Array<string> = [];
    serviceTokens.push('ngf.device.holding_awareness');
    serviceTokens.push('ngf.device.adaptation');
    serviceTokens.push('ngf.device.visual_effects');
    this.registerDefaultModule(
      new NGFModuleDefinition('ngf.device.awareness', CORE_SERVICES_PHASE, 25, dependencies, serviceTokens),
      ngfDeviceAwarenessIntegrationFacade
    );
  }

  private registerWorkflowModule(): void {
    const dependencies: Array<string> = [];
    dependencies.push('ngf.data.core');
    const serviceTokens: Array<string> = [];
    serviceTokens.push('ngf.workflow.engine');
    serviceTokens.push('ngf.workflow.action_executor');
    serviceTokens.push('ngf.workflow.retry_policy');
    serviceTokens.push('ngf.workflow.rate_limit_policy');
    this.registerDefaultModule(
      new NGFModuleDefinition('ngf.workflow.core', CORE_SERVICES_PHASE, 30, dependencies, serviceTokens),
      ngfContentWorkflowIntegrationFacade
    );
  }

  private registerSourceModule(): void {
    const dependencies: Array<string> = [];
    dependencies.push('ngf.data.core');
    dependencies.push('ngf.workflow.core');
    const serviceTokens: Array<string> = [];
    serviceTokens.push('ngf.source.repository');
    serviceTokens.push('ngf.source.loader');
    serviceTokens.push('ngf.source.registry');
    this.registerDefaultModule(
      new NGFModuleDefinition('ngf.content_source.core', CORE_SERVICES_PHASE, 40, dependencies, serviceTokens),
      ngfContentSourceIntegrationFacade
    );
  }

  private registerUiShellModule(): void {
    const dependencies: Array<string> = [];
    dependencies.push('ngf.platform.ohos');
    const serviceTokens: Array<string> = [];
    serviceTokens.push('ngf.ui.navigation_shell');
    serviceTokens.push('ngf.ui.page_policy_host');
    this.registerDefaultModule(
      new NGFModuleDefinition('ngf.ui_shell.core', CORE_SERVICES_PHASE, 50, dependencies, serviceTokens),
      ngfUiShellIntegrationFacade
    );
  }

  private registerDefaultModule(definition: NGFModuleDefinition, runtime: IModuleBootstrap): void {
    const success = this.registry.registerModule(definition, runtime);
    logger.debug(TAG, `注册默认模块：模块=${definition.moduleName}, 成功=${success}`);
  }

  private toRuntimeSnapshot(registration: NGFModuleRegistration): NGFModuleRuntimeSnapshot {
    const latestResult = this.getLatestModuleResult(registration.definition.moduleName);
    const dependencies = this.copyStringArray(registration.definition.dependencies);
    const serviceTokens = this.copyStringArray(registration.definition.serviceTokens);
    const hasBootstrapResult = latestResult !== null;
    const lastSuccess = latestResult ? latestResult.success : false;
    const lastMessage = latestResult ? latestResult.message : 'not_bootstrapped';
    const lastUpdatedAt = latestResult ? latestResult.timestamp : 0;
    return new NGFModuleRuntimeSnapshot(
      registration.definition.moduleName,
      registration.definition.phaseName,
      registration.definition.order,
      dependencies,
      serviceTokens,
      registration.runtime.isBootstrapped(),
      hasBootstrapResult,
      lastSuccess,
      lastMessage,
      lastUpdatedAt
    );
  }

  private copyStringArray(source: Array<string>): Array<string> {
    const copied: Array<string> = [];
    for (let index = 0; index < source.length; index++) {
      copied.push(source[index]);
    }
    return copied;
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

export const ngfModuleBootstrapCoordinator: NGFModuleBootstrapCoordinator = NGFModuleBootstrapCoordinator.getInstance();
