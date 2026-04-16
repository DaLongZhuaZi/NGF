import { logger } from '../../utils/Logger';
import { IServiceContainer } from '../contracts/IServiceContainer';

const TAG: string = 'NGFServiceContainerFacade';

export class ServiceContainerFacade implements IServiceContainer {
  private readonly registrations: Map<string, string> = new Map<string, string>();
  private readonly instances: Map<string, object> = new Map<string, object>();

  registerSingleton(token: string, implementationName: string): void {
    const normalizedToken = token.trim();
    const normalizedName = implementationName.trim();
    if (normalizedToken.length <= 0 || normalizedName.length <= 0) {
      logger.warn(TAG, `registerSingleton ignored: token=${normalizedToken}, implementation=${normalizedName}`);
      return;
    }
    this.registrations.set(normalizedToken, normalizedName);
    logger.info(TAG, `register singleton: token=${normalizedToken}, implementation=${normalizedName}`);
  }

  resolve(token: string): string {
    const normalizedToken = token.trim();
    const implementationName = this.registrations.get(normalizedToken);
    if (!implementationName) {
      logger.warn(TAG, `resolve service missed: token=${normalizedToken}`);
      return '';
    }
    logger.debug(TAG, `resolve service: token=${normalizedToken}, implementation=${implementationName}`);
    return implementationName;
  }

  contains(token: string): boolean {
    const normalizedToken = token.trim();
    const exists = this.registrations.has(normalizedToken);
    logger.debug(TAG, `contains service: token=${normalizedToken}, exists=${exists}`);
    return exists;
  }

  registerInstance(token: string, instance: object): void {
    const normalizedToken = token.trim();
    if (normalizedToken.length <= 0) {
      logger.warn(TAG, 'registerInstance ignored: token is empty');
      return;
    }
    this.instances.set(normalizedToken, instance);
    logger.info(TAG, `register service instance: token=${normalizedToken}`);
  }

  resolveInstance(token: string): object | null {
    const normalizedToken = token.trim();
    const instance = this.instances.get(normalizedToken);
    if (!instance) {
      logger.debug(TAG, `resolveInstance missed: token=${normalizedToken}`);
      return null;
    }
    return instance;
  }

  clear(): void {
    this.registrations.clear();
    this.instances.clear();
    logger.info(TAG, 'clear service container facade');
  }
}

export const ngfServiceContainerFacade: ServiceContainerFacade = new ServiceContainerFacade();
