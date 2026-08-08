/**
 * NGF 视觉效果门面
 * - 通过 hdsMaterial 检测材质能力
 * - 管理自适应/手动材质策略
 * - 将当前视觉效果状态同步至 AppStorage
 */

import { logger } from '../../utils/Logger';
import { hdsMaterial } from '@kit.UIDesignKit';
import uiMaterial from '@ohos.arkui.uiMaterial';
import { BusinessError } from '@kit.BasicServicesKit';
import { SettingsManager } from '../../data/SettingsManager';
import {
  IVisualEffectsManager,
  NGFSystemMaterialPolicy,
  NGFVisualEffectsMaterialMode,
  NGFVisualEffectsCapability,
  NGFVisualEffectsSettings,
  NGFVisualEffectsState,
  NGFVisualEffectsStateListener
} from '../contracts/IVisualEffectsManager';

const TAG: string = 'NGFVisualEffectsFacade';

/**
 * 视觉效果持久化配置键
 */
export class NGFVisualEffectsSettingKeys {
  static readonly VISUAL_EFFECTS_MATERIAL_MODE: string = 'ngf_visual_effects_material_mode';
  static readonly VISUAL_EFFECTS_MANUAL_MATERIAL_LEVEL: string = 'ngf_visual_effects_manual_material_level';
  static readonly VISUAL_EFFECTS_SYSTEM_MATERIAL_POLICY: string = 'ngf_visual_effects_system_material_policy';
  static readonly VISUAL_EFFECTS_SUPPORTED_MATERIAL_TYPES: string = 'ngf_visual_effects_supported_material_types';
  static readonly VISUAL_EFFECTS_SYSTEM_MATERIAL_STATE: string = 'ngf_visual_effects_system_material_state';
  static readonly VISUAL_EFFECTS_SYSTEM_MATERIAL_TYPE: string = 'ngf_visual_effects_system_material_type';
  static readonly VISUAL_EFFECTS_CAPABILITY_LAST_CHECKED_AT: string = 'ngf_visual_effects_capability_last_checked_at';
  static readonly VISUAL_EFFECTS_CAPABILITY_DETECT_ERROR: string = 'ngf_visual_effects_capability_detect_error';
}

class NGFImmersiveMaterialOptions implements uiMaterial.ImmersiveOptions {
  style?: uiMaterial.ImmersiveStyle;
  materialColor?: ResourceColor;
  colorInvert?: boolean;
  applyShadow?: boolean;
  interactive?: boolean;
  lightEffect?: uiMaterial.LightEffectOptions | null;

  constructor(
    style: uiMaterial.ImmersiveStyle,
    interactive: boolean,
    enableLightEffect: boolean,
    materialColor: ResourceColor | undefined
  ) {
    this.style = style;
    if (materialColor !== undefined) {
      this.materialColor = materialColor;
    }
    this.colorInvert = true;
    this.applyShadow = true;
    this.interactive = interactive;
    this.lightEffect = enableLightEffect ? new NGFImmersiveLightEffectOptions() : null;
  }
}

class NGFImmersiveLightEffectOptions implements uiMaterial.LightEffectOptions {
  color?: ResourceColor;
}

const DEFAULT_VISUAL_EFFECTS_CAPABILITY: NGFVisualEffectsCapability = {
  supportedMaterialTypes: [hdsMaterial.MaterialType.ADAPTIVE],
  supportsImmersiveMaterial: false,
  supportsAdaptiveMaterial: true,
  availableManualLevels: [hdsMaterial.MaterialLevel.SMOOTH],
  recommendedManualLevel: hdsMaterial.MaterialLevel.SMOOTH,
  systemMaterialState: uiMaterial.MaterialState.DEFAULT,
  systemMaterialType: uiMaterial.MaterialType.IMMERSIVE,
  lastCheckedAt: 0,
  detectError: ''
};

const DEFAULT_VISUAL_EFFECTS_SETTINGS: NGFVisualEffectsSettings = {
  materialMode: NGFVisualEffectsMaterialMode.ADAPTIVE,
  manualMaterialLevel: hdsMaterial.MaterialLevel.SMOOTH,
  systemMaterialPolicy: NGFSystemMaterialPolicy.AUTO
};

class NGFVisualEffectsManager implements IVisualEffectsManager {
  private static instance: NGFVisualEffectsManager | null = null;

  private settingsManager: SettingsManager = SettingsManager.getInstance();
  private currentState: NGFVisualEffectsState = this.createDefaultState();
  private listeners: Set<NGFVisualEffectsStateListener> = new Set<NGFVisualEffectsStateListener>();
  private initialized: boolean = false;

  private constructor() {}

