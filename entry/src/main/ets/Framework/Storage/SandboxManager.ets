import { fileIo as fs } from '@kit.CoreFileKit';
import { getContext, isInitialized as isGlobalContextInitialized } from '../../GlobalContext';
import { uiContextManager } from '../Managers/UIContextManager';
import { logger } from '../NGF/utils/Logger';

const TAG: string = 'NGFSandboxManager';

export class SandboxManager {
  private static instance: SandboxManager | null = null;

  static getInstance(): SandboxManager {
    if (!SandboxManager.instance) {
      SandboxManager.instance = new SandboxManager();
    }
    return SandboxManager.instance;
  }

  getDirectory(directoryName: string): string {
    const filesDir = this.resolveFilesDir();
    if (filesDir.length <= 0) {
      logger.warn(TAG, `getDirectory failed: filesDir unavailable, directory=${directoryName}`);
      return '';
    }

    const normalizedName = this.normalizeDirectoryName(directoryName);
    const targetDirectory = normalizedName === 'files' ? filesDir : `${filesDir}/${normalizedName}`;
    this.ensureDirectory(targetDirectory);
    logger.debug(TAG, `getDirectory success: directory=${targetDirectory}`);
    return targetDirectory;
  }

  private resolveFilesDir(): string {
    const abilityContext = uiContextManager.getAbilityContext();
    if (abilityContext) {
      return abilityContext.filesDir;
    }

    if (isGlobalContextInitialized()) {
      try {
        return getContext().filesDir;
      } catch {
        return '';
      }
    }

    return '';
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
        logger.warn(TAG, `ensureDirectory failed: path=${directoryPath}`);
      }
    }
  }
}
