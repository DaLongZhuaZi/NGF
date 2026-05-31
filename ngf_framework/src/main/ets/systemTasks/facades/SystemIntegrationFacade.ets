import { NGFEventPayload, NGFEventListener } from '../../core/contracts/IEventBus';
import { ISystemIntegration, NGFTaskEventListener } from '../contracts/ISystemIntegration';
import { ITaskManager, NGFTaskExecutor, NGFTaskInfo } from '../contracts/ITaskManager';
import { ngfTaskManager } from './TaskManagerFacade';
import { ngfStarterKernel } from '../../core/starter/StarterKernel';
import { logger } from '../../utils/Logger';

const TAG: string = 'SystemIntegrationFacade';

class SystemIntegrationFacade implements ISystemIntegration {
  private taskManager: ITaskManager;

  constructor(taskManager: ITaskManager) {
    this.taskManager = taskManager;
    // 自动监听 ACTION: SUBMIT_TASK
    this.subscribeSystemEvent('ngf.intent.action.SUBMIT_TASK', 'SysIntegration_AutoSubmit', (payload: NGFEventPayload) => {
      this.handleActionSubmitTask(payload);
    });
  }

  submitTask(name: string, executor: NGFTaskExecutor): Promise<string> {
    logger.info(TAG, `提交任务 (统一入口): ${name}`);
    return this.taskManager.submitTask(name, executor);
  }

  getTask(taskId: string): NGFTaskInfo | null {
    return this.taskManager.getTask(taskId);
  }

  getAllTasks(): Array<NGFTaskInfo> {
    return this.taskManager.getAllTasks();
  }

  onTaskProgress(listenerId: string, listener: NGFTaskEventListener): boolean {
    return this.subscribeTaskEvent('ngf.task.progress', listenerId, listener);
  }

  onTaskCompleted(listenerId: string, listener: NGFTaskEventListener): boolean {
    return this.subscribeTaskEvent('ngf.task.completed', listenerId, listener);
  }

  onTaskFailed(listenerId: string, listener: NGFTaskEventListener): boolean {
    return this.subscribeTaskEvent('ngf.task.failed', listenerId, listener);
  }

  removeTaskListener(eventName: string, listenerId: string): boolean {
    return this.unsubscribeSystemEvent(eventName, listenerId);
  }

  publishSystemEvent(eventName: string, payload: NGFEventPayload): void {
    logger.info(TAG, `发布基础事件: ${eventName}`);
    ngfStarterKernel.eventBus.publish(eventName, payload);
  }

  subscribeSystemEvent(eventName: string, listenerId: string, listener: NGFEventListener): boolean {
    logger.info(TAG, `订阅基础事件: ${eventName} (ID: ${listenerId})`);
    return ngfStarterKernel.eventBus.subscribe(eventName, listenerId, listener);
  }

  unsubscribeSystemEvent(eventName: string, listenerId: string): boolean {
    logger.info(TAG, `取消订阅基础事件: ${eventName} (ID: ${listenerId})`);
    return ngfStarterKernel.eventBus.unsubscribe(eventName, listenerId);
  }

  publishNotification(request: import('../contracts/ISystemNotificationManager').NGFNotificationRequest): Promise<void> {
    return import('./SystemNotificationManagerFacade').then(module => {
      return module.ngfSystemNotificationManager.publish(request);
    });
  }

  private subscribeTaskEvent(eventName: string, listenerId: string, listener: NGFTaskEventListener): boolean {
    const rawListener: NGFEventListener = (payload: NGFEventPayload) => {
      try {
        const taskInfo = JSON.parse(payload.payloadJson) as NGFTaskInfo;
        listener(taskInfo);
      } catch (e) {
        logger.error(TAG, `解析任务事件 payload 失败: ${e}`);
      }
    };
    return this.subscribeSystemEvent(eventName, listenerId, rawListener);
  }

  private handleActionSubmitTask(payload: NGFEventPayload): void {
    // 解析附带的参数并自动派发任务
    try {
      // 这里的实现依赖于业务方约定的格式，为了简便，假设载荷包含 name
      const actionData = JSON.parse(payload.payloadJson) as Record<string, string>;
      const name = actionData['name'] || 'EventTriggeredTask';
      
      // 注意：通过事件直接派发，一般需要有默认的 Executor，或者通过容器获取
      // 此处我们提供一个通用模拟 Executor 以验证流程
      const dummyExecutor: NGFTaskExecutor = async (taskId: string, updateCallback: (progress: number, total: number, message: string) => void) => {
        updateCallback(0, 100, '事件触发任务启动...');
        for (let i = 1; i <= 10; i++) {
          await new Promise<void>(resolve => setTimeout(resolve, 300));
          updateCallback(i * 10, 100, `事件触发任务运行中 (${i * 10}%)`);
        }
        updateCallback(100, 100, '事件触发任务完成');
      };

      void this.submitTask(name, dummyExecutor);
    } catch (e) {
      logger.error(TAG, `处理自动派发任务事件失败: ${e}`);
    }
  }
}

export const ngfSystem: ISystemIntegration = new SystemIntegrationFacade(ngfTaskManager);
