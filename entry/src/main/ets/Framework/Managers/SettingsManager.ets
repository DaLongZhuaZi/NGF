import { logger } from '../NGF/utils/Logger';

const TAG: string = 'NGFSettingsManager';

class SettingsManager {
  private static instance: SettingsManager | null = null;
  private readonly stringValues: Map<string, string> = new Map<string, string>();
  private readonly numberValues: Map<string, number> = new Map<string, number>();
  private readonly booleanValues: Map<string, boolean> = new Map<string, boolean>();

  static getInstance(): SettingsManager {
    if (!SettingsManager.instance) {
      SettingsManager.instance = new SettingsManager();
    }
    return SettingsManager.instance;
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
      logger.warn(TAG, 'setString ignored: key is empty');
      return;
    }
    this.stringValues.set(normalizedKey, value);
    this.numberValues.delete(normalizedKey);
    this.booleanValues.delete(normalizedKey);
    logger.info(TAG, `set string setting: key=${normalizedKey}`);
  }

  async setNumber(key: string, value: number): Promise<void> {
    const normalizedKey = key.trim();
    if (normalizedKey.length <= 0) {
      logger.warn(TAG, 'setNumber ignored: key is empty');
      return;
    }
    this.numberValues.set(normalizedKey, value);
    this.stringValues.delete(normalizedKey);
    this.booleanValues.delete(normalizedKey);
    logger.info(TAG, `set number setting: key=${normalizedKey}`);
  }

  async setBoolean(key: string, value: boolean): Promise<void> {
    const normalizedKey = key.trim();
    if (normalizedKey.length <= 0) {
      logger.warn(TAG, 'setBoolean ignored: key is empty');
      return;
    }
    this.booleanValues.set(normalizedKey, value);
    this.stringValues.delete(normalizedKey);
    this.numberValues.delete(normalizedKey);
    logger.info(TAG, `set boolean setting: key=${normalizedKey}`);
  }

  async deleteSetting(key: string): Promise<void> {
    const normalizedKey = key.trim();
    if (normalizedKey.length <= 0) {
      logger.warn(TAG, 'deleteSetting ignored: key is empty');
      return;
    }
    this.stringValues.delete(normalizedKey);
    this.numberValues.delete(normalizedKey);
    this.booleanValues.delete(normalizedKey);
    logger.info(TAG, `delete setting: key=${normalizedKey}`);
  }
}

export { SettingsManager };
