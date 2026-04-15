import { logger } from '../../utils/Logger';
import { uiContextManager } from '../../../Managers/UIContextManager';
import { IOhosContextBridge } from '../contracts/IOhosContextBridge';

const TAG: string = 'NGFOhosContextBridgeFacade';

export class OhosContextBridgeFacade implements IOhosContextBridge {
  private boundContextName: string = '';

  bindUIContext(contextName: string): void {
    this.boundContextName = contextName;
    logger.info(TAG, `bind UI context: contextName=${contextName}`);
  }

  clearUIContext(): void {
    const previousContextName = this.boundContextName;
    this.boundContextName = '';
    logger.info(TAG, `clear UI context: previous=${previousContextName}`);
  }

  isUIContextReady(): boolean {
    if (this.boundContextName.length <= 0) {
      logger.debug(TAG, 'isUIContextReady=false: no bound context name');
      return false;
    }

    const ready = uiContextManager.getUIContext() !== null;
    logger.debug(TAG, `isUIContextReady=${ready}: contextName=${this.boundContextName}`);
    return ready;
  }

  getHostContextName(): string {
    if (this.boundContextName.length > 0) {
      logger.debug(TAG, `getHostContextName: bound=${this.boundContextName}`);
      return this.boundContextName;
    }
    if (uiContextManager.getAbilityContext()) {
      logger.debug(TAG, 'getHostContextName: resolved UIAbilityContext');
      return 'UIAbilityContext';
    }

    logger.debug(TAG, 'getHostContextName: no host context');
    return '';
  }
}

export const ngfOhosContextBridgeFacade = new OhosContextBridgeFacade();
