import { HdsNavDestination } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import { logger } from 'ngf_framework';
import { resolveResourceString } from 'ngf_framework';
import { FileUtils, NGFFileEntry } from 'ngf_framework';
import { ngfContentCacheFacade } from 'ngf_framework';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from 'ngf_framework';
import { NGFHdsTitleBarOptionsFactory } from 'ngf_framework';
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
  @State private topInsetVp: number = 108;
  @State private fileWriteInput: ResourceStr = $r('app.string.ui_str_2231');
  @State private fileReadResult: string = '';
  @State private fileEntries: Array<NGFDemoFileEntryDisplay> = [];
  @State private cacheKey: string = 'demo_key';
  @State private cacheValue: string = 'demo_value';
  @State private cacheGetResult: ResourceStr = '';
  @State private cacheHasResult: ResourceStr = '';
  @State private cacheMemorySize: number = 0;
  @State private statusMessage: ResourceStr = '';

  aboutToAppear(): void {
    NGFPageWindowSupport.loadDynamicTopInset(this.getUIContext(), 108, 108, (inset) => {
      this.topInsetVp = inset;
    });
    NGFPageWindowSupport.apply(NGFPageWindowName.DEMO_DATA_STORAGE);
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: DEMO_DATA_TOP_CHROME })

        Scroll() {
          Column({ space: 12 }) {
            this.buildTitleCard()
            this.buildFileReadWriteSection()
            this.buildDirectorySection()
            this.buildCacheSection()
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
      $r('app.string.ui_str_2049'),
      $r('app.string.ui_str_2232'),
      '#1A0F08',
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
      Text($r('app.string.ui_str_2233'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.panel_background'))
      Text($r('app.string.ui_str_2234'))
        .fontSize(13)
        .lineHeight(20)
        .fontColor($r('app.color.text_white_low'))
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
      Text($r('app.string.ui_str_2235'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      TextInput({ text: this.fileWriteInput, placeholder: $r('app.string.ui_str_2236') })
        .width('100%')
        .height(44)
        .fontSize(14)
        .onChange((value: string): void => {
          this.fileWriteInput = value;
        })

      Row({ space: 10 }) {
        Button($r('app.string.ui_str_2237'))
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor($r('app.color.tag_amber'))
          .onClick((): void => {
            void this.handleFileWrite();
          })
        Button($r('app.string.ui_str_2238'))
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor($r('app.color.tag_cyan'))
          .onClick((): void => {
            void this.handleFileRead();
          })
      }
      .width('100%')

      if (this.fileReadResult.length > 0) {
        Column({ space: 4 }) {
          Text($r('app.string.ui_str_2239'))
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
          Text(this.fileReadResult)
            .fontSize(13)
            .fontColor($r('app.color.text_body'))
            .width('100%')
            .padding(10)
            .backgroundColor($r('app.color.background_surface'))
            .borderRadius(10)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      if ((typeof this.statusMessage === "string" ? this.statusMessage : '').length > 0) {
        Text(this.statusMessage)
          .fontSize(12)
          .fontColor($r('app.color.tag_green'))
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
  private buildDirectorySection(): void {
    Column({ space: 10 }) {
      Text($r('app.string.ui_str_2240'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Button($r('app.string.ui_str_2241'))
        .width('100%')
        .height(40)
        .fontSize(14)
        .borderRadius(12)
        .backgroundColor($r('app.color.tag_purple'))
        .onClick((): void => {
          void this.handleListDirectory();
        })

      if (this.fileEntries.length > 0) {
        Column({ space: 4 }) {
          ForEach(this.fileEntries, (entry: NGFDemoFileEntryDisplay) => {
            Row() {
              Text(entry.name)
                .fontSize(13)
                .fontColor($r('app.color.text_body'))
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(entry.sizeText)
                .fontSize(12)
                .fontColor($r('app.color.text_tertiary'))
                .margin({ left: 8 })
              Text(entry.typeText)
                .fontSize(11)
                .fontColor($r('app.color.panel_background'))
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor(entry.typeText === 'DIR' ? $r('app.color.tag_purple') : $r('app.color.tag_cyan'))
                .borderRadius(6)
                .margin({ left: 8 })
            }
            .width('100%')
            .padding({ top: 6, bottom: 6, left: 10, right: 10 })
            .backgroundColor($r('app.color.background_surface'))
            .borderRadius(8)
          }, (entry: NGFDemoFileEntryDisplay): string => `file_${entry.id}`)
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
  private buildCacheSection(): void {
    Column({ space: 10 }) {
      Text($r('app.string.ui_str_2242'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      TextInput({ text: this.cacheKey, placeholder: $r('app.string.ui_str_2243') })
        .width('100%')
        .height(40)
        .fontSize(14)
        .onChange((value: string): void => {
          this.cacheKey = value;
        })

      TextInput({ text: this.cacheValue, placeholder: $r('app.string.ui_str_2244') })
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
          .backgroundColor($r('app.color.tag_green'))
          .onClick((): void => {
            ngfContentCacheFacade.put(this.cacheKey, this.cacheValue, 300000);
            this.cacheMemorySize = ngfContentCacheFacade.memorySize();
            this.statusMessage = $r('app.string.ui_str_2245', this.cacheKey);
          })
        Button('Get')
          .layoutWeight(1)
          .height(36)
          .fontSize(13)
          .borderRadius(10)
          .backgroundColor($r('app.color.button_primary'))
          .onClick((): void => {
            const value = ngfContentCacheFacade.get(this.cacheKey);
            const valStr = typeof value === 'string' ? value : ''; this.cacheGetResult = valStr.length > 0 ? valStr : $r('app.string.ui_str_2246');
          })
        Button('Has')
          .layoutWeight(1)
          .height(36)
          .fontSize(13)
          .borderRadius(10)
          .backgroundColor($r('app.color.tag_purple'))
          .onClick((): void => {
            const exists = ngfContentCacheFacade.has(this.cacheKey);
            this.cacheHasResult = exists ? $r('app.string.ui_str_2247') : $r('app.string.ui_str_2248');
          })
        Button('Del')
          .layoutWeight(1)
          .height(36)
          .fontSize(13)
          .borderRadius(10)
          .backgroundColor($r('app.color.tag_red'))
          .onClick((): void => {
            ngfContentCacheFacade.remove(this.cacheKey);
            this.cacheMemorySize = ngfContentCacheFacade.memorySize();
            this.statusMessage = $r('app.string.ui_str_2249', this.cacheKey);
          })
      }
      .width('100%')

      Column({ space: 4 }) {
        Row() {
          Text($r('app.string.ui_str_2250'))
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
          Text(this.cacheGetResult)
            .fontSize(13)
            .fontColor($r('app.color.text_body'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Row() {
          Text($r('app.string.ui_str_2251'))
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
          Text(this.cacheHasResult)
            .fontSize(13)
            .fontColor($r('app.color.text_body'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Row() {
          Text($r('app.string.ui_str_2252'))
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
          Text(`${this.cacheMemorySize}`)
            .fontSize(13)
            .fontColor($r('app.color.text_body'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .padding(10)
      .backgroundColor($r('app.color.background_surface'))
      .borderRadius(10)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.card_border') })
    .shadow({ radius: 10, color: $r('app.color.card_shadow_demo'), offsetX: 0, offsetY: 4 })
  }

  private async handleFileWrite(): Promise<void> {
    try {
      const inputStr: string = typeof this.fileWriteInput === 'string' ? this.fileWriteInput : '';
      const success: boolean = FileUtils.writeText('ngf_demo.txt', inputStr);
      this.statusMessage = success ? $r('app.string.ui_str_2253') : $r('app.string.ui_str_2254');
      logger.info(TAG, `文件写入: success=${success}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.statusMessage = $r('app.string.ui_str_2255', message);
    }
  }

  private async handleFileRead(): Promise<void> {
    try {
      const content: string = FileUtils.readText('ngf_demo.txt');
      const contentStr: string = typeof content === 'string' ? content : '';
      this.fileReadResult = contentStr.length > 0 ? contentStr : resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.ui_str_2256'));
      logger.info(TAG, `文件读取: length=${content.length}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.fileReadResult = resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.ui_str_2257', message));
    }
  }

  private async handleListDirectory(): Promise<void> {
    try {
      const entries: Array<NGFFileEntry> = FileUtils.listDirectory('');
      const result: Array<NGFDemoFileEntryDisplay> = [];
      for (let i: number = 0; i < entries.length; i++) {
        const entry: NGFFileEntry = entries[i];
        const sizeText: string = entry.isDirectory ? '-' : `${entry.size}B`;
        const typeText: string = entry.isDirectory ? 'DIR' : 'FILE';
        result.push(new NGFDemoFileEntryDisplay(i + 1, entry.name, sizeText, typeText));
      }
      this.fileEntries = result;
      logger.info(TAG, `目录列表: count=${result.length}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.statusMessage = $r('app.string.ui_str_2258', message);
    }
  }
}
