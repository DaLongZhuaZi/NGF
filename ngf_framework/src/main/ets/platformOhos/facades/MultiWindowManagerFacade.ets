import { window } from '@kit.ArkUI';
import { logger } from '../../utils/Logger';
import { IMultiWindowManager, NGFWindowMode } from '../contracts/IMultiWindowManager';
import { IPlatformWindowSnapshotObserver, NGFWindowRuntimeSnapshot, NGFWindowStatus } from '../contracts/IPlatformWindowManager';
import { ngfPlatformWindowManagerFacade } from './PlatformWindowManagerFacade';

const TAG: string = 'NGFMultiWindowManagerFacade';

class MultiWindowManagerFacade implements IMultiWindowManager, IPlatformWindowSnapshotObserver {
  private static instance: MultiWindowManagerFacade | null = null;
  private currentMode: NGFWindowMode = NGFWindowMode.UNKNOWN;
  private readonly callbacks: Array<(mode: NGFWindowMode) => void> = [];
  private initialized: boolean = false;

  private constructor() {}

  static getInstance(): MultiWindowManagerFacade {
    if (!MultiWindowManagerFacade.instance) {
      MultiWindowManagerFacade.instance = new MultiWindowManagerFacade();
    }
    return MultiWindowManagerFacade.instance;
  }

  getCurrentWindowMode(): NGFWindowMode {
    if (!this.initialized) {
      this.initialized = true;
      ngfPlatformWindowManagerFacade.subscribe('MultiWindowManagerFacade', this);
    }
    return this.currentMode;
  }

  onWindowModeChanged(callback: (mode: NGFWindowMode) => void): void {
    if (!this.initialized) {
      this.initialized = true;
      ngfPlatformWindowManagerFacade.subscribe('MultiWindowManagerFacade', this);
    }
    if (!this.callbacks.includes(callback)) {
      this.callbacks.push(callback);
    }
  }

  offWindowModeChanged(callback: (mode: NGFWindowMode) => void): void {
    const index = this.callbacks.indexOf(callback);
    if (index >= 0) {
      this.callbacks.splice(index, 1);
    }
  }

  async setWindowMode(mode: NGFWindowMode): Promise<void> {
    let windowMode: number = 1;
    switch (mode) {
      case NGFWindowMode.FULLSCREEN:
        windowMode = 1;
        break;
      case NGFWindowMode.SPLIT_SCREEN:
        windowMode = 100;
        break;
      case NGFWindowMode.FLOATING:
        windowMode = 102;
        break;
      case NGFWindowMode.UNKNOWN:
      default:
        logger.warn(TAG, `不支持的窗口模式设置: mode=${mode}`);
        return;
    }
    
    logger.info(TAG, `尝试设置窗口模式: from=${this.currentMode} to=${mode}`);
    try {
      await ngfPlatformWindowManagerFacade.setWindowMode(windowMode);
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `设置窗口模式失败: ${errMsg}`);
      throw new Error(errMsg);
    }
  }

  onWindowSnapshotChanged(snapshot: NGFWindowRuntimeSnapshot): void {
    if (!snapshot.isWindowReady) {
      return;
    }
    
    let newMode = NGFWindowMode.UNKNOWN;
    
    if (snapshot.status === NGFWindowStatus.FULL_SCREEN || snapshot.status === NGFWindowStatus.MAXIMIZE) {
      newMode = NGFWindowMode.FULLSCREEN;
    } else if (snapshot.status === NGFWindowStatus.SPLIT_SCREEN) {
      newMode = NGFWindowMode.SPLIT_SCREEN;
    } else if (snapshot.status === NGFWindowStatus.FLOATING) {
      newMode = NGFWindowMode.FLOATING;
    } else if (snapshot.isFullScreen) {
      newMode = NGFWindowMode.FULLSCREEN;
    }

    if (this.currentMode !== newMode && newMode !== NGFWindowMode.UNKNOWN) {
      this.currentMode = newMode;
      logger.info(TAG, `窗口模式变更 -> ${newMode}`);
      this.notifyCallbacks(newMode);
    }
  }

  private notifyCallbacks(mode: NGFWindowMode): void {
    for (let i = 0; i < this.callbacks.length; i++) {
      try {
        this.callbacks[i](mode);
      } catch (error) {
        logger.error(TAG, '执行窗口变更回调失败');
      }
    }
  }
}

export const ngfMultiWindowManagerFacade: MultiWindowManagerFacade = MultiWindowManagerFacade.getInstance();
