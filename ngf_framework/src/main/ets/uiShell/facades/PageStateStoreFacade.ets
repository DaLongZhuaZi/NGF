import { logger } from '../../utils/Logger';
import { SettingsManager } from '../../data/SettingsManager';
import { IPageStateStore, NGFPageStateSnapshot } from '../contracts/IPageStateStore';

const TAG: string = 'NGFPageStateStoreFacade';
const KEY_PREFIX: string = 'page_state_';

export class PageStateStoreFacade implements IPageStateStore {
  private readonly cache: Map<string, NGFPageStateSnapshot> = new Map<string, NGFPageStateSnapshot>();

  savePageState(pageName: string, stateJson: string): void {
    const key = KEY_PREFIX + pageName;
    const snapshot = new NGFPageStateSnapshot(pageName, stateJson, Date.now());
    this.cache.set(pageName, snapshot);
    void SettingsManager.getInstance().setString(key, stateJson);
    logger.debug(TAG, `保存页面状态: page=${pageName}, length=${stateJson.length}`);
  }

  restorePageState(pageName: string): NGFPageStateSnapshot | null {
    const cached = this.cache.get(pageName);
    if (cached !== undefined) {
      return cached;
    }

    const key = KEY_PREFIX + pageName;
    const stateJson = SettingsManager.getInstance().getString(key, '');
    if (stateJson.length <= 0) {
      return null;
    }

    const snapshot = new NGFPageStateSnapshot(pageName, stateJson, Date.now());
    this.cache.set(pageName, snapshot);
    logger.debug(TAG, `恢复页面状态: page=${pageName}, length=${stateJson.length}`);
    return snapshot;
  }

  removePageState(pageName: string): boolean {
    const key = KEY_PREFIX + pageName;
    const existed = this.cache.has(pageName);
    this.cache.delete(pageName);
    void SettingsManager.getInstance().setString(key, '');
    logger.debug(TAG, `移除页面状态: page=${pageName}, existed=${existed}`);
    return existed;
  }

  listSavedPages(): Array<string> {
    const names: Array<string> = [];
    const keys = this.cache.keys();
    for (const key of keys) {
      names.push(key);
    }
    logger.debug(TAG, `列出已保存页面: count=${names.length}`);
    return names;
  }

  clearAll(): void {
    const keys = this.cache.keys();
    for (const key of keys) {
      const settingsKey = KEY_PREFIX + key;
      void SettingsManager.getInstance().setString(settingsKey, '');
    }
    this.cache.clear();
    logger.info(TAG, '清除所有页面状态');
  }
}

export const ngfPageStateStoreFacade: PageStateStoreFacade = new PageStateStoreFacade();
