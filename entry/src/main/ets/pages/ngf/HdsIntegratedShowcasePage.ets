import {
  ChipGroup,
  ChipGroupItemOptions,
  OperationType,
  SegmentButton,
  SegmentButtonOptions,
  SubHeader
} from '@kit.ArkUI';
import { hdsEffect, hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';
import { logger } from '../../Framework/NGF/utils/Logger';
import { resolveResourceString } from '../../Framework/NGF/i18n/index';
import { NGFHdsTitleBarOptionsFactory } from '../../Framework/NGF/uiShell/components/HdsNavigationSupport';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from '../../Framework/NGF/uiShell/components/NGFImmersiveTopChrome';
import { NGFPageWindowName, NGFPageWindowSupport } from './NGFPageWindowSupport';

const TAG: string = 'NGFHdsIntegratedShowcasePage';
const HDS_INTEGRATED_TOP_CHROME_SPEC: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#0A101B',
  '#122B4A',
  '#0A1521',
  '#3B82F6D8',
  '#22D3EED8',
  160,
  88
);
const NGF_HDS_INTEGRATED_SURFACE_BACKGROUND: Resource = $r('app.color.background_surface');
const NGF_HDS_INTEGRATED_SURFACE_BORDER: Resource = $r('app.color.card_border');
const NGF_HDS_INTEGRATED_SURFACE_SHADOW: Resource = $r('app.color.card_shadow_demo');
const NGF_HDS_INTEGRATED_INNER_BACKGROUND: Resource = $r('app.color.panel_background');
const NGF_HDS_INTEGRATED_INNER_BORDER: Resource = $r('app.color.card_border_inner');
const NGF_HDS_INTEGRATED_INACTIVE_BUTTON_BACKGROUND: Resource = $r('app.color.button_inactive_bg');
const NGF_HDS_INTEGRATED_COMPONENT_CONTROL_BACKGROUND: Resource = $r('app.color.component_control_bg');
const NGF_HDS_INTEGRATED_COMPONENT_CONTROL_BORDER: Resource = $r('app.color.component_control_border');

class NGFHdsIntegratedCapabilityCard {
  id: string;
  title: ResourceStr;
  subtitle: ResourceStr;
  description: ResourceStr;
  accentStart: string;
  accentEnd: string;

  constructor(
    id: string,
    title: ResourceStr,
    subtitle: ResourceStr,
    description: ResourceStr,
    accentStart: string,
    accentEnd: string
  ) {
    this.id = id;
    this.title = title;
    this.subtitle = subtitle;
    this.description = description;
    this.accentStart = accentStart;
    this.accentEnd = accentEnd;
  }
}

class NGFHdsIntegratedComponentCard {
  id: string;
  title: ResourceStr;
  group: ResourceStr;
  tag: ResourceStr;
  description: ResourceStr;
  accentColor: string;

  constructor(id: string, title: ResourceStr, group: ResourceStr, tag: ResourceStr, description: ResourceStr, accentColor: string) {
    this.id = id;
    this.title = title;
    this.group = group;
    this.tag = tag;
    this.description = description;
    this.accentColor = accentColor;
  }
}

class NGFHdsIntegratedLayoutCard {
  id: string;
  title: ResourceStr;
  section: ResourceStr;
  description: ResourceStr;
  accentColor: string;

  constructor(id: string, title: ResourceStr, section: ResourceStr, description: ResourceStr, accentColor: string) {
    this.id = id;
    this.title = title;
    this.section = section;
    this.description = description;
    this.accentColor = accentColor;
  }
}

class NGFHdsIntegratedMotionSlide {
  id: string;
  title: ResourceStr;
  subtitle: ResourceStr;
  description: ResourceStr;
  colorStart: string;
  colorEnd: string;

  constructor(id: string, title: ResourceStr, subtitle: ResourceStr, description: ResourceStr, colorStart: string, colorEnd: string) {
    this.id = id;
    this.title = title;
    this.subtitle = subtitle;
    this.description = description;
    this.colorStart = colorStart;
    this.colorEnd = colorEnd;
  }
}

class NGFHdsIntegratedPointLightOptions implements hdsEffect.PointLightOptions {
  color?: ResourceColor;
  intensity?: number;
  height?: Dimension;
  bloom?: number;

  constructor(color: ResourceColor, intensity: number, height: Dimension, bloom: number) {
    this.color = color;
    this.intensity = intensity;
    this.height = height;
    this.bloom = bloom;
  }
}

class NGFHdsIntegratedPointLightEffect implements hdsEffect.PointLightEffect {
  sourceType?: hdsEffect.PointLightSourceType;
  illuminatedType?: hdsEffect.PointLightIlluminatedType;
  options?: hdsEffect.PointLightOptions;

  constructor(
    sourceType: hdsEffect.PointLightSourceType,
    illuminatedType: hdsEffect.PointLightIlluminatedType,
    options: hdsEffect.PointLightOptions
  ) {
    this.sourceType = sourceType;
    this.illuminatedType = illuminatedType;
    this.options = options;
  }
}

