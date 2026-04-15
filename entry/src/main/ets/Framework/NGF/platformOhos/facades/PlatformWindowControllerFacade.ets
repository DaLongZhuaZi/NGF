import { logger } from '../../utils/Logger';
import { WindowManager, DisplayMode } from '../../../../Utils/WindowManager';
import { uiContextManager } from '../../../Managers/UIContextManager';
import { IPlatformWindowController, NGFDisplayMode } from '../contracts/IPlatformWindowController';

const TAG: string = 'NGFPlatformWindowControllerFacade';

export class PlatformWindowControllerFacade implements IPlatformWindowController {
  setDisplayMode(mode: NGFDisplayMode): void {
    const previousMode = this.toNGFMode(WindowManager.getCurrentMode());
    logger.stateChange(TAG, previousMode, mode, 'apply display mode');

    try {
      const uiContext = uiContextManager.getUIContext();
      WindowManager.setDisplayMode(this.toLegacyMode(mode), uiContext ?? undefined);
      logger.info(TAG, `display mode applied: mode=${mode}`);
    } catch (error) {
      logger.error(TAG, `setDisplayMode failed: ${this.errorToString(error as Object | string | number | boolean)}`);
      throw error;
    }
  }

  getCurrentDisplayMode(): NGFDisplayMode {
    const currentMode = this.toNGFMode(WindowManager.getCurrentMode());
    logger.debug(TAG, `getCurrentDisplayMode: mode=${currentMode}`);
    return currentMode;
  }

  reapplyCurrentDisplayMode(delayMs: number): void {
    logger.info(TAG, `reapply current display mode: delayMs=${delayMs}`);
    try {
      WindowManager.reapplyCurrentDisplayMode(delayMs);
    } catch (error) {
      logger.error(TAG, `reapplyCurrentDisplayMode failed: ${this.errorToString(error as Object | string | number | boolean)}`);
      throw error;
    }
  }

  private toLegacyMode(mode: NGFDisplayMode): DisplayMode {
    switch (mode) {
      case NGFDisplayMode.FULL_IMMERSIVE:
        return DisplayMode.FULL_IMMERSIVE;
      case NGFDisplayMode.IMMERSIVE_WITH_BARS:
        return DisplayMode.IMMERSIVE_WITH_BARS;
      case NGFDisplayMode.STATUS_SAFE_BOTTOM_IMMERSIVE:
        return DisplayMode.STATUS_SAFE_BOTTOM_IMMERSIVE;
      case NGFDisplayMode.DEFAULT:
      default:
        return DisplayMode.DEFAULT;
    }
  }

  private toNGFMode(mode: DisplayMode): NGFDisplayMode {
    switch (mode) {
      case DisplayMode.FULL_IMMERSIVE:
        return NGFDisplayMode.FULL_IMMERSIVE;
      case DisplayMode.IMMERSIVE_WITH_BARS:
        return NGFDisplayMode.IMMERSIVE_WITH_BARS;
      case DisplayMode.STATUS_SAFE_BOTTOM_IMMERSIVE:
        return NGFDisplayMode.STATUS_SAFE_BOTTOM_IMMERSIVE;
      case DisplayMode.DEFAULT:
      case DisplayMode.HIDE_STATUS_BAR:
      case DisplayMode.HIDE_NAVIGATION_BAR:
      default:
        return NGFDisplayMode.DEFAULT;
    }
  }

  private errorToString(error: Object | string | number | boolean): string {
    if (typeof error === 'string') {
      return error;
    }
    if (typeof error === 'number' || typeof error === 'boolean') {
      return String(error);
    }
    if (error instanceof Error) {
      return error.message;
    }
    return String(error);
  }
}

export const ngfPlatformWindowControllerFacade = new PlatformWindowControllerFacade();
