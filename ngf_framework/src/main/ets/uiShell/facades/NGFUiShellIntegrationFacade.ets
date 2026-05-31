import { NGFIntegrationFacadeBase } from '../../core/facades/NGFIntegrationFacadeBase';
import { NGFServiceRegistration } from '../../core/contracts/NGFServiceRegistration';
import { ngfNavigationShellFacade } from './NavigationShellFacade';
import { ngfPagePolicyHostFacade } from './PagePolicyHostFacade';
import { ngfRouteInterceptorFacade } from './RouteInterceptorFacade';
import { ngfDeepLinkFacade } from './DeepLinkFacade';
import { ngfPageStateStoreFacade } from './PageStateStoreFacade';
import { ngfOverlayManagerFacade } from './OverlayManagerFacade';
import { ngfPageTransitionManager } from './PageTransitionManagerFacade';

export class NGFUiShellIntegrationFacade extends NGFIntegrationFacadeBase {
  protected readonly tag: string = 'NGFUiShellIntegrationFacade';
  protected readonly appStorageKey: string = 'ngf_ui_shell_integrated';

  protected getServiceRegistrations(): Array<NGFServiceRegistration> {
    const registrations: Array<NGFServiceRegistration> = [];
    registrations.push(new NGFServiceRegistration('ngf.ui.navigation_shell', 'NavigationShellFacade', ngfNavigationShellFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.ui.page_policy_host', 'PagePolicyHostFacade', ngfPagePolicyHostFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.ui.route_interceptor', 'RouteInterceptorFacade', ngfRouteInterceptorFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.ui.deep_link', 'DeepLinkFacade', ngfDeepLinkFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.ui.page_state_store', 'PageStateStoreFacade', ngfPageStateStoreFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.ui.overlay_manager', 'OverlayManagerFacade', ngfOverlayManagerFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.ui.page_transition_manager', 'PageTransitionManagerFacade', ngfPageTransitionManager as object));
    return registrations;
  }
}

export const ngfUiShellIntegrationFacade = new NGFUiShellIntegrationFacade();
