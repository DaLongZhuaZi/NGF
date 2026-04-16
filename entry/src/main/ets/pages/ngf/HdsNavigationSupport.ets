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

class NGFHdsNavigationTitle implements HdsNavigationTitle {
  mainTitle: ResourceStr;
  subTitle?: ResourceStr;

  constructor(mainTitle: ResourceStr, subTitle?: ResourceStr) {
    this.mainTitle = mainTitle;
    if (subTitle !== undefined) {
      this.subTitle = subTitle;
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
    this.mainTitleShadowColor = '#1A000000';
    this.subTitleShadowColor = '#12000000';
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

class NGFHdsSystemMaterialParams implements SystemMaterialParams {
  materialType?: hdsMaterial.MaterialType;
  materialLevel?: hdsMaterial.MaterialLevel;

  constructor(materialType: hdsMaterial.MaterialType, materialLevel: hdsMaterial.MaterialLevel) {
    this.materialType = materialType;
    this.materialLevel = materialLevel;
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
    mainTitle: string,
    subTitle: string,
    backgroundColor: string,
    materialLevel: hdsMaterial.MaterialLevel,
    avoidLayoutSafeArea: boolean = false,
    enableComponentSafeArea: boolean = false
  ): HdsNavigationTitleBarOptions {
    const originalTitleStyle = new NGFHdsNavigationTitleStyle('#FFFFFFFF', '#CCFFFFFF');
    const scrollTitleStyle = new NGFHdsNavigationTitleStyle('#FFFFFFFF', '#E6FFFFFF');
    const originalContentStyle = new NGFHdsTitleBarContentStyle(originalTitleStyle);
    const scrollContentStyle = new NGFHdsTitleBarContentStyle(scrollTitleStyle);
    const originalBackgroundStyle = new NGFHdsNavigationBackgroundStyle(backgroundColor, 18);
    const scrollBackgroundStyle = new NGFHdsNavigationBackgroundStyle(backgroundColor, 28);
    const originalBarStyle = new NGFHdsNavigationTitleBarStyle(originalBackgroundStyle, originalContentStyle);
    const scrollBarStyle = new NGFHdsNavigationTitleBarStyle(scrollBackgroundStyle, scrollContentStyle);
    const materialParams = new NGFHdsSystemMaterialParams(hdsMaterial.MaterialType.IMMERSIVE, materialLevel);
    const content = new NGFHdsTitleBarContentOptions(new NGFHdsNavigationTitle(mainTitle, subTitle));
    const style = new NGFHdsTitleBarStyleOptions(originalBarStyle, scrollBarStyle, materialParams);
    return new NGFHdsNavigationTitleBarOptions(content, style, avoidLayoutSafeArea, enableComponentSafeArea);
  }
}
