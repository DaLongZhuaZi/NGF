import { HdsNavDestination } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import { logger } from '../../Framework/NGF/utils/Logger';
import {
  NGFRelativeTimeResult,
  ngfRelativeTimeFormatterFacade
} from '../../Framework/NGF/i18n/index';
import {
  NGFCapabilityType,
  NGFCapabilityResult,
  ngfDeviceCapabilityDetectorFacade
} from '../../Framework/NGF/deviceAwareness/index';
import {
  NGFFontScaleLevel,
  ngfFontScaleManagerFacade
} from '../../Framework/NGF/uiTheme/index';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from '../../Framework/NGF/uiShell/components/NGFImmersiveTopChrome';
import { NGFHdsTitleBarOptionsFactory } from '../../Framework/NGF/uiShell/components/HdsNavigationSupport';
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
  name: string;
  available: boolean;
  detail: string;

  constructor(id: number, name: string, available: boolean, detail: string) {
    this.id = id;
    this.name = name;
    this.available = available;
    this.detail = detail;
  }
}

@Component
export struct NGFDemoDeviceDisplayPage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private localeIndexes: Array<number> = [0];
  @State private relativeTimeResults: Array<string> = [];
  @State private capabilities: Array<NGFDemoCapabilityEntry> = [];
  @State private currentFontScale: number = 1.0;
  @State private currentFontLevel: string = 'NORMAL';
  @State private statusMessage: string = '';

  private readonly locales: Array<string> = ['zh-CN', 'en-US', 'ja-JP'];
  private readonly localeLabels: Array<string> = ['中文', 'English', '日本語'];

  aboutToAppear(): void {
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
          .padding({ left: 16, right: 16, top: DEMO_DEVICE_TOP_CHROME.metrics.contentTopInset, bottom: 36 })
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
      '设备与显示',
      '相对时间/能力检测/字体缩放',
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
      Text('设备与显示演示')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.panel_background'))
      Text('RelativeTimeFormatter 多语言 / DeviceCapabilityDetector 硬件检测 / FontScaleManager 字体缩放')
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
      Text('相对时间格式化')
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
        Button('1分钟前')
          .layoutWeight(1)
          .height(36)
          .fontSize(12)
          .borderRadius(10)
          .backgroundColor($r('app.color.tag_green'))
          .onClick((): void => {
            this.formatRelativeTime(60 * 1000);
          })
        Button('1小时前')
          .layoutWeight(1)
          .height(36)
          .fontSize(12)
          .borderRadius(10)
          .backgroundColor($r('app.color.tag_green'))
          .onClick((): void => {
            this.formatRelativeTime(60 * 60 * 1000);
          })
        Button('1天前')
          .layoutWeight(1)
          .height(36)
          .fontSize(12)
          .borderRadius(10)
          .backgroundColor($r('app.color.tag_green_dark'))
          .onClick((): void => {
            this.formatRelativeTime(24 * 60 * 60 * 1000);
          })
        Button('1月前')
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
      Text('设备能力检测')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Button('检测全部能力 (13项)')
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

              Text(entry.available ? '可用' : '不可用')
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
      Text('字体缩放')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Row({ space: 8 }) {
        Button('小 (0.85x)')
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
        Button('标准 (1.0x)')
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
        Button('大 (1.15x)')
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
        Button('特大 (1.3x)')
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

      Button('重置为系统默认')
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
          Text('当前级别')
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
          Text('缩放倍数')
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

      Text('这是一段预览文字，用于展示当前字体缩放效果。The quick brown fox jumps over the lazy dog.')
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

  private resolveCapabilityName(type: NGFCapabilityType): string {
    if (type === NGFCapabilityType.CAMERA) return '摄像头';
    if (type === NGFCapabilityType.GPS) return 'GPS';
    if (type === NGFCapabilityType.NFC) return 'NFC';
    if (type === NGFCapabilityType.BLUETOOTH) return '蓝牙';
    if (type === NGFCapabilityType.WIFI) return 'WiFi';
    if (type === NGFCapabilityType.VIBRATION) return '振动';
    if (type === NGFCapabilityType.FINGERPRINT) return '指纹';
    if (type === NGFCapabilityType.FACE_RECOGNITION) return '人脸识别';
    if (type === NGFCapabilityType.ACCELEROMETER) return '加速度计';
    if (type === NGFCapabilityType.GYROSCOPE) return '陀螺仪';
    if (type === NGFCapabilityType.BAROMETER) return '气压计';
    if (type === NGFCapabilityType.AMBIENT_LIGHT) return '环境光';
    if (type === NGFCapabilityType.PROXIMITY) return '接近传感器';
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
    this.statusMessage = `字体缩放: ${this.currentFontLevel} (${this.currentFontScale}x)`;
    logger.info(TAG, `字体缩放更新: level=${this.currentFontLevel}, scale=${this.currentFontScale}`);
  }
}
