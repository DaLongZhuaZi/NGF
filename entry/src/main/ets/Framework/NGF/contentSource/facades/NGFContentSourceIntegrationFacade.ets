import { NGFIntegrationFacadeBase } from '../../core/facades/NGFIntegrationFacadeBase';
import { NGFServiceRegistration } from '../../core/contracts/NGFServiceRegistration';
import { logger } from '../../utils/Logger';
import { uiContextManager } from '../../platformOhos/UIContextManager';
import { ngfSourceLoaderFacade } from './SourceLoaderFacade';
import { ngfSourceRegistryFacade } from './SourceRegistryFacade';
import { ngfSourceRepositoryFacade } from './SourceRepositoryFacade';
import { ngfHttpClientFacade } from './HttpClientFacade';
import { ngfContentCacheFacade } from './ContentCacheFacade';
import { ngfContentPipelineFacade } from './ContentPipelineFacade';
import { ngfSourceHealthCheckerFacade } from './SourceHealthCheckerFacade';

const TAG: string = 'NGFContentSourceIntegrationFacade';

export class NGFContentSourceIntegrationFacade extends NGFIntegrationFacadeBase {
  protected readonly tag: string = 'NGFContentSourceIntegrationFacade';
  protected readonly appStorageKey: string = 'ngf_content_source_integrated';

  protected getServiceRegistrations(): Array<NGFServiceRegistration> {
    const registrations: Array<NGFServiceRegistration> = [];
    registrations.push(new NGFServiceRegistration('ngf.source.repository', 'SourceRepositoryFacade', ngfSourceRepositoryFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.source.loader', 'SourceLoaderFacade', ngfSourceLoaderFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.source.registry', 'SourceRegistryFacade', ngfSourceRegistryFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.network.http_client', 'HttpClientFacade', ngfHttpClientFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.source.content_cache', 'ContentCacheFacade', ngfContentCacheFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.source.content_pipeline', 'ContentPipelineFacade', ngfContentPipelineFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.source.health_checker', 'SourceHealthCheckerFacade', ngfSourceHealthCheckerFacade as object));
    return registrations;
  }

  protected onBootstrapped(): void {
    const context = uiContextManager.getAbilityContext();
    if (context !== null) {
      ngfContentCacheFacade.initialize(context.filesDir);
      ngfSourceLoaderFacade.initialize(context.filesDir);
      ngfSourceRepositoryFacade.initialize(context.filesDir);
    } else {
      logger.warn(TAG, 'AbilityContext 不可用，内容源层延迟初始化');
    }
  }
}

export const ngfContentSourceIntegrationFacade = new NGFContentSourceIntegrationFacade();
