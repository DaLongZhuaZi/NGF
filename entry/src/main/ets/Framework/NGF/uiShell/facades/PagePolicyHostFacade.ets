import { logger } from '../../utils/Logger';
import { DisplayMode } from '../../../../Utils/WindowManager';
import { PageWindowCoordinator } from '../../../../Utils/PageWindowCoordinator';
import { uiContextManager } from '../../../Managers/UIContextManager';
import { IPagePolicyHost } from '../contracts/IPagePolicyHost';

const TAG: string = 'NGFPagePolicyHostFacade';

export class PagePolicyHostFacade implements IPagePolicyHost {
  applyPolicy(pageName: string): void {
    logger.info(TAG, `apply page policy: page=${pageName}`);
    try {
      const uiContext = uiContextManager.getUIContext();
      PageWindowCoordinator.applyPagePolicy(pageName, uiContext ?? undefined);
    } catch (error) {
      logger.error(TAG, `applyPolicy failed: page=${pageName}, error=${this.errorToString(error as Object | string | number | boolean)}`);
      throw error as Error;
    }
  }

  reapplyPolicy(pageName: string): void {
    logger.info(TAG, `reapply page policy: page=${pageName}`);
    try {
      const uiContext = uiContextManager.getUIContext();
      PageWindowCoordinator.reapplyPagePolicy(pageName, uiContext ?? undefined);
    } catch (error) {
      logger.error(TAG, `reapplyPolicy failed: page=${pageName}, error=${this.errorToString(error as Object | string | number | boolean)}`);
      throw error as Error;
    }
  }

  resolveDisplayMode(pageName: string): string {
    const mode = PageWindowCoordinator.resolveDisplayModeForPage(pageName);
    const resolvedMode = mode ? mode : DisplayMode.DEFAULT;
    logger.debug(TAG, `resolveDisplayMode: page=${pageName}, mode=${resolvedMode}`);
    return resolvedMode;
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

export const ngfPagePolicyHostFacade = new PagePolicyHostFacade();
