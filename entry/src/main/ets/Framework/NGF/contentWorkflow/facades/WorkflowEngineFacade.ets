import { logger } from '../../utils/Logger';
import { IWorkflowEngine, NGFWorkflowResult } from '../contracts/IWorkflowEngine';
import { ngfActionExecutorFacade } from './ActionExecutorFacade';
import { ngfRateLimitPolicyFacade } from './RateLimitPolicyFacade';
import { ngfRetryPolicyFacade } from './RetryPolicyFacade';

const TAG: string = 'NGFWorkflowEngineFacade';

class NGFWorkflowInputEnvelope {
  actionType: string;
  actionJson: string;
  contextJson: string;

  constructor(actionType: string, actionJson: string, contextJson: string) {
    this.actionType = actionType;
    this.actionJson = actionJson;
    this.contextJson = contextJson;
  }
}

class NGFWorkflowSuccessEnvelope {
  workflowName: string;
  sourceId: string;
  attempts: number;
  outputJson: string;
  executedAt: number;

  constructor(workflowName: string, sourceId: string, attempts: number, outputJson: string, executedAt: number) {
    this.workflowName = workflowName;
    this.sourceId = sourceId;
    this.attempts = attempts;
    this.outputJson = outputJson;
    this.executedAt = executedAt;
  }
}

class NGFWorkflowErrorEnvelope {
  code: string;
  message: string;
  retryAfterMs: number;
  attempts: number;

  constructor(code: string, message: string, retryAfterMs: number, attempts: number) {
    this.code = code;
    this.message = message;
    this.retryAfterMs = retryAfterMs;
    this.attempts = attempts;
  }
}

export class WorkflowEngineFacade implements IWorkflowEngine {
  async executeWorkflow(workflowName: string, sourceId: string, inputJson: string): Promise<NGFWorkflowResult> {
    const normalizedWorkflow = workflowName.trim();
    const normalizedSource = sourceId.trim();
    if (normalizedWorkflow.length <= 0 || normalizedSource.length <= 0) {
      logger.warn(TAG, `executeWorkflow ignored: workflow=${normalizedWorkflow}, source=${normalizedSource}`);
      return new NGFWorkflowResult(false, '');
    }

    logger.info(TAG, `execute workflow: workflow=${normalizedWorkflow}, source=${normalizedSource}`);

    const rateLimitKey = `${normalizedSource}:${normalizedWorkflow}`;
    const now = Date.now();
    if (!ngfRateLimitPolicyFacade.canProceed(rateLimitKey, now)) {
      const retryAfter = ngfRateLimitPolicyFacade.retryAfterMs(rateLimitKey, now);
      logger.warn(TAG, `workflow rate limited: workflow=${normalizedWorkflow}, source=${normalizedSource}, retryAfterMs=${retryAfter}`);
      const rateLimitError = new NGFWorkflowErrorEnvelope(
        'RATE_LIMITED',
        'workflow request is rate limited',
        retryAfter,
        0
      );
      return new NGFWorkflowResult(false, JSON.stringify(rateLimitError));
    }
    ngfRateLimitPolicyFacade.markRequest(rateLimitKey, now);

    const workflowInput = this.parseWorkflowInput(inputJson);
    logger.debug(TAG, `workflow input resolved: actionType=${workflowInput.actionType}`);

    let attempt = 1;
    let lastRetryDelay = 0;
    while (true) {
      logger.debug(TAG, `workflow attempt start: workflow=${normalizedWorkflow}, attempt=${attempt}`);
      const actionResult = await ngfActionExecutorFacade.executeAction(
        workflowInput.actionType,
        workflowInput.actionJson,
        workflowInput.contextJson
      );
      if (actionResult.success) {
        const successOutput = new NGFWorkflowSuccessEnvelope(
          normalizedWorkflow,
          normalizedSource,
          attempt,
          actionResult.outputJson,
          Date.now()
        );
        logger.info(TAG, `workflow completed: workflow=${normalizedWorkflow}, source=${normalizedSource}, attempts=${attempt}`);
        return new NGFWorkflowResult(true, JSON.stringify(successOutput));
      }

      if (!ngfRetryPolicyFacade.shouldRetry(attempt, 'ACTION_FAILED')) {
        logger.warn(TAG, `workflow retry rejected: workflow=${normalizedWorkflow}, attempt=${attempt}`);
        break;
      }

      lastRetryDelay = ngfRetryPolicyFacade.nextDelayMs(attempt);
      logger.info(TAG, `workflow retry scheduled: workflow=${normalizedWorkflow}, nextAttempt=${attempt + 1}, delayMs=${lastRetryDelay}`);
      await this.sleep(lastRetryDelay);
      attempt = attempt + 1;
    }

    const failedOutput = new NGFWorkflowErrorEnvelope(
      'ACTION_FAILED',
      'workflow action execution failed',
      lastRetryDelay,
      attempt
    );
    logger.warn(TAG, `workflow failed: workflow=${normalizedWorkflow}, source=${normalizedSource}, attempts=${attempt}`);
    return new NGFWorkflowResult(false, JSON.stringify(failedOutput));
  }

  private parseWorkflowInput(inputJson: string): NGFWorkflowInputEnvelope {
    if (inputJson.trim().length <= 0) {
      logger.debug(TAG, 'parseWorkflowInput fallback: inputJson is empty');
      return new NGFWorkflowInputEnvelope('extract', '{}', '{}');
    }

    try {
      const parsed = JSON.parse(inputJson) as Partial<NGFWorkflowInputEnvelope>;
      const actionType = parsed.actionType && typeof parsed.actionType === 'string' ? parsed.actionType : 'extract';
      const actionJson = parsed.actionJson && typeof parsed.actionJson === 'string' ? parsed.actionJson : '{}';
      const contextJson = parsed.contextJson && typeof parsed.contextJson === 'string' ? parsed.contextJson : '{}';
      return new NGFWorkflowInputEnvelope(actionType, actionJson, contextJson);
    } catch {
      logger.warn(TAG, 'parseWorkflowInput failed: invalid JSON payload');
      return new NGFWorkflowInputEnvelope('extract', '{}', '{}');
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

export const ngfWorkflowEngineFacade = new WorkflowEngineFacade();
