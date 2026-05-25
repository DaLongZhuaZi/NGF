export { ITaskManager, NGFTaskExecutor, NGFTaskInfo, NGFTaskState } from './contracts/ITaskManager';
export { ISystemIntegration, NGFTaskEventListener } from './contracts/ISystemIntegration';
export { ISystemNotificationManager, NGFNotificationRequest } from './contracts/ISystemNotificationManager';
export { IBackgroundTaskManager } from './contracts/IBackgroundTaskManager';

export { ngfTaskManager } from './facades/TaskManagerFacade';
export { ngfSystemNotificationManager } from './facades/SystemNotificationManagerFacade';
export { ngfBackgroundTaskManager } from './facades/BackgroundTaskManagerFacade';
export { ngfSystem } from './facades/SystemIntegrationFacade';
