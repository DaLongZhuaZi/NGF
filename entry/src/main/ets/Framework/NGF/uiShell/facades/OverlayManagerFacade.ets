import { ComponentContent, promptAction } from '@kit.ArkUI';
import { IOverlayManager } from '../contracts/IOverlayManager';
import { logger } from '../../utils/Logger';
import { uiContextManager } from '../../platformOhos/UIContextManager';

const TAG: string = 'OverlayManagerFacade';

export class OverlayManagerFacade implements IOverlayManager {
  showCustomDialog(content: ComponentContent<object>): void {
    const uiContext = uiContextManager.getUIContext();
    if (!uiContext) {
      logger.error(TAG, 'showCustomDialog failed: UIContext not found.');
      return;
    }
    
    try {
      const promptAction = uiContext.getPromptAction();
      promptAction.openCustomDialog(content).catch((e: Error) => {
        logger.error(TAG, `openCustomDialog failed with promise rejection: ${e}`);
      });
      logger.info(TAG, 'showCustomDialog triggered.');
    } catch (e) {
      logger.error(TAG, `showCustomDialog failed: ${e}`);
    }
  }

  hideCustomDialog(content: ComponentContent<object>): void {
    const uiContext = uiContextManager.getUIContext();
    if (!uiContext) {
      logger.error(TAG, 'hideCustomDialog failed: UIContext not found.');
      return;
    }
    
    try {
      const promptAction = uiContext.getPromptAction();
      promptAction.closeCustomDialog(content).catch((e: Error) => {
        logger.error(TAG, `closeCustomDialog failed with promise rejection: ${e}`);
      });
      logger.info(TAG, 'hideCustomDialog triggered.');
    } catch (e) {
      logger.error(TAG, `hideCustomDialog failed: ${e}`);
    }
  }

  showToast(message: string): void {
    const uiContext = uiContextManager.getUIContext();
    if (uiContext) {
      try {
        uiContext.getPromptAction().openToast({
          message: message,
          duration: 2000
        });
        return;
      } catch (e) {
        logger.warn(TAG, `UIContext openToast failed, falling back to global: ${e}`);
      }
    }
    
    // Fallback to global promptAction if uiContext fails or is missing
    try {
      promptAction.openToast({
        message: message,
        duration: 2000
      });
    } catch (e) {
      logger.error(TAG, `Global promptAction.openToast failed: ${e}`);
    }
  }
}

export const ngfOverlayManagerFacade = new OverlayManagerFacade();
