import { hdsMaterial } from '@kit.UIDesignKit';
import uiMaterial from '@ohos.arkui.uiMaterial';

export enum NGFVisualEffectsMaterialMode {
  ADAPTIVE = 'adaptive',
  MANUAL = 'manual'
}

export enum NGFSystemMaterialPolicy {
  AUTO = 'auto',
  FORCE_IMMERSIVE = 'force_immersive',
  DISABLED = 'disabled'
}

export interface NGFVisualEffectsCapability {
  supportedMaterialTypes: Array<hdsMaterial.MaterialType>;
  supportsImmersiveMaterial: boolean;
  supportsAdaptiveMaterial: boolean;
  availableManualLevels: Array<hdsMaterial.MaterialLevel>;
  recommendedManualLevel: hdsMaterial.MaterialLevel;
  systemMaterialState: uiMaterial.MaterialState;
  systemMaterialType: uiMaterial.MaterialType;
  lastCheckedAt: number;
  detectError: string;
}

export interface NGFVisualEffectsSettings {
  materialMode: NGFVisualEffectsMaterialMode;
  manualMaterialLevel: hdsMaterial.MaterialLevel;
  systemMaterialPolicy: NGFSystemMaterialPolicy;
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
  setSystemMaterialPolicy(policy: NGFSystemMaterialPolicy): Promise<void>;
  resetToRecommended(): Promise<void>;
  addListener(listener: NGFVisualEffectsStateListener): void;
  removeListener(listener: NGFVisualEffectsStateListener): void;
  shouldUseSystemMaterialSurface(): boolean;
  buildSystemMaterialForOverlay(): uiMaterial.Material | undefined;
  buildSystemMaterialForInteractive(): uiMaterial.Material | undefined;
  buildSystemMaterialForPanel(): uiMaterial.Material | undefined;
  buildSystemMaterialForProminentPanel(): uiMaterial.Material | undefined;
  buildSystemMaterialForSheet(): uiMaterial.Material | undefined;
  buildSystemMaterialForFloatingControl(): uiMaterial.Material | undefined;
  buildSystemMaterialForLightEffectControl(): uiMaterial.Material | undefined;
  buildSystemMaterialForClickablePanel(): uiMaterial.Material | undefined;
  buildImmersiveMaterialForTabs(): uiMaterial.ImmersiveMaterial | undefined;
  getMaterialTypeLabel(type: hdsMaterial.MaterialType): string;
  getMaterialLevelLabel(level: hdsMaterial.MaterialLevel): string;
  getMaterialModeLabel(mode: NGFVisualEffectsMaterialMode): string;
  getSystemMaterialPolicyLabel(policy: NGFSystemMaterialPolicy): string;
  getSystemMaterialStateLabel(state: uiMaterial.MaterialState): string;
  getSystemMaterialTypeLabel(type: uiMaterial.MaterialType): string;
}
