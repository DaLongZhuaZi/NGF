import {
  IErrorHandler,
  NGFErrorContext,
  NGFErrorSeverity,
  NGFRecoveryHandler
} from '../contracts/IErrorHandler';
import { logger } from '../../utils/Logger';

const LOG_TAG: string = 'ErrorHandlerFacade';
const MAX_RECENT_ERROR_RECORDS: number = 50;

export class NGFErrorRecord {
  readonly errorName: string;
  readonly message: string;
  readonly severity: NGFErrorSeverity;
  readonly context: NGFErrorContext;
  readonly timestamp: number;

  constructor(
    errorName: string,
    message: string,
    severity: NGFErrorSeverity,
    context: NGFErrorContext,
    timestamp: number
  ) {
    this.errorName = errorName;
    this.message = message;
    this.severity = severity;
    this.context = context;
    this.timestamp = timestamp;
  }
}

export type NGFErrorListener = (record: NGFErrorRecord) => void;

export class ErrorHandlerFacade implements IErrorHandler {
  private readonly recentErrors: Array<NGFErrorRecord> = [];
  private readonly recoveryStrategies: Map<string, NGFRecoveryHandler> = new Map<string, NGFRecoveryHandler>();
  private readonly errorListeners: Array<NGFErrorListener> = [];

  async handle(
    errorName: string,
    message: string,
    severity: NGFErrorSeverity,
    context: NGFErrorContext
  ): Promise<boolean> {
    try {
      const now = Date.now();
      const record = new NGFErrorRecord(errorName, message, severity, context, now);

      this.pushRecord(record);
      logger.error(context.source, `${errorName}: ${message}`);
      this.notifyListeners(record);

      if (severity === NGFErrorSeverity.HIGH || severity === NGFErrorSeverity.CRITICAL) {
        const recovered = await this.tryRecover(errorName, message, severity, context);
        if (recovered) {
          logger.info(context.source, `recovery succeeded: error=${errorName}`);
          return true;
        }
      }
      return true;
    } catch (error) {
      logger.error(LOG_TAG, `error handling failed: ${errorToString(error as Object | string | number | boolean)}`);
      return false;
    }
  }

  registerRecoverStrategy(strategyName: string, handler: NGFRecoveryHandler): boolean {
    const normalized = strategyName.trim();
    if (normalized.length <= 0) {
      logger.warn(LOG_TAG, 'registerRecoverStrategy ignored: strategyName is empty');
      return false;
    }
    if (this.recoveryStrategies.has(normalized)) {
      logger.debug(LOG_TAG, `registerRecoverStrategy skipped (already exists): strategy=${normalized}`);
      return false;
    }
    this.recoveryStrategies.set(normalized, handler);
    logger.info(LOG_TAG, `registered recovery strategy: strategy=${normalized}`);
    return true;
  }

  reportError(
    errorName: string,
    message: string,
    severity: NGFErrorSeverity,
    context: NGFErrorContext
  ): void {
    const now = Date.now();
    const record = new NGFErrorRecord(errorName, message, severity, context, now);
    this.pushRecord(record);
    logger.error(context.source, `${errorName}: ${message}`);
    this.notifyListeners(record);
  }

  getRecentErrorCount(): number {
    return this.recentErrors.length;
  }

  getRecentErrors(): Array<NGFErrorRecord> {
    const copy: Array<NGFErrorRecord> = [];
    for (let i = 0; i < this.recentErrors.length; i++) {
      copy.push(this.recentErrors[i]);
    }
    return copy;
  }

  clearErrors(): void {
    const count = this.recentErrors.length;
    this.recentErrors.length = 0;
    logger.info(LOG_TAG, `cleared errors: count=${count}`);
  }

  addErrorListener(listener: NGFErrorListener): void {
    for (let i = 0; i < this.errorListeners.length; i++) {
      if (this.errorListeners[i] === listener) {
        logger.debug(LOG_TAG, 'addErrorListener skipped: listener already registered');
        return;
      }
    }
    this.errorListeners.push(listener);
    logger.info(LOG_TAG, `added error listener: total=${this.errorListeners.length}`);
  }

  removeErrorListener(listener: NGFErrorListener): void {
    for (let i = 0; i < this.errorListeners.length; i++) {
      if (this.errorListeners[i] === listener) {
        this.errorListeners.splice(i, 1);
        logger.info(LOG_TAG, `removed error listener: total=${this.errorListeners.length}`);
        return;
      }
    }
    logger.debug(LOG_TAG, 'removeErrorListener skipped: listener not found');
  }

  private pushRecord(record: NGFErrorRecord): void {
    this.recentErrors.push(record);
    if (this.recentErrors.length > MAX_RECENT_ERROR_RECORDS) {
      this.recentErrors.shift();
    }
  }

  private notifyListeners(record: NGFErrorRecord): void {
    for (let i = 0; i < this.errorListeners.length; i++) {
      try {
        this.errorListeners[i](record);
      } catch (error) {
        logger.warn(LOG_TAG, `error listener execution failed: ${errorToString(error as Object | string | number | boolean)}`);
      }
    }
  }

  private async tryRecover(
    errorName: string,
    message: string,
    severity: NGFErrorSeverity,
    context: NGFErrorContext
  ): Promise<boolean> {
    const strategyNames = this.recoveryStrategies.keys();
    for (const strategyName of strategyNames) {
      const handler = this.recoveryStrategies.get(strategyName);
      if (handler) {
        try {
          logger.info(LOG_TAG, `trying recovery strategy: ${strategyName}`);
          const result = await handler(errorName, message, severity, context);
          if (result) {
            return true;
          }
        } catch (recoveryError) {
          logger.warn(LOG_TAG, `recovery strategy failed: ${strategyName}, error=${errorToString(recoveryError as Object | string | number | boolean)}`);
        }
      }
    }
    return false;
  }
}

function errorToString(error: Object | string | number | boolean): string {
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

export const ngfErrorHandlerFacade: ErrorHandlerFacade = new ErrorHandlerFacade();
