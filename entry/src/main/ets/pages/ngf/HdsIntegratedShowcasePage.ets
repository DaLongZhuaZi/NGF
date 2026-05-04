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
const NGF_HDS_INTEGRATED_SURFACE_BACKGROUND: string = '#F8FBFF';
const NGF_HDS_INTEGRATED_SURFACE_BORDER: string = '#D7E3F0';
const NGF_HDS_INTEGRATED_SURFACE_SHADOW: string = '#180F172A';
const NGF_HDS_INTEGRATED_INNER_BACKGROUND: string = '#FFFFFFFF';
const NGF_HDS_INTEGRATED_INNER_BORDER: string = '#DCE6F2';
const NGF_HDS_INTEGRATED_INACTIVE_BUTTON_BACKGROUND: string = '#E6EEF8';
const NGF_HDS_INTEGRATED_COMPONENT_CONTROL_BACKGROUND: string = '#0F172A';
const NGF_HDS_INTEGRATED_COMPONENT_CONTROL_BORDER: string = '#243B53';

class NGFHdsIntegratedCapabilityCard {
  id: string;
  title: string;
  subtitle: string;
  description: string;
  accentStart: string;
  accentEnd: string;

  constructor(
    id: string,
    title: string,
    subtitle: string,
    description: string,
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
  title: string;
  group: string;
  tag: string;
  description: string;
  accentColor: string;

  constructor(id: string, title: string, group: string, tag: string, description: string, accentColor: string) {
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
  title: string;
  section: string;
  description: string;
  accentColor: string;

  constructor(id: string, title: string, section: string, description: string, accentColor: string) {
    this.id = id;
    this.title = title;
    this.section = section;
    this.description = description;
    this.accentColor = accentColor;
  }
}

class NGFHdsIntegratedMotionSlide {
  id: string;
  title: string;
  subtitle: string;
  description: string;
  colorStart: string;
  colorEnd: string;

  constructor(id: string, title: string, subtitle: string, description: string, colorStart: string, colorEnd: string) {
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
  @State private lastActionText: string = '等待激活融合示例能力卡片';
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
      '组件能力区',
      'Search / SegmentButton / ChipGroup',
      '在同一页面中直接验证搜索、筛选、分段切换与信息摘要的组合效果。',
      '#0B1220',
      '#183B8C'
    ),
    new NGFHdsIntegratedCapabilityCard(
      'layouts',
      '布局能力区',
      'Tabs / 信息分区 / 服务入口',
      '以统一卡片风格呈现内容布局、导航布局和服务入口骨架，不再拆成独立页面。',
      '#17132F',
      '#5B21B6'
    ),
    new NGFHdsIntegratedCapabilityCard(
      'motion',
      '动效能力区',
      'Swiper / 焦点过渡 / 播放控制',
      '保留轮播、焦点切换和动效模式调节能力，并与同页内容连续显示。',
      '#072723',
      '#0F5C56'
    )
  ];
  @State private componentGroupOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [
      { text: '全部' },
      { text: '组件' },
      { text: '导航' },
      { text: '反馈' }
    ]
  });
  private readonly componentTagItems: Array<ChipGroupItemOptions> = [
    { label: { text: '全部' } },
    { label: { text: '表单' } },
    { label: { text: '筛选' } },
    { label: { text: '状态' } },
    { label: { text: '组织' } }
  ];
  private readonly componentCards: Array<NGFHdsIntegratedComponentCard> = [
    new NGFHdsIntegratedComponentCard(
      'search',
      'Search 搜索入口',
      '组件',
      '筛选',
      '结合关键词过滤与结果统计，适合作为资源检索、命令筛选和列表定位入口。',
      '#2563EB'
    ),
    new NGFHdsIntegratedComponentCard(
      'segment',
      'SegmentButton 分段切换',
      '导航',
      '组织',
      '为多区块内容提供快速切换入口，保持页面上下文不被打断。',
      '#7C3AED'
    ),
    new NGFHdsIntegratedComponentCard(
      'chip',
      'ChipGroup 轻量筛选',
      '组件',
      '表单',
      '适合搭配搜索和分段控件进行快速筛选，强调状态可见与切换效率。',
      '#0EA5E9'
    ),
    new NGFHdsIntegratedComponentCard(
      'status',
      '状态摘要卡',
      '反馈',
      '状态',
      '将当前筛选、焦点区块和验证状态整合为即时反馈，提升框架验证可读性。',
      '#0F766E'
    )
  ];
  private readonly layoutCards: Array<NGFHdsIntegratedLayoutCard> = [
    new NGFHdsIntegratedLayoutCard(
      'content_grid',
      '内容布局卡片区',
      '内容布局',
      '适合聚合推荐、组件示例和分区摘要，强调分层信息与滚动阅读体验。',
      '#2563EB'
    ),
    new NGFHdsIntegratedLayoutCard(
      'content_panel',
      '信息说明面板',
      '内容布局',
      '用于承载说明文本、状态提示和结果汇总，让验证信息集中呈现。',
      '#0EA5E9'
    ),
    new NGFHdsIntegratedLayoutCard(
      'nav_tabs',
      'Tabs 顶层切换',
      '导航布局',
      '保留单页内的导航切换语义，适合在同页整合多个能力区块。',
      '#7C3AED'
    ),
    new NGFHdsIntegratedLayoutCard(
      'nav_focus',
      '焦点入口卡片',
      '导航布局',
      '使用统一卡片样式替代旧独立页面跳转，使导航意图与视觉重点一致。',
      '#8B5CF6'
    ),
    new NGFHdsIntegratedLayoutCard(
      'service_tools',
      '服务工具入口',
      '服务入口',
      '把组件、布局和动效验证工具统一收束到同一页面，减少页面切换成本。',
      '#0F766E'
    ),
    new NGFHdsIntegratedLayoutCard(
      'service_verify',
      '验证链路摘要',
      '服务入口',
      '以框架视角汇总当前页面已接入的 SDK 能力、导航方式和窗口策略。',
      '#14B8A6'
    )
  ];
  @State private motionModeOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [
      { text: '柔和' },
      { text: '标准' },
      { text: '强调' }
    ]
  });
  private readonly motionSlides: Array<NGFHdsIntegratedMotionSlide> = [
    new NGFHdsIntegratedMotionSlide(
      'banner',
      'Banner 焦点位',
      '标准缩放',
      '适合首页头图和重点推荐位展示，在单页融合模式下仍保留明显的视觉重心。',
      '#0F172A',
      '#2563EB'
    ),
    new NGFHdsIntegratedMotionSlide(
      'hero',
      'Hero 说明卡',
      '层次透明度',
      '通过透明度与阴影变化强化内容主次，让融合页面中的重点能力更易识别。',
      '#4C1D95',
      '#A855F7'
    ),
    new NGFHdsIntegratedMotionSlide(
      'gallery',
      'Gallery 轮播区',
      '平滑切页',
      '结合指示器与按钮控制，验证轮播在 HDS 页面壳层中的连续过渡表现。',
      '#134E4A',
      '#14B8A6'
    )
  ];

  aboutToAppear(): void {
    NGFPageWindowSupport.apply(NGFPageWindowName.HDS_SHOWCASE);
    logger.lifecycle(TAG, '即将显示');
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
    this.lastActionText = `当前聚焦：${this.capabilityCards[index].title}`;
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
    this.lastActionText = '已重置组件区筛选条件';
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
    const title = card.title.toLowerCase();
    const description = card.description.toLowerCase();
    const group = card.group.toLowerCase();
    const tag = card.tag.toLowerCase();
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
      return card.group === '组件';
    }
    if (groupIndex === 2) {
      return card.group === '导航';
    }
    return card.group === '反馈';
  }

  private matchesComponentTag(card: NGFHdsIntegratedComponentCard, tagIndex: number): boolean {
    if (tagIndex === 0) {
      return true;
    }
    if (tagIndex === 1) {
      return card.tag === '表单';
    }
    if (tagIndex === 2) {
      return card.tag === '筛选';
    }
    if (tagIndex === 3) {
      return card.tag === '状态';
    }
    return card.tag === '组织';
  }

  private resolveComponentGroupLabel(): string {
    const groupIndex = this.componentGroupIndexes.length > 0 ? this.componentGroupIndexes[0] : 0;
    if (groupIndex === 1) {
      return '组件';
    }
    if (groupIndex === 2) {
      return '导航';
    }
    if (groupIndex === 3) {
      return '反馈';
    }
    return '全部';
  }

  private resolveComponentTagLabel(): string {
    const tagIndex = this.componentTagIndexes.length > 0 ? this.componentTagIndexes[0] : 0;
    if (tagIndex === 1) {
      return '表单';
    }
    if (tagIndex === 2) {
      return '筛选';
    }
    if (tagIndex === 3) {
      return '状态';
    }
    if (tagIndex === 4) {
      return '组织';
    }
    return '全部';
  }

  private buildLayoutCardsBySection(section: string): Array<NGFHdsIntegratedLayoutCard> {
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
    this.lastActionText = '已重置动效区演示状态';
    logger.info(TAG, '重置动效区');
  }

  private resolveMotionModeLabel(): string {
    const modeIndex = this.motionModeIndexes.length > 0 ? this.motionModeIndexes[0] : 1;
    if (modeIndex === 0) {
      return '柔和';
    }
    if (modeIndex === 2) {
      return '强调';
    }
    return '标准';
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
    this.lastActionText = `当前动效焦点：${this.motionSlides[index].title}`;
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
            top: HDS_INTEGRATED_TOP_CHROME_SPEC.metrics.contentTopInset,
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
      'HDS 综合示例',
      '以 HdsNavigation 风格统一展示组件 / 布局 / 动效',
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
      Text('MainMenuPage → HDS 综合示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFFFF')

      Text('旧的组件页、布局页和动效页已移除，当前页面以与官方 HDS Navigation 示例一致的视觉骨架，统一承载三类能力验证。')
        .fontSize(14)
        .lineHeight(22)
        .fontColor('#E6FFFFFF')

      Text(this.lastActionText)
        .fontSize(13)
        .fontColor('#CCFFFFFF')

      Text(`当前聚焦区块：${this.capabilityCards[this.selectedCapabilityIndexes[0]].title}`)
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
      Text('融合能力入口')
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
          .fontColor('#FFFFFFFF')
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
          .fontColor('#E6FFFFFF')
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
      Text('当前融合结构')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Text('1. 旧的 HDS 组件页、布局页、动效页已收束为同一个 HdsNavDestination。')
        .width('100%')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))

      Text('2. 页面继续复用 MainMenuPage 作为唯一 HdsNavigation 根容器。')
        .width('100%')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))

      Text('3. 组件、布局、动效三类验证内容改为在同页连续滚动展示，不再通过多页面切换承载。')
        .width('100%')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
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
        primaryTitle: '组件能力区',
        secondaryTitle: '在同一页面中验证搜索、筛选、分段切换与状态摘要',
        operationType: OperationType.BUTTON,
        operationItem: [
          {
            value: '重置筛选',
            action: (): void => {
              this.resetComponentFilters();
            }
          }
        ]
      })

      Search({ value: this.componentSearchValue, placeholder: '搜索组件能力、分段控件或筛选模式' })
        .searchButton('搜索')
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
          this.lastActionText = `组件区分组切换为：${this.resolveComponentGroupLabel()}`;
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
          this.lastActionText = `组件区标签切换为：${this.resolveComponentTagLabel()}`;
          logger.info(TAG, `组件标签切换: indexes=${JSON.stringify(this.componentTagIndexes)}`);
        }
      })
      .backgroundColor(NGF_HDS_INTEGRATED_COMPONENT_CONTROL_BACKGROUND)
      .borderRadius(18)
      .border({ width: 1, color: NGF_HDS_INTEGRATED_COMPONENT_CONTROL_BORDER })

      Text(`当前分组：${this.resolveComponentGroupLabel()} · 当前标签：${this.resolveComponentTagLabel()} · 可见组件：${this.buildVisibleComponentCards().length}`)
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
        primaryTitle: '布局能力区',
        secondaryTitle: '用单页方式整合内容布局、导航布局与服务入口骨架'
      })

      HdsTabs({ controller: this.layoutTabsController }) {
        TabContent() {
          this.buildLayoutTabPanel('内容布局')
        }
        .tabBar('内容布局')

        TabContent() {
          this.buildLayoutTabPanel('导航布局')
        }
        .tabBar('导航布局')

        TabContent() {
          this.buildLayoutTabPanel('服务入口')
        }
        .tabBar('服务入口')
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
        this.lastActionText = `布局区切换为：${index === 0 ? '内容布局' : index === 1 ? '导航布局' : '服务入口'}`;
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
  private buildLayoutTabPanel(section: string): void {
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
        primaryTitle: '动效能力区',
        secondaryTitle: '保留轮播焦点、模式切换与播放控制，统一在同页验证',
        operationType: OperationType.BUTTON,
        operationItem: [
          {
            value: '重置动效',
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
          this.lastActionText = `动效模式切换为：${this.resolveMotionModeLabel()}`;
          logger.info(TAG, `动效模式切换: index=${index}`);
        }
      })

      Text(`当前动效模式：${this.resolveMotionModeLabel()} · 自动播放：${this.motionAutoPlayEnabled ? '开启' : '关闭'} · 轮播间隔：${this.motionIntervalValue}ms`)
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
        .fontColor('#FFFFFFFF')

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
          .fontColor(this.motionCurrentIndex === index ? '#FFFFFFFF' : $r('app.color.text_primary'))
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
      Button('上一张')
        .layoutWeight(1)
        .height(42)
        .buttonStyle(ButtonStyleMode.NORMAL)
        .backgroundColor(NGF_HDS_INTEGRATED_INACTIVE_BUTTON_BACKGROUND)
        .fontColor($r('app.color.text_primary'))
        .onClick((): void => {
          this.shiftMotionSlide(-1);
        })

      Button(this.motionAutoPlayEnabled ? '关闭自动播放' : '开启自动播放')
        .layoutWeight(1)
        .height(42)
        .buttonStyle(ButtonStyleMode.NORMAL)
        .backgroundColor('#1D4ED8')
        .fontColor('#FFFFFFFF')
        .onClick((): void => {
          this.motionAutoPlayEnabled = !this.motionAutoPlayEnabled;
          this.lastActionText = this.motionAutoPlayEnabled ? '已开启自动播放' : '已关闭自动播放';
          logger.info(TAG, `切换动效自动播放: enabled=${this.motionAutoPlayEnabled}`);
        })

      Button('下一张')
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
      Text('验证目标')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Text('当前页用于验证：MainMenuPage 根导航、统一沉浸式 HDS 顶栏、单页融合内容编排、官方组件接入、滚动标题栏联动与窗口策略在同一目的地中的协同效果。')
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor(NGF_HDS_INTEGRATED_SURFACE_BACKGROUND)
    .borderRadius(20)
    .border({ width: 1, color: NGF_HDS_INTEGRATED_SURFACE_BORDER })
    .shadow({ radius: 12, color: NGF_HDS_INTEGRATED_SURFACE_SHADOW, offsetX: 0, offsetY: 6 })
  }
}
