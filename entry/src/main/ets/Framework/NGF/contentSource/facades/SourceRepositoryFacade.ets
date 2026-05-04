import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { getContext, isInitialized as isGlobalContextInitialized } from '../../../../GlobalContext';
import { logger } from '../../utils/Logger';
import { uiContextManager } from '../../platformOhos/UIContextManager';
import { ISourceRepository } from '../contracts/ISourceRepository';

const TAG = 'NGFSourceRepositoryFacade';

class NGFSourceRepositoryEntry {
  pkg: string;

  constructor(pkg: string) {
    this.pkg = pkg;
  }
}

class NGFSourceRepositoryIndex {
  version: string;
  lastUpdate: number;
  sources: Array<NGFSourceRepositoryEntry>;

  constructor(version: string, lastUpdate: number, sources: Array<NGFSourceRepositoryEntry>) {
    this.version = version;
    this.lastUpdate = lastUpdate;
    this.sources = sources;
  }
}

export class SourceRepositoryFacade implements ISourceRepository {
  private readonly repositoryDirName: string = 'extensions-source';
  private readonly indexFileName: string = 'index.main.json';

  readIndexJson(): string {
    const indexPath = this.getIndexFilePath();
    if (indexPath.length <= 0 || !this.exists(indexPath)) {
      logger.debug(TAG, '读取仓库索引回退默认值');
      return this.createDefaultIndexJson();
    }

    try {
      const indexJson = this.readText(indexPath);
      logger.info(TAG, `读取仓库索引成功: ${indexPath}`);
      return indexJson;
    } catch {
      logger.warn(TAG, `读取仓库索引失败: ${indexPath}`);
      return this.createDefaultIndexJson();
    }
  }

  updateIndexJson(content: string): boolean {
    const indexPath = this.getIndexFilePath();
    if (indexPath.length <= 0) {
      logger.warn(TAG, '更新仓库索引失败: indexPath为空');
      return false;
    }

    const normalized = content.trim();
    if (normalized.length <= 0) {
      logger.warn(TAG, '更新仓库索引失败: content为空');
      return false;
    }

    try {
      this.parseIndexJson(normalized);
      this.ensureRepositoryDir();
      const result = this.writeText(indexPath, normalized);
      logger.info(TAG, `更新仓库索引: path=${indexPath}, 成功=${result}`);
      return result;
    } catch {
      logger.warn(TAG, '更新仓库索引失败: JSON格式不合法');
      return false;
    }
  }

  listPackages(): string[] {
    const indexJson = this.readIndexJson();
    try {
      const indexObject = this.parseIndexJson(indexJson);
      const packages: string[] = [];
      for (let i = 0; i < indexObject.sources.length; i++) {
        const pkg = indexObject.sources[i].pkg.trim();
        if (pkg.length > 0) {
          packages.push(pkg);
        }
      }
      logger.debug(TAG, `列出仓库包成功: 数量=${packages.length}`);
      return packages;
    } catch {
      logger.warn(TAG, '列出仓库包失败');
      return [];
    }
  }

  private parseIndexJson(indexJson: string): NGFSourceRepositoryIndex {
    const parsed = JSON.parse(indexJson) as Partial<NGFSourceRepositoryIndex>;
    const version = parsed.version && typeof parsed.version === 'string' ? parsed.version : '1.0.0';
    const lastUpdate = parsed.lastUpdate && typeof parsed.lastUpdate === 'number'
      ? parsed.lastUpdate
      : Date.now();
    const sourceEntries: Array<NGFSourceRepositoryEntry> = [];

    if (parsed.sources && Array.isArray(parsed.sources)) {
      for (let i = 0; i < parsed.sources.length; i++) {
        const item = parsed.sources[i] as Partial<NGFSourceRepositoryEntry>;
        const pkg = item.pkg && typeof item.pkg === 'string' ? item.pkg : '';
        if (pkg.length > 0) {
          sourceEntries.push(new NGFSourceRepositoryEntry(pkg));
        }
      }
    }

    return new NGFSourceRepositoryIndex(version, lastUpdate, sourceEntries);
  }

  private createDefaultIndexJson(): string {
    const defaultIndex = new NGFSourceRepositoryIndex('1.0.0', Date.now(), []);
    return JSON.stringify(defaultIndex);
  }

  private getIndexFilePath(): string {
    const repositoryDir = this.getRepositoryDir();
    if (repositoryDir.length <= 0) {
      return '';
    }
    return `${repositoryDir}/${this.indexFileName}`;
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

  private ensureRepositoryDir(): void {
    const repositoryDir = this.getRepositoryDir();
    if (repositoryDir.length <= 0 || this.exists(repositoryDir)) {
      return;
    }

    try {
      fs.mkdirSync(repositoryDir, true);
    } catch {
      logger.warn(TAG, `创建仓库目录失败: ${repositoryDir}`);
    }
  }

  private exists(path: string): boolean {
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
      logger.warn(TAG, `读取仓库文本失败: path=${path}, error=${this.errorToString(error as Object | string | number | boolean)}`);
      return '';
    } finally {
      this.closeFileQuietly(file, path);
    }
  }

  private writeText(path: string, content: string): boolean {
    let file: fs.File | null = null;
    try {
      file = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, content);
      return true;
    } catch (error) {
      logger.warn(TAG, `写入仓库文本失败: path=${path}, error=${this.errorToString(error as Object | string | number | boolean)}`);
      return false;
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
      logger.warn(TAG, `关闭仓库文件失败: path=${path}, error=${this.errorToString(error as Object | string | number | boolean)}`);
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

export const ngfSourceRepositoryFacade = new SourceRepositoryFacade();
