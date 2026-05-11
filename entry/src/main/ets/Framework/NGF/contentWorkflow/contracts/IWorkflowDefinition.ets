/**
 * 工作流步骤执行结果
 */
export class NGFWorkflowStepResult {
  readonly stepName: string;
  readonly actionType: string;
  readonly success: boolean;
  readonly outputJson: string;
  readonly skipped: boolean;

  constructor(stepName: string, actionType: string, success: boolean, outputJson: string, skipped: boolean) {
    this.stepName = stepName;
    this.actionType = actionType;
    this.success = success;
    this.outputJson = outputJson;
    this.skipped = skipped;
  }
}

/**
 * 工作流执行结果
 */
export class NGFWorkflowExecutionResult {
  readonly workflowName: string;
  readonly success: boolean;
  readonly stepResults: Array<NGFWorkflowStepResult>;
  readonly outputJson: string;

  constructor(workflowName: string, success: boolean, stepResults: Array<NGFWorkflowStepResult>, outputJson: string) {
    this.workflowName = workflowName;
    this.success = success;
    this.stepResults = stepResults;
    this.outputJson = outputJson;
  }
}

/**
 * 工作流步骤条件
 */
export class NGFWorkflowStepCondition {
  readonly field: string;
  readonly operator: string;
  readonly value: string;

  constructor(field: string, operator: string, value: string) {
    this.field = field;
    this.operator = operator;
    this.value = value;
  }
}

/**
 * 工作流步骤定义
 */
export class NGFWorkflowStepDefinition {
  readonly stepName: string;
  readonly actionType: string;
  readonly actionJson: string;
  readonly condition: NGFWorkflowStepCondition | null;

  constructor(
    stepName: string,
    actionType: string,
    actionJson: string,
    condition: NGFWorkflowStepCondition | null = null
  ) {
    this.stepName = stepName;
    this.actionType = actionType;
    this.actionJson = actionJson;
    this.condition = condition;
  }
}

/**
 * 工作流定义
 */
export class NGFWorkflowDefinition {
  readonly workflowName: string;
  readonly description: string;
  readonly steps: Array<NGFWorkflowStepDefinition>;

  constructor(workflowName: string, description: string, steps: Array<NGFWorkflowStepDefinition>) {
    this.workflowName = workflowName;
    this.description = description;
    this.steps = steps;
  }
}

/**
 * 工作流定义管理接口
 */
export interface IWorkflowDefinitionManager {
  registerWorkflow(definition: NGFWorkflowDefinition): void;
  unregisterWorkflow(workflowName: string): boolean;
  getWorkflow(workflowName: string): NGFWorkflowDefinition | null;
  listWorkflowNames(): Array<string>;
  executeWorkflow(workflowName: string, contextJson: string): Promise<NGFWorkflowExecutionResult>;
}
