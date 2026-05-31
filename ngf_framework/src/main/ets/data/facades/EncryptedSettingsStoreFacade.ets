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

  // master key 在 AppStorage 中的持久化键名
  private static readonly MASTER_KEY_STORAGE: string = 'ngf_encrypted_master_key';
  // 生产环境应使用 HarmonyOS Keystore (HUKS) 托管密钥，此处为框架级降级方案
  private static readonly FALLBACK_STATIC_KEY: string = 'TkdGRW5jcnlwdGVkIQ=='; // "NGFEncrypted!"

  private constructor() {
    // 优先从持久化存储加载已有密钥，确保重启后能解密历史数据
    const stored = AppStorage.get<string>(EncryptedSettingsStoreFacade.MASTER_KEY_STORAGE);
    if (stored !== undefined && stored !== null && stored.length > 0) {
      this.masterKeyBase64 = stored;
    } else {
      // 尝试使用安全随机数生成新密钥
      const generated = securityToolkit.generateRandomBase64(16);
      if (generated.length > 0) {
        this.masterKeyBase64 = generated;
        // 持久化生成的密钥，避免重启后无法解密
        AppStorage.setOrCreate<string>(EncryptedSettingsStoreFacade.MASTER_KEY_STORAGE, generated);
        logger.info(TAG, '已生成新的加密主密钥并持久化');
      } else {
        // 随机数生成失败时使用静态降级密钥（仅用于开发/测试）
        this.masterKeyBase64 = EncryptedSettingsStoreFacade.FALLBACK_STATIC_KEY;
        logger.warn(TAG, '随机密钥生成失败，使用静态降级密钥（仅限开发环境）');
      }
    }
    // TODO: 生产环境应接入 HarmonyOS Keystore (HUKS) 进行密钥托管，
    //       避免密钥明文存储在 AppStorage 中。
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
