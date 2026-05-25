import { DualEdgeFlowLightWithMaskParam, hdsEffect, hdsMaterial, SystemMaterialParams } from '@kit.UIDesignKit';

export enum NGFHdsInteractiveEffectPresetKind {
  PRESS_SHADOW = 0,
  POINT_LIGHT = 1,
  COMBINED = 2,
  FLOW_LIGHT_SCENE = 3
}

export class NGFHdsSystemMaterialParams implements SystemMaterialParams {
  materialType?: hdsMaterial.MaterialType;
  materialLevel?: hdsMaterial.MaterialLevel;

  constructor(materialType: hdsMaterial.MaterialType, materialLevel: hdsMaterial.MaterialLevel) {
    this.materialType = materialType;
    this.materialLevel = materialLevel;
  }
}

export class NGFHdsBackgroundEffectOptions implements BackgroundEffectOptions {
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

  getSummary(): string {
    const saturationText = this.saturation === undefined ? '-' : this.saturation.toFixed(2);
    const brightnessText = this.brightness === undefined ? '-' : this.brightness.toFixed(2);
    return `radius ${this.radius} / saturation ${saturationText} / brightness ${brightnessText}`;
  }
}

export class NGFHdsShadowOptions implements ShadowOptions {
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

export class NGFHdsScaleOptions implements ScaleOptions {
  x?: number;
  y?: number;

  constructor(scale: number) {
    this.x = scale;
    this.y = scale;
  }
}

export class NGFHdsTranslateOptions implements TranslateOptions {
  x?: number | string;
  y?: number | string;

  constructor(y: number | string) {
    this.x = 0;
    this.y = y;
  }
}

export class NGFHdsPointLightOptions implements hdsEffect.PointLightOptions {
  color?: ResourceColor;
  intensity?: number;
  height?: Dimension;
  bloom?: number;

  constructor(color: ResourceColor, intensity: number, height: Dimension, bloom: number) {
    this.color = color;
    this.intensity = intensity;
    this.height = height;
    this.bloom = bloom;
  }
}

export class NGFHdsPointLightEffect implements hdsEffect.PointLightEffect {
  sourceType?: hdsEffect.PointLightSourceType;
  illuminatedType?: hdsEffect.PointLightIlluminatedType;
  options?: hdsEffect.PointLightOptions;

  constructor(
    sourceType: hdsEffect.PointLightSourceType,
    illuminatedType: hdsEffect.PointLightIlluminatedType,
    options: hdsEffect.PointLightOptions
  ) {
    this.sourceType = sourceType;
    this.illuminatedType = illuminatedType;
    this.options = options;
  }
}

export class NGFHdsExpectedFrameRateRange implements hdsEffect.ExpectedFrameRateRange {
  expected: hdsEffect.FrameRateType;
  min: hdsEffect.FrameRateType;
  max: hdsEffect.FrameRateType;

  constructor(
    expected: hdsEffect.FrameRateType,
    min: hdsEffect.FrameRateType,
    max: hdsEffect.FrameRateType
  ) {
    this.expected = expected;
    this.min = min;
    this.max = max;
  }
}

export class NGFHdsEdgeFlowLightParam implements hdsEffect.EdgeFlowLightParam {
  startPos: number;
  endPos: number;
  color: ResourceColor;

  constructor(startPos: number, endPos: number, color: ResourceColor) {
    this.startPos = startPos;
    this.endPos = endPos;
    this.color = color;
  }
}

export class NGFHdsDualEdgeFlowLightWithMaskParam implements DualEdgeFlowLightWithMaskParam {
  backgroundMaskColors: Array<ResourceColor>;
  firstEdgeFlowLight: hdsEffect.EdgeFlowLightParam;
  secondEdgeFlowLight: hdsEffect.EdgeFlowLightParam;

