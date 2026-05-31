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

/**
 * 模块注册表
 * @note API 23 适配：添加私有构造函数确保单例模式正确实现
 */
export class NGFModuleRegistry {
  private static instance: NGFModuleRegistry | null = null;
  private readonly registrations: Map<string, NGFModuleRegistration> = new Map<string, NGFModuleRegistration>();

  private constructor() {
    // 私有构造函数，确保单例模式
  }

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

  unregisterModule(moduleName: string): boolean {
    const normalizedName = moduleName.trim();
    if (this.registrations.has(normalizedName)) {
      this.registrations.delete(normalizedName);
      logger.info(TAG, `注销模块成功：模块=${normalizedName}`);
      return true;
    }
    logger.debug(TAG, `注销模块失败，模块不存在：模块=${normalizedName}`);
    return false;
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

  async reloadModule(moduleName: string): Promise<boolean> {
    const normalizedName = moduleName.trim();
    if (normalizedName.length <= 0) {
      logger.warn(TAG, '热重载模块已忽略：模块名为空');
      return false;
    }

    const registration = this.registrations.get(normalizedName);
    if (!registration) {
      logger.warn(TAG, `热重载模块失败，模块不存在：模块=${normalizedName}`);
      return false;
    }

    // Phase 1: Shutdown
    if (registration.runtime.isBootstrapped()) {
      try {
        const shutdownOk = registration.runtime.shutdown();
        if (!shutdownOk) {
          logger.warn(TAG, `热重载模块关闭返回失败：模块=${normalizedName}`);
        } else {
          logger.info(TAG, `热重载模块关闭成功：模块=${normalizedName}`);
        }
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        logger.error(TAG, `热重载模块关闭异常：模块=${normalizedName}, 错误=${message}`);
        return false;
      }
    }

    // Phase 2: Unregister and re-register (re-acquires fresh state)
    this.registrations.delete(normalizedName);
    const reRegisterOk = this.registerModule(registration.definition, registration.runtime);
    if (!reRegisterOk) {
      logger.warn(TAG, `热重载模块重新注册失败：模块=${normalizedName}`);
      return false;
    }

    // Phase 3: Re-bootstrap
    try {
      const bootstrapOk = registration.runtime.bootstrap();
      if (bootstrapOk) {
        logger.info(TAG, `热重载模块引导成功：模块=${normalizedName}`);
        return true;
      }
      logger.warn(TAG, `热重载模块引导返回失败：模块=${normalizedName}`);
      return false;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `热重载模块引导异常：模块=${normalizedName}, 错误=${message}`);
      return false;
    }
  }

  clear(): void {
    this.registrations.clear();
    logger.info(TAG, '清除模块注册表');
  }
}

export const ngfModuleRegistry: NGFModuleRegistry = NGFModuleRegistry.getInstance();
