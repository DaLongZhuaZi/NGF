/**
 * 同步操作类型
 */
export enum NGFSyncOperation {
  CREATE = 'create',
  UPDATE = 'update',
  DELETE = 'delete'
}

/**
 * 同步冲突策略
 */
export enum NGFConflictStrategy {
  CLIENT_WINS = 'client_wins',
  SERVER_WINS = 'server_wins',
  MANUAL = 'manual'
}

/**
 * 同步队列项
 */
export class NGFSyncQueueItem {
  readonly id: string;
  readonly entityName: string;
  readonly entityId: string;
  readonly operation: NGFSyncOperation;
  readonly payload: string;
  readonly createdAt: number;
  retryCount: number;

  constructor(
    id: string,
    entityName: string,
    entityId: string,
    operation: NGFSyncOperation,
    payload: string,
    createdAt: number,
    retryCount: number = 0
  ) {
    this.id = id;
    this.entityName = entityName;
    this.entityId = entityId;
    this.operation = operation;
    this.payload = payload;
    this.createdAt = createdAt;
    this.retryCount = retryCount;
  }
}

/**
 * 同步结果
 */
export class NGFSyncResult {
  readonly success: boolean;
  readonly syncedCount: number;
  readonly failedCount: number;
  readonly conflicts: Array<NGFSyncQueueItem>;

  constructor(success: boolean, syncedCount: number, failedCount: number, conflicts: Array<NGFSyncQueueItem>) {
    this.success = success;
    this.syncedCount = syncedCount;
    this.failedCount = failedCount;
    this.conflicts = conflicts;
  }
}

/**
 * 同步数据处理器接口
 */
export interface ISyncDataHandler {
  push(item: NGFSyncQueueItem): Promise<boolean>;
  pull(entityName: string, sinceTimestamp: number): Promise<string>;
  resolveConflict(local: NGFSyncQueueItem, remote: string, strategy: NGFConflictStrategy): Promise<string>;
}

/**
 * 同步管理器接口
 */
export interface ISyncManager {
  enqueue(item: NGFSyncQueueItem): void;
  flush(): Promise<NGFSyncResult>;
  queueSize(): number;
  clearQueue(): void;
  setConflictStrategy(strategy: NGFConflictStrategy): void;
  getConflictStrategy(): NGFConflictStrategy;
  setSyncHandler(handler: ISyncDataHandler): void;
}
