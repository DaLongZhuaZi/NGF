import { relationalStore } from '@kit.ArkData';
import { logger } from '../../utils/Logger';
import { IDbMigrator, INGFMigrationStep } from '../contracts/IDbMigrator';

const TAG = 'NGFDbMigratorFacade';
const VERSION_TABLE: string = 'ngf_schema_version';
const VERSION_KEY: string = 'current_version';

export class DbMigratorFacade implements IDbMigrator {
  private readonly schemaVersionKey: string = 'ngf_data_schema_version';
  private readonly baselineVersion: number = 1;
  private readonly fallbackTargetVersion: number = 1;
  private readonly migrationSteps: Array<INGFMigrationStep> = [];
  private rdbStore: relationalStore.RdbStore | null = null;

  initialize(rdbStore?: relationalStore.RdbStore): void {
    if (!rdbStore) {
      return;
    }
    this.rdbStore = rdbStore;
    this.ensureVersionTable();
    logger.info(TAG, 'DbMigrator RDB 初始化完成');
  }

  currentVersion(): number {
    const rdbVersion = this.readVersionFromRdb();
    if (rdbVersion > 0) {
      return rdbVersion;
    }
    const version = AppStorage.get<number>(this.schemaVersionKey);
    if (version && version > 0) {
      return version;
    }
    return this.baselineVersion;
  }

  targetVersion(): number {
    if (this.migrationSteps.length > 0) {
      let maxVersion: number = 0;
      for (let i = 0; i < this.migrationSteps.length; i++) {
        if (this.migrationSteps[i].targetVersion > maxVersion) {
          maxVersion = this.migrationSteps[i].targetVersion;
        }
      }
      return maxVersion;
    }
    return this.fallbackTargetVersion;
  }

  registerStep(step: INGFMigrationStep): void {
    this.migrationSteps.push(step);
    this.migrationSteps.sort((a: INGFMigrationStep, b: INGFMigrationStep) => {
      return a.targetVersion - b.targetVersion;
    });
    logger.info(TAG, `注册迁移步骤: v${step.targetVersion}, desc=${step.description}`);
  }

  async migrate(): Promise<boolean> {
    const current = this.currentVersion();
    const target = this.targetVersion();

    if (this.migrationSteps.length === 0) {
      try {
        this.writeVersionToRdb(target);
        AppStorage.setOrCreate(this.schemaVersionKey, target);
        logger.info(TAG, `数据 schema 迁移完成: v${current} -> v${target}`);
        return true;
      } catch {
        logger.warn(TAG, '数据 schema 迁移失败');
        return false;
      }
    }

    let executedCount: number = 0;
    for (let i = 0; i < this.migrationSteps.length; i++) {
      const step = this.migrationSteps[i];
      if (step.targetVersion <= current) {
        continue;
      }
      logger.info(TAG, `执行迁移步骤: v${step.targetVersion}, desc=${step.description}`);
      const success = await step.execute();
      if (!success) {
        logger.warn(TAG, `迁移步骤失败: v${step.targetVersion}, 已完成=${executedCount}`);
        return false;
      }
      this.writeVersionToRdb(step.targetVersion);
      AppStorage.setOrCreate(this.schemaVersionKey, step.targetVersion);
      executedCount++;
    }
    logger.info(TAG, `数据 schema 迁移完成: v${current} -> v${target}, 执行步骤=${executedCount}`);
    return true;
  }

  async rollback(toVersion: number): Promise<boolean> {
    if (toVersion <= 0) {
      logger.warn(TAG, `回滚版本非法: ${toVersion}`);
      return false;
    }

    try {
      this.writeVersionToRdb(toVersion);
      AppStorage.setOrCreate(this.schemaVersionKey, toVersion);
      logger.info(TAG, `数据 schema 已回滚到: v${toVersion}`);
      return true;
    } catch {
      logger.warn(TAG, `数据 schema 回滚失败: v${toVersion}`);
      return false;
    }
  }

  private ensureVersionTable(): void {
    const store = this.rdbStore;
    if (store === null) {
      return;
    }
    try {
      store.executeSql(`CREATE TABLE IF NOT EXISTS ${VERSION_TABLE} (key TEXT PRIMARY KEY, value INTEGER)`);
      logger.debug(TAG, '版本表已就绪');
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `创建版本表失败: ${message}`);
    }
  }

  private readVersionFromRdb(): number {
    const store = this.rdbStore;
    if (store === null) {
      return 0;
    }
    try {
      const predicates = new relationalStore.RdbPredicates(VERSION_TABLE);
      predicates.equalTo('key', VERSION_KEY);
      const resultSet = store.querySync(predicates, ['value']);
      if (resultSet.goToFirstRow()) {
        const version = resultSet.getLong(resultSet.getColumnIndex('value'));
        resultSet.close();
        return version;
      }
      resultSet.close();
      return 0;
    } catch {
      return 0;
    }
  }

  private writeVersionToRdb(version: number): void {
    const store = this.rdbStore;
    if (store === null) {
      return;
    }
    try {
      store.executeSql(
        `INSERT OR REPLACE INTO ${VERSION_TABLE} (key, value) VALUES (?, ?)`,
        [VERSION_KEY, version]
      );
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `写入版本号失败: ${message}`);
    }
  }
}

export const ngfDbMigratorFacade = new DbMigratorFacade();
