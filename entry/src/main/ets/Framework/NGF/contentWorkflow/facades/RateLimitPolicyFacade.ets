import { logger } from '../../utils/Logger';
import { IRateLimitPolicy } from '../contracts/IRateLimitPolicy';

const TAG: string = 'NGFRateLimitPolicyFacade';

class NGFRateLimitRecord {
  key: string;
  lastRequestAt: number;
  minIntervalMs: number;

  constructor(key: string, lastRequestAt: number, minIntervalMs: number) {
    this.key = key;
    this.lastRequestAt = lastRequestAt;
    this.minIntervalMs = minIntervalMs;
  }
}

export class RateLimitPolicyFacade implements IRateLimitPolicy {
  private readonly records: Map<string, NGFRateLimitRecord> = new Map<string, NGFRateLimitRecord>();
  private readonly defaultIntervalMs: number = 400;

  canProceed(key: string, nowMs: number): boolean {
    const normalizedKey = this.normalizeKey(key);
    const record = this.getOrCreateRecord(normalizedKey);
    if (record.lastRequestAt <= 0) {
      logger.debug(TAG, `限流检查: key=${normalizedKey}, 允许=true, 原因=首次请求`);
      return true;
    }

    const elapsed = nowMs - record.lastRequestAt;
    const allowed = elapsed >= record.minIntervalMs;
    if (!allowed) {
      logger.warn(TAG, `限流拦截: key=${normalizedKey}, 重试等待=${record.minIntervalMs - elapsed}ms`);
    } else {
      logger.debug(TAG, `限流检查: key=${normalizedKey}, 允许=true, 已过=${elapsed}ms`);
    }
    return allowed;
  }

  markRequest(key: string, nowMs: number): void {
    const normalizedKey = this.normalizeKey(key);
    const record = this.getOrCreateRecord(normalizedKey);
    record.lastRequestAt = nowMs;
    logger.debug(TAG, `标记请求: key=${normalizedKey}, 请求时间=${nowMs}`);
  }

  retryAfterMs(key: string, nowMs: number): number {
    const normalizedKey = this.normalizeKey(key);
    const record = this.getOrCreateRecord(normalizedKey);
    if (record.lastRequestAt <= 0) {
      logger.debug(TAG, `重试等待: key=${normalizedKey}, 剩余=0ms`);
      return 0;
    }

    const elapsed = nowMs - record.lastRequestAt;
    const remaining = record.minIntervalMs - elapsed;
    if (remaining <= 0) {
      logger.debug(TAG, `重试等待: key=${normalizedKey}, 剩余=0ms`);
      return 0;
    }
    logger.debug(TAG, `重试等待: key=${normalizedKey}, 剩余=${remaining}ms`);
    return remaining;
  }

  private normalizeKey(key: string): string {
    const normalized = key.trim();
    if (normalized.length <= 0) {
      return 'global';
    }
    return normalized;
  }

  private getOrCreateRecord(key: string): NGFRateLimitRecord {
    const existing = this.records.get(key);
    if (existing) {
      return existing;
    }

    const created = new NGFRateLimitRecord(key, 0, this.defaultIntervalMs);
    this.records.set(key, created);
    logger.debug(TAG, `创建限流记录: key=${key}, 间隔=${this.defaultIntervalMs}ms`);
    return created;
  }
}

export const ngfRateLimitPolicyFacade = new RateLimitPolicyFacade();
