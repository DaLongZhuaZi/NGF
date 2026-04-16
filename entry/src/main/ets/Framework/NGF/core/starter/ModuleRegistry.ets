import { logger } from '../../utils/Logger';
import { IModuleBootstrap, NGFModuleDefinition } from '../contracts/IModuleBootstrap';

const TAG: string = 'NGFModuleRegistry';

export class NGFModuleRegistration {
  definition: NGFModuleDefinition;
  runtime: IModuleBootstrap;

  constructor(definition: NGFModuleDefinition, runtime: IModuleBootstrap) {
    this.definition = definition;
    this.runtime = runtime;
  }
}

export class NGFModuleRegistry {
  private static instance: NGFModuleRegistry | null = null;
  private readonly registrations: Map<string, NGFModuleRegistration> = new Map<string, NGFModuleRegistration>();

  static getInstance(): NGFModuleRegistry {
    if (!NGFModuleRegistry.instance) {
      NGFModuleRegistry.instance = new NGFModuleRegistry();
    }
    return NGFModuleRegistry.instance;
  }

  registerModule(definition: NGFModuleDefinition, runtime: IModuleBootstrap): boolean {
    const moduleName = definition.moduleName.trim();
    if (moduleName.length <= 0) {
      logger.warn(TAG, 'registerModule ignored: moduleName is empty');
      return false;
    }

    if (this.registrations.has(moduleName)) {
      logger.debug(TAG, `registerModule skipped: module=${moduleName}`);
      return false;
    }

    this.registrations.set(moduleName, new NGFModuleRegistration(definition, runtime));
    logger.info(TAG, `register module: module=${moduleName}, phase=${definition.phaseName}, order=${definition.order}`);
    return true;
  }

  hasModule(moduleName: string): boolean {
    const normalizedName = moduleName.trim();
    const exists = this.registrations.has(normalizedName);
    logger.debug(TAG, `hasModule: module=${normalizedName}, exists=${exists}`);
    return exists;
  }

  resolveModule(moduleName: string): NGFModuleRegistration | null {
    const normalizedName = moduleName.trim();
    const registration = this.registrations.get(normalizedName);
    if (!registration) {
      logger.debug(TAG, `resolveModule missed: module=${normalizedName}`);
      return null;
    }
    return registration;
  }

  listModulesByPhase(phaseName: string): Array<NGFModuleRegistration> {
    const normalizedPhase = phaseName.trim();
    const modules: Array<NGFModuleRegistration> = [];
    this.registrations.forEach((registration: NGFModuleRegistration): void => {
      if (registration.definition.phaseName === normalizedPhase) {
        modules.push(registration);
      }
    });
    modules.sort((left: NGFModuleRegistration, right: NGFModuleRegistration): number => {
      return left.definition.order - right.definition.order;
    });
    logger.debug(TAG, `listModulesByPhase: phase=${normalizedPhase}, count=${modules.length}`);
    return modules;
  }

  listAllModules(): Array<NGFModuleRegistration> {
    const modules: Array<NGFModuleRegistration> = [];
    this.registrations.forEach((registration: NGFModuleRegistration): void => {
      modules.push(registration);
    });
    modules.sort((left: NGFModuleRegistration, right: NGFModuleRegistration): number => {
      if (left.definition.order === right.definition.order) {
        if (left.definition.moduleName < right.definition.moduleName) {
          return -1;
        }
        if (left.definition.moduleName > right.definition.moduleName) {
          return 1;
        }
        return 0;
      }
      return left.definition.order - right.definition.order;
    });
    logger.debug(TAG, `listAllModules: count=${modules.length}`);
    return modules;
  }

  clear(): void {
    this.registrations.clear();
    logger.info(TAG, 'clear module registry');
  }
}

export const ngfModuleRegistry: NGFModuleRegistry = NGFModuleRegistry.getInstance();
