import { logger } from '../NGF/utils/Logger';
import { NGFAbilityContextLike } from '../../GlobalContext';

const TAG: string = 'NGFUIContextManager';

class UIContextManager {
  private static instance: UIContextManager | null = null;
  private uiContext: Object | null = null;
  private abilityContext: NGFAbilityContextLike | null = null;

  static getInstance(): UIContextManager {
    if (!UIContextManager.instance) {
      UIContextManager.instance = new UIContextManager();
    }
    return UIContextManager.instance;
  }

  bindUIContext(context: Object): void {
    this.uiContext = context;
    logger.info(TAG, 'bind UIContext');
  }

  clearUIContext(): void {
    this.uiContext = null;
    logger.info(TAG, 'clear UIContext');
  }

  getUIContext(): Object | null {
    return this.uiContext;
  }

  bindAbilityContext(context: NGFAbilityContextLike): void {
    this.abilityContext = context;
    logger.info(TAG, `bind ability context: filesDir=${context.filesDir}`);
  }

  clearAbilityContext(): void {
    this.abilityContext = null;
    logger.info(TAG, 'clear ability context');
  }

  getAbilityContext(): NGFAbilityContextLike | null {
    return this.abilityContext;
  }
}

export const uiContextManager: UIContextManager = UIContextManager.getInstance();
