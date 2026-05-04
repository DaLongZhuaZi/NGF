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
      logger.warn(TAG, `注册单例已忽略：令牌=${normalizedToken}, 实现=${normalizedName}`);
      return;
    }
    this.registrations.set(normalizedToken, normalizedName);
    logger.info(TAG, `注册单例：令牌=${normalizedToken}, 实现=${normalizedName}`);
  }

  resolve(token: string): string {
    const normalizedToken = token.trim();
    const implementationName = this.registrations.get(normalizedToken);
    if (!implementationName) {
      logger.warn(TAG, `解析服务未命中：令牌=${normalizedToken}`);
      return '';
    }
    logger.debug(TAG, `解析服务：令牌=${normalizedToken}, 实现=${implementationName}`);
    return implementationName;
  }

  contains(token: string): boolean {
    const normalizedToken = token.trim();
    const exists = this.registrations.has(normalizedToken);
    logger.debug(TAG, `查询服务：令牌=${normalizedToken}, 存在=${exists}`);
    return exists;
  }

  registerInstance(token: string, instance: object): void {
    const normalizedToken = token.trim();
    if (normalizedToken.length <= 0) {
      logger.warn(TAG, '注册实例已忽略：令牌为空');
      return;
    }
    this.instances.set(normalizedToken, instance);
    logger.info(TAG, `注册服务实例：令牌=${normalizedToken}`);
  }

  resolveInstance(token: string): object | null {
    const normalizedToken = token.trim();
    const instance = this.instances.get(normalizedToken);
    if (!instance) {
      logger.debug(TAG, `解析实例未命中：令牌=${normalizedToken}`);
      return null;
    }
    return instance;
  }

  clear(): void {
    this.registrations.clear();
    this.instances.clear();
    logger.info(TAG, '清除服务容器外观');
  }
}

export const ngfServiceContainerFacade: ServiceContainerFacade = new ServiceContainerFacade();
