import { HdsNavDestination } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import { logger } from '../../Framework/NGF/utils/Logger';
import { FileUtils, NGFFileEntry } from '../../Framework/NGF/utils/FileUtils';
import { ngfContentCacheFacade } from '../../Framework/NGF/contentSource/index';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from '../../Framework/NGF/uiShell/components/NGFImmersiveTopChrome';
import { NGFHdsTitleBarOptionsFactory } from '../../Framework/NGF/uiShell/components/HdsNavigationSupport';
import { NGFPageWindowName, NGFPageWindowSupport } from './NGFPageWindowSupport';

const TAG: string = 'NGFDemoDataStoragePage';

const DEMO_DATA_TOP_CHROME: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#1A0F08',
  '#3D2508',
  '#1A1005',
  '#F59E0BD8',
  '#FCD34DD8',
  160,
  88
);

class NGFDemoFileEntryDisplay {
  id: number;
  name: string;
  sizeText: string;
  typeText: string;

  constructor(id: number, name: string, sizeText: string, typeText: string) {
    this.id = id;
    this.name = name;
    this.sizeText = sizeText;
    this.typeText = typeText;
  }
}

@Component
export struct NGFDemoDataStoragePage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private fileWriteInput: string = 'NGF Framework 数据存储测试';
  @State private fileReadResult: string = '';
  @State private fileEntries: Array<NGFDemoFileEntryDisplay> = [];
  @State private cacheKey: string = 'demo_key';
  @State private cacheValue: string = 'demo_value';
  @State private cacheGetResult: string = '';
  @State private cacheHasResult: string = '';
  @State private cacheMemorySize: number = 0;
  @State private statusMessage: string = '';

  aboutToAppear(): void {
    NGFPageWindowSupport.apply(NGFPageWindowName.DEMO_DATA_STORAGE);
  }

  build() {
    HdsNavDestination() {
      Stack() {
        NGFImmersiveTopChromeUnderlay({ spec: DEMO_DATA_TOP_CHROME })

        Scroll() {
          Column({ space: 12 }) {
            this.buildTitleCard()
            this.buildFileReadWriteSection()
            this.buildDirectorySection()
            this.buildCacheSection()
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
      '数据与存储',
      'FileUtils/目录/ContentCache',
      '#1A0F08',
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
      Text('数据与存储演示')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFFFF')
      Text('FileUtils 文件读写 / 目录操作 / ContentCache LRU 缓存管理')
        .fontSize(13)
        .lineHeight(20)
        .fontColor('#B0FFFFFF')
    }
    .width('100%')
    .padding(18)
    .linearGradient({
      angle: 140,
      colors: [['#78350F', 0], ['#F59E0B', 1]]
    })
    .borderRadius(20)
    .shadow({ radius: 14, color: '#1A78350F', offsetX: 0, offsetY: 8 })
  }

  @Builder
  private buildFileReadWriteSection(): void {
    Column({ space: 10 }) {
      Text('文件读写')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FF0F172A')

      TextInput({ text: this.fileWriteInput, placeholder: '输入要写入的内容' })
        .width('100%')
        .height(44)
        .fontSize(14)
        .onChange((value: string): void => {
          this.fileWriteInput = value;
        })

      Row({ space: 10 }) {
        Button('写入文件')
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor('#FFD97706')
          .onClick((): void => {
            void this.handleFileWrite();
          })
        Button('读取文件')
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor('#FF0284C7')
          .onClick((): void => {
            void this.handleFileRead();
          })
      }
      .width('100%')

      if (this.fileReadResult.length > 0) {
        Column({ space: 4 }) {
          Text('读取结果')
            .fontSize(12)
            .fontColor('#FF64748B')
          Text(this.fileReadResult)
            .fontSize(13)
            .fontColor('#FF0F172A')
            .width('100%')
            .padding(10)
            .backgroundColor('#FFF1F5F9')
            .borderRadius(10)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      if (this.statusMessage.length > 0) {
        Text(this.statusMessage)
          .fontSize(12)
          .fontColor('#FF16A34A')
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
  private buildDirectorySection(): void {
    Column({ space: 10 }) {
      Text('目录操作')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FF0F172A')

      Button('列出应用文件目录')
        .width('100%')
        .height(40)
        .fontSize(14)
        .borderRadius(12)
        .backgroundColor('#FF7C3AED')
        .onClick((): void => {
          void this.handleListDirectory();
        })

      if (this.fileEntries.length > 0) {
        Column({ space: 4 }) {
          ForEach(this.fileEntries, (entry: NGFDemoFileEntryDisplay) => {
            Row() {
              Text(entry.name)
                .fontSize(13)
                .fontColor('#FF0F172A')
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(entry.sizeText)
                .fontSize(12)
                .fontColor('#FF64748B')
                .margin({ left: 8 })
              Text(entry.typeText)
                .fontSize(11)
                .fontColor('#FFFFFFFF')
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor(entry.typeText === 'DIR' ? '#FF8B5CF6' : '#FF0EA5E9')
                .borderRadius(6)
                .margin({ left: 8 })
            }
            .width('100%')
            .padding({ top: 6, bottom: 6, left: 10, right: 10 })
            .backgroundColor('#FFF8FAFC')
            .borderRadius(8)
          }, (entry: NGFDemoFileEntryDisplay): string => `file_${entry.id}`)
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
  private buildCacheSection(): void {
    Column({ space: 10 }) {
      Text('内容缓存 (LRU)')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FF0F172A')

      TextInput({ text: this.cacheKey, placeholder: '缓存 Key' })
        .width('100%')
        .height(40)
        .fontSize(14)
        .onChange((value: string): void => {
          this.cacheKey = value;
        })

      TextInput({ text: this.cacheValue, placeholder: '缓存 Value' })
        .width('100%')
        .height(40)
        .fontSize(14)
        .onChange((value: string): void => {
          this.cacheValue = value;
        })

      Row({ space: 8 }) {
        Button('Put')
          .layoutWeight(1)
          .height(36)
          .fontSize(13)
          .borderRadius(10)
          .backgroundColor('#FF16A34A')
          .onClick((): void => {
            ngfContentCacheFacade.put(this.cacheKey, this.cacheValue, 300000);
            this.cacheMemorySize = ngfContentCacheFacade.memorySize();
            this.statusMessage = `已放入缓存: ${this.cacheKey}`;
          })
        Button('Get')
          .layoutWeight(1)
          .height(36)
          .fontSize(13)
          .borderRadius(10)
          .backgroundColor('#FF2563EB')
          .onClick((): void => {
            const value = ngfContentCacheFacade.get(this.cacheKey);
            this.cacheGetResult = value.length > 0 ? value : '(空)';
          })
        Button('Has')
          .layoutWeight(1)
          .height(36)
          .fontSize(13)
          .borderRadius(10)
          .backgroundColor('#FF7C3AED')
          .onClick((): void => {
            const exists = ngfContentCacheFacade.has(this.cacheKey);
            this.cacheHasResult = exists ? '存在' : '不存在';
          })
        Button('Del')
          .layoutWeight(1)
          .height(36)
          .fontSize(13)
          .borderRadius(10)
          .backgroundColor('#FFDC2626')
          .onClick((): void => {
            ngfContentCacheFacade.remove(this.cacheKey);
            this.cacheMemorySize = ngfContentCacheFacade.memorySize();
            this.statusMessage = `已删除缓存: ${this.cacheKey}`;
          })
      }
      .width('100%')

      Column({ space: 4 }) {
        Row() {
          Text('Get 结果:')
            .fontSize(12)
            .fontColor('#FF64748B')
          Text(this.cacheGetResult)
            .fontSize(13)
            .fontColor('#FF0F172A')
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Row() {
          Text('Has 结果:')
            .fontSize(12)
            .fontColor('#FF64748B')
          Text(this.cacheHasResult)
            .fontSize(13)
            .fontColor('#FF0F172A')
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Row() {
          Text('内存条目数:')
            .fontSize(12)
            .fontColor('#FF64748B')
          Text(`${this.cacheMemorySize}`)
            .fontSize(13)
            .fontColor('#FF0F172A')
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#FFF8FAFC')
      .borderRadius(10)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#FFE2E8F0' })
    .shadow({ radius: 10, color: '#180F172A', offsetX: 0, offsetY: 4 })
  }

  private async handleFileWrite(): Promise<void> {
    try {
      const success = FileUtils.writeText('ngf_demo.txt', this.fileWriteInput);
      this.statusMessage = success ? '写入成功: ngf_demo.txt' : '写入失败';
      logger.info(TAG, `文件写入: success=${success}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.statusMessage = `写入异常: ${message}`;
    }
  }

  private async handleFileRead(): Promise<void> {
    try {
      const content = FileUtils.readText('ngf_demo.txt');
      this.fileReadResult = content.length > 0 ? content : '(文件为空或不存在)';
      logger.info(TAG, `文件读取: length=${content.length}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.fileReadResult = `读取异常: ${message}`;
    }
  }

  private async handleListDirectory(): Promise<void> {
    try {
      const entries = FileUtils.listDirectory('');
      const result: Array<NGFDemoFileEntryDisplay> = [];
      for (let i = 0; i < entries.length; i++) {
        const entry = entries[i];
        const sizeText = entry.isDirectory ? '-' : `${entry.size}B`;
        const typeText = entry.isDirectory ? 'DIR' : 'FILE';
        result.push(new NGFDemoFileEntryDisplay(i + 1, entry.name, sizeText, typeText));
      }
      this.fileEntries = result;
      logger.info(TAG, `目录列表: count=${result.length}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.statusMessage = `列出目录异常: ${message}`;
    }
  }
}
