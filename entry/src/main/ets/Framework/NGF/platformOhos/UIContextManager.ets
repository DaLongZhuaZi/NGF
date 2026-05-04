import { common } from '@kit.AbilityKit';
import { logger } from '../utils/Logger';
import { NGFAbilityContextLike } from '../../../GlobalContext';

const TAG: string = 'NGFUIContextManager';

class UIContextManager {
  private static instance: UIContextManager | null = null;
  private uiContext: Object | null = null;
  private abilityContext: NGFAbilityContextLike | null = null;
  private fullAbilityContext: common.UIAbilityContext | null = null;

  static getInstance(): UIContextManager {
    if (!UIContextManager.instance) {
      UIContextManager.instance = new UIContextManager();
    }
    return UIContextManager.instance;
  }

  bindUIContext(context: Object): void {
    this.uiContext = context;
    logger.info(TAG, '绑定 UIContext');
  }

  clearUIContext(): void {
    this.uiContext = null;
    logger.info(TAG, '清除 UIContext');
  }

  getUIContext(): Object | null {
    return this.uiContext;
  }

  bindAbilityContext(context: NGFAbilityContextLike): void {
    this.abilityContext = context;
    this.fullAbilityContext = context as common.UIAbilityContext;
    logger.info(TAG, `绑定 Ability 上下文: filesDir=${context.filesDir}`);
  }

  clearAbilityContext(): void {
    this.abilityContext = null;
    this.fullAbilityContext = null;
    logger.info(TAG, '清除 Ability 上下文');
  }

  getAbilityContext(): NGFAbilityContextLike | null {
    return this.abilityContext;
  }

  getFullAbilityContext(): common.UIAbilityContext | null {
    return this.fullAbilityContext;
  }
}

export const uiContextManager: UIContextManager = UIContextManager.getInstance();
