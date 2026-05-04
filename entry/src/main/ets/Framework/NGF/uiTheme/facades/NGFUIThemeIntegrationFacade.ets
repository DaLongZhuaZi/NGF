import { NGFIntegrationFacadeBase } from '../../core/facades/NGFIntegrationFacadeBase';
import { NGFServiceRegistration } from '../../core/contracts/NGFServiceRegistration';
import { ngfThemeManagerFacade } from './ThemeManagerFacade';

export class NGFUIThemeIntegrationFacade extends NGFIntegrationFacadeBase {
  protected readonly tag: string = 'NGFUIThemeIntegrationFacade';
  protected readonly appStorageKey: string = 'ngf_theme_integrated';

  protected getServiceRegistrations(): Array<NGFServiceRegistration> {
    const registrations: Array<NGFServiceRegistration> = [];
    registrations.push(new NGFServiceRegistration(
      'ngf.theme.theme_manager',
      'ThemeManagerFacade',
      ngfThemeManagerFacade as object
    ));
    return registrations;
  }

  protected onBootstrapped(): void {
    ngfThemeManagerFacade.initializeDefaults();
  }
}

export const ngfUIThemeIntegrationFacade = new NGFUIThemeIntegrationFacade();
