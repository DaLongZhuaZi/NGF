import { NGFIntegrationFacadeBase } from '../../core/facades/NGFIntegrationFacadeBase';
import { NGFServiceRegistration } from '../../core/contracts/NGFServiceRegistration';
import { ngfOhosContextBridgeFacade } from './OhosContextBridgeFacade';
import { ngfPageWindowPolicyResolverFacade } from './PageWindowPolicyResolverFacade';
import { ngfPlatformWindowManagerFacade } from './PlatformWindowManagerFacade';
import { ngfPlatformWindowControllerFacade } from './PlatformWindowControllerFacade';
import { ngfMultiWindowManagerFacade } from './MultiWindowManagerFacade';
import { ngfPermissionManagerFacade } from './PermissionManagerFacade';

export class NGFPlatformOhosIntegrationFacade extends NGFIntegrationFacadeBase {
  protected readonly tag: string = 'NGFPlatformOhosIntegrationFacade';
  protected readonly appStorageKey: string = 'ngf_platform_integrated';

  protected getServiceRegistrations(): Array<NGFServiceRegistration> {
    const registrations: Array<NGFServiceRegistration> = [];
    registrations.push(new NGFServiceRegistration('ngf.platform.window_manager', 'PlatformWindowManagerFacade', ngfPlatformWindowManagerFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.platform.window_controller', 'PlatformWindowControllerFacade', ngfPlatformWindowControllerFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.platform.page_policy_resolver', 'PageWindowPolicyResolverFacade', ngfPageWindowPolicyResolverFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.platform.context_bridge', 'OhosContextBridgeFacade', ngfOhosContextBridgeFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.platform.multi_window_manager', 'MultiWindowManagerFacade', ngfMultiWindowManagerFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.platform.permission_manager', 'PermissionManagerFacade', ngfPermissionManagerFacade as object));
    return registrations;
  }

  protected onBootstrapped(): void {
    ngfOhosContextBridgeFacade.bindUIContext('EntryAbility');
  }
}

export const ngfPlatformOhosIntegrationFacade = new NGFPlatformOhosIntegrationFacade();
