import { NGFIntegrationFacadeBase } from '../../core/facades/NGFIntegrationFacadeBase';
import { NGFServiceRegistration } from '../../core/contracts/NGFServiceRegistration';
import { ngfCacheStoreFacade } from './CacheStoreFacade';
import { ngfDataFacade } from './DataFacade';
import { ngfDbMigratorFacade } from './DbMigratorFacade';
import { ngfSettingsStoreFacade } from './SettingsStoreFacade';
import { ngfStorageProviderFacade } from './StorageProviderFacade';

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
    return registrations;
  }
}

export const ngfDataIntegrationFacade = new NGFDataIntegrationFacade();