  constructor(
    backgroundMaskColors: Array<ResourceColor>,
    firstEdgeFlowLight: hdsEffect.EdgeFlowLightParam,
    secondEdgeFlowLight: hdsEffect.EdgeFlowLightParam
  ) {
    this.backgroundMaskColors = backgroundMaskColors;
    this.firstEdgeFlowLight = firstEdgeFlowLight;
    this.secondEdgeFlowLight = secondEdgeFlowLight;
  }
}

export class NGFHdsPointLightPresetSpec {
  sourceType: hdsEffect.PointLightSourceType;
  illuminatedType: hdsEffect.PointLightIlluminatedType;
  color: ResourceColor;
  intensity: number;
  height: Dimension;
  bloom: number;

  constructor(
    sourceType: hdsEffect.PointLightSourceType,
    illuminatedType: hdsEffect.PointLightIlluminatedType,
    color: ResourceColor,
    intensity: number,
    height: Dimension,
    bloom: number
  ) {
    this.sourceType = sourceType;
    this.illuminatedType = illuminatedType;
    this.color = color;
    this.intensity = intensity;
    this.height = height;
    this.bloom = bloom;
  }

  buildEffect(): hdsEffect.PointLightEffect {
    return new NGFHdsPointLightEffect(
      this.sourceType,
      this.illuminatedType,
      new NGFHdsPointLightOptions(this.color, this.intensity, this.height, this.bloom)
    );
  }

  getSourceTypeLabel(): string {
    if (this.sourceType === hdsEffect.PointLightSourceType.SOFT) {
      return 'SOFT';
    }
    if (this.sourceType === hdsEffect.PointLightSourceType.BRIGHT) {
      return 'BRIGHT';
    }
    return 'NONE';
  }

  getIlluminatedTypeLabel(): string {
    if (this.illuminatedType === hdsEffect.PointLightIlluminatedType.BORDER) {
      return 'BORDER';
    }
    if (this.illuminatedType === hdsEffect.PointLightIlluminatedType.CONTENT) {
      return 'CONTENT';
    }
    if (this.illuminatedType === hdsEffect.PointLightIlluminatedType.BORDER_CONTENT) {
      return 'BORDER_CONTENT';
    }
    if (this.illuminatedType === hdsEffect.PointLightIlluminatedType.DEFAULT_FEATHERING_BORDER) {
      return 'DEFAULT_FEATHERING_BORDER';
    }
    return 'NONE';
  }

  getOptionSummary(): string {
    return `${this.getSourceTypeLabel()} / ${this.getIlluminatedTypeLabel()} / intensity ${this.intensity.toFixed(2)} / height ${this.height} / bloom ${this.bloom.toFixed(2)}`;
  }
}

export class NGFHdsVisualEffectPresetSpec {
  pressShadowType: hdsEffect.PressShadowType;
  pointLight: NGFHdsPointLightPresetSpec | null;

  constructor(pressShadowType: hdsEffect.PressShadowType, pointLight: NGFHdsPointLightPresetSpec | null) {
    this.pressShadowType = pressShadowType;
    this.pointLight = pointLight;
  }

  buildVisualEffect(): VisualEffect {
    const builder = new hdsEffect.HdsEffectBuilder();
    if (this.pressShadowType !== hdsEffect.PressShadowType.NONE) {
      builder.pressShadow(this.pressShadowType);
    }
    if (this.pointLight !== null) {
      builder.pointLight(this.pointLight.buildEffect());
    }
    return builder.buildEffect();
  }

  getPressShadowLabel(): string {
    if (this.pressShadowType === hdsEffect.PressShadowType.BLEND_GRADIENT) {
      return 'BLEND_GRADIENT';
    }
    if (this.pressShadowType === hdsEffect.PressShadowType.BLEND_WHITE) {
      return 'BLEND_WHITE';
    }
    return 'NONE';
  }

  getPointLightSummary(): string {
    if (this.pointLight === null) {
      return 'NONE';
    }
    return this.pointLight.getOptionSummary();
  }
}

export class NGFHdsMaterialSurfacePreset {
  materialParams: SystemMaterialParams;
  backgroundEffect: NGFHdsBackgroundEffectOptions;
  visualEffectPreset: NGFHdsVisualEffectPresetSpec;
  levelLabel: string;
  effectLabel: string;
  titleAlpha: string;
  borderWidth: number;
  borderColor: ResourceColor;
  shadowOptions: NGFHdsShadowOptions;
  scaleOptions: NGFHdsScaleOptions;
  translateOptions: NGFHdsTranslateOptions;

