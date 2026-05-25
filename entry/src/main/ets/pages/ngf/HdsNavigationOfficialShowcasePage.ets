import {
  hdsMaterial,
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  HdsSceneController,
  HdsSceneType,
  HdsVisualComponent
} from '@kit.UIDesignKit';
import { logger } from '../../Framework/NGF/utils/Logger';
import { NGFHdsDemoRouteName } from './HdsDemoRoutes';
import { NGFHdsTitleBarOptionsFactory } from '../../Framework/NGF/uiShell/components/HdsNavigationSupport';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from '../../Framework/NGF/uiShell/components/NGFImmersiveTopChrome';
import {
  NGFHdsEffectPresetFactory,
  NGFHdsInteractiveEffectPreset,
  NGFHdsInteractiveEffectPresetKind,
  NGFHdsMaterialSurfacePreset,
  NGFHdsSceneFlowPreset
} from '../../Framework/NGF/uiShell/components/NGFHdsEffectPresets';
import { NGFPageWindowName, NGFPageWindowSupport } from './NGFPageWindowSupport';

const TAG: string = 'NGFHdsNavigationOfficialShowcasePage';
const HDS_OFFICIAL_SHOWCASE_TOP_CHROME_SPEC: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#0A101B',
  '#132742',
  '#0B1421',
  '#3B82F6D8',
  '#22D3EED8',
  160,
  88
);
const HDS_OFFICIAL_OVERVIEW_TOP_CHROME_SPEC: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#0A1523',
  '#102A43',
  '#0C1726',
  '#315CFFD8',
  '#2CCBFFD8',
  160,
  88
);
const HDS_OFFICIAL_MATERIAL_TOP_CHROME_SPEC: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#160F26',
  '#241B3B',
  '#120A1D',
  '#8B5CF6D8',
  '#C084FCD8',
  160,
  88
);
const HDS_OFFICIAL_EFFECT_TOP_CHROME_SPEC: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#082127',
  '#083344',
  '#06171C',
  '#14B8A6D8',
  '#22D3EED8',
  160,
  88
);
const NGF_HDS_OFFICIAL_SURFACE_BACKGROUND: string = '#F8FBFF';
const NGF_HDS_OFFICIAL_SURFACE_BORDER: string = '#D7E3F0';
const NGF_HDS_OFFICIAL_SURFACE_SHADOW: Resource = $r('app.color.card_shadow_demo');

class NGFHdsOfficialActionCard {
  id: string;
  routeName: string;
  title: string;
  subtitle: string;
  description: string;
  accentStart: string | Resource;
  accentEnd: string | Resource;

  constructor(
    id: string,
    routeName: string,
    title: string,
    subtitle: string,
    description: string,
    accentStart: string | Resource,
    accentEnd: string | Resource
  ) {
    this.id = id;
    this.routeName = routeName;
    this.title = title;
    this.subtitle = subtitle;
    this.description = description;
    this.accentStart = accentStart;
    this.accentEnd = accentEnd;
  }
}

class NGFHdsOfficialHighlightItem {
  id: string;
  title: string;
  description: string;
  accentColor: string | Resource;

  constructor(id: string, title: string, description: string, accentColor: string | Resource) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.accentColor = accentColor;
  }
}

class NGFHdsOfficialMaterialItem {
  id: string;
  title: string;
  description: string;
  // 真实 MaterialType（均为 IMMERSIVE）
  materialType: hdsMaterial.MaterialType;
  // 真实 MaterialLevel（GENTLE / SMOOTH / EXQUISITE）
  materialLevel: hdsMaterial.MaterialLevel;
  // 面板渐变起始色
  gradientStart: string;
  // 面板渐变结束色
  gradientEnd: string;

  constructor(
    id: string,
    title: string,
    description: string,
    materialType: hdsMaterial.MaterialType,
    materialLevel: hdsMaterial.MaterialLevel,
    gradientStart: string,
    gradientEnd: string
  ) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.materialType = materialType;
    this.materialLevel = materialLevel;
    this.gradientStart = gradientStart;
    this.gradientEnd = gradientEnd;
  }
}

class NGFHdsOfficialEffectEntry {
  id: string;
  presetKind: NGFHdsInteractiveEffectPresetKind;
  title: string;
  description: string;
  accentStart: string;
  accentEnd: string;
  // 卡片高度（差异化展示）
  cardHeight: number;
  // 效果标签（展示在卡片上）
  effectLabel: string;
  // 边框强调色
  borderAccent: string;
  // 右上角徽标文字
  badgeLabel: string;

  constructor(
    id: string,
    presetKind: NGFHdsInteractiveEffectPresetKind,
    title: string,
    description: string,
    accentStart: string,
    accentEnd: string,
    cardHeight: number,
    effectLabel: string,
    borderAccent: string,
    badgeLabel: string
  ) {
    this.id = id;
    this.presetKind = presetKind;
    this.title = title;
    this.description = description;
    this.accentStart = accentStart;
    this.accentEnd = accentEnd;
    this.cardHeight = cardHeight;
    this.effectLabel = effectLabel;
    this.borderAccent = borderAccent;
    this.badgeLabel = badgeLabel;
  }
}

