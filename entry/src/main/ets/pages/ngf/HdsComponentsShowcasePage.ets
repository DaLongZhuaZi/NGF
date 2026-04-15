import {
  ChipGroup,
  ChipGroupItemOptions,
  OperationType,
  SegmentButton,
  SegmentButtonOptions,
  SelectOptions,
  SubHeader
} from '@kit.ArkUI';
import { logger } from '../../Framework/NGF/utils/Logger';

const TAG: string = 'NGFHdsComponentsShowcasePage';

class NGFHdsExampleCard {
  id: string;
  title: string;
  group: string;
  tags: Array<string>;
  description: string;
  accentColor: string;

  constructor(id: string, title: string, group: string, tags: Array<string>, description: string, accentColor: string) {
    this.id = id;
    this.title = title;
    this.group = group;
    this.tags = tags;
    this.description = description;
    this.accentColor = accentColor;
  }
}

class NGFComponentSearchEntry {
  title: string;
  category: string;
  description: string;

  constructor(title: string, category: string, description: string) {
    this.title = title;
    this.category = category;
    this.description = description;
  }
}

class NGFComponentDemoSlide {
  id: string;
  title: string;
  description: string;
  colorStart: string;
  colorEnd: string;

  constructor(id: string, title: string, description: string, colorStart: string, colorEnd: string) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.colorStart = colorStart;
    this.colorEnd = colorEnd;
  }
}

