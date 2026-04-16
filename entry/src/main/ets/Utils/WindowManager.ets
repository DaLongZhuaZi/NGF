import { logger } from '../Framework/NGF/utils/Logger';

const TAG: string = 'NGFLegacyWindowManager';

export enum DisplayMode {
  DEFAULT = 'default',
  FULL_IMMERSIVE = 'full_immersive',
  IMMERSIVE_WITH_BARS = 'immersive_with_bars',
  STATUS_SAFE_BOTTOM_IMMERSIVE = 'status_safe_bottom_immersive',
  HIDE_STATUS_BAR = 'hide_status_bar',
  HIDE_NAVIGATION_BAR = 'hide_navigation_bar'
}

export class WindowManager {
  private static currentMode: DisplayMode = DisplayMode.DEFAULT;

  static setDisplayMode(mode: DisplayMode, uiContext?: Object): void {
    WindowManager.currentMode = mode;
    const hasUiContext = uiContext ? 'true' : 'false';
    logger.info(TAG, `set display mode: mode=${mode}, hasUiContext=${hasUiContext}`);
  }

  static getCurrentMode(): DisplayMode {
    return WindowManager.currentMode;
  }

  static reapplyCurrentDisplayMode(delayMs: number): void {
    if (delayMs <= 0) {
      logger.debug(TAG, `reapply display mode immediately: mode=${WindowManager.currentMode}`);
      return;
    }

    setTimeout((): void => {
      logger.debug(TAG, `reapply display mode: mode=${WindowManager.currentMode}, delayMs=${delayMs}`);
    }, delayMs);
  }
}
