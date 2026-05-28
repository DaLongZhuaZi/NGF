import { logger } from '../../utils/Logger';
import { IWorkflowEngine, NGFWorkflowResult } from '../contracts/IWorkflowEngine';
import { ngfActionExecutorFacade } from './ActionExecutorFacade';
import { ngfRateLimitPolicyFacade } from './RateLimitPolicyFacade';
import { ngfRetryPolicyFacade } from './RetryPolicyFacade';

const TAG: string = 'NGFWorkflowEngineFacade';
const ACTION_TYPE_LOOP: string = 'loop';
const ACTION_TYPE_PARALLEL: string = 'parallel';

class NGFWorkflowLoopStepDef {
  actionType: string;
  actionJson: string;

  constructor(actionType: string, actionJson: string) {
    this.actionType = actionType;
    this.actionJson = actionJson;
  }
}

class NGFWorkflowParallelStepDef {
  actionType: string;
  actionJson: string;

  constructor(actionType: string, actionJson: string) {
    this.actionType = actionType;
    this.actionJson = actionJson;
  }
}

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
      logger.warn(TAG, `executeWorkflow 忽略：workflow=${normalizedWorkflow}, source=${normalizedSource}`);
      return new NGFWorkflowResult(false, '');
    }

    logger.info(TAG, `执行工作流：workflow=${normalizedWorkflow}, source=${normalizedSource}`);

    const rateLimitKey = `${normalizedSource}:${normalizedWorkflow}`;
    const now = Date.now();
    if (!ngfRateLimitPolicyFacade.canProceed(rateLimitKey, now)) {
      const retryAfter = ngfRateLimitPolicyFacade.retryAfterMs(rateLimitKey, now);
      logger.warn(TAG, `工作流被限流：workflow=${normalizedWorkflow}, source=${normalizedSource}, retryAfterMs=${retryAfter}`);
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
    logger.debug(TAG, `工作流输入已解析：actionType=${workflowInput.actionType}`);

    if (workflowInput.actionType === ACTION_TYPE_LOOP) {
      logger.info(TAG, `执行循环工作流：workflow=${normalizedWorkflow}`);
      const loopResult = await this.executeLoopSteps(workflowInput.actionJson, workflowInput.contextJson);
      if (loopResult.success) {
        const successOutput = new NGFWorkflowSuccessEnvelope(
          normalizedWorkflow,
          normalizedSource,
          1,
          loopResult.outputJson,
          Date.now()
        );
        return new NGFWorkflowResult(true, JSON.stringify(successOutput));
      }
      const failedOutput = new NGFWorkflowErrorEnvelope(
        'LOOP_FAILED',
        'loop workflow execution failed',
        0,
        1
      );
      return new NGFWorkflowResult(false, JSON.stringify(failedOutput));
    }

    if (workflowInput.actionType === ACTION_TYPE_PARALLEL) {
      logger.info(TAG, `执行并发工作流：workflow=${normalizedWorkflow}`);
      const parallelResult = await this.executeParallelSteps(workflowInput.actionJson, workflowInput.contextJson);
      if (parallelResult.success) {
        const successOutput = new NGFWorkflowSuccessEnvelope(
          normalizedWorkflow,
          normalizedSource,
          1,
          parallelResult.outputJson,
          Date.now()
        );
        return new NGFWorkflowResult(true, JSON.stringify(successOutput));
      }
      const failedOutput = new NGFWorkflowErrorEnvelope(
        'PARALLEL_FAILED',
        'parallel workflow execution failed',
        0,
        1
      );
      return new NGFWorkflowResult(false, JSON.stringify(failedOutput));
    }


    let attempt = 1;
    let lastRetryDelay = 0;
    while (true) {
      logger.debug(TAG, `工作流尝试开始：workflow=${normalizedWorkflow}, 尝试=${attempt}`);
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
        logger.info(TAG, `工作流完成：workflow=${normalizedWorkflow}, source=${normalizedSource}, attempts=${attempt}`);
        return new NGFWorkflowResult(true, JSON.stringify(successOutput));
      }

      if (!ngfRetryPolicyFacade.shouldRetry(attempt, 'ACTION_FAILED')) {
        logger.warn(TAG, `工作流重试被拒绝：workflow=${normalizedWorkflow}, 尝试=${attempt}`);
        break;
      }

      lastRetryDelay = ngfRetryPolicyFacade.nextDelayMs(attempt);
      logger.info(TAG, `工作流重试已调度：workflow=${normalizedWorkflow}, nextAttempt=${attempt + 1}, delayMs=${lastRetryDelay}`);
      await this.sleep(lastRetryDelay);
      attempt = attempt + 1;
    }

    const failedOutput = new NGFWorkflowErrorEnvelope(
      'ACTION_FAILED',
      'workflow action execution failed',
      lastRetryDelay,
      attempt
    );
    logger.warn(TAG, `工作流失败：workflow=${normalizedWorkflow}, source=${normalizedSource}, attempts=${attempt}`);
    return new NGFWorkflowResult(false, JSON.stringify(failedOutput));
  }

  private parseWorkflowInput(inputJson: string): NGFWorkflowInputEnvelope {
    if (inputJson.trim().length <= 0) {
      logger.debug(TAG, 'parseWorkflowInput 回退：inputJson 为空');
      return new NGFWorkflowInputEnvelope('extract', '{}', '{}');
    }

    try {
      const parsed = JSON.parse(inputJson) as Partial<NGFWorkflowInputEnvelope>;
      const actionType = parsed.actionType && typeof parsed.actionType === 'string' ? parsed.actionType : 'extract';
      const actionJson = parsed.actionJson && typeof parsed.actionJson === 'string' ? parsed.actionJson : '{}';
      const contextJson = parsed.contextJson && typeof parsed.contextJson === 'string' ? parsed.contextJson : '{}';
      return new NGFWorkflowInputEnvelope(actionType, actionJson, contextJson);
    } catch {
      logger.warn(TAG, 'parseWorkflowInput 失败：无效的 JSON 负载');
      return new NGFWorkflowInputEnvelope('extract', '{}', '{}');
    }
  }

  private async executeLoopSteps(actionJson: string, contextJson: string): Promise<NGFWorkflowResult> {
    let iterations: number = 1;
    let steps: Array<NGFWorkflowLoopStepDef> = [];

    try {
      const parsed = JSON.parse(actionJson) as Record<string, Object | string | number | boolean | Array<Object>>;
      if (typeof parsed['iterations'] === 'number') {
        iterations = parsed['iterations'] as number;
      }
      if (Array.isArray(parsed['steps'])) {
        steps = this.parseLoopSteps(parsed['steps'] as Array<Record<string, string>>);
      }
    } catch {
      logger.warn(TAG, 'executeLoopSteps 解析 actionJson 失败');
      return new NGFWorkflowResult(false, '');
    }

    if (steps.length <= 0) {
      logger.warn(TAG, 'executeLoopSteps 已跳过：无内部步骤');
      return new NGFWorkflowResult(false, '');
    }

    if (iterations <= 0) {
      logger.warn(TAG, `executeLoopSteps 已跳过：iterations=${iterations}`);
      return new NGFWorkflowResult(false, '');
    }

    let lastOutput: string = '';
    for (let i: number = 0; i < iterations; i++) {
      logger.debug(TAG, `循环迭代开始：index=${i}, total=${iterations}`);

      const contextWithIndex = this.injectLoopIndex(contextJson, i);
      for (let stepIdx: number = 0; stepIdx < steps.length; stepIdx++) {
        const step = steps[stepIdx];
        const stepResult = await ngfActionExecutorFacade.executeAction(
          step.actionType,
          step.actionJson,
          contextWithIndex
        );
        if (!stepResult.success) {
          logger.warn(TAG, `循环内部步骤失败：iteration=${i}, stepIndex=${stepIdx}, actionType=${step.actionType}`);
          return new NGFWorkflowResult(false, lastOutput);
        }
        lastOutput = stepResult.outputJson;
      }

      logger.debug(TAG, `循环迭代完成：index=${i}`);
    }

    logger.info(TAG, `循环执行完成：iterations=${iterations}, steps=${steps.length}`);
    return new NGFWorkflowResult(true, lastOutput);
  }

  private parseLoopSteps(raw: Array<Record<string, string>>): Array<NGFWorkflowLoopStepDef> {
    const steps: Array<NGFWorkflowLoopStepDef> = [];
    for (let i: number = 0; i < raw.length; i++) {
      const entry = raw[i];
      const actionType = entry['actionType'] !== undefined ? entry['actionType'] : 'extract';
      const actionJson = entry['actionJson'] !== undefined ? entry['actionJson'] : '{}';
      steps.push(new NGFWorkflowLoopStepDef(actionType, actionJson));
    }
    return steps;
  }

  private injectLoopIndex(contextJson: string, loopIndex: number): string {
    try {
      const context = JSON.parse(contextJson) as Record<string, Object | string | number | boolean>;
      context['loopIndex'] = loopIndex;
      const serialized = JSON.stringify(context);
      return serialized !== undefined ? serialized : '{}';
    } catch {
      return `{"loopIndex":${loopIndex}}`;
    }
  }

  private async executeParallelSteps(actionJson: string, contextJson: string): Promise<NGFWorkflowResult> {
    let steps: Array<NGFWorkflowParallelStepDef> = [];

    try {
      const parsed = JSON.parse(actionJson) as Record<string, Object | string | number | boolean | Array<Object>>;
      if (Array.isArray(parsed['steps'])) {
        steps = this.parseParallelSteps(parsed['steps'] as Array<Record<string, string>>);
      }
    } catch {
      logger.warn(TAG, 'executeParallelSteps 解析 actionJson 失败');
      return new NGFWorkflowResult(false, '');
    }

    if (steps.length <= 0) {
      logger.warn(TAG, 'executeParallelSteps 已跳过：无内部步骤');
      return new NGFWorkflowResult(false, '');
    }

    logger.debug(TAG, `并发执行开始：steps=${steps.length}`);
    const promises: Array<Promise<NGFWorkflowResult>> = [];
    
    for (let stepIdx: number = 0; stepIdx < steps.length; stepIdx++) {
      const step = steps[stepIdx];
      promises.push(ngfActionExecutorFacade.executeAction(
        step.actionType,
        step.actionJson,
        contextJson
      ));
    }

    try {
      const results = await Promise.all(promises);
      let allSuccess = true;
      const outputs: Array<string> = [];
      for (let i = 0; i < results.length; i++) {
        if (!results[i].success) {
          logger.warn(TAG, `并发内部步骤失败：stepIndex=${i}, actionType=${steps[i].actionType}`);
          allSuccess = false;
          break;
        }
        outputs.push(results[i].outputJson);
      }
      
      if (!allSuccess) {
        return new NGFWorkflowResult(false, '');
      }

      logger.info(TAG, `并发执行完成：steps=${steps.length}`);
      return new NGFWorkflowResult(true, JSON.stringify(outputs));
    } catch (error) {
      logger.error(TAG, `并发执行发生异常: ${error}`);
      return new NGFWorkflowResult(false, '');
    }
  }

  private parseParallelSteps(raw: Array<Record<string, string>>): Array<NGFWorkflowParallelStepDef> {
    const steps: Array<NGFWorkflowParallelStepDef> = [];
    for (let i: number = 0; i < raw.length; i++) {
      const entry = raw[i];
      const actionType = entry['actionType'] !== undefined ? entry['actionType'] : 'extract';
      const actionJson = entry['actionJson'] !== undefined ? entry['actionJson'] : '{}';
      steps.push(new NGFWorkflowParallelStepDef(actionType, actionJson));
    }
    return steps;
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
