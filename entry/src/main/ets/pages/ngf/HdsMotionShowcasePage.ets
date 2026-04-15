import { OperationType, SegmentButton, SegmentButtonOptions, SubHeader } from '@kit.ArkUI';
import { logger } from '../../Framework/NGF/utils/Logger';

const TAG: string = 'NGFHdsMotionShowcasePage';

class NGFHdsMotionSlide {
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

@Component
export struct HdsMotionShowcasePage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private currentIndex: number = 0;
  @State private autoPlayEnabled: boolean = true;
  @State private selectedMotionIndexes: Array<number> = [1];
  @State private motionOptions: SegmentButtonOptions = SegmentButtonOptions.tab({
    buttons: [
      { text: '柔和' },
      { text: '标准' },
      { text: '强调' }
    ]
  });
  @State private intervalValue: number = 3200;
  @State private scalePercent: number = 100;
  @State private shadowEnabled: boolean = true;

  private readonly swiperController: SwiperController = new SwiperController();
  private readonly slides: Array<NGFHdsMotionSlide> = [
    new NGFHdsMotionSlide('banner', 'Banner 焦点位', '标准缩放', '适合首页头图、重点活动和推荐位展示。', '#0B57D0', '#26C6DA'),
    new NGFHdsMotionSlide('hero', 'Hero 内容卡', '层次透明度', '通过透明度与阴影变化强调当前焦点内容。', '#7B1FA2', '#EC407A'),
    new NGFHdsMotionSlide('gallery', 'Gallery 轮播', '平滑切页', '结合 Swiper 指示器与索引说明，形成完整浏览闭环。', '#00796B', '#66BB6A')
  ];

  aboutToAppear(): void {
    logger.lifecycle(TAG, 'aboutToAppear');
  }

  aboutToDisappear(): void {
    logger.lifecycle(TAG, 'aboutToDisappear');
  }

  private resetMotionDemo(): void {
    this.currentIndex = 0;
    this.autoPlayEnabled = true;
    this.selectedMotionIndexes = [1];
    this.intervalValue = 3200;
    this.scalePercent = 100;
    this.shadowEnabled = true;
    this.swiperController.changeIndex(0, true);
    logger.info(TAG, 'motion demo reset');
  }

  private resolveMotionModeLabel(): string {
    if (this.selectedMotionIndexes.length <= 0) {
      return '标准';
    }
    const index = this.selectedMotionIndexes[0];
    if (index === 0) {
      return '柔和';
    }
    if (index === 2) {
      return '强调';
    }
    return '标准';
  }

  private currentScale(): number {
    let baseScale = 1.01;
    if (this.selectedMotionIndexes.length > 0) {
      const index = this.selectedMotionIndexes[0];
      if (index === 0) {
        baseScale = 0.96;
      } else if (index === 2) {
        baseScale = 1.06;
      }
    }
    return baseScale * this.scalePercent / 100;
  }

  private currentOpacity(): number {
    if (this.selectedMotionIndexes.length <= 0) {
      return 0.88;
    }
    const index = this.selectedMotionIndexes[0];
    if (index === 0) {
      return 0.86;
    }
    if (index === 2) {
      return 1;
    }
    return 0.93;
  }

  private isFocusedSlide(index: number): boolean {
    return this.currentIndex === index;
  }

  private resolveMotionProgress(): number {
    return (this.currentIndex + 1) * 100 / this.slides.length;
  }

  private resolveShadowRadius(index: number): number {
    if (!this.shadowEnabled) {
      return 0;
    }
    return this.isFocusedSlide(index) ? 18 : 10;
  }

  private selectSlide(index: number): void {
    this.currentIndex = index;
    this.swiperController.changeIndex(index, true);
    logger.info(TAG, `motion slide selected: index=${index}`);
  }

