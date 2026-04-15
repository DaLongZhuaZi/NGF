import { OperationType, SelectOptions, SubHeader } from '@kit.ArkUI';
import { logger } from '../../Framework/NGF/utils/Logger';
import { NGFHdsDemoRouteName } from './HdsDemoRoutes';

const TAG: string = 'NGFHdsLayoutsShowcasePage';

class NGFHdsLayoutCard {
  id: string;
  title: string;
  section: string;
  emphasis: string;
  description: string;
  color: string;

  constructor(id: string, title: string, section: string, emphasis: string, description: string, color: string) {
    this.id = id;
    this.title = title;
    this.section = section;
    this.emphasis = emphasis;
    this.description = description;
    this.color = color;
  }
}

class NGFLayoutActionItem {
  id: string;
  title: string;
  description: string;
  color: string;

  constructor(id: string, title: string, description: string, color: string) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.color = color;
  }
}

class NGFLayoutBannerSlide {
  id: string;
  title: string;
  subtitle: string;
  colorStart: string;
  colorEnd: string;

  constructor(id: string, title: string, subtitle: string, colorStart: string, colorEnd: string) {
    this.id = id;
    this.title = title;
    this.subtitle = subtitle;
    this.colorStart = colorStart;
    this.colorEnd = colorEnd;
  }
}

class NGFLayoutRouteParam {
  routeName: string;
  source: string;

  constructor(routeName: string, source: string) {
    this.routeName = routeName;
    this.source = source;
  }
}

