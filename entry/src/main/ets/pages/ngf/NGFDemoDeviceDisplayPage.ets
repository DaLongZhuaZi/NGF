import { HdsNavDestination } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import { logger } from 'ngf_framework';
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
          Column({ space: 12 }) {
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
    NGFPageWindowSupport.restoreMainMenu();
  }

  @Builder
  private buildTitleCard(): void {
    Column({ space: 8 }) {
      Text($r('app.string.ui_str_2262'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.panel_background'))
      Text($r('app.string.ui_str_2263'))
        .fontSize(13)
        .lineHeight(20)
        .fontColor($r('app.color.text_white_low'))
    }
    .width('100%')
    .padding(18)
    .linearGradient({
      angle: 140,
      colors: [['#14532D', 0], ['#22C55E', 1]]
    })
    .borderRadius(20)
    .shadow({ radius: 14, color: '#1A14532D', offsetX: 0, offsetY: 8 })
  }

  @Builder
  private buildRelativeTimeSection(): void {
    Column({ space: 10 }) {
      Text($r('app.string.ui_str_2264'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Row({ space: 8 }) {
        ForEach(this.localeLabels, (label: string, index: number) => {
          Button(label)
            .height(36)
            .fontSize(13)
            .borderRadius(10)
            .backgroundColor(this.localeIndexes[0] === index ? $r('app.color.tag_green') : $r('app.color.card_border'))
            .fontColor(this.localeIndexes[0] === index ? $r('app.color.panel_background') : $r('app.color.text_body'))
            .onClick((): void => {
              this.localeIndexes = [index];
            })
        })
      }
      .width('100%')

      Row({ space: 8 }) {
        Button($r('app.string.ui_str_2265'))
          .layoutWeight(1)
          .height(36)
          .fontSize(12)
          .borderRadius(10)
          .backgroundColor($r('app.color.tag_green'))
          .onClick((): void => {
            this.formatRelativeTime(60 * 1000);
          })
        Button($r('app.string.ui_str_2266'))
          .layoutWeight(1)
          .height(36)
          .fontSize(12)
          .borderRadius(10)
          .backgroundColor($r('app.color.tag_green'))
          .onClick((): void => {
            this.formatRelativeTime(60 * 60 * 1000);
          })
        Button($r('app.string.ui_str_2267'))
          .layoutWeight(1)
          .height(36)
          .fontSize(12)
          .borderRadius(10)
          .backgroundColor($r('app.color.tag_green_dark'))
          .onClick((): void => {
            this.formatRelativeTime(24 * 60 * 60 * 1000);
          })
        Button($r('app.string.ui_str_2268'))
          .layoutWeight(1)
          .height(36)
          .fontSize(12)
          .borderRadius(10)
          .backgroundColor($r('app.color.tag_green_darker'))
          .onClick((): void => {
            this.formatRelativeTime(30 * 24 * 60 * 60 * 1000);
          })
      }
      .width('100%')

      if (this.relativeTimeResults.length > 0) {
        Column({ space: 4 }) {
          ForEach(this.relativeTimeResults, (text: string, index: number) => {
            Row() {
              Text(`${index + 1}.`)
                .fontSize(12)
                .fontColor($r('app.color.text_muted'))
                .width(24)
              Text(text)
                .fontSize(13)
                .fontColor($r('app.color.text_body'))
            }
            .width('100%')
            .padding({ top: 5, bottom: 5, left: 10, right: 10 })
            .backgroundColor($r('app.color.background_surface'))
            .borderRadius(8)
          })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.card_border') })
    .shadow({ radius: 10, color: $r('app.color.card_shadow_demo'), offsetX: 0, offsetY: 4 })
  }

  @Builder
  private buildCapabilitySection(): void {
    Column({ space: 10 }) {
      Text($r('app.string.ui_str_2269'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Button($r('app.string.ui_str_2270'))
        .width('100%')
        .height(40)
        .fontSize(14)
        .borderRadius(12)
        .backgroundColor($r('app.color.tag_green'))
        .onClick((): void => {
          this.handleDetectAll();
        })

      if (this.capabilities.length > 0) {
        Column({ space: 4 }) {
          ForEach(this.capabilities, (entry: NGFDemoCapabilityEntry) => {
            Row() {
              Column({ space: 2 }) {
                Text(entry.name)
                  .fontSize(13)
                  .fontColor($r('app.color.text_body'))
                  .fontWeight(FontWeight.Medium)
                Text(entry.detail)
                  .fontSize(11)
                  .fontColor($r('app.color.text_muted'))
                  .maxLines(2)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text(entry.available ? $r('app.string.ui_str_2271') : $r('app.string.ui_str_2272'))
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.panel_background'))
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .backgroundColor(entry.available ? $r('app.color.tag_green') : $r('app.color.tag_red'))
                .borderRadius(8)
            }
            .width('100%')
            .padding({ top: 8, bottom: 8, left: 12, right: 12 })
            .backgroundColor($r('app.color.background_surface'))
            .borderRadius(10)
          }, (entry: NGFDemoCapabilityEntry): string => `cap_${entry.id}`)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.card_border') })
    .shadow({ radius: 10, color: $r('app.color.card_shadow_demo'), offsetX: 0, offsetY: 4 })
  }

  @Builder
  private buildFontScaleSection(): void {
    Column({ space: 10 }) {
      Text($r('app.string.ui_str_2273'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Row({ space: 8 }) {
        Button($r('app.string.ui_str_2274'))
          .layoutWeight(1)
          .height(36)
          .fontSize(12)
          .borderRadius(10)
          .backgroundColor(this.currentFontLevel === 'SMALL' ? $r('app.color.button_primary') : $r('app.color.card_border'))
          .fontColor(this.currentFontLevel === 'SMALL' ? $r('app.color.panel_background') : $r('app.color.text_body'))
          .onClick((): void => {
            ngfFontScaleManagerFacade.setFontScaleLevel(NGFFontScaleLevel.SMALL);
            this.syncFontScale();
          })
        Button($r('app.string.ui_str_2275'))
          .layoutWeight(1)
          .height(36)
          .fontSize(12)
          .borderRadius(10)
          .backgroundColor(this.currentFontLevel === 'NORMAL' ? $r('app.color.button_primary') : $r('app.color.card_border'))
          .fontColor(this.currentFontLevel === 'NORMAL' ? $r('app.color.panel_background') : $r('app.color.text_body'))
          .onClick((): void => {
            ngfFontScaleManagerFacade.setFontScaleLevel(NGFFontScaleLevel.NORMAL);
            this.syncFontScale();
          })
        Button($r('app.string.ui_str_2276'))
          .layoutWeight(1)
          .height(36)
          .fontSize(12)
          .borderRadius(10)
          .backgroundColor(this.currentFontLevel === 'LARGE' ? $r('app.color.button_primary') : $r('app.color.card_border'))
          .fontColor(this.currentFontLevel === 'LARGE' ? $r('app.color.panel_background') : $r('app.color.text_body'))
          .onClick((): void => {
            ngfFontScaleManagerFacade.setFontScaleLevel(NGFFontScaleLevel.LARGE);
            this.syncFontScale();
          })
        Button($r('app.string.ui_str_2277'))
          .layoutWeight(1)
          .height(36)
          .fontSize(12)
          .borderRadius(10)
          .backgroundColor(this.currentFontLevel === 'EXTRA_LARGE' ? $r('app.color.button_primary') : $r('app.color.card_border'))
          .fontColor(this.currentFontLevel === 'EXTRA_LARGE' ? $r('app.color.panel_background') : $r('app.color.text_body'))
          .onClick((): void => {
            ngfFontScaleManagerFacade.setFontScaleLevel(NGFFontScaleLevel.EXTRA_LARGE);
            this.syncFontScale();
          })
      }
      .width('100%')

      Button($r('app.string.ui_str_2278'))
        .width('100%')
        .height(36)
        .fontSize(13)
        .borderRadius(10)
        .backgroundColor($r('app.color.text_muted'))
        .onClick((): void => {
          ngfFontScaleManagerFacade.resetToSystem();
          this.syncFontScale();
        })

      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text($r('app.string.ui_str_2279'))
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
          Text(this.currentFontLevel)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.button_primary'))
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
        .padding(12)
        .backgroundColor($r('app.color.background_surface'))
        .borderRadius(12)

        Column({ space: 4 }) {
          Text($r('app.string.ui_str_2280'))
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
          Text(`${this.currentFontScale}x`)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.tag_green'))
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
        .padding(12)
        .backgroundColor($r('app.color.background_surface'))
        .borderRadius(12)
      }
      .width('100%')

      Text($r('app.string.ui_str_2281'))
        .fontSize(14)
        .fontColor($r('app.color.text_body'))
        .width('100%')
        .padding(12)
        .backgroundColor('#FFF0FDF4')
        .borderRadius(10)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.card_border') })
    .shadow({ radius: 10, color: $r('app.color.card_shadow_demo'), offsetX: 0, offsetY: 4 })
  }

  private formatRelativeTime(offsetMs: number): void {
    const localeIndex = this.localeIndexes.length > 0 ? this.localeIndexes[0] : 0;
    const locale = this.locales[localeIndex];
    const timestamp = Date.now() - offsetMs;
    const result = ngfRelativeTimeFormatterFacade.format(timestamp, locale);
    const text = `${locale}: ${result.text}`;
    const nextResults: Array<string> = [];
    for (let i = 0; i < this.relativeTimeResults.length; i++) {
      nextResults.push(this.relativeTimeResults[i]);
    }
    nextResults.push(text);
    while (nextResults.length > 8) {
      nextResults.shift();
    }
    this.relativeTimeResults = nextResults;
    logger.info(TAG, `相对时间: locale=${locale}, text=${result.text}`);
  }

  private handleDetectAll(): void {
    const results = ngfDeviceCapabilityDetectorFacade.checkAll();
    const entries: Array<NGFDemoCapabilityEntry> = [];
    for (let i = 0; i < results.length; i++) {
      const r = results[i];
      entries.push(new NGFDemoCapabilityEntry(i + 1, this.resolveCapabilityName(r.capability), r.available, r.detail));
    }
    this.capabilities = entries;
    logger.info(TAG, `设备能力检测完成: total=${entries.length}`);
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
    logger.info(TAG, `字体缩放更新: level=${this.currentFontLevel}, scale=${this.currentFontScale}`);
  }
}
