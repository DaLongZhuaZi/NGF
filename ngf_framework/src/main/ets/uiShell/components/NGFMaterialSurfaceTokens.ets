import uiMaterial from '@ohos.arkui.uiMaterial';
import { NGFSystemMaterialPolicy } from '../../deviceAwareness/contracts/IVisualEffectsManager';

const NGF_SYSTEM_MATERIAL_POLICY_KEY: string = 'ngf_visual_effects_system_material_policy';
const NGF_SYSTEM_MATERIAL_STATE_KEY: string = 'ngf_visual_effects_system_material_state';

export class NGFMaterialBackgroundEffectOptions implements BackgroundEffectOptions {
  radius: number;
  saturation?: number;
  brightness?: number;
  color?: ResourceColor;
  adaptiveColor?: AdaptiveColor;

  constructor(radius: number, saturation: number, brightness: number, color: ResourceColor) {
    this.radius = radius;
    this.saturation = saturation;
    this.brightness = brightness;
    this.color = color;
    this.adaptiveColor = AdaptiveColor.DEFAULT;
  }
}

export class NGFMaterialShadowOptions implements ShadowOptions {
  radius: number | Resource;
  color?: Color | string | Resource | ColoringStrategy;
  offsetX?: number | Resource;
  offsetY?: number | Resource;

  constructor(
    radius: number | Resource,
    color: Color | string | Resource | ColoringStrategy,
    offsetX: number | Resource,
    offsetY: number | Resource
  ) {
    this.radius = radius;
    this.color = color;
    this.offsetX = offsetX;
    this.offsetY = offsetY;
  }
}

export class NGFMaterialSheetOptions implements SheetOptions {
  preferType: SheetType = SheetType.BOTTOM;
  detents: [SheetSize, SheetSize] = [SheetSize.LARGE, SheetSize.MEDIUM];
  dragBar: boolean = true;
  showClose: boolean | Resource = false;
  blurStyle: BlurStyle = BlurStyle.NONE;
  maskColor: ResourceColor = '#66000000';
  backgroundColor: ResourceColor;
  keyboardAvoidMode: SheetKeyboardAvoidMode = SheetKeyboardAvoidMode.RESIZE_ONLY;
  systemMaterial?: uiMaterial.Material;

  constructor(systemMaterial: uiMaterial.Material | undefined, useTransparentMaterialSurface: boolean) {
    this.backgroundColor = useTransparentMaterialSurface ? Color.Transparent : $r('app.color.panel_background');
    if (systemMaterial !== undefined) {
      this.systemMaterial = systemMaterial;
    }
  }
}

export class NGFMaterialSurfaceTokens {
  private static readonly GLASS_BG_EFFECT: string = '#10FFFFFF';
  private static readonly GLASS_BG_EFFECT_STRONG: string = '#1AFFFFFF';
  private static readonly GLASS_BG_EFFECT_LIGHT: string = '#14FFFFFF';
  private static readonly CARD_SHADOW_LIGHT: string = '#24000000';
  private static readonly CARD_SHADOW_DEMO: string = '#180F172A';

  static readonly PROMINENT_RADIUS: number = 24;
  static readonly PANEL_RADIUS: number = 18;
  static readonly CONTROL_RADIUS: number = 16;
  static readonly SHEET_RADIUS: number = 28;
  static readonly BORDER_WIDTH: number = 1;

  static shouldUseSystemMaterialSurface(useSystemMaterial?: boolean): boolean {
    if (useSystemMaterial !== undefined) {
      return useSystemMaterial;
    }
    const policy: string | undefined = AppStorage.get<string>(NGF_SYSTEM_MATERIAL_POLICY_KEY);
    if (policy === NGFSystemMaterialPolicy.DISABLED) {
      return false;
    }
    if (policy === NGFSystemMaterialPolicy.FORCE_IMMERSIVE) {
      return true;
    }

    const state: number | undefined = AppStorage.get<number>(NGF_SYSTEM_MATERIAL_STATE_KEY);
    if (state === undefined) {
      return true;
    }
    return state !== uiMaterial.MaterialState.DISABLE;
  }

  static buildMaterialAwareSurfaceBackground(fallback: ResourceColor, useSystemMaterial?: boolean): ResourceColor {
    return NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface(useSystemMaterial) ? Color.Transparent : fallback;
  }

