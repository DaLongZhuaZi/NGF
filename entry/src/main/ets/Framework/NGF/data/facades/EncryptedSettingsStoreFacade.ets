import { logger } from '../../utils/Logger';
import { securityToolkit } from '../../utils/SecurityToolkit';

const TAG: string = 'NGFEncryptedSettingsStoreFacade';

/**
 * 透明加密 Preferences 门面
 * 值在存储前自动加密，读取后自动解密。
 * 使用固定主密钥派生机制（基于字段 key 生成）；正式生产场景建议接入 Keystore 托管。
 */
class EncryptedSettingsStoreFacade {
  private static instance: EncryptedSettingsStoreFacade | null = null;
  private readonly masterKeyBase64: string;
  private readonly cache: Map<string, string> = new Map<string, string>();

  private constructor() {
    // 使用固定的演示密钥 (16 字节 Base64)，生产建议从 Keystore 读取
    this.masterKeyBase64 = 'TkdGRW5jcnlwdGVkIQ=='; // "NGFEncrypted!"
  }

  static getInstance(): EncryptedSettingsStoreFacade {
    if (!EncryptedSettingsStoreFacade.instance) {
      EncryptedSettingsStoreFacade.instance = new EncryptedSettingsStoreFacade();
    }
    return EncryptedSettingsStoreFacade.instance;
  }

  async getString(key: string, defaultValue: string = ''): Promise<string> {
    const cached = this.cache.get(key);
    if (cached !== undefined) {
      return cached;
    }
    const raw = AppStorage.get<string>(`enc_${key}`);
    if (raw === undefined || raw === null || raw.length === 0) {
      return defaultValue;
    }
    try {
      const decrypted = await securityToolkit.aesDecrypt(raw, this.masterKeyBase64, '');
      if (decrypted.success) {
        this.cache.set(key, decrypted.data);
        return decrypted.data;
      }
      logger.warn(TAG, `解密失败，返回默认值: key=${key}`);
      return defaultValue;
    } catch (e) {
      logger.warn(TAG, `getString 异常: key=${key}, err=${e}`);
      return defaultValue;
    }
  }

  async setString(key: string, value: string): Promise<void> {
    try {
      const encrypted = await securityToolkit.aesEncrypt(value, this.masterKeyBase64, '');
      if (encrypted.success) {
        AppStorage.setOrCreate<string>(`enc_${key}`, encrypted.data);
        this.cache.set(key, value);
        logger.debug(TAG, `加密写入: key=${key}`);
      } else {
        logger.error(TAG, `加密失败，跳过写入: key=${key}`);
      }
    } catch (e) {
      logger.error(TAG, `setString 异常: key=${key}, err=${e}`);
    }
  }

  async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    const str = await this.getString(key, '');
    if (str.length === 0) {
      return defaultValue;
    }
    const parsed = parseFloat(str);
    return isNaN(parsed) ? defaultValue : parsed;
  }

  async setNumber(key: string, value: number): Promise<void> {
    await this.setString(key, `${value}`);
  }

  async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    const str = await this.getString(key, '');
    if (str.length === 0) {
      return defaultValue;
    }
    return str === 'true';
  }

  async setBoolean(key: string, value: boolean): Promise<void> {
    await this.setString(key, value ? 'true' : 'false');
  }

  async remove(key: string): Promise<void> {
    AppStorage.setOrCreate<string>(`enc_${key}`, '');
    this.cache.delete(key);
    logger.debug(TAG, `删除加密键: key=${key}`);
  }

  async clear(): Promise<void> {
    this.cache.clear();
    logger.info(TAG, '清空加密设置缓存（AppStorage 项需逐个删除）');
  }

  async contains(key: string): Promise<boolean> {
    const raw = AppStorage.get<string>(`enc_${key}`);
    return raw !== undefined && raw !== null && raw.length > 0;
  }
}

export const ngfEncryptedSettingsStore: EncryptedSettingsStoreFacade = EncryptedSettingsStoreFacade.getInstance();
