import { asset } from '@kit.AssetStoreKit';
import { logger } from '../../utils/Logger';

const TAG: string = 'KeyStoreManagerFacade';

export class KeyStoreManagerFacade {
  
  /**
   * 存储极度敏感数据 (如支付密码、长期 Token) 到芯片级安全环境
   */
  static async addSecret(alias: string, secretString: string): Promise<boolean> {
    try {
      const secretBuffer = new Uint8Array(secretString.split('').map(c => c.charCodeAt(0)));
      
      const attr: asset.AssetMap = new Map();
      attr.set(asset.Tag.ALIAS, new Uint8Array(alias.split('').map(c => c.charCodeAt(0))));
      attr.set(asset.Tag.SECRET, secretBuffer);
      // 默认需要设备解锁后才能访问
      attr.set(asset.Tag.ACCESSIBILITY, asset.Accessibility.DEVICE_UNLOCKED);
      
      await asset.add(attr);
      logger.info(TAG, `安全数据存入成功: ${alias}`);
      return true;
    } catch (e) {
      logger.error(TAG, `安全数据存入失败 [${alias}]: ${e}`);
      return false;
    }
  }

  /**
   * 读取极度敏感数据
   */
  static async querySecret(alias: string): Promise<string | null> {
    try {
      const query: asset.AssetMap = new Map();
      query.set(asset.Tag.ALIAS, new Uint8Array(alias.split('').map(c => c.charCodeAt(0))));
      query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);

      const results = await asset.query(query);
      if (results && results.length > 0) {
        const secretAttr = results[0].get(asset.Tag.SECRET);
        if (secretAttr) {
          const secretArr = secretAttr as Uint8Array;
          let str = '';
          for (let i = 0; i < secretArr.length; i++) {
            str += String.fromCharCode(secretArr[i]);
          }
          logger.info(TAG, `安全数据读取成功: ${alias}`);
          return str;
        }
      }
      return null;
    } catch (e) {
      logger.error(TAG, `安全数据读取失败 [${alias}]: ${e}`);
      return null;
    }
  }

  /**
   * 删除敏感数据
   */
  static async removeSecret(alias: string): Promise<boolean> {
    try {
      const query: asset.AssetMap = new Map();
      query.set(asset.Tag.ALIAS, new Uint8Array(alias.split('').map(c => c.charCodeAt(0))));
      await asset.remove(query);
      logger.info(TAG, `安全数据删除成功: ${alias}`);
      return true;
    } catch (e) {
      logger.error(TAG, `安全数据删除失败 [${alias}]: ${e}`);
      return false;
    }
  }
}
