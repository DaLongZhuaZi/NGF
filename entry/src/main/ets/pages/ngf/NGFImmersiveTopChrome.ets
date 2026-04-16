import { hdsEffect } from '@kit.UIDesignKit';

export class NGFImmersiveTopChromeMetrics {
  underlayHeight: number;
  contentTopInset: number;

  constructor(underlayHeight: number, contentTopInset: number) {
    this.underlayHeight = underlayHeight;
    this.contentTopInset = contentTopInset;
  }
}

export class NGFImmersiveTopChromeSpec {
  metrics: NGFImmersiveTopChromeMetrics;
  gradientStart: string;
  gradientMid: string;
  gradientEnd: string;
  primaryGlowColor: string;
  secondaryGlowColor: string;
  lineColor: string;
  maskColor: string;
  effectRadius: number;
  effectSaturation: number;
  effectBrightness: number;

  constructor(
    metrics: NGFImmersiveTopChromeMetrics,
    gradientStart: string,
    gradientMid: string,
    gradientEnd: string,
    primaryGlowColor: string,
    secondaryGlowColor: string,
    lineColor: string,
    maskColor: string,
    effectRadius: number,
    effectSaturation: number,
    effectBrightness: number
  ) {
    this.metrics = metrics;
    this.gradientStart = gradientStart;
    this.gradientMid = gradientMid;
    this.gradientEnd = gradientEnd;
    this.primaryGlowColor = primaryGlowColor;
    this.secondaryGlowColor = secondaryGlowColor;
    this.lineColor = lineColor;
    this.maskColor = maskColor;
    this.effectRadius = effectRadius;
    this.effectSaturation = effectSaturation;
    this.effectBrightness = effectBrightness;
  }
}

class NGFImmersiveTopChromePointLightOptions implements hdsEffect.PointLightOptions {
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

class NGFImmersiveTopChromePointLightEffect implements hdsEffect.PointLightEffect {
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

class NGFImmersiveTopChromeBackgroundEffectOptions implements BackgroundEffectOptions {
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

class NGFImmersiveTopChromeEffectFactory {
  static build(spec: NGFImmersiveTopChromeSpec): VisualEffect {
    const pointLightOptions = new NGFImmersiveTopChromePointLightOptions('#EAFFFFFF', 0.32, 30, 0.22);
    const pointLightEffect = new NGFImmersiveTopChromePointLightEffect(
      hdsEffect.PointLightSourceType.SOFT,
      hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
      pointLightOptions
    );
    return new hdsEffect.HdsEffectBuilder()
      .pointLight(pointLightEffect)
      .buildEffect();
  }
}

export class NGFImmersiveTopChromePresetFactory {
  static build(
    gradientStart: string,
    gradientMid: string,
    gradientEnd: string,
    primaryGlowColor: string,
    secondaryGlowColor: string,
    underlayHeight: number = 168,
    contentTopInset: number = 92
  ): NGFImmersiveTopChromeSpec {
    return new NGFImmersiveTopChromeSpec(
      new NGFImmersiveTopChromeMetrics(underlayHeight, contentTopInset),
      gradientStart,
      gradientMid,
      gradientEnd,
      primaryGlowColor,
      secondaryGlowColor,
      '#66FFFFFF',
      '#12FFFFFF',
      38,
      1.22,
      1.04
    );
  }
}

@Component
export struct NGFImmersiveTopChromeUnderlay {
  spec: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
    '#07101E',
    '#0C2341',
    '#0A1626',
    '#2854F0E8',
    '#32A4F2D8'
  );

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {}
        .width('100%')
        .height(this.spec.metrics.underlayHeight)
        .linearGradient({
          angle: 150,
          colors: [
            [this.spec.gradientStart, 0],
            [this.spec.gradientMid, 0.4],
            [this.spec.gradientEnd, 1]
          ]
        })

      Column() {}
        .width(176)
        .height(176)
        .borderRadius(176)
        .backgroundColor(this.spec.primaryGlowColor)
        .opacity(0.22)
        .margin({ left: 192, top: 12 })
        .shadow({ radius: 82, color: '#704A89FF', offsetX: 10, offsetY: 6 })

      Column() {}
        .width(148)
        .height(148)
        .borderRadius(148)
        .backgroundColor(this.spec.secondaryGlowColor)
        .opacity(0.18)
        .margin({ left: 18, top: 28 })
        .shadow({ radius: 74, color: '#6635D5FF', offsetX: -8, offsetY: 8 })

      Column() {}
        .width('86%')
        .height(1)
        .backgroundColor(this.spec.lineColor)
        .opacity(0.52)
        .margin({ left: 16, top: 94 })

      Column() {}
        .width('100%')
        .height(this.spec.metrics.underlayHeight)
        .backgroundEffect(
          new NGFImmersiveTopChromeBackgroundEffectOptions(
            this.spec.effectRadius,
            this.spec.effectSaturation,
            this.spec.effectBrightness,
            this.spec.maskColor
          )
        )
        .visualEffect(NGFImmersiveTopChromeEffectFactory.build(this.spec))
    }
    .width('100%')
    .height(this.spec.metrics.underlayHeight)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}
