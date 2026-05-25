import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { wantAgent, WantAgent } from '@kit.AbilityKit';
import { IBackgroundTaskManager } from '../contracts/IBackgroundTaskManager';
import { uiContextManager } from '../../platformOhos/UIContextManager';
import { logger } from '../../utils/Logger';

const TAG: string = 'BackgroundTaskManagerFacade';

class BackgroundTaskManagerFacade implements IBackgroundTaskManager {
  async startContinuousTask(taskId: string, title: string, content: string): Promise<boolean> {
    const context = uiContextManager.getFullAbilityContext();
    if (!context) {
      logger.error(TAG, '无 UIAbilityContext，无法启动后台长时任务');
      return false;
    }
    try {
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: context.abilityInfo.bundleName,
            abilityName: context.abilityInfo.name
          }
        ],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      };
      const wa: WantAgent = await wantAgent.getWantAgent(wantAgentInfo);
      
      await backgroundTaskManager.startBackgroundRunning(context, backgroundTaskManager.BackgroundMode.DATA_TRANSFER, wa);
      logger.info(TAG, `后台长时任务已启动: TaskID=${taskId}`);
      return true;
    } catch (e) {
      logger.error(TAG, `启动后台长时任务失败: ${e}`);
      return false;
    }
  }

  async stopContinuousTask(): Promise<boolean> {
    const context = uiContextManager.getFullAbilityContext();
    if (!context) {
      logger.error(TAG, '无 UIAbilityContext，无法停止后台长时任务');
      return false;
    }
    try {
      await backgroundTaskManager.stopBackgroundRunning(context);
      logger.info(TAG, '后台长时任务已停止');
      return true;
    } catch (e) {
      logger.error(TAG, `停止后台长时任务失败: ${e}`);
      return false;
    }
  }
}

export const ngfBackgroundTaskManager: IBackgroundTaskManager = new BackgroundTaskManagerFacade();
