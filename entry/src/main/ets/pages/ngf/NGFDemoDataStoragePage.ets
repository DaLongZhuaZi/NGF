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
import { ngfOverlayManagerFacade } from 'ngf_framework';
import { ngfVisualEffectsFacade } from 'ngf_framework';
import { resolveResourceString } from 'ngf_framework';
import { FileUtils, NGFFileEntry } from 'ngf_framework';
import { ngfContentCacheFacade } from 'ngf_framework';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay,
  ngfMediaPickerFacade
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
    this.attachA11yBinding();
    NGFPageWindowSupport.loadDynamicTopInset(this.getUIContext(), 108, 108, (inset) => {
      this.topInsetVp = inset;
    });
    NGFPageWindowSupport.apply(NGFPageWindowName.DEMO_DATA_STORAGE);
  }

  appendLog(msg: string): void {
    this.statusMessage = msg;
    logger.info(TAG, msg);
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: DEMO_DATA_TOP_CHROME })

        Scroll() {
          Column({ space: this.a11yScale.paragraphSpacing(12, 18) }) {
            this.buildTitleCard()
            this.buildSecurityPickerSection()
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
    this.detachA11yBinding();
    NGFPageWindowSupport.restoreMainMenu();
  }

  @Builder
  private buildTitleCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
      Text($r('app.string.ui_str_2233'))
        .fontSize(this.a11yScale.font(22))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(22)))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text($r('app.string.ui_str_2234'))
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
  private buildSecurityPickerSection(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Text($r('app.string.picker_title'))
        .fontSize(this.a11yScale.font(16))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Text($r('app.string.picker_desc'))
        .fontSize(this.a11yScale.font(13))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')

      Row({ space: 10 }) {
        Button($r('app.string.picker_btn_image'))
          .layoutWeight(1)
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(14))
          .borderRadius(12)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick(async (): Promise<void> => {
            const uris = await ngfMediaPickerFacade.pickImages(1);
            if (uris.length > 0) {
              ngfOverlayManagerFacade.showToast('成功选取图片: ' + uris[0]);
              this.appendLog('安全选择图片: ' + uris[0]);
            }
          })
        Button($r('app.string.picker_btn_doc'))
          .layoutWeight(1)
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(14))
          .borderRadius(14)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick(async (): Promise<void> => {
            const uris = await ngfMediaPickerFacade.pickDocuments();
            if (uris.length > 0) {
              this.appendLog('安全选择文档: ' + uris[0]);
            }
          })
      }
      .width('100%')
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
  private buildFileReadWriteSection(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Text($r('app.string.ui_str_2235'))
        .fontSize(this.a11yScale.font(16))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      TextInput({ text: this.fileWriteInput, placeholder: $r('app.string.ui_str_2236') })
        .width('100%')
        .height(44)
        .fontSize(this.a11yScale.font(14))
        .onChange((value: string): void => {
          this.fileWriteInput = value;
        })

      Row({ space: 10 }) {
        Button($r('app.string.ui_str_2237'))
          .layoutWeight(1)
          .height(NGFControlStyleTokens.FORM_CONTROL_MIN_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.FORM_CONTROL_FONT_SIZE))
          .borderRadius(NGFControlStyleTokens.FORM_CONTROL_RADIUS)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            void this.handleFileWrite();
          })
        Button($r('app.string.ui_str_2238'))
          .layoutWeight(1)
          .height(NGFControlStyleTokens.FORM_CONTROL_MIN_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.FORM_CONTROL_FONT_SIZE))
          .borderRadius(NGFControlStyleTokens.FORM_CONTROL_RADIUS)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            void this.handleFileRead();
          })
      }
      .width('100%')

      if (this.fileReadResult.length > 0) {
        Column({ space: this.a11yScale.paragraphSpacing(4, 18) }) {
          Text($r('app.string.ui_str_2239'))
            .fontSize(this.a11yScale.font(12))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
            .fontColor($r('app.color.text_tertiary'))
          Text(this.fileReadResult)
            .fontSize(this.a11yScale.font(13))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
            .fontColor($r('app.color.text_body'))
            .width('100%')
            .padding(10)
            .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
            .borderRadius(10)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      if ((typeof this.statusMessage === "string" ? this.statusMessage : '').length > 0) {
        Text(this.statusMessage)
          .fontSize(this.a11yScale.font(12))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
          .fontColor($r('app.color.tag_green'))
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
  private buildDirectorySection(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Text($r('app.string.ui_str_2240'))
        .fontSize(this.a11yScale.font(16))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Button($r('app.string.ui_str_2241'))
        .width('100%')
        .height(NGFControlStyleTokens.FORM_CONTROL_MIN_HEIGHT)
        .controlSize(ControlSize.SMALL)
        .fontSize(this.a11yScale.font(NGFControlStyleTokens.FORM_CONTROL_FONT_SIZE))
        .borderRadius(NGFControlStyleTokens.FORM_CONTROL_RADIUS)
        .fontColor($r('app.color.text_primary'))
        .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
        .onClick((): void => {
          void this.handleListDirectory();
        })

      if (this.fileEntries.length > 0) {
        Column({ space: this.a11yScale.paragraphSpacing(4, 18) }) {
          ForEach(this.fileEntries, (entry: NGFDemoFileEntryDisplay) => {
            Row() {
              Text(entry.name)
                .fontSize(this.a11yScale.font(13))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
                .fontColor($r('app.color.text_body'))
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(entry.sizeText)
                .fontSize(this.a11yScale.font(12))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
                .fontColor($r('app.color.text_tertiary'))
                .margin({ left: 8 })
              Text(entry.typeText)
                .fontSize(this.a11yScale.font(11))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(11)))
                .fontColor(entry.typeText === 'DIR' ? $r('app.color.tag_purple') : $r('app.color.tag_cyan'))
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
                .borderRadius(6)
                .margin({ left: 8 })
            }
            .width('100%')
            .padding({ top: 6, bottom: 6, left: 10, right: 10 })
            .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
            .borderRadius(8)
          }, (entry: NGFDemoFileEntryDisplay): string => 'file_' + entry.id)
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
  private buildCacheSection(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Text($r('app.string.ui_str_2242'))
        .fontSize(this.a11yScale.font(16))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      TextInput({ text: this.cacheKey, placeholder: $r('app.string.ui_str_2243') })
        .width('100%')
        .height(NGFControlStyleTokens.FORM_CONTROL_MIN_HEIGHT)
        .fontSize(this.a11yScale.font(NGFControlStyleTokens.FORM_CONTROL_FONT_SIZE))
        .onChange((value: string): void => {
          this.cacheKey = value;
        })

      TextInput({ text: this.cacheValue, placeholder: $r('app.string.ui_str_2244') })
        .width('100%')
        .height(NGFControlStyleTokens.FORM_CONTROL_MIN_HEIGHT)
        .fontSize(this.a11yScale.font(NGFControlStyleTokens.FORM_CONTROL_FONT_SIZE))
        .onChange((value: string): void => {
          this.cacheValue = value;
        })

      Row({ space: 8 }) {
        Button('Put')
          .layoutWeight(1)
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
          .borderRadius(10)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            ngfContentCacheFacade.put(this.cacheKey, this.cacheValue, 300000);
            this.cacheMemorySize = ngfContentCacheFacade.memorySize();
            this.statusMessage = $r('app.string.ui_str_2245', this.cacheKey);
          })
        Button('Get')
          .layoutWeight(1)
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
          .borderRadius(14)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            const value = ngfContentCacheFacade.get(this.cacheKey);
            const valStr = typeof value === 'string' ? value : ''; this.cacheGetResult = valStr.length > 0 ? valStr : $r('app.string.ui_str_2246');
          })
        Button('Has')
          .layoutWeight(1)
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
          .borderRadius(10)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            const exists = ngfContentCacheFacade.has(this.cacheKey);
            this.cacheHasResult = exists ? $r('app.string.ui_str_2247') : $r('app.string.ui_str_2248');
          })
        Button('Del')
          .layoutWeight(1)
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
          .borderRadius(10)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            ngfContentCacheFacade.remove(this.cacheKey);
            this.cacheMemorySize = ngfContentCacheFacade.memorySize();
            this.statusMessage = $r('app.string.ui_str_2249', this.cacheKey);
          })
      }
      .width('100%')

      Column({ space: this.a11yScale.paragraphSpacing(4, 18) }) {
        Row() {
          Text($r('app.string.ui_str_2250'))
            .fontSize(this.a11yScale.font(12))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
            .fontColor($r('app.color.text_tertiary'))
          Text(this.cacheGetResult)
            .fontSize(this.a11yScale.font(13))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
            .fontColor($r('app.color.text_body'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Row() {
          Text($r('app.string.ui_str_2251'))
            .fontSize(this.a11yScale.font(12))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
            .fontColor($r('app.color.text_tertiary'))
          Text(this.cacheHasResult)
            .fontSize(this.a11yScale.font(13))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
            .fontColor($r('app.color.text_body'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Row() {
          Text($r('app.string.ui_str_2252'))
            .fontSize(this.a11yScale.font(12))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
            .fontColor($r('app.color.text_tertiary'))
          Text(String(this.cacheMemorySize))
            .fontSize(this.a11yScale.font(13))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
            .fontColor($r('app.color.text_body'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .padding(10)
      .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
      .borderRadius(10)
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

  private async handleFileWrite(): Promise<void> {
    try {
      const inputStr: string = typeof this.fileWriteInput === 'string' ? this.fileWriteInput : '';
      const success: boolean = FileUtils.writeText('ngf_demo.txt', inputStr);
      this.statusMessage = success ? $r('app.string.ui_str_2253') : $r('app.string.ui_str_2254');
      logger.info(TAG, '文件写入: success=' + success);
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
      logger.info(TAG, '文件读取: length=' + String(content.length));
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
        const sizeText: string = entry.isDirectory ? '-' : String(entry.size) + 'B';
        const typeText: string = entry.isDirectory ? 'DIR' : 'FILE';
        result.push(new NGFDemoFileEntryDisplay(i + 1, entry.name, sizeText, typeText));
      }
      this.fileEntries = result;
      logger.info(TAG, '目录列表: count=' + String(result.length));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.statusMessage = $r('app.string.ui_str_2258', message);
    }
  }
}
