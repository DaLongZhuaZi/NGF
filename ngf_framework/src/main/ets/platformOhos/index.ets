export { IPlatformWindowController, NGFDisplayMode } from './contracts/IPlatformWindowController';
export { IPageWindowPolicyResolver, NGFPageWindowPolicy, NGFPageWindowSpec } from './contracts/IPageWindowPolicyResolver';
export { IOhosContextBridge } from './contracts/IOhosContextBridge';
export {
  IPlatformWindowManager,
  IPlatformWindowSnapshotObserver,
  NGFPageWindowProfile,
  NGFWindowAvoidAreaSnapshot,
  NGFWindowAvoidAreaType,
  NGFWindowMonitorStorageKey,
  NGFWindowOrientationPreference,
  NGFWindowRectSnapshot,
  NGFWindowRuntimeSnapshot,
  NGFWindowStatus,
  NGFWindowSystemBarPolicy,
  NGFWindowSystemBarStyle
} from './contracts/IPlatformWindowManager';
export { IMultiWindowManager, NGFWindowMode } from './contracts/IMultiWindowManager';
export { IPermissionManager } from './contracts/IPermissionManager';

export { PlatformWindowControllerFacade, ngfPlatformWindowControllerFacade } from './facades/PlatformWindowControllerFacade';
export { PageWindowPolicyResolverFacade, ngfPageWindowPolicyResolverFacade } from './facades/PageWindowPolicyResolverFacade';
export { OhosContextBridgeFacade, ngfOhosContextBridgeFacade } from './facades/OhosContextBridgeFacade';
export { PlatformWindowManagerFacade, ngfPlatformWindowManagerFacade } from './facades/PlatformWindowManagerFacade';
export { NGFPlatformOhosIntegrationFacade, ngfPlatformOhosIntegrationFacade } from './facades/NGFPlatformOhosIntegrationFacade';
export { PermissionManagerFacade, ngfPermissionManagerFacade } from './facades/PermissionManagerFacade';
export { ngfMultiWindowManagerFacade } from './facades/MultiWindowManagerFacade';
