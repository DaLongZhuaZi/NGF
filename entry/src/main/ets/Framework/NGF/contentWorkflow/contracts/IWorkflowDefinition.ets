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
  /** 步骤超时时间（毫秒），null 表示不限制 */
  readonly timeoutMs: number | null;

  constructor(
    stepName: string,
    actionType: string,
    actionJson: string,
    condition: NGFWorkflowStepCondition | null = null,
    timeoutMs: number | null = null
  ) {
    this.stepName = stepName;
    this.actionType = actionType;
    this.actionJson = actionJson;
    this.condition = condition;
    this.timeoutMs = timeoutMs;
  }
}

/**
 * 并行步骤组 — 组内步骤并发执行，全部完成后继续
 */
export class NGFWorkflowParallelGroup {
  readonly groupName: string;
  readonly steps: Array<NGFWorkflowStepDefinition>;
  /** 并行组超时时间（毫秒），null 表示不限制 */
  readonly timeoutMs: number | null;

  constructor(
    groupName: string,
    steps: Array<NGFWorkflowStepDefinition>,
    timeoutMs: number | null = null
  ) {
    this.groupName = groupName;
    this.steps = steps;
    this.timeoutMs = timeoutMs;
  }
}

/**
 * 工作流定义
 */
export class NGFWorkflowDefinition {
  readonly workflowName: string;
  readonly description: string;
  readonly steps: Array<NGFWorkflowStepDefinition>;
  /** 并行组列表（可选） */
  readonly parallelGroups: Array<NGFWorkflowParallelGroup>;

  constructor(
    workflowName: string,
    description: string,
    steps: Array<NGFWorkflowStepDefinition>,
    parallelGroups: Array<NGFWorkflowParallelGroup> = []
  ) {
    this.workflowName = workflowName;
    this.description = description;
    this.steps = steps;
    this.parallelGroups = parallelGroups;
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
