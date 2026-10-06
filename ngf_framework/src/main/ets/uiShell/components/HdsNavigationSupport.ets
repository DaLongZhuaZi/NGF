import {
  BlurStrategy,
  hdsMaterial,
  HdsNavigationBackgroundStyle,
  HdsNavigationTitle,
  HdsNavigationTitleBarOptions,
  HdsNavigationTitleBarStyle,
  HdsNavigationTitleStyle,
  HdsTitleBarContentStyle,
  ScrollEffectOptions,
  ScrollEffectType,
  SystemMaterialParams,
  TitleBarContentOptions,
  TitleBarStyleOptions
} from '@kit.UIDesignKit';
import { NGFHdsEffectPresetFactory } from './NGFHdsEffectPresets';

/**
 * 标题栏无障碍配置。
 *
 * 来源：HDS 的 `HdsNavigationTitle`（`@hms.hds.hdsBaseComponent.d.ets`）暴露了
 * `mainTitleAccessibilityText` / `subTitleAccessibilityText`（**@since 6.1.0(23)，即 API 23**）
 * 与 `mainTitleId` / `subTitleId`（**@since 6.0.0(20)，即 API 20**）。
 *
 * 注意：`HdsNavigationTitleBarOptions` **本身没有**无障碍字段，标题无障碍只能经
 * `content.title` 这条路径下发 —— 所以 NGF 必须在 `NGFHdsNavigationTitle` 上补齐，
 * 否则调用方**没有任何办法**给标题提供朗读文本。
 */
export interface NGFHdsTitleBarAccessibilityConfig {
  /** 主标题朗读文本；标题是缩写、纯图标或需要补充语境时必填 */
  mainTitleAccessibilityText?: ResourceStr;
  /** 副标题朗读文本 */
  subTitleAccessibilityText?: ResourceStr;
  /** 主标题组件 ID，供无障碍焦点跳转定位 */
  mainTitleId?: string;
  /** 副标题组件 ID */
  subTitleId?: string;
}

class NGFHdsNavigationTitle implements HdsNavigationTitle {
  mainTitle: ResourceStr;
  subTitle?: ResourceStr;
  mainTitleAccessibilityText?: ResourceStr;
  subTitleAccessibilityText?: ResourceStr;
  mainTitleId?: string;
  subTitleId?: string;

  constructor(mainTitle: ResourceStr, subTitle?: ResourceStr,
    accessibility?: NGFHdsTitleBarAccessibilityConfig) {
    this.mainTitle = mainTitle;
    if (subTitle !== undefined) {
      this.subTitle = subTitle;
    }
    if (accessibility !== undefined) {
      this.mainTitleAccessibilityText = accessibility.mainTitleAccessibilityText;
      this.subTitleAccessibilityText = accessibility.subTitleAccessibilityText;
      this.mainTitleId = accessibility.mainTitleId;
      this.subTitleId = accessibility.subTitleId;
    }
  }
}

class NGFHdsNavigationBackgroundStyle implements HdsNavigationBackgroundStyle {
  backgroundColor?: ResourceColor;
  maskExtraHeight?: number;
  blurRadius?: number;

  constructor(backgroundColor: ResourceColor, blurRadius: number) {
    this.backgroundColor = backgroundColor;
    this.maskExtraHeight = 28;
    this.blurRadius = blurRadius;
  }
}

class NGFHdsNavigationTitleStyle implements HdsNavigationTitleStyle {
  mainTitleColor?: ResourceColor;
  subTitleColor?: ResourceColor;
  mainTitleShadowColor?: ResourceColor;
  subTitleShadowColor?: ResourceColor;

  constructor(mainTitleColor: ResourceColor, subTitleColor: ResourceColor) {
    this.mainTitleColor = mainTitleColor;
    this.subTitleColor = subTitleColor;
    this.mainTitleShadowColor = $r('app.color.circle_shadow_light');
    this.subTitleShadowColor = $r('app.color.card_shadow_light');
  }
}

class NGFHdsTitleBarContentStyle implements HdsTitleBarContentStyle {
  titleStyle?: HdsNavigationTitleStyle;

  constructor(titleStyle: HdsNavigationTitleStyle) {
    this.titleStyle = titleStyle;
  }
}

class NGFHdsNavigationTitleBarStyle implements HdsNavigationTitleBarStyle {
  backgroundStyle?: HdsNavigationBackgroundStyle;
  contentStyle?: HdsTitleBarContentStyle;

