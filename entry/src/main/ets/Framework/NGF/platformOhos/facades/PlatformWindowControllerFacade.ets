import { logger } from '../../utils/Logger';
import { IPlatformWindowController, NGFDisplayMode } from '../contracts/IPlatformWindowController';
import { ngfPlatformWindowManagerFacade } from './PlatformWindowManagerFacade';

const TAG: string = 'NGFPlatformWindowControllerFacade';

export class PlatformWindowControllerFacade implements IPlatformWindowController {
  setDisplayMode(mode: NGFDisplayMode): void {
    const previousMode = ngfPlatformWindowManagerFacade.getCurrentSnapshot().displayMode;
    logger.stateChange(TAG, previousMode, mode, '应用显示模式');

    try {
      ngfPlatformWindowManagerFacade.setDisplayMode(mode);
      logger.info(TAG, `显示模式已应用: mode=${mode}`);
    } catch (error) {
      logger.error(TAG, `设置显示模式失败: ${this.errorToString(error as Object | string | number | boolean)}`);
      throw error as Error;
    }
  }

  getCurrentDisplayMode(): NGFDisplayMode {
    const currentMode = ngfPlatformWindowManagerFacade.getCurrentSnapshot().displayMode;
    logger.debug(TAG, `获取当前显示模式: mode=${currentMode}`);
    return currentMode;
  }

  reapplyCurrentDisplayMode(delayMs: number): void {
    logger.info(TAG, `重新应用当前显示模式: delayMs=${delayMs}`);
    try {
      const activePageName = ngfPlatformWindowManagerFacade.getActivePageName();
      if (activePageName.length > 0) {
        ngfPlatformWindowManagerFacade.reapplyActivePage(delayMs);
        return;
      }

      const currentMode = this.getCurrentDisplayMode();
      if (delayMs <= 0) {
        ngfPlatformWindowManagerFacade.setDisplayMode(currentMode);
        return;
      }

      setTimeout((): void => {
        ngfPlatformWindowManagerFacade.setDisplayMode(currentMode);
      }, delayMs);
    } catch (error) {
      logger.error(TAG, `重新应用显示模式失败: ${this.errorToString(error as Object | string | number | boolean)}`);
      throw error as Error;
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
