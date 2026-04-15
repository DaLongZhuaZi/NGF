import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { getContext, isInitialized as isGlobalContextInitialized } from '../../../../GlobalContext';
import { logger } from '../../../../Utils/Logger';
import { uiContextManager } from '../../../Managers/UIContextManager';
import { SandboxManager } from '../../../Storage/SandboxManager';
import { IStorageProvider } from '../contracts/IStorageProvider';

const TAG = 'NGFStorageProviderFacade';

export class StorageProviderFacade implements IStorageProvider {
  private readonly sandboxManager: SandboxManager = SandboxManager.getInstance();

  getCacheDir(): string {
    try {
      const cacheDir = this.sandboxManager.getDirectory('cache');
      logger.debug(TAG, `获取缓存目录: ${cacheDir}`);
      return cacheDir;
    } catch {
      const filesDir = this.getFilesDir();
      if (filesDir.length > 0) {
        const fallbackCacheDir = `${filesDir}/cache`;
        logger.debug(TAG, `获取缓存目录回退: ${fallbackCacheDir}`);
        return fallbackCacheDir;
      }
      logger.warn(TAG, '获取缓存目录失败');
      return '';
    }
  }

  getFilesDir(): string {
    try {
      const filesDir = this.sandboxManager.getDirectory('files');
      logger.debug(TAG, `获取文件目录: ${filesDir}`);
      return filesDir;
    } catch {
      const fallbackFilesDir = this.resolveFilesDirFromContext();
      logger.debug(TAG, `获取文件目录回退: ${fallbackFilesDir}`);
      return fallbackFilesDir;
    }
  }

  readText(path: string): string {
    if (path.trim().length <= 0) {
      logger.warn(TAG, '读取文本失败: path为空');
      return '';
    }

    try {
      if (!this.exists(path)) {
        return '';
      }

      const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(path);
      if (stat.size <= 0) {
        fs.closeSync(file);
        return '';
      }

      const buffer = new ArrayBuffer(Number(stat.size));
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);

      const decoder = new util.TextDecoder('utf-8');
      const content = decoder.decodeToString(new Uint8Array(buffer));
      logger.debug(TAG, `读取文本成功: ${path}`);
      return content;
    } catch {
      logger.warn(TAG, `璇诲彇鏂囨湰澶辫触: ${path}`);
      return '';
    }
  }

  writeText(path: string, content: string): boolean {
    if (path.trim().length <= 0) {
      logger.warn(TAG, '写入文本失败: path为空');
      return false;
    }

    try {
      this.ensureParentDirectory(path);
      const file = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, content);
      fs.closeSync(file);
      logger.info(TAG, `写入文本成功: ${path}`);
      return true;
    } catch {
      logger.warn(TAG, `鍐欏叆鏂囨湰澶辫触: ${path}`);
      return false;
    }
  }

  exists(path: string): boolean {
    if (path.trim().length <= 0) {
      logger.debug(TAG, 'exists=false: path为空');
      return false;
    }

    try {
      const exists = fs.accessSync(path);
      logger.debug(TAG, `exists=${exists}: ${path}`);
      return exists;
    } catch {
      logger.debug(TAG, `exists=false: ${path}`);
      return false;
    }
  }

  private resolveFilesDirFromContext(): string {
    const abilityContext = uiContextManager.getAbilityContext();
    if (abilityContext) {
      return abilityContext.filesDir;
    }

    if (isGlobalContextInitialized()) {
      try {
        const globalContext = getContext();
        return globalContext.filesDir;
      } catch {
        return '';
      }
    }

    return '';
  }

  private ensureParentDirectory(path: string): void {
    const normalizedPath = path.replace(/\\/g, '/');
    const lastSlash = normalizedPath.lastIndexOf('/');
    if (lastSlash <= 0) {
      return;
    }

    const parentDir = normalizedPath.substring(0, lastSlash);
    if (parentDir.length <= 0 || this.exists(parentDir)) {
      return;
    }

    try {
      fs.mkdirSync(parentDir, true);
    } catch {
      logger.warn(TAG, `鍒涘缓鐖剁洰褰曞け璐? ${parentDir}`);
    }
  }
}

export const ngfStorageProviderFacade = new StorageProviderFacade();