@Component
export struct HdsComponentsShowcasePage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private searchValue: string = '';
  @State private selectedSegmentIndexes: Array<number> = [0];
  @State private selectedChipIndexes: Array<number> = [0];
  @State private selectedDemoCardId: string = 'segment_button';
  @State private segmentOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [
      { text: '全部' },
      { text: '组件' },
      { text: '布局' }
    ]
  });
  @State private demoSegmentOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [
      { text: '推荐' },
      { text: '服务' },
      { text: '设置' }
    ]
  });
  @State private demoSegmentIndexes: Array<number> = [0];
  @State private demoChipIndexes: Array<number> = [0];
  @State private demoSearchValue: string = '';
  @State private demoTabsIndex: number = 0;
  @State private demoSwiperIndex: number = 0;
  @State private demoSubHeaderSelectIndex: number = 0;
  @State private demoTaskCount: number = 2;
  @State private demoAutoPlayEnabled: boolean = false;
  @State private demoNoticeEnabled: boolean = true;

  private readonly demoSwiperController: SwiperController = new SwiperController();
  private readonly chipItems: Array<ChipGroupItemOptions> = [
    { label: { text: '全部' } },
    { label: { text: 'HDS' } },
    { label: { text: '表单' } },
    { label: { text: '导航' } },
    { label: { text: '动效' } }
  ];
  private readonly demoChipItems: Array<ChipGroupItemOptions> = [
    { label: { text: '消息' } },
    { label: { text: '下载' } },
    { label: { text: '收藏' } },
    { label: { text: '历史' } }
  ];
  private readonly exampleCards: Array<NGFHdsExampleCard> = [
    new NGFHdsExampleCard(
      'segment_button',
      'SegmentButton',
      '组件',
      ['HDS', '导航'],
      '使用官方 SegmentButton 分段切换内容，适合作为频道、状态和内容分组入口。',
      '#0B57D0'
    ),
    new NGFHdsExampleCard(
      'chip_group',
      'ChipGroup',
      '组件',
      ['HDS', '表单'],
      '使用官方 ChipGroup 进行轻量筛选，强调单选/多选条件的快速反馈。',
      '#00796B'
    ),
    new NGFHdsExampleCard(
      'sub_header',
      'SubHeader',
      '组件',
      ['HDS', '导航'],
      '使用官方 SubHeader 组织分区说明与右侧操作，适合作为列表区段标题。',
      '#6A1B9A'
    ),
    new NGFHdsExampleCard(
      'search',
      'Search',
      '布局',
      ['表单', '导航'],
      '采用官方 Search 交互模式，支持输入联想、关键词过滤和即时反馈。',
      '#EF6C00'
    ),
    new NGFHdsExampleCard(
      'tabs',
      'Tabs',
      '布局',
      ['导航'],
      '使用官方 Tabs/TabContent 构建横向内容分栏，适合首页和资源中心。',
      '#AD1457'
    ),
    new NGFHdsExampleCard(
      'swiper_motion',
      'Swiper + Motion',
      '布局',
      ['动效', '导航'],
      '遵循官方 Swiper 能力组织轮播与焦点切换，配合缩放/透明度做页面动效。',
      '#00838F'
    )
  ];
  private readonly demoSearchEntries: Array<NGFComponentSearchEntry> = [
    new NGFComponentSearchEntry('应用中心', '服务', '展示常用应用入口与安装状态。'),
    new NGFComponentSearchEntry('下载管理', '服务', '查看下载进度、失败重试与队列状态。'),
    new NGFComponentSearchEntry('媒体中心', '内容', '组织视频、音频与近期播放记录。'),
    new NGFComponentSearchEntry('系统设置', '设置', '管理主题、通知、网络与权限。'),
    new NGFComponentSearchEntry('收藏列表', '内容', '聚合用户关注的内容与快捷操作。'),
    new NGFComponentSearchEntry('消息通知', '服务', '预览系统消息、升级提示与提醒。')
  ];
  private readonly demoSlides: Array<NGFComponentDemoSlide> = [
    new NGFComponentDemoSlide('intro', '焦点内容', '通过官方 Swiper 轮播重点内容。', '#0B57D0', '#26C6DA'),
    new NGFComponentDemoSlide('service', '服务入口', '将高频服务以轮播卡片形式聚合。', '#8E24AA', '#EC407A'),
    new NGFComponentDemoSlide('status', '状态信息', '适合展示近期任务、同步状态与提醒。', '#00796B', '#66BB6A')
  ];

  aboutToAppear(): void {
    logger.lifecycle(TAG, 'aboutToAppear');
  }

  aboutToDisappear(): void {
    logger.lifecycle(TAG, 'aboutToDisappear');
  }

  private resetFilters(): void {
    this.searchValue = '';
    this.selectedSegmentIndexes = [0];
    this.selectedChipIndexes = [0];
    logger.info(TAG, 'reset HDS component filters');
  }

  private resetInteractiveDemos(): void {
    this.selectedDemoCardId = 'segment_button';
    this.demoSegmentIndexes = [0];
    this.demoChipIndexes = [0];
    this.demoSearchValue = '';
    this.demoTabsIndex = 0;
    this.demoSwiperIndex = 0;
    this.demoSubHeaderSelectIndex = 0;
    this.demoTaskCount = 2;
    this.demoAutoPlayEnabled = false;
    this.demoNoticeEnabled = true;
    logger.info(TAG, 'reset interactive demos');
  }

  private selectDemoCard(cardId: string): void {
    this.selectedDemoCardId = cardId;
    logger.info(TAG, `select demo card: ${cardId}`);
  }

  private resolveSegmentLabel(): string {
    if (this.selectedSegmentIndexes.length <= 0) {
      return '全部';
    }
    const index = this.selectedSegmentIndexes[0];
    if (index === 1) {
      return '组件';
    }
    if (index === 2) {
      return '布局';
    }
    return '全部';
  }

  private resolveChipLabel(): string {
    if (this.selectedChipIndexes.length <= 0) {
      return '全部';
    }
    const index = this.selectedChipIndexes[0];
    if (index === 1) {
      return 'HDS';
    }
    if (index === 2) {
      return '表单';
    }
    if (index === 3) {
      return '导航';
    }
    if (index === 4) {
      return '动效';
    }
    return '全部';
  }

  private resolveDemoSegmentLabel(): string {
    if (this.demoSegmentIndexes.length <= 0) {
      return '推荐';
    }
    const index = this.demoSegmentIndexes[0];
    if (index === 1) {
      return '服务';
    }
    if (index === 2) {
      return '设置';
    }
    return '推荐';
  }

  private resolveDemoChipLabel(): string {
    if (this.demoChipIndexes.length <= 0) {
      return '消息';
    }
    const index = this.demoChipIndexes[0];
    if (index === 1) {
      return '下载';
    }
    if (index === 2) {
      return '收藏';
    }
    if (index === 3) {
      return '历史';
    }
    return '消息';
  }

  private resolveDemoTabLabel(): string {
    if (this.demoTabsIndex === 1) {
      return '组件规范';
    }
    if (this.demoTabsIndex === 2) {
      return '接入建议';
    }
    return '官方示例';
  }

  private resolveDemoPriorityLabel(): string {
    if (this.demoSubHeaderSelectIndex === 1) {
      return '中优先级';
    }
    if (this.demoSubHeaderSelectIndex === 2) {
      return '低优先级';
    }
    return '高优先级';
  }

  private buildVisibleCards(): Array<NGFHdsExampleCard> {
    const result: Array<NGFHdsExampleCard> = [];
    const searchValue = this.searchValue.trim().toLowerCase();
    const segmentLabel = this.resolveSegmentLabel();
    const chipLabel = this.resolveChipLabel();

    for (let index = 0; index < this.exampleCards.length; index++) {
      const card = this.exampleCards[index];
      if (segmentLabel !== '全部' && card.group !== segmentLabel) {
        continue;
      }
      if (chipLabel !== '全部' && !this.containsTag(card.tags, chipLabel)) {
        continue;
      }
      if (searchValue.length > 0 && !this.matchesSearch(card, searchValue)) {
        continue;
      }
      result.push(card);
    }

    return result;
  }

  private containsTag(tags: Array<string>, tag: string): boolean {
    for (let index = 0; index < tags.length; index++) {
      if (tags[index] === tag) {
        return true;
      }
    }
    return false;
  }

  private matchesSearch(card: NGFHdsExampleCard, searchValue: string): boolean {
    if (card.title.toLowerCase().indexOf(searchValue) >= 0) {
      return true;
    }
    if (card.description.toLowerCase().indexOf(searchValue) >= 0) {
      return true;
    }
    if (card.group.toLowerCase().indexOf(searchValue) >= 0) {
      return true;
    }
    for (let index = 0; index < card.tags.length; index++) {
      if (card.tags[index].toLowerCase().indexOf(searchValue) >= 0) {
        return true;
      }
    }
    return false;
  }

  private resolveSelectedDemoCard(): NGFHdsExampleCard {
    for (let index = 0; index < this.exampleCards.length; index++) {
      if (this.exampleCards[index].id === this.selectedDemoCardId) {
        return this.exampleCards[index];
      }
    }
    return this.exampleCards[0];
  }

  private isSelectedDemoCard(cardId: string): boolean {
    return this.resolveSelectedDemoCard().id === cardId;
  }

  private buildDemoSearchResults(): Array<NGFComponentSearchEntry> {
    const keyword = this.demoSearchValue.trim().toLowerCase();
    const result: Array<NGFComponentSearchEntry> = [];

    for (let index = 0; index < this.demoSearchEntries.length; index++) {
      const entry = this.demoSearchEntries[index];
      if (keyword.length <= 0) {
        result.push(entry);
        continue;
      }
      if (entry.title.toLowerCase().indexOf(keyword) >= 0) {
        result.push(entry);
        continue;
      }
      if (entry.category.toLowerCase().indexOf(keyword) >= 0) {
        result.push(entry);
        continue;
      }
      if (entry.description.toLowerCase().indexOf(keyword) >= 0) {
        result.push(entry);
      }
    }

    return result;
  }

  private buildDemoSubHeaderSelectOptions(): SelectOptions {
    return {
      options: [
        { value: '高优先级' },
        { value: '中优先级' },
        { value: '低优先级' }
      ],
      selected: this.demoSubHeaderSelectIndex,
      value: this.resolveDemoPriorityLabel(),
      onSelect: (index: number): void => {
        this.demoSubHeaderSelectIndex = index;
        logger.info(TAG, `demo subheader priority changed: index=${index}`);
      }
    };
  }

  private shiftDemoSegment(step: number): void {
    const currentIndex = this.demoSegmentIndexes.length > 0 ? this.demoSegmentIndexes[0] : 0;
    let nextIndex = currentIndex + step;
    if (nextIndex < 0) {
      nextIndex = 2;
    }
    if (nextIndex > 2) {
      nextIndex = 0;
    }
    this.demoSegmentIndexes = [nextIndex];
    logger.info(TAG, `demo segment changed by button: index=${nextIndex}`);
  }

  private shiftDemoSwiper(step: number): void {
    let nextIndex = this.demoSwiperIndex + step;
    if (nextIndex < 0) {
      nextIndex = this.demoSlides.length - 1;
    }
    if (nextIndex >= this.demoSlides.length) {
      nextIndex = 0;
    }
    this.demoSwiperIndex = nextIndex;
    this.demoSwiperController.changeIndex(nextIndex, true);
    logger.info(TAG, `demo swiper changed by button: index=${nextIndex}`);
  }

  private selectDemoSwiper(index: number): void {
    this.demoSwiperIndex = index;
    this.demoSwiperController.changeIndex(index, true);
    logger.info(TAG, `demo swiper selected: index=${index}`);
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          SubHeader({
            primaryTitle: 'HDS 组件示例',
            secondaryTitle: '基于官方 SDK 组件能力组织搜索、筛选与分段切换',
            operationType: OperationType.BUTTON,
            operationItem: [
              {
                value: '重置筛选',
                action: (): void => {
                  this.resetFilters();
                }
              }
            ]
          })

          Search({ value: this.searchValue, placeholder: '搜索 HDS / ArkUI 官方示例组件' })
            .searchButton('搜索')
            .width('100%')
            .onChange((value: string): void => {
              this.searchValue = value;
            })

          SegmentButton({
            options: this.segmentOptions,
            selectedIndexes: this.selectedSegmentIndexes,
            onItemClicked: (index: number): void => {
              this.selectedSegmentIndexes = [index];
              logger.info(TAG, `segment switched: index=${index}`);
            }
          })

          ChipGroup({
            items: this.chipItems,
            selectedIndexes: this.selectedChipIndexes,
            multiple: false,
            onChange: (indexes: Array<number>): void => {
              this.selectedChipIndexes = indexes.length > 0 ? indexes : [0];
              logger.info(TAG, `chip changed: indexes=${JSON.stringify(this.selectedChipIndexes)}`);
            }
          })

          this.buildSummaryCard()
          this.buildInteractiveDemoPanel()
          this.buildCardsGrid()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 24 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background_primary'))
      .scrollBar(BarState.Auto)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .title('HDS 组件示例')
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
  private buildSummaryCard(): void {
    Column({ space: 6 }) {
      Text('筛选结果')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Text(`当前分组：${this.resolveSegmentLabel()}  ·  当前标签：${this.resolveChipLabel()}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))

      Text(`当前互动示例：${this.resolveSelectedDemoCard().title}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))

      Text(`符合条件的官方示例组件：${this.buildVisibleCards().length}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildInteractiveDemoPanel(): void {
    Column({ space: 12 }) {
      SubHeader({
        primaryTitle: `互动示例 · ${this.resolveSelectedDemoCard().title}`,
        secondaryTitle: '点击下方卡片切换组件，直接操作官方控件',
        operationType: OperationType.BUTTON,
        operationItem: [
          {
            value: '重置示例',
            action: (): void => {
              this.resetInteractiveDemos();
            }
          }
        ]
      })

      Text(this.resolveSelectedDemoCard().description)
        .width('100%')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))

      if (this.resolveSelectedDemoCard().id === 'segment_button') {
        this.buildSegmentDemo()
      } else if (this.resolveSelectedDemoCard().id === 'chip_group') {
        this.buildChipGroupDemo()
      } else if (this.resolveSelectedDemoCard().id === 'sub_header') {
        this.buildSubHeaderDemo()
      } else if (this.resolveSelectedDemoCard().id === 'search') {
        this.buildSearchDemo()
      } else if (this.resolveSelectedDemoCard().id === 'tabs') {
        this.buildTabsDemo()
      } else {
        this.buildSwiperDemo()
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(18)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildSegmentDemo(): void {
    Column({ space: 12 }) {
      SegmentButton({
        options: this.demoSegmentOptions,
        selectedIndexes: this.demoSegmentIndexes,
        onItemClicked: (index: number): void => {
          this.demoSegmentIndexes = [index];
          logger.info(TAG, `demo segment clicked: index=${index}`);
        }
      })

      Text(`当前频道：${this.resolveDemoSegmentLabel()}`)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Progress({ value: (this.demoSegmentIndexes[0] + 1) * 33, total: 100, type: ProgressType.Linear })
        .width('100%')
        .color($r('app.color.button_primary'))

      Row({ space: 12 }) {
        Button('上一项')
          .layoutWeight(1)
          .height(40)
          .backgroundColor($r('app.color.button_secondary'))
          .fontColor($r('app.color.text_white'))
          .onClick((): void => {
            this.shiftDemoSegment(-1);
          })

        Button('下一项')
          .layoutWeight(1)
          .height(40)
          .backgroundColor($r('app.color.button_primary'))
          .fontColor($r('app.color.text_white'))
          .onClick((): void => {
            this.shiftDemoSegment(1);
          })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private buildChipGroupDemo(): void {
    Column({ space: 12 }) {
      ChipGroup({
        items: this.demoChipItems,
        selectedIndexes: this.demoChipIndexes,
        multiple: false,
        onChange: (indexes: Array<number>): void => {
          this.demoChipIndexes = indexes.length > 0 ? indexes : [0];
          logger.info(TAG, `demo chip changed: indexes=${JSON.stringify(this.demoChipIndexes)}`);
        }
      })

      Row() {
        Text(`当前筛选标签：${this.resolveDemoChipLabel()}`)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: this.demoNoticeEnabled })
          .selectedColor($r('app.color.button_primary'))
          .onChange((isOn: boolean): void => {
            this.demoNoticeEnabled = isOn;
            logger.info(TAG, `demo notice switch: enabled=${isOn}`);
          })
      }
      .width('100%')

      Text(this.demoNoticeEnabled ? '通知联动已开启，筛选后可继续触发消息区刷新。' : '通知联动已关闭，仅保留本地筛选反馈。')
        .width('100%')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
  }

  @Builder
  private buildSubHeaderDemo(): void {
    Column({ space: 12 }) {
      SubHeader({
        primaryTitle: '下载任务区段',
        secondaryTitle: '右侧按钮与选择器都来自官方 SubHeader',
        select: this.buildDemoSubHeaderSelectOptions(),
        operationType: OperationType.BUTTON,
        operationItem: [
          {
            value: '新增任务',
            action: (): void => {
              this.demoTaskCount = this.demoTaskCount + 1;
              logger.info(TAG, `demo task count increased: count=${this.demoTaskCount}`);
            }
          }
        ]
      })

      Text(`当前任务数：${this.demoTaskCount}  ·  当前优先级：${this.resolveDemoPriorityLabel()}`)
        .width('100%')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))

      Row({ space: 12 }) {
        Button('完成一项')
          .layoutWeight(1)
          .height(40)
          .backgroundColor($r('app.color.button_success'))
          .fontColor($r('app.color.text_white'))
          .onClick((): void => {
            if (this.demoTaskCount > 0) {
              this.demoTaskCount = this.demoTaskCount - 1;
            }
            logger.info(TAG, `demo task count decreased: count=${this.demoTaskCount}`);
          })

        Button('清空任务')
          .layoutWeight(1)
          .height(40)
          .backgroundColor($r('app.color.button_secondary'))
          .fontColor($r('app.color.text_white'))
          .onClick((): void => {
            this.demoTaskCount = 0;
            logger.info(TAG, 'demo task count cleared');
          })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private buildSearchDemo(): void {
    Column({ space: 12 }) {
      Search({ value: this.demoSearchValue, placeholder: '搜索资源中心 / 服务入口 / 设置项' })
        .searchButton('查找')
        .width('100%')
        .onChange((value: string): void => {
          this.demoSearchValue = value;
        })

      Row({ space: 12 }) {
        Text(`匹配结果：${this.buildDemoSearchResults().length}`)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
        Blank()
        Button('清空')
          .height(34)
          .backgroundColor($r('app.color.button_secondary'))
          .fontColor($r('app.color.text_white'))
          .onClick((): void => {
            this.demoSearchValue = '';
          })
      }
      .width('100%')

      if (this.buildDemoSearchResults().length <= 0) {
        Text('暂无匹配内容，请尝试搜索“服务”、“设置”或“通知”。')
          .width('100%')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
      } else {
        Column({ space: 10 }) {
          ForEach(this.buildDemoSearchResults(), (entry: NGFComponentSearchEntry) => {
            Column({ space: 6 }) {
              Row() {
                Text(entry.title)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                Blank()
                Text(entry.category)
                  .fontSize(12)
                  .fontColor($r('app.color.button_primary'))
              }
              .width('100%')

              Text(entry.description)
                .width('100%')
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#10FFFFFF')
            .borderRadius(14)
            .onClick((): void => {
              this.demoSearchValue = entry.title;
              logger.info(TAG, `demo search item clicked: ${entry.title}`);
            })
          }, (entry: NGFComponentSearchEntry): string => `${entry.category}_${entry.title}`)
        }
        .width('100%')
      }
    }
    .width('100%')
  }

  @Builder
  private buildTabsDemo(): void {
    Column({ space: 12 }) {
      Tabs({ index: this.demoTabsIndex }) {
        TabContent() {
          Column({ space: 8 }) {
            Text('官方示例栏位')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
            Text('适合放置组件说明、预览入口与当前状态。')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding(14)
        }
        .tabBar('官方示例')

        TabContent() {
          Column({ space: 8 }) {
            Text('组件规范栏位')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
            Text('适合放置禁用态、空态、间距与交互反馈规范。')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding(14)
        }
        .tabBar('组件规范')

        TabContent() {
          Column({ space: 8 }) {
            Text('接入建议栏位')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
            Text('适合总结接入方式、与 MainMenuPage 的导航关系及日志策略。')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding(14)
        }
        .tabBar('接入建议')
      }
      .barMode(BarMode.Fixed)
      .width('100%')
      .height(180)
      .onChange((index: number): void => {
        this.demoTabsIndex = index;
        logger.info(TAG, `demo tabs changed: index=${index}`);
      })

      Text(`当前标签页：${this.resolveDemoTabLabel()}`)
        .width('100%')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
  }

  @Builder
  private buildSwiperDemo(): void {
    Column({ space: 12 }) {
      Swiper(this.demoSwiperController) {
        ForEach(this.demoSlides, (slide: NGFComponentDemoSlide, index: number) => {
          Stack({ alignContent: Alignment.BottomStart }) {
            Column({ space: 8 }) {
              Text(slide.title)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)

              Text(slide.description)
                .fontSize(13)
                .fontColor('#F5FFFFFF')
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
            this.selectDemoSwiper(index);
          })
        }, (slide: NGFComponentDemoSlide): string => slide.id)
      }
      .width('100%')
      .height(220)
      .autoPlay(this.demoAutoPlayEnabled)
      .interval(2600)
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
        this.demoSwiperIndex = index;
        logger.info(TAG, `demo swiper changed: index=${index}`);
      })

      Row() {
        Text(`当前轮播：${this.demoSwiperIndex + 1}/${this.demoSlides.length}`)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: this.demoAutoPlayEnabled })
          .selectedColor($r('app.color.button_primary'))
          .onChange((isOn: boolean): void => {
            this.demoAutoPlayEnabled = isOn;
            logger.info(TAG, `demo swiper autoplay toggled: enabled=${isOn}`);
          })
      }
      .width('100%')

      Row({ space: 10 }) {
        Button('上一张')
          .layoutWeight(1)
          .height(40)
          .backgroundColor($r('app.color.button_secondary'))
          .fontColor($r('app.color.text_white'))
          .onClick((): void => {
            this.shiftDemoSwiper(-1);
          })

        Button('下一张')
          .layoutWeight(1)
          .height(40)
          .backgroundColor($r('app.color.button_success'))
          .fontColor($r('app.color.text_white'))
          .onClick((): void => {
            this.shiftDemoSwiper(1);
          })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private buildCardsGrid(): void {
    if (this.buildVisibleCards().length <= 0) {
      Column({ space: 10 }) {
        Text('没有匹配结果')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Text('尝试修改搜索词、分段或 Chip 筛选条件。')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .padding(20)
      .backgroundColor($r('app.color.panel_background'))
      .borderRadius(16)
      .border({ width: 1, color: $r('app.color.panel_border') })
    } else {
      Grid() {
        ForEach(this.buildVisibleCards(), (card: NGFHdsExampleCard) => {
          GridItem() {
            this.buildCardItem(card)
          }
        }, (card: NGFHdsExampleCard): string => card.id)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width('100%')
    }
  }

  @Builder
  private buildCardItem(card: NGFHdsExampleCard): void {
    Column({ space: 10 }) {
      Row() {
        Text(card.group)
          .fontSize(11)
          .fontColor($r('app.color.text_white'))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(card.accentColor)
          .borderRadius(99)

        Blank()

        Text(this.isSelectedDemoCard(card.id) ? '已选中' : '点击体验')
          .fontSize(11)
          .fontColor(this.isSelectedDemoCard(card.id) ? card.accentColor : $r('app.color.text_secondary'))
      }
      .width('100%')

      Text(card.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      Text(card.description)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .maxLines(4)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(card.tags, (tag: string) => {
          Text(tag)
            .fontSize(11)
            .fontColor(card.accentColor)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#12222222')
            .borderRadius(99)
            .margin({ right: 6, bottom: 6 })
        }, (tag: string): string => `${card.id}_${tag}`)
      }
      .width('100%')
    }
    .width('100%')
    .height(236)
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(18)
    .border({
      width: this.isSelectedDemoCard(card.id) ? 2 : 1,
      color: this.isSelectedDemoCard(card.id) ? card.accentColor : $r('app.color.panel_border')
    })
    .shadow({
      radius: this.isSelectedDemoCard(card.id) ? 14 : 10,
      color: '#14000000',
      offsetX: 0,
      offsetY: 6
    })
    .animation({ duration: 240, curve: Curve.EaseInOut })
    .onClick((): void => {
      this.selectDemoCard(card.id);
    })
  }
}
