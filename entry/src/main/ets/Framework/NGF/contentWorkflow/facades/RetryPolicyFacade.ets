import { logger } from '../../utils/Logger';
import { IRetryPolicy } from '../contracts/IRetryPolicy';

const TAG: string = 'NGFRetryPolicyFacade';

class NGFRetryProfile {
  maxAttempts: number;
  baseDelayMs: number;
  maxDelayMs: number;

  constructor(maxAttempts: number, baseDelayMs: number, maxDelayMs: number) {
    this.maxAttempts = maxAttempts;
    this.baseDelayMs = baseDelayMs;
    this.maxDelayMs = maxDelayMs;
  }
}

export class RetryPolicyFacade implements IRetryPolicy {
  private readonly profile: NGFRetryProfile = new NGFRetryProfile(3, 600, 5000);

  shouldRetry(attempt: number, errorCode: string): boolean {
    if (attempt <= 0) {
      logger.warn(TAG, `重试判断忽略: 无效的尝试次数=${attempt}`);
      return false;
    }

    const normalizedCode = errorCode.trim().toUpperCase();
    if (normalizedCode === 'NON_RETRYABLE') {
      logger.info(TAG, `不重试: 尝试=${attempt}, 错误码=${normalizedCode}`);
      return false;
    }

    const shouldRetry = attempt < this.profile.maxAttempts;
    logger.debug(TAG, `重试判断: 尝试=${attempt}, 错误码=${normalizedCode}, 结果=${shouldRetry}`);
    return shouldRetry;
  }

  nextDelayMs(attempt: number): number {
    if (attempt <= 0) {
      logger.debug(TAG, `下次延迟回退: 尝试=${attempt}, 延迟=${this.profile.baseDelayMs}ms`);
      return this.profile.baseDelayMs;
    }

    const rawDelay = this.profile.baseDelayMs * Math.pow(2, attempt - 1);
    if (rawDelay > this.profile.maxDelayMs) {
      logger.debug(TAG, `下次延迟封顶: 尝试=${attempt}, 延迟=${this.profile.maxDelayMs}ms`);
      return this.profile.maxDelayMs;
    }

    logger.debug(TAG, `下次延迟: 尝试=${attempt}, 延迟=${rawDelay}ms`);
    return rawDelay;
  }
}

export const ngfRetryPolicyFacade = new RetryPolicyFacade();
