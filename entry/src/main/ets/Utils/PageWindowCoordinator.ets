import { logger } from '../Framework/NGF/utils/Logger';
import { PageWindowRegistry } from './PageWindowRegistry';
import { WindowManager, DisplayMode } from './WindowManager';

const TAG: string = 'NGFPageWindowCoordinator';

export class PageWindowCoordinator {
  static applyPagePolicy(pageName: string, uiContext?: Object): void {
    const resolvedMode = PageWindowCoordinator.resolveDisplayModeForPage(pageName);
    const displayMode = resolvedMode ? resolvedMode : DisplayMode.DEFAULT;
    WindowManager.setDisplayMode(displayMode, uiContext);
    logger.info(TAG, `apply page policy: page=${pageName}, mode=${displayMode}`);
  }

  static reapplyPagePolicy(pageName: string, uiContext?: Object): void {
    const resolvedMode = PageWindowCoordinator.resolveDisplayModeForPage(pageName);
    const displayMode = resolvedMode ? resolvedMode : WindowManager.getCurrentMode();
    WindowManager.setDisplayMode(displayMode, uiContext);
    logger.info(TAG, `reapply page policy: page=${pageName}, mode=${displayMode}`);
  }

  static resolveDisplayModeForPage(pageName: string): DisplayMode | null {
    const spec = PageWindowRegistry.getSpec(pageName);
    if (!spec) {
      logger.debug(TAG, `resolve display mode missed: page=${pageName}`);
      return null;
    }
    logger.debug(TAG, `resolve display mode: page=${pageName}, mode=${spec.fallbackDisplayMode}`);
    return spec.fallbackDisplayMode;
  }
}
