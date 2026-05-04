import { NGFIntegrationFacadeBase } from '../../core/facades/NGFIntegrationFacadeBase';
import { NGFServiceRegistration } from '../../core/contracts/NGFServiceRegistration';
import { ngfSourceLoaderFacade } from './SourceLoaderFacade';
import { ngfSourceRegistryFacade } from './SourceRegistryFacade';
import { ngfSourceRepositoryFacade } from './SourceRepositoryFacade';

export class NGFContentSourceIntegrationFacade extends NGFIntegrationFacadeBase {
  protected readonly tag: string = 'NGFContentSourceIntegrationFacade';
  protected readonly appStorageKey: string = 'ngf_content_source_integrated';

  protected getServiceRegistrations(): Array<NGFServiceRegistration> {
    const registrations: Array<NGFServiceRegistration> = [];
    registrations.push(new NGFServiceRegistration('ngf.source.repository', 'SourceRepositoryFacade', ngfSourceRepositoryFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.source.loader', 'SourceLoaderFacade', ngfSourceLoaderFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.source.registry', 'SourceRegistryFacade', ngfSourceRegistryFacade as object));
    return registrations;
  }
}

export const ngfContentSourceIntegrationFacade = new NGFContentSourceIntegrationFacade();
