import { NGFIntegrationFacadeBase } from '../../core/facades/NGFIntegrationFacadeBase';
import { NGFServiceRegistration } from '../../core/contracts/NGFServiceRegistration';
import { ngfI18nManagerFacade } from './I18nManagerFacade';

export class NGFI18nIntegrationFacade extends NGFIntegrationFacadeBase {
  protected readonly tag: string = 'NGFI18nIntegrationFacade';
  protected readonly appStorageKey: string = 'ngf_i18n_integrated';

  protected getServiceRegistrations(): Array<NGFServiceRegistration> {
    const registrations: Array<NGFServiceRegistration> = [];
    registrations.push(new NGFServiceRegistration(
      'ngf.i18n.i18n_manager',
      'I18nManagerFacade',
      ngfI18nManagerFacade as object
    ));
    return registrations;
  }

  protected onBootstrapped(): void {
    ngfI18nManagerFacade.initializeDefaults();
  }
}

export const ngfI18nIntegrationFacade = new NGFI18nIntegrationFacade();