  public static getInstance(): NGFVisualEffectsManager {
    if (!NGFVisualEffectsManager.instance) {
      NGFVisualEffectsManager.instance = new NGFVisualEffectsManager();
    }
    return NGFVisualEffectsManager.instance;
  }

  public async initialize(): Promise<void> {
    if (this.initialized) {
      return;
    }

    const hasPersistedCapability: boolean = this.loadCapabilityFromStorage();
    let capabilityPersistNeeded: boolean = false;

    if (!hasPersistedCapability) {
      await this.refreshCapabilityInternal();
      capabilityPersistNeeded = true;
    }

    const normalized: boolean = this.loadSettingsFromStorage();
    this.recalculateEffectiveMaterialLevel();

    if (capabilityPersistNeeded) {
      await this.persistCapability();
    }

    if (normalized) {
      await this.persistSettings();
    }

    this.syncStateToAppStorage();
    this.initialized = true;
    logger.info(
      TAG,
      '初始化视觉效果管理器完成：模式=' + this.currentState.settings.materialMode + '，生效等级=' + this.currentState.effectiveMaterialLevel + '，能力来源=' + String(hasPersistedCapability ? '持久化存储' : '系统检测')
    );
  }

  public async refreshCapability(): Promise<void> {
    await this.refreshCapabilityInternal();
    const normalized: boolean = this.sanitizeSettingsByCapability();
    this.recalculateEffectiveMaterialLevel();
    await this.persistCapability();

    if (normalized) {
      await this.persistSettings();
    }

    this.syncStateToAppStorage();
    this.notifyListeners();
  }

  public getState(): NGFVisualEffectsState {
    return this.copyState(this.currentState);
  }

  public isInitialized(): boolean {
    return this.initialized;
  }

  public async setMaterialMode(mode: NGFVisualEffectsMaterialMode): Promise<void> {
    const normalizedMode: NGFVisualEffectsMaterialMode = this.normalizeMaterialMode(mode);
    if (normalizedMode === this.currentState.settings.materialMode) {
      return;
    }

    this.currentState.settings.materialMode = normalizedMode;
    this.recalculateEffectiveMaterialLevel();
    await this.persistSettings();
    this.syncStateToAppStorage();
    this.notifyListeners();
    logger.info(TAG, '已更新材质模式：' + normalizedMode);
  }

  public async setManualMaterialLevel(level: hdsMaterial.MaterialLevel): Promise<void> {
    const normalizedLevel: hdsMaterial.MaterialLevel = this.normalizeManualMaterialLevel(level);
    if (normalizedLevel === this.currentState.settings.manualMaterialLevel) {
      return;
    }

    this.currentState.settings.manualMaterialLevel = normalizedLevel;
    this.recalculateEffectiveMaterialLevel();
    await this.persistSettings();
    this.syncStateToAppStorage();
    this.notifyListeners();
    logger.info(TAG, '已更新手动材质等级：' + normalizedLevel);
  }

  public async setSystemMaterialPolicy(policy: NGFSystemMaterialPolicy): Promise<void> {
    const normalizedPolicy: NGFSystemMaterialPolicy = this.normalizeSystemMaterialPolicy(policy);
    if (normalizedPolicy === this.currentState.settings.systemMaterialPolicy) {
      return;
    }

    this.currentState.settings.systemMaterialPolicy = normalizedPolicy;
    await this.persistSettings();
    this.syncStateToAppStorage();
    this.notifyListeners();
    logger.info(TAG, '已更新系统材质策略：' + normalizedPolicy);
  }

  public async resetToRecommended(): Promise<void> {
    this.currentState.settings.materialMode = DEFAULT_VISUAL_EFFECTS_SETTINGS.materialMode;
    this.currentState.settings.manualMaterialLevel = this.currentState.capability.recommendedManualLevel;
    this.currentState.settings.systemMaterialPolicy = DEFAULT_VISUAL_EFFECTS_SETTINGS.systemMaterialPolicy;
    this.recalculateEffectiveMaterialLevel();
    await this.persistSettings();
    this.syncStateToAppStorage();
    this.notifyListeners();
    logger.info(TAG, '已将视觉效果设置重置为推荐默认值');
  }

  public addListener(listener: NGFVisualEffectsStateListener): void {
    this.listeners.add(listener);
  }

  public removeListener(listener: NGFVisualEffectsStateListener): void {
    this.listeners.delete(listener);
  }

  public shouldUseSystemMaterialSurface(): boolean {
    if (this.currentState.settings.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED) {
      return false;
    }
    if (this.currentState.settings.systemMaterialPolicy === NGFSystemMaterialPolicy.FORCE_IMMERSIVE) {
      return true;
    }
    return this.currentState.capability.systemMaterialState !== uiMaterial.MaterialState.DISABLE;
  }

