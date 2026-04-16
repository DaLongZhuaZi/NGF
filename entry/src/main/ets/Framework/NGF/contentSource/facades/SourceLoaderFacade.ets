import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { getContext, isInitialized as isGlobalContextInitialized } from '../../../../GlobalContext';
import { logger } from '../../../../Utils/Logger';
import { uiContextManager } from '../../../Managers/UIContextManager';
import { ISourceLoader } from '../contracts/ISourceLoader';

const TAG = 'NGFSourceLoaderFacade';

class NGFSourceLoaderIconCandidate {
  path: string;

  constructor(path: string) {
    this.path = path;
  }
}

export class SourceLoaderFacade implements ISourceLoader {
  private readonly repositoryDirName: string = 'extensions-source';
  private readonly sourceFileName: string = 'source.json';

  exists(pkg: string): boolean {
    const normalizedPkg = this.normalizePkg(pkg);
    if (normalizedPkg.length <= 0) {
      logger.warn(TAG, 'exists ignored: pkg为空');
      return false;
    }

    const sourceJsonCandidates = this.buildSourceJsonCandidates(normalizedPkg);
    for (let index = 0; index < sourceJsonCandidates.length; index++) {
      if (this.existsPath(sourceJsonCandidates[index])) {
        logger.debug(TAG, `图源存在: pkg=${normalizedPkg}`);
        return true;
      }
    }

    logger.debug(TAG, `图源不存在: pkg=${normalizedPkg}`);
    return false;
  }

  loadSourceJson(pkg: string): string {
    const normalizedPkg = this.normalizePkg(pkg);
    if (normalizedPkg.length <= 0) {
      logger.warn(TAG, 'loadSourceJson ignored: pkg为空');
      return '';
    }

    const sourceJsonCandidates = this.buildSourceJsonCandidates(normalizedPkg);
    for (let index = 0; index < sourceJsonCandidates.length; index++) {
      const candidatePath = sourceJsonCandidates[index];
      if (!this.existsPath(candidatePath)) {
        continue;
      }

      try {
        const content = this.readText(candidatePath).trim();
        if (content.length > 0) {
          logger.info(TAG, `读取图源配置成功: pkg=${normalizedPkg}, path=${candidatePath}`);
          return content;
        }
      } catch {
        logger.warn(TAG, `璇诲彇鍥炬簮閰嶇疆澶辫触: ${candidatePath}`);
      }
    }

    logger.debug(TAG, `未找到图源配置: pkg=${normalizedPkg}`);
    return '';
  }

  loadIconPath(pkg: string): string {
    const normalizedPkg = this.normalizePkg(pkg);
    if (normalizedPkg.length <= 0) {
      logger.warn(TAG, 'loadIconPath ignored: pkg为空');
      return '';
    }

    const iconCandidates = this.buildIconCandidates(normalizedPkg);
    for (let index = 0; index < iconCandidates.length; index++) {
      const candidate = iconCandidates[index];
      if (this.existsPath(candidate.path)) {
        logger.info(TAG, `读取图源图标成功: pkg=${normalizedPkg}, path=${candidate.path}`);
        return candidate.path;
      }
    }

    logger.debug(TAG, `未找到图源图标: pkg=${normalizedPkg}`);
    return '';
  }

  private normalizePkg(pkg: string): string {
    return pkg.trim();
  }

  private buildSourceJsonCandidates(pkg: string): string[] {
    const repositoryDir = this.getRepositoryDir();
    if (repositoryDir.length <= 0) {
      return [];
    }

    const candidates: string[] = [];
    candidates.push(`${repositoryDir}/${pkg}/${this.sourceFileName}`);
    candidates.push(`${repositoryDir}/${pkg}.json`);
    return candidates;
  }

  private buildIconCandidates(pkg: string): Array<NGFSourceLoaderIconCandidate> {
    const repositoryDir = this.getRepositoryDir();
    if (repositoryDir.length <= 0) {
      return [];
    }

    const iconCandidates: Array<NGFSourceLoaderIconCandidate> = [];
    const iconFormats: string[] = ['webp', 'png', 'jpg'];

    for (let index = 0; index < iconFormats.length; index++) {
      const ext = iconFormats[index];
      iconCandidates.push(new NGFSourceLoaderIconCandidate(`${repositoryDir}/icons/${pkg}.${ext}`));
    }
    for (let index = 0; index < iconFormats.length; index++) {
      const ext = iconFormats[index];
      iconCandidates.push(new NGFSourceLoaderIconCandidate(`${repositoryDir}/${pkg}/icon.${ext}`));
    }

    return iconCandidates;
  }

  private getRepositoryDir(): string {
    const filesDir = this.resolveFilesDir();
    if (filesDir.length <= 0) {
      return '';
    }
    return `${filesDir}/${this.repositoryDirName}`;
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

  private existsPath(path: string): boolean {
    try {
      return fs.accessSync(path);
    } catch {
      return false;
    }
  }

  private readText(path: string): string {
    let file: fs.File | null = null;
    try {
      file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(path);
      if (stat.size <= 0) {
        return '';
      }
      const buffer = new ArrayBuffer(Number(stat.size));
      fs.readSync(file.fd, buffer);
      const decoder = new util.TextDecoder('utf-8');
      return decoder.decodeToString(new Uint8Array(buffer));
    } catch (error) {
      logger.warn(TAG, `读取图源文本失败: path=${path}, error=${this.errorToString(error as Object | string | number | boolean)}`);
      return '';
    } finally {
      this.closeFileQuietly(file, path);
    }
  }

  private closeFileQuietly(file: fs.File | null, path: string): void {
    if (file === null) {
      return;
    }

    try {
      fs.closeSync(file);
    } catch (error) {
      logger.warn(TAG, `关闭图源文件失败: path=${path}, error=${this.errorToString(error as Object | string | number | boolean)}`);
    }
  }

  private errorToString(error: Object | string | number | boolean): string {
    if (typeof error === 'string') {
      return error;
    }
    if (typeof error === 'number' || typeof error === 'boolean') {
      return String(error);
    }
    if (error instanceof Error) {
      return error.message;
    }
    return String(error);
  }
}

export const ngfSourceLoaderFacade = new SourceLoaderFacade();
