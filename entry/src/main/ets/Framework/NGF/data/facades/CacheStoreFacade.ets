import { logger } from '../../utils/Logger';
import { ICacheStore } from '../contracts/ICacheStore';

const TAG: string = 'NGFCacheStoreFacade';

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

  put(key: string, value: string, ttlMs: number): void {
    const now = Date.now();
    const expiresAt = ttlMs > 0 ? now + ttlMs : 0;
    const entry = new NGFCacheEntry(value, expiresAt);
    this.cacheEntries.set(key, entry);
    logger.info(TAG, `cache put: key=${key}, ttlMs=${ttlMs}`);
  }

  get(key: string): string {
    const entry = this.cacheEntries.get(key);
    if (!entry) {
      logger.debug(TAG, `cache miss: key=${key}`);
      return '';
    }

    const now = Date.now();
    if (entry.isExpired(now)) {
      this.cacheEntries.delete(key);
      logger.debug(TAG, `cache expired: key=${key}`);
      return '';
    }

    logger.debug(TAG, `cache hit: key=${key}`);
    return entry.value;
  }

  has(key: string): boolean {
    const entry = this.cacheEntries.get(key);
    if (!entry) {
      logger.debug(TAG, `cache has=false: key=${key}`);
      return false;
    }

    const now = Date.now();
    if (entry.isExpired(now)) {
      this.cacheEntries.delete(key);
      logger.debug(TAG, `cache has=false: key=${key}, reason=expired`);
      return false;
    }

    logger.debug(TAG, `cache has=true: key=${key}`);
    return true;
  }

  remove(key: string): void {
    const existed = this.cacheEntries.delete(key);
    logger.info(TAG, `cache remove: key=${key}, existed=${existed}`);
  }

  clear(): void {
    const count = this.cacheEntries.size;
    this.cacheEntries.clear();
    logger.info(TAG, `cache clear: count=${count}`);
  }
}

export const ngfCacheStoreFacade = new CacheStoreFacade();
