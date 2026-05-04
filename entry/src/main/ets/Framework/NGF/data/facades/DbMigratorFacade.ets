import { logger } from '../../utils/Logger';
import { IDbMigrator, INGFMigrationStep } from '../contracts/IDbMigrator';

const TAG = 'NGFDbMigratorFacade';

export class DbMigratorFacade implements IDbMigrator {
  private readonly schemaVersionKey: string = 'ngf_data_schema_version';
  private readonly baselineVersion: number = 1;
  private readonly fallbackTargetVersion: number = 1;
  private readonly migrationSteps: Array<INGFMigrationStep> = [];

  currentVersion(): number {
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
      AppStorage.setOrCreate(this.schemaVersionKey, toVersion);
      logger.info(TAG, `数据 schema 已回滚到: v${toVersion}`);
      return true;
    } catch {
      logger.warn(TAG, `数据 schema 回滚失败: v${toVersion}`);
      return false;
    }
  }
}

export const ngfDbMigratorFacade = new DbMigratorFacade();