  constructor(
    materialParams: SystemMaterialParams,
    backgroundEffect: NGFHdsBackgroundEffectOptions,
    visualEffectPreset: NGFHdsVisualEffectPresetSpec,
    levelLabel: string,
    effectLabel: string,
    titleAlpha: string,
    borderWidth: number,
    borderColor: ResourceColor,
    shadowOptions: NGFHdsShadowOptions,
    scaleOptions: NGFHdsScaleOptions,
    translateOptions: NGFHdsTranslateOptions
  ) {
    this.materialParams = materialParams;
    this.backgroundEffect = backgroundEffect;
    this.visualEffectPreset = visualEffectPreset;
    this.levelLabel = levelLabel;
    this.effectLabel = effectLabel;
    this.titleAlpha = titleAlpha;
    this.borderWidth = borderWidth;
    this.borderColor = borderColor;
    this.shadowOptions = shadowOptions;
    this.scaleOptions = scaleOptions;
    this.translateOptions = translateOptions;
  }

  buildVisualEffect(): VisualEffect {
    return this.visualEffectPreset.buildVisualEffect();
  }

  getApiSummary(): string {
    return `systemMaterialEffect(IMMERSIVE, ${this.levelLabel}) + backgroundEffect(${this.backgroundEffect.getSummary()})`;
  }
}

export class NGFHdsInteractiveEffectPreset {
  kind: NGFHdsInteractiveEffectPresetKind;
  backgroundEffect: NGFHdsBackgroundEffectOptions;
  visualEffectPreset: NGFHdsVisualEffectPresetSpec;
  apiSummary: string;
  stateText: string;
  borderWidth: number;
  borderColor: ResourceColor;
  shadowOptions: NGFHdsShadowOptions;
  scaleOptions: NGFHdsScaleOptions;
  translateOptions: NGFHdsTranslateOptions;
  contentOpacity: number;

  constructor(
    kind: NGFHdsInteractiveEffectPresetKind,
    backgroundEffect: NGFHdsBackgroundEffectOptions,
    visualEffectPreset: NGFHdsVisualEffectPresetSpec,
    apiSummary: string,
    stateText: string,
    borderWidth: number,
    borderColor: ResourceColor,
    shadowOptions: NGFHdsShadowOptions,
    scaleOptions: NGFHdsScaleOptions,
    translateOptions: NGFHdsTranslateOptions,
    contentOpacity: number
  ) {
    this.kind = kind;
    this.backgroundEffect = backgroundEffect;
    this.visualEffectPreset = visualEffectPreset;
    this.apiSummary = apiSummary;
    this.stateText = stateText;
    this.borderWidth = borderWidth;
    this.borderColor = borderColor;
    this.shadowOptions = shadowOptions;
    this.scaleOptions = scaleOptions;
    this.translateOptions = translateOptions;
    this.contentOpacity = contentOpacity;
  }

  buildVisualEffect(): VisualEffect {
    return this.visualEffectPreset.buildVisualEffect();
  }
}

export class NGFHdsSceneFlowPreset {
  sceneParams: DualEdgeFlowLightWithMaskParam;
  frameRateRange: hdsEffect.ExpectedFrameRateRange;
  apiSummary: string;
  stateText: string;
  borderWidth: number;
  borderColor: ResourceColor;
  shadowOptions: NGFHdsShadowOptions;
  scaleOptions: NGFHdsScaleOptions;
  translateOptions: NGFHdsTranslateOptions;
  visualOpacity: number;

