import { errorManager } from '@kit.AbilityKit';
import { logger } from './Logger';
import { FileUtils } from './FileUtils';

const TAG: string = 'CrashAnalyticsFacade';
const CRASH_LOG_DIR = 'crash_logs';

export class CrashAnalyticsFacade {
  private isInitialized: boolean = false;
  private observerId: number = -1;

  public initialize(): void {
    if (this.isInitialized) {
      return;
    }

    try {
      // Register global error observer
      this.observerId = errorManager.on('error', {
        onUnhandledException: (errMsg: string) => {
          this.handleCrash(errMsg);
        }
      });
      this.isInitialized = true;
      logger.info(TAG, 'CrashAnalytics initialized and monitoring global exceptions.');
    } catch (e) {
      logger.error(TAG, `Failed to initialize CrashAnalytics: ${e}`);
    }
  }

  public terminate(): void {
    if (!this.isInitialized || this.observerId === -1) {
      return;
    }
    try {
      errorManager.off('error', this.observerId);
      this.isInitialized = false;
      this.observerId = -1;
      logger.info(TAG, 'CrashAnalytics terminated.');
    } catch (e) {
      logger.error(TAG, `Failed to terminate CrashAnalytics: ${e}`);
    }
  }

  private handleCrash(errorDetails: string): void {
    logger.error(TAG, `FATAL CRASH DETECTED:\n${errorDetails}`);
    try {
      const timestamp = Date.now();
      const fileName = `${CRASH_LOG_DIR}/crash_${timestamp}.log`;
      
      const logContent = `--- CRASH REPORT ---\n` +
                         `Time: ${new Date(timestamp).toISOString()}\n` +
                         `Details:\n${errorDetails}\n` +
                         `--------------------\n`;
      
      // Ensure the directory exists implicitly or explicitly. FileUtils in NGF handles parent dir creation.
      FileUtils.writeText(fileName, logContent);
      logger.info(TAG, `Crash log saved to sandbox: ${fileName}`);
    } catch (e) {
      logger.error(TAG, `Failed to write crash log to sandbox: ${e}`);
    }
  }

  public getCrashLogs(): string[] {
    try {
      const entries = FileUtils.listDirectory(CRASH_LOG_DIR);
      return entries.filter(e => !e.isDirectory).map(e => `${CRASH_LOG_DIR}/${e.name}`);
    } catch (e) {
      logger.warn(TAG, `Could not list crash logs: ${e}`);
      return [];
    }
  }

  public readCrashLog(fileName: string): string {
    try {
      return FileUtils.readText(fileName);
    } catch (e) {
      logger.error(TAG, `Failed to read crash log: ${fileName}`);
      return '';
    }
  }
}

export const crashAnalytics = new CrashAnalyticsFacade();
