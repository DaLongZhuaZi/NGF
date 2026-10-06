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
  /**
   * 是否显示浮窗关闭键。
   *
   * ArkUI 的 `showClose` **默认就是 true**；这里曾显式改成 false，等于**全应用的浮窗都没有关闭键**，
   * 违反工信厅信管函〔2021〕67号 附件2 §2.4：
   * 「关闭按钮只可在左上、右上、中央底部，且最小点击响应区域不能小于44×44dp/pt」——
   * 该条款**预设了关闭按钮存在**；只能拖拽关闭对老年用户尤其不友好。
   * 现恢复 SDK 默认值 true；关闭键的实际位置与尺寸需在设备上复核（见设计文档 §3.10）。
   */
  showClose: boolean | Resource = true;
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

  /**
   * 普通组件是否改用「系统材质」表面。
   *
   * ## 为什么现在**恒为 false**
   *
   * **不再生效**。而这个开关一旦为 true，上面所有 `buildMaterialAware*` 助手就会
   * 把背景 / 边框 / 模糊 / 阴影**全部置空**（返回 `Color.Transparent` 或 `undefined`），
   * 文字直接压在沉浸式渐变上，**对比度反而下降**。
   *
   * 设备端像素实测（模拟器 `127.0.0.1:5555`，densityPixels=2.75）：
   * 深色正文在半透明深蓝底上只有 **1.49 ~ 2.28 : 1**，远低于附件2 §1.3 要求的 4.5:1。
   *
   * 因此普通组件**一律走普通玻璃模糊材质**（`backgroundEffect` + 半透明底色 + 描边 + 阴影）。
   *
   * ## HDS 底栏不受影响
   *
   * 底栏用的是 `barFloatingStyle({ systemMaterialEffect: ... })`，
   * 那是**另一套 API**，不经过本函数，因此仍然保留系统材质。
   *
   * @deprecated 参数保留仅为兼容既有调用点；函数恒返回 false。
   */
  static shouldUseSystemMaterialSurface(useSystemMaterial?: boolean): boolean {
    return false;
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
