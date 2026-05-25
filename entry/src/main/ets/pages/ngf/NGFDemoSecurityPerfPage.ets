import { HdsNavDestination } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import { logger } from '../../Framework/NGF/utils/Logger';
import {
  NGFHashAlgorithm,
  securityToolkit
} from '../../Framework/NGF/utils/SecurityToolkit';
import {
  performanceMonitor
} from '../../Framework/NGF/utils/PerformanceMonitor';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from '../../Framework/NGF/uiShell/components/NGFImmersiveTopChrome';
import { NGFHdsTitleBarOptionsFactory } from '../../Framework/NGF/uiShell/components/HdsNavigationSupport';
import { NGFPageWindowName, NGFPageWindowSupport } from './NGFPageWindowSupport';

const TAG: string = 'NGFDemoSecurityPerfPage';

const DEMO_SECURITY_TOP_CHROME: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#0A1628',
  '#0D3B4D',
  '#071A24',
  '#14B8A6D8',
  '#5EEAD4D8',
  160,
  88
);

class NGFDemoMeasureEntry {
  id: number;
  name: string;
  durationMs: number;

  constructor(id: number, name: string, durationMs: number) {
    this.id = id;
    this.name = name;
    this.durationMs = durationMs;
  }
}

class NGFDemoMemoryEntry {
  id: number;
  pssKb: number;
  timeText: string;

  constructor(id: number, pssKb: number, timeText: string) {
    this.id = id;
    this.pssKb = pssKb;
    this.timeText = timeText;
  }
}

