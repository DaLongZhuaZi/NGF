import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { logger } from './Logger';

const TAG: string = 'NGFFileUtils';

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
  static readText(filePath: string): string {
    try {
      const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(filePath);
      const buffer = new ArrayBuffer(stat.size);
      const readResult = fs.readSync(file.fd, buffer);
      fs.closeSync(file);
      const decoder = new util.TextDecoder('utf-8');
      return decoder.decode(new Uint8Array(buffer, 0, readResult));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `readText 失败: path=${filePath}, error=${message}`);
      return '';
    }
  }

  static writeText(filePath: string, content: string): boolean {
    try {
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      const encoder = new util.TextEncoder('utf-8');
      const buffer = encoder.encodeInto(content);
      fs.writeSync(file.fd, buffer);
      fs.closeSync(file);
      return true;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `writeText 失败: path=${filePath}, error=${message}`);
      return false;
    }
  }

  static appendText(filePath: string, content: string): boolean {
    try {
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.APPEND);
      const encoder = new util.TextEncoder('utf-8');
      const buffer = encoder.encodeInto(content);
      fs.writeSync(file.fd, buffer);
      fs.closeSync(file);
      return true;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `appendText 失败: path=${filePath}, error=${message}`);
      return false;
    }
  }

  static readBytes(filePath: string): ArrayBuffer {
    try {
      const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(filePath);
      const buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);
      return buffer;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `readBytes 失败: path=${filePath}, error=${message}`);
      return new ArrayBuffer(0);
    }
  }

  static writeBytes(filePath: string, data: ArrayBuffer): boolean {
    try {
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, data);
      fs.closeSync(file);
      return true;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `writeBytes 失败: path=${filePath}, error=${message}`);
      return false;
    }
  }

  static exists(filePath: string): boolean {
    try {
      fs.accessSync(filePath);
      return true;
    } catch {
      return false;
    }
  }

  static isDirectory(filePath: string): boolean {
    try {
      const stat = fs.statSync(filePath);
      return stat.isDirectory();
    } catch {
      return false;
    }
  }

  static getFileSize(filePath: string): number {
    try {
      const stat = fs.statSync(filePath);
      return stat.size;
    } catch {
      return 0;
    }
  }

  static createDirectory(dirPath: string, recursive: boolean = true): boolean {
    try {
      fs.mkdirSync(dirPath, recursive);
      return true;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `createDirectory 失败: path=${dirPath}, error=${message}`);
      return false;
    }
  }

  static listDirectory(dirPath: string): Array<NGFFileEntry> {
    try {
      const entries: Array<NGFFileEntry> = [];
      const dir = fs.listFileSync(dirPath);
      for (let index = 0; index < dir.length; index++) {
        const name = dir[index];
        const fullPath = dirPath + '/' + name;
        try {
          const stat = fs.statSync(fullPath);
          entries.push(new NGFFileEntry(name, stat.isDirectory(), stat.size));
        } catch {
          entries.push(new NGFFileEntry(name, false, 0));
        }
      }
      return entries;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `listDirectory 失败: path=${dirPath}, error=${message}`);
      return [];
    }
  }

  static deleteFile(filePath: string): boolean {
    try {
      fs.unlinkSync(filePath);
      return true;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `deleteFile 失败: path=${filePath}, error=${message}`);
      return false;
    }
  }

  static deleteDirectory(dirPath: string): boolean {
    try {
      fs.rmdirSync(dirPath);
      return true;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `deleteDirectory 失败: path=${dirPath}, error=${message}`);
      return false;
    }
  }

  static copyFile(srcPath: string, destPath: string): boolean {
    try {
      fs.copyFileSync(srcPath, destPath);
      return true;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `copyFile 失败: src=${srcPath}, dest=${destPath}, error=${message}`);
      return false;
    }
  }

  static moveFile(srcPath: string, destPath: string): boolean {
    try {
      fs.moveFileSync(srcPath, destPath);
      return true;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `moveFile 失败: src=${srcPath}, dest=${destPath}, error=${message}`);
      return false;
    }
  }
}
