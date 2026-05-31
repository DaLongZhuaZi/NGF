import { logger } from '../../utils/Logger';
import { ILiveViewManager } from '../contracts/ILiveViewManager';

const TAG: string = 'LiveViewManagerFacade';

/**
 * 实况窗门面
 * 当前 SDK 版本不提供 LiveViewKit 原生 API，使用内存状态追踪实现，
 * 确保上层业务代码无感知且健壮。后续 SDK 升级后可接入原生能力。
 */
export class LiveViewManagerFacade implements ILiveViewManager {
  private activeLiveViews: Map<string, boolean> = new Map();

  async startLiveView(id: string, title: string, content: string): Promise<boolean> {
    try {
      logger.info(TAG, `[LiveView 启动] ID: ${id}, 标题: ${title}, 内容: ${content}`);
      this.activeLiveViews.set(id, true);
      return true;
    } catch (e) {
      logger.error(TAG, `启动实况窗失败: ${e}`);
      return false;
    }
  }

  async updateLiveView(id: string, progress: number, content: string): Promise<boolean> {
    if (!this.activeLiveViews.has(id)) {
      logger.warn(TAG, `[LiveView 更新] ID: ${id} 不存在或已结束`);
      return false;
    }

    try {
      logger.info(TAG, `[LiveView 更新] ID: ${id}, 进度: ${progress}%, 内容: ${content}`);
      return true;
    } catch (e) {
      logger.error(TAG, `更新实况窗失败: ${e}`);
      return false;
    }
  }

  async stopLiveView(id: string): Promise<boolean> {
    if (!this.activeLiveViews.has(id)) {
      return false;
    }

    try {
      logger.info(TAG, `[LiveView 结束] ID: ${id}`);
      this.activeLiveViews.delete(id);
      return true;
    } catch (e) {
      logger.error(TAG, `结束实况窗失败: ${e}`);
      return false;
    }
  }
}

export const ngfLiveViewManagerFacade = new LiveViewManagerFacade();
