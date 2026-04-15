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
      logger.debug(TAG, `canProceed: key=${normalizedKey}, allowed=true, reason=first_request`);
      return true;
    }

    const elapsed = nowMs - record.lastRequestAt;
    const allowed = elapsed >= record.minIntervalMs;
    if (!allowed) {
      logger.warn(TAG, `canProceed blocked: key=${normalizedKey}, retryAfterMs=${record.minIntervalMs - elapsed}`);
    } else {
      logger.debug(TAG, `canProceed: key=${normalizedKey}, allowed=true, elapsedMs=${elapsed}`);
    }
    return allowed;
  }

  markRequest(key: string, nowMs: number): void {
    const normalizedKey = this.normalizeKey(key);
    const record = this.getOrCreateRecord(normalizedKey);
    record.lastRequestAt = nowMs;
    logger.debug(TAG, `markRequest: key=${normalizedKey}, requestAt=${nowMs}`);
  }

  retryAfterMs(key: string, nowMs: number): number {
    const normalizedKey = this.normalizeKey(key);
    const record = this.getOrCreateRecord(normalizedKey);
    if (record.lastRequestAt <= 0) {
      logger.debug(TAG, `retryAfterMs: key=${normalizedKey}, remainingMs=0`);
      return 0;
    }

    const elapsed = nowMs - record.lastRequestAt;
    const remaining = record.minIntervalMs - elapsed;
    if (remaining <= 0) {
      logger.debug(TAG, `retryAfterMs: key=${normalizedKey}, remainingMs=0`);
      return 0;
    }
    logger.debug(TAG, `retryAfterMs: key=${normalizedKey}, remainingMs=${remaining}`);
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
    logger.debug(TAG, `create rate limit record: key=${key}, intervalMs=${this.defaultIntervalMs}`);
    return created;
  }
}

export const ngfRateLimitPolicyFacade = new RateLimitPolicyFacade();
