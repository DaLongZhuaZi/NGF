import {
  NGFAccessibilityBindingListener,
  NGFAccessibilityLifecycleBinding,
  NGFA11yTextScale,
  NGFInclusiveDesignResolved,
  a11yTouchTarget,
  ngfAccessibilityFacade,
  resolveA11yTextScaleForCurrent
} from 'ngf_framework';
import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import { pasteboard } from '@kit.BasicServicesKit';
import unifiedDataChannel from '@ohos.data.unifiedDataChannel';
import uiMaterial from '@ohos.arkui.uiMaterial';
import {
  SYSTEM_SYMBOL_GROUPS,
  SYSTEM_SYMBOL_TOTAL_COUNT,
  SystemSymbolResourceGroup
} from 'ngf_framework';
import { logger } from 'ngf_framework';
import { NGFControlStyleTokens } from 'ngf_framework';
import { NGFMaterialBackgroundEffectOptions } from 'ngf_framework';
import { NGFMaterialShadowOptions } from 'ngf_framework';
import { NGFMaterialSurfaceTokens } from 'ngf_framework';
import { NGFSystemMaterialPolicy } from 'ngf_framework';
import { ngfOverlayManagerFacade } from 'ngf_framework';
import { ngfVisualEffectsFacade } from 'ngf_framework';
import { NGFImmersiveTopChromePresetFactory, NGFImmersiveTopChromeSpec, NGFImmersiveTopChromeUnderlay } from 'ngf_framework';
import { NGFHdsTitleBarOptionsFactory } from 'ngf_framework';
import { ngfDragDropManagerFacade } from 'ngf_framework';
import { NGFPageWindowName, NGFPageWindowSupport } from './NGFPageWindowSupport';

const TAG: string = 'NGFSystemResourcePreviewPage';
const SYMBOL_GRID_BATCH_SIZE: number = 120;
const SYMBOL_SEARCH_BATCH_SIZE: number = 160;

const SYSTEM_SYMBOL_TOP_CHROME: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#0B1020',
  '#21365F',
  '#0E172A',
  '#60A5FAD8',
  '#F59E0BD8',
  168,
  96
);

type NGFSystemSymbolError = Error | string | number | boolean | null | undefined;

@Component
export struct NGFSystemResourcePreviewPage {
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


