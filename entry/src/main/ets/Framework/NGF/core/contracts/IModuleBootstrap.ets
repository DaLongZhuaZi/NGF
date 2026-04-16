export interface IModuleBootstrap {
  bootstrap(): boolean;
  isBootstrapped(): boolean;
}

export class NGFModuleDefinition {
  moduleName: string;
  phaseName: string;
  order: number;
  dependencies: Array<string>;
  serviceTokens: Array<string>;

  constructor(
    moduleName: string,
    phaseName: string,
    order: number,
    dependencies: Array<string>,
    serviceTokens: Array<string>
  ) {
    this.moduleName = moduleName;
    this.phaseName = phaseName;
    this.order = order;
    this.dependencies = dependencies;
    this.serviceTokens = serviceTokens;
  }
}

export class NGFModuleBootstrapResult {
  moduleName: string;
  success: boolean;
  message: string;
  timestamp: number;

  constructor(moduleName: string, success: boolean, message: string, timestamp: number) {
    this.moduleName = moduleName;
    this.success = success;
    this.message = message;
    this.timestamp = timestamp;
  }
}

export class NGFModuleBootstrapReport {
  phaseName: string;
  success: boolean;
  totalCount: number;
  successCount: number;
  failureCount: number;
  results: Array<NGFModuleBootstrapResult>;
  timestamp: number;

  constructor(
    phaseName: string,
    success: boolean,
    totalCount: number,
    successCount: number,
    failureCount: number,
    results: Array<NGFModuleBootstrapResult>,
    timestamp: number
  ) {
    this.phaseName = phaseName;
    this.success = success;
    this.totalCount = totalCount;
    this.successCount = successCount;
    this.failureCount = failureCount;
    this.results = results;
    this.timestamp = timestamp;
  }
}

export class NGFModuleRuntimeSnapshot {
  moduleName: string;
  phaseName: string;
  order: number;
  dependencies: Array<string>;
  serviceTokens: Array<string>;
  isBootstrapped: boolean;
  hasBootstrapResult: boolean;
  lastSuccess: boolean;
  lastMessage: string;
  lastUpdatedAt: number;

  constructor(
    moduleName: string,
    phaseName: string,
    order: number,
    dependencies: Array<string>,
    serviceTokens: Array<string>,
    isBootstrapped: boolean,
    hasBootstrapResult: boolean,
    lastSuccess: boolean,
    lastMessage: string,
    lastUpdatedAt: number
  ) {
    this.moduleName = moduleName;
    this.phaseName = phaseName;
    this.order = order;
    this.dependencies = dependencies;
    this.serviceTokens = serviceTokens;
    this.isBootstrapped = isBootstrapped;
    this.hasBootstrapResult = hasBootstrapResult;
    this.lastSuccess = lastSuccess;
    this.lastMessage = lastMessage;
    this.lastUpdatedAt = lastUpdatedAt;
  }
}

export class NGFFrameworkRuntimeSnapshot {
  coreReady: boolean;
  lifecyclePhaseName: string;
  lifecycleProgress: number;
  lifecycleCompleted: boolean;
  moduleCount: number;
  bootstrappedModuleCount: number;
  successfulModuleCount: number;
  failedModuleCount: number;
  modules: Array<NGFModuleRuntimeSnapshot>;
  timestamp: number;

  constructor(
    coreReady: boolean,
    lifecyclePhaseName: string,
    lifecycleProgress: number,
    lifecycleCompleted: boolean,
    moduleCount: number,
    bootstrappedModuleCount: number,
    successfulModuleCount: number,
    failedModuleCount: number,
    modules: Array<NGFModuleRuntimeSnapshot>,
    timestamp: number
  ) {
    this.coreReady = coreReady;
    this.lifecyclePhaseName = lifecyclePhaseName;
    this.lifecycleProgress = lifecycleProgress;
    this.lifecycleCompleted = lifecycleCompleted;
    this.moduleCount = moduleCount;
    this.bootstrappedModuleCount = bootstrappedModuleCount;
    this.successfulModuleCount = successfulModuleCount;
    this.failedModuleCount = failedModuleCount;
    this.modules = modules;
    this.timestamp = timestamp;
  }
}