  private shiftSlide(step: number): void {
    let nextIndex = this.currentIndex + step;
    if (nextIndex < 0) {
      nextIndex = this.slides.length - 1;
    }
    if (nextIndex >= this.slides.length) {
      nextIndex = 0;
    }
    this.selectSlide(nextIndex);
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          SubHeader({
            primaryTitle: 'HDS 动效示例',
            secondaryTitle: '使用官方 Swiper 与分段切换组织轮播、焦点和过渡效果',
            operationType: OperationType.BUTTON,
            operationItem: [
              {
                value: '重置示例',
                action: (): void => {
                  this.resetMotionDemo();
                }
              }
            ]
          })

          SegmentButton({
            options: this.motionOptions,
            selectedIndexes: this.selectedMotionIndexes,
            onItemClicked: (index: number): void => {
              this.selectedMotionIndexes = [index];
              logger.info(TAG, `motion mode switched: index=${index}`);
            }
          })

          this.buildMotionStatusCard()
          this.buildMotionControlPanel()

          Swiper(this.swiperController) {
            ForEach(this.slides, (slide: NGFHdsMotionSlide, index: number) => {
              this.buildSlideItem(slide, index)
            }, (slide: NGFHdsMotionSlide): string => slide.id)
          }
          .width('100%')
          .height(260)
          .autoPlay(this.autoPlayEnabled)
          .interval(this.intervalValue)
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
            this.currentIndex = index;
            logger.info(TAG, `swiper changed: index=${index}`);
          })

          this.buildSlideSelectorRow()
          this.buildMotionActionRow()
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
    .title('HDS 动效示例')
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
  private buildMotionStatusCard(): void {
    Column({ space: 6 }) {
      Text('当前状态')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Text(`当前页：${this.currentIndex + 1}/${this.slides.length}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))

      Text(`动效模式：${this.resolveMotionModeLabel()}  ·  自动播放：${this.autoPlayEnabled ? '开启' : '关闭'}`)
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
  private buildMotionControlPanel(): void {
    Column({ space: 12 }) {
      Row() {
        Text(`轮播间隔：${this.intervalValue} ms`)
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Text(`缩放：${this.scalePercent}%`)
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')

      Slider({ value: this.intervalValue, min: 1800, max: 5000, step: 200, style: SliderStyle.OutSet })
        .width('100%')
        .selectedColor($r('app.color.button_primary'))
        .trackColor($r('app.color.panel_border'))
        .onChange((value: number): void => {
          this.intervalValue = value;
          logger.info(TAG, `motion interval changed: ${value}`);
        })

      Slider({ value: this.scalePercent, min: 90, max: 115, step: 1, style: SliderStyle.OutSet })
        .width('100%')
        .selectedColor($r('app.color.button_success'))
        .trackColor($r('app.color.panel_border'))
        .onChange((value: number): void => {
          this.scalePercent = value;
          logger.info(TAG, `motion scale changed: ${value}`);
        })

      Row() {
        Text('阴影强调')
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: this.shadowEnabled })
          .selectedColor($r('app.color.button_primary'))
          .onChange((isOn: boolean): void => {
            this.shadowEnabled = isOn;
            logger.info(TAG, `motion shadow toggled: enabled=${isOn}`);
          })
      }
      .width('100%')

      Progress({ value: this.resolveMotionProgress(), total: 100, type: ProgressType.Linear })
        .width('100%')
        .color($r('app.color.button_success'))
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildSlideItem(slide: NGFHdsMotionSlide, index: number): void {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column({ space: 10 }) {
        Text(slide.subtitle)
          .fontSize(13)
          .fontColor('#CCFFFFFF')

        Text(slide.title)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)

        Text(slide.description)
          .fontSize(14)
          .fontColor('#E6FFFFFF')
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .height('100%')
      .padding(22)
      .justifyContent(FlexAlign.End)
      .linearGradient({
        angle: 135,
        colors: [
          [slide.colorStart, 0],
          [slide.colorEnd, 1]
        ]
      })
      .borderRadius(24)
      .scale({
        x: this.isFocusedSlide(index) ? this.currentScale() : 0.92,
        y: this.isFocusedSlide(index) ? this.currentScale() : 0.92
      })
      .opacity(this.isFocusedSlide(index) ? 1 : this.currentOpacity())
      .shadow({
        radius: this.resolveShadowRadius(index),
        color: this.shadowEnabled ? '#26000000' : '#00000000',
        offsetX: 0,
        offsetY: 10
      })
      .animation({ duration: 320, curve: Curve.EaseInOut })
    }
    .padding({ top: 8, bottom: 12, left: 6, right: 6 })
    .onClick((): void => {
      this.selectSlide(index);
    })
  }

  @Builder
  private buildSlideSelectorRow(): void {
    Row({ space: 10 }) {
      ForEach(this.slides, (slide: NGFHdsMotionSlide, index: number) => {
        Button(`${index + 1}. ${slide.title}`)
          .layoutWeight(1)
          .height(40)
          .backgroundColor(this.isFocusedSlide(index) ? $r('app.color.button_primary') : $r('app.color.button_secondary'))
          .fontColor($r('app.color.text_white'))
          .onClick((): void => {
            this.selectSlide(index);
          })
      }, (slide: NGFHdsMotionSlide): string => `selector_${slide.id}`)
    }
    .width('100%')
  }

  @Builder
  private buildMotionActionRow(): void {
    Row({ space: 12 }) {
      Button('上一张')
        .layoutWeight(1)
        .height(42)
        .backgroundColor($r('app.color.button_secondary'))
        .fontColor($r('app.color.text_white'))
        .onClick((): void => {
          logger.info(TAG, 'show previous slide');
          this.shiftSlide(-1);
        })

      Button(this.autoPlayEnabled ? '关闭自动播放' : '开启自动播放')
        .layoutWeight(1)
        .height(42)
        .backgroundColor($r('app.color.button_primary'))
        .fontColor($r('app.color.text_white'))
        .onClick((): void => {
          this.autoPlayEnabled = !this.autoPlayEnabled;
          logger.info(TAG, `toggle autoplay: enabled=${this.autoPlayEnabled}`);
        })

      Button('下一张')
        .layoutWeight(1)
        .height(42)
        .backgroundColor($r('app.color.button_success'))
        .fontColor($r('app.color.text_white'))
        .onClick((): void => {
          logger.info(TAG, 'show next slide');
          this.shiftSlide(1);
        })
    }
    .width('100%')
  }
}
