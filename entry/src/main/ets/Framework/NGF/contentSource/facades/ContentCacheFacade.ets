import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { logger } from '../../utils/Logger';
import { IContentCache } from '../contracts/IContentCache';

const TAG: string = 'NGFContentCacheFacade';

class NGFContentCacheEntry {
  readonly value: string;
  readonly expiresAt: number;

  constructor(value: string, expiresAt: number) {
    this.value = value;
    this.expiresAt = expiresAt;
  }
}

export class ContentCacheFacade implements IContentCache {
  private static readonly MAX_MEMORY_ENTRIES: number = 100;
  private static readonly CACHE_DIR_NAME: string = 'content-cache';
  private readonly memoryCache: Map<string, NGFContentCacheEntry> = new Map<string, NGFContentCacheEntry>();
  private filesDir: string = '';

  initialize(filesDir: string): void {
    this.filesDir = filesDir;
    const cacheDir = this.getCacheDir();
    this.ensureDir(cacheDir);
    logger.info(TAG, `内容缓存初始化: dir=${cacheDir}`);
  }

  put(key: string, value: string, ttlMs: number): void {
    const normalizedKey = this.normalizeKey(key);
    if (normalizedKey.length <= 0) {
      logger.warn(TAG, 'put 忽略: key 为空');
      return;
    }
    const now = Date.now();
    const expiresAt = ttlMs > 0 ? now + ttlMs : 0;
    this.putMemory(normalizedKey, value, expiresAt);
    this.putDisk(normalizedKey, value, expiresAt);
  }

  get(key: string): string {
    const normalizedKey = this.normalizeKey(key);
    if (normalizedKey.length <= 0) {
      return '';
    }
    const memoryValue = this.getMemory(normalizedKey);
    if (memoryValue !== null) {
      return memoryValue;
    }
    const diskEntry = this.getDisk(normalizedKey);
    if (diskEntry !== null) {
      this.putMemory(normalizedKey, diskEntry.value, diskEntry.expiresAt);
      return diskEntry.value;
    }
    return '';
  }

  has(key: string): boolean {
    const normalizedKey = this.normalizeKey(key);
    if (normalizedKey.length <= 0) {
      return false;
    }
    if (this.hasMemory(normalizedKey)) {
      return true;
    }
    return this.hasDisk(normalizedKey);
  }

  remove(key: string): void {
    const normalizedKey = this.normalizeKey(key);
    if (normalizedKey.length <= 0) {
      return;
    }
    this.memoryCache.delete(normalizedKey);
    this.removeDisk(normalizedKey);
    logger.debug(TAG, `移除缓存: key=${normalizedKey}`);
  }

  clear(): void {
    this.memoryCache.clear();
    this.clearDisk();
    logger.info(TAG, '清除所有内容缓存');
  }

  memorySize(): number {
    return this.memoryCache.size;
  }

  private putMemory(key: string, value: string, expiresAt: number): void {
    if (this.memoryCache.size >= ContentCacheFacade.MAX_MEMORY_ENTRIES && !this.memoryCache.has(key)) {
      this.evictOldestMemory();
    }
    this.memoryCache.set(key, new NGFContentCacheEntry(value, expiresAt));
  }

  private getMemory(key: string): string | null {
    const entry = this.memoryCache.get(key);
    if (entry === undefined) {
      return null;
    }
    if (entry.expiresAt > 0 && Date.now() > entry.expiresAt) {
      this.memoryCache.delete(key);
      return null;
    }
    return entry.value;
  }

  private hasMemory(key: string): boolean {
    const entry = this.memoryCache.get(key);
    if (entry === undefined) {
      return false;
    }
    if (entry.expiresAt > 0 && Date.now() > entry.expiresAt) {
      this.memoryCache.delete(key);
      return false;
    }
    return true;
  }

  private evictOldestMemory(): void {
    const keys = this.memoryCache.keys();
    for (const key of keys) {
      this.memoryCache.delete(key);
      return;
    }
  }

  private putDisk(key: string, value: string, expiresAt: number): void {
    const filePath = this.buildDiskPath(key);
    try {
      const content = `${expiresAt}\n${value}`;
      const encoder = new util.TextEncoder();
      const buffer = encoder.encodeInto(content);
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      fs.writeSync(file.fd, buffer);
      fs.closeSync(file);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `磁盘写入失败: key=${key}, error=${message}`);
    }
  }

  private getDisk(key: string): NGFContentCacheEntry | null {
    const filePath = this.buildDiskPath(key);
    if (!this.existsPath(filePath)) {
      return null;
    }
    try {
      const content = this.readTextSync(filePath);
      const newlineIndex = content.indexOf('\n');
      if (newlineIndex < 0) {
        return null;
      }
      const expiresAtStr = content.substring(0, newlineIndex);
      const value = content.substring(newlineIndex + 1);
      const expiresAt = Number(expiresAtStr);
      if (expiresAt > 0 && Date.now() > expiresAt) {
        this.removeDisk(key);
        return null;
      }
      return new NGFContentCacheEntry(value, expiresAt);
    } catch {
      return null;
    }
  }

  private hasDisk(key: string): boolean {
    const filePath = this.buildDiskPath(key);
    if (!this.existsPath(filePath)) {
      return false;
    }
    try {
      const content = this.readTextSync(filePath);
      const newlineIndex = content.indexOf('\n');
      if (newlineIndex < 0) {
        return false;
      }
      const expiresAtStr = content.substring(0, newlineIndex);
      const expiresAt = Number(expiresAtStr);
      if (expiresAt > 0 && Date.now() > expiresAt) {
        this.removeDisk(key);
        return false;
      }
      return true;
    } catch {
      return false;
    }
  }

  private removeDisk(key: string): void {
    const filePath = this.buildDiskPath(key);
    try {
      if (this.existsPath(filePath)) {
        fs.unlinkSync(filePath);
      }
    } catch {
      // ignore
    }
  }

  private clearDisk(): void {
    const cacheDir = this.getCacheDir();
    if (!this.existsPath(cacheDir)) {
      return;
    }
    try {
      fs.rmdirSync(cacheDir);
    } catch {
      // ignore
    }
    this.ensureDir(cacheDir);
  }

  private readTextSync(path: string): string {
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

  private buildDiskPath(key: string): string {
    const safeKey = key.replace(/[^a-zA-Z0-9._-]/g, '_');
    return `${this.getCacheDir()}/${safeKey}.cache`;
  }

  private getCacheDir(): string {
    if (this.filesDir.length <= 0) {
      return '';
    }
    return `${this.filesDir}/${ContentCacheFacade.CACHE_DIR_NAME}`;
  }

  private ensureDir(path: string): void {
    if (path.length <= 0) {
      return;
    }
    try {
      fs.mkdirSync(path, true);
    } catch {
      // directory may already exist
    }
  }

  private existsPath(path: string): boolean {
    try {
      return fs.accessSync(path);
    } catch {
      return false;
    }
  }

  private normalizeKey(key: string): string {
    return key.trim();
  }
}

export const ngfContentCacheFacade: ContentCacheFacade = new ContentCacheFacade();