  constructor(backgroundStyle: HdsNavigationBackgroundStyle, contentStyle: HdsTitleBarContentStyle) {
    this.backgroundStyle = backgroundStyle;
    this.contentStyle = contentStyle;
  }
}

class NGFHdsScrollEffectOptions implements ScrollEffectOptions {
  enableScrollEffect?: boolean;
  scrollEffectType?: ScrollEffectType;

  constructor(scrollEffectType: ScrollEffectType) {
    this.enableScrollEffect = true;
    this.scrollEffectType = scrollEffectType;
  }
}

class NGFHdsTitleBarStyleOptions implements TitleBarStyleOptions {
  scrollEffectOpts?: ScrollEffectOptions;
  originalStyle?: HdsNavigationTitleBarStyle;
  scrollEffectStyle?: HdsNavigationTitleBarStyle;
  blurStrategy?: BlurStrategy;
  thermoCtrl?: boolean;
  systemMaterialEffect?: SystemMaterialParams;

  constructor(
    originalStyle: HdsNavigationTitleBarStyle,
    scrollEffectStyle: HdsNavigationTitleBarStyle,
    systemMaterialEffect: SystemMaterialParams
  ) {
    this.scrollEffectOpts = new NGFHdsScrollEffectOptions(ScrollEffectType.GRADIENT_BLUR);
    this.originalStyle = originalStyle;
    this.scrollEffectStyle = scrollEffectStyle;
    this.blurStrategy = BlurStrategy.ADAPTIVE;
    this.thermoCtrl = false;
    this.systemMaterialEffect = systemMaterialEffect;
  }
}

class NGFHdsTitleBarContentOptions implements TitleBarContentOptions {
  title?: HdsNavigationTitle;

  constructor(title: HdsNavigationTitle) {
    this.title = title;
  }
}

class NGFHdsNavigationTitleBarOptions implements HdsNavigationTitleBarOptions {
  style?: TitleBarStyleOptions;
  content?: TitleBarContentOptions;
  enableHoverMode?: boolean;
  avoidLayoutSafeArea?: boolean;
  enableComponentSafeArea?: boolean;

  constructor(
    content: TitleBarContentOptions,
    style: TitleBarStyleOptions,
    avoidLayoutSafeArea: boolean,
    enableComponentSafeArea: boolean
  ) {
    this.content = content;
    this.style = style;
    this.enableHoverMode = false;
    this.avoidLayoutSafeArea = avoidLayoutSafeArea;
    this.enableComponentSafeArea = enableComponentSafeArea;
  }
}

export class NGFHdsTitleBarOptionsFactory {
  static build(
    mainTitle: ResourceStr,
    subTitle: ResourceStr,
    backgroundColor: ResourceColor,
    materialLevel: hdsMaterial.MaterialLevel,
    avoidLayoutSafeArea: boolean = false,
    enableComponentSafeArea: boolean = false,
    accessibility?: NGFHdsTitleBarAccessibilityConfig
  ): HdsNavigationTitleBarOptions {
    const originalTitleStyle = new NGFHdsNavigationTitleStyle($r('app.color.text_white'), $r('app.color.glass_chip_overlay'));
    const scrollTitleStyle = new NGFHdsNavigationTitleStyle($r('app.color.text_white'), $r('app.color.text_white_medium'));
    const originalContentStyle = new NGFHdsTitleBarContentStyle(originalTitleStyle);
    const scrollContentStyle = new NGFHdsTitleBarContentStyle(scrollTitleStyle);
    const originalBackgroundStyle = new NGFHdsNavigationBackgroundStyle(backgroundColor, 18);
    const scrollBackgroundStyle = new NGFHdsNavigationBackgroundStyle(backgroundColor, 28);
    const originalBarStyle = new NGFHdsNavigationTitleBarStyle(originalBackgroundStyle, originalContentStyle);
    const scrollBarStyle = new NGFHdsNavigationTitleBarStyle(scrollBackgroundStyle, scrollContentStyle);
    const materialParams = NGFHdsEffectPresetFactory.buildSystemMaterialParams(hdsMaterial.MaterialType.IMMERSIVE, materialLevel);
    // 标题无障碍只能经 content.title 下发，见 NGFHdsTitleBarAccessibilityConfig 的说明
    const content = new NGFHdsTitleBarContentOptions(
      new NGFHdsNavigationTitle(mainTitle, subTitle, accessibility)
    );
    const style = new NGFHdsTitleBarStyleOptions(originalBarStyle, scrollBarStyle, materialParams);
    return new NGFHdsNavigationTitleBarOptions(content, style, avoidLayoutSafeArea, enableComponentSafeArea);
  }
}
