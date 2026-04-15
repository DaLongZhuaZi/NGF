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
      logger.warn(TAG, `shouldRetry ignored: invalid attempt=${attempt}`);
      return false;
    }

    const normalizedCode = errorCode.trim().toUpperCase();
    if (normalizedCode === 'NON_RETRYABLE') {
      logger.info(TAG, `shouldRetry=false: attempt=${attempt}, errorCode=${normalizedCode}`);
      return false;
    }

    const shouldRetry = attempt < this.profile.maxAttempts;
    logger.debug(TAG, `shouldRetry: attempt=${attempt}, errorCode=${normalizedCode}, result=${shouldRetry}`);
    return shouldRetry;
  }

  nextDelayMs(attempt: number): number {
    if (attempt <= 0) {
      logger.debug(TAG, `nextDelayMs fallback: attempt=${attempt}, delayMs=${this.profile.baseDelayMs}`);
      return this.profile.baseDelayMs;
    }

    const rawDelay = this.profile.baseDelayMs * Math.pow(2, attempt - 1);
    if (rawDelay > this.profile.maxDelayMs) {
      logger.debug(TAG, `nextDelayMs capped: attempt=${attempt}, delayMs=${this.profile.maxDelayMs}`);
      return this.profile.maxDelayMs;
    }

    logger.debug(TAG, `nextDelayMs: attempt=${attempt}, delayMs=${rawDelay}`);
    return rawDelay;
  }
}

export const ngfRetryPolicyFacade = new RetryPolicyFacade();
