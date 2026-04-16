import { logger } from './NGF/utils/Logger';

const TAG: string = 'NGFDependencyContainer';

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
}

export class DependencyContainer {
  private static instance: DependencyContainer | null = null;
  private readonly registrations: Map<string, DependencyRegistration> = new Map<string, DependencyRegistration>();

  static getInstance(): DependencyContainer {
    if (!DependencyContainer.instance) {
      DependencyContainer.instance = new DependencyContainer();
    }
    return DependencyContainer.instance;
  }

  register(token: string, factory: DependencyFactory, lifecycle: ContainerLifecycle): void {
    const normalizedToken = token.trim();
    if (normalizedToken.length <= 0) {
      logger.warn(TAG, 'register ignored: token is empty');
      return;
    }
    this.registrations.set(normalizedToken, new DependencyRegistration(normalizedToken, factory, lifecycle));
    logger.info(TAG, `register dependency: token=${normalizedToken}, lifecycle=${lifecycle}`);
  }

  isRegistered(token: string): boolean {
    const normalizedToken = token.trim();
    return this.registrations.has(normalizedToken);
  }

  resolve(token: string): object | null {
    const normalizedToken = token.trim();
    const registration = this.registrations.get(normalizedToken);
    if (!registration) {
      logger.warn(TAG, `resolve missed: token=${normalizedToken}`);
      return null;
    }
    const instance = registration.resolve();
    logger.debug(TAG, `resolve dependency: token=${normalizedToken}`);
    return instance;
  }

  clear(): void {
    this.registrations.clear();
    logger.info(TAG, 'clear dependency registrations');
  }
}
