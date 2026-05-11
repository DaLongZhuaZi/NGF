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
      Stack() {
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
          .padding({ left: 16, right: 16, top: 100, bottom: 36 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
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
        .fontColor('#FFFFFFFF')
      Text('SecurityToolkit SHA 哈希 / AES-GCM 加解密 / PerformanceMonitor 打点与内存快照')
        .fontSize(13)
        .lineHeight(20)
        .fontColor('#B0FFFFFF')
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
        .fontColor('#FF0F172A')

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
            .backgroundColor(this.shaAlgorithmIndexes[0] === index ? '#FF0D9488' : '#FFE2E8F0')
            .fontColor(this.shaAlgorithmIndexes[0] === index ? '#FFFFFFFF' : '#FF0F172A')
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
        .backgroundColor('#FF0D9488')
        .onClick((): void => {
          void this.handleShaHash();
        })

      if (this.shaResult.length > 0) {
        Column({ space: 4 }) {
          Text('哈希结果')
            .fontSize(12)
            .fontColor('#FF64748B')
          Text(this.shaResult)
            .fontSize(11)
            .fontColor('#FF0F172A')
            .fontFamily('monospace')
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .maxLines(4)
            .width('100%')
            .padding(10)
            .backgroundColor('#FFF1F5F9')
            .borderRadius(10)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#FFE2E8F0' })
    .shadow({ radius: 10, color: '#180F172A', offsetX: 0, offsetY: 4 })
  }

  @Builder
  private buildAesSection(): void {
    Column({ space: 10 }) {
      Text('AES-GCM 加解密')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FF0F172A')

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
          .backgroundColor('#FF0EA5E9')
          .onClick((): void => {
            void this.handleAesEncrypt();
          })
        Button('解密')
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor('#FF8B5CF6')
          .onClick((): void => {
            void this.handleAesDecrypt();
          })
      }
      .width('100%')

      if (this.aesCipher.length > 0) {
        Column({ space: 4 }) {
          Text('密文 (Base64)')
            .fontSize(12)
            .fontColor('#FF64748B')
          Text(this.aesCipher)
            .fontSize(11)
            .fontColor('#FF0F172A')
            .fontFamily('monospace')
            .maxLines(3)
            .width('100%')
            .padding(10)
            .backgroundColor('#FFF1F5F9')
            .borderRadius(10)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      if (this.aesDecrypted.length > 0) {
        Column({ space: 4 }) {
          Text('解密结果')
            .fontSize(12)
            .fontColor('#FF64748B')
          Text(this.aesDecrypted)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FF16A34A')
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
    .backgroundColor('#FFFFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#FFE2E8F0' })
    .shadow({ radius: 10, color: '#180F172A', offsetX: 0, offsetY: 4 })
  }

  @Builder
  private buildPerformanceSection(): void {
    Column({ space: 10 }) {
      Text('性能打点')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FF0F172A')

      Row({ space: 10 }) {
        Button('开始打点')
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor('#FF2563EB')
          .onClick((): void => {
            performanceMonitor.mark('demo_start');
            logger.info(TAG, '已记录开始打点: demo_start');
          })
        Button('结束打点')
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor('#FF7C3AED')
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
                .fontColor('#FF0F172A')
              Text(`${entry.durationMs} ms`)
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FF2563EB')
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ top: 6, bottom: 6, left: 10, right: 10 })
            .backgroundColor('#FFF8FAFC')
            .borderRadius(8)
          }, (entry: NGFDemoMeasureEntry): string => `measure_${entry.id}`)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#FFE2E8F0' })
    .shadow({ radius: 10, color: '#180F172A', offsetX: 0, offsetY: 4 })
  }

  @Builder
  private buildMemorySection(): void {
    Column({ space: 10 }) {
      Text('内存快照')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FF0F172A')

      Button('拍摄内存快照')
        .width('100%')
        .height(40)
        .fontSize(14)
        .borderRadius(12)
        .backgroundColor('#FFDC2626')
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
                .fontColor('#FF0F172A')
              Text(`${entry.pssKb} KB`)
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFDC2626')
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ top: 6, bottom: 6, left: 10, right: 10 })
            .backgroundColor('#FFF8FAFC')
            .borderRadius(8)
          }, (entry: NGFDemoMemoryEntry): string => `memory_${entry.id}`)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#FFE2E8F0' })
    .shadow({ radius: 10, color: '#180F172A', offsetX: 0, offsetY: 4 })
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
