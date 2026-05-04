import { hdsMaterial } from '@kit.UIDesignKit';

export enum NGFVisualEffectsMaterialMode {
  ADAPTIVE = 'adaptive',
  MANUAL = 'manual'
}

export interface NGFVisualEffectsCapability {
  supportedMaterialTypes: Array<hdsMaterial.MaterialType>;
  supportsImmersiveMaterial: boolean;
  supportsAdaptiveMaterial: boolean;
  availableManualLevels: Array<hdsMaterial.MaterialLevel>;
  recommendedManualLevel: hdsMaterial.MaterialLevel;
  lastCheckedAt: number;
  detectError: string;
}

export interface NGFVisualEffectsSettings {
  materialMode: NGFVisualEffectsMaterialMode;
  manualMaterialLevel: hdsMaterial.MaterialLevel;
}

export interface NGFVisualEffectsState {
  capability: NGFVisualEffectsCapability;
  settings: NGFVisualEffectsSettings;
  effectiveMaterialLevel: hdsMaterial.MaterialLevel;
}

export type NGFVisualEffectsStateListener = (state: NGFVisualEffectsState) => void;

export interface IVisualEffectsManager {
  initialize(): Promise<void>;
  refreshCapability(): Promise<void>;
  getState(): NGFVisualEffectsState;
  isInitialized(): boolean;
  setMaterialMode(mode: NGFVisualEffectsMaterialMode): Promise<void>;
  setManualMaterialLevel(level: hdsMaterial.MaterialLevel): Promise<void>;
  resetToRecommended(): Promise<void>;
  addListener(listener: NGFVisualEffectsStateListener): void;
  removeListener(listener: NGFVisualEffectsStateListener): void;
  getMaterialTypeLabel(type: hdsMaterial.MaterialType): string;
  getMaterialLevelLabel(level: hdsMaterial.MaterialLevel): string;
  getMaterialModeLabel(mode: NGFVisualEffectsMaterialMode): string;
}
