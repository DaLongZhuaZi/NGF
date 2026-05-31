import { logger } from '../../utils/Logger';
import { IAdaptiveLayout, NGFBreakpointLayoutConfig } from '../contracts/IAdaptiveLayout';
import { ngfDeviceAdaptationFacade } from './DeviceAdaptationFacade';

const TAG: string = 'NGFAdaptiveLayoutFacade';

export class AdaptiveLayoutFacade implements IAdaptiveLayout {
  private readonly configs: Map<string, NGFBreakpointLayoutConfig> = new Map<string, NGFBreakpointLayoutConfig>();

  registerConfig(config: NGFBreakpointLayoutConfig): void {
    const name = config.configName.trim();
    if (name.length <= 0) {
      logger.warn(TAG, '注册布局配置忽略: configName 为空');
      return;
    }
    this.configs.set(name, config);
    logger.info(TAG, `注册布局配置: name=${name}`);
  }

  unregisterConfig(configName: string): boolean {
    const name = configName.trim();
    if (this.configs.has(name)) {
      this.configs.delete(name);
      logger.info(TAG, `注销布局配置: name=${name}`);
      return true;
    }
    logger.warn(TAG, `注销布局配置未找到: name=${name}`);
    return false;
  }

  resolveConfig(configName: string): string {
    const name = configName.trim();
    const config = this.configs.get(name);
    if (config === undefined) {
      logger.debug(TAG, `布局配置未注册: name=${name}`);
      return '';
    }
    const breakpoint = ngfDeviceAdaptationFacade.getCurrentBreakpoint();
    const value = config.resolve(breakpoint);
    logger.debug(TAG, `解析布局配置: name=${name}, breakpoint=${breakpoint}, value=${value}`);
    return value;
  }

  hasConfig(configName: string): boolean {
    return this.configs.has(configName.trim());
  }
}

export const ngfAdaptiveLayoutFacade: AdaptiveLayoutFacade = new AdaptiveLayoutFacade();
