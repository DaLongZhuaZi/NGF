import { hdsEffect, hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { logger } from '../../Framework/NGF/utils/Logger';
import { NGFHdsDemoRouteName } from './HdsDemoRoutes';
import { NGFHdsTitleBarOptionsFactory } from './HdsNavigationSupport';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from './NGFImmersiveTopChrome';
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
const NGF_HDS_OFFICIAL_SURFACE_SHADOW: string = '#180F172A';

class NGFHdsOfficialActionCard {
  id: string;
  routeName: string;
  title: string;
  subtitle: string;
  description: string;
  accentStart: string;
  accentEnd: string;

  constructor(
    id: string,
    routeName: string,
    title: string,
    subtitle: string,
    description: string,
    accentStart: string,
    accentEnd: string
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
  accentColor: string;

  constructor(id: string, title: string, description: string, accentColor: string) {
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
  accentStart: string;
  accentEnd: string;

  constructor(id: string, title: string, description: string, accentStart: string, accentEnd: string) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.accentStart = accentStart;
    this.accentEnd = accentEnd;
  }
}

class NGFHdsOfficialEffectEntry {
  id: string;
  title: string;
  description: string;
  accentStart: string;
  accentEnd: string;

  constructor(id: string, title: string, description: string, accentStart: string, accentEnd: string) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.accentStart = accentStart;
    this.accentEnd = accentEnd;
  }
}

class NGFHdsPointLightOptions implements hdsEffect.PointLightOptions {
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

class NGFHdsPointLightEffect implements hdsEffect.PointLightEffect {
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

class NGFHdsEffectFactory {
  static buildPrimaryCardEffect(): VisualEffect {
    const pointLightOptions = new NGFHdsPointLightOptions('#E6FFFFFF', 0.34, 30, 0.28);
    const pointLightEffect = new NGFHdsPointLightEffect(
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
    const pointLightOptions = new NGFHdsPointLightOptions('#CCFFFFFF', 0.24, 26, 0.18);
    const pointLightEffect = new NGFHdsPointLightEffect(
      hdsEffect.PointLightSourceType.BRIGHT,
      hdsEffect.PointLightIlluminatedType.BORDER,
      pointLightOptions
    );
    return new hdsEffect.HdsEffectBuilder()
      .pressShadow(hdsEffect.PressShadowType.BLEND_WHITE)
      .pointLight(pointLightEffect)
      .buildEffect();
  }

  static buildPressShadowOnlyEffect(): VisualEffect {
    return new hdsEffect.HdsEffectBuilder()
      .pressShadow(hdsEffect.PressShadowType.BLEND_GRADIENT)
      .buildEffect();
  }

  static buildPointLightOnlyEffect(pressed: boolean): VisualEffect {
    const pointLightOptions = pressed
      ? new NGFHdsPointLightOptions('#F2FFFFFF', 0.42, 34, 0.36)
      : new NGFHdsPointLightOptions('#CCFFFFFF', 0.2, 24, 0.14);
    const pointLightEffect = new NGFHdsPointLightEffect(
      pressed ? hdsEffect.PointLightSourceType.BRIGHT : hdsEffect.PointLightSourceType.SOFT,
      hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
      pointLightOptions
    );
    return new hdsEffect.HdsEffectBuilder()
      .pointLight(pointLightEffect)
      .buildEffect();
  }

  static buildCombinedInteractiveEffect(pressed: boolean): VisualEffect {
    const pointLightOptions = pressed
      ? new NGFHdsPointLightOptions('#F5FFFFFF', 0.4, 34, 0.34)
      : new NGFHdsPointLightOptions('#D9FFFFFF', 0.22, 24, 0.16);
    const pointLightEffect = new NGFHdsPointLightEffect(
      pressed ? hdsEffect.PointLightSourceType.BRIGHT : hdsEffect.PointLightSourceType.SOFT,
      hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
      pointLightOptions
    );
    const builder = new hdsEffect.HdsEffectBuilder()
      .pointLight(pointLightEffect);
    if (pressed) {
      builder.pressShadow(hdsEffect.PressShadowType.BLEND_WHITE);
    }
    return builder.buildEffect();
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
      '#0B57D0',
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
    logger.lifecycle(TAG, 'official showcase aboutToAppear');
  }

  aboutToDisappear(): void {
    logger.lifecycle(TAG, 'official showcase aboutToDisappear');
  }

  private bindPathStack(context: NavDestinationContext): void {
    this.pathStack = context.pathStack;
    logger.info(TAG, 'bound pathStack for official showcase');
  }

  private handleBackPressed(): boolean {
    NGFPageWindowSupport.restoreMainMenu();
    this.pathStack.pop();
    logger.info(TAG, 'pop official showcase page');
    return true;
  }

  private openDestination(card: NGFHdsOfficialActionCard): void {
    try {
      this.pathStack.pushPathByName(card.routeName, null);
      this.lastActionText = `已打开：${card.title}`;
      this.openedCount = this.openedCount + 1;
      logger.info(TAG, `open official HDS route: ${card.routeName}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.lastActionText = `打开失败：${card.title}`;
      logger.warn(TAG, `open official HDS route failed: route=${card.routeName}, error=${message}`);
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
      logger.info(TAG, 'official showcase shown');
    })
    .onHidden((): void => {
      logger.info(TAG, 'official showcase hidden');
    })
    .backgroundColor($r('app.color.background_primary'))
  }

  @Builder
  private buildHeroCard(): void {
    Column({ space: 12 }) {
      Text('MainMenuPage → HdsNavigation')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFFFF')

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
    .visualEffect(NGFHdsEffectFactory.buildPrimaryCardEffect())
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
    .border({ width: 1, color: '#24FFFFFF' })
    .shadow({ radius: 16, color: '#220F172A', offsetX: 0, offsetY: 10 })
    .visualEffect(NGFHdsEffectFactory.buildPrimaryCardEffect())
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
      '#0B57D0'
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
    logger.lifecycle(TAG, 'official overview aboutToAppear');
  }

  aboutToDisappear(): void {
    NGFPageWindowSupport.restore(NGFPageWindowName.HDS_OFFICIAL_NAVIGATION);
    logger.lifecycle(TAG, 'official overview aboutToDisappear');
  }

  private bindPathStack(context: NavDestinationContext): void {
    this.pathStack = context.pathStack;
    logger.info(TAG, 'bound pathStack for overview page');
  }

  private handleBackPressed(): boolean {
    NGFPageWindowSupport.restore(NGFPageWindowName.HDS_OFFICIAL_NAVIGATION);
    this.pathStack.pop();
    logger.info(TAG, 'pop overview page');
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
    .visualEffect(NGFHdsEffectFactory.buildAccentCardEffect())
  }
}

@Component
export struct HdsNavigationOfficialMaterialPage {
  @State private pathStack: NavPathStack = new NavPathStack();

  private readonly scroller: Scroller = new Scroller();
  private readonly materialItems: Array<NGFHdsOfficialMaterialItem> = [
    new NGFHdsOfficialMaterialItem(
      'gentle',
      'GENTLE 材质层级',
      '适合作为主菜单入口页标题栏的柔和玻璃材质，强调稳定可读性。',
      '#1E293B',
      '#1F2937'
    ),
    new NGFHdsOfficialMaterialItem(
      'smooth',
      'SMOOTH 材质层级',
      '适合作为内容目的地标题栏的平滑材质，滚动时保留更强的层次感。',
      '#312E81',
      '#3730A3'
    ),
    new NGFHdsOfficialMaterialItem(
      'exquisite',
      'EXQUISITE 材质层级',
      '适合作为强调型目的地标题栏的精致材质，验证更高质感的沉浸表现。',
      '#0F766E',
      '#0F5F59'
    )
  ];

  aboutToAppear(): void {
    NGFPageWindowSupport.apply(NGFPageWindowName.HDS_OFFICIAL_NAVIGATION_MATERIAL);
    logger.lifecycle(TAG, 'official material aboutToAppear');
  }

  aboutToDisappear(): void {
    NGFPageWindowSupport.restore(NGFPageWindowName.HDS_OFFICIAL_NAVIGATION);
    logger.lifecycle(TAG, 'official material aboutToDisappear');
  }

  private bindPathStack(context: NavDestinationContext): void {
    this.pathStack = context.pathStack;
    logger.info(TAG, 'bound pathStack for material page');
  }

  private handleBackPressed(): boolean {
    NGFPageWindowSupport.restore(NGFPageWindowName.HDS_OFFICIAL_NAVIGATION);
    this.pathStack.pop();
    logger.info(TAG, 'pop material page');
    return true;
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
    Stack({ alignContent: Alignment.Center }) {
      Column({ space: 8 }) {
        Text(item.title)
          .width('100%')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFFFF')

        Text(item.description)
          .width('100%')
          .fontSize(13)
          .lineHeight(20)
          .fontColor('#E6FFFFFF')
      }
      .width('100%')
      .padding(14)
      .backgroundColor('#18000000')
      .borderRadius(18)
      .border({ width: 1, color: '#16FFFFFF' })
      .margin(4)
    }
    .width('100%')
    .padding(18)
    .linearGradient({
      angle: 135,
      colors: [
        [item.accentStart, 0],
        [item.accentEnd, 1]
      ]
    })
    .borderRadius(24)
    .border({ width: 1, color: '#22FFFFFF' })
    .shadow({ radius: 16, color: '#220F172A', offsetX: 0, offsetY: 10 })
    .visualEffect(NGFHdsEffectFactory.buildPrimaryCardEffect())
  }
}

@Component
export struct HdsNavigationOfficialEffectPage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private lastEffectText: string = '等待触发 HDS 特效卡片';
  @State private pressedEffectEntryId: string = '';

  private readonly scroller: Scroller = new Scroller();
  private readonly effectEntries: Array<NGFHdsOfficialEffectEntry> = [
    new NGFHdsOfficialEffectEntry(
      'press_shadow',
      'PressShadow',
      '点击卡片时使用 hdsEffect.PressShadowType 产生官方压感反馈。',
      '#1E3A8A',
      '#1D4ED8'
    ),
    new NGFHdsOfficialEffectEntry(
      'point_light',
      'PointLight',
      '使用点光模型强调边框与内容区域，适合焦点卡片和重要操作。',
      '#6D28D9',
      '#5B21B6'
    ),
    new NGFHdsOfficialEffectEntry(
      'combined',
      'Combined',
      '在同一视觉节点中组合 PressShadow 与 PointLight，验证 HDS 特效叠加后的交互表现。',
      '#047857',
      '#0F5F59'
    )
  ];

  aboutToAppear(): void {
    NGFPageWindowSupport.apply(NGFPageWindowName.HDS_OFFICIAL_NAVIGATION_EFFECT);
    logger.lifecycle(TAG, 'official effect aboutToAppear');
  }

  aboutToDisappear(): void {
    NGFPageWindowSupport.restore(NGFPageWindowName.HDS_OFFICIAL_NAVIGATION);
    logger.lifecycle(TAG, 'official effect aboutToDisappear');
  }

  private bindPathStack(context: NavDestinationContext): void {
    this.pathStack = context.pathStack;
    logger.info(TAG, 'bound pathStack for effect page');
  }

  private handleBackPressed(): boolean {
    NGFPageWindowSupport.restore(NGFPageWindowName.HDS_OFFICIAL_NAVIGATION);
    this.pathStack.pop();
    logger.info(TAG, 'pop effect page');
    return true;
  }

  private updatePressedEffectEntry(entryId: string): void {
    this.pressedEffectEntryId = entryId;
    logger.info(TAG, `effect entry pressed: ${entryId}`);
  }

  private clearPressedEffectEntry(entryId: string): void {
    if (this.pressedEffectEntryId === entryId) {
      this.pressedEffectEntryId = '';
      logger.info(TAG, `effect entry released: ${entryId}`);
    }
  }

  private isEffectEntryPressed(entryId: string): boolean {
    return this.pressedEffectEntryId === entryId;
  }

  private buildInteractiveEffect(entry: NGFHdsOfficialEffectEntry): VisualEffect {
    const pressed = this.isEffectEntryPressed(entry.id);
    if (entry.id === 'press_shadow') {
      return pressed ? NGFHdsEffectFactory.buildPressShadowOnlyEffect() : NGFHdsEffectFactory.buildPointLightOnlyEffect(false);
    }
    if (entry.id === 'point_light') {
      return NGFHdsEffectFactory.buildPointLightOnlyEffect(pressed);
    }
    return NGFHdsEffectFactory.buildCombinedInteractiveEffect(pressed);
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

            Text('以下交互卡片全部通过官方 hdsEffect.HdsEffectBuilder 生成视觉效果，点击卡片可直接观察 PressShadow 与 PointLight 的反馈。')
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
    Button() {
      Column({ space: 8 }) {
        Text(entry.title)
          .width('100%')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFFFF')
          .textAlign(TextAlign.Start)

        Text(entry.description)
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
    .height(122)
    .padding(18)
    .buttonStyle(ButtonStyleMode.NORMAL)
    .stateEffect(false)
    .linearGradient({
      angle: 135,
      colors: [
        [entry.accentStart, 0],
        [entry.accentEnd, 1]
      ]
    })
    .borderRadius(24)
    .border({ width: 1, color: '#22FFFFFF' })
    .shadow({ radius: 16, color: '#220F172A', offsetX: 0, offsetY: 10 })
    .scale(this.isEffectEntryPressed(entry.id) ? { x: 0.985, y: 0.985 } : { x: 1, y: 1 })
    .visualEffect(this.buildInteractiveEffect(entry))
    .onTouch((event: TouchEvent): void => {
      this.handleEffectEntryTouch(entry.id, event);
    })
    .onClick((): void => {
      this.lastEffectText = `已触发 HDS 特效卡片：${entry.title}`;
      this.clearPressedEffectEntry(entry.id);
      logger.info(TAG, `effect card clicked: ${entry.id}`);
    })
  }
}