  public buildSystemMaterialForOverlay(): uiMaterial.Material | undefined {
    return this.buildSystemMaterial(uiMaterial.ImmersiveStyle.REGULAR, false, true);
  }

  public buildSystemMaterialForInteractive(): uiMaterial.Material | undefined {
    return this.buildSystemMaterial(uiMaterial.ImmersiveStyle.THIN, true, true);
  }

  public buildSystemMaterialForPanel(): uiMaterial.Material | undefined {
    return this.buildSystemMaterial(uiMaterial.ImmersiveStyle.REGULAR, false, false);
  }

  public buildSystemMaterialForProminentPanel(): uiMaterial.Material | undefined {
    return this.buildSystemMaterial(uiMaterial.ImmersiveStyle.REGULAR, false, false);
  }

  public buildSystemMaterialForSheet(): uiMaterial.Material | undefined {
    return this.buildSystemMaterial(uiMaterial.ImmersiveStyle.THICK, false, false);
  }

  public buildSystemMaterialForFloatingControl(): uiMaterial.Material | undefined {
    return this.buildSystemMaterial(uiMaterial.ImmersiveStyle.THIN, true, true);
  }

  public buildSystemMaterialForLightEffectControl(): uiMaterial.Material | undefined {
    return this.buildSystemMaterial(uiMaterial.ImmersiveStyle.ULTRA_THIN, true, true);
  }

  public buildSystemMaterialForClickablePanel(): uiMaterial.Material | undefined {
    return this.buildSystemMaterial(uiMaterial.ImmersiveStyle.REGULAR, true, true);
  }

  public buildImmersiveMaterialForTabs(): uiMaterial.ImmersiveMaterial | undefined {
    if (this.currentState.settings.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED) {
      return undefined;
    }
    if (this.currentState.settings.systemMaterialPolicy === NGFSystemMaterialPolicy.AUTO &&
      this.currentState.capability.systemMaterialState === uiMaterial.MaterialState.DISABLE) {
      return undefined;
    }
    return this.createImmersiveMaterial(uiMaterial.ImmersiveStyle.REGULAR, true, true, undefined);
  }

  public getMaterialTypeLabel(type: hdsMaterial.MaterialType): string {
    switch (type) {
      case hdsMaterial.MaterialType.NONE:
        return 'NONE（无材质）';
      case hdsMaterial.MaterialType.ADAPTIVE:
        return 'ADAPTIVE（系统自适应）';
      case hdsMaterial.MaterialType.IMMERSIVE:
        return 'IMMERSIVE（沉浸式）';
      default:
        return '未知类型(' + type + ')';
    }
  }

  public getMaterialLevelLabel(level: hdsMaterial.MaterialLevel): string {
    switch (level) {
      case hdsMaterial.MaterialLevel.EXQUISITE:
        return 'EXQUISITE（精美）';
      case hdsMaterial.MaterialLevel.GENTLE:
        return 'GENTLE（轻柔）';
      case hdsMaterial.MaterialLevel.SMOOTH:
        return 'SMOOTH（流畅）';
      case hdsMaterial.MaterialLevel.ADAPTIVE:
        return 'ADAPTIVE（系统自适应）';
      default:
        return '未知等级(' + level + ')';
    }
  }

  public getMaterialModeLabel(mode: NGFVisualEffectsMaterialMode): string {
    return mode === NGFVisualEffectsMaterialMode.MANUAL ? '手动固定档位' : '系统自适应（推荐）';
  }

  public getSystemMaterialPolicyLabel(policy: NGFSystemMaterialPolicy): string {
    switch (policy) {
      case NGFSystemMaterialPolicy.DISABLED:
        return '关闭系统材质';
      case NGFSystemMaterialPolicy.FORCE_IMMERSIVE:
        return '强制沉浸材质';
      default:
        return '跟随系统默认';
    }
  }

  public getSystemMaterialStateLabel(state: uiMaterial.MaterialState): string {
    switch (state) {
      case uiMaterial.MaterialState.ENABLE:
        return 'ENABLE（默认开启）';
      case uiMaterial.MaterialState.DISABLE:
        return 'DISABLE（全局关闭）';
      default:
        return 'DEFAULT（系统默认）';
    }
  }

  public getSystemMaterialTypeLabel(type: uiMaterial.MaterialType): string {
    if (type === uiMaterial.MaterialType.IMMERSIVE) {
      return 'IMMERSIVE（沉浸式）';
    }
    return '未知系统材质(' + type + ')';
  }