  constructor(
    sceneParams: DualEdgeFlowLightWithMaskParam,
    frameRateRange: hdsEffect.ExpectedFrameRateRange,
    apiSummary: string,
    stateText: string,
    borderWidth: number,
    borderColor: ResourceColor,
    shadowOptions: NGFHdsShadowOptions,
    scaleOptions: NGFHdsScaleOptions,
    translateOptions: NGFHdsTranslateOptions,
    visualOpacity: number
  ) {
    this.sceneParams = sceneParams;
    this.frameRateRange = frameRateRange;
    this.apiSummary = apiSummary;
    this.stateText = stateText;
    this.borderWidth = borderWidth;
    this.borderColor = borderColor;
    this.shadowOptions = shadowOptions;
    this.scaleOptions = scaleOptions;
    this.translateOptions = translateOptions;
    this.visualOpacity = visualOpacity;
  }
}

export class NGFHdsEffectPresetFactory {
  static buildSystemMaterialParams(
    materialType: hdsMaterial.MaterialType,
    materialLevel: hdsMaterial.MaterialLevel
  ): SystemMaterialParams {
    return new NGFHdsSystemMaterialParams(materialType, materialLevel);
  }

  static buildPrimaryCardEffect(): VisualEffect {
    const pointLight = new NGFHdsPointLightPresetSpec(
      hdsEffect.PointLightSourceType.SOFT,
      hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
      '#E6FFFFFF',
      0.34,
      30,
      0.28
    );
    return new NGFHdsVisualEffectPresetSpec(
      hdsEffect.PressShadowType.BLEND_GRADIENT,
      pointLight
    ).buildVisualEffect();
  }

  static buildAccentCardEffect(): VisualEffect {
    const pointLight = new NGFHdsPointLightPresetSpec(
      hdsEffect.PointLightSourceType.BRIGHT,
      hdsEffect.PointLightIlluminatedType.BORDER,
      '#CCFFFFFF',
      0.24,
      26,
      0.18
    );
    return new NGFHdsVisualEffectPresetSpec(
      hdsEffect.PressShadowType.BLEND_WHITE,
      pointLight
    ).buildVisualEffect();
  }

  static buildMaterialSurfacePreset(level: hdsMaterial.MaterialLevel, pressed: boolean): NGFHdsMaterialSurfacePreset {
    if (level === hdsMaterial.MaterialLevel.GENTLE) {
      const pointLight = new NGFHdsPointLightPresetSpec(
        hdsEffect.PointLightSourceType.SOFT,
        hdsEffect.PointLightIlluminatedType.BORDER,
        '#D9FFFFFF',
        pressed ? 0.24 : 0.16,
        pressed ? 24 : 20,
        pressed ? 0.16 : 0.08
      );
      return new NGFHdsMaterialSurfacePreset(
        NGFHdsEffectPresetFactory.buildSystemMaterialParams(hdsMaterial.MaterialType.IMMERSIVE, hdsMaterial.MaterialLevel.GENTLE),
        new NGFHdsBackgroundEffectOptions(16, 1.08, 1.02, '#1CFFFFFF'),
        new NGFHdsVisualEffectPresetSpec(hdsEffect.PressShadowType.NONE, pointLight),
        'GENTLE',
        '柔光边框 / 无按压阴影',
        pressed ? '77' : '55',
        pressed ? 1.5 : 1,
        pressed ? '#46FFFFFF' : '#24FFFFFF',
        new NGFHdsShadowOptions(pressed ? 10 : 7, '#140F172A', 0, pressed ? 3 : 5),
        new NGFHdsScaleOptions(1),
        new NGFHdsTranslateOptions(0)
      );
    }
    if (level === hdsMaterial.MaterialLevel.EXQUISITE) {
      const pointLight = new NGFHdsPointLightPresetSpec(
        hdsEffect.PointLightSourceType.BRIGHT,
        hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
        '#F8FFFFFF',
        pressed ? 0.64 : 0.50,
        pressed ? 46 : 40,
        pressed ? 0.52 : 0.40
      );
      return new NGFHdsMaterialSurfacePreset(
        NGFHdsEffectPresetFactory.buildSystemMaterialParams(hdsMaterial.MaterialType.IMMERSIVE, hdsMaterial.MaterialLevel.EXQUISITE),
        new NGFHdsBackgroundEffectOptions(46, 1.32, 1.08, '#42FFFFFF'),
        new NGFHdsVisualEffectPresetSpec(hdsEffect.PressShadowType.BLEND_WHITE, pointLight),
        'EXQUISITE',
        '强点光 / 白色混合阴影 / 高辉光',
        pressed ? 'EE' : 'CC',
        pressed ? 2.5 : 2,
        pressed ? '#76FFFFFF' : '#44FFFFFF',
        new NGFHdsShadowOptions(pressed ? 16 : 30, pressed ? '#4234D399' : '#420F172A', 0, pressed ? 5 : 16),
        new NGFHdsScaleOptions(pressed ? 0.97 : 1),
        new NGFHdsTranslateOptions(pressed ? 3 : 0)
      );
    }
    const pointLight = new NGFHdsPointLightPresetSpec(
      hdsEffect.PointLightSourceType.SOFT,
      hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
      '#F0FFFFFF',
      pressed ? 0.42 : 0.32,
      pressed ? 34 : 30,
      pressed ? 0.34 : 0.24
    );
    return new NGFHdsMaterialSurfacePreset(
      NGFHdsEffectPresetFactory.buildSystemMaterialParams(hdsMaterial.MaterialType.IMMERSIVE, hdsMaterial.MaterialLevel.SMOOTH),
      new NGFHdsBackgroundEffectOptions(30, 1.18, 1.05, '#2FFFFFFF'),
      new NGFHdsVisualEffectPresetSpec(hdsEffect.PressShadowType.BLEND_GRADIENT, pointLight),
      'SMOOTH',
      '柔点光 / 渐变按压阴影 / 中等毛玻璃',
      pressed ? 'BB' : '99',
      pressed ? 2 : 1.5,
      pressed ? '#60FFFFFF' : '#32FFFFFF',
      new NGFHdsShadowOptions(pressed ? 12 : 18, pressed ? '#263B82F6' : '#260F172A', 0, pressed ? 4 : 10),
      new NGFHdsScaleOptions(pressed ? 0.985 : 1),
      new NGFHdsTranslateOptions(pressed ? 2 : 0)
    );
  }

