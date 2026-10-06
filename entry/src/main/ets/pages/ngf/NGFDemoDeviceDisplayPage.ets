import {
  NGFAccessibilityBindingListener,
  NGFAccessibilityLifecycleBinding,
  NGFA11yTextScale,
  NGFInclusiveDesignResolved,
  a11yTouchTarget,
  ngfAccessibilityFacade,
  resolveA11yTextScaleForCurrent
} from 'ngf_framework';
import { HdsNavDestination } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import { logger } from 'ngf_framework';
import { NGFControlStyleTokens } from 'ngf_framework';
import { NGFMaterialSurfaceTokens } from 'ngf_framework';
import { ngfVisualEffectsFacade } from 'ngf_framework';
import {
  NGFRelativeTimeResult,
  ngfRelativeTimeFormatterFacade
} from 'ngf_framework';
import {
  NGFCapabilityType,
  NGFCapabilityResult,
  ngfDeviceCapabilityDetectorFacade
} from 'ngf_framework';
import {
  NGFFontScaleLevel,
  ngfFontScaleManagerFacade
} from 'ngf_framework';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from 'ngf_framework';
import { NGFHdsTitleBarOptionsFactory } from 'ngf_framework';
import { NGFPageWindowName, NGFPageWindowSupport } from './NGFPageWindowSupport';

const TAG: string = 'NGFDemoDeviceDisplayPage';

const DEMO_DEVICE_TOP_CHROME: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#0A1A08',
  '#14460D',
  '#081205',
  '#22C55ED8',
  '#86EFACD8',
  160,
  88
);

class NGFDemoCapabilityEntry {
  id: number;
  name: ResourceStr;
  available: boolean;
  detail: string;

  constructor(id: number, name: ResourceStr, available: boolean, detail: string) {
    this.id = id;
    this.name = name;
    this.available = available;
    this.detail = detail;
  }
}

@Component
export struct NGFDemoDeviceDisplayPage {
  /**
   * 适老呈现层（.rules/skill-elderly-ui.md）：字号 / 行高 / 点击区一律经缩放器取。
   * 普通档原样返回（零视觉回归），适老档抬到附件2 §1.1（≥18）与 §1.2（行距 ≥1.3 倍）。
   */
  @State private a11yScale: NGFA11yTextScale = resolveA11yTextScaleForCurrent();
  private a11yBinding: NGFAccessibilityLifecycleBinding | null = null;

  /** 订阅平台策略变化；与 detach 严格成对 */
  private attachA11yBinding(): void {
    if (this.a11yBinding !== null) {
      return;
    }
    const listener: NGFAccessibilityBindingListener = {
      onInclusiveDesignChanged: (resolved: NGFInclusiveDesignResolved): void => {
        this.a11yScale = resolveA11yTextScaleForCurrent();
      }
    };
    this.a11yBinding = new NGFAccessibilityLifecycleBinding(listener);
    this.a11yBinding.attach();
  }

  /** 取消订阅（幂等） */
  private detachA11yBinding(): void {
    const binding: NGFAccessibilityLifecycleBinding | null = this.a11yBinding;
    if (binding !== null) {
      binding.detach();
      this.a11yBinding = null;
    }
  }


  @StorageProp('ngf_visual_effects_should_use_system_material_surface') private useSysMat: boolean = true;
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private topInsetVp: number = 108;
  @State private localeIndexes: Array<number> = [0];
  @State private relativeTimeResults: Array<string> = [];
  @State private capabilities: Array<NGFDemoCapabilityEntry> = [];
  @State private currentFontScale: number = 1.0;
  @State private currentFontLevel: string = 'NORMAL';
  @State private statusMessage: ResourceStr = '';

  private readonly locales: Array<string> = ['zh-CN', 'en-US', 'ja-JP'];
  private readonly localeLabels: Array<ResourceStr> = [$r('app.string.ui_str_2259'), $r('app.string.ui_str_2260')];