  private createDefaultState(): NGFVisualEffectsState {
    return {
      capability: this.copyCapability(DEFAULT_VISUAL_EFFECTS_CAPABILITY),
      settings: this.copySettings(DEFAULT_VISUAL_EFFECTS_SETTINGS),
      effectiveMaterialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
    };
  }

  private copyState(source: NGFVisualEffectsState): NGFVisualEffectsState {
    return {
      capability: this.copyCapability(source.capability),
      settings: this.copySettings(source.settings),
      effectiveMaterialLevel: source.effectiveMaterialLevel
    };
  }

  private copyCapability(source: NGFVisualEffectsCapability): NGFVisualEffectsCapability {
    return {
      supportedMaterialTypes: source.supportedMaterialTypes.slice(),
      supportsImmersiveMaterial: source.supportsImmersiveMaterial,
      supportsAdaptiveMaterial: source.supportsAdaptiveMaterial,
      availableManualLevels: source.availableManualLevels.slice(),
      recommendedManualLevel: source.recommendedManualLevel,
      systemMaterialState: source.systemMaterialState,
      systemMaterialType: source.systemMaterialType,
      lastCheckedAt: source.lastCheckedAt,
      detectError: source.detectError
    };
  }

  private copySettings(source: NGFVisualEffectsSettings): NGFVisualEffectsSettings {
    return {
      materialMode: source.materialMode,
      manualMaterialLevel: source.manualMaterialLevel,
      systemMaterialPolicy: source.systemMaterialPolicy
    };
  }

  private createCapability(
    materialTypes: Array<hdsMaterial.MaterialType>,
    checkedAt: number,
    detectError: string,
    systemMaterialState: uiMaterial.MaterialState = DEFAULT_VISUAL_EFFECTS_CAPABILITY.systemMaterialState,
    systemMaterialType: uiMaterial.MaterialType = DEFAULT_VISUAL_EFFECTS_CAPABILITY.systemMaterialType
  ): NGFVisualEffectsCapability {
    const normalizedTypes: Array<hdsMaterial.MaterialType> = this.normalizeMaterialTypes(materialTypes);
    const supportsImmersive: boolean = this.hasMaterialType(normalizedTypes, hdsMaterial.MaterialType.IMMERSIVE);
    const supportsAdaptive: boolean = this.hasMaterialType(normalizedTypes, hdsMaterial.MaterialType.ADAPTIVE);
    const availableManualLevels: Array<hdsMaterial.MaterialLevel> = this.buildAvailableManualLevels(supportsImmersive);
    const recommendedManualLevel: hdsMaterial.MaterialLevel = supportsImmersive
      ? hdsMaterial.MaterialLevel.GENTLE
      : hdsMaterial.MaterialLevel.SMOOTH;

    return {
      supportedMaterialTypes: normalizedTypes,
      supportsImmersiveMaterial: supportsImmersive,
      supportsAdaptiveMaterial: supportsAdaptive,
      availableManualLevels,
      recommendedManualLevel,
      systemMaterialState,
      systemMaterialType,
      lastCheckedAt: checkedAt,
      detectError
    };
  }

  private async refreshCapabilityInternal(): Promise<void> {
    const checkedAt: number = Date.now();
    try {
      const queriedTypes: Array<hdsMaterial.MaterialType> = hdsMaterial.getSystemMaterialTypes();
      const normalizedTypes: Array<hdsMaterial.MaterialType> = this.normalizeMaterialTypes(queriedTypes);
      const materialInfo: uiMaterial.MaterialInfo = uiMaterial.getMaterialInfo();
      const capability: NGFVisualEffectsCapability = this.createCapability(
        normalizedTypes,
        checkedAt,
        '',
        this.normalizeSystemMaterialState(materialInfo.state),
        this.normalizeSystemMaterialType(materialInfo.type)
      );
      this.currentState.capability = capability;
      logger.info(
        TAG,
        '系统材质能力检测完成：支持沉浸式=' + capability.supportsImmersiveMaterial +
          '，支持自适应=' + capability.supportsAdaptiveMaterial +
          '，类型=' + JSON.stringify(normalizedTypes) +
          '，系统材质状态=' + capability.systemMaterialState +
          '，系统材质类型=' + capability.systemMaterialType
      );
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      const code: number = typeof businessError.code === 'number' ? businessError.code : -1;
      const message: string = typeof businessError.message === 'string' ? businessError.message : String(error);
      const detectError: string = 'code=' + code + ', message=' + message;
      const hasPreviousCapability: boolean = this.currentState.capability.lastCheckedAt > 0;
      const fallbackTypes: Array<hdsMaterial.MaterialType> = hasPreviousCapability
        ? this.currentState.capability.supportedMaterialTypes.slice()
        : DEFAULT_VISUAL_EFFECTS_CAPABILITY.supportedMaterialTypes.slice();
      const fallbackState: uiMaterial.MaterialState = hasPreviousCapability
        ? this.currentState.capability.systemMaterialState
        : DEFAULT_VISUAL_EFFECTS_CAPABILITY.systemMaterialState;
      const fallbackType: uiMaterial.MaterialType = hasPreviousCapability
        ? this.currentState.capability.systemMaterialType
        : DEFAULT_VISUAL_EFFECTS_CAPABILITY.systemMaterialType;

      this.currentState.capability = this.createCapability(fallbackTypes, checkedAt, detectError, fallbackState, fallbackType);
      logger.warn(
        TAG,
        '材质能力检测失败，' + String(hasPreviousCapability ? '保留上次能力快照' : '回退至保守默认值') + '：' + detectError
      );
    }
  }

