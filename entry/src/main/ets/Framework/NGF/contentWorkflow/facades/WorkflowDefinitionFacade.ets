import { logger } from '../../utils/Logger';
import {
  IWorkflowDefinitionManager,
  NGFWorkflowDefinition,
  NGFWorkflowExecutionResult,
  NGFWorkflowParallelGroup,
  NGFWorkflowStepCondition,
  NGFWorkflowStepDefinition,
  NGFWorkflowStepResult
} from '../contracts/IWorkflowDefinition';
import { ngfActionExecutorFacade } from './ActionExecutorFacade';
import { NGFActionResult } from '../contracts/IActionExecutor';

const TAG: string = 'NGFWorkflowDefinitionFacade';

export class WorkflowDefinitionFacade implements IWorkflowDefinitionManager {
  private readonly workflows: Map<string, NGFWorkflowDefinition> = new Map<string, NGFWorkflowDefinition>();

  registerWorkflow(definition: NGFWorkflowDefinition): void {
    const name = definition.workflowName.trim();
    if (name.length <= 0) {
      logger.warn(TAG, '注册工作流忽略: workflowName 为空');
      return;
    }
    this.workflows.set(name, definition);
    logger.info(TAG, `注册工作流: name=${name}, steps=${definition.steps.length}`);
  }

  unregisterWorkflow(workflowName: string): boolean {
    const name = workflowName.trim();
    if (this.workflows.has(name)) {
      this.workflows.delete(name);
      logger.info(TAG, `注销工作流: name=${name}`);
      return true;
    }
    logger.warn(TAG, `注销工作流未找到: name=${name}`);
    return false;
  }

  getWorkflow(workflowName: string): NGFWorkflowDefinition | null {
    const name = workflowName.trim();
    const definition = this.workflows.get(name);
    if (definition === undefined) {
      return null;
    }
    return definition;
  }

  listWorkflowNames(): Array<string> {
    const names: Array<string> = [];
    const keys = this.workflows.keys();
    for (const key of keys) {
      names.push(key);
    }
    return names;
  }

  async executeWorkflow(workflowName: string, contextJson: string): Promise<NGFWorkflowExecutionResult> {
    const name = workflowName.trim();
    const definition = this.workflows.get(name);
    if (definition === undefined) {
      logger.warn(TAG, `工作流未注册: name=${name}`);
      return new NGFWorkflowExecutionResult(name, false, [], '');
    }

    const stepResults: Array<NGFWorkflowStepResult> = [];
    let lastOutput: string = contextJson;

    // 并行组执行（在串行步骤前执行）
    if (definition.parallelGroups.length > 0) {
      for (let gi = 0; gi < definition.parallelGroups.length; gi++) {
        const group = definition.parallelGroups[gi];
        const groupResult = await this.executeParallelGroup(group, lastOutput);
        for (let ri = 0; ri < groupResult.length; ri++) {
          stepResults.push(groupResult[ri]);
          if (!groupResult[ri].success) {
            logger.warn(TAG, `并行组步骤失败: group=${group.groupName}, step=${groupResult[ri].stepName}`);
            return new NGFWorkflowExecutionResult(name, false, stepResults, lastOutput);
          }
        }
      }
    }

    // 串行步骤执行（支持超时）
    for (let index = 0; index < definition.steps.length; index++) {
      const step = definition.steps[index];

      if (step.condition !== null && !this.evaluateCondition(step.condition, lastOutput)) {
        logger.debug(TAG, `步骤跳过: step=${step.stepName}, 前置条件不满足`);
        stepResults.push(new NGFWorkflowStepResult(step.stepName, step.actionType, true, '', true));
        continue;
      }

      logger.debug(TAG, `执行步骤: step=${step.stepName}, type=${step.actionType}`);
      const actionResult: NGFActionResult = await this.executeStepWithTimeout(step, lastOutput);

      stepResults.push(new NGFWorkflowStepResult(
        step.stepName,
        step.actionType,
        actionResult.success,
        actionResult.outputJson,
        false
      ));

      if (!actionResult.success) {
        logger.warn(TAG, `步骤失败: step=${step.stepName}, workflow=${name}`);
        return new NGFWorkflowExecutionResult(name, false, stepResults, lastOutput);
      }

      lastOutput = actionResult.outputJson;
    }

    logger.info(TAG, `工作流执行完成: name=${name}, steps=${stepResults.length}`);
    return new NGFWorkflowExecutionResult(name, true, stepResults, lastOutput);
  }

