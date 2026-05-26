import { fileIo as fs } from '@kit.CoreFileKit';
import { logger } from '../utils/Logger';

const TAG: string = 'NGFSandboxManager';

/**
 * 沙盒管理器
 * @note API 23 适配：移除对 platformOhos/UIContextManager 的直接依赖
 * 改为通过 initialize 方法注入 filesDir，遵循分层原则
 */
export class SandboxManager {
  private static instance: SandboxManager | null = null;
  private filesDir: string = '';

  private constructor() {
    // 私有构造函数，确保单例模式
  }

  static getInstance(): SandboxManager {
    if (!SandboxManager.instance) {
      SandboxManager.instance = new SandboxManager();
    }
    return SandboxManager.instance;
  }

  /**
   * 初始化沙盒管理器
   * @param filesDir 文件目录路径
   * @note API 23 适配：通过依赖注入传入路径，替代直接依赖 UIContextManager
   */
  initialize(filesDir: string | undefined): void {
    this.filesDir = filesDir || '';
    logger.info(TAG, `沙盒管理器初始化完成: filesDir=${filesDir}`);
  }

  getDirectory(directoryName: string): string {
    const filesDir = this.resolveFilesDir();
    if (filesDir.length <= 0) {
      logger.warn(TAG, `获取目录失败：filesDir 不可用，directory=${directoryName}`);
      return '';
    }

    const normalizedName = this.normalizeDirectoryName(directoryName);
    const targetDirectory = normalizedName === 'files' ? filesDir : `${filesDir}/${normalizedName}`;
    this.ensureDirectory(targetDirectory);
    logger.debug(TAG, `获取目录成功：directory=${targetDirectory}`);
    return targetDirectory;
  }

  private resolveFilesDir(): string {
    return this.filesDir;
  }

  private normalizeDirectoryName(directoryName: string): string {
    const normalizedName = directoryName.trim();
    if (normalizedName.length <= 0) {
      return 'files';
    }
    return normalizedName.replace(/\\/g, '/');
  }

  private ensureDirectory(directoryPath: string): void {
    if (directoryPath.length <= 0) {
      return;
    }

    try {
      if (!fs.accessSync(directoryPath)) {
        fs.mkdirSync(directoryPath, true);
      }
    } catch {
      try {
        fs.mkdirSync(directoryPath, true);
      } catch {
        logger.warn(TAG, `确保目录失败：path=${directoryPath}`);
      }
    }
  }
}