  static buildMaterialVisualEffectByLevel(level: hdsMaterial.MaterialLevel, pressed: boolean = false): VisualEffect {
    return NGFHdsEffectPresetFactory.buildMaterialSurfacePreset(level, pressed).buildVisualEffect();
  }

  static buildGentleMaterialSurfacePreset(pressed: boolean = false): NGFHdsMaterialSurfacePreset {
    return NGFHdsEffectPresetFactory.buildMaterialSurfacePreset(hdsMaterial.MaterialLevel.GENTLE, pressed);
  }

  static buildSmoothMaterialSurfacePreset(pressed: boolean = false): NGFHdsMaterialSurfacePreset {
    return NGFHdsEffectPresetFactory.buildMaterialSurfacePreset(hdsMaterial.MaterialLevel.SMOOTH, pressed);
  }

  static buildExquisiteMaterialSurfacePreset(pressed: boolean = false): NGFHdsMaterialSurfacePreset {
    return NGFHdsEffectPresetFactory.buildMaterialSurfacePreset(hdsMaterial.MaterialLevel.EXQUISITE, pressed);
  }

  static buildInteractiveEffectPreset(
    kind: NGFHdsInteractiveEffectPresetKind,
    pressed: boolean
  ): NGFHdsInteractiveEffectPreset {
    if (kind === NGFHdsInteractiveEffectPresetKind.PRESS_SHADOW) {
      return NGFHdsEffectPresetFactory.buildPressShadowPreset(pressed);
    }
    if (kind === NGFHdsInteractiveEffectPresetKind.POINT_LIGHT) {
      return NGFHdsEffectPresetFactory.buildPointLightPreset(pressed);
    }
    if (kind === NGFHdsInteractiveEffectPresetKind.FLOW_LIGHT_SCENE) {
      return NGFHdsEffectPresetFactory.buildFlowLightSurfacePreset(pressed);
    }
    return NGFHdsEffectPresetFactory.buildCombinedPreset(pressed);
  }

