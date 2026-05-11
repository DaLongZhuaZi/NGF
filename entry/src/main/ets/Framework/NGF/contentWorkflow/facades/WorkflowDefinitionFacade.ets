import { logger } from '../../utils/Logger';
import {
  IWorkflowDefinitionManager,
  NGFWorkflowDefinition,
  NGFWorkflowExecutionResult,
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

    for (let index = 0; index < definition.steps.length; index++) {
      const step = definition.steps[index];

      if (step.condition !== null && !this.evaluateCondition(step.condition, lastOutput)) {
        logger.debug(TAG, `步骤跳过: step=${step.stepName}, 前置条件不满足`);
        stepResults.push(new NGFWorkflowStepResult(step.stepName, step.actionType, true, '', true));
        continue;
      }

      logger.debug(TAG, `执行步骤: step=${step.stepName}, type=${step.actionType}`);
      const actionResult: NGFActionResult = await ngfActionExecutorFacade.executeAction(
        step.actionType,
        step.actionJson,
        lastOutput
      );

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
