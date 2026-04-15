import { logger } from '../../../../Utils/Logger';
import { SettingsManager } from '../../../Managers/SettingsManager';
import { ISettingsStore } from '../contracts/ISettingsStore';

const TAG = 'NGFSettingsStoreFacade';

export class SettingsStoreFacade implements ISettingsStore {
  private readonly settingsManager: SettingsManager = SettingsManager.getInstance();

  getString(key: string, defaultValue: string): string {
    const value = this.settingsManager.getString(key, defaultValue);
    logger.debug(TAG, `读取字符串设置: key=${key}`);
    return value;
  }

  getNumber(key: string, defaultValue: number): number {
    const value = this.settingsManager.getNumber(key, defaultValue);
    logger.debug(TAG, `读取数字设置: key=${key}`);
    return value;
  }

  getBoolean(key: string, defaultValue: boolean): boolean {
    const value = this.settingsManager.getBoolean(key, defaultValue);
    logger.debug(TAG, `读取布尔设置: key=${key}`);
    return value;
  }

  setString(key: string, value: string): void {
    logger.info(TAG, `写入字符串设置: key=${key}`);
    void this.persistString(key, value);
  }

  setNumber(key: string, value: number): void {
    logger.info(TAG, `写入数字设置: key=${key}`);
    void this.persistNumber(key, value);
  }

  setBoolean(key: string, value: boolean): void {
    logger.info(TAG, `写入布尔设置: key=${key}`);
    void this.persistBoolean(key, value);
  }

  private async persistString(key: string, value: string): Promise<void> {
    try {
      await this.settingsManager.setString(key, value);
    } catch {
      logger.warn(TAG, `璁剧疆瀛楃涓插け璐? key=${key}`);
    }
  }

  private async persistNumber(key: string, value: number): Promise<void> {
    try {
      await this.settingsManager.setNumber(key, value);
    } catch {
      logger.warn(TAG, `璁剧疆鏁板瓧澶辫触: key=${key}`);
    }
  }

  private async persistBoolean(key: string, value: boolean): Promise<void> {
    try {
      await this.settingsManager.setBoolean(key, value);
    } catch {
      logger.warn(TAG, `璁剧疆甯冨皵澶辫触: key=${key}`);
    }
  }
}

export const ngfSettingsStoreFacade = new SettingsStoreFacade();