  static buildPressShadowPreset(pressed: boolean = false): NGFHdsInteractiveEffectPreset {
    return new NGFHdsInteractiveEffectPreset(
      NGFHdsInteractiveEffectPresetKind.PRESS_SHADOW,
      new NGFHdsBackgroundEffectOptions(pressed ? 28 : 6, pressed ? 1.20 : 1.04, pressed ? 1.06 : 1.00, pressed ? '#303B82F6' : '#0FFFFFFF'),
      new NGFHdsVisualEffectPresetSpec(hdsEffect.PressShadowType.BLEND_GRADIENT, null),
      'pressShadow(BLEND_GRADIENT)，不叠加 pointLight',
      pressed ? '预览态：容器同步下沉；真实 pressShadow 请按住卡片观察' : '未按下：保留普通外投影',
      pressed ? 4 : 1,
      pressed ? '#F8FAFF' : '#24FFFFFF',
      new NGFHdsShadowOptions(pressed ? 44 : 18, pressed ? '#883B82F6' : '#260F172A', 0, pressed ? 16 : 10),
      new NGFHdsScaleOptions(pressed ? 0.92 : 1),
      new NGFHdsTranslateOptions(pressed ? 8 : 0),
      pressed ? 0.96 : 1
    );
  }

  static buildPointLightPreset(pressed: boolean = false): NGFHdsInteractiveEffectPreset {
    const pointLight = new NGFHdsPointLightPresetSpec(
      pressed ? hdsEffect.PointLightSourceType.BRIGHT : hdsEffect.PointLightSourceType.SOFT,
      pressed ? hdsEffect.PointLightIlluminatedType.DEFAULT_FEATHERING_BORDER : hdsEffect.PointLightIlluminatedType.BORDER,
      '#F6FFFFFF',
      pressed ? 0.62 : 0.26,
      pressed ? 42 : 26,
      pressed ? 0.48 : 0.16
    );
    return new NGFHdsInteractiveEffectPreset(
      NGFHdsInteractiveEffectPresetKind.POINT_LIGHT,
      new NGFHdsBackgroundEffectOptions(pressed ? 40 : 12, pressed ? 1.34 : 1.08, pressed ? 1.12 : 1.02, pressed ? '#36FFFFFF' : '#16FFFFFF'),
      new NGFHdsVisualEffectPresetSpec(hdsEffect.PressShadowType.NONE, pointLight),
      `pointLight(${pointLight.getOptionSummary()})，不使用 pressShadow`,
      pressed ? '已激活：点光扩大、边框羽化高亮' : '未激活：柔和边框光',
      pressed ? 5 : 1,
      pressed ? '#FFFFFFFF' : '#30FFFFFF',
      new NGFHdsShadowOptions(pressed ? 64 : 12, pressed ? '#A8A78BFA' : '#220F172A', 0, pressed ? 0 : 6),
      new NGFHdsScaleOptions(pressed ? 1.045 : 1),
      new NGFHdsTranslateOptions(0),
      pressed ? 1 : 0.9
    );
  }

  static buildFlowLightSurfacePreset(pressed: boolean = false): NGFHdsInteractiveEffectPreset {
    const pointLight = new NGFHdsPointLightPresetSpec(
      pressed ? hdsEffect.PointLightSourceType.BRIGHT : hdsEffect.PointLightSourceType.SOFT,
      hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
      '#EFFFFFFF',
      pressed ? 0.44 : 0.22,
      pressed ? 36 : 24,
      pressed ? 0.34 : 0.14
    );
    return new NGFHdsInteractiveEffectPreset(
      NGFHdsInteractiveEffectPresetKind.FLOW_LIGHT_SCENE,
      new NGFHdsBackgroundEffectOptions(pressed ? 36 : 18, pressed ? 1.26 : 1.10, pressed ? 1.10 : 1.02, pressed ? '#2C22D3EE' : '#140F172A'),
      new NGFHdsVisualEffectPresetSpec(hdsEffect.PressShadowType.NONE, pointLight),
      `HdsVisualComponent.scene(DUAL_EDGE_FLOW_LIGHT_WITH_BACKGROUND_MASK) + pointLight(${pointLight.getOptionSummary()})`,
      pressed ? '已启动：双边流光场景正在播放' : '待启动：流光组件保持低亮预览',
      pressed ? 4 : 1,
      pressed ? '#BFF7FF' : '#28FFFFFF',
      new NGFHdsShadowOptions(pressed ? 58 : 18, pressed ? '#7822D3EE' : '#240F172A', 0, pressed ? 8 : 10),
      new NGFHdsScaleOptions(pressed ? 1.018 : 1),
      new NGFHdsTranslateOptions(0),
      pressed ? 1 : 0.9
    );
  }