@Component
export struct HdsLayoutsShowcasePage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private currentTabIndex: number = 0;
  @State private currentEmphasisIndex: number = 0;
  @State private selectedLayoutCardId: string = 'grid_cards';
  @State private nestedTabIndex: number = 0;
  @State private layoutHubProgress: number = 36;
  @State private layoutServicesEnabled: boolean = true;
  @State private listDetailExpanded: boolean = true;
  @State private lastHubAction: string = '尚未触发';
  @State private bannerIndex: number = 0;
  @State private bannerAutoPlayEnabled: boolean = false;

  private readonly bannerController: SwiperController = new SwiperController();
  private readonly tabGroups: Array<string> = ['内容布局', '导航布局', '服务入口'];
  private readonly layoutCards: Array<NGFHdsLayoutCard> = [
    new NGFHdsLayoutCard('grid_cards', 'Grid 宫格卡片', '内容布局', '全部', '适合资源中心、工具台、快捷入口等多卡片排布场景。', '#0B57D0'),
    new NGFHdsLayoutCard('list_panels', '列表分区面板', '内容布局', '高频', '配合 SubHeader 作为标题栏，可将列表内容切为多个说明清晰的区段。', '#2E7D32'),
    new NGFHdsLayoutCard('tabs_shell', 'Tabs + TabContent', '导航布局', '全部', '适合顶层频道、探索页、媒体中心的内容分栏与保留上下文。', '#8E24AA'),
    new NGFHdsLayoutCard('navigation_stack', 'Navigation + NavDestination', '导航布局', '高频', '基于 NavPathStack 的标准栈式导航，适合详情、设置和示例子页。', '#00796B'),
    new NGFHdsLayoutCard('action_hub', '服务入口面板', '服务入口', '全部', '将下载、管理、系统状态等入口统一卡片化展示，便于快速进入。', '#EF6C00'),
    new NGFHdsLayoutCard('immersive_banner', '沉浸式头图区', '服务入口', '精选', '适合首页 Banner、活动位和重点推荐区，强调视觉层次与转场。', '#C2185B')
  ];
  private readonly hubActions: Array<NGFLayoutActionItem> = [
    new NGFLayoutActionItem('downloads', '下载中心', '查看全部下载任务与失败重试。', '#0B57D0'),
    new NGFLayoutActionItem('favorites', '我的收藏', '进入用户收藏、历史与最近访问。', '#8E24AA'),
    new NGFLayoutActionItem('sync', '同步服务', '执行账户同步、数据回写与状态刷新。', '#00796B'),
    new NGFLayoutActionItem('settings', '系统设置', '打开主题、网络、通知等配置入口。', '#EF6C00')
  ];
  private readonly bannerSlides: Array<NGFLayoutBannerSlide> = [
    new NGFLayoutBannerSlide('featured', '首页精选横幅', '适合主入口与活动推荐区', '#0B57D0', '#26C6DA'),
    new NGFLayoutBannerSlide('service', '服务状态横幅', '适合展示同步、下载与提醒状态', '#8E24AA', '#EC407A'),
    new NGFLayoutBannerSlide('library', '资源内容横幅', '适合展示内容更新、专题推荐与分类聚合', '#00796B', '#66BB6A')
  ];

  aboutToAppear(): void {
    logger.lifecycle(TAG, 'aboutToAppear');
  }

  aboutToDisappear(): void {
    logger.lifecycle(TAG, 'aboutToDisappear');
  }

  private buildSelectOptions(): SelectOptions {
    return {
      options: [
        { value: '全部' },
        { value: '高频' },
        { value: '精选' }
      ],
      selected: this.currentEmphasisIndex,
      value: this.resolveEmphasisFilter(),
      onSelect: (index: number): void => {
        this.currentEmphasisIndex = index;
        logger.info(TAG, `layout emphasis switched: index=${index}`);
      }
    };
  }

  private resolveCurrentTabName(): string {
    return this.tabGroups[this.currentTabIndex];
  }

  private resolveEmphasisFilter(): string {
    if (this.currentEmphasisIndex === 1) {
      return '高频';
    }
    if (this.currentEmphasisIndex === 2) {
      return '精选';
    }
    return '全部';
  }

  private buildCardsForCurrentTab(): Array<NGFHdsLayoutCard> {
    const result: Array<NGFHdsLayoutCard> = [];
    const currentSection = this.resolveCurrentTabName();
    const emphasis = this.resolveEmphasisFilter();
    for (let index = 0; index < this.layoutCards.length; index++) {
      const card = this.layoutCards[index];
      if (card.section !== currentSection) {
        continue;
      }
      if (emphasis !== '全部' && card.emphasis !== emphasis) {
        continue;
      }
      result.push(card);
    }
    return result;
  }

  private resolveActiveLayoutCard(): NGFHdsLayoutCard {
    const cards = this.buildCardsForCurrentTab();
    for (let index = 0; index < cards.length; index++) {
      if (cards[index].id === this.selectedLayoutCardId) {
        return cards[index];
      }
    }
    if (cards.length > 0) {
      return cards[0];
    }
    return this.layoutCards[0];
  }

  private isSelectedLayoutCard(cardId: string): boolean {
    return this.resolveActiveLayoutCard().id === cardId;
  }

  private selectLayoutCard(cardId: string): void {
    this.selectedLayoutCardId = cardId;
    logger.info(TAG, `layout demo selected: ${cardId}`);
  }

  private resetLayoutInteractiveState(): void {
    this.nestedTabIndex = 0;
    this.layoutHubProgress = 36;
    this.layoutServicesEnabled = true;
    this.listDetailExpanded = true;
    this.lastHubAction = '尚未触发';
    this.bannerIndex = 0;
    this.bannerAutoPlayEnabled = false;
    logger.info(TAG, 'layout interactive state reset');
  }

  private triggerHubAction(action: NGFLayoutActionItem): void {
    this.lastHubAction = action.title;
    this.layoutHubProgress = Math.min(100, this.layoutHubProgress + 12);
    logger.info(TAG, `layout hub action triggered: ${action.id}`);
  }

  private navigateTo(routeName: string, label: string): void {
    try {
      this.pathStack.pushPathByName(routeName, new NGFLayoutRouteParam(routeName, TAG));
      logger.info(TAG, `navigate to route: ${routeName}, label=${label}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `navigate failed: route=${routeName}, label=${label}, error=${message}`);
    }
  }

  private shiftBanner(step: number): void {
    let nextIndex = this.bannerIndex + step;
    if (nextIndex < 0) {
      nextIndex = this.bannerSlides.length - 1;
    }
    if (nextIndex >= this.bannerSlides.length) {
      nextIndex = 0;
    }
    this.bannerIndex = nextIndex;
    this.bannerController.changeIndex(nextIndex, true);
    logger.info(TAG, `banner changed by button: index=${nextIndex}`);
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        SubHeader({
          primaryTitle: 'HDS 布局与标签示例',
          secondaryTitle: '组合 Tabs、Grid 与 SubHeader 构建标准页面骨架',
          select: this.buildSelectOptions(),
          operationType: OperationType.TEXT_ARROW,
          operationItem: [
            {
              value: '回到默认',
              action: (): void => {
                this.currentTabIndex = 0;
                this.currentEmphasisIndex = 0;
                this.selectedLayoutCardId = 'grid_cards';
                this.resetLayoutInteractiveState();
                logger.info(TAG, 'layout filters reset to default');
              }
            }
          ]
        })

        Tabs({ index: this.currentTabIndex }) {
          TabContent() {
            Scroll() {
              this.buildLayoutGrid()
            }
            .width('100%')
            .height('100%')
          }
          .tabBar('内容布局')

          TabContent() {
            Scroll() {
              this.buildLayoutGrid()
            }
            .width('100%')
            .height('100%')
          }
          .tabBar('导航布局')

          TabContent() {
            Scroll() {
              this.buildLayoutGrid()
            }
            .width('100%')
            .height('100%')
          }
          .tabBar('服务入口')
        }
        .barMode(BarMode.Fixed)
        .width('100%')
        .layoutWeight(1)
        .onChange((index: number): void => {
          this.currentTabIndex = index;
          logger.info(TAG, `tab changed: index=${index}`);
        })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor($r('app.color.background_primary'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .title('HDS 布局示例')
    .backgroundColor($r('app.color.background_primary'))
    .onReady((context: NavDestinationContext): void => {
      this.pathStack = context.pathStack;
    })
    .onBackPressed((): boolean => {
      logger.info(TAG, 'back pressed');
      this.pathStack.pop();
      return true;
    })
  }

  @Builder
  private buildLayoutGrid(): void {
    Column({ space: 12 }) {
      Text(`${this.resolveCurrentTabName()} · ${this.resolveEmphasisFilter()} · 当前互动布局：${this.resolveActiveLayoutCard().title}`)
        .width('100%')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))

      this.buildLayoutInteractivePanel()

      if (this.buildCardsForCurrentTab().length <= 0) {
        Column({ space: 8 }) {
          Text('当前标签下暂无布局示例')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))

          Text('可切换顶部标签页或右侧筛选条件查看更多内容。')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding(18)
        .backgroundColor($r('app.color.panel_background'))
        .borderRadius(16)
        .border({ width: 1, color: $r('app.color.panel_border') })
      } else {
        Grid() {
          ForEach(this.buildCardsForCurrentTab(), (card: NGFHdsLayoutCard) => {
            GridItem() {
              this.buildLayoutCardItem(card)
            }
          }, (card: NGFHdsLayoutCard): string => `${this.resolveCurrentTabName()}_${card.id}`)
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
        .width('100%')
      }
    }
    .width('100%')
    .padding({ bottom: 12 })
  }

  @Builder
  private buildLayoutInteractivePanel(): void {
    Column({ space: 12 }) {
      SubHeader({
        primaryTitle: `互动布局 · ${this.resolveActiveLayoutCard().title}`,
        secondaryTitle: '点击下方卡片切换布局，并直接操作官方组件',
        operationType: OperationType.BUTTON,
        operationItem: [
          {
            value: '重置示例',
            action: (): void => {
              this.resetLayoutInteractiveState();
            }
          }
        ]
      })

      Text(this.resolveActiveLayoutCard().description)
        .width('100%')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))

      if (this.resolveActiveLayoutCard().id === 'grid_cards') {
        this.buildGridCardsDemo()
      } else if (this.resolveActiveLayoutCard().id === 'list_panels') {
        this.buildListPanelsDemo()
      } else if (this.resolveActiveLayoutCard().id === 'tabs_shell') {
        this.buildTabsShellDemo()
      } else if (this.resolveActiveLayoutCard().id === 'navigation_stack') {
        this.buildNavigationDemo()
      } else if (this.resolveActiveLayoutCard().id === 'action_hub') {
        this.buildActionHubDemo()
      } else {
        this.buildImmersiveBannerDemo()
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(18)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildGridCardsDemo(): void {
    Column({ space: 12 }) {
      Grid() {
        ForEach(this.hubActions, (action: NGFLayoutActionItem) => {
          GridItem() {
            Button(action.title)
              .width('100%')
              .height(74)
              .backgroundColor(action.color)
              .fontColor($r('app.color.text_white'))
              .onClick((): void => {
                this.triggerHubAction(action);
              })
          }
        }, (action: NGFLayoutActionItem): string => action.id)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .width('100%')

      Text(`最近触发：${this.lastHubAction}`)
        .width('100%')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
  }

  @Builder
  private buildListPanelsDemo(): void {
    Column({ space: 10 }) {
      SubHeader({
        primaryTitle: '资源列表区段',
        secondaryTitle: '一个列表面板可以由多个官方 SubHeader 分区组成',
        operationType: OperationType.TEXT_ARROW,
        operationItem: [
          {
            value: this.listDetailExpanded ? '收起说明' : '展开说明',
            action: (): void => {
              this.listDetailExpanded = !this.listDetailExpanded;
              logger.info(TAG, `list detail expanded: ${this.listDetailExpanded}`);
            }
          }
        ]
      })

      if (this.listDetailExpanded) {
        Text('点击右侧“进入”按钮，可以模拟进入下载、收藏、同步等分区内容。')
          .width('100%')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
      }

      Column({ space: 10 }) {
        ForEach(this.hubActions, (action: NGFLayoutActionItem) => {
          Row({ space: 12 }) {
            Column({ space: 4 }) {
              Text(action.title)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))

              Text(action.description)
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Button('进入')
              .height(36)
              .backgroundColor(action.color)
              .fontColor($r('app.color.text_white'))
              .onClick((): void => {
                this.triggerHubAction(action);
              })
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#10FFFFFF')
          .borderRadius(14)
        }, (action: NGFLayoutActionItem): string => `panel_${action.id}`)
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private buildTabsShellDemo(): void {
    Column({ space: 12 }) {
      Tabs({ index: this.nestedTabIndex }) {
        TabContent() {
          Column({ space: 8 }) {
            Text('发现页内容')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
            Text('适合放推荐位、分类入口、最近更新等组合内容。')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding(14)
        }
        .tabBar('发现')

        TabContent() {
          Column({ space: 8 }) {
            Text('服务页内容')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
            Text('适合放下载中心、同步状态、通知与任务调度。')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding(14)
        }
        .tabBar('服务')

        TabContent() {
          Column({ space: 8 }) {
            Text('我的页内容')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
            Text('适合放账户信息、收藏列表、使用记录与设置入口。')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding(14)
        }
        .tabBar('我的')
      }
      .barMode(BarMode.Fixed)
      .width('100%')
      .height(180)
      .onChange((index: number): void => {
        this.nestedTabIndex = index;
        logger.info(TAG, `nested tabs changed: index=${index}`);
      })

      Text(`当前子标签页：${this.nestedTabIndex + 1}/3`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
  }

  @Builder
  private buildNavigationDemo(): void {
    Column({ space: 12 }) {
      Text('下列按钮会直接复用 MainMenuPage 的 NavPathStack 导航到其他官方示例页。')
        .width('100%')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))

      Row({ space: 12 }) {
        Button('打开组件示例')
          .layoutWeight(1)
          .height(40)
          .backgroundColor($r('app.color.button_primary'))
          .fontColor($r('app.color.text_white'))
          .onClick((): void => {
            this.navigateTo(NGFHdsDemoRouteName.COMPONENTS, 'HDS 组件示例');
          })

        Button('打开动效示例')
          .layoutWeight(1)
          .height(40)
          .backgroundColor($r('app.color.button_success'))
          .fontColor($r('app.color.text_white'))
          .onClick((): void => {
            this.navigateTo(NGFHdsDemoRouteName.MOTION, 'HDS 动效示例');
          })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private buildActionHubDemo(): void {
    Column({ space: 12 }) {
      Row() {
        Text('服务入口启用')
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: this.layoutServicesEnabled })
          .selectedColor($r('app.color.button_primary'))
          .onChange((isOn: boolean): void => {
            this.layoutServicesEnabled = isOn;
            logger.info(TAG, `layout services enabled: ${isOn}`);
          })
      }
      .width('100%')

      Progress({ value: this.layoutHubProgress, total: 100, type: ProgressType.Linear })
        .width('100%')
        .color($r('app.color.button_success'))

      Text(`服务面板准备度：${this.layoutHubProgress}%`)
        .width('100%')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))

      Grid() {
        ForEach(this.hubActions, (action: NGFLayoutActionItem) => {
          GridItem() {
            Button(action.title)
              .width('100%')
              .height(58)
              .backgroundColor(this.layoutServicesEnabled ? action.color : '#778899')
              .fontColor($r('app.color.text_white'))
              .enabled(this.layoutServicesEnabled)
              .onClick((): void => {
                this.triggerHubAction(action);
              })
          }
        }, (action: NGFLayoutActionItem): string => `hub_${action.id}`)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private buildImmersiveBannerDemo(): void {
    Column({ space: 12 }) {
      Swiper(this.bannerController) {
        ForEach(this.bannerSlides, (slide: NGFLayoutBannerSlide, index: number) => {
          Stack({ alignContent: Alignment.BottomStart }) {
            Column({ space: 8 }) {
              Text(slide.subtitle)
                .fontSize(13)
                .fontColor('#D9FFFFFF')

              Text(slide.title)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
            .width('100%')
            .height('100%')
            .padding(20)
            .justifyContent(FlexAlign.End)
            .linearGradient({
              angle: 135,
              colors: [
                [slide.colorStart, 0],
                [slide.colorEnd, 1]
              ]
            })
            .borderRadius(22)
          }
          .padding({ top: 4, bottom: 10, left: 2, right: 2 })
          .onClick((): void => {
            this.bannerIndex = index;
            logger.info(TAG, `banner slide clicked: index=${index}`);
          })
        }, (slide: NGFLayoutBannerSlide): string => slide.id)
      }
      .width('100%')
      .height(220)
      .autoPlay(this.bannerAutoPlayEnabled)
      .interval(3200)
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
        this.bannerIndex = index;
        logger.info(TAG, `banner changed: index=${index}`);
      })

      Row() {
        Text(`当前横幅：${this.bannerIndex + 1}/${this.bannerSlides.length}`)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: this.bannerAutoPlayEnabled })
          .selectedColor($r('app.color.button_primary'))
          .onChange((isOn: boolean): void => {
            this.bannerAutoPlayEnabled = isOn;
            logger.info(TAG, `banner autoplay toggled: enabled=${isOn}`);
          })
      }
      .width('100%')

      Row({ space: 12 }) {
        Button('上一张')
          .layoutWeight(1)
          .height(40)
          .backgroundColor($r('app.color.button_secondary'))
          .fontColor($r('app.color.text_white'))
          .onClick((): void => {
            this.shiftBanner(-1);
          })

        Button('下一张')
          .layoutWeight(1)
          .height(40)
          .backgroundColor($r('app.color.button_success'))
          .fontColor($r('app.color.text_white'))
          .onClick((): void => {
            this.shiftBanner(1);
          })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private buildLayoutCardItem(card: NGFHdsLayoutCard): void {
    Column({ space: 10 }) {
      Row() {
        Text(card.emphasis)
          .fontSize(11)
          .fontColor($r('app.color.text_white'))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(card.color)
          .borderRadius(99)
        Blank()
        Text(this.isSelectedLayoutCard(card.id) ? '已选中' : '点击切换')
          .fontSize(11)
          .fontColor(this.isSelectedLayoutCard(card.id) ? card.color : $r('app.color.text_secondary'))
      }
      .width('100%')

      Text(card.title)
        .width('100%')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Text(card.description)
        .width('100%')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(4)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row() {
        Text(card.section)
          .fontSize(12)
          .fontColor(card.color)
        Blank()
      }
      .width('100%')
    }
    .width('100%')
    .height(200)
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(18)
    .border({
      width: this.isSelectedLayoutCard(card.id) ? 2 : 1,
      color: this.isSelectedLayoutCard(card.id) ? card.color : $r('app.color.panel_border')
    })
    .shadow({ radius: 10, color: '#14000000', offsetX: 0, offsetY: 4 })
    .onClick((): void => {
      this.selectLayoutCard(card.id);
    })
  }
}
