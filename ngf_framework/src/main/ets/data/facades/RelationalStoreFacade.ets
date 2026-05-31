import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { logger } from '../../utils/Logger';

const TAG: string = 'NGFRelationalStoreFacade';

export class RelationalStoreFacade {
  private rdbStore: relationalStore.RdbStore | null = null;
  private initialized: boolean = false;

  async initialize(context?: common.UIAbilityContext, storeConfig?: relationalStore.StoreConfig): Promise<void> {
    if (!context || !storeConfig) {
      logger.debug(TAG, '缺少参数，暂缓初始化');
      return;
    }
    if (this.initialized) {
      logger.debug(TAG, '已初始化，跳过');
      return;
    }
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, storeConfig);
      this.initialized = true;
      logger.info(TAG, `RDB 初始化完成: name=${storeConfig.name}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `RDB 初始化失败: ${message}`);
    }
  }

  getRdbStore(): relationalStore.RdbStore | null {
    return this.rdbStore;
  }

  isInitialized(): boolean {
    return this.initialized;
  }

  executeSql(sql: string, args?: Array<relationalStore.ValueType>): void {
    const store = this.rdbStore;
    if (store === null) {
      logger.warn(TAG, `executeSql 失败: RDB 未初始化, sql=${sql}`);
      return;
    }
    try {
      if (args !== undefined && args.length > 0) {
        store.executeSql(sql, args);
      } else {
        store.executeSql(sql);
      }
      logger.debug(TAG, `executeSql 成功: sql=${sql}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `executeSql 异常: sql=${sql}, error=${message}`);
      throw new Error(`executeSql failed: ${message}`);
    }
  }

  query(predicates: relationalStore.RdbPredicates, columns: Array<string>): relationalStore.ResultSet {
    const store = this.rdbStore;
    if (store === null) {
      logger.warn(TAG, 'query 失败: RDB 未初始化');
      throw new Error('RDB not initialized');
    }
    try {
      const resultSet = store.querySync(predicates, columns);
      logger.debug(TAG, `query 成功: columns=${columns.length}`);
      return resultSet;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `query 异常: error=${message}`);
      throw new Error(`query failed: ${message}`);
    }
  }

  insert(table: string, values: relationalStore.ValuesBucket): number {
    const store = this.rdbStore;
    if (store === null) {
      logger.warn(TAG, `insert 失败: RDB 未初始化, table=${table}`);
      return -1;
    }
    try {
      const rowId = store.insertSync(table, values);
      logger.debug(TAG, `insert 成功: table=${table}, rowId=${rowId}`);
      return rowId;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `insert 异常: table=${table}, error=${message}`);
      return -1;
    }
  }

  update(values: relationalStore.ValuesBucket, predicates: relationalStore.RdbPredicates): number {
    const store = this.rdbStore;
    if (store === null) {
      logger.warn(TAG, 'update 失败: RDB 未初始化');
      return -1;
    }
    try {
      const changedRows = store.updateSync(values, predicates);
      logger.debug(TAG, `update 成功: changedRows=${changedRows}`);
      return changedRows;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `update 异常: error=${message}`);
      return -1;
    }
  }

  delete(predicates: relationalStore.RdbPredicates): number {
    const store = this.rdbStore;
    if (store === null) {
      logger.warn(TAG, 'delete 失败: RDB 未初始化');
      return -1;
    }
    try {
      const deletedRows = store.deleteSync(predicates);
      logger.debug(TAG, `delete 成功: deletedRows=${deletedRows}`);
      return deletedRows;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `delete 异常: error=${message}`);
      return -1;
    }
  }
}

export const ngfRelationalStoreFacade: RelationalStoreFacade = new RelationalStoreFacade();