  private normalizeMaterialTypes(types: Array<hdsMaterial.MaterialType>): Array<hdsMaterial.MaterialType> {
    const uniqueTypes: Array<hdsMaterial.MaterialType> = [];
    types.forEach((type: hdsMaterial.MaterialType) => {
      if (!uniqueTypes.some((item: hdsMaterial.MaterialType) => item === type)) {
        uniqueTypes.push(type);
      }
    });

    if (uniqueTypes.length === 0) {
      uniqueTypes.push(hdsMaterial.MaterialType.ADAPTIVE);
    }

    return uniqueTypes;
  }

  private hasMaterialType(
    types: Array<hdsMaterial.MaterialType>,
    target: hdsMaterial.MaterialType
  ): boolean {
    return types.some((item: hdsMaterial.MaterialType) => item === target);
  }

  private buildAvailableManualLevels(supportsImmersive: boolean): Array<hdsMaterial.MaterialLevel> {
    if (supportsImmersive) {
      return [
        hdsMaterial.MaterialLevel.EXQUISITE,
        hdsMaterial.MaterialLevel.GENTLE,
        hdsMaterial.MaterialLevel.SMOOTH
      ];
    }

    return [hdsMaterial.MaterialLevel.SMOOTH];
  }

  private loadCapabilityFromStorage(): boolean {
    const rawMaterialTypes: string = this.settingsManager.getString(
      NGFVisualEffectsSettingKeys.VISUAL_EFFECTS_SUPPORTED_MATERIAL_TYPES,
      ''
    );
    const checkedAt: number = this.settingsManager.getNumber(
      NGFVisualEffectsSettingKeys.VISUAL_EFFECTS_CAPABILITY_LAST_CHECKED_AT,
      0
    );
    const detectError: string = this.settingsManager.getString(
      NGFVisualEffectsSettingKeys.VISUAL_EFFECTS_CAPABILITY_DETECT_ERROR,
      ''
    );
    const rawSystemMaterialState: number = this.settingsManager.getNumber(
      NGFVisualEffectsSettingKeys.VISUAL_EFFECTS_SYSTEM_MATERIAL_STATE,
      DEFAULT_VISUAL_EFFECTS_CAPABILITY.systemMaterialState
    );
    const rawSystemMaterialType: number = this.settingsManager.getNumber(
      NGFVisualEffectsSettingKeys.VISUAL_EFFECTS_SYSTEM_MATERIAL_TYPE,
      DEFAULT_VISUAL_EFFECTS_CAPABILITY.systemMaterialType
    );
    const hasPersistedCapability: boolean = rawMaterialTypes.length > 0 || checkedAt > 0 || detectError.length > 0;

    if (!hasPersistedCapability) {
      return false;
    }

    const materialTypes: Array<hdsMaterial.MaterialType> = this.parsePersistedMaterialTypes(rawMaterialTypes);
    const normalizedTypes: Array<hdsMaterial.MaterialType> = materialTypes.length > 0
      ? materialTypes
      : DEFAULT_VISUAL_EFFECTS_CAPABILITY.supportedMaterialTypes.slice();
    const systemMaterialState: uiMaterial.MaterialState = this.parseSystemMaterialState(rawSystemMaterialState);
    const systemMaterialType: uiMaterial.MaterialType = this.parseSystemMaterialType(rawSystemMaterialType);

    this.currentState.capability = this.createCapability(
      normalizedTypes,
      checkedAt,
      detectError,
      systemMaterialState,
      systemMaterialType
    );
    logger.info(
      TAG,
      '已从持久化存储加载材质能力快照：检测时间=' + checkedAt +
        '，有错误=' + String(detectError.length > 0) +
        '，类型=' + JSON.stringify(normalizedTypes) +
        '，系统材质状态=' + systemMaterialState +
        '，系统材质类型=' + systemMaterialType
    );
    return true;
  }

