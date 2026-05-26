import { ITaskManager, NGFTaskInfo, NGFTaskState, NGFTaskExecutor } from '../contracts/ITaskManager';
import { ngfSystemNotificationManager } from './SystemNotificationManagerFacade';
import { ngfBackgroundTaskManager } from './BackgroundTaskManagerFacade';
import { NGFNotificationRequest, NGFNotificationType } from '../contracts/ISystemNotificationManager';
import { logger } from '../../utils/Logger';
import { ngfStarterKernel } from '../../core/starter/StarterKernel';
import { NGFEventPayload } from '../../core/contracts/IEventBus';

const TAG: string = 'TaskManagerFacade';
const STORAGE_KEY: string = 'ngf_tasks_map';

class TaskManagerFacade implements ITaskManager {
  private tasks: Map<string, NGFTaskInfo> = new Map();
  private notificationIdCounter: number = 20000;

  constructor() {
    AppStorage.setOrCreate(STORAGE_KEY, new Map<string, NGFTaskInfo>());
  }

  async submitTask(name: string, executor: NGFTaskExecutor): Promise<string> {
    const taskId = `task_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    const taskInfo = new NGFTaskInfo(
      taskId,
      name,
      NGFTaskState.PENDING,
      0,
      0,
      '等待执行',
      Date.now()
    );
    this.tasks.set(taskId, taskInfo);
    this.syncStorage();

    // 申请通知权限
    await ngfSystemNotificationManager.requestPermission();

    // 申请后台常驻（针对任务）
    await ngfBackgroundTaskManager.startContinuousTask(taskId, 'NGF 后台任务', '正在运行后台任务');

    // 发布初始通知
    const notifId = this.getNextNotificationId();
    await this.updateNotification(notifId, taskInfo);

    // 异步执行任务，不阻塞 submitTask 返回
    this.executeTask(taskId, executor, notifId);

    return taskId;
  }

  getTask(taskId: string): NGFTaskInfo | null {
    return this.tasks.get(taskId) || null;
  }

  getAllTasks(): Array<NGFTaskInfo> {
    return Array.from(this.tasks.values());
  }

  private async executeTask(taskId: string, executor: NGFTaskExecutor, notifId: number): Promise<void> {
    const taskInfo = this.tasks.get(taskId);
    if (!taskInfo) {
      return;
    }

    try {
      taskInfo.state = NGFTaskState.RUNNING;
      taskInfo.message = '任务已启动';
      this.syncStorage();
      this.publishEvent('ngf.task.started', taskInfo);
      await this.updateNotification(notifId, taskInfo);

      // 执行开发者提供的任务逻辑
      await executor(taskId, (progress: number, total: number, message: string) => {
        taskInfo.progress = progress;
        taskInfo.total = total;
        taskInfo.message = message;
        this.syncStorage();
        this.publishEvent('ngf.task.progress', taskInfo);
        // 此处不需要 await，避免阻塞执行进度
        void this.updateNotification(notifId, taskInfo);
      });

      taskInfo.state = NGFTaskState.COMPLETED;
      taskInfo.message = '任务已完成';
      this.syncStorage();
      this.publishEvent('ngf.task.completed', taskInfo);
      await this.updateNotification(notifId, taskInfo);

    } catch (e) {
      taskInfo.state = NGFTaskState.FAILED;
      taskInfo.message = `任务异常: ${e}`;
      this.syncStorage();
      this.publishEvent('ngf.task.failed', taskInfo);
      await this.updateNotification(notifId, taskInfo);
      logger.error(TAG, `任务执行异常: TaskID=${taskId}, Error=${e}`);
    } finally {
      void this.checkStopBackground();
    }
  }

  private publishEvent(eventName: string, taskInfo: NGFTaskInfo): void {
    const payload = new NGFEventPayload(eventName, JSON.stringify(taskInfo), Date.now());
    ngfStarterKernel.eventBus.publish(eventName, payload);
  }

  private async updateNotification(notifId: number, taskInfo: NGFTaskInfo): Promise<void> {
    const isOngoing = taskInfo.state === NGFTaskState.RUNNING || taskInfo.state === NGFTaskState.PENDING;
    const request = new NGFNotificationRequest(
      notifId,
      taskInfo.name,
      taskInfo.message,
      NGFNotificationType.PROGRESS,
      taskInfo.progress,
      taskInfo.total,
      isOngoing
    );
    await ngfSystemNotificationManager.publish(request);
  }

  private syncStorage(): void {
    // 拷贝 Map 触发 ArkUI 的更新机制
    AppStorage.setOrCreate(STORAGE_KEY, new Map(this.tasks));
  }

  private getNextNotificationId(): number {
    this.notificationIdCounter += 1;
    return this.notificationIdCounter;
  }

  private async checkStopBackground(): Promise<void> {
    const runningTasks = this.getAllTasks().filter((t: NGFTaskInfo) => { return t.state === NGFTaskState.RUNNING; });
    if (runningTasks.length === 0) {
      await ngfBackgroundTaskManager.stopContinuousTask();
    }
  }
}

export const ngfTaskManager: ITaskManager = new TaskManagerFacade();