@Component
export struct HdsNavigationOfficialShowcasePage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private lastActionText: string = '等待打开 HDS 官方目的地';
  @State private openedCount: number = 0;

  private readonly scroller: Scroller = new Scroller();
  private readonly actionCards: Array<NGFHdsOfficialActionCard> = [
    new NGFHdsOfficialActionCard(
      'overview',
      NGFHdsDemoRouteName.OFFICIAL_NAVIGATION_OVERVIEW,
      '总览目的地',
      'HdsNavDestination 生命周期 / 滚动绑定',
      '验证 MainMenuPage 作为唯一 HdsNavigation 根容器时，后续页面如何继续沿用同一 NavPathStack。',
      $r('app.color.button_primary'),
      '#183B8C'
    ),
    new NGFHdsOfficialActionCard(
      'material',
      NGFHdsDemoRouteName.OFFICIAL_NAVIGATION_MATERIAL,
      '材质目的地',
      'hdsMaterial + systemMaterialEffect',
      '在目的地标题栏中使用官方材质参数，展示沉浸式材质与滚动模糊的组合效果。',
      '#6A1B9A',
      '#5B21B6'
    ),
    new NGFHdsOfficialActionCard(
      'effect',
      NGFHdsDemoRouteName.OFFICIAL_NAVIGATION_EFFECT,
      '特效目的地',
      'hdsEffect pressShadow + pointLight',
      '通过官方视觉效果构建交互卡片，验证同栈 HDS 目的地中的点击反馈。',
      '#00796B',
      '#0F5C56'
    )
  ];

  aboutToAppear(): void {
    NGFPageWindowSupport.apply(NGFPageWindowName.HDS_OFFICIAL_NAVIGATION);
    logger.lifecycle(TAG, '官方展示即将显示');
  }

  aboutToDisappear(): void {
    logger.lifecycle(TAG, '官方展示即将消失');
  }

  private bindPathStack(context: NavDestinationContext): void {
    this.pathStack = context.pathStack;
    logger.info(TAG, '官方展示已绑定路径栈');
  }

  private handleBackPressed(): boolean {
    NGFPageWindowSupport.restoreMainMenu();
    this.pathStack.pop();
    logger.info(TAG, '官方展示页面已弹出');
    return true;
  }

  private openDestination(card: NGFHdsOfficialActionCard): void {
    try {
      this.pathStack.pushPathByName(card.routeName, null);
      this.lastActionText = `已打开：${card.title}`;
      this.openedCount = this.openedCount + 1;
      logger.info(TAG, `打开官方HDS路由: ${card.routeName}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.lastActionText = `打开失败：${card.title}`;
      logger.warn(TAG, `打开官方HDS路由失败: route=${card.routeName}, error=${message}`);
    }
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: HDS_OFFICIAL_SHOWCASE_TOP_CHROME_SPEC })

        Scroll(this.scroller) {
          Column({ space: 16 }) {
            this.buildHeroCard()
            this.buildEntryCardList()
            this.buildFactCard()
            this.buildVerificationCard()
          }
          .width('100%')
          .padding({
            left: 16,
            right: 16,
            top: HDS_OFFICIAL_SHOWCASE_TOP_CHROME_SPEC.metrics.contentTopInset,
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
      '官方 HDS Navigation',
      'MainMenuPage 统一承载 HdsNavigation，当前页为第一个 HdsNavDestination',
      '#111827',
      hdsMaterial.MaterialLevel.GENTLE,
      true,
      false
    ))
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .mode(NavDestinationMode.STANDARD)
    .bindToScrollable([this.scroller])
    .onReady((context: NavDestinationContext): void => {
      this.bindPathStack(context);
    })
    .onBackPressed((): boolean => {
      return this.handleBackPressed();
    })
    .onShown((): void => {
      logger.info(TAG, '官方展示已显示');
    })
    .onHidden((): void => {
      logger.info(TAG, '官方展示已隐藏');
    })
    .backgroundColor($r('app.color.background_primary'))
  }

  @Builder
  private buildHeroCard(): void {
    Column({ space: 12 }) {
      Text('MainMenuPage → HdsNavigation')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.panel_background'))

      Text('当前结构已调整为：MainMenuPage 作为唯一 HdsNavigation 根容器，后续官方示例页全部以 HdsNavDestination 形式加入同一主栈。')
        .fontSize(14)
        .lineHeight(22)
        .fontColor('#E6FFFFFF')

      Text(this.lastActionText)
        .fontSize(13)
        .fontColor('#CCFFFFFF')

      Text(`已成功打开官方 HDS 目的地 ${this.openedCount} 次`)
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
    .visualEffect(NGFHdsEffectPresetFactory.buildPrimaryCardEffect())
  }

  @Builder
  private buildEntryCardList(): void {
    Column({ space: 12 }) {
      Text('后续页面入口')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      ForEach(this.actionCards, (card: NGFHdsOfficialActionCard): void => {
        this.buildActionCard(card)
      }, (card: NGFHdsOfficialActionCard): string => card.id)
    }
    .width('100%')
  }

  @Builder
  private buildActionCard(card: NGFHdsOfficialActionCard): void {
    Button() {
      Column({ space: 8 }) {
        Text(card.title)
          .width('100%')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.panel_background'))
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
    .border({ width: 1, color: '#24FFFFFF' })
    .shadow({ radius: 16, color: '#220F172A', offsetX: 0, offsetY: 10 })
    .visualEffect(NGFHdsEffectPresetFactory.buildPrimaryCardEffect())
    .onClick((): void => {
      this.openDestination(card);
    })
  }

  @Builder
  private buildFactCard(): void {
    Column({ space: 10 }) {
      Text('当前导航结构')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Text('1. `main_pages.json` 入口仍为 MainMenuPage。')
        .width('100%')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))

      Text('2. MainMenuPage 根节点切换为 HdsNavigation。')
        .width('100%')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))

      Text('3. 当前页与后续 3 个子页都通过同一 NavPathStack 以 HdsNavDestination 推入主栈。')
        .width('100%')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor(NGF_HDS_OFFICIAL_SURFACE_BACKGROUND)
    .borderRadius(20)
    .border({ width: 1, color: NGF_HDS_OFFICIAL_SURFACE_BORDER })
    .shadow({ radius: 12, color: NGF_HDS_OFFICIAL_SURFACE_SHADOW, offsetX: 0, offsetY: 6 })
  }

  @Builder
  private buildVerificationCard(): void {
    Column({ space: 10 }) {
      Text('验证目标')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Text('继续进入后续页面，可验证 HDS 标题栏、返回链路、材质参数和 hdsEffect 在同一主导航栈中的工作方式。')
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor(NGF_HDS_OFFICIAL_SURFACE_BACKGROUND)
    .borderRadius(20)
    .border({ width: 1, color: NGF_HDS_OFFICIAL_SURFACE_BORDER })
    .shadow({ radius: 12, color: NGF_HDS_OFFICIAL_SURFACE_SHADOW, offsetX: 0, offsetY: 6 })
  }
}

@Component
export struct HdsNavigationOfficialOverviewPage {
  @State private pathStack: NavPathStack = new NavPathStack();

  private readonly scroller: Scroller = new Scroller();
  private readonly overviewItems: Array<NGFHdsOfficialHighlightItem> = [
    new NGFHdsOfficialHighlightItem(
      'root_nav',
      '唯一根导航',
      'MainMenuPage 负责创建唯一的 HdsNavigation 根容器，后续示例不再嵌套新的 HdsNavigation。',
      $r('app.color.button_primary')
    ),
    new NGFHdsOfficialHighlightItem(
      'path_stack',
      '统一主栈',
      '当前页通过 NavDestinationContext.pathStack 绑定主栈，因此继续 push 的后续页都能自然接续。',
      '#7B1FA2'
    ),
    new NGFHdsOfficialHighlightItem(
      'destination',
      '官方目的地',
      '当前页自身和后续材质/特效页都直接使用 HdsNavDestination，保持 HDS 导航语义闭环。',
      '#00796B'
    )
  ];

  aboutToAppear(): void {
    NGFPageWindowSupport.apply(NGFPageWindowName.HDS_OFFICIAL_NAVIGATION_OVERVIEW);
    logger.lifecycle(TAG, '官方概览即将显示');
  }

  aboutToDisappear(): void {
    NGFPageWindowSupport.restore(NGFPageWindowName.HDS_OFFICIAL_NAVIGATION);
    logger.lifecycle(TAG, '官方概览即将消失');
  }

  private bindPathStack(context: NavDestinationContext): void {
    this.pathStack = context.pathStack;
    logger.info(TAG, '官方概览已绑定路径栈');
  }

  private handleBackPressed(): boolean {
    NGFPageWindowSupport.restore(NGFPageWindowName.HDS_OFFICIAL_NAVIGATION);
    this.pathStack.pop();
    logger.info(TAG, '官方概览页面已弹出');
    return true;
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: HDS_OFFICIAL_OVERVIEW_TOP_CHROME_SPEC })

        Scroll(this.scroller) {
          Column({ space: 14 }) {
            Text('总览目的地')
              .width('100%')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))

            Text('本页用于解释为什么要以 MainMenuPage 为唯一 HDS 根导航，以及这种结构如何正确支持后续页面。')
              .width('100%')
              .fontSize(14)
              .lineHeight(22)
              .fontColor($r('app.color.text_secondary'))

            ForEach(this.overviewItems, (item: NGFHdsOfficialHighlightItem): void => {
              this.buildOverviewHighlightCard(item)
            }, (item: NGFHdsOfficialHighlightItem): string => item.id)
          }
          .width('100%')
          .padding({
            left: 16,
            right: 16,
            top: HDS_OFFICIAL_OVERVIEW_TOP_CHROME_SPEC.metrics.contentTopInset,
            bottom: 24
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#00000000')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background_primary'))
    }
    .titleBar(NGFHdsTitleBarOptionsFactory.build(
      '总览目的地',
      'HdsNavDestination 生命周期与主栈绑定',
      '#102A43',
      hdsMaterial.MaterialLevel.EXQUISITE,
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
  private buildOverviewHighlightCard(item: NGFHdsOfficialHighlightItem): void {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text('●')
          .fontSize(14)
          .fontColor(item.accentColor)

        Text(item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
      }

      Text(item.description)
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor(NGF_HDS_OFFICIAL_SURFACE_BACKGROUND)
    .borderRadius(20)
    .border({ width: 1, color: NGF_HDS_OFFICIAL_SURFACE_BORDER })
    .shadow({ radius: 12, color: NGF_HDS_OFFICIAL_SURFACE_SHADOW, offsetX: 0, offsetY: 6 })
    .visualEffect(NGFHdsEffectPresetFactory.buildAccentCardEffect())
  }
}

@Component
export struct HdsNavigationOfficialMaterialPage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private pressedMaterialItemId: string = '';

  private readonly scroller: Scroller = new Scroller();
  private readonly materialItems: Array<NGFHdsOfficialMaterialItem> = [
    new NGFHdsOfficialMaterialItem(
      'gentle',
      'GENTLE — 柔和玻璃',
      'MaterialLevel.GENTLE 提供最实的材质层，模糊度最低、通透度最低，文字对比度最高。\n适用于入口页标题栏等强调稳定可读性的场景。',
      hdsMaterial.MaterialType.IMMERSIVE,
      hdsMaterial.MaterialLevel.GENTLE,
      '#1A1B2E',
      '#2D1F3C'
    ),
    new NGFHdsOfficialMaterialItem(
      'smooth',
      'SMOOTH — 平滑毛玻璃',
      'MaterialLevel.SMOOTH 是均衡的毛玻璃效果，中等模糊与通透度。\n适合内容目的地标题栏，兼顾文字识别与材质层次感。',
      hdsMaterial.MaterialType.IMMERSIVE,
      hdsMaterial.MaterialLevel.SMOOTH,
      '#1A1B4E',
      '#3D1F5C'
    ),
    new NGFHdsOfficialMaterialItem(
      'exquisite',
      'EXQUISITE — 精致高透',
      'MaterialLevel.EXQUISITE 模糊最强、通透度最高，下层内容隐约可见。\n适合强调型目的地标题栏，追求极致沉浸与通透质感。',
      hdsMaterial.MaterialType.IMMERSIVE,
      hdsMaterial.MaterialLevel.EXQUISITE,
      '#0A2E1E',
      '#1F4E3E'
    )
  ];

  aboutToAppear(): void {
    NGFPageWindowSupport.apply(NGFPageWindowName.HDS_OFFICIAL_NAVIGATION_MATERIAL);
    logger.lifecycle(TAG, '官方材质即将显示');
  }

  aboutToDisappear(): void {
    NGFPageWindowSupport.restore(NGFPageWindowName.HDS_OFFICIAL_NAVIGATION);
    logger.lifecycle(TAG, '官方材质即将消失');
  }

  private bindPathStack(context: NavDestinationContext): void {
    this.pathStack = context.pathStack;
    logger.info(TAG, '官方材质已绑定路径栈');
  }

  private handleBackPressed(): boolean {
    NGFPageWindowSupport.restore(NGFPageWindowName.HDS_OFFICIAL_NAVIGATION);
    this.pathStack.pop();
    logger.info(TAG, '官方材质页面已弹出');
    return true;
  }

  private updatePressedMaterialItem(itemId: string): void {
    this.pressedMaterialItemId = itemId;
    logger.info(TAG, `材质预设按下: ${itemId}`);
  }

  private clearPressedMaterialItem(itemId: string): void {
    if (this.pressedMaterialItemId === itemId) {
      this.pressedMaterialItemId = '';
      logger.info(TAG, `材质预设释放: ${itemId}`);
    }
  }

  private isMaterialItemPressed(itemId: string): boolean {
    return this.pressedMaterialItemId === itemId;
  }

  private buildMaterialSurfacePreset(item: NGFHdsOfficialMaterialItem): NGFHdsMaterialSurfacePreset {
    return NGFHdsEffectPresetFactory.buildMaterialSurfacePreset(
      item.materialLevel,
      this.isMaterialItemPressed(item.id)
    );
  }

  private handleMaterialPanelTouch(itemId: string, event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.updatePressedMaterialItem(itemId);
      return;
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.clearPressedMaterialItem(itemId);
    }
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: HDS_OFFICIAL_MATERIAL_TOP_CHROME_SPEC })

        Scroll(this.scroller) {
          Column({ space: 14 }) {
            Text('材质目的地')
              .width('100%')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))

            Text('本页标题栏通过官方 systemMaterialEffect 注入 `MaterialType.IMMERSIVE`，并使用不同的 MaterialLevel 展示材质策略。')
              .width('100%')
              .fontSize(14)
              .lineHeight(22)
              .fontColor($r('app.color.text_secondary'))

            ForEach(this.materialItems, (item: NGFHdsOfficialMaterialItem): void => {
              this.buildMaterialPanel(item)
            }, (item: NGFHdsOfficialMaterialItem): string => item.id)
          }
          .width('100%')
          .padding({
            left: 16,
            right: 16,
            top: HDS_OFFICIAL_MATERIAL_TOP_CHROME_SPEC.metrics.contentTopInset,
            bottom: 24
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#00000000')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background_primary'))
    }
    .titleBar(NGFHdsTitleBarOptionsFactory.build(
      '材质目的地',
      'systemMaterialEffect + hdsMaterial 官方材质参数',
      '#241B3B',
      hdsMaterial.MaterialLevel.SMOOTH,
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
  private buildMaterialPanel(item: NGFHdsOfficialMaterialItem): void {
    this.buildMaterialPanelContent(item, this.buildMaterialSurfacePreset(item))
  }

  @Builder
  private buildMaterialPanelContent(
    item: NGFHdsOfficialMaterialItem,
    preset: NGFHdsMaterialSurfacePreset
  ): void {
    Column({ space: 14 }) {
      Column({ space: 6 }) {
        Row({ space: 8 }) {
          Circle()
            .width(12)
            .height(12)
            .fill('#FFFFFF')

          Text(item.title.replace(/.*— /, ''))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
        }

        Row({ space: 6 }) {
          Text(preset.effectLabel)
            .fontSize(12)
            .fontColor('#E6FFFFFF')
            .layoutWeight(1)

          Text(preset.levelLabel)
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .opacity(0.7)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(10)
            .border({ width: 1, color: '#33FFFFFF' })
        }
      }
      .width('100%')
      .padding(14)
      .linearGradient({
        angle: 90,
        colors: [
          [`${item.gradientStart}${preset.titleAlpha}`, 0],
          [`${item.gradientEnd}${preset.titleAlpha}`, 1]
        ]
      })
      .borderRadius(14)
      .backgroundEffect(preset.backgroundEffect)

      Row({ space: 12 }) {
        this.buildMaterialApiMetric('MaterialType', 'IMMERSIVE')
        this.buildMaterialApiMetric('MaterialLevel', preset.levelLabel)
        this.buildMaterialApiMetric('PressShadow', preset.visualEffectPreset.getPressShadowLabel())
      }
      .width('100%')

      Column({ space: 8 }) {
        this.buildMaterialApiLine('backgroundEffect', preset.backgroundEffect.getSummary())
        this.buildMaterialApiLine('pointLight', preset.visualEffectPreset.getPointLightSummary())
        this.buildMaterialApiLine('preset API', preset.getApiSummary())
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#18000000')
      .borderRadius(14)
      .border({ width: 1, color: '#18FFFFFF' })

      Text(item.description)
        .width('100%')
        .fontSize(13)
        .lineHeight(20)
        .fontColor('#E6FFFFFF')

      Text(this.isMaterialItemPressed(item.id) ? '已按下：当前预设的 pressShadow / pointLight / backgroundEffect 正在使用按压参数。' : '按住卡片可观察该 MaterialLevel 对应的预设反馈。')
        .width('100%')
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#BFFFFFFF')
    }
    .width('100%')
    .padding(16)
    .linearGradient({
      angle: 135,
      colors: [
        [item.gradientStart, 0],
        [`${item.gradientEnd}A0`, 1]
      ]
    })
    .borderRadius(24)
    .border({ width: preset.borderWidth, color: preset.borderColor })
    .shadow(preset.shadowOptions)
    .backgroundEffect(preset.backgroundEffect)
    .visualEffect(preset.buildVisualEffect())
    .scale(preset.scaleOptions)
    .translate(preset.translateOptions)
    .animation({
      duration: 220,
      curve: Curve.FastOutSlowIn
    })
    .onTouch((event: TouchEvent): void => {
      this.handleMaterialPanelTouch(item.id, event);
    })
  }

  @Builder
  private buildMaterialApiMetric(label: string, value: string): void {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(11)
        .fontColor('#99FFFFFF')

      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
  }

  @Builder
  private buildMaterialApiLine(label: string, value: string): void {
    Row({ space: 8 }) {
      Text(label)
        .width(116)
        .fontSize(11)
        .fontColor('#99FFFFFF')

      Text(value)
        .layoutWeight(1)
        .fontSize(11)
        .fontColor('#F2FFFFFF')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
  }
}

@Component
export struct HdsNavigationOfficialEffectPage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private lastEffectText: string = '等待触发 HDS 特效卡片';
  @State private pressedEffectEntryId: string = '';
  @State private activeEffectEntryId: string = '';
  @State private clickPulseEffectEntryId: string = '';
  @State private clickPulseStrength: number = 0;

  private readonly scroller: Scroller = new Scroller();
  private readonly effectEntries: Array<NGFHdsOfficialEffectEntry> = [
    new NGFHdsOfficialEffectEntry(
      'press_shadow',
      NGFHdsInteractiveEffectPresetKind.PRESS_SHADOW,
      'PressShadow 按压阴影',
      '只启用 hdsEffect.PressShadowType.BLEND_GRADIENT，不叠加 PointLight。\nPressShadow 是按压态效果，请按住卡片观察白色径向混合。',
      '#1E3A8A',
      '#1D4ED8',
      290,
      '仅 PressShadow',
      '#3B82F6',
      '阴影下沉'
    ),
    new NGFHdsOfficialEffectEntry(
      'point_light',
      NGFHdsInteractiveEffectPresetKind.POINT_LIGHT,
      'PointLight 点光聚焦',
      '只启用 pointLight，点击后从 SOFT+BORDER 切换为 BRIGHT+DEFAULT_FEATHERING_BORDER。\n适合焦点、选中和确认操作。',
      '#6D28D9',
      '#5B21B6',
      296,
      '纯点光',
      '#A78BFA',
      '点光聚焦'
    ),
    new NGFHdsOfficialEffectEntry(
      'flow_light',
      NGFHdsInteractiveEffectPresetKind.FLOW_LIGHT_SCENE,
      'FlowLight 流光场景',
      '使用 HdsVisualComponent.scene 启动 DUAL_EDGE_FLOW_LIGHT_WITH_BACKGROUND_MASK。\n点击后播放真实双边流光与背景遮罩动画。',
      '#047857',
      '#083344',
      318,
      '场景流光',
      '#22D3EE',
      '双边流光'
    )
  ];
  private readonly flowLightSceneController: HdsSceneController = new HdsSceneController();
  private clickPulseDecayTimer: number = -1;
  private clickPulseClearTimer: number = -1;

  aboutToAppear(): void {
    NGFPageWindowSupport.apply(NGFPageWindowName.HDS_OFFICIAL_NAVIGATION_EFFECT);
    this.configureFlowLightScene(false);
    logger.lifecycle(TAG, '官方特效即将显示');
  }

  aboutToDisappear(): void {
    this.clearClickPulseTimers();
    this.flowLightSceneController.stop();
    NGFPageWindowSupport.restore(NGFPageWindowName.HDS_OFFICIAL_NAVIGATION);
    logger.lifecycle(TAG, '官方特效即将消失');
  }

  private bindPathStack(context: NavDestinationContext): void {
    this.pathStack = context.pathStack;
    logger.info(TAG, '官方特效已绑定路径栈');
  }

  private handleBackPressed(): boolean {
    this.clearClickPulseTimers();
    this.flowLightSceneController.stop();
    NGFPageWindowSupport.restore(NGFPageWindowName.HDS_OFFICIAL_NAVIGATION);
    this.pathStack.pop();
    logger.info(TAG, '官方特效页面已弹出');
    return true;
  }

  private configureFlowLightScene(active: boolean): void {
    const scenePreset: NGFHdsSceneFlowPreset = NGFHdsEffectPresetFactory.buildFlowLightScenePreset(active);
    this.flowLightSceneController.setSceneParams(scenePreset.sceneParams);
  }

  private startFlowLightScene(): void {
    this.configureFlowLightScene(true);
    this.flowLightSceneController.start();
    logger.info(TAG, 'HDS 流光场景已启动');
  }

  private stopFlowLightScene(): void {
    this.configureFlowLightScene(false);
    this.flowLightSceneController.stop();
    logger.info(TAG, 'HDS 流光场景已停止');
  }

  private animateEffectState(duration: number, curve: Curve, updater: () => void): void {
    const uiContext: UIContext | undefined = this.getUIContext();
    if (uiContext) {
      uiContext.animateTo({
        duration: duration,
        curve: curve
      }, updater);
      return;
    }
    updater();
  }

  private clearClickPulseTimers(): void {
    if (this.clickPulseDecayTimer >= 0) {
      clearTimeout(this.clickPulseDecayTimer);
      this.clickPulseDecayTimer = -1;
    }
    if (this.clickPulseClearTimer >= 0) {
      clearTimeout(this.clickPulseClearTimer);
      this.clickPulseClearTimer = -1;
    }
  }

  private playClickPulse(entryId: string): void {
    this.clearClickPulseTimers();
    this.animateEffectState(90, Curve.EaseOut, (): void => {
      this.clickPulseEffectEntryId = entryId;
      this.clickPulseStrength = 1;
    });
    this.clickPulseDecayTimer = setTimeout((): void => {
      this.animateEffectState(280, Curve.FastOutSlowIn, (): void => {
        this.clickPulseStrength = 0;
      });
      this.clickPulseClearTimer = setTimeout((): void => {
        if (this.clickPulseStrength <= 0) {
          this.clickPulseEffectEntryId = '';
        }
        this.clickPulseClearTimer = -1;
      }, 300);
      this.clickPulseDecayTimer = -1;
    }, 120);
  }

  private updatePressedEffectEntry(entryId: string): void {
    this.animateEffectState(120, Curve.FastOutSlowIn, (): void => {
      this.pressedEffectEntryId = entryId;
    });
    logger.info(TAG, `特效条目按下: ${entryId}`);
  }

  private clearPressedEffectEntry(entryId: string): void {
    if (this.pressedEffectEntryId === entryId) {
      this.animateEffectState(160, Curve.EaseOut, (): void => {
        this.pressedEffectEntryId = '';
      });
      logger.info(TAG, `特效条目释放: ${entryId}`);
    }
  }

  private isEffectEntryEffectActive(entryId: string): boolean {
    return this.pressedEffectEntryId === entryId || this.activeEffectEntryId === entryId;
  }

  private buildInteractivePreset(entry: NGFHdsOfficialEffectEntry): NGFHdsInteractiveEffectPreset {
    return NGFHdsEffectPresetFactory.buildInteractiveEffectPreset(
      entry.presetKind,
      this.isEffectEntryEffectActive(entry.id)
    );
  }

  private activateEffectEntry(entry: NGFHdsOfficialEffectEntry): void {
    if (this.activeEffectEntryId === 'flow_light' && entry.id !== 'flow_light') {
      this.stopFlowLightScene();
    }
    this.animateEffectState(220, Curve.FastOutSlowIn, (): void => {
      this.activeEffectEntryId = entry.id;
    });
    if (entry.presetKind === NGFHdsInteractiveEffectPresetKind.FLOW_LIGHT_SCENE) {
      const scenePreset: NGFHdsSceneFlowPreset = NGFHdsEffectPresetFactory.buildFlowLightScenePreset(true);
      this.startFlowLightScene();
      this.lastEffectText = `已启动 HDS 流光场景：${entry.title}（${scenePreset.apiSummary}）`;
      logger.info(TAG, `特效场景启动: ${entry.id}`);
      return;
    }
    const activePreset: NGFHdsInteractiveEffectPreset =
      NGFHdsEffectPresetFactory.buildInteractiveEffectPreset(entry.presetKind, true);
    if (entry.presetKind === NGFHdsInteractiveEffectPresetKind.PRESS_SHADOW) {
      this.lastEffectText = `已切换 PressShadow 预览：${entry.title}。pressShadow 真实效果发生在按住卡片时。`;
    } else {
      this.lastEffectText = `已激活 HDS 特效卡片：${entry.title}（${activePreset.apiSummary}）`;
    }
    logger.info(TAG, `特效卡片激活: ${entry.id}`);
  }

  private toggleEffectEntry(entry: NGFHdsOfficialEffectEntry): void {
    this.playClickPulse(entry.id);
    if (this.activeEffectEntryId === entry.id) {
      this.animateEffectState(180, Curve.EaseOut, (): void => {
        this.activeEffectEntryId = '';
      });
      if (entry.presetKind === NGFHdsInteractiveEffectPresetKind.FLOW_LIGHT_SCENE) {
        this.stopFlowLightScene();
      }
      this.lastEffectText = `已关闭 HDS 特效卡片：${entry.title}`;
      logger.info(TAG, `特效卡片关闭: ${entry.id}`);
      return;
    }
    this.activateEffectEntry(entry);
  }

  private isEffectEntryClickPulsing(entryId: string): boolean {
    return this.clickPulseEffectEntryId === entryId && this.clickPulseStrength > 0;
  }

  private handleEffectEntryTouch(entryId: string, event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.updatePressedEffectEntry(entryId);
      return;
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.clearPressedEffectEntry(entryId);
    }
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: HDS_OFFICIAL_EFFECT_TOP_CHROME_SPEC })

        Scroll(this.scroller) {
          Column({ space: 14 }) {
            Text('特效目的地')
              .width('100%')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))

            Text('以下卡片分别验证 pressShadow、pointLight 与 HdsVisualComponent.scene：点击可切换持久预览，第一张请按住观察真实按压态，第三张点击会启动流光场景。')
              .width('100%')
              .fontSize(14)
              .lineHeight(22)
              .fontColor($r('app.color.text_secondary'))

            Text(this.lastEffectText)
              .width('100%')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))

            ForEach(this.effectEntries, (entry: NGFHdsOfficialEffectEntry): void => {
              this.buildEffectEntryCard(entry)
            }, (entry: NGFHdsOfficialEffectEntry): string => entry.id)
          }
          .width('100%')
          .padding({
            left: 16,
            right: 16,
            top: HDS_OFFICIAL_EFFECT_TOP_CHROME_SPEC.metrics.contentTopInset,
            bottom: 24
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#00000000')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background_primary'))
    }
    .titleBar(NGFHdsTitleBarOptionsFactory.build(
      '特效目的地',
      'hdsEffect 按压阴影与点光效果组合',
      '#083344',
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
  private buildEffectEntryCard(entry: NGFHdsOfficialEffectEntry): void {
    if (entry.id === 'press_shadow') {
      this.buildPressShadowCard(entry);
    } else if (entry.id === 'point_light') {
      this.buildPointLightCard(entry);
    } else {
      this.buildFlowLightSceneCard(entry);
    }
  }

  @Builder
  private buildEffectActivationBadge(active: boolean): void {
    Text(active ? '已激活' : '点击激活')
      .fontSize(11)
      .fontWeight(FontWeight.Bold)
      .fontColor(active ? '#07111F' : '#CCFFFFFF')
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      .borderRadius(12)
      .backgroundColor(active ? '#FFFFFFFF' : '#22FFFFFF')
      .border({ width: 1, color: active ? '#FFFFFFFF' : '#24FFFFFF' })
  }

  @Builder
  private buildEffectActivationRibbon(entry: NGFHdsOfficialEffectEntry, active: boolean): void {
    Column()
      .width('100%')
      .height(active ? 9 : 3)
      .linearGradient({
        angle: 90,
        colors: [
          [active ? '#FFFFFFFF' : '#22FFFFFF', 0],
          [active ? entry.borderAccent : '#44FFFFFF', 0.48],
          [active ? '#FFFFFFFF' : '#22FFFFFF', 1]
        ]
      })
      .borderRadius(10)
      .opacity(active ? 1 : 0.45)
      .shadow({
        radius: active ? 18 : 0,
        color: active ? `${entry.borderAccent}88` : '#00000000',
        offsetX: 0,
        offsetY: active ? 0 : 0
      })
  }

  @Builder
  private buildEffectClickPulseLayer(entry: NGFHdsOfficialEffectEntry): void {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('78%')
        .height('78%')
        .radialGradient({
          center: ['50%', '50%'],
          radius: '72%',
          colors: [
            ['#FFFFFFFF', 0],
            [`${entry.borderAccent}CC`, 0.36],
            ['#00000000', 1]
          ]
        })
        .borderRadius(24)
        .opacity(this.clickPulseStrength * 0.72)
        .scale({
          x: 0.86 + this.clickPulseStrength * 0.22,
          y: 0.86 + this.clickPulseStrength * 0.22
        })

      Column()
        .width('100%')
        .height('100%')
        .borderRadius(24)
        .border({
          width: 2 + this.clickPulseStrength * 5,
          color: entry.borderAccent
        })
        .opacity(this.clickPulseStrength * 0.68)
        .scale({
          x: 0.98 + this.clickPulseStrength * 0.08,
          y: 0.98 + this.clickPulseStrength * 0.08
        })
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
  }

  @Builder
  private buildPressShadowActiveLayer(entry: NGFHdsOfficialEffectEntry): void {
    Column()
      .width('100%')
      .height('100%')
      .radialGradient({
        center: ['50%', '52%'],
        radius: '78%',
        colors: [
          ['#E6FFFFFF', 0],
          [`${entry.borderAccent}AA`, 0.38],
          ['#00000000', 1]
        ]
      })
      .borderRadius(24)
      .opacity(0.72)
  }

  @Builder
  private buildPointLightActiveLayer(entry: NGFHdsOfficialEffectEntry): void {
    Column()
      .width('100%')
      .height('100%')
      .radialGradient({
        center: ['78%', '18%'],
        radius: '92%',
        colors: [
          ['#FFFFFFFF', 0],
          [`${entry.borderAccent}CC`, 0.36],
          ['#00000000', 1]
        ]
      })
      .borderRadius(24)
      .opacity(0.88)
  }

  @Builder
  private buildPressShadowCard(entry: NGFHdsOfficialEffectEntry): void {
    this.buildPressShadowCardContent(entry, this.buildInteractivePreset(entry))
  }

  @Builder
  private buildPressShadowCardContent(
    entry: NGFHdsOfficialEffectEntry,
    preset: NGFHdsInteractiveEffectPreset
  ): void {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.isEffectEntryEffectActive(entry.id)) {
        this.buildPressShadowActiveLayer(entry)
      }
      if (this.isEffectEntryClickPulsing(entry.id)) {
        this.buildEffectClickPulseLayer(entry)
      }

      Column({ space: 10 }) {
        Row({ space: 8 }) {
          ForEach([1, 2, 3, 4], (level: number): void => {
            Column()
              .width(6)
              .height(level * 6 + 4)
              .backgroundColor(this.isEffectEntryEffectActive(entry.id)
                ? `${entry.borderAccent}66`
                : '#33FFFFFF')
              .borderRadius(3)
          }, (level: number): string => `shadow-bar-${level}`)

          Text(entry.effectLabel)
            .fontSize(12)
            .fontColor('#DDEBFF')
            .layoutWeight(1)
            .textAlign(TextAlign.End)

          this.buildEffectActivationBadge(this.isEffectEntryEffectActive(entry.id))
        }

        this.buildEffectActivationRibbon(entry, this.isEffectEntryEffectActive(entry.id))

        Text(entry.title)
          .width('100%')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.panel_background'))
          .textAlign(TextAlign.Start)

        Text(entry.description)
          .width('100%')
          .fontSize(13)
          .lineHeight(20)
          .fontColor('#E6FFFFFF')
          .textAlign(TextAlign.Start)

        Text(preset.apiSummary)
          .width('100%')
          .fontSize(11)
          .lineHeight(16)
          .fontColor('#DDEBFF')
          .textAlign(TextAlign.Start)

        Row({ space: 6 }) {
          Text('效果状态')
            .fontSize(11)
            .fontColor('#B3FFFFFF')

          Text(preset.stateText)
            .fontSize(11)
            .fontColor(this.isEffectEntryEffectActive(entry.id) ? '#FCD34D' : '#99FFFFFF')
        }
        .width('100%')
        .padding({ top: 6 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(14)
      .backgroundColor('#18000000')
      .borderRadius(18)
      .border({ width: 1, color: '#16FFFFFF' })
      .opacity(preset.contentOpacity)
    }
    .width('100%')
    .height(entry.cardHeight)
    .padding(18)
    .linearGradient({
      angle: 135,
      colors: [
        [entry.accentStart, 0],
        [entry.accentEnd, 1]
      ]
    })
    .borderRadius(24)
    .border({ width: preset.borderWidth, color: preset.borderColor })
    .shadow(preset.shadowOptions)
    .backgroundEffect(preset.backgroundEffect)
    .translate(preset.translateOptions)
    .scale(preset.scaleOptions)
    .animation({
      duration: 200,
      curve: Curve.FastOutSlowIn
    })
    .visualEffect(preset.buildVisualEffect())
    .onTouch((event: TouchEvent): void => {
      this.handleEffectEntryTouch(entry.id, event);
    })
    .onClick((): void => {
      this.toggleEffectEntry(entry);
      this.clearPressedEffectEntry(entry.id);
    })
  }

  @Builder
  private buildPointLightCard(entry: NGFHdsOfficialEffectEntry): void {
    this.buildPointLightCardContent(entry, this.buildInteractivePreset(entry))
  }

  @Builder
  private buildPointLightCardContent(
    entry: NGFHdsOfficialEffectEntry,
    preset: NGFHdsInteractiveEffectPreset
  ): void {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.isEffectEntryEffectActive(entry.id)) {
        this.buildPointLightActiveLayer(entry)
      }
      if (this.isEffectEntryClickPulsing(entry.id)) {
        this.buildEffectClickPulseLayer(entry)
      }

      Column({ space: 10 }) {
        Row({ space: 8 }) {
          Circle()
            .width(20)
            .height(20)
            .fill(this.isEffectEntryEffectActive(entry.id) ? entry.borderAccent : '#33FFFFFF')
            .opacity(this.isEffectEntryEffectActive(entry.id) ? 0.9 : 0.3)

          Text(entry.effectLabel)
            .fontSize(11)
            .fontColor('#B3FFFFFF')

          Text(this.isEffectEntryEffectActive(entry.id) ? `● ${entry.badgeLabel}` : '○ 待触发')
            .fontSize(11)
            .fontColor(this.isEffectEntryEffectActive(entry.id) ? '#FCD34D' : '#99FFFFFF')
            .layoutWeight(1)
            .textAlign(TextAlign.End)

          this.buildEffectActivationBadge(this.isEffectEntryEffectActive(entry.id))
        }

        this.buildEffectActivationRibbon(entry, this.isEffectEntryEffectActive(entry.id))

        Text(entry.title)
          .width('100%')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.panel_background'))
          .textAlign(TextAlign.Start)

        Text(entry.description)
          .width('100%')
          .fontSize(13)
          .lineHeight(20)
          .fontColor('#E6FFFFFF')
          .textAlign(TextAlign.Start)

        Text(preset.apiSummary)
          .width('100%')
          .fontSize(11)
          .lineHeight(16)
          .fontColor('#EDE9FE')
          .textAlign(TextAlign.Start)

        Text(preset.stateText)
          .width('100%')
          .fontSize(11)
          .fontColor(this.isEffectEntryEffectActive(entry.id) ? '#FCD34D' : '#99FFFFFF')
          .textAlign(TextAlign.Start)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(14)
      .backgroundColor('#18000000')
      .borderRadius(18)
      .border({
        width: 1,
        color: this.isEffectEntryEffectActive(entry.id) ? `${entry.borderAccent}88` : '#16FFFFFF'
      })
      .opacity(preset.contentOpacity)
    }
    .width('100%')
    .height(entry.cardHeight)
    .padding(18)
    .linearGradient({
      angle: 135,
      colors: [
        [entry.accentStart, 0],
        [entry.accentEnd, 1]
      ]
    })
    .borderRadius(24)
    .border({ width: preset.borderWidth, color: preset.borderColor })
    .shadow(preset.shadowOptions)
    .backgroundEffect(preset.backgroundEffect)
    .translate(preset.translateOptions)
    .scale(preset.scaleOptions)
    .animation({
      duration: 300,
      curve: Curve.FastOutSlowIn
    })
    .visualEffect(preset.buildVisualEffect())
    .onTouch((event: TouchEvent): void => {
      this.handleEffectEntryTouch(entry.id, event);
    })
    .onClick((): void => {
      this.toggleEffectEntry(entry);
      this.clearPressedEffectEntry(entry.id);
    })
  }

  private handleFlowLightSceneFinished(): void {
    logger.debug(TAG, 'HDS 流光场景动画完成');
  }

  @Builder
  private buildFlowLightSceneCard(entry: NGFHdsOfficialEffectEntry): void {
    this.buildFlowLightSceneCardContent(
      entry,
      this.buildInteractivePreset(entry),
      NGFHdsEffectPresetFactory.buildFlowLightScenePreset(this.isEffectEntryEffectActive(entry.id))
    )
  }

  @Builder
  private buildFlowLightSceneCardContent(
    entry: NGFHdsOfficialEffectEntry,
    preset: NGFHdsInteractiveEffectPreset,
    scenePreset: NGFHdsSceneFlowPreset
  ): void {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [
            ['#041316', 0],
            [entry.accentStart, 0.48],
            [entry.accentEnd, 1]
          ]
        })
        .borderRadius(24)

      HdsVisualComponent()
        .width('100%')
        .height('100%')
        .borderRadius(24)
        .opacity(scenePreset.visualOpacity)
        .hitTestBehavior(HitTestMode.None)
        .scene(
          HdsSceneType.DUAL_EDGE_FLOW_LIGHT_WITH_BACKGROUND_MASK,
          this.flowLightSceneController,
          (): void => {
            this.handleFlowLightSceneFinished();
          },
          scenePreset.frameRateRange
        )

      if (this.isEffectEntryEffectActive(entry.id)) {
        Column()
          .width('100%')
          .height('100%')
          .radialGradient({
            center: ['50%', '50%'],
            radius: '96%',
            colors: [
              ['#44FFFFFF', 0],
              ['#1822D3EE', 0.44],
              ['#00000000', 1]
            ]
          })
          .borderRadius(24)
          .opacity(0.42)
      }
      if (this.isEffectEntryClickPulsing(entry.id)) {
        this.buildEffectClickPulseLayer(entry)
      }

      Column({ space: 10 }) {
        Row({ space: 8 }) {
          ForEach([1, 2, 3, 4], (level: number): void => {
            Column()
              .width(5)
              .height(level * 5 + 8)
              .backgroundColor(this.isEffectEntryEffectActive(entry.id) ? '#BFF7FF' : '#44FFFFFF')
              .borderRadius(3)
              .opacity(this.isEffectEntryEffectActive(entry.id) ? 1 : 0.38)
          }, (level: number): string => `flow-bar-${level}`)

          Text(entry.effectLabel)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isEffectEntryEffectActive(entry.id) ? '#BFF7FF' : '#C9F5FF')
            .layoutWeight(1)
            .textAlign(TextAlign.End)

          this.buildEffectActivationBadge(this.isEffectEntryEffectActive(entry.id))
        }

        this.buildEffectActivationRibbon(entry, this.isEffectEntryEffectActive(entry.id))

        Text(entry.title)
          .width('100%')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#F7FEFF')
          .textAlign(TextAlign.Start)

        Text(entry.description)
          .width('100%')
          .fontSize(13)
          .lineHeight(20)
          .fontColor('#E6FFFFFF')
          .textAlign(TextAlign.Start)

        Text(scenePreset.apiSummary)
          .width('100%')
          .fontSize(11)
          .lineHeight(16)
          .fontColor('#CFFAFE')
          .textAlign(TextAlign.Start)

        Text(scenePreset.stateText)
          .width('100%')
          .fontSize(11)
          .fontColor(this.isEffectEntryEffectActive(entry.id) ? '#FCD34D' : '#99FFFFFF')
          .textAlign(TextAlign.Start)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(14)
      .backgroundColor('#26000000')
      .borderRadius(18)
      .border({ width: 1, color: this.isEffectEntryEffectActive(entry.id) ? '#80FFFFFF' : '#16FFFFFF' })
      .opacity(preset.contentOpacity)
    }
    .width('100%')
    .height(entry.cardHeight)
    .padding(18)
    .borderRadius(24)
    .border({ width: scenePreset.borderWidth, color: scenePreset.borderColor })
    .shadow(scenePreset.shadowOptions)
    .backgroundEffect(preset.backgroundEffect)
    .scale(scenePreset.scaleOptions)
    .translate(scenePreset.translateOptions)
    .animation({
      duration: 280,
      curve: Curve.FastOutSlowIn
    })
    .visualEffect(preset.buildVisualEffect())
    .onTouch((event: TouchEvent): void => {
      this.handleEffectEntryTouch(entry.id, event);
    })
    .onClick((): void => {
      this.toggleEffectEntry(entry);
      this.clearPressedEffectEntry(entry.id);
    })
  }
}
