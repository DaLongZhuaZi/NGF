import { logger } from '../../utils/Logger';
import { ICacheStore } from '../contracts/ICacheStore';

const TAG: string = 'NGFCacheStoreFacade';
const MAX_CAPACITY: number = 200;
const CLEANUP_INTERVAL_MS: number = 60000;

class NGFCacheEntry {
  value: string;
  expiresAt: number;

  constructor(value: string, expiresAt: number) {
    this.value = value;
    this.expiresAt = expiresAt;
  }

  isExpired(now: number): boolean {
    if (this.expiresAt <= 0) {
      return false;
    }
    return now >= this.expiresAt;
  }
}

export class CacheStoreFacade implements ICacheStore {
  private readonly cacheEntries: Map<string, NGFCacheEntry> = new Map<string, NGFCacheEntry>();
  private cleanupTimerId: number = -1;

  put(key: string, value: string, ttlMs: number): void {
    const now = Date.now();
    const expiresAt = ttlMs > 0 ? now + ttlMs : 0;
    const entry = new NGFCacheEntry(value, expiresAt);
    this.cacheEntries.set(key, entry);
    this.ensureCleanupTimer();
    this.evictIfOverCapacity();
    logger.info(TAG, `缓存写入: key=${key}, ttlMs=${ttlMs}`);
  }

  get(key: string): string {
    const entry = this.cacheEntries.get(key);
    if (!entry) {
      logger.debug(TAG, `缓存未命中: key=${key}`);
      return '';
    }

    const now = Date.now();
    if (entry.isExpired(now)) {
      this.cacheEntries.delete(key);
      logger.debug(TAG, `缓存已过期: key=${key}`);
      return '';
    }

    logger.debug(TAG, `缓存命中: key=${key}`);
    return entry.value;
  }

  has(key: string): boolean {
    const entry = this.cacheEntries.get(key);
    if (!entry) {
      logger.debug(TAG, `缓存存在=false: key=${key}`);
      return false;
    }

    const now = Date.now();
    if (entry.isExpired(now)) {
      this.cacheEntries.delete(key);
      logger.debug(TAG, `缓存存在=false: key=${key}, 原因=已过期`);
      return false;
    }

    logger.debug(TAG, `缓存存在=true: key=${key}`);
    return true;
  }

  remove(key: string): void {
    const existed = this.cacheEntries.delete(key);
    logger.info(TAG, `缓存删除: key=${key}, 存在=${existed}`);
  }

  clear(): void {
    const count = this.cacheEntries.size;
    this.cacheEntries.clear();
    this.stopCleanupTimer();
    logger.info(TAG, `缓存清空: 数量=${count}`);
  }

  size(): number {
    return this.cacheEntries.size;
  }

  private evictIfOverCapacity(): void {
    while (this.cacheEntries.size > MAX_CAPACITY) {
      let oldestKey: string = '';
      const keys = this.cacheEntries.keys();
      for (const key of keys) {
        oldestKey = key;
        break;
      }
      if (oldestKey.length > 0) {
        this.cacheEntries.delete(oldestKey);
        logger.debug(TAG, `缓存LRU淘汰: key=${oldestKey}`);
      } else {
        break;
      }
    }
  }

  private purgeExpired(): void {
    const now = Date.now();
    let purgedCount: number = 0;
    const keysToDelete: Array<string> = [];
    this.cacheEntries.forEach((entry: NGFCacheEntry, key: string) => {
      if (entry.isExpired(now)) {
        keysToDelete.push(key);
      }
    });
    for (let i = 0; i < keysToDelete.length; i++) {
      this.cacheEntries.delete(keysToDelete[i]);
      purgedCount++;
    }
    if (purgedCount > 0) {
      logger.info(TAG, `缓存清理过期: 数量=${purgedCount}`);
    }
  }

  private ensureCleanupTimer(): void {
    if (this.cleanupTimerId >= 0) {
      return;
    }
    this.cleanupTimerId = setInterval(() => {
      this.purgeExpired();
    }, CLEANUP_INTERVAL_MS);
    logger.debug(TAG, '缓存清理定时器已启动');
  }

  private stopCleanupTimer(): void {
    if (this.cleanupTimerId < 0) {
      return;
    }
    clearInterval(this.cleanupTimerId);
    this.cleanupTimerId = -1;
    logger.debug(TAG, '缓存清理定时器已停止');
  }
}

export const ngfCacheStoreFacade = new CacheStoreFacade();
