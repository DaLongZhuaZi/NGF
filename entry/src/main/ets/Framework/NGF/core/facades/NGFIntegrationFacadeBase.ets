import { logger } from '../../utils/Logger';
import { ContainerLifecycle, DependencyContainer } from '../DependencyContainer';
import { IModuleBootstrap } from '../contracts/IModuleBootstrap';
import { NGFServiceRegistration } from '../contracts/NGFServiceRegistration';
import { ngfServiceContainerFacade } from './ServiceContainerFacade';

export abstract class NGFIntegrationFacadeBase implements IModuleBootstrap {
  private bootstrapped: boolean = false;

  protected abstract readonly tag: string;
  protected abstract readonly appStorageKey: string;
  protected abstract getServiceRegistrations(): Array<NGFServiceRegistration>;

  bootstrap(): boolean {
    if (this.bootstrapped) {
      return true;
    }

    try {
      const container = DependencyContainer.getInstance();
      const registrations = this.getServiceRegistrations();
      for (let index = 0; index < registrations.length; index++) {
        this.register(container, registrations[index]);
      }
      this.onBootstrapped();
      this.bootstrapped = true;
      this.syncAppStorage(true);
      logger.info(this.tag, `${this.tag} 集成完成`);
      return true;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.syncAppStorage(false);
      logger.error(this.tag, `${this.tag} 集成失败：${message}`);
      return false;
    }
  }

  isBootstrapped(): boolean {
    return this.bootstrapped;
  }

  protected onBootstrapped(): void {
    // Override in subclass for post-bootstrap hooks
  }

  private register(container: DependencyContainer, registration: NGFServiceRegistration): void {
    if (!container.isRegistered(registration.token)) {
      container.register(registration.token, (): object => {
        return registration.service;
      }, ContainerLifecycle.SINGLETON);
    }

    if (!ngfServiceContainerFacade.contains(registration.token)) {
      ngfServiceContainerFacade.registerSingleton(registration.token, registration.implementationName);
    }
  }

  private syncAppStorage(success: boolean): void {
    AppStorage.setOrCreate(this.appStorageKey, success);
    if (success) {
      AppStorage.setOrCreate(`${this.appStorageKey}_at`, Date.now());
    }
  }
}
