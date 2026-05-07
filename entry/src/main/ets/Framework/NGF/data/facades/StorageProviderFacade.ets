import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { logger } from '../../utils/Logger';
import { errorToString } from '../../utils/ErrorUtils';
import { SandboxManager } from '../SandboxManager';
import { IStorageProvider } from '../contracts/IStorageProvider';

const TAG: string = 'NGFStorageProviderFacade';

/**
 * 存储提供者门面
 * @note API 23 适配：
 * 1. 使用 ErrorUtils.errorToString 替代私有方法，消除代码重复
 * 2. 移除对 GlobalContext 和 UIContextManager 的直接依赖
 * 3. 通过 initialize 方法注入 filesDir，遵循分层原则
 */
export class StorageProviderFacade implements IStorageProvider {
  private readonly sandboxManager: SandboxManager = SandboxManager.getInstance();
  private filesDir: string = '';

  /**
   * 初始化存储提供者
   * @param filesDir 文件目录路径
   * @note API 23 适配：通过依赖注入传入路径，替代直接依赖 UIContextManager
   */
  initialize(filesDir: string): void {
    this.filesDir = filesDir;
    this.sandboxManager.initialize(filesDir);
    logger.info(TAG, `存储提供者初始化完成: filesDir=${filesDir}`);
  }

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
      const fallbackFilesDir = this.filesDir;
      logger.debug(TAG, `获取文件目录回退: ${fallbackFilesDir}`);
      return fallbackFilesDir;
    }
  }

  readText(path: string): string {
    if (path.trim().length <= 0) {
      logger.warn(TAG, '读取文本失败: path为空');
      return '';
    }

    let file: fs.File | null = null;
    try {
      if (!this.exists(path)) {
        return '';
      }

      file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(path);
      if (stat.size <= 0) {
        return '';
      }

      const buffer = new ArrayBuffer(Number(stat.size));
      fs.readSync(file.fd, buffer);

      const decoder = new util.TextDecoder('utf-8');
      const content = decoder.decodeToString(new Uint8Array(buffer));
      logger.debug(TAG, `读取文本成功: ${path}`);
      return content;
    } catch (error) {
      logger.warn(TAG, `读取文本失败: path=${path}, error=${errorToString(error)}`);
      return '';
    } finally {
      this.closeFileQuietly(file, path);
    }
  }

  writeText(path: string, content: string): boolean {
    if (path.trim().length <= 0) {
      logger.warn(TAG, '写入文本失败: path为空');
      return false;
    }

    let file: fs.File | null = null;
    try {
      this.ensureParentDirectory(path);
      file = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, content);
      logger.info(TAG, `写入文本成功: ${path}`);
      return true;
    } catch (error) {
      logger.warn(TAG, `写入文本失败: path=${path}, error=${errorToString(error)}`);
      return false;
    } finally {
      this.closeFileQuietly(file, path);
    }
  }

  exists(path: string): boolean {
    if (path.trim().length <= 0) {
      logger.debug(TAG, '文件存在=false: path为空');
      return false;
    }

    try {
      const exists = fs.accessSync(path);
      logger.debug(TAG, `文件存在=${exists}: ${path}`);
      return exists;
    } catch {
      logger.debug(TAG, `文件存在=false: ${path}`);
      return false;
    }
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
      logger.warn(TAG, `创建父目录失败: ${parentDir}`);
    }
  }

  private closeFileQuietly(file: fs.File | null, path: string): void {
    if (file === null) {
      return;
    }

    try {
      fs.closeSync(file);
    } catch (error) {
      logger.warn(TAG, `关闭文件失败: path=${path}, error=${errorToString(error)}`);
    }
  }
}

export const ngfStorageProviderFacade = new StorageProviderFacade();