  /**
   * 并行组执行：组内所有步骤并发执行，投入 Promise.all
   */
  private async executeParallelGroup(
    group: NGFWorkflowParallelGroup,
    contextJson: string
  ): Promise<Array<NGFWorkflowStepResult>> {
    logger.debug(TAG, `并行组开始: group=${group.groupName}, steps=${group.steps.length}`);
    const promises: Array<Promise<NGFWorkflowStepResult>> = [];
    for (let i = 0; i < group.steps.length; i++) {
      const step = group.steps[i];
      const p = this.executeStepWithTimeout(step, contextJson).then(
        (result: NGFActionResult): NGFWorkflowStepResult => {
          return new NGFWorkflowStepResult(step.stepName, step.actionType, result.success, result.outputJson, false);
        }
      );
      promises.push(p);
    }

    let results: Array<NGFWorkflowStepResult>;
    if (group.timeoutMs !== null) {
      const timeoutPromise = new Promise<Array<NGFWorkflowStepResult>>(
        (_resolve: (v: Array<NGFWorkflowStepResult>) => void, reject: (e: Error) => void) => {
          setTimeout(() => reject(new Error(`并行组超时: group=${group.groupName}, timeout=${group.timeoutMs}ms`)), group.timeoutMs as number);
        }
      );
      results = await Promise.race<Array<NGFWorkflowStepResult>>([
        Promise.all<NGFWorkflowStepResult>(promises),
        timeoutPromise
      ]);
    } else {
      results = await Promise.all<NGFWorkflowStepResult>(promises);
    }

    logger.info(TAG, `并行组完成: group=${group.groupName}, results=${results.length}`);
    return results;
  }

  /**
   * 单步骤执行（包装超时逻辑）
   */
  private async executeStepWithTimeout(
    step: NGFWorkflowStepDefinition,
    contextJson: string
  ): Promise<NGFActionResult> {
    const actionPromise = ngfActionExecutorFacade.executeAction(step.actionType, step.actionJson, contextJson);
    if (step.timeoutMs === null) {
      return actionPromise;
    }
    const timeoutMs = step.timeoutMs as number;
    const timeoutPromise = new Promise<NGFActionResult>(
      (_resolve: (v: NGFActionResult) => void, reject: (e: Error) => void) => {
        setTimeout(
          () => reject(new Error(`步骤超时: step=${step.stepName}, timeout=${timeoutMs}ms`)),
          timeoutMs
        );
      }
    );
    try {
      return await Promise.race<NGFActionResult>([actionPromise, timeoutPromise]);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.warn(TAG, `步骤超时或异常: step=${step.stepName}, err=${msg}`);
      return new NGFActionResult(false, '');
    }
  }

  private evaluateCondition(condition: NGFWorkflowStepCondition, contextJson: string): boolean {
    try {
      const context = JSON.parse(contextJson) as object;
      const entries = Object.entries(context) as [string, string][];
      let actualValue: string = '';
      for (let index = 0; index < entries.length; index++) {
        if (entries[index][0] === condition.field) {
          actualValue = String(entries[index][1]);
          break;
        }
      }

      if (condition.operator === 'equals') {
        return actualValue === condition.value;
      }
      if (condition.operator === 'not_equals') {
        return actualValue !== condition.value;
      }
      if (condition.operator === 'contains') {
        return actualValue.indexOf(condition.value) >= 0;
      }
      if (condition.operator === 'not_empty') {
        return actualValue.length > 0;
      }
      if (condition.operator === 'empty') {
        return actualValue.length <= 0;
      }

      logger.warn(TAG, `未知条件操作符: ${condition.operator}`);
      return true;
    } catch {
      logger.warn(TAG, '条件评估失败: contextJson 解析错误');
      return true;
    }
  }
}

export const ngfWorkflowDefinitionFacade: WorkflowDefinitionFacade = new WorkflowDefinitionFacade();
