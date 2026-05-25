export enum NGFTaskState {
  PENDING = 'PENDING',
  RUNNING = 'RUNNING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED'
}

export class NGFTaskInfo {
  taskId: string;
  name: string;
  state: NGFTaskState;
  progress: number;
  total: number;
  message: string;
  createdAt: number;
  
  constructor(taskId: string, name: string, state: NGFTaskState, progress: number, total: number, message: string, createdAt: number) {
    this.taskId = taskId;
    this.name = name;
    this.state = state;
    this.progress = progress;
    this.total = total;
    this.message = message;
    this.createdAt = createdAt;
  }
}

export type NGFTaskExecutor = (taskId: string, updateCallback: (progress: number, total: number, message: string) => void) => Promise<void>;

export interface ITaskManager {
  submitTask(name: string, executor: NGFTaskExecutor): Promise<string>;
  getTask(taskId: string): NGFTaskInfo | null;
  getAllTasks(): Array<NGFTaskInfo>;
}
