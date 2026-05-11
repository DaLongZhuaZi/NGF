import { common } from '@kit.AbilityKit';
import dataPreferences from '@ohos.data.preferences';
import { logger } from '../utils/Logger';

const TAG: string = 'NGFSettingsManager';
const PREFERENCES_NAME: string = 'ngf_settings';

/**
 * 设置管理器
 * 基于 @ohos.data.preferences 实现持久化，内部维护内存缓存用于同步读取
 */
class SettingsManager {
  private static instance: SettingsManager | null = null;
  private readonly stringValues: Map<string, string> = new Map<string, string>();
  private readonly numberValues: Map<string, number> = new Map<string, number>();
  private readonly booleanValues: Map<string, boolean> = new Map<string, boolean>();
  private preferences: dataPreferences.Preferences | null = null;
  private initialized: boolean = false;

  private constructor() {
    // 私有构造函数，确保单例模式
  }

  static getInstance(): SettingsManager {
    if (!SettingsManager.instance) {
      SettingsManager.instance = new SettingsManager();
    }
    return SettingsManager.instance;
  }

  async initialize(context: common.UIAbilityContext): Promise<void> {
    if (this.initialized) {
      logger.debug(TAG, '已初始化，跳过');
      return;
    }
    try {
      this.preferences = await dataPreferences.getPreferences(context, PREFERENCES_NAME);
      await this.loadFromPreferences();
      this.initialized = true;
      logger.info(TAG, 'Preferences 初始化完成');
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `Preferences 初始化失败: ${message}`);
    }
  }

  getString(key: string, defaultValue: string): string {
    const normalizedKey = key.trim();
    if (normalizedKey.length <= 0) {
      return defaultValue;
    }
    const value = this.stringValues.get(normalizedKey);
    return value !== undefined ? value : defaultValue;
  }

  getNumber(key: string, defaultValue: number): number {
    const normalizedKey = key.trim();
    if (normalizedKey.length <= 0) {
      return defaultValue;
    }
    const value = this.numberValues.get(normalizedKey);
    return value !== undefined ? value : defaultValue;
  }

  getBoolean(key: string, defaultValue: boolean): boolean {
    const normalizedKey = key.trim();
    if (normalizedKey.length <= 0) {
      return defaultValue;
    }
    const value = this.booleanValues.get(normalizedKey);
    return value !== undefined ? value : defaultValue;
  }

  async setString(key: string, value: string): Promise<void> {
    const normalizedKey = key.trim();
    if (normalizedKey.length <= 0) {
      logger.warn(TAG, 'setString 忽略：key 为空');
      return;
    }
    this.stringValues.set(normalizedKey, value);
    this.numberValues.delete(normalizedKey);
    this.booleanValues.delete(normalizedKey);
    await this.persistToPreferences(normalizedKey, value);
    logger.info(TAG, `设置字符串配置：key=${normalizedKey}`);
  }

  async setNumber(key: string, value: number): Promise<void> {
    const normalizedKey = key.trim();
    if (normalizedKey.length <= 0) {
      logger.warn(TAG, 'setNumber 忽略：key 为空');
      return;
    }
    this.numberValues.set(normalizedKey, value);
    this.stringValues.delete(normalizedKey);
    this.booleanValues.delete(normalizedKey);
    await this.persistToPreferences(normalizedKey, value);
    logger.info(TAG, `设置数值配置：key=${normalizedKey}`);
  }

  async setBoolean(key: string, value: boolean): Promise<void> {
    const normalizedKey = key.trim();
    if (normalizedKey.length <= 0) {
      logger.warn(TAG, 'setBoolean 忽略：key 为空');
      return;
    }
    this.booleanValues.set(normalizedKey, value);
    this.stringValues.delete(normalizedKey);
    this.numberValues.delete(normalizedKey);
    await this.persistToPreferences(normalizedKey, value);
    logger.info(TAG, `设置布尔配置：key=${normalizedKey}`);
  }

  async deleteSetting(key: string): Promise<void> {
    const normalizedKey = key.trim();
    if (normalizedKey.length <= 0) {
      logger.warn(TAG, 'deleteSetting 忽略：key 为空');
      return;
    }
    this.stringValues.delete(normalizedKey);
    this.numberValues.delete(normalizedKey);
    this.booleanValues.delete(normalizedKey);
    await this.deleteFromPreferences(normalizedKey);
    logger.info(TAG, `删除配置：key=${normalizedKey}`);
  }

  isInitialized(): boolean {
    return this.initialized;
  }

  private async loadFromPreferences(): Promise<void> {
    const prefs = this.preferences;
    if (prefs === null) {
      return;
    }
    try {
      const all = await prefs.getAll();
      const entries = Object.entries(all) as [string, dataPreferences.ValueType][];
      for (let index = 0; index < entries.length; index++) {
        const entry = entries[index];
        const key = entry[0];
        const value = entry[1];
        if (typeof value === 'string') {
          this.stringValues.set(key, value);
        } else if (typeof value === 'number') {
          this.numberValues.set(key, value);
        } else if (typeof value === 'boolean') {
          this.booleanValues.set(key, value);
        }
      }
      logger.info(TAG, `从 Preferences 加载 ${entries.length} 条配置`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `加载 Preferences 数据失败: ${message}`);
    }
  }

  private async persistToPreferences(key: string, value: dataPreferences.ValueType): Promise<void> {
    const prefs = this.preferences;
    if (prefs === null) {
      logger.debug(TAG, `Preferences 未初始化，仅缓存: key=${key}`);
      return;
    }
    try {
      await prefs.put(key, value);
      await prefs.flush();
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `持久化写入失败: key=${key}, error=${message}`);
    }
  }

  private async deleteFromPreferences(key: string): Promise<void> {
    const prefs = this.preferences;
    if (prefs === null) {
      logger.debug(TAG, `Preferences 未初始化，仅清除缓存: key=${key}`);
      return;
    }
    try {
      await prefs.delete(key);
      await prefs.flush();
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `持久化删除失败: key=${key}, error=${message}`);
    }
  }
}

export { SettingsManager };