@Component
export struct NGFDemoSecurityPerfPage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private shaInput: string = 'Hello NGF Framework';
  @State private shaAlgorithmIndexes: Array<number> = [0];
  @State private shaResult: string = '';
  @State private aesInput: string = 'NGF Secret Message';
  @State private aesCipher: string = '';
  @State private aesDecrypted: string = '';
  @State private aesKey: string = '';
  @State private aesIv: string = '';
  @State private measures: Array<NGFDemoMeasureEntry> = [];
  @State private memoryEntries: Array<NGFDemoMemoryEntry> = [];
  @State private nextMeasureId: number = 1;
  @State private nextMemoryId: number = 1;

  private readonly algorithms: Array<string> = ['SHA256', 'SHA384', 'SHA512'];

  aboutToAppear(): void {
    NGFPageWindowSupport.apply(NGFPageWindowName.DEMO_SECURITY_PERF);
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: DEMO_SECURITY_TOP_CHROME })

        Scroll() {
          Column({ space: 12 }) {
            this.buildTitleCard()
            this.buildShaSection()
            this.buildAesSection()
            this.buildPerformanceSection()
            this.buildMemorySection()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: DEMO_SECURITY_TOP_CHROME.metrics.contentTopInset, bottom: 36 })
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
      '安全与性能',
      'SHA/AES/性能打点/内存快照',
      '#0A1628',
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
      Text('安全与性能演示')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.panel_background'))
      Text('SecurityToolkit SHA 哈希 / AES-GCM 加解密 / PerformanceMonitor 打点与内存快照')
        .fontSize(13)
        .lineHeight(20)
        .fontColor($r('app.color.text_white_low'))
    }
    .width('100%')
    .padding(18)
    .linearGradient({
      angle: 140,
      colors: [['#0D4B59', 0], ['#14B8A6', 1]]
    })
    .borderRadius(20)
    .shadow({ radius: 14, color: '#1A0D4B59', offsetX: 0, offsetY: 8 })
  }

  @Builder
  private buildShaSection(): void {
    Column({ space: 10 }) {
      Text('SHA 哈希')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      TextInput({ text: this.shaInput, placeholder: '输入待哈希文本' })
        .width('100%')
        .height(44)
        .fontSize(14)
        .onChange((value: string): void => {
          this.shaInput = value;
        })

      Row({ space: 8 }) {
        ForEach(this.algorithms, (algo: string, index: number) => {
          Button(algo)
            .height(36)
            .fontSize(13)
            .borderRadius(10)
            .backgroundColor(this.shaAlgorithmIndexes[0] === index ? $r('app.color.tag_teal') : $r('app.color.card_border'))
            .fontColor(this.shaAlgorithmIndexes[0] === index ? $r('app.color.panel_background') : $r('app.color.text_body'))
            .onClick((): void => {
              this.shaAlgorithmIndexes = [index];
            })
        })
      }
      .width('100%')

      Button('计算哈希')
        .width('100%')
        .height(40)
        .fontSize(14)
        .borderRadius(12)
        .backgroundColor($r('app.color.tag_teal'))
        .onClick((): void => {
          void this.handleShaHash();
        })

      if (this.shaResult.length > 0) {
        Column({ space: 4 }) {
          Text('哈希结果')
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
          Text(this.shaResult)
            .fontSize(11)
            .fontColor($r('app.color.text_body'))
            .fontFamily('monospace')
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .maxLines(4)
            .width('100%')
            .padding(10)
            .backgroundColor($r('app.color.background_surface'))
            .borderRadius(10)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
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
  private buildAesSection(): void {
    Column({ space: 10 }) {
      Text('AES-GCM 加解密')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      TextInput({ text: this.aesInput, placeholder: '输入明文' })
        .width('100%')
        .height(44)
        .fontSize(14)
        .onChange((value: string): void => {
          this.aesInput = value;
        })

      Row({ space: 10 }) {
        Button('加密')
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor($r('app.color.tag_cyan'))
          .onClick((): void => {
            void this.handleAesEncrypt();
          })
        Button('解密')
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor($r('app.color.tag_purple'))
          .onClick((): void => {
            void this.handleAesDecrypt();
          })
      }
      .width('100%')

      if (this.aesCipher.length > 0) {
        Column({ space: 4 }) {
          Text('密文 (Base64)')
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
          Text(this.aesCipher)
            .fontSize(11)
            .fontColor($r('app.color.text_body'))
            .fontFamily('monospace')
            .maxLines(3)
            .width('100%')
            .padding(10)
            .backgroundColor($r('app.color.background_surface'))
            .borderRadius(10)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      if (this.aesDecrypted.length > 0) {
        Column({ space: 4 }) {
          Text('解密结果')
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
          Text(this.aesDecrypted)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.tag_green'))
            .width('100%')
            .padding(10)
            .backgroundColor('#FFF0FDF4')
            .borderRadius(10)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
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
  private buildPerformanceSection(): void {
    Column({ space: 10 }) {
      Text('性能打点')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Row({ space: 10 }) {
        Button('开始打点')
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor($r('app.color.button_primary'))
          .onClick((): void => {
            performanceMonitor.mark('demo_start');
            logger.info(TAG, '已记录开始打点: demo_start');
          })
        Button('结束打点')
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor($r('app.color.tag_purple'))
          .onClick((): void => {
            performanceMonitor.mark('demo_end');
            const result = performanceMonitor.measure('demo_measure', 'demo_start', 'demo_end');
            if (result !== null) {
              const nextMeasures: Array<NGFDemoMeasureEntry> = [];
              for (let i = 0; i < this.measures.length; i++) {
                nextMeasures.push(this.measures[i]);
              }
              nextMeasures.push(new NGFDemoMeasureEntry(this.nextMeasureId, result.name, result.durationMs));
              this.nextMeasureId = this.nextMeasureId + 1;
              this.measures = nextMeasures;
            }
          })
      }
      .width('100%')

      if (this.measures.length > 0) {
        Column({ space: 4 }) {
          ForEach(this.measures, (entry: NGFDemoMeasureEntry) => {
            Row() {
              Text(`${entry.id}. ${entry.name}`)
                .fontSize(13)
                .fontColor($r('app.color.text_body'))
              Text(`${entry.durationMs} ms`)
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.button_primary'))
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ top: 6, bottom: 6, left: 10, right: 10 })
            .backgroundColor($r('app.color.background_surface'))
            .borderRadius(8)
          }, (entry: NGFDemoMeasureEntry): string => `measure_${entry.id}`)
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
  private buildMemorySection(): void {
    Column({ space: 10 }) {
      Text('内存快照')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Button('拍摄内存快照')
        .width('100%')
        .height(40)
        .fontSize(14)
        .borderRadius(12)
        .backgroundColor($r('app.color.tag_red'))
        .onClick((): void => {
          const snapshot = performanceMonitor.snapshotMemory();
          const now = new Date();
          const timeText = `${this.pad2(now.getHours())}:${this.pad2(now.getMinutes())}:${this.pad2(now.getSeconds())}`;
          const nextEntries: Array<NGFDemoMemoryEntry> = [];
          for (let i = 0; i < this.memoryEntries.length; i++) {
            nextEntries.push(this.memoryEntries[i]);
          }
          nextEntries.push(new NGFDemoMemoryEntry(this.nextMemoryId, snapshot.usedPssKb, timeText));
          this.nextMemoryId = this.nextMemoryId + 1;
          this.memoryEntries = nextEntries;
        })

      if (this.memoryEntries.length > 0) {
        Column({ space: 4 }) {
          ForEach(this.memoryEntries, (entry: NGFDemoMemoryEntry) => {
            Row() {
              Text(`#${entry.id}  ${entry.timeText}`)
                .fontSize(13)
                .fontColor($r('app.color.text_body'))
              Text(`${entry.pssKb} KB`)
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.tag_red'))
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ top: 6, bottom: 6, left: 10, right: 10 })
            .backgroundColor($r('app.color.background_surface'))
            .borderRadius(8)
          }, (entry: NGFDemoMemoryEntry): string => `memory_${entry.id}`)
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

  private async handleShaHash(): Promise<void> {
    try {
      const algoIndex = this.shaAlgorithmIndexes.length > 0 ? this.shaAlgorithmIndexes[0] : 0;
      const algo = algoIndex === 0 ? NGFHashAlgorithm.SHA256
        : algoIndex === 1 ? NGFHashAlgorithm.SHA384
          : NGFHashAlgorithm.SHA512;
      const hash = await securityToolkit.shaHash(this.shaInput, algo);
      this.shaResult = hash;
      logger.info(TAG, `SHA 哈希完成: algo=${algo}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.shaResult = `错误: ${message}`;
    }
  }

  private async handleAesEncrypt(): Promise<void> {
    try {
      const key = securityToolkit.generateRandomBase64(16);
      const iv = securityToolkit.generateRandomBase64(12);
      this.aesKey = key;
      this.aesIv = iv;
      const result = await securityToolkit.aesEncrypt(this.aesInput, key, iv);
      if (result.success) {
        this.aesCipher = result.data;
        this.aesDecrypted = '';
        logger.info(TAG, 'AES 加密成功');
      } else {
        this.aesCipher = '加密失败';
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.aesCipher = `错误: ${message}`;
    }
  }

  private async handleAesDecrypt(): Promise<void> {
    try {
      if (this.aesCipher.length <= 0 || this.aesKey.length <= 0) {
        this.aesDecrypted = '请先加密';
        return;
      }
      const result = await securityToolkit.aesDecrypt(this.aesCipher, this.aesKey, this.aesIv);
      if (result.success) {
        this.aesDecrypted = result.data;
        logger.info(TAG, 'AES 解密成功');
      } else {
        this.aesDecrypted = '解密失败';
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.aesDecrypted = `错误: ${message}`;
    }
  }

  private pad2(value: number): string {
    if (value >= 10) {
      return `${value}`;
    }
    return `0${value}`;
  }
}
