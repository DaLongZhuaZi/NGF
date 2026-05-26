import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { uiContextManager } from '../../../platformOhos/UIContextManager';
import { IRelationalStore, NGFRdbConfig } from '../contracts/IRelationalStore';
import { logger } from '../../../utils/Logger';

const TAG: string = 'RdbManagerFacade';

class RdbManagerFacade implements IRelationalStore {
  private store: relationalStore.RdbStore | null = null;
  private isInitialized: boolean = false;

  async init(config: NGFRdbConfig, createTableSqls: string[]): Promise<boolean> {
    if (this.isInitialized && this.store) {
      return true;
    }

    const context: common.UIAbilityContext | null = uiContextManager.getFullAbilityContext();
    if (!context) {
      logger.error(TAG, '缺少 UIAbilityContext，无法初始化关系型数据库');
      return false;
    }

    const rdbConfig: relationalStore.StoreConfig = {
      name: config.name,
      securityLevel: config.securityLevel ?? relationalStore.SecurityLevel.S1
    };

    try {
      this.store = await relationalStore.getRdbStore(context, rdbConfig);
      
      // 执行建表语句
      if (this.store.version === 0) {
        for (const sql of createTableSqls) {
          await this.store.executeSql(sql);
          logger.debug(TAG, `执行建表 SQL 成功: ${sql}`);
        }
        this.store.version = 1;
      }
      
      this.isInitialized = true;
      logger.info(TAG, `关系型数据库 ${config.name} 初始化完成`);
      return true;
    } catch (e) {
      logger.error(TAG, `关系型数据库初始化失败: ${e}`);
      return false;
    }
  }

  async executeSql(sql: string, bindArgs?: Array<string | number | boolean>): Promise<void> {
    this.ensureInitialized();
    try {
      if (bindArgs) {
        await this.store!.executeSql(sql, bindArgs as Array<relationalStore.ValueType>);
      } else {
        await this.store!.executeSql(sql);
      }
    } catch (e) {
      logger.error(TAG, `执行 SQL 失败: ${sql} | err: ${e}`);
      throw e as Error;
    }
  }

  async querySql(sql: string, bindArgs?: Array<string | number | boolean>): Promise<Array<Record<string, string | number | boolean>>> {
    this.ensureInitialized();
    try {
      const resultSet = await this.store!.querySql(sql, bindArgs as Array<relationalStore.ValueType>);
      const results: Array<Record<string, string | number | boolean>> = [];

      while (resultSet.goToNextRow()) {
        const row: Record<string, string | number | boolean> = {};
        for (let i = 0; i < resultSet.columnCount; i++) {
          const columnName = resultSet.getColumnName(i);
          const columnType = resultSet.getColumnType(i);
          try {
            row[columnName] = resultSet.getString(i);
          } catch (e) {
            row[columnName] = String(resultSet.getDouble(i));
          }
        }
        results.push(row);
      }
      
      resultSet.close();
      return results;
    } catch (e) {
      logger.error(TAG, `查询 SQL 失败: ${sql} | err: ${e}`);
      throw e as Error;
    }
  }

  async beginTransaction(): Promise<void> {
    this.ensureInitialized();
    try {
      await this.store!.beginTransaction();
    } catch (e) {
      logger.error(TAG, `beginTransaction failed: ${e}`);
      throw e as Error;
    }
  }

  async commit(): Promise<void> {
    this.ensureInitialized();
    try {
      await this.store!.commit();
    } catch (e) {
      logger.error(TAG, `commit failed: ${e}`);
      throw e as Error;
    }
  }

  async rollback(): Promise<void> {
    this.ensureInitialized();
    try {
      await this.store!.rollBack();
    } catch (e) {
      logger.error(TAG, `rollback failed: ${e}`);
      throw e as Error;
    }
  }

  private ensureInitialized() {
    if (!this.isInitialized || !this.store) {
      throw new Error('数据库尚未初始化，请先调用 init()');
    }
  }
}

export const ngfRdbManager: IRelationalStore = new RdbManagerFacade();
