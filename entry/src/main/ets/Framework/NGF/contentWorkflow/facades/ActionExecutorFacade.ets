import { logger } from '../../utils/Logger';
import { IActionExecutor, NGFActionResult } from '../contracts/IActionExecutor';

const TAG: string = 'NGFActionExecutorFacade';

class NGFWaitActionEnvelope {
  waitMs: number;

  constructor(waitMs: number) {
    this.waitMs = waitMs;
  }
}

class NGFActionOutputEnvelope {
  actionType: string;
  actionJson: string;
  contextJson: string;
  executedAt: number;

  constructor(actionType: string, actionJson: string, contextJson: string, executedAt: number) {
    this.actionType = actionType;
    this.actionJson = actionJson;
    this.contextJson = contextJson;
    this.executedAt = executedAt;
  }
}

export class ActionExecutorFacade implements IActionExecutor {
  async executeAction(actionType: string, actionJson: string, contextJson: string): Promise<NGFActionResult> {
    const normalizedType = actionType.trim().toLowerCase();
    if (normalizedType.length <= 0) {
      logger.warn(TAG, 'executeAction ignored: actionType is empty');
      return new NGFActionResult(false, '');
    }

    logger.info(TAG, `execute action: type=${normalizedType}`);

    if (normalizedType === 'wait') {
      const waitAction = this.parseWaitAction(actionJson);
      if (waitAction.waitMs > 0) {
        logger.debug(TAG, `wait action sleep: durationMs=${waitAction.waitMs}`);
        await this.sleep(waitAction.waitMs);
      }
      const waitOutput = new NGFActionOutputEnvelope('wait', actionJson, contextJson, Date.now());
      logger.info(TAG, `action completed: type=${normalizedType}`);
      return new NGFActionResult(true, JSON.stringify(waitOutput));
    }

    if (normalizedType === 'extract'
      || normalizedType === 'transform'
      || normalizedType === 'script'
      || normalizedType === 'navigate'
      || normalizedType === 'api') {
      const output = new NGFActionOutputEnvelope(normalizedType, actionJson, contextJson, Date.now());
      logger.info(TAG, `action completed: type=${normalizedType}`);
      return new NGFActionResult(true, JSON.stringify(output));
    }

    logger.warn(TAG, `unsupported action type: ${normalizedType}`);
    return new NGFActionResult(false, '');
  }

  private parseWaitAction(actionJson: string): NGFWaitActionEnvelope {
    if (actionJson.trim().length <= 0) {
      logger.debug(TAG, 'parseWaitAction fallback: actionJson is empty');
      return new NGFWaitActionEnvelope(0);
    }

    try {
      const parsed = JSON.parse(actionJson) as Partial<NGFWaitActionEnvelope>;
      const waitMs = parsed.waitMs && typeof parsed.waitMs === 'number' ? parsed.waitMs : 0;
      return new NGFWaitActionEnvelope(waitMs);
    } catch {
      logger.warn(TAG, 'parseWaitAction failed: invalid JSON payload');
      return new NGFWaitActionEnvelope(0);
    }
  }

  private async sleep(durationMs: number): Promise<void> {
    await new Promise<void>((resolve: () => void) => {
      setTimeout((): void => {
        resolve();
      }, durationMs);
    });
  }
}

export const ngfActionExecutorFacade = new ActionExecutorFacade();