class NGFHdsIntegratedEffectFactory {
  static buildPrimaryCardEffect(): VisualEffect {
    const pointLightOptions = new NGFHdsIntegratedPointLightOptions('#E6FFFFFF', 0.34, 30, 0.28);
    const pointLightEffect = new NGFHdsIntegratedPointLightEffect(
      hdsEffect.PointLightSourceType.SOFT,
      hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
      pointLightOptions
    );
    return new hdsEffect.HdsEffectBuilder()
      .pressShadow(hdsEffect.PressShadowType.BLEND_GRADIENT)
      .pointLight(pointLightEffect)
      .buildEffect();
  }

  static buildAccentCardEffect(): VisualEffect {
    const pointLightOptions = new NGFHdsIntegratedPointLightOptions('#CCFFFFFF', 0.24, 26, 0.18);
    const pointLightEffect = new NGFHdsIntegratedPointLightEffect(
      hdsEffect.PointLightSourceType.BRIGHT,
      hdsEffect.PointLightIlluminatedType.BORDER,
      pointLightOptions
    );
    return new hdsEffect.HdsEffectBuilder()
      .pressShadow(hdsEffect.PressShadowType.BLEND_WHITE)
      .pointLight(pointLightEffect)
      .buildEffect();
  }
}

@Component
export struct HdsIntegratedShowcasePage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private topInsetVp: number = 108;
  @State private lastActionText: ResourceStr = $r('app.string.ui_str_2081');
  @State private selectedCapabilityIndexes: Array<number> = [0];
  @State private componentSearchValue: string = '';
  @State private componentGroupIndexes: Array<number> = [0];
  @State private componentTagIndexes: Array<number> = [0];
  @State private layoutTabIndex: number = 0;
  @State private motionModeIndexes: Array<number> = [1];
  @State private motionCurrentIndex: number = 0;
  @State private motionAutoPlayEnabled: boolean = true;
  @State private motionIntervalValue: number = 3200;

  private readonly scroller: Scroller = new Scroller();
  private readonly layoutTabsController: HdsTabsController = new HdsTabsController();
  private readonly swiperController: SwiperController = new SwiperController();
  private readonly capabilityCards: Array<NGFHdsIntegratedCapabilityCard> = [
    new NGFHdsIntegratedCapabilityCard(
      'components',
      $r('app.string.ui_str_2082'),
      'Search / SegmentButton / ChipGroup',
      $r('app.string.ui_str_2083'),
      '#0B1220',
      '#183B8C'
    ),
    new NGFHdsIntegratedCapabilityCard(
      'layouts',
      $r('app.string.ui_str_2084'),
      $r('app.string.ui_str_2085'),
      $r('app.string.ui_str_2086'),
      '#17132F',
      '#5B21B6'
    ),
    new NGFHdsIntegratedCapabilityCard(
      'motion',
      $r('app.string.ui_str_2087'),
      $r('app.string.ui_str_2088'),
      $r('app.string.ui_str_2089'),
      '#072723',
      '#0F5C56'
    )
  ];
  @State private componentGroupOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [
      { text: $r('app.string.ui_str_2090') },
      { text: $r('app.string.ui_str_2091') },
      { text: $r('app.string.ui_str_2092') },
      { text: $r('app.string.ui_str_2093') }
    ]
  });
  private componentTagItems: Array<ChipGroupItemOptions> = [];
  private readonly componentCards: Array<NGFHdsIntegratedComponentCard> = [
    new NGFHdsIntegratedComponentCard(
      'search',
      $r('app.string.ui_str_2098'),
      $r('app.string.ui_str_2091'),
      $r('app.string.ui_str_2095'),
      $r('app.string.ui_str_2099'),
      '#2563EB'
    ),
    new NGFHdsIntegratedComponentCard(
      'segment',
      $r('app.string.ui_str_2100'),
      $r('app.string.ui_str_2092'),
      $r('app.string.ui_str_2097'),
      $r('app.string.ui_str_2101'),
      '#7C3AED'
    ),
    new NGFHdsIntegratedComponentCard(
      'chip',
      $r('app.string.ui_str_2102'),
      $r('app.string.ui_str_2091'),
      $r('app.string.ui_str_2094'),
      $r('app.string.ui_str_2103'),
      '#0EA5E9'
    ),
    new NGFHdsIntegratedComponentCard(
      'status',
      $r('app.string.ui_str_2104'),
      $r('app.string.ui_str_2093'),
      $r('app.string.ui_str_2096'),
      $r('app.string.ui_str_2105'),
      '#0F766E'
    )
  ];
  private readonly layoutCards: Array<NGFHdsIntegratedLayoutCard> = [
    new NGFHdsIntegratedLayoutCard(
      'content_grid',
      $r('app.string.ui_str_2106'),
      $r('app.string.ui_str_2107'),
      $r('app.string.ui_str_2108'),
      '#2563EB'
    ),
    new NGFHdsIntegratedLayoutCard(
      'content_panel',
      $r('app.string.ui_str_2109'),
      $r('app.string.ui_str_2107'),
      $r('app.string.ui_str_2110'),
      '#0EA5E9'
    ),
    new NGFHdsIntegratedLayoutCard(
      'nav_tabs',
      $r('app.string.ui_str_2111'),
      $r('app.string.ui_str_2112'),
      $r('app.string.ui_str_2113'),
      '#7C3AED'
    ),
    new NGFHdsIntegratedLayoutCard(
      'nav_focus',
      $r('app.string.ui_str_2114'),
      $r('app.string.ui_str_2112'),
      $r('app.string.ui_str_2115'),
      '#8B5CF6'
    ),
    new NGFHdsIntegratedLayoutCard(
      'service_tools',
      $r('app.string.ui_str_2116'),
      $r('app.string.ui_str_2117'),
      $r('app.string.ui_str_2118'),
      '#0F766E'
    ),
    new NGFHdsIntegratedLayoutCard(
      'service_verify',
      $r('app.string.ui_str_2119'),
      $r('app.string.ui_str_2117'),
      $r('app.string.ui_str_2120'),
      '#14B8A6'
    )
  ];
  @State private motionModeOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [
      { text: $r('app.string.ui_str_2121') },
      { text: $r('app.string.ui_str_2122') },
      { text: $r('app.string.ui_str_2123') }
    ]
  });
  private readonly motionSlides: Array<NGFHdsIntegratedMotionSlide> = [
    new NGFHdsIntegratedMotionSlide(
      'banner',
      $r('app.string.ui_str_2124'),
      $r('app.string.ui_str_2125'),
      $r('app.string.ui_str_2126'),
      '#0F172A',
      '#2563EB'
    ),
    new NGFHdsIntegratedMotionSlide(
      'hero',
      $r('app.string.ui_str_2127'),
      $r('app.string.ui_str_2128'),
      $r('app.string.ui_str_2129'),
      '#4C1D95',
      '#A855F7'
    ),
    new NGFHdsIntegratedMotionSlide(
      'gallery',
      $r('app.string.ui_str_2130'),
      $r('app.string.ui_str_2131'),
      $r('app.string.ui_str_2132'),
      '#134E4A',
      '#14B8A6'
    )
  ];

  aboutToAppear(): void {
    NGFPageWindowSupport.loadDynamicTopInset(this.getUIContext(), 108, 108, (inset) => {
      this.topInsetVp = inset;
    });
    NGFPageWindowSupport.apply(NGFPageWindowName.HDS_SHOWCASE);
    logger.lifecycle(TAG, '即将显示');
    this.componentTagItems = [
      { label: { text: resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.ui_str_2090')) } },
      { label: { text: resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.ui_str_2094')) } },
      { label: { text: resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.ui_str_2095')) } },
      { label: { text: resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.ui_str_2096')) } },
      { label: { text: resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.ui_str_2097')) } }
    ];
  }

  aboutToDisappear(): void {
    NGFPageWindowSupport.restoreMainMenu();
    logger.lifecycle(TAG, '即将消失');
  }

  private bindPathStack(context: NavDestinationContext): void {
    this.pathStack = context.pathStack;
    logger.info(TAG, '综合展示已绑定路径栈');
  }

  private handleBackPressed(): boolean {
    NGFPageWindowSupport.restoreMainMenu();
    this.pathStack.pop();
    logger.info(TAG, '综合展示页面已弹出');
    return true;
  }

  private updateFocusedCapability(index: number): void {
    this.selectedCapabilityIndexes = [index];
    this.lastActionText = $r('app.string.ui_str_2133', this.capabilityCards[index].title);
    logger.info(TAG, `聚焦能力卡片: index=${index}`);
  }

  private resolveFocusedCapabilityId(): string {
    if (this.selectedCapabilityIndexes.length <= 0) {
      return this.capabilityCards[0].id;
    }
    return this.capabilityCards[this.selectedCapabilityIndexes[0]].id;
  }

  private isFocusedCapability(capabilityId: string): boolean {
    return this.resolveFocusedCapabilityId() === capabilityId;
  }

  private resetComponentFilters(): void {
    this.componentSearchValue = '';
    this.componentGroupIndexes = [0];
    this.componentTagIndexes = [0];
    this.lastActionText = $r('app.string.ui_str_2134');
    logger.info(TAG, '重置组件筛选条件');
  }

  private buildVisibleComponentCards(): Array<NGFHdsIntegratedComponentCard> {
    const visibleCards: Array<NGFHdsIntegratedComponentCard> = [];
    const searchText = this.componentSearchValue.trim().toLowerCase();
    const groupIndex = this.componentGroupIndexes.length > 0 ? this.componentGroupIndexes[0] : 0;
    const tagIndex = this.componentTagIndexes.length > 0 ? this.componentTagIndexes[0] : 0;

    for (let index = 0; index < this.componentCards.length; index++) {
      const card = this.componentCards[index];
      if (!this.matchesComponentSearch(card, searchText)) {
        continue;
      }
      if (!this.matchesComponentGroup(card, groupIndex)) {
        continue;
      }
      if (!this.matchesComponentTag(card, tagIndex)) {
        continue;
      }
      visibleCards.push(card);
    }
    return visibleCards;
  }

  private matchesComponentSearch(card: NGFHdsIntegratedComponentCard, searchText: string): boolean {
    if (searchText.length <= 0) {
      return true;
    }
    const title = (typeof card.title === "string" ? card.title : '').toLowerCase();
    const description = (typeof card.description === "string" ? card.description : '').toLowerCase();
    const group = (typeof card.group === "string" ? card.group : '').toLowerCase();
    const tag = (typeof card.tag === "string" ? card.tag : '').toLowerCase();
    return title.indexOf(searchText) >= 0 ||
      description.indexOf(searchText) >= 0 ||
      group.indexOf(searchText) >= 0 ||
      tag.indexOf(searchText) >= 0;
  }

  private matchesComponentGroup(card: NGFHdsIntegratedComponentCard, groupIndex: number): boolean {
    if (groupIndex === 0) {
      return true;
    }
    if (groupIndex === 1) {
      return card.group === $r('app.string.ui_str_2091');
    }
    if (groupIndex === 2) {
      return card.group === $r('app.string.ui_str_2092');
    }
    return card.group === $r('app.string.ui_str_2093');
  }

  private matchesComponentTag(card: NGFHdsIntegratedComponentCard, tagIndex: number): boolean {
    if (tagIndex === 0) {
      return true;
    }
    if (tagIndex === 1) {
      return card.tag === $r('app.string.ui_str_2094');
    }
    if (tagIndex === 2) {
      return card.tag === $r('app.string.ui_str_2095');
    }
    if (tagIndex === 3) {
      return card.tag === $r('app.string.ui_str_2096');
    }
    return card.tag === $r('app.string.ui_str_2097');
  }

  private resolveComponentGroupLabel(): ResourceStr {
    const groupIndex = this.componentGroupIndexes.length > 0 ? this.componentGroupIndexes[0] : 0;
    if (groupIndex === 1) {
      return $r('app.string.ui_str_2091');
    }
    if (groupIndex === 2) {
      return $r('app.string.ui_str_2092');
    }
    if (groupIndex === 3) {
      return $r('app.string.ui_str_2093');
    }
    return $r('app.string.ui_str_2090');
  }

  private resolveComponentTagLabel(): ResourceStr {
    const tagIndex = this.componentTagIndexes.length > 0 ? this.componentTagIndexes[0] : 0;
    if (tagIndex === 1) {
      return $r('app.string.ui_str_2094');
    }
    if (tagIndex === 2) {
      return $r('app.string.ui_str_2095');
    }
    if (tagIndex === 3) {
      return $r('app.string.ui_str_2096');
    }
    if (tagIndex === 4) {
      return $r('app.string.ui_str_2097');
    }
    return $r('app.string.ui_str_2090');
  }

  private buildLayoutCardsBySection(section: ResourceStr): Array<NGFHdsIntegratedLayoutCard> {
    const visibleCards: Array<NGFHdsIntegratedLayoutCard> = [];
    for (let index = 0; index < this.layoutCards.length; index++) {
      const card = this.layoutCards[index];
      if (card.section === section) {
        visibleCards.push(card);
      }
    }
    return visibleCards;
  }

  private resetMotionSection(): void {
    this.motionModeIndexes = [1];
    this.motionCurrentIndex = 0;
    this.motionAutoPlayEnabled = true;
    this.motionIntervalValue = 3200;
    this.swiperController.changeIndex(0, true);
    this.lastActionText = $r('app.string.ui_str_2135');
    logger.info(TAG, '重置动效区');
  }

  private resolveMotionModeLabel(): ResourceStr {
    const modeIndex = this.motionModeIndexes.length > 0 ? this.motionModeIndexes[0] : 1;
    if (modeIndex === 0) {
      return $r('app.string.ui_str_2121');
    }
    if (modeIndex === 2) {
      return $r('app.string.ui_str_2123');
    }
    return $r('app.string.ui_str_2122');
  }

  private resolveMotionScale(index: number): number {
    const modeIndex = this.motionModeIndexes.length > 0 ? this.motionModeIndexes[0] : 1;
    let baseScale = 1;
    if (modeIndex === 0) {
      baseScale = 0.97;
    } else if (modeIndex === 2) {
      baseScale = 1.04;
    }
    if (this.motionCurrentIndex === index) {
      return baseScale;
    }
    return baseScale - 0.05;
  }

  private resolveMotionOpacity(index: number): number {
    const modeIndex = this.motionModeIndexes.length > 0 ? this.motionModeIndexes[0] : 1;
    if (this.motionCurrentIndex === index) {
      if (modeIndex === 0) {
        return 0.9;
      }
      if (modeIndex === 2) {
        return 1;
      }
      return 0.95;
    }
    return 0.72;
  }

  private selectMotionSlide(index: number): void {
    this.motionCurrentIndex = index;
    this.swiperController.changeIndex(index, true);
    this.lastActionText = $r('app.string.ui_str_2136', this.motionSlides[index].title);
    logger.info(TAG, `选中动效幻灯片: index=${index}`);
  }

  private shiftMotionSlide(step: number): void {
    let nextIndex = this.motionCurrentIndex + step;
    if (nextIndex < 0) {
      nextIndex = this.motionSlides.length - 1;
    }
    if (nextIndex >= this.motionSlides.length) {
      nextIndex = 0;
    }
    this.selectMotionSlide(nextIndex);
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: HDS_INTEGRATED_TOP_CHROME_SPEC })

        Scroll(this.scroller) {
          Column({ space: 16 }) {
            this.buildHeroCard()
            this.buildCapabilityEntryList()
            this.buildFactCard()
            this.buildComponentSection()
            this.buildLayoutSection()
            this.buildMotionSection()
            this.buildVerificationCard()
          }
          .width('100%')
          .padding({
            left: 16,
            right: 16,
            top: this.topInsetVp,
            bottom: 24
          })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Auto)
        .backgroundColor('#00000000')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background_primary'))
    }
    .titleBar(NGFHdsTitleBarOptionsFactory.build(
      $r('app.string.ui_str_2137'),
      $r('app.string.ui_str_2138'),
      '#111827',
      hdsMaterial.MaterialLevel.GENTLE,
      true,
      false
    ))
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .mode(NavDestinationMode.STANDARD)
    .bindToScrollable([this.scroller])
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .onReady((context: NavDestinationContext): void => {
      this.bindPathStack(context);
    })
    .onBackPressed((): boolean => {
      return this.handleBackPressed();
    })
    .backgroundColor($r('app.color.background_primary'))
  }

  @Builder
  private buildHeroCard(): void {
    Column({ space: 12 }) {
      Text($r('app.string.ui_str_2139'))
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')

      Text($r('app.string.ui_str_2140'))
        .fontSize(14)
        .lineHeight(22)
        .fontColor('#E6FFFFFF')

      Text(this.lastActionText)
        .fontSize(13)
        .fontColor('#CCFFFFFF')

      Text($r('app.string.ui_str_2141', this.capabilityCards[this.selectedCapabilityIndexes[0]].title))
        .fontSize(13)
        .fontColor('#CCFFFFFF')
    }
    .width('100%')
    .padding(20)
    .linearGradient({
      angle: 135,
      colors: [
        ['#0F172A', 0],
        ['#1D4ED8', 1]
      ]
    })
    .borderRadius(28)
    .visualEffect(NGFHdsIntegratedEffectFactory.buildPrimaryCardEffect())
  }

  @Builder
  private buildCapabilityEntryList(): void {
    Column({ space: 12 }) {
      Text($r('app.string.ui_str_2142'))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      ForEach(this.capabilityCards, (card: NGFHdsIntegratedCapabilityCard, index: number): void => {
        this.buildCapabilityCard(card, index)
      }, (card: NGFHdsIntegratedCapabilityCard): string => card.id)
    }
    .width('100%')
  }

  @Builder
  private buildCapabilityCard(card: NGFHdsIntegratedCapabilityCard, index: number): void {
    Button() {
      Column({ space: 8 }) {
        Text(card.title)
          .width('100%')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Start)

        Text(card.subtitle)
          .width('100%')
          .fontSize(13)
          .fontColor('#E6FFFFFF')
          .textAlign(TextAlign.Start)

        Text(card.description)
          .width('100%')
          .fontSize(13)
          .lineHeight(20)
          .fontColor('#CCFFFFFF')
          .textAlign(TextAlign.Start)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(14)
      .backgroundColor('#18000000')
      .borderRadius(18)
      .border({ width: 1, color: '#16FFFFFF' })
    }
    .width('100%')
    .height(126)
    .padding(18)
    .buttonStyle(ButtonStyleMode.NORMAL)
    .linearGradient({
      angle: 135,
      colors: [
        [card.accentStart, 0],
        [card.accentEnd, 1]
      ]
    })
    .borderRadius(24)
    .shadow({ radius: 16, color: '#220F172A', offsetX: 0, offsetY: 10 })
    .border({
      width: this.selectedCapabilityIndexes[0] === index ? 2 : 1,
      color: this.selectedCapabilityIndexes[0] === index ? '#66FFFFFF' : '#24FFFFFF'
    })
    .visualEffect(NGFHdsIntegratedEffectFactory.buildPrimaryCardEffect())
    .onClick((): void => {
      this.updateFocusedCapability(index);
    })
  }

  @Builder
  private buildFactCard(): void {
    Column({ space: 10 }) {
      Text($r('app.string.ui_str_2143'))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')

      Text($r('app.string.ui_str_2144'))
        .width('100%')
        .fontSize(13)
        .fontColor('#E6FFFFFF')

      Text($r('app.string.ui_str_2145'))
        .width('100%')
        .fontSize(13)
        .fontColor('#E6FFFFFF')

      Text($r('app.string.ui_str_2146'))
        .width('100%')
        .fontSize(13)
        .fontColor('#E6FFFFFF')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(NGF_HDS_INTEGRATED_SURFACE_BACKGROUND)
    .borderRadius(20)
    .border({ width: 1, color: NGF_HDS_INTEGRATED_SURFACE_BORDER })
    .shadow({ radius: 12, color: NGF_HDS_INTEGRATED_SURFACE_SHADOW, offsetX: 0, offsetY: 6 })
  }

  @Builder
  private buildComponentSection(): void {
    Column({ space: 14 }) {
      SubHeader({
        primaryTitle: $r('app.string.ui_str_2082'),
        secondaryTitle: $r('app.string.ui_str_2147'),
        operationType: OperationType.BUTTON,
        operationItem: [
          {
            value: $r('app.string.ui_str_2148'),
            action: (): void => {
              this.resetComponentFilters();
            }
          }
        ]
      })

      Search({ value: this.componentSearchValue, placeholder: $r('app.string.ui_str_2149') })
        .searchButton($r('app.string.ui_str_2150'))
        .width('100%')
        .backgroundColor(NGF_HDS_INTEGRATED_COMPONENT_CONTROL_BACKGROUND)
        .borderRadius(18)
        .border({ width: 1, color: NGF_HDS_INTEGRATED_COMPONENT_CONTROL_BORDER })
        .onChange((value: string): void => {
          this.componentSearchValue = value;
        })

      SegmentButton({
        options: this.componentGroupOptions,
        selectedIndexes: this.componentGroupIndexes,
        onItemClicked: (index: number): void => {
          this.componentGroupIndexes = [index];
          this.lastActionText = $r('app.string.ui_str_2151', this.resolveComponentGroupLabel());
          logger.info(TAG, `组件分组切换: index=${index}`);
        }
      })
      .backgroundColor(NGF_HDS_INTEGRATED_COMPONENT_CONTROL_BACKGROUND)
      .borderRadius(18)
      .border({ width: 1, color: NGF_HDS_INTEGRATED_COMPONENT_CONTROL_BORDER })

      ChipGroup({
        items: this.componentTagItems,
        selectedIndexes: this.componentTagIndexes,
        multiple: false,
        onChange: (indexes: Array<number>): void => {
          this.componentTagIndexes = indexes.length > 0 ? indexes : [0];
          this.lastActionText = $r('app.string.ui_str_2152', this.resolveComponentTagLabel());
          logger.info(TAG, `组件标签切换: indexes=${JSON.stringify(this.componentTagIndexes)}`);
        }
      })
      .backgroundColor(NGF_HDS_INTEGRATED_COMPONENT_CONTROL_BACKGROUND)
      .borderRadius(18)
      .border({ width: 1, color: NGF_HDS_INTEGRATED_COMPONENT_CONTROL_BORDER })

      Text($r('app.string.ui_str_2153', this.resolveComponentGroupLabel(), this.resolveComponentTagLabel(), this.buildVisibleComponentCards().length))
        .width('100%')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))

      ForEach(this.buildVisibleComponentCards(), (card: NGFHdsIntegratedComponentCard): void => {
        this.buildComponentExampleCard(card)
      }, (card: NGFHdsIntegratedComponentCard): string => card.id)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(NGF_HDS_INTEGRATED_SURFACE_BACKGROUND)
    .borderRadius(24)
    .border({
      width: this.isFocusedCapability('components') ? 2 : 1,
      color: this.isFocusedCapability('components') ? '#3B82F666' : NGF_HDS_INTEGRATED_SURFACE_BORDER
    })
    .shadow({ radius: 12, color: NGF_HDS_INTEGRATED_SURFACE_SHADOW, offsetX: 0, offsetY: 6 })
  }

  @Builder
  private buildComponentExampleCard(card: NGFHdsIntegratedComponentCard): void {
    Column({ space: 8 }) {
      Row() {
        Text(card.title)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Text(card.group)
          .fontSize(12)
          .fontColor(card.accentColor)
      }
      .width('100%')

      Text(`${card.tag} · ${card.description}`)
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(14)
    .backgroundColor(NGF_HDS_INTEGRATED_INNER_BACKGROUND)
    .borderRadius(18)
    .border({ width: 1, color: NGF_HDS_INTEGRATED_INNER_BORDER })
    .shadow({ radius: 8, color: '#100F172A', offsetX: 0, offsetY: 4 })
  }

  @Builder
  private buildLayoutSection(): void {
    Column({ space: 14 }) {
      SubHeader({
        primaryTitle: $r('app.string.ui_str_2084'),
        secondaryTitle: $r('app.string.ui_str_2154')
      })

      HdsTabs({ controller: this.layoutTabsController }) {
        TabContent() {
          this.buildLayoutTabPanel($r('app.string.ui_str_2107'))
        }
        .tabBar($r('app.string.ui_str_2107'))

        TabContent() {
          this.buildLayoutTabPanel($r('app.string.ui_str_2112'))
        }
        .tabBar($r('app.string.ui_str_2112'))

        TabContent() {
          this.buildLayoutTabPanel($r('app.string.ui_str_2117'))
        }
        .tabBar($r('app.string.ui_str_2117'))
      }
      .barPosition(BarPosition.Start)
      .barMode(BarMode.Fixed)
      .width('100%')
      .height(332)
      .barFloatingStyle({
        adaptToHandedness: true,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        },
        thermoCtrl: true
      })
      .onChange((index: number): void => {
        this.layoutTabIndex = index;
        this.lastActionText = $r('app.string.ui_str_2155', index === 0 ? $r('app.string.ui_str_2107') : index === 1 ? $r('app.string.ui_str_2112') : $r('app.string.ui_str_2117'));
        logger.info(TAG, `布局标签切换: index=${index}`);
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(NGF_HDS_INTEGRATED_SURFACE_BACKGROUND)
    .borderRadius(24)
    .border({
      width: this.isFocusedCapability('layouts') ? 2 : 1,
      color: this.isFocusedCapability('layouts') ? '#8B5CF666' : NGF_HDS_INTEGRATED_SURFACE_BORDER
    })
    .shadow({ radius: 12, color: NGF_HDS_INTEGRATED_SURFACE_SHADOW, offsetX: 0, offsetY: 6 })
  }

  @Builder
  private buildLayoutTabPanel(section: ResourceStr): void {
    Column({ space: 12 }) {
      ForEach(this.buildLayoutCardsBySection(section), (card: NGFHdsIntegratedLayoutCard): void => {
        this.buildLayoutCard(card)
      }, (card: NGFHdsIntegratedLayoutCard): string => card.id)
    }
    .width('100%')
    .height('100%')
    .padding({ top: 14, bottom: 4 })
  }

  @Builder
  private buildLayoutCard(card: NGFHdsIntegratedLayoutCard): void {
    Row({ space: 12 }) {
      Column() {}
        .width(4)
        .height('80%')
        .backgroundColor(card.accentColor)
        .borderRadius(4)

      Column({ space: 6 }) {
        Text(card.title)
          .width('100%')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        Text(card.description)
          .width('100%')
          .fontSize(13)
          .lineHeight(20)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(NGF_HDS_INTEGRATED_INNER_BACKGROUND)
    .borderRadius(18)
    .border({ width: 1, color: NGF_HDS_INTEGRATED_INNER_BORDER })
    .shadow({ radius: 8, color: '#100F172A', offsetX: 0, offsetY: 4 })
  }

  @Builder
  private buildMotionSection(): void {
    Column({ space: 14 }) {
      SubHeader({
        primaryTitle: $r('app.string.ui_str_2087'),
        secondaryTitle: $r('app.string.ui_str_2156'),
        operationType: OperationType.BUTTON,
        operationItem: [
          {
            value: $r('app.string.ui_str_2157'),
            action: (): void => {
              this.resetMotionSection();
            }
          }
        ]
      })

      SegmentButton({
        options: this.motionModeOptions,
        selectedIndexes: this.motionModeIndexes,
        onItemClicked: (index: number): void => {
          this.motionModeIndexes = [index];
          this.lastActionText = $r('app.string.ui_str_2158', this.resolveMotionModeLabel());
          logger.info(TAG, `动效模式切换: index=${index}`);
        }
      })

      Text($r('app.string.ui_str_2161', this.resolveMotionModeLabel(), this.motionAutoPlayEnabled ? $r('app.string.ui_str_2159') : $r('app.string.ui_str_2160'), this.motionIntervalValue))
        .width('100%')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))

      Swiper(this.swiperController) {
        ForEach(this.motionSlides, (slide: NGFHdsIntegratedMotionSlide, index: number): void => {
          this.buildMotionSlide(slide, index)
        }, (slide: NGFHdsIntegratedMotionSlide): string => slide.id)
      }
      .width('100%')
      .height(240)
      .autoPlay(this.motionAutoPlayEnabled)
      .interval(this.motionIntervalValue)
      .loop(true)
      .displayCount(1)
      .curve(Curve.EaseInOut)
      .indicator(
        new DotIndicator()
          .itemWidth(8)
          .itemHeight(8)
          .selectedItemWidth(18)
          .selectedItemHeight(8)
          .color('#66FFFFFF')
          .selectedColor(Color.White)
      )
      .onChange((index: number): void => {
        this.motionCurrentIndex = index;
        logger.info(TAG, `动效轮播切换: index=${index}`);
      })

      this.buildMotionSelectorRow()
      this.buildMotionActionRow()
    }
    .width('100%')
    .padding(16)
    .backgroundColor(NGF_HDS_INTEGRATED_SURFACE_BACKGROUND)
    .borderRadius(24)
    .border({
      width: this.isFocusedCapability('motion') ? 2 : 1,
      color: this.isFocusedCapability('motion') ? '#14B8A666' : NGF_HDS_INTEGRATED_SURFACE_BORDER
    })
    .shadow({ radius: 12, color: NGF_HDS_INTEGRATED_SURFACE_SHADOW, offsetX: 0, offsetY: 6 })
  }

  @Builder
  private buildMotionSlide(slide: NGFHdsIntegratedMotionSlide, index: number): void {
    Column({ space: 10 }) {
      Text(slide.title)
        .width('100%')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')

      Text(slide.subtitle)
        .width('100%')
        .fontSize(13)
        .fontColor('#E6FFFFFF')

      Text(slide.description)
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor('#E6FFFFFF')
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .linearGradient({
      angle: 135,
      colors: [
        [slide.colorStart, 0],
        [slide.colorEnd, 1]
      ]
    })
    .borderRadius(24)
    .scale({ x: this.resolveMotionScale(index), y: this.resolveMotionScale(index) })
    .opacity(this.resolveMotionOpacity(index))
    .shadow({
      radius: this.motionCurrentIndex === index ? 18 : 10,
      color: '#26000000',
      offsetX: 0,
      offsetY: 8
    })
    .visualEffect(NGFHdsIntegratedEffectFactory.buildAccentCardEffect())
  }

  @Builder
  private buildMotionSelectorRow(): void {
    Row({ space: 10 }) {
      ForEach(this.motionSlides, (slide: NGFHdsIntegratedMotionSlide, index: number): void => {
        Button(`${index + 1}`)
          .width(36)
          .height(36)
          .buttonStyle(ButtonStyleMode.NORMAL)
          .backgroundColor(this.motionCurrentIndex === index ? '#0F766E' : NGF_HDS_INTEGRATED_INACTIVE_BUTTON_BACKGROUND)
          .fontColor(this.motionCurrentIndex === index ? $r('app.color.panel_background') : $r('app.color.text_primary'))
          .onClick((): void => {
            this.selectMotionSlide(index);
          })
      }, (slide: NGFHdsIntegratedMotionSlide): string => slide.id)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private buildMotionActionRow(): void {
    Row({ space: 10 }) {
      Button($r('app.string.ui_str_2162'))
        .layoutWeight(1)
        .height(42)
        .buttonStyle(ButtonStyleMode.NORMAL)
        .backgroundColor(NGF_HDS_INTEGRATED_INACTIVE_BUTTON_BACKGROUND)
        .fontColor($r('app.color.text_primary'))
        .onClick((): void => {
          this.shiftMotionSlide(-1);
        })

      Button(this.motionAutoPlayEnabled ? $r('app.string.ui_str_2163') : $r('app.string.ui_str_2164'))
        .layoutWeight(1)
        .height(42)
        .buttonStyle(ButtonStyleMode.NORMAL)
        .backgroundColor('#1D4ED8')
        .fontColor($r('app.color.panel_background'))
        .onClick((): void => {
          this.motionAutoPlayEnabled = !this.motionAutoPlayEnabled;
          this.lastActionText = this.motionAutoPlayEnabled ? $r('app.string.ui_str_2165') : $r('app.string.ui_str_2166');
          logger.info(TAG, `切换动效自动播放: enabled=${this.motionAutoPlayEnabled}`);
        })

      Button($r('app.string.ui_str_2167'))
        .layoutWeight(1)
        .height(42)
        .buttonStyle(ButtonStyleMode.NORMAL)
        .backgroundColor(NGF_HDS_INTEGRATED_INACTIVE_BUTTON_BACKGROUND)
        .fontColor($r('app.color.text_primary'))
        .onClick((): void => {
          this.shiftMotionSlide(1);
        })
    }
    .width('100%')
  }

  @Builder
  private buildVerificationCard(): void {
    Column({ space: 10 }) {
      Text($r('app.string.ui_str_2168'))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')

      Text($r('app.string.ui_str_2169'))
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor('#E6FFFFFF')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(NGF_HDS_INTEGRATED_SURFACE_BACKGROUND)
    .borderRadius(20)
    .border({ width: 1, color: NGF_HDS_INTEGRATED_SURFACE_BORDER })
    .shadow({ radius: 12, color: NGF_HDS_INTEGRATED_SURFACE_SHADOW, offsetX: 0, offsetY: 6 })
  }
}