  aboutToAppear(): void {
    this.attachA11yBinding();
    NGFPageWindowSupport.loadDynamicTopInset(this.getUIContext(), 108, 108, (inset) => {
      this.topInsetVp = inset;
    });
    NGFPageWindowSupport.apply(NGFPageWindowName.DEMO_DEVICE_DISPLAY);
    this.currentFontScale = ngfFontScaleManagerFacade.getCurrentScale();
    this.currentFontLevel = this.resolveLevelText(ngfFontScaleManagerFacade.getCurrentLevel());
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: DEMO_DEVICE_TOP_CHROME })

        Scroll() {
          Column({ space: this.a11yScale.paragraphSpacing(12, 18) }) {
            this.buildTitleCard()
            this.buildRelativeTimeSection()
            this.buildCapabilitySection()
            this.buildFontScaleSection()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: this.topInsetVp, bottom: 36 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .backgroundColor($r('app.color.background_transparent'))
      }
      .width('100%')
      .height('100%')
    }
    .titleBar(NGFHdsTitleBarOptionsFactory.build(
      $r('app.string.ui_str_2053'),
      $r('app.string.ui_str_2261'),
      '#0A1A08',
      hdsMaterial.MaterialLevel.GENTLE,
      true,
      false
    ))
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .onReady((context: NavDestinationContext): void => {
      this.pathStack = context.pathStack;
    })
    .onBackPressed((): boolean => {
      NGFPageWindowSupport.restoreMainMenu();
      this.pathStack.pop();
      return true;
    })
  }

  aboutToDisappear(): void {
    this.detachA11yBinding();
    NGFPageWindowSupport.restoreMainMenu();
  }

  @Builder
  private buildTitleCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
      Text($r('app.string.ui_str_2262'))
        .fontSize(this.a11yScale.font(22))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(22)))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text($r('app.string.ui_str_2263'))
        .fontSize(this.a11yScale.font(13))
        .lineHeight(this.a11yScale.explicitLineHeight(this.a11yScale.font(13), 20))
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(18)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwareProminentBackgroundEffect(this.useSysMat))
    .borderRadius(NGFMaterialSurfaceTokens.PROMINENT_RADIUS)
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwareProminentShadow(this.useSysMat))
  }

  @Builder
  private buildRelativeTimeSection(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Text($r('app.string.ui_str_2264'))
        .fontSize(this.a11yScale.font(16))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Row({ space: 8 }) {
        ForEach(this.localeLabels, (label: string, index: number) => {
          Button(label)
            .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
            .controlSize(ControlSize.SMALL)
            .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
            .borderRadius(10)
            .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
            .fontColor($r('app.color.text_primary'))
            .onClick((): void => {
              this.localeIndexes = [index];
            })
        })
      }
      .width('100%')

      Row({ space: 8 }) {
        Button($r('app.string.ui_str_2265'))
          .layoutWeight(1)
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE))
          .borderRadius(10)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            this.formatRelativeTime(60 * 1000);
          })
        Button($r('app.string.ui_str_2266'))
          .layoutWeight(1)
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE))
          .borderRadius(10)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            this.formatRelativeTime(60 * 60 * 1000);
          })
        Button($r('app.string.ui_str_2267'))
          .layoutWeight(1)
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE))
          .borderRadius(10)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            this.formatRelativeTime(24 * 60 * 60 * 1000);
          })
        Button($r('app.string.ui_str_2268'))
          .layoutWeight(1)
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE))
          .borderRadius(10)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            this.formatRelativeTime(30 * 24 * 60 * 60 * 1000);
          })
      }
      .width('100%')

      if (this.relativeTimeResults.length > 0) {
        Column({ space: this.a11yScale.paragraphSpacing(4, 18) }) {
          ForEach(this.relativeTimeResults, (text: string, index: number) => {
            Row() {
              Text(String(index + 1) + '.')
                .fontSize(this.a11yScale.font(12))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
                .fontColor($r('app.color.text_muted'))
                .width(24)
              Text(text)
                .fontSize(this.a11yScale.font(13))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
                .fontColor($r('app.color.text_body'))
            }
            .width('100%')
            .padding({ top: 5, bottom: 5, left: 10, right: 10 })
            .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
            .borderRadius(8)
          })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect(this.useSysMat))
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.card_border'), this.useSysMat)
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow(this.useSysMat))
  }

  @Builder
  private buildCapabilitySection(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Text($r('app.string.ui_str_2269'))
        .fontSize(this.a11yScale.font(16))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Button($r('app.string.ui_str_2270'))
        .width('100%')
        .height(NGFControlStyleTokens.FORM_CONTROL_MIN_HEIGHT)
        .controlSize(ControlSize.SMALL)
        .fontSize(this.a11yScale.font(NGFControlStyleTokens.FORM_CONTROL_FONT_SIZE))
        .borderRadius(NGFControlStyleTokens.FORM_CONTROL_RADIUS)
        .fontColor($r('app.color.text_primary'))
        .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
        .onClick((): void => {
          this.handleDetectAll();
        })

      if (this.capabilities.length > 0) {
        Column({ space: this.a11yScale.paragraphSpacing(4, 18) }) {
          ForEach(this.capabilities, (entry: NGFDemoCapabilityEntry) => {
            Row() {
              Column({ space: this.a11yScale.paragraphSpacing(2, 18) }) {
                Text(entry.name)
                  .fontSize(this.a11yScale.font(13))
                  .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
                  .fontColor($r('app.color.text_body'))
                  .fontWeight(FontWeight.Medium)
                Text(entry.detail)
                  .fontSize(this.a11yScale.font(11))
                  .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(11)))
                  .fontColor($r('app.color.text_muted'))
                  .maxLines(2)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text(entry.available ? $r('app.string.ui_str_2271') : $r('app.string.ui_str_2272'))
                .fontSize(this.a11yScale.font(11))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(11)))
                .fontWeight(FontWeight.Medium)
                .fontColor(entry.available ? $r('app.color.tag_green') : $r('app.color.tag_red'))
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
                .borderRadius(8)
            }
            .width('100%')
            .padding({ top: 8, bottom: 8, left: 12, right: 12 })
            .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
            .borderRadius(10)
          }, (entry: NGFDemoCapabilityEntry): string => 'cap_' + entry.id)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect(this.useSysMat))
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.card_border'), this.useSysMat)
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow(this.useSysMat))
  }

  @Builder
  private buildFontScaleSection(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Text($r('app.string.ui_str_2273'))
        .fontSize(this.a11yScale.font(16))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Row({ space: 8 }) {
        Button($r('app.string.ui_str_2274'))
          .layoutWeight(1)
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE))
          .borderRadius(10)
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .fontColor($r('app.color.text_primary'))
          .onClick((): void => {
            ngfFontScaleManagerFacade.setFontScaleLevel(NGFFontScaleLevel.SMALL);
            this.syncFontScale();
          })
        Button($r('app.string.ui_str_2275'))
          .layoutWeight(1)
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE))
          .borderRadius(10)
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .fontColor($r('app.color.text_primary'))
          .onClick((): void => {
            ngfFontScaleManagerFacade.setFontScaleLevel(NGFFontScaleLevel.NORMAL);
            this.syncFontScale();
          })
        Button($r('app.string.ui_str_2276'))
          .layoutWeight(1)
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE))
          .borderRadius(10)
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .fontColor($r('app.color.text_primary'))
          .onClick((): void => {
            ngfFontScaleManagerFacade.setFontScaleLevel(NGFFontScaleLevel.LARGE);
            this.syncFontScale();
          })
        Button($r('app.string.ui_str_2277'))
          .layoutWeight(1)
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE))
          .borderRadius(10)
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .fontColor($r('app.color.text_primary'))
          .onClick((): void => {
            ngfFontScaleManagerFacade.setFontScaleLevel(NGFFontScaleLevel.EXTRA_LARGE);
            this.syncFontScale();
          })
      }
      .width('100%')

      Button($r('app.string.ui_str_2278'))
        .width('100%')
        .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
        .controlSize(ControlSize.SMALL)
        .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
        .borderRadius(10)
        .fontColor($r('app.color.text_primary'))
        .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
        .onClick((): void => {
          ngfFontScaleManagerFacade.resetToSystem();
          this.syncFontScale();
        })

      Row({ space: 12 }) {
        Column({ space: this.a11yScale.paragraphSpacing(4, 18) }) {
          Text($r('app.string.ui_str_2279'))
            .fontSize(this.a11yScale.font(11))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(11)))
            .fontColor($r('app.color.text_tertiary'))
          Text(this.currentFontLevel)
            .fontSize(this.a11yScale.font(15))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
        .padding(12)
        .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
        .borderRadius(12)

        Column({ space: this.a11yScale.paragraphSpacing(4, 18) }) {
          Text($r('app.string.ui_str_2280'))
            .fontSize(this.a11yScale.font(11))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(11)))
            .fontColor($r('app.color.text_tertiary'))
          Text(this.currentFontScale + 'x')
            .fontSize(this.a11yScale.font(15))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.tag_green'))
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
        .padding(12)
        .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
        .borderRadius(12)
      }
      .width('100%')

      Text($r('app.string.ui_str_2281'))
        .fontSize(this.a11yScale.font(14))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
        .fontColor($r('app.color.text_body'))
        .width('100%')
        .padding(12)
        .borderRadius(10)
        .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
    }
    .width('100%')
    .padding(16)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect(this.useSysMat))
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.card_border'), this.useSysMat)
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow(this.useSysMat))
  }

  private formatRelativeTime(offsetMs: number): void {
    const localeIndex = this.localeIndexes.length > 0 ? this.localeIndexes[0] : 0;
    const locale = this.locales[localeIndex];
    const timestamp = Date.now() - offsetMs;
    const result = ngfRelativeTimeFormatterFacade.format(timestamp, locale);
    const text = locale + ': ' + result.text;
    const nextResults: Array<string> = [];
    for (let i = 0; i < this.relativeTimeResults.length; i++) {
      nextResults.push(this.relativeTimeResults[i]);
    }
    nextResults.push(text);
    while (nextResults.length > 8) {
      nextResults.shift();
    }
    this.relativeTimeResults = nextResults;
    logger.info(TAG, '相对时间: locale=' + locale + ', text=' + result.text);
  }

  private handleDetectAll(): void {
    const results = ngfDeviceCapabilityDetectorFacade.checkAll();
    const entries: Array<NGFDemoCapabilityEntry> = [];
    for (let i = 0; i < results.length; i++) {
      const r = results[i];
      entries.push(new NGFDemoCapabilityEntry(i + 1, this.resolveCapabilityName(r.capability), r.available, r.detail));
    }
    this.capabilities = entries;
    logger.info(TAG, '设备能力检测完成: total=' + String(entries.length));
  }

  private resolveCapabilityName(type: NGFCapabilityType): ResourceStr {
    if (type === NGFCapabilityType.CAMERA) return $r('app.string.ui_str_2282');
    if (type === NGFCapabilityType.GPS) return 'GPS';
    if (type === NGFCapabilityType.NFC) return 'NFC';
    if (type === NGFCapabilityType.BLUETOOTH) return $r('app.string.ui_str_2283');
    if (type === NGFCapabilityType.WIFI) return 'WiFi';
    if (type === NGFCapabilityType.VIBRATION) return $r('app.string.ui_str_2284');
    if (type === NGFCapabilityType.FINGERPRINT) return $r('app.string.ui_str_2285');
    if (type === NGFCapabilityType.FACE_RECOGNITION) return $r('app.string.ui_str_2286');
    if (type === NGFCapabilityType.ACCELEROMETER) return $r('app.string.ui_str_2287');
    if (type === NGFCapabilityType.GYROSCOPE) return $r('app.string.ui_str_2288');
    if (type === NGFCapabilityType.BAROMETER) return $r('app.string.ui_str_2289');
    if (type === NGFCapabilityType.AMBIENT_LIGHT) return $r('app.string.ui_str_2290');
    if (type === NGFCapabilityType.PROXIMITY) return $r('app.string.ui_str_2291');
    return type;
  }

  private resolveLevelText(level: NGFFontScaleLevel): string {
    if (level === NGFFontScaleLevel.SMALL) return 'SMALL';
    if (level === NGFFontScaleLevel.NORMAL) return 'NORMAL';
    if (level === NGFFontScaleLevel.LARGE) return 'LARGE';
    if (level === NGFFontScaleLevel.EXTRA_LARGE) return 'EXTRA_LARGE';
    return 'NORMAL';
  }

  private syncFontScale(): void {
    this.currentFontScale = ngfFontScaleManagerFacade.getCurrentScale();
    this.currentFontLevel = this.resolveLevelText(ngfFontScaleManagerFacade.getCurrentLevel());
    this.statusMessage = $r('app.string.ui_str_2292', this.currentFontLevel, this.currentFontScale);
    logger.info(TAG, '字体缩放更新: level=' + this.currentFontLevel + ', scale=' + this.currentFontScale);
  }
}
