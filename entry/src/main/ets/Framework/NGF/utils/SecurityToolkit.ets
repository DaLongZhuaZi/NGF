import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';
import { logger } from './Logger';

const TAG: string = 'NGFSecurityToolkit';

/**
 * 哈希算法枚举
 */
export enum NGFHashAlgorithm {
  SHA256 = 'SHA256',
  SHA384 = 'SHA384',
  SHA512 = 'SHA512'
}

/**
 * 加密结果
 */
export class NGFEncryptResult {
  readonly success: boolean;
  readonly data: string;

  constructor(success: boolean, data: string) {
    this.success = success;
    this.data = data;
  }
}

/**
 * 安全工具
 */
class SecurityToolkit {
  private static instance: SecurityToolkit | null = null;
  private readonly base64Helper: util.Base64Helper = new util.Base64Helper();

  private constructor() {
    // 私有构造函数，确保单例模式
  }

  static getInstance(): SecurityToolkit {
    if (!SecurityToolkit.instance) {
      SecurityToolkit.instance = new SecurityToolkit();
    }
    return SecurityToolkit.instance;
  }

  /**
   * SHA 哈希
   * @param input 输入字符串
   * @param algorithm 哈希算法
   * @returns 十六进制哈希字符串
   */
  async shaHash(input: string, algorithm: NGFHashAlgorithm = NGFHashAlgorithm.SHA256): Promise<string> {
    try {
      const algoName = this.mapHashAlgorithm(algorithm);
      const md = cryptoFramework.createMd(algoName);
      const inputBlob: cryptoFramework.DataBlob = { data: this.stringToUint8Array(input) };
      await md.update(inputBlob);
      const digest = await md.digest();
      return this.arrayBufferToHex(digest.data);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `SHA 哈希失败: ${message}`);
      throw new Error(`SHA hash failed: ${message}`);
    }
  }

  /**
   * AES-GCM 加密
   * @param plainText 明文
   * @param keyBase64 Base64 编码的 AES 密钥 (16 字节)
   * @param ivBase64 Base64 编码的 12 字节 IV；为空时自动生成
   * @returns Base64 编码的 (IV + 密文 + authTag)
   */
  async aesEncrypt(plainText: string, keyBase64: string, ivBase64: string): Promise<NGFEncryptResult> {
    try {
      const ivBytes: Uint8Array = ivBase64.length > 0
        ? this.base64ToUint8Array(ivBase64)
        : this.generateRandomBytes(12);
      const keyBlob: cryptoFramework.DataBlob = { data: this.base64ToUint8Array(keyBase64) };
      const ivBlob: cryptoFramework.DataBlob = { data: ivBytes };
      const emptyAad: cryptoFramework.DataBlob = { data: new Uint8Array(0) };
      const emptyTag: cryptoFramework.DataBlob = { data: new Uint8Array(0) };
      const gcmParams: cryptoFramework.GcmParamsSpec = {
        algName: 'AES128|GCM|PKCS7',
        iv: ivBlob,
        aad: emptyAad,
        authTag: emptyTag
      };
      const cipher = cryptoFramework.createCipher('AES128|GCM|PKCS7');
      const keyGenerator = cryptoFramework.createSymKeyGenerator('AES128');
      const key = await keyGenerator.convertKey(keyBlob);
      await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, gcmParams);
      const plainBlob: cryptoFramework.DataBlob = { data: this.stringToUint8Array(plainText) };
      const encrypted = await cipher.doFinal(plainBlob);
      const output: Uint8Array = this.concatUint8Arrays(ivBytes, encrypted.data);
      return new NGFEncryptResult(true, this.uint8ArrayToBase64(output));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `AES-GCM 加密失败: ${message}`);
      return new NGFEncryptResult(false, '');
    }
  }

  /**
   * AES-GCM 解密
   * @param cipherBase64 Base64 编码的 (IV + 密文 + authTag)
   * @param keyBase64 Base64 编码的 AES 密钥
   * @param ivBase64 未使用（IV 已包含在 cipherBase64 中），保留参数兼容
   * @returns 解密后的明文
   */
  async aesDecrypt(cipherBase64: string, keyBase64: string, ivBase64: string): Promise<NGFEncryptResult> {
    try {
      const combined: Uint8Array = this.base64ToUint8Array(cipherBase64);
      if (combined.length < 28) {
        return new NGFEncryptResult(false, '');
      }
      const ivBytes: Uint8Array = combined.slice(0, 12);
      const authTag: Uint8Array = combined.slice(combined.length - 16);
      const cipherBytes: Uint8Array = combined.slice(12, combined.length - 16);
      const keyBlob: cryptoFramework.DataBlob = { data: this.base64ToUint8Array(keyBase64) };
      const ivBlob: cryptoFramework.DataBlob = { data: ivBytes };
      const emptyAad: cryptoFramework.DataBlob = { data: new Uint8Array(0) };
      const authTagBlob: cryptoFramework.DataBlob = { data: authTag };
      const gcmParams: cryptoFramework.GcmParamsSpec = {
        algName: 'AES128|GCM|PKCS7',
        iv: ivBlob,
        aad: emptyAad,
        authTag: authTagBlob
      };
      const decipher = cryptoFramework.createCipher('AES128|GCM|PKCS7');
      const keyGenerator = cryptoFramework.createSymKeyGenerator('AES128');
      const key = await keyGenerator.convertKey(keyBlob);
      await decipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, key, gcmParams);
      const dataBlob: cryptoFramework.DataBlob = { data: cipherBytes };
      const decrypted = await decipher.doFinal(dataBlob);
      return new NGFEncryptResult(true, this.uint8ArrayToString(decrypted.data));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `AES-GCM 解密失败: ${message}`);
      return new NGFEncryptResult(false, '');
    }
  }
  /**
   * 生成随机字节并返回 Base64
   */
  generateRandomBase64(byteLength: number): string {
    try {
      const rand = cryptoFramework.createRandom();
      const blob = rand.generateRandomSync(byteLength);
      return this.uint8ArrayToBase64(blob.data);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `生成随机数失败: ${message}`);
      return '';
    }
  }

  private generateRandomBytes(length: number): Uint8Array {
    const rand = cryptoFramework.createRandom();
    const blob = rand.generateRandomSync(length);
    return blob.data;
  }

  private concatUint8Arrays(a: Uint8Array, b: Uint8Array): Uint8Array {
    const result = new Uint8Array(a.length + b.length);
    for (let i = 0; i < a.length; i++) {
      result[i] = a[i];
    }
    for (let i = 0; i < b.length; i++) {
      result[a.length + i] = b[i];
    }
    return result;
  }

  private mapHashAlgorithm(algorithm: NGFHashAlgorithm): string {
    if (algorithm === NGFHashAlgorithm.SHA256) {
      return 'SHA256';
    }
    if (algorithm === NGFHashAlgorithm.SHA384) {
      return 'SHA384';
    }
    if (algorithm === NGFHashAlgorithm.SHA512) {
      return 'SHA512';
    }
    return 'SHA256';
  }

  private stringToUint8Array(str: string): Uint8Array {
    const encoder = new util.TextEncoder();
    return encoder.encodeInto(str);
  }

  private uint8ArrayToString(arr: Uint8Array): string {
    const decoder = new util.TextDecoder('utf-8');
    return decoder.decodeToString(arr);
  }

  private uint8ArrayToBase64(arr: Uint8Array): string {
    return this.base64Helper.encodeToStringSync(arr);
  }

  private base64ToUint8Array(base64: string): Uint8Array {
    return this.base64Helper.decodeSync(base64);
  }

  private arrayBufferToHex(arr: Uint8Array): string {
    let hex = '';
    for (let index = 0; index < arr.length; index++) {
      const byte = arr[index];
      const h = byte.toString(16);
      hex += h.length < 2 ? `0${h}` : h;
    }
    return hex;
  }
}

export const securityToolkit: SecurityToolkit = SecurityToolkit.getInstance();
