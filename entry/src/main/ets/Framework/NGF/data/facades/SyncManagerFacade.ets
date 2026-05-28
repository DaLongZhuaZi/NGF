import { logger } from '../../utils/Logger';
import {
  ISyncDataHandler,
  ISyncManager,
  NGFConflictStrategy,
  NGFSyncQueueItem,
  NGFSyncResult
} from '../contracts/ISyncManager';

const TAG: string = 'NGFSyncManagerFacade';
const MAX_RETRY_COUNT: number = 3;

export class SyncManagerFacade implements ISyncManager {
  private readonly queue: Array<NGFSyncQueueItem> = [];
  private conflictStrategy: NGFConflictStrategy = NGFConflictStrategy.CLIENT_WINS;
  private syncHandler: ISyncDataHandler | null = null;

  private async tryResolveConflict(
    handler: ISyncDataHandler,
    item: NGFSyncQueueItem,
    conflicts: Array<NGFSyncQueueItem>,
    syncedCountRef: Array<number>
  ): Promise<void> {
    if (this.conflictStrategy === NGFConflictStrategy.MANUAL) {
      conflicts.push(item);
      logger.info(TAG, `冲突(手动解决): entity=${item.entityName}, id=${item.entityId}`);
      return;
    }

    try {
      const remoteData = await handler.pull(item.entityName, item.createdAt);
      const resolved = await handler.resolveConflict(item, remoteData, this.conflictStrategy);
      const resolvedItem = new NGFSyncQueueItem(
        `resolved_${item.id}`,
        item.entityName,
        item.entityId,
        item.operation,
        resolved,
        item.createdAt,
        0
      );
      const rePushOk = await handler.push(resolvedItem);
      if (rePushOk) {
        syncedCountRef[0]++;
        logger.info(TAG, `冲突已解决(${this.conflictStrategy}): entity=${item.entityName}, id=${item.entityId}`);
      } else {
        conflicts.push(item);
        logger.warn(TAG, `冲突解决后推送仍失败: entity=${item.entityName}, id=${item.entityId}`);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `冲突解决异常: entity=${item.entityName}, id=${item.entityId}, error=${message}`);
      conflicts.push(item);
    }
  }

  enqueue(item: NGFSyncQueueItem): void {
    this.queue.push(item);
    logger.debug(TAG, `入队: entity=${item.entityName}, op=${item.operation}, queueSize=${this.queue.length}`);
  }

  async flush(): Promise<NGFSyncResult> {
    const handler = this.syncHandler;
    if (handler === null) {
      logger.warn(TAG, 'flush 失败: syncHandler 未设置');
      return new NGFSyncResult(false, 0, 0, []);
    }

    let syncedCount: number = 0;
    let failedCount: number = 0;
    const conflicts: Array<NGFSyncQueueItem> = [];
    const processed: Array<string> = [];
    const syncedCountRef: Array<number> = [syncedCount];

    for (let index = 0; index < this.queue.length; index++) {
      const item = this.queue[index];
      try {
        const success = await handler.push(item);
        if (success) {
          processed.push(item.id);
          syncedCountRef[0]++;
        } else {
          item.retryCount++;
          if (item.retryCount >= MAX_RETRY_COUNT) {
            processed.push(item.id);
            await this.tryResolveConflict(handler, item, conflicts, syncedCountRef);
          }
          failedCount++;
        }
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        logger.error(TAG, `同步项失败: id=${item.id}, error=${message}`);
        item.retryCount++;
        if (item.retryCount >= MAX_RETRY_COUNT) {
          processed.push(item.id);
          await this.tryResolveConflict(handler, item, conflicts, syncedCountRef);
        }
        failedCount++;
      }
    }

    syncedCount = syncedCountRef[0];

    for (let index = this.queue.length - 1; index >= 0; index--) {
      const itemId = this.queue[index].id;
      let shouldRemove: boolean = false;
      for (let j = 0; j < processed.length; j++) {
        if (processed[j] === itemId) {
          shouldRemove = true;
          break;
        }
      }
      if (shouldRemove) {
        this.queue.splice(index, 1);
      }
    }

    const allSuccess = failedCount === 0;
    logger.info(TAG, `同步完成: synced=${syncedCount}, failed=${failedCount}, conflicts=${conflicts.length}, remaining=${this.queue.length}`);
    return new NGFSyncResult(allSuccess, syncedCount, failedCount, conflicts);
  }

  queueSize(): number {
    return this.queue.length;
  }

  clearQueue(): void {
    this.queue.length = 0;
    logger.info(TAG, '清空同步队列');
  }

  setConflictStrategy(strategy: NGFConflictStrategy): void {
    this.conflictStrategy = strategy;
    logger.info(TAG, `设置冲突策略: ${strategy}`);
  }

  getConflictStrategy(): NGFConflictStrategy {
    return this.conflictStrategy;
  }

  setSyncHandler(handler: ISyncDataHandler): void {
    this.syncHandler = handler;
    logger.info(TAG, '设置同步数据处理器');
  }
}

export const ngfSyncManagerFacade: SyncManagerFacade = new SyncManagerFacade();