  private loadSettingsFromStorage(): boolean {
    let normalized: boolean = false;

    const modeFromStorage: string = this.settingsManager.getString(
      NGFVisualEffectsSettingKeys.VISUAL_EFFECTS_MATERIAL_MODE,
      DEFAULT_VISUAL_EFFECTS_SETTINGS.materialMode
    );
    const manualLevelFromStorage: number = this.settingsManager.getNumber(
      NGFVisualEffectsSettingKeys.VISUAL_EFFECTS_MANUAL_MATERIAL_LEVEL,
      DEFAULT_VISUAL_EFFECTS_SETTINGS.manualMaterialLevel
    );
    const policyFromStorage: string = this.settingsManager.getString(
      NGFVisualEffectsSettingKeys.VISUAL_EFFECTS_SYSTEM_MATERIAL_POLICY,
      DEFAULT_VISUAL_EFFECTS_SETTINGS.systemMaterialPolicy
    );

    const mode: NGFVisualEffectsMaterialMode = this.parseMaterialMode(modeFromStorage);
    const manualLevel: hdsMaterial.MaterialLevel = this.parseMaterialLevel(manualLevelFromStorage);
    const systemMaterialPolicy: NGFSystemMaterialPolicy = this.parseSystemMaterialPolicy(policyFromStorage);

    if (modeFromStorage !== mode) {
      normalized = true;
    }
    if (manualLevelFromStorage !== manualLevel) {
      normalized = true;
    }
    if (policyFromStorage !== systemMaterialPolicy) {
      normalized = true;
    }

    this.currentState.settings = {
      materialMode: mode,
      manualMaterialLevel: manualLevel,
      systemMaterialPolicy
    };

    if (this.sanitizeSettingsByCapability()) {
      normalized = true;
    }

    return normalized;
  }

  private sanitizeSettingsByCapability(): boolean {
    const normalizedManualLevel: hdsMaterial.MaterialLevel =
      this.normalizeManualMaterialLevel(this.currentState.settings.manualMaterialLevel);
    if (normalizedManualLevel !== this.currentState.settings.manualMaterialLevel) {
      this.currentState.settings.manualMaterialLevel = normalizedManualLevel;
      return true;
    }

    return false;
  }

  private normalizeManualMaterialLevel(level: hdsMaterial.MaterialLevel): hdsMaterial.MaterialLevel {
    if (this.currentState.capability.availableManualLevels.some(
      (item: hdsMaterial.MaterialLevel) => item === level
    )) {
      return level;
    }

    return this.currentState.capability.recommendedManualLevel;
  }

  private parseMaterialMode(raw: string): NGFVisualEffectsMaterialMode {
    return raw === NGFVisualEffectsMaterialMode.MANUAL
      ? NGFVisualEffectsMaterialMode.MANUAL
      : NGFVisualEffectsMaterialMode.ADAPTIVE;
  }

  private normalizeMaterialMode(mode: NGFVisualEffectsMaterialMode): NGFVisualEffectsMaterialMode {
    return mode === NGFVisualEffectsMaterialMode.MANUAL
      ? NGFVisualEffectsMaterialMode.MANUAL
      : NGFVisualEffectsMaterialMode.ADAPTIVE;
  }

  private parseSystemMaterialPolicy(raw: string): NGFSystemMaterialPolicy {
    if (raw === NGFSystemMaterialPolicy.FORCE_IMMERSIVE) {
      return NGFSystemMaterialPolicy.FORCE_IMMERSIVE;
    }
    if (raw === NGFSystemMaterialPolicy.DISABLED) {
      return NGFSystemMaterialPolicy.DISABLED;
    }
    return NGFSystemMaterialPolicy.AUTO;
  }

  private normalizeSystemMaterialPolicy(policy: NGFSystemMaterialPolicy): NGFSystemMaterialPolicy {
    if (policy === NGFSystemMaterialPolicy.FORCE_IMMERSIVE) {
      return NGFSystemMaterialPolicy.FORCE_IMMERSIVE;
    }
    if (policy === NGFSystemMaterialPolicy.DISABLED) {
      return NGFSystemMaterialPolicy.DISABLED;
    }
    return NGFSystemMaterialPolicy.AUTO;
  }

  private parseSystemMaterialState(raw: number): uiMaterial.MaterialState {
    switch (raw) {
      case uiMaterial.MaterialState.ENABLE:
        return uiMaterial.MaterialState.ENABLE;
      case uiMaterial.MaterialState.DISABLE:
        return uiMaterial.MaterialState.DISABLE;
      default:
        return uiMaterial.MaterialState.DEFAULT;
    }
  }