  static buildFlowLightScenePreset(active: boolean = false): NGFHdsSceneFlowPreset {
    const backgroundMaskColors: Array<ResourceColor> = new Array<ResourceColor>();
    if (active) {
      backgroundMaskColors.push('#4814B8A6');
      backgroundMaskColors.push('#3822D3EE');
      backgroundMaskColors.push('#180F172A');
    } else {
      backgroundMaskColors.push('#2014B8A6');
      backgroundMaskColors.push('#1822D3EE');
      backgroundMaskColors.push('#100F172A');
    }

    const firstEdgeFlowLight = new NGFHdsEdgeFlowLightParam(
      active ? 0.02 : 0.08,
      active ? 0.36 : 0.24,
      active ? '#F0FEFFFF' : '#90D9FBFF'
    );
    const secondEdgeFlowLight = new NGFHdsEdgeFlowLightParam(
      active ? 0.54 : 0.62,
      active ? 0.92 : 0.82,
      active ? '#F034D399' : '#9034D399'
    );

    return new NGFHdsSceneFlowPreset(
      new NGFHdsDualEdgeFlowLightWithMaskParam(backgroundMaskColors, firstEdgeFlowLight, secondEdgeFlowLight),
      new NGFHdsExpectedFrameRateRange(
        active ? hdsEffect.FrameRateType.FRAME_RATE_60 : hdsEffect.FrameRateType.FRAME_RATE_30,
        hdsEffect.FrameRateType.FRAME_RATE_30,
        hdsEffect.FrameRateType.FRAME_RATE_60
      ),
      'HdsVisualComponent.scene(HdsSceneType.DUAL_EDGE_FLOW_LIGHT_WITH_BACKGROUND_MASK)',
      active ? '双边流光 + 背景遮罩：已使用 60fps 预期帧率播放' : '双边流光 + 背景遮罩：低亮待启动',
      active ? 4 : 1,
      active ? '#BFF7FF' : '#28FFFFFF',
      new NGFHdsShadowOptions(active ? 62 : 18, active ? '#7422D3EE' : '#240F172A', 0, active ? 6 : 10),
      new NGFHdsScaleOptions(active ? 1.018 : 1),
      new NGFHdsTranslateOptions(0),
      active ? 1 : 0.45
    );
  }

  static buildCombinedPreset(pressed: boolean = false): NGFHdsInteractiveEffectPreset {
    const pointLight = new NGFHdsPointLightPresetSpec(
      pressed ? hdsEffect.PointLightSourceType.BRIGHT : hdsEffect.PointLightSourceType.SOFT,
      hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
      '#F5FFFFFF',
      pressed ? 0.58 : 0.30,
      pressed ? 44 : 30,
      pressed ? 0.46 : 0.22
    );
    return new NGFHdsInteractiveEffectPreset(
      NGFHdsInteractiveEffectPresetKind.COMBINED,
      new NGFHdsBackgroundEffectOptions(pressed ? 38 : 24, pressed ? 1.28 : 1.16, pressed ? 1.08 : 1.04, '#32FFFFFF'),
      new NGFHdsVisualEffectPresetSpec(hdsEffect.PressShadowType.BLEND_WHITE, pointLight),
      `pressShadow(BLEND_WHITE) + pointLight(${pointLight.getOptionSummary()})`,
      pressed ? '已激活：阴影、点光、内容亮度同步增强' : '未激活：组合效果待触发',
      pressed ? 4 : 1,
      pressed ? '#B7F8D2' : '#2EFFFFFF',
      new NGFHdsShadowOptions(pressed ? 58 : 24, pressed ? '#8834D399' : '#320F172A', 0, pressed ? 8 : 14),
      new NGFHdsScaleOptions(pressed ? 1.025 : 1),
      new NGFHdsTranslateOptions(pressed ? -2 : 0),
      pressed ? 1 : 0.95
    );
  }
}
