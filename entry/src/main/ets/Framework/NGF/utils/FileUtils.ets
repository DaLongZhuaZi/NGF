import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { logger } from './Logger';
import { uiContextManager } from '../platformOhos/UIContextManager';

const TAG: string = 'NGFFileUtils';

let sandboxBaseDir: string = '';

function getSandboxBaseDir(): string {
  if (sandboxBaseDir.length > 0) {
    return sandboxBaseDir;
  }
  const ctx = uiContextManager.getAbilityContext();
  if (ctx !== null && ctx.filesDir.length > 0) {
    sandboxBaseDir = ctx.filesDir;
    logger.info(TAG, `沙箱基础目录延迟初始化: ${sandboxBaseDir}`);
  }
  return sandboxBaseDir;
}

export class NGFFileEntry {
  readonly name: string;
  readonly isDirectory: boolean;
  readonly size: number;

  constructor(name: string, isDirectory: boolean, size: number) {
    this.name = name;
    this.isDirectory = isDirectory;
    this.size = size;
  }
}

export class FileUtils {
  /**
   * Set the sandbox base directory for resolving relative paths.
   * Must be called during app initialization with context.filesDir.
   */
  static setSandboxBaseDir(baseDir: string): void {
    sandboxBaseDir = baseDir;
    logger.info(TAG, `沙箱基础目录已设置: ${baseDir}`);
  }

  private static resolvePath(filePath: string): string {
    if (filePath.length > 0 && (filePath.startsWith('/') || filePath.startsWith('file://'))) {
      return filePath;
    }
    const baseDir: string = getSandboxBaseDir();
    if (baseDir.length <= 0) {
      logger.warn(TAG, `沙箱基础目录未设置，使用相对路径可能导致失败: ${filePath}`);
      return filePath;
    }
    if (filePath.length <= 0) {
      return baseDir;
    }
    return `${baseDir}/${filePath}`;
  }

  static readText(filePath: string): string {
    const resolved: string = FileUtils.resolvePath(filePath);
    try {
      const file: fs.File = fs.openSync(resolved, fs.OpenMode.READ_ONLY);
      const stat: fs.Stat = fs.statSync(resolved);
      const buffer: ArrayBuffer = new ArrayBuffer(stat.size);
      const readResult: number = fs.readSync(file.fd, buffer);
      fs.closeSync(file);
      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
      return decoder.decodeToString(new Uint8Array(buffer, 0, readResult));
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `readText 失败: path=${filePath}, error=${message}`);
      return '';
    }
  }

  static writeText(filePath: string, content: string): boolean {
    const resolved: string = FileUtils.resolvePath(filePath);
    let file: fs.File | null = null;
    try {
      file = fs.openSync(resolved, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, content);
      return true;
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `writeText 失败: path=${filePath}, error=${message}`);
      return false;
    } finally {
      if (file !== null) {
        try {
          fs.closeSync(file);
        } catch {
          // ignore
        }
      }
    }
  }

  static appendText(filePath: string, content: string): boolean {
    const resolved: string = FileUtils.resolvePath(filePath);
    let file: fs.File | null = null;
    try {
      file = fs.openSync(resolved, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.APPEND);
      fs.writeSync(file.fd, content);
      return true;
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `appendText 失败: path=${filePath}, error=${message}`);
      return false;
    } finally {
      if (file !== null) {
        try {
          fs.closeSync(file);
        } catch {
          // ignore
        }
      }
    }
  }

  static readBytes(filePath: string): ArrayBuffer {
    const resolved: string = FileUtils.resolvePath(filePath);
    try {
      const file: fs.File = fs.openSync(resolved, fs.OpenMode.READ_ONLY);
      const stat: fs.Stat = fs.statSync(resolved);
      const buffer: ArrayBuffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);
      return buffer;
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `readBytes 失败: path=${filePath}, error=${message}`);
      return new ArrayBuffer(0);
    }
  }

  static writeBytes(filePath: string, data: ArrayBuffer): boolean {
    const resolved: string = FileUtils.resolvePath(filePath);
    let file: fs.File | null = null;
    try {
      file = fs.openSync(resolved, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, data);
      return true;
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `writeBytes 失败: path=${filePath}, error=${message}`);
      return false;
    } finally {
      if (file !== null) {
        try {
          fs.closeSync(file);
        } catch {
          // ignore
        }
      }
    }
  }

  static exists(filePath: string): boolean {
    const resolved: string = FileUtils.resolvePath(filePath);
    try {
      fs.accessSync(resolved);
      return true;
    } catch {
      return false;
    }
  }

  static isDirectory(filePath: string): boolean {
    const resolved: string = FileUtils.resolvePath(filePath);
    try {
      const stat: fs.Stat = fs.statSync(resolved);
      return stat.isDirectory();
    } catch {
      return false;
    }
  }

  static getFileSize(filePath: string): number {
    const resolved: string = FileUtils.resolvePath(filePath);
    try {
      const stat: fs.Stat = fs.statSync(resolved);
      return stat.size;
    } catch {
      return 0;
    }
  }

  static createDirectory(dirPath: string, recursive: boolean = true): boolean {
    const resolved: string = FileUtils.resolvePath(dirPath);
    try {
      fs.mkdirSync(resolved, recursive);
      return true;
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `createDirectory 失败: path=${dirPath}, error=${message}`);
      return false;
    }
  }

  static listDirectory(dirPath: string): Array<NGFFileEntry> {
    const resolved: string = FileUtils.resolvePath(dirPath);
    try {
      const entries: Array<NGFFileEntry> = [];
      const dir: Array<string> = fs.listFileSync(resolved);
      for (let index = 0; index < dir.length; index++) {
        const name: string = dir[index];
        const fullPath: string = resolved + '/' + name;
        try {
          const stat: fs.Stat = fs.statSync(fullPath);
          entries.push(new NGFFileEntry(name, stat.isDirectory(), stat.size));
        } catch {
          entries.push(new NGFFileEntry(name, false, 0));
        }
      }
      return entries;
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `listDirectory 失败: path=${dirPath}, error=${message}`);
      return [];
    }
  }

  static deleteFile(filePath: string): boolean {
    const resolved: string = FileUtils.resolvePath(filePath);
    try {
      fs.unlinkSync(resolved);
      return true;
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `deleteFile 失败: path=${filePath}, error=${message}`);
      return false;
    }
  }

  static deleteDirectory(dirPath: string): boolean {
    const resolved: string = FileUtils.resolvePath(dirPath);
    try {
      fs.rmdirSync(resolved);
      return true;
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `deleteDirectory 失败: path=${dirPath}, error=${message}`);
      return false;
    }
  }

  static copyFile(srcPath: string, destPath: string): boolean {
    const resolvedSrc: string = FileUtils.resolvePath(srcPath);
    const resolvedDest: string = FileUtils.resolvePath(destPath);
    try {
      fs.copyFileSync(resolvedSrc, resolvedDest);
      return true;
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `copyFile 失败: src=${srcPath}, dest=${destPath}, error=${message}`);
      return false;
    }
  }

  static moveFile(srcPath: string, destPath: string): boolean {
    const resolvedSrc: string = FileUtils.resolvePath(srcPath);
    const resolvedDest: string = FileUtils.resolvePath(destPath);
    try {
      fs.moveFileSync(resolvedSrc, resolvedDest);
      return true;
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `moveFile 失败: src=${srcPath}, dest=${destPath}, error=${message}`);
      return false;
    }
  }
}