  private normalizeSystemMaterialState(state: uiMaterial.MaterialState): uiMaterial.MaterialState {
    switch (state) {
      case uiMaterial.MaterialState.ENABLE:
        return uiMaterial.MaterialState.ENABLE;
      case uiMaterial.MaterialState.DISABLE:
        return uiMaterial.MaterialState.DISABLE;
      default:
        return uiMaterial.MaterialState.DEFAULT;
    }
  }

  private parseSystemMaterialType(raw: number): uiMaterial.MaterialType {
    if (raw === uiMaterial.MaterialType.IMMERSIVE) {
      return uiMaterial.MaterialType.IMMERSIVE;
    }
    return DEFAULT_VISUAL_EFFECTS_CAPABILITY.systemMaterialType;
  }

  private normalizeSystemMaterialType(type: uiMaterial.MaterialType): uiMaterial.MaterialType {
    if (type === uiMaterial.MaterialType.IMMERSIVE) {
      return uiMaterial.MaterialType.IMMERSIVE;
    }
    return DEFAULT_VISUAL_EFFECTS_CAPABILITY.systemMaterialType;
  }

  private buildSystemMaterial(
    style: uiMaterial.ImmersiveStyle,
    interactive: boolean,
    enableLightEffect: boolean,
    materialColor: ResourceColor | undefined = undefined
  ): uiMaterial.Material | undefined {
    if (this.currentState.settings.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED) {
      return uiMaterial.Material.empty;
    }
    if (this.currentState.settings.systemMaterialPolicy === NGFSystemMaterialPolicy.FORCE_IMMERSIVE) {
      return this.createImmersiveMaterial(style, interactive, enableLightEffect, materialColor);
    }
    if (this.currentState.capability.systemMaterialState === uiMaterial.MaterialState.DISABLE) {
      return undefined;
    }
    return this.createImmersiveMaterial(style, interactive, enableLightEffect, materialColor);
  }

  private createImmersiveMaterial(
    style: uiMaterial.ImmersiveStyle,
    interactive: boolean,
    enableLightEffect: boolean,
    materialColor: ResourceColor | undefined
  ): uiMaterial.ImmersiveMaterial {
    return new uiMaterial.ImmersiveMaterial(new NGFImmersiveMaterialOptions(
      style,
      interactive,
      enableLightEffect,
      materialColor
    ));
  }

  private parsePersistedMaterialTypes(raw: string): Array<hdsMaterial.MaterialType> {
    const parsedTypes: Array<hdsMaterial.MaterialType> = [];
    if (raw.length === 0) {
      return parsedTypes;
    }

    raw.split(',').forEach((segment: string) => {
      this.appendPersistedMaterialType(segment, parsedTypes);
    });
    return this.normalizeMaterialTypes(parsedTypes);
  }

  private appendPersistedMaterialType(
    rawValue: string,
    target: Array<hdsMaterial.MaterialType>
  ): void {
    const trimmed: string = rawValue.trim();
    if (trimmed.length === 0) {
      return;
    }

    const numericValue: number = Number(trimmed);
    if (Number.isNaN(numericValue)) {
      return;
    }

    switch (numericValue) {
      case hdsMaterial.MaterialType.NONE:
        target.push(hdsMaterial.MaterialType.NONE);
        return;
      case hdsMaterial.MaterialType.ADAPTIVE:
        target.push(hdsMaterial.MaterialType.ADAPTIVE);
        return;
      case hdsMaterial.MaterialType.IMMERSIVE:
        target.push(hdsMaterial.MaterialType.IMMERSIVE);
        return;
      default:
        return;
    }
  }

  private serializeMaterialTypes(types: Array<hdsMaterial.MaterialType>): string {
    return types.map((type: hdsMaterial.MaterialType) => String(type)).join(',');
  }

  private parseMaterialLevel(raw: number): hdsMaterial.MaterialLevel {
    switch (raw) {
      case hdsMaterial.MaterialLevel.EXQUISITE:
        return hdsMaterial.MaterialLevel.EXQUISITE;
      case hdsMaterial.MaterialLevel.GENTLE:
        return hdsMaterial.MaterialLevel.GENTLE;
      case hdsMaterial.MaterialLevel.SMOOTH:
        return hdsMaterial.MaterialLevel.SMOOTH;
      case hdsMaterial.MaterialLevel.ADAPTIVE:
        return hdsMaterial.MaterialLevel.ADAPTIVE;
      default:
        return DEFAULT_VISUAL_EFFECTS_SETTINGS.manualMaterialLevel;
    }
  }

