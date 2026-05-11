import { logger } from '../utils/Logger';

const TAG: string = 'NGFDependencyContainer';

interface NGFServiceLifecycleAware {
  initialize?(): void;
  destroy?(): void;
}

export enum ContainerLifecycle {
  SINGLETON = 'singleton',
  TRANSIENT = 'transient'
}

export type DependencyFactory = () => object;

class DependencyRegistration {
  readonly token: string;
  readonly factory: DependencyFactory;
  readonly lifecycle: ContainerLifecycle;
  private cachedInstance: object | null = null;

  constructor(token: string, factory: DependencyFactory, lifecycle: ContainerLifecycle) {
    this.token = token;
    this.factory = factory;
    this.lifecycle = lifecycle;
  }

  resolve(): object {
    if (this.lifecycle === ContainerLifecycle.SINGLETON) {
      if (!this.cachedInstance) {
        this.cachedInstance = this.factory();
      }
      return this.cachedInstance;
    }
    return this.factory();
  }

  getCachedInstance(): object | null {
    return this.cachedInstance;
  }
}

export class DependencyContainer {
  private static instance: DependencyContainer | null = null;
  private readonly registrations: Map<string, DependencyRegistration> = new Map<string, DependencyRegistration>();

  private constructor() {
    // 私有构造函数，确保单例模式
  }

  static getInstance(): DependencyContainer {
    if (!DependencyContainer.instance) {
      DependencyContainer.instance = new DependencyContainer();
    }
    return DependencyContainer.instance;
  }

  register(token: string, factory: DependencyFactory, lifecycle: ContainerLifecycle): void {
    const normalizedToken = token.trim();
    if (normalizedToken.length <= 0) {
      logger.warn(TAG, 'register 忽略：token 为空');
      return;
    }
    const registration = new DependencyRegistration(normalizedToken, factory, lifecycle);
    this.registrations.set(normalizedToken, registration);
    logger.info(TAG, `注册依赖：token=${normalizedToken}, lifecycle=${lifecycle}`);

    if (lifecycle === ContainerLifecycle.SINGLETON) {
      const instance = registration.resolve();
      this.tryInitialize(instance, normalizedToken);
    }
  }

  isRegistered(token: string): boolean {
    const normalizedToken = token.trim();
    return this.registrations.has(normalizedToken);
  }

  resolve(token: string): object | null {
    const normalizedToken = token.trim();
    const registration = this.registrations.get(normalizedToken);
    if (!registration) {
      logger.warn(TAG, `解析未命中：token=${normalizedToken}`);
      return null;
    }
    const instance = registration.resolve();
    logger.debug(TAG, `解析依赖：token=${normalizedToken}`);
    return instance;
  }

  clear(): void {
    const keys = this.registrations.keys();
    for (const key of keys) {
      const registration = this.registrations.get(key);
      if (registration !== undefined) {
        const cached = registration.getCachedInstance();
        if (cached !== null) {
          this.tryDestroy(cached, key);
        }
      }
    }
    this.registrations.clear();
    logger.info(TAG, '清除所有依赖注册');
  }

  private tryInitialize(instance: object, token: string): void {
    const aware = instance as NGFServiceLifecycleAware;
    if (aware.initialize !== undefined) {
      try {
        aware.initialize();
        logger.debug(TAG, `生命周期钩子已调用：token=${token}, method=initialize`);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        logger.warn(TAG, `生命周期钩子异常：token=${token}, method=initialize, error=${message}`);
      }
    }
  }

  private tryDestroy(instance: object, token: string): void {
    const aware = instance as NGFServiceLifecycleAware;
    if (aware.destroy !== undefined) {
      try {
        aware.destroy();
        logger.debug(TAG, `生命周期钩子已调用：token=${token}, method=destroy`);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        logger.warn(TAG, `生命周期钩子异常：token=${token}, method=destroy, error=${message}`);
      }
    }
  }
}
