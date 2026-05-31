export interface IBackgroundTaskManager {
  startContinuousTask(taskId: string, title: string, content: string): Promise<boolean>;
  stopContinuousTask(): Promise<boolean>;
}
