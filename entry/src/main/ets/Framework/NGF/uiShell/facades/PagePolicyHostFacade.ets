import { logger } from '../../utils/Logger';
import { IPagePolicyHost } from '../contracts/IPagePolicyHost';
import { NGFDisplayMode } from '../../platformOhos/contracts/IPlatformWindowController';
import { ngfPlatformWindowManagerFacade } from '../../platformOhos/facades/PlatformWindowManagerFacade';

const TAG: string = 'NGFPagePolicyHostFacade';

export class PagePolicyHostFacade implements IPagePolicyHost {
  applyPolicy(pageName: string): void {
    logger.info(TAG, `应用页面策略: page=${pageName}`);
    try {
      ngfPlatformWindowManagerFacade.activatePage(pageName);
    } catch (error) {
      logger.error(TAG, `应用策略失败: page=${pageName}, error=${this.errorToString(error as Object | string | number | boolean)}`);
      throw error as Error;
    }
  }

  reapplyPolicy(pageName: string): void {
    logger.info(TAG, `重新应用页面策略: page=${pageName}`);
    try {
      const profile = ngfPlatformWindowManagerFacade.resolvePageProfile(pageName);
      if (ngfPlatformWindowManagerFacade.getActivePageName() !== pageName) {
        ngfPlatformWindowManagerFacade.activatePage(pageName);
      }
      const delayMs = profile ? profile.reapplyDelayMs : 0;
      ngfPlatformWindowManagerFacade.reapplyActivePage(delayMs);
    } catch (error) {
      logger.error(TAG, `重新应用策略失败: page=${pageName}, error=${this.errorToString(error as Object | string | number | boolean)}`);
      throw error as Error;
    }
  }

  resolveDisplayMode(pageName: string): string {
    const profile = ngfPlatformWindowManagerFacade.resolvePageProfile(pageName);
    const resolvedMode = profile ? profile.displayMode : NGFDisplayMode.DEFAULT;
    logger.debug(TAG, `解析显示模式: page=${pageName}, mode=${resolvedMode}`);
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