  static buildMaterialAwareBorderColor(fallback: ResourceColor, useSystemMaterial?: boolean): ResourceColor {
    return NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface(useSystemMaterial) ? Color.Transparent : fallback;
  }

  static buildMaterialAwareBorderWidth(fallback: number, useSystemMaterial?: boolean): number {
    return NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface(useSystemMaterial) ? 0 : fallback;
  }

  static buildMaterialAwareProminentBackgroundEffect(useSystemMaterial?: boolean): NGFMaterialBackgroundEffectOptions | undefined {
    if (NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface(useSystemMaterial)) {
      return undefined;
    }
    return NGFMaterialSurfaceTokens.buildProminentBackgroundEffect();
  }

  static buildMaterialAwarePanelBackgroundEffect(useSystemMaterial?: boolean): NGFMaterialBackgroundEffectOptions | undefined {
    if (NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface(useSystemMaterial)) {
      return undefined;
    }
    return NGFMaterialSurfaceTokens.buildPanelBackgroundEffect();
  }

  static buildMaterialAwareControlBackgroundEffect(useSystemMaterial?: boolean): NGFMaterialBackgroundEffectOptions | undefined {
    if (NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface(useSystemMaterial)) {
      return undefined;
    }
    return NGFMaterialSurfaceTokens.buildControlBackgroundEffect();
  }

  static buildMaterialAwareSheetBackgroundEffect(useSystemMaterial?: boolean): NGFMaterialBackgroundEffectOptions | undefined {
    if (NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface(useSystemMaterial)) {
      return undefined;
    }
    return NGFMaterialSurfaceTokens.buildSheetBackgroundEffect();
  }

  static buildMaterialAwareProminentShadow(useSystemMaterial?: boolean): NGFMaterialShadowOptions | undefined {
    if (NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface(useSystemMaterial)) {
      return undefined;
    }
    return NGFMaterialSurfaceTokens.buildProminentShadow();
  }

  static buildMaterialAwarePanelShadow(useSystemMaterial?: boolean): NGFMaterialShadowOptions | undefined {
    if (NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface(useSystemMaterial)) {
      return undefined;
    }
    return NGFMaterialSurfaceTokens.buildPanelShadow();
  }

  static buildMaterialAwareControlShadow(useSystemMaterial?: boolean): NGFMaterialShadowOptions | undefined {
    if (NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface(useSystemMaterial)) {
      return undefined;
    }
    return NGFMaterialSurfaceTokens.buildControlShadow();
  }

  static buildProminentBackgroundEffect(): NGFMaterialBackgroundEffectOptions {
    return new NGFMaterialBackgroundEffectOptions(44, 1.30, 1.07, NGFMaterialSurfaceTokens.GLASS_BG_EFFECT_STRONG);
  }

  static buildPanelBackgroundEffect(): NGFMaterialBackgroundEffectOptions {
    return new NGFMaterialBackgroundEffectOptions(32, 1.24, 1.05, NGFMaterialSurfaceTokens.GLASS_BG_EFFECT);
  }

  static buildControlBackgroundEffect(): NGFMaterialBackgroundEffectOptions {
    return new NGFMaterialBackgroundEffectOptions(22, 1.18, 1.04, NGFMaterialSurfaceTokens.GLASS_BG_EFFECT_LIGHT);
  }

  static buildSheetBackgroundEffect(): NGFMaterialBackgroundEffectOptions {
    return new NGFMaterialBackgroundEffectOptions(40, 1.28, 1.06, NGFMaterialSurfaceTokens.GLASS_BG_EFFECT);
  }

  static buildProminentShadow(): NGFMaterialShadowOptions {
    return new NGFMaterialShadowOptions(18, NGFMaterialSurfaceTokens.CARD_SHADOW_LIGHT, 0, 12);
  }

  static buildPanelShadow(): NGFMaterialShadowOptions {
    return new NGFMaterialShadowOptions(12, NGFMaterialSurfaceTokens.CARD_SHADOW_DEMO, 0, 6);
  }

  static buildControlShadow(): NGFMaterialShadowOptions {
    return new NGFMaterialShadowOptions(8, NGFMaterialSurfaceTokens.CARD_SHADOW_LIGHT, 0, 4);
  }
}
