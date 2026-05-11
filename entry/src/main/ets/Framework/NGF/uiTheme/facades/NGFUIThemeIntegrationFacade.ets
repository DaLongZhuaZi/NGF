import { NGFIntegrationFacadeBase } from '../../core/facades/NGFIntegrationFacadeBase';
import { NGFServiceRegistration } from '../../core/contracts/NGFServiceRegistration';
import { ngfThemeManagerFacade } from './ThemeManagerFacade';
import { ngfColorTokenProviderFacade } from './ColorTokenProviderFacade';
import { ngfFontScaleManagerFacade } from './FontScaleManagerFacade';

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
    registrations.push(new NGFServiceRegistration(
      'ngf.theme.color_token_provider',
      'ColorTokenProviderFacade',
      ngfColorTokenProviderFacade as object
    ));
    registrations.push(new NGFServiceRegistration(
      'ngf.theme.font_scale_manager',
      'FontScaleManagerFacade',
      ngfFontScaleManagerFacade as object
    ));
    return registrations;
  }

  protected onBootstrapped(): void {
    ngfThemeManagerFacade.initializeDefaults();
    ngfColorTokenProviderFacade.registerDefaults();
  }
}

export const ngfUIThemeIntegrationFacade = new NGFUIThemeIntegrationFacade();