  private recalculateEffectiveMaterialLevel(): void {
    if (this.currentState.settings.materialMode === NGFVisualEffectsMaterialMode.ADAPTIVE) {
      this.currentState.effectiveMaterialLevel = hdsMaterial.MaterialLevel.ADAPTIVE;
      return;
    }

    this.currentState.effectiveMaterialLevel = this.normalizeManualMaterialLevel(
      this.currentState.settings.manualMaterialLevel
    );
  }

  private async persistSettings(): Promise<void> {
    await this.settingsManager.setString(
      NGFVisualEffectsSettingKeys.VISUAL_EFFECTS_MATERIAL_MODE,
      this.currentState.settings.materialMode
    );
    await this.settingsManager.setNumber(
      NGFVisualEffectsSettingKeys.VISUAL_EFFECTS_MANUAL_MATERIAL_LEVEL,
      this.currentState.settings.manualMaterialLevel
    );
    await this.settingsManager.setString(
      NGFVisualEffectsSettingKeys.VISUAL_EFFECTS_SYSTEM_MATERIAL_POLICY,
      this.currentState.settings.systemMaterialPolicy
    );
  }

  private async persistCapability(): Promise<void> {
    await this.settingsManager.setString(
      NGFVisualEffectsSettingKeys.VISUAL_EFFECTS_SUPPORTED_MATERIAL_TYPES,
      this.serializeMaterialTypes(this.currentState.capability.supportedMaterialTypes)
    );
    await this.settingsManager.setNumber(
      NGFVisualEffectsSettingKeys.VISUAL_EFFECTS_SYSTEM_MATERIAL_STATE,
      this.currentState.capability.systemMaterialState
    );
    await this.settingsManager.setNumber(
      NGFVisualEffectsSettingKeys.VISUAL_EFFECTS_SYSTEM_MATERIAL_TYPE,
      this.currentState.capability.systemMaterialType
    );
    await this.settingsManager.setNumber(
      NGFVisualEffectsSettingKeys.VISUAL_EFFECTS_CAPABILITY_LAST_CHECKED_AT,
      this.currentState.capability.lastCheckedAt
    );
    await this.settingsManager.setString(
      NGFVisualEffectsSettingKeys.VISUAL_EFFECTS_CAPABILITY_DETECT_ERROR,
      this.currentState.capability.detectError
    );
  }

  private syncStateToAppStorage(): void {
    AppStorage.setOrCreate('ngf_visual_effects_material_mode', this.currentState.settings.materialMode);
    AppStorage.setOrCreate('ngf_visual_effects_manual_material_level', this.currentState.settings.manualMaterialLevel);
    AppStorage.setOrCreate('ngf_visual_effects_system_material_policy', this.currentState.settings.systemMaterialPolicy);
    AppStorage.setOrCreate('ngf_visual_effects_effective_material_level', this.currentState.effectiveMaterialLevel);
    AppStorage.setOrCreate(
      'ngf_visual_effects_supported_material_types',
      JSON.stringify(this.currentState.capability.supportedMaterialTypes)
    );
    AppStorage.setOrCreate(
      'ngf_visual_effects_available_manual_levels',
      JSON.stringify(this.currentState.capability.availableManualLevels)
    );
    AppStorage.setOrCreate('ngf_visual_effects_supports_immersive', this.currentState.capability.supportsImmersiveMaterial);
    AppStorage.setOrCreate('ngf_visual_effects_supports_adaptive', this.currentState.capability.supportsAdaptiveMaterial);
    AppStorage.setOrCreate('ngf_visual_effects_recommended_manual_level', this.currentState.capability.recommendedManualLevel);
    AppStorage.setOrCreate('ngf_visual_effects_system_material_state', this.currentState.capability.systemMaterialState);
    AppStorage.setOrCreate('ngf_visual_effects_system_material_type', this.currentState.capability.systemMaterialType);
    AppStorage.setOrCreate('ngf_visual_effects_capability_last_checked_at', this.currentState.capability.lastCheckedAt);
    AppStorage.setOrCreate('ngf_visual_effects_capability_error', this.currentState.capability.detectError);
    AppStorage.setOrCreate('ngf_visual_effects_should_use_system_material_surface', this.shouldUseSystemMaterialSurface());
  }

  private notifyListeners(): void {
    const snapshot: NGFVisualEffectsState = this.getState();
    this.listeners.forEach((listener: NGFVisualEffectsStateListener) => {
      try {
        listener(snapshot);
      } catch (error) {
        logger.error(TAG, '执行视觉效果监听回调失败', String(error));
      }
    });
  }
}

export const ngfVisualEffectsFacade: NGFVisualEffectsManager = NGFVisualEffectsManager.getInstance();
