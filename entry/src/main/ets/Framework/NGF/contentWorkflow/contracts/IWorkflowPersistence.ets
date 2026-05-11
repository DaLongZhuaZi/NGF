/**
 * 工作流持久化状态
 */
export class NGFWorkflowPersistedState {
  readonly workflowName: string;
  readonly currentStepIndex: number;
  readonly contextJson: string;
  readonly stepResultsJson: string;
  readonly savedAt: number;

  constructor(
    workflowName: string,
    currentStepIndex: number,
    contextJson: string,
    stepResultsJson: string,
    savedAt: number
  ) {
    this.workflowName = workflowName;
    this.currentStepIndex = currentStepIndex;
    this.contextJson = contextJson;
    this.stepResultsJson = stepResultsJson;
    this.savedAt = savedAt;
  }
}

/**
 * 工作流持久化管理接口
 */
export interface IWorkflowPersistence {
  saveState(state: NGFWorkflowPersistedState): void;
  loadState(workflowName: string): NGFWorkflowPersistedState | null;
  removeState(workflowName: string): boolean;
  listSavedNames(): Array<string>;
  clearAll(): void;
}
