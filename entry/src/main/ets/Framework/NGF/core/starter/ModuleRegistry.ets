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
      logger.warn(TAG, '注册模块已忽略：模块名为空');
      return false;
    }

    if (this.registrations.has(moduleName)) {
      logger.debug(TAG, `注册模块已跳过：模块=${moduleName}`);
      return false;
    }

    this.registrations.set(moduleName, new NGFModuleRegistration(definition, runtime));
    logger.info(TAG, `注册模块：模块=${moduleName}, 阶段=${definition.phaseName}, 顺序=${definition.order}`);
    return true;
  }

  hasModule(moduleName: string): boolean {
    const normalizedName = moduleName.trim();
    const exists = this.registrations.has(normalizedName);
    logger.debug(TAG, `查询模块：模块=${normalizedName}, 存在=${exists}`);
    return exists;
  }

  resolveModule(moduleName: string): NGFModuleRegistration | null {
    const normalizedName = moduleName.trim();
    const registration = this.registrations.get(normalizedName);
    if (!registration) {
      logger.debug(TAG, `解析模块未命中：模块=${normalizedName}`);
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
    logger.debug(TAG, `按阶段列出模块：阶段=${normalizedPhase}, 数量=${modules.length}`);
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
    logger.debug(TAG, `列出全部模块：数量=${modules.length}`);
    return modules;
  }

  clear(): void {
    this.registrations.clear();
    logger.info(TAG, '清除模块注册表');
  }
}

export const ngfModuleRegistry: NGFModuleRegistry = NGFModuleRegistry.getInstance();