  @State private pathStack: NavPathStack = new NavPathStack();
  @State private topInsetVp: number = 108;
  @State private selectedGroupName: string = '';
  @State private currentGroupItems: Array<string> = [];
  @State private visibleGroupSymbols: Array<string> = [];
  @State private searchText: string = '';
  @State private searchResults: Array<string> = [];
  @State private visibleSearchItems: Array<string> = [];
  @State private isSearching: boolean = false;
  @State private visibleGridItemCount: number = SYMBOL_GRID_BATCH_SIZE;
  @State private visibleSearchResultCount: number = SYMBOL_SEARCH_BATCH_SIZE;
  @State private selectedSymbolName: string = 'ohos_arrow_up';
  @State private statusText: ResourceStr = $r('app.string.ui_str_2435');
  @State private droppedSymbol: string = '';
  @StorageProp('ngf_visual_effects_system_material_policy') private systemMaterialPolicy: string = 'auto';
  @StorageProp('ngf_visual_effects_system_material_state') private systemMaterialState: number = 0;
  @StorageProp('ngf_visual_effects_should_use_system_material_surface') private useSysMat: boolean = true;
  private readonly scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.attachA11yBinding();
    NGFPageWindowSupport.loadDynamicTopInset(this.getUIContext(), 108, 108, (inset) => {
      this.topInsetVp = inset;
    });
    NGFPageWindowSupport.apply(NGFPageWindowName.SYSTEM_RESOURCE_PREVIEW);
    this.ensureSelectedGroup();
    this.ensureSelectedSymbol();
    logger.info(TAG, '系统 Symbol 预览页出现：total=' + SYSTEM_SYMBOL_TOTAL_COUNT);
  }

  aboutToDisappear(): void {
    this.detachA11yBinding();
    NGFPageWindowSupport.restoreMainMenu();
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: SYSTEM_SYMBOL_TOP_CHROME })

        Scroll(this.scroller) {
          Column({ space: this.a11yScale.paragraphSpacing(12, 18) }) {
            this.buildSummaryPanel()
            this.buildDropZonePanel()
            this.buildSearchPanel()
            if (this.isSearching) {
              this.buildSearchResultsPanel()
            } else {
              this.buildGroupPanel()
              this.buildSymbolGridPanel()
            }
          }
          .width('100%')
          .padding({
            left: 16,
            right: 16,
            top: this.topInsetVp,
            bottom: 36
          })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .backgroundColor($r('app.color.background_transparent'))
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .onScrollStop((): void => {
          this.loadMoreForCurrentMode();
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background_primary'))
    }
    .titleBar(NGFHdsTitleBarOptionsFactory.build(
      $r('app.string.ui_str_2436'),
      $r('app.string.ui_str_2437'),
      '#0B1020',
      hdsMaterial.MaterialLevel.GENTLE,
      true,
      false
    ))
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .mode(NavDestinationMode.STANDARD)
    .bindToScrollable([this.scroller])
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .onReady((context: NavDestinationContext): void => {
      this.pathStack = context.pathStack;
    })
    .onBackPressed((): boolean => {
      if (this.isSearching) {
        this.clearSearch();
        return true;
      }
      NGFPageWindowSupport.restoreMainMenu();
      this.pathStack.pop();
      return true;
    })
    .backgroundColor($r('app.color.background_primary'))
  }

  @Builder
  private buildSummaryPanel(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {}
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)
        .borderRadius(NGFMaterialSurfaceTokens.PROMINENT_RADIUS)

      Column({ space: this.a11yScale.paragraphSpacing(12, 18) }) {
        Row({ space: 12 }) {
          this.buildPreviewGlyph(this.selectedSymbolName, 46, $r('app.color.text_primary'))

          Column({ space: this.a11yScale.paragraphSpacing(5, 18) }) {
            Text(this.selectedSymbolName)
              .fontSize(this.a11yScale.font(18))
              .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(18)))
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(this.getSelectedSymbolReference())
              .fontSize(this.a11yScale.font(12))
              .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Row({ space: 8 }) {
          this.buildMetricPill($r('app.string.ui_str_2438'), String(SYSTEM_SYMBOL_TOTAL_COUNT))
          this.buildMetricPill($r('app.string.ui_str_2439'), String(SYSTEM_SYMBOL_GROUPS.length))
          this.buildMetricPill($r('app.string.ui_str_2440'), String(this.getCurrentGridItemCount()))
        }
        .width('100%')

        Row({ space: 10 }) {
          Button() {
            Row({ space: 6 }) {
              // 装饰图标：按钮文字紧随其后
              SymbolGlyph($r('sys.symbol.doc_plaintext_and_checkmark'))
                .fontSize(this.a11yScale.font(17))
                .fontColor([this.resolveGlassActionTextColor(true)])
                .accessibilityLevel('no')
              Text($r('app.string.ui_str_2441'))
                .fontSize(this.a11yScale.font(13))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
                .fontWeight(FontWeight.Medium)
                .fontColor(this.resolveGlassActionTextColor(true))
            }
          }
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .padding({ left: 14, right: 14 })
          .borderRadius(12)
          .backgroundColor(this.resolveGlassPrimaryActionBackground())
          .onClick((): void => {
            void this.copySymbolName(this.selectedSymbolName);
          })

          Text(this.statusText)
            .fontSize(this.a11yScale.font(12))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
            .fontColor($r('app.color.text_secondary'))
            .layoutWeight(1)
            .maxLines(2)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.Transparent)
      .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwareProminentBackgroundEffect(this.useSysMat))
      .borderRadius(NGFMaterialSurfaceTokens.PROMINENT_RADIUS)
      .shadow(NGFMaterialSurfaceTokens.buildMaterialAwareProminentShadow(this.useSysMat))
    }
    .width('100%')
  }

  @Builder
  private buildDropZonePanel(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Text(this.droppedSymbol ? '已接收拖放 Symbol: ' + this.droppedSymbol : '长按拖拽下方 Symbol 到此处，测试 UDMF')
        .fontSize(this.a11yScale.font(14))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .height(60)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.resolveGlassPanelBackground())
    .backgroundEffect(this.buildGlassPanelBackgroundEffect())
    .borderRadius(12)
    .border({
      width: this.resolveGlassPanelBorderWidth(),
      color: this.resolveGlassDropZoneBorderColor(),
      style: BorderStyle.Dashed
    })
    .onDrop((event: DragEvent, extraParams: string) => {
      try {
        const data = event.getData();
        if (data) {
          const text = ngfDragDropManagerFacade.extractPlainText(data as unifiedDataChannel.UnifiedData);
          if (text) {
            this.droppedSymbol = text;
            this.statusText = '拖放成功: ' + text;
            ngfOverlayManagerFacade.showToast('拖放成功: ' + text);
          }
        }
      } catch (err) {
        logger.error(TAG, 'onDrop 处理失败: ' + err);
      }
    })
  }

  @Builder
  private buildMetricPill(label: ResourceStr, value: ResourceStr): void {
    Column({ space: this.a11yScale.paragraphSpacing(2, 18) }) {
      Text(label)
        .fontSize(this.a11yScale.font(11))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(11)))
        .fontColor($r('app.color.text_secondary'))
      Text(value)
        .fontSize(this.a11yScale.font(15))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding({ top: 8, bottom: 8 })
    .backgroundColor(this.resolveGlassFloatingControlBackground())
    .backgroundEffect(this.buildGlassControlBackgroundEffect())
    .borderRadius(12)
    // 无障碍分组（官方「使用建议」：对复杂布局减少冗余播报）。
    // 不分组时读屏把「标签」与「数值」当成**两个独立节点**，
    // 用户会听到一个孤立的数值，不知道它属于哪个标签。
    .accessibilityGroup(true)
  }

  @Builder
  private buildSearchPanel(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Search({ value: this.searchText, placeholder: $r('app.string.ui_str_2442') })
        .width('100%')
        .height(44)
        .searchButton($r('app.string.ui_str_2443'))
        .backgroundColor(this.resolveGlassFloatingControlBackground())
        .backgroundEffect(this.buildGlassControlBackgroundEffect())
        .placeholderColor($r('app.color.text_tertiary'))
        .textFont({ size: 14 })
        .placeholderFont({ size: 14 })
        .onChange((value: string): void => {
          this.searchText = value;
          if (value.trim().length <= 0) {
            this.clearSearch();
          }
        })
        .onSubmit((value: string): void => {
          this.searchText = value;
          this.performSearch();
        })

      Row({ space: 8 }) {
        Button($r('app.string.ui_str_2444'))
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE))
          .fontColor(this.resolveGlassActionTextColor(!this.isSearching))
          .backgroundColor(this.resolveGlassSegmentButtonBackground(!this.isSearching))
          .borderRadius(12)
          .onClick((): void => {
            this.clearSearch();
          })

        if (this.isSearching) {
          Text($r('app.string.search_results_status', this.searchResults.length, this.getVisibleSearchResultCount()))
            .fontSize(this.a11yScale.font(12))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
            .fontColor($r('app.color.text_secondary'))
            .layoutWeight(1)
        } else {
          Text(this.getSelectedGroupSummaryText())
            .fontSize(this.a11yScale.font(12))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
            .fontColor($r('app.color.text_secondary'))
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.resolveGlassPanelBackground())
    .backgroundEffect(this.buildGlassPanelBackgroundEffect())
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({ width: this.resolveGlassPanelBorderWidth(), color: this.resolveGlassPanelBorderColor() })
    .shadow(this.buildGlassPanelShadow())
  }

  @Builder
  private buildGroupPanel(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Row() {
        Text($r('app.string.ui_str_2445'))
          .fontSize(this.a11yScale.font(16))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Text(String(SYSTEM_SYMBOL_GROUPS.length))
          .fontSize(this.a11yScale.font(12))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
          .fontColor($r('app.color.text_tertiary'))
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(SYSTEM_SYMBOL_GROUPS, (group: SystemSymbolResourceGroup) => {
          Button() {
            Row({ space: 6 }) {
              Text(group.name)
                .fontSize(this.a11yScale.font(12))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
                .fontWeight(this.isSelectedGroup(group.name) ? FontWeight.Medium : FontWeight.Normal)
                .fontColor(this.resolveGlassActionTextColor(this.isSelectedGroup(group.name)))
                .maxLines(1)
              Text(String(group.items.length))
                .fontSize(this.a11yScale.font(11))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(11)))
                .fontColor(this.resolveGlassActionMetaColor(this.isSelectedGroup(group.name)))
            }
          }
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .padding({ left: 12, right: 12 })
          .borderRadius(14)
          .backgroundColor(this.resolveGlassSegmentButtonBackground(this.isSelectedGroup(group.name)))
          .margin({ right: 8, bottom: 8 })
          .onClick((): void => {
            this.selectGroup(group.name);
          })
        }, (group: SystemSymbolResourceGroup): string => group.name)
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.resolveGlassPanelBackground())
    .backgroundEffect(this.buildGlassPanelBackgroundEffect())
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({ width: this.resolveGlassPanelBorderWidth(), color: this.resolveGlassPanelBorderColor() })
    .shadow(this.buildGlassPanelShadow())
  }

  @Builder
  private buildSymbolGridPanel(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      this.buildGridHeader(this.getCurrentGridItemCount(), this.getVisibleCurrentGridItemCount())
      this.buildCurrentSymbolGrid()
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.resolveGlassPanelBackground())
    .backgroundEffect(this.buildGlassPanelBackgroundEffect())
    .borderRadius(18)
    .border({ width: this.resolveGlassPanelBorderWidth(), color: this.resolveGlassPanelBorderColor() })
    .shadow(this.buildGlassPanelShadow())
  }

  @Builder
  private buildSearchResultsPanel(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      this.buildGridHeader(this.searchResults.length, this.getVisibleSearchResultCount())

      if (this.searchResults.length <= 0) {
        Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
          // 空态插图：纯装饰，含义由下面的文字传达。
          // 整组作为**一个**信息单元播报，避免读屏用户听到孤立的图标。
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(this.a11yScale.font(44))
            .fontColor([$r('app.color.text_tertiary')])
            .accessibilityLevel('no')
          Text($r('app.string.ui_str_2446'))
            .fontSize(this.a11yScale.font(14))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding({ top: 36, bottom: 36 })
        // 官方「使用建议」：分组优化 —— 对复杂布局减少冗余播报
        .accessibilityGroup(true)
      } else {
        this.buildSearchSymbolGrid()
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.resolveGlassPanelBackground())
    .backgroundEffect(this.buildGlassPanelBackgroundEffect())
    .borderRadius(18)
    .border({ width: this.resolveGlassPanelBorderWidth(), color: this.resolveGlassPanelBorderColor() })
    .shadow(this.buildGlassPanelShadow())
  }

  @Builder
  private buildGridHeader(totalCount: number, visibleCount: number): void {
    Row() {
      Text(this.isSearching ? $r('app.string.ui_str_2447') : this.getCurrentGroupName())
        .fontSize(this.a11yScale.font(16))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(visibleCount + '/' + totalCount)
        .fontSize(this.a11yScale.font(12))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
        .fontColor($r('app.color.text_tertiary'))
    }
    .width('100%')
  }

  @Builder
  private buildCurrentSymbolGrid(): void {
    Grid() {
      ForEach(this.visibleGroupSymbols, (itemName: string) => {
        GridItem() {
          this.buildSymbolCell(itemName)
        }
        .aspectRatio(1)
      }, (itemName: string): string => itemName)
    }
    .width('100%')
    .columnsTemplate('1fr 1fr 1fr 1fr')
    .columnsGap(8)
    .rowsGap(8)
  }

  @Builder
  private buildSearchSymbolGrid(): void {
    Grid() {
      ForEach(this.visibleSearchItems, (itemName: string) => {
        GridItem() {
          this.buildSymbolCell(itemName)
        }
        .aspectRatio(1)
      }, (itemName: string): string => itemName)
    }
    .width('100%')
    .columnsTemplate('1fr 1fr 1fr 1fr')
    .columnsGap(8)
    .rowsGap(8)
  }

  @Builder
  private buildDragPreview(itemName: string): void {
    Column({ space: this.a11yScale.paragraphSpacing(7, 18) }) {
      this.buildPreviewGlyph(itemName, 32, $r('app.color.text_primary'))
    }
    .width(60)
    .height(60)
    .justifyContent(FlexAlign.Center)
    .borderRadius(12)
    .backgroundColor(this.resolveGlassFloatingControlBackground())
  }

  @Builder
  private buildSymbolCell(itemName: string): void {
    Column({ space: this.a11yScale.paragraphSpacing(7, 18) }) {
      this.buildPreviewGlyph(itemName, 27, this.getSymbolIconColor(itemName))

      Text(itemName)
        .fontSize(this.a11yScale.font(9))
        .lineHeight(this.a11yScale.explicitLineHeight(this.a11yScale.font(9), 12))
        .fontWeight(this.isSelectedSymbol(itemName) ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.getSymbolTextColor(itemName))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding(7)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.getSymbolCellBackgroundColor(itemName))
    .borderRadius(12)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(this.isSelectedSymbol(itemName) ? 1.5 : 1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.card_border'), this.useSysMat)
    })
    .onClick((): void => {
      this.selectSymbol(itemName);
      void this.copySymbolName(itemName);
    })
    .onDragStart((event: DragEvent, extraParams: string): CustomBuilder | void => {
      try {
        const data = ngfDragDropManagerFacade.createPlainTextDragData(itemName);
        if (data) {
          event.setData(data as unifiedDataChannel.UnifiedData);
        }
      } catch (err) {
        logger.error(TAG, 'onDragStart 处理失败: ' + err);
      }
      return this.buildDragPreview(itemName);
    })
  }

  @Builder
  private buildPreviewGlyph(itemName: string, size: number, color: ResourceColor): void {
    // 装饰图标：含义由相邻文字传达
    SymbolGlyph($r('sys.symbol.' + itemName))
      .fontSize(this.a11yScale.font(size))
      .fontColor([color])
      .accessibilityLevel('no')
  }

  private ensureSelectedSymbol(): void {
    if (this.selectedSymbolName.length > 0) {
      return;
    }

    const currentItems: Array<string> = this.getCurrentGridItems();
    if (currentItems.length > 0) {
      this.selectedSymbolName = currentItems[0];
    }
  }

  private ensureSelectedGroup(): void {
    const selectedGroup: SystemSymbolResourceGroup | null = this.findGroupByName(this.selectedGroupName);
    if (selectedGroup !== null) {
      if (this.currentGroupItems.length <= 0) {
        this.currentGroupItems = this.copyStringItems(selectedGroup.items);
        this.refreshVisibleGroupSymbols();
      }
      return;
    }

    if (SYSTEM_SYMBOL_GROUPS.length > 0) {
      const group: SystemSymbolResourceGroup = SYSTEM_SYMBOL_GROUPS[0];
      this.selectedGroupName = group.name;
      this.currentGroupItems = this.copyStringItems(group.items);
      this.refreshVisibleGroupSymbols();
    }
  }

  private getSelectedSymbolReference(): string {
    return '$r(\'sys.symbol.' + this.selectedSymbolName + '\')';
  }

  private getCurrentGroup(): SystemSymbolResourceGroup | null {
    const selectedGroup: SystemSymbolResourceGroup | null = this.findGroupByName(this.selectedGroupName);
    if (selectedGroup !== null) {
      return selectedGroup;
    }

    if (SYSTEM_SYMBOL_GROUPS.length > 0) {
      return SYSTEM_SYMBOL_GROUPS[0];
    }
    return null;
  }

  private getCurrentGroupName(): ResourceStr {
    const group: SystemSymbolResourceGroup | null = this.getCurrentGroup();
    if (!group) {
      return $r('app.string.ui_str_2448');
    }
    return group.name;
  }

  private getSelectedGroupSummaryText(): ResourceStr {
    const group: SystemSymbolResourceGroup | null = this.getCurrentGroup();
    if (!group) {
      return $r('app.string.ui_str_2449');
    }
    return group.name + ' · ' + group.items.length + ' 个 Symbol';
  }

  private getCurrentGridItems(): Array<string> {
    if (this.currentGroupItems.length > 0) {
      return this.currentGroupItems;
    }

    const group: SystemSymbolResourceGroup | null = this.getCurrentGroup();
    if (group !== null) {
      return group.items;
    }
    return [];
  }

  private getCurrentGridItemCount(): number {
    return this.getCurrentGridItems().length;
  }

  private getVisibleCurrentGridItemCount(): number {
    return this.visibleGroupSymbols.length;
  }

  private hasMoreCurrentGridItems(): boolean {
    return this.getVisibleCurrentGridItemCount() < this.getCurrentGridItemCount();
  }

  private loadMoreCurrentGridItems(): void {
    const totalCount: number = this.getCurrentGridItemCount();
    this.visibleGridItemCount = Math.min(totalCount, this.visibleGridItemCount + SYMBOL_GRID_BATCH_SIZE);
    this.refreshVisibleGroupSymbols();
  }

  private getVisibleSearchResultCount(): number {
    return this.visibleSearchItems.length;
  }

  private hasMoreSearchResults(): boolean {
    return this.getVisibleSearchResultCount() < this.searchResults.length;
  }

  private loadMoreSearchResults(): void {
    this.visibleSearchResultCount = Math.min(
      this.searchResults.length,
      this.visibleSearchResultCount + SYMBOL_SEARCH_BATCH_SIZE
    );
    this.refreshVisibleSearchItems();
  }

  private loadMoreForCurrentMode(): void {
    if (this.isSearching) {
      if (this.hasMoreSearchResults()) {
        this.loadMoreSearchResults();
      }
      return;
    }

    if (this.hasMoreCurrentGridItems()) {
      this.loadMoreCurrentGridItems();
    }
  }

  private selectGroup(groupName: string): void {
    const group: SystemSymbolResourceGroup | null = this.findGroupByName(groupName);
    if (group === null) {
      return;
    }
    this.selectedGroupName = group.name;
    this.currentGroupItems = this.copyStringItems(group.items);
    this.visibleGridItemCount = SYMBOL_GRID_BATCH_SIZE;
    this.refreshVisibleGroupSymbols();
    this.searchText = '';
    this.searchResults = [];
    this.visibleSearchItems = [];
    this.isSearching = false;
    this.visibleSearchResultCount = SYMBOL_SEARCH_BATCH_SIZE;
    const items: Array<string> = group.items;
    if (items.length > 0) {
      this.selectedSymbolName = items[0];
    }
    this.statusText = this.getSelectedGroupSummaryText();
  }

  private isSelectedGroup(groupName: string): boolean {
    const group: SystemSymbolResourceGroup | null = this.getCurrentGroup();
    if (group === null) {
      return false;
    }
    return group.name === groupName;
  }

  private findGroupByName(groupName: string): SystemSymbolResourceGroup | null {
    for (let index = 0; index < SYSTEM_SYMBOL_GROUPS.length; index++) {
      const group: SystemSymbolResourceGroup = SYSTEM_SYMBOL_GROUPS[index];
      if (group.name === groupName) {
        return group;
      }
    }
    return null;
  }

  private copyStringItems(items: Array<string>): Array<string> {
    const copiedItems: Array<string> = [];
    for (let index = 0; index < items.length; index++) {
      copiedItems.push(items[index]);
    }
    return copiedItems;
  }

  private copyLimitedStringItems(items: Array<string>, limit: number): Array<string> {
    const copiedItems: Array<string> = [];
    const maxCount: number = Math.min(items.length, limit);
    for (let index = 0; index < maxCount; index++) {
      copiedItems.push(items[index]);
    }
    return copiedItems;
  }

  private refreshVisibleGroupSymbols(): void {
    this.visibleGroupSymbols = this.copyLimitedStringItems(this.currentGroupItems, this.visibleGridItemCount);
  }

  private refreshVisibleSearchItems(): void {
    this.visibleSearchItems = this.copyLimitedStringItems(this.searchResults, this.visibleSearchResultCount);
  }

  private selectSymbol(symbolName: string): void {
    this.selectedSymbolName = symbolName;
    this.statusText = this.getSelectedSymbolReference();
  }

  private isSelectedSymbol(symbolName: string): boolean {
    return symbolName === this.selectedSymbolName;
  }

  private getSymbolCellBackgroundColor(symbolName: string): ResourceColor {
    return NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat);
  }

  private getSymbolCellMaterial(symbolName: string): uiMaterial.Material | undefined {
    if (this.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED) {
      return uiMaterial.Material.empty;
    }
    return this.isSelectedSymbol(symbolName)
      ? ngfVisualEffectsFacade.buildSystemMaterialForFloatingControl()
      : ngfVisualEffectsFacade.buildSystemMaterialForLightEffectControl();
  }

  /**
   * 是否改用「系统材质」的透明表面。
   *
   * ⚠️ **不要在这里再写一份判断。**
   * 本方法原先**复制**了 `NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface()` 的逻辑，
   * 于是「普通组件不再使用系统材质」这个决策（项目规则 **PR-006**）传不到本页：
   * 面板背景被判为透明、模糊与描边一并被置空，深色文字直接压在沉浸式渐变上，
   * 实测对比度只有 1.5~2.3:1（附件2 §1.3 要求 4.5:1）。
   * 现统一委托给令牌层，**决策只保留一处**。
   */
  private shouldUseTransparentSystemMaterialSurface(): boolean {
    return NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface();
  }

  private resolveGlassPanelBackground(): ResourceColor {
    return this.shouldUseTransparentSystemMaterialSurface() ? Color.Transparent : $r('app.color.panel_background');
  }

  private resolveGlassPanelBorderWidth(): number {
    return this.shouldUseTransparentSystemMaterialSurface() ? 0 : NGFMaterialSurfaceTokens.BORDER_WIDTH;
  }

  private resolveGlassPanelBorderColor(): ResourceColor {
    return this.shouldUseTransparentSystemMaterialSurface() ? Color.Transparent : $r('app.color.panel_border');
  }

  private resolveGlassDropZoneBorderColor(): ResourceColor {
    return this.shouldUseTransparentSystemMaterialSurface() ? Color.Transparent : $r('app.color.panel_border');
  }

  private buildGlassPanelBackgroundEffect(): NGFMaterialBackgroundEffectOptions | undefined {
    if (this.shouldUseTransparentSystemMaterialSurface()) {
      return undefined;
    }
    return NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect(this.useSysMat);
  }

  private buildGlassPanelShadow(): NGFMaterialShadowOptions | undefined {
    if (this.shouldUseTransparentSystemMaterialSurface()) {
      return undefined;
    }
    return NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow(this.useSysMat);
  }

  private resolveGlassFloatingControlBackground(): ResourceColor {
    return this.shouldUseTransparentSystemMaterialSurface() ? Color.Transparent : $r('app.color.background_surface');
  }

  private buildGlassControlBackgroundEffect(): NGFMaterialBackgroundEffectOptions | undefined {
    if (this.shouldUseTransparentSystemMaterialSurface()) {
      return undefined;
    }
    return NGFMaterialSurfaceTokens.buildMaterialAwareControlBackgroundEffect(this.useSysMat);
  }

  private resolveGlassFloatingControlMaterial(): uiMaterial.Material | undefined {
    if (this.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED) {
      return uiMaterial.Material.empty;
    }
    return ngfVisualEffectsFacade.buildSystemMaterialForFloatingControl();
  }

  private resolveGlassPrimaryActionBackground(): ResourceColor {
    return this.shouldUseTransparentSystemMaterialSurface() ? Color.Transparent : $r('app.color.background_surface');
  }

  private resolveGlassPrimaryActionMaterial(): uiMaterial.Material | undefined {
    if (this.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED) {
      return uiMaterial.Material.empty;
    }
    return this.shouldUseTransparentSystemMaterialSurface()
      ? ngfVisualEffectsFacade.buildSystemMaterialForFloatingControl()
      : undefined;
  }

  private resolveGlassSegmentButtonBackground(selected: boolean): ResourceColor {
    if (this.shouldUseTransparentSystemMaterialSurface()) {
      return Color.Transparent;
    }
    if (selected) {
      return $r('app.color.background_surface');
    }
    return Color.Transparent;
  }

  private resolveGlassSegmentButtonMaterial(selected: boolean): uiMaterial.Material | undefined {
    if (this.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED) {
      return uiMaterial.Material.empty;
    }
    if (!this.shouldUseTransparentSystemMaterialSurface()) {
      return undefined;
    }
    return selected
      ? ngfVisualEffectsFacade.buildSystemMaterialForFloatingControl()
      : ngfVisualEffectsFacade.buildSystemMaterialForLightEffectControl();
  }

  private resolveGlassActionTextColor(selected: boolean): ResourceColor {
    return selected ? $r('app.color.text_primary') : $r('app.color.text_secondary');
  }

  private resolveGlassActionMetaColor(selected: boolean): ResourceColor {
    return selected ? $r('app.color.text_secondary') : $r('app.color.text_tertiary');
  }

  private getSymbolIconColor(symbolName: string): ResourceColor {
    return this.isSelectedSymbol(symbolName) ? $r('app.color.text_primary') : $r('app.color.text_secondary');
  }

  private getSymbolTextColor(symbolName: string): ResourceColor {
    return this.isSelectedSymbol(symbolName) ? $r('app.color.text_primary') : $r('app.color.text_secondary');
  }

  private performSearch(): void {
    const keyword: string = this.searchText.trim().toLowerCase();
    if (keyword.length <= 0) {
      this.clearSearch();
      return;
    }

    const results: Array<string> = [];
    for (let groupIndex = 0; groupIndex < SYSTEM_SYMBOL_GROUPS.length; groupIndex++) {
      const group: SystemSymbolResourceGroup = SYSTEM_SYMBOL_GROUPS[groupIndex];
      for (let itemIndex = 0; itemIndex < group.items.length; itemIndex++) {
        const itemName: string = group.items[itemIndex];
        if (itemName.toLowerCase().includes(keyword)) {
          results.push(itemName);
        }
      }
    }

    this.isSearching = true;
    this.searchResults = this.copyStringItems(results);
    this.visibleSearchResultCount = SYMBOL_SEARCH_BATCH_SIZE;
    this.refreshVisibleSearchItems();
    this.statusText = '搜索 ' + keyword + '：' + String(results.length) + ' 个结果';
    logger.info(TAG, '搜索系统 Symbol：keyword=' + keyword + ', count=' + String(results.length));
  }

  private clearSearch(): void {
    this.searchText = '';
    this.searchResults = [];
    this.visibleSearchItems = [];
    this.isSearching = false;
    this.visibleSearchResultCount = SYMBOL_SEARCH_BATCH_SIZE;
    this.statusText = this.getSelectedGroupSummaryText();
  }

  private async copySymbolName(symbolName: string): Promise<void> {
    const fullName: string = '$r(\'sys.symbol.' + symbolName + '\')';
    try {
      const pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, fullName);
      const systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      await systemPasteboard.setData(pasteData);
      this.statusText = '已复制 ' + fullName;
      ngfOverlayManagerFacade.showToast('已复制 ' + fullName);
      logger.info(TAG, '复制系统 Symbol 引用：' + fullName);
    } catch (error) {
      const message: string = this.formatError(error as NGFSystemSymbolError);
      this.statusText = '复制失败：' + message;
      try {
        ngfOverlayManagerFacade.showToast($r('app.string.ui_str_2450'));
      } catch (toastError) {
        logger.warn(TAG, '复制失败后 Toast 显示异常：' + toastError);
      }
      logger.warn(TAG, '复制系统 Symbol 引用失败：' + message);
    }
  }

  private formatError(error: NGFSystemSymbolError): string {
    if (error instanceof Error) {
      return error.message;
    }
    if (error === null || error === undefined) {
      return 'empty error';
    }
    return String(error);
  }
}
