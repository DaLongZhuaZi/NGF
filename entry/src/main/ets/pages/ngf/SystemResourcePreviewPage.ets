import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import { pasteboard } from '@kit.BasicServicesKit';
import {
  SYSTEM_SYMBOL_GROUPS,
  SYSTEM_SYMBOL_TOTAL_COUNT,
  SystemSymbolResourceGroup
} from '../../Framework/NGF/resources/SystemSymbolCatalog';
import { logger } from '../../Framework/NGF/utils/Logger';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from '../../Framework/NGF/uiShell/components/NGFImmersiveTopChrome';
import { NGFHdsTitleBarOptionsFactory } from '../../Framework/NGF/uiShell/components/HdsNavigationSupport';
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
  private readonly scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    NGFPageWindowSupport.loadDynamicTopInset(this.getUIContext(), 108, 108, (inset) => {
      this.topInsetVp = inset;
    });
    NGFPageWindowSupport.apply(NGFPageWindowName.SYSTEM_RESOURCE_PREVIEW);
    this.ensureSelectedGroup();
    this.ensureSelectedSymbol();
    logger.info(TAG, `系统 Symbol 预览页出现：total=${SYSTEM_SYMBOL_TOTAL_COUNT}`);
  }

  aboutToDisappear(): void {
    NGFPageWindowSupport.restoreMainMenu();
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: SYSTEM_SYMBOL_TOP_CHROME })

        Scroll(this.scroller) {
          Column({ space: 12 }) {
            this.buildSummaryPanel()
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
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        this.buildPreviewGlyph(this.selectedSymbolName, 46, $r('app.color.text_white'))

        Column({ space: 5 }) {
          Text(this.selectedSymbolName)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_white'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.getSelectedSymbolReference())
            .fontSize(12)
            .fontColor($r('app.color.text_white_medium'))
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
            SymbolGlyph($r('sys.symbol.doc_plaintext_and_checkmark'))
              .fontSize(17)
              .fontColor([$r('app.color.text_white')])
            Text($r('app.string.ui_str_2441'))
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_white'))
          }
        }
        .height(38)
        .padding({ left: 14, right: 14 })
        .borderRadius(12)
        .backgroundColor($r('app.color.button_primary'))
        .onClick((): void => {
          void this.copySymbolName(this.selectedSymbolName);
        })

        Text(this.statusText)
          .fontSize(12)
          .fontColor($r('app.color.text_white_medium'))
          .layoutWeight(1)
          .maxLines(2)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .linearGradient({
      angle: 140,
      colors: [['#1D4ED8', 0], ['#7C3AED', 0.62], ['#F59E0B', 1]]
    })
    .borderRadius(20)
    .shadow({ radius: 14, color: '#221D4ED8', offsetX: 0, offsetY: 8 })
  }

  @Builder
  private buildMetricPill(label: ResourceStr, value: ResourceStr): void {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(11)
        .fontColor($r('app.color.text_white_medium'))
      Text(value)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_white'))
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding({ top: 8, bottom: 8 })
    .backgroundColor('#24FFFFFF')
    .borderRadius(12)
  }

  @Builder
  private buildSearchPanel(): void {
    Column({ space: 10 }) {
      Search({ value: this.searchText, placeholder: $r('app.string.ui_str_2442') })
        .width('100%')
        .height(44)
        .searchButton($r('app.string.ui_str_2443'))
        .backgroundColor($r('app.color.background_surface'))
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
          .height(32)
          .fontSize(12)
          .fontColor(this.isSearching ? $r('app.color.text_secondary') : $r('app.color.text_white'))
          .backgroundColor(this.isSearching ? $r('app.color.background_surface') : $r('app.color.button_primary'))
          .borderRadius(12)
          .onClick((): void => {
            this.clearSearch();
          })

        if (this.isSearching) {
          Text(`搜索结果 ${this.searchResults.length} 个，已显示 ${this.getVisibleSearchResultCount()} 个`)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .layoutWeight(1)
        } else {
          Text(this.getSelectedGroupSummaryText())
            .fontSize(12)
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
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(18)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildGroupPanel(): void {
    Column({ space: 10 }) {
      Row() {
        Text($r('app.string.ui_str_2445'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Text(String(SYSTEM_SYMBOL_GROUPS.length))
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(SYSTEM_SYMBOL_GROUPS, (group: SystemSymbolResourceGroup) => {
          Button() {
            Row({ space: 6 }) {
              Text(group.name)
                .fontSize(12)
                .fontWeight(this.isSelectedGroup(group.name) ? FontWeight.Medium : FontWeight.Normal)
                .fontColor(this.isSelectedGroup(group.name) ? $r('app.color.text_white') : $r('app.color.text_primary'))
                .maxLines(1)
              Text(String(group.items.length))
                .fontSize(11)
                .fontColor(this.isSelectedGroup(group.name) ? $r('app.color.text_white_medium') : $r('app.color.text_tertiary'))
            }
          }
          .height(34)
          .padding({ left: 12, right: 12 })
          .borderRadius(14)
          .backgroundColor(this.isSelectedGroup(group.name) ? $r('app.color.button_primary') : $r('app.color.background_surface'))
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
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(18)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildSymbolGridPanel(): void {
    Column({ space: 10 }) {
      this.buildGridHeader(this.getCurrentGridItemCount(), this.getVisibleCurrentGridItemCount())
      this.buildCurrentSymbolGrid()
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(18)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildSearchResultsPanel(): void {
    Column({ space: 10 }) {
      this.buildGridHeader(this.searchResults.length, this.getVisibleSearchResultCount())

      if (this.searchResults.length <= 0) {
        Column({ space: 10 }) {
          SymbolGlyph($r('sys.symbol.magnifyingglass'))
            .fontSize(44)
            .fontColor([$r('app.color.text_tertiary')])
          Text($r('app.string.ui_str_2446'))
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding({ top: 36, bottom: 36 })
      } else {
        this.buildSearchSymbolGrid()
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(18)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildGridHeader(totalCount: number, visibleCount: number): void {
    Row() {
      Text(this.isSearching ? $r('app.string.ui_str_2447') : this.getCurrentGroupName())
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(`${visibleCount}/${totalCount}`)
        .fontSize(12)
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
  private buildSymbolCell(itemName: string): void {
    Column({ space: 7 }) {
      this.buildPreviewGlyph(itemName, 27, this.getSymbolIconColor(itemName))

      Text(itemName)
        .fontSize(9)
        .lineHeight(12)
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
      width: this.isSelectedSymbol(itemName) ? 1.5 : 1,
      color: this.isSelectedSymbol(itemName) ? $r('app.color.text_white_medium') : $r('app.color.card_border')
    })
    .onClick((): void => {
      this.selectSymbol(itemName);
      void this.copySymbolName(itemName);
    })
  }

  @Builder
  private buildPreviewGlyph(itemName: string, size: number, color: ResourceColor): void {
    SymbolGlyph($r(`sys.symbol.${itemName}`))
      .fontSize(size)
      .fontColor([color])
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
    return `$r('sys.symbol.${this.selectedSymbolName}')`;
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
    return `${group.name} · ${group.items.length} 个 Symbol`;
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
    return this.isSelectedSymbol(symbolName) ? $r('app.color.button_primary') : $r('app.color.background_surface');
  }

  private getSymbolIconColor(symbolName: string): ResourceColor {
    return this.isSelectedSymbol(symbolName) ? $r('app.color.text_white') : $r('app.color.text_primary');
  }

  private getSymbolTextColor(symbolName: string): ResourceColor {
    return this.isSelectedSymbol(symbolName) ? $r('app.color.text_white_high') : $r('app.color.text_secondary');
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
    this.statusText = `搜索 ${keyword}：${results.length} 个结果`;
    logger.info(TAG, `搜索系统 Symbol：keyword=${keyword}, count=${results.length}`);
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
    const fullName: string = `$r('sys.symbol.${symbolName}')`;
    try {
      const pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, fullName);
      const systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      await systemPasteboard.setData(pasteData);
      this.statusText = `已复制 ${fullName}`;
      this.getUIContext().getPromptAction().openToast({ message: `已复制 ${fullName}` });
      logger.info(TAG, `复制系统 Symbol 引用：${fullName}`);
    } catch (error) {
      const message: string = this.formatError(error as NGFSystemSymbolError);
      this.statusText = `复制失败：${message}`;
      try {
        this.getUIContext().getPromptAction().openToast({ message: $r('app.string.ui_str_2450') });
      } catch (toastError) {
        logger.warn(TAG, `复制失败后 Toast 显示异常：${toastError}`);
      }
      logger.warn(TAG, `复制系统 Symbol 引用失败：${message}`);
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
