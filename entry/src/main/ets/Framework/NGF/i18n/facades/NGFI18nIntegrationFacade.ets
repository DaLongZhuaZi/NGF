import { NGFIntegrationFacadeBase } from '../../core/facades/NGFIntegrationFacadeBase';
import { NGFServiceRegistration } from '../../core/contracts/NGFServiceRegistration';
import { ngfI18nManagerFacade } from './I18nManagerFacade';
import { ngfTranslationResourceFacade } from './TranslationResourceFacade';
import { ngfRelativeTimeFormatterFacade } from './RelativeTimeFormatterFacade';

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
    registrations.push(new NGFServiceRegistration(
      'ngf.i18n.translation_resource',
      'TranslationResourceFacade',
      ngfTranslationResourceFacade as object
    ));
    registrations.push(new NGFServiceRegistration(
      'ngf.i18n.relative_time',
      'RelativeTimeFormatterFacade',
      ngfRelativeTimeFormatterFacade as object
    ));
    return registrations;
  }

  protected onBootstrapped(): void {
    ngfI18nManagerFacade.initializeDefaults();
  }
}

export const ngfI18nIntegrationFacade = new NGFI18nIntegrationFacade();
