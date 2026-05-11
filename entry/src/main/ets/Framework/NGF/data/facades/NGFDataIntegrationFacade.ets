import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { NGFIntegrationFacadeBase } from '../../core/facades/NGFIntegrationFacadeBase';
import { NGFServiceRegistration } from '../../core/contracts/NGFServiceRegistration';
import { logger } from '../../utils/Logger';
import { SettingsManager } from '../SettingsManager';
import { uiContextManager } from '../../platformOhos/UIContextManager';
import { ngfCacheStoreFacade } from './CacheStoreFacade';
import { ngfDataFacade } from './DataFacade';
import { ngfDbMigratorFacade } from './DbMigratorFacade';
import { ngfRelationalStoreFacade } from './RelationalStoreFacade';
import { ngfSettingsStoreFacade } from './SettingsStoreFacade';
import { ngfStorageProviderFacade } from './StorageProviderFacade';
import { ngfSyncManagerFacade } from './SyncManagerFacade';

const TAG: string = 'NGFDataIntegrationFacade';
const DB_NAME: string = 'ngf_data.db';

export class NGFDataIntegrationFacade extends NGFIntegrationFacadeBase {
  protected readonly tag: string = 'NGFDataIntegrationFacade';
  protected readonly appStorageKey: string = 'ngf_data_integrated';

  protected getServiceRegistrations(): Array<NGFServiceRegistration> {
    const registrations: Array<NGFServiceRegistration> = [];
    registrations.push(new NGFServiceRegistration('ngf.data.data_facade', 'DataFacade', ngfDataFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.data.settings_store', 'SettingsStoreFacade', ngfSettingsStoreFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.data.cache_store', 'CacheStoreFacade', ngfCacheStoreFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.data.storage_provider', 'StorageProviderFacade', ngfStorageProviderFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.data.db_migrator', 'DbMigratorFacade', ngfDbMigratorFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.data.relational_store', 'RelationalStoreFacade', ngfRelationalStoreFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.data.sync_manager', 'SyncManagerFacade', ngfSyncManagerFacade as object));
    return registrations;
  }

  protected onBootstrapped(): void {
    const context = uiContextManager.getFullAbilityContext();
    if (context !== null) {
      void SettingsManager.getInstance().initialize(context);
      void this.initializeRdb(context);
    } else {
      logger.warn(TAG, 'AbilityContext 不可用，数据层延迟初始化');
    }
  }

  private async initializeRdb(context: common.UIAbilityContext): Promise<void> {
    try {
      const storeConfig: relationalStore.StoreConfig = {
        name: DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S1
      };
      await ngfRelationalStoreFacade.initialize(context, storeConfig);
      const rdbStore = ngfRelationalStoreFacade.getRdbStore();
      if (rdbStore !== null) {
        ngfDbMigratorFacade.initialize(rdbStore);
        logger.info(TAG, 'RDB 和 DbMigrator 初始化完成');
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `RDB 初始化异常: ${message}`);
    }
  }
}

export const ngfDataIntegrationFacade = new NGFDataIntegrationFacade();
