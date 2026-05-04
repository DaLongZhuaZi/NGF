export enum NGFHoldingUiAnchor {
  LEFT = 'left',
  RIGHT = 'right'
}

export enum NGFHoldingAwarenessSide {
  UNKNOWN = 'unknown',
  NONE = 'none',
  LEFT = 'left',
  RIGHT = 'right',
  BOTH = 'both'
}

export enum NGFHoldingAwarenessSource {
  DEFAULT = 'default',
  HOLDING_HAND = 'holding_hand',
  OPERATING_HAND = 'operating_hand',
  COMBINED = 'combined'
}

export enum NGFHoldingAwarenessConfidence {
  FALLBACK = 'fallback',
  INFERRED = 'inferred',
  EXACT = 'exact'
}

export interface NGFHoldingAwarenessSnapshot {
  preferredAnchor: NGFHoldingUiAnchor;
  side: NGFHoldingAwarenessSide;
  source: NGFHoldingAwarenessSource;
  confidence: NGFHoldingAwarenessConfidence;
  available: boolean;
  preciseSupported: boolean;
  detectGestureGranted: boolean;
  activityMotionGranted: boolean;
  lastUpdatedAt: number;
}

export type NGFHoldingAwarenessListener = (snapshot: NGFHoldingAwarenessSnapshot) => void;

export interface IHoldingAwarenessManager {
  initialize(): Promise<void>;
  resume(): Promise<void>;
  requestActivityMotionPermission(context?: object): Promise<boolean>;
  getSnapshot(): NGFHoldingAwarenessSnapshot;
  getPreferredAnchor(): NGFHoldingUiAnchor;
  addListener(listener: NGFHoldingAwarenessListener): void;
  removeListener(listener: NGFHoldingAwarenessListener): void;
  destroy(): void;
}
