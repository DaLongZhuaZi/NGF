import { logger } from '../../utils/Logger';
import { SettingsManager } from '../../data/SettingsManager';
import { IWorkflowPersistence, NGFWorkflowPersistedState } from '../contracts/IWorkflowPersistence';

const TAG: string = 'NGFWorkflowPersistenceFacade';
const KEY_PREFIX: string = 'wf_state_';

export class WorkflowPersistenceFacade implements IWorkflowPersistence {
  private readonly cache: Map<string, NGFWorkflowPersistedState> = new Map<string, NGFWorkflowPersistedState>();

  saveState(state: NGFWorkflowPersistedState): void {
    const key = KEY_PREFIX + state.workflowName;
    const json = this.serializeState(state);
    this.cache.set(state.workflowName, state);
    void SettingsManager.getInstance().setString(key, json);
    logger.info(TAG, `保存工作流状态: name=${state.workflowName}, step=${state.currentStepIndex}`);
  }

  loadState(workflowName: string): NGFWorkflowPersistedState | null {
    const cached = this.cache.get(workflowName);
    if (cached !== undefined) {
      return cached;
    }

    const key = KEY_PREFIX + workflowName;
    const json = SettingsManager.getInstance().getString(key, '');
    if (json.length <= 0) {
      return null;
    }

    const state = this.deserializeState(workflowName, json);
    if (state !== null) {
      this.cache.set(workflowName, state);
    }
    return state;
  }

  removeState(workflowName: string): boolean {
    const key = KEY_PREFIX + workflowName;
    const existed = this.cache.has(workflowName);
    this.cache.delete(workflowName);
    void SettingsManager.getInstance().setString(key, '');
    logger.info(TAG, `移除工作流状态: name=${workflowName}, existed=${existed}`);
    return existed;
  }

  listSavedNames(): Array<string> {
    const names: Array<string> = [];
    const keys = this.cache.keys();
    for (const key of keys) {
      names.push(key);
    }
    logger.debug(TAG, `列出已保存工作流: count=${names.length}`);
    return names;
  }

  clearAll(): void {
    const keys = this.cache.keys();
    for (const key of keys) {
      const settingsKey = KEY_PREFIX + key;
      void SettingsManager.getInstance().setString(settingsKey, '');
    }
    this.cache.clear();
    logger.info(TAG, '清除所有工作流状态');
  }

  private serializeState(state: NGFWorkflowPersistedState): string {
    const wrapper: Record<string, string | number> = {};
    wrapper['currentStepIndex'] = state.currentStepIndex;
    wrapper['contextJson'] = state.contextJson;
    wrapper['stepResultsJson'] = state.stepResultsJson;
    wrapper['savedAt'] = state.savedAt;
    return JSON.stringify(wrapper);
  }

  private deserializeState(workflowName: string, json: string): NGFWorkflowPersistedState | null {
    try {
      const wrapper = JSON.parse(json) as Record<string, string | number>;
      const entries = Object.entries(wrapper) as [string, string | number][];
      let currentStepIndex: number = 0;
      let contextJson: string = '';
      let stepResultsJson: string = '';
      let savedAt: number = 0;
      for (let index = 0; index < entries.length; index++) {
        const pair = entries[index];
        if (pair[0] === 'currentStepIndex') {
          currentStepIndex = Number(pair[1]);
        } else if (pair[0] === 'contextJson') {
          contextJson = String(pair[1]);
        } else if (pair[0] === 'stepResultsJson') {
          stepResultsJson = String(pair[1]);
        } else if (pair[0] === 'savedAt') {
          savedAt = Number(pair[1]);
        }
      }
      return new NGFWorkflowPersistedState(workflowName, currentStepIndex, contextJson, stepResultsJson, savedAt);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `反序列化工作流状态失败: name=${workflowName}, error=${message}`);
      return null;
    }
  }
}

export const ngfWorkflowPersistenceFacade: WorkflowPersistenceFacade = new WorkflowPersistenceFacade();
