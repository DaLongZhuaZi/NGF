import { logger } from '../../utils/Logger';
import { uiContextManager } from '../UIContextManager';
import { IOhosContextBridge } from '../contracts/IOhosContextBridge';

const TAG: string = 'NGFOhosContextBridgeFacade';

export class OhosContextBridgeFacade implements IOhosContextBridge {
  private boundContextName: string = '';

  bindUIContext(contextName: string): void {
    this.boundContextName = contextName;
    logger.info(TAG, `绑定 UI 上下文: contextName=${contextName}`);
  }

  clearUIContext(): void {
    const previousContextName = this.boundContextName;
    this.boundContextName = '';
    logger.info(TAG, `清除 UI 上下文: previous=${previousContextName}`);
  }

  isUIContextReady(): boolean {
    if (this.boundContextName.length <= 0) {
      logger.debug(TAG, 'isUIContextReady=false: 无绑定的上下文名称');
      return false;
    }

    const ready = uiContextManager.getUIContext() !== null;
    logger.debug(TAG, `isUIContextReady=${ready}: 已绑定上下文名称=${this.boundContextName}`);
    return ready;
  }

  getHostContextName(): string {
    if (this.boundContextName.length > 0) {
      logger.debug(TAG, `获取宿主上下文名称: 已绑定=${this.boundContextName}`);
      return this.boundContextName;
    }
    if (uiContextManager.getAbilityContext()) {
      logger.debug(TAG, '获取宿主上下文名称: 已解析为 UIAbilityContext');
      return 'UIAbilityContext';
    }

    logger.debug(TAG, '获取宿主上下文名称: 无宿主上下文');
    return '';
  }
}

export const ngfOhosContextBridgeFacade = new OhosContextBridgeFacade();
