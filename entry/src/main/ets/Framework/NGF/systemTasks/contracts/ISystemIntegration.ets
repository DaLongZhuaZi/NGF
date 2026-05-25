import { NGFEventPayload, NGFEventListener } from '../../core/contracts/IEventBus';
import { NGFTaskExecutor, NGFTaskInfo } from './ITaskManager';

export type NGFTaskEventListener = (taskInfo: NGFTaskInfo) => void;

export interface ISystemIntegration {
  /**
   * 提交并调度一个受管后台任务。
   */
  submitTask(name: string, executor: NGFTaskExecutor): Promise<string>;

  /**
   * 获取指定任务的信息。
   */
  getTask(taskId: string): NGFTaskInfo | null;

  /**
   * 获取所有被追踪的任务。
   */
  getAllTasks(): Array<NGFTaskInfo>;

  /**
   * 监听任务进度更新（强类型）。
   */
  onTaskProgress(listenerId: string, listener: NGFTaskEventListener): boolean;

  /**
   * 监听任务完成事件（强类型）。
   */
  onTaskCompleted(listenerId: string, listener: NGFTaskEventListener): boolean;

  /**
   * 监听任务失败事件（强类型）。
   */
  onTaskFailed(listenerId: string, listener: NGFTaskEventListener): boolean;

  /**
   * 移除特定的任务监听器。
   */
  removeTaskListener(eventName: string, listenerId: string): boolean;

  /**
   * 基础底层：发布通用系统事件。
   */
  publishSystemEvent(eventName: string, payload: NGFEventPayload): void;

  /**
   * 基础底层：订阅通用系统事件。
   */
  subscribeSystemEvent(eventName: string, listenerId: string, listener: NGFEventListener): boolean;

  /**
   * 基础底层：取消订阅通用系统事件。
   */
  unsubscribeSystemEvent(eventName: string, listenerId: string): boolean;
}
