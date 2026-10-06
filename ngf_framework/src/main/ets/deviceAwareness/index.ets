export {
  IHoldingAwarenessManager,
  NGFHoldingAwarenessConfidence,
  NGFHoldingAwarenessListener,
  NGFHoldingAwarenessSide,
  NGFHoldingAwarenessSnapshot,
  NGFHoldingAwarenessSource,
  NGFHoldingUiAnchor
} from './contracts/IHoldingAwarenessManager';

export {
  IDeviceAdaptationManager,
  NGFBreakpoint,
  NGFDeviceChangeListener,
  NGFDeviceInfo,
  NGFDeviceType,
  NGFFoldStatus,
  NGFScreenOrientation,
  NGFRuntimeStatus,
  NGFAppThreadInfo
} from './contracts/IDeviceAdaptationManager';

export {
  IVisualEffectsManager,
  NGFSystemMaterialPolicy,
  NGFVisualEffectsCapability,
  NGFVisualEffectsMaterialMode,
  NGFVisualEffectsSettings,
  NGFVisualEffectsState,
  NGFVisualEffectsStateListener
} from './contracts/IVisualEffectsManager';

export { IAdaptiveLayout, NGFBreakpointLayoutConfig } from './contracts/IAdaptiveLayout';
export {
  IDeviceCapabilityDetector,
  NGFCapabilityType,
  NGFCapabilityResult
} from './contracts/IDeviceCapabilityDetector';

export {
  IAccessibilityManager,
  NGFAccessibilityState,
  NGFAccessibilityStateListener,
  NGFAccessibilityStateSnapshot,
  NGFInclusiveDesignPolicyListener,
  NGFInclusiveDesignResolved,
  NGFTouchMode
} from './contracts/IAccessibilityManager';

export {
  auditAccessibilitySemantics,
  NGFAccessibilityAction,
  NGFAccessibilityCustomAction,
  NGFAccessibilityGrouping,
  NGFAccessibilityLevel,
  NGFAccessibilityRole,
  NGFAccessibilitySemantics,
  NGFAccessibilitySemanticsAudit,
  NGFAccessibilitySemanticsIssue,
  NGFAccessibilitySemanticsIssueCode,
  NGFAccessibilitySemanticState
} from './contracts/NGFAccessibilitySemantics';

export {
  isAnnouncementDeliverable,
  resolveAnnouncementEventType,
  NGFAnnouncementMode,
  NGFAnnouncementRequest
} from './contracts/NGFAccessibilityAnnouncement';

export {
  filterElderlyModeKeywords,
  getElderlyModeAliasDisplayNames,
  getElderlyModeDisplayName,
  isElderlyModeSearchHit,
  matchesElderlyModeKeyword,
  NGF_ELDERLY_MODE_ALIASES_ZH,
  NGF_ELDERLY_MODE_ALL_KEYWORDS_ZH,
  NGF_ELDERLY_MODE_STANDARD_NAME_ZH
} from './contracts/NGFElderlyModeNaming';

export {
  NGF_APP_FONT_SIZE_MAX_SCALE,
  NGF_INCLUSIVE_DESIGN_METRICS,
  NGF_INCLUSIVE_DESIGN_POLICY_DEFAULT,
  NGFContrastPolicy,
  NGFDensityPolicy,
  NGFInclusiveDesignMetrics,
  NGFInclusiveDesignPolicy,
  NGFInclusiveDesignPolicyInput,
  NGFMotionPolicy,
  NGFTextScalePolicy,
  NGFTouchTargetPolicy,
  NGFUiContext,
  parseContrastPolicy,
  parseDensityPolicy,
  parseMotionPolicy,
  parseTextScalePolicy,
  parseTouchTargetPolicy,
  resolveInclusiveDesignPolicy,
  resolveRequiredBodyFontDp,
  resolveRequiredTouchTargetDp,
  resolveUiContextForPolicy
} from './contracts/NGFInclusiveDesignPolicy';

export { ngfAccessibilityFacade } from './facades/AccessibilityFacade';
export { ngfHoldingAwarenessFacade } from './facades/HoldingAwarenessFacade';
export { ngfDeviceAdaptationFacade } from './facades/DeviceAdaptationFacade';
export { ngfVisualEffectsFacade } from './facades/VisualEffectsFacade';
export { ngfAdaptiveLayoutFacade } from './facades/AdaptiveLayoutFacade';
export { DeviceCapabilityDetectorFacade, ngfDeviceCapabilityDetectorFacade } from './facades/DeviceCapabilityDetectorFacade';
export { ngfDeviceAwarenessIntegrationFacade } from './facades/NGFDeviceAwarenessIntegrationFacade';
