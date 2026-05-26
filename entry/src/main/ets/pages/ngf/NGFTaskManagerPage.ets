import { HdsNavDestination, hdsMaterial } from '@kit.UIDesignKit';
import { NGFHdsTitleBarOptionsFactory } from '../../Framework/NGF/uiShell/components/HdsNavigationSupport';
import {
  NGFImmersiveTopChromeUnderlay,
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec
} from '../../Framework/NGF/uiShell/components/NGFImmersiveTopChrome';
import { ngfSystem, NGFTaskInfo, NGFTaskState } from '../../Framework/NGF/systemTasks/index';
import { NGFNotificationRequest, NGFNotificationType } from '../../Framework/NGF/systemTasks/contracts/ISystemNotificationManager';
import { NGFPageWindowSupport } from './NGFPageWindowSupport';

const DEMO_TOP_CHROME_BLUE: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#07101E', '#0C2341', '#0A1626', '#3B82F6D8', '#22D3EED8', 160, 88
);





@Component
export struct NGFTaskManagerPage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private tasks: Array<NGFTaskInfo> = [];
  private readonly listenerId = 'NGFTaskManagerPage_Listener';

  aboutToAppear(): void {
    this.refreshTasks();
    const handleEvent = () => {
      this.refreshTasks();
    };
    ngfSystem.subscribeSystemEvent('ngf.task.started', this.listenerId, handleEvent);
    ngfSystem.subscribeSystemEvent('ngf.task.progress', this.listenerId, handleEvent);
    ngfSystem.subscribeSystemEvent('ngf.task.completed', this.listenerId, handleEvent);
    ngfSystem.subscribeSystemEvent('ngf.task.failed', this.listenerId, handleEvent);
  }

  aboutToDisappear(): void {
    NGFPageWindowSupport.restoreMainMenu();
    ngfSystem.unsubscribeSystemEvent('ngf.task.started', this.listenerId);
    ngfSystem.unsubscribeSystemEvent('ngf.task.progress', this.listenerId);
    ngfSystem.unsubscribeSystemEvent('ngf.task.completed', this.listenerId);
    ngfSystem.unsubscribeSystemEvent('ngf.task.failed', this.listenerId);
  }

  private refreshTasks(): void {
    const allTasks = ngfSystem.getAllTasks();
    // Copy the array to trigger UI updates
    this.tasks = [...allTasks];
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: DEMO_TOP_CHROME_BLUE })

        Scroll() {
          Column({ space: 16 }) {
            this.buildTitleCard()
            
            Text('测试任务排队与执行')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 8, bottom: -8 })

            Button('提交模拟下载任务 (带进度模板)', { type: ButtonType.Capsule })
              .width('100%')
              .height(44)
              .fontSize(14)
              .backgroundColor($r('app.color.button_primary'))
              .onClick(() => {
                this.submitMockDownloadTask();
              })

            Text('测试多类型通知')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 8, bottom: -8 })

            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
              Button('基础通知', { type: ButtonType.Normal })
                .borderRadius(8)
                .width('48%')
                .height(40)
                .fontSize(13)
                .backgroundColor($r('app.color.button_secondary'))
                .fontColor($r('app.color.text_primary'))
                .margin({ bottom: 12 })
                .onClick(() => this.testBasicNotification())

              Button('长文本通知', { type: ButtonType.Normal })
                .borderRadius(8)
                .width('48%')
                .height(40)
                .fontSize(13)
                .backgroundColor($r('app.color.button_secondary'))
                .fontColor($r('app.color.text_primary'))
                .margin({ bottom: 12 })
                .onClick(() => this.testLongTextNotification())

              Button('多行通知', { type: ButtonType.Normal })
                .borderRadius(8)
                .width('48%')
                .height(40)
                .fontSize(13)
                .backgroundColor($r('app.color.button_secondary'))
                .fontColor($r('app.color.text_primary'))
                .margin({ bottom: 12 })
                .onClick(() => this.testMultiLineNotification())

              Button('自定义进度模板', { type: ButtonType.Normal })
                .borderRadius(8)
                .width('48%')
                .height(40)
                .fontSize(13)
                .backgroundColor($r('app.color.button_secondary'))
                .fontColor($r('app.color.text_primary'))
                .margin({ bottom: 12 })
                .onClick(() => this.testCustomNotification())
            }
            .width('100%')

            List({ space: 12 }) {
              ForEach(this.tasks, (task: NGFTaskInfo) => {
                ListItem() {
                  TaskListItem({ task: task })
                }
              }, (task: NGFTaskInfo) => task.taskId)
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Auto)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: DEMO_TOP_CHROME_BLUE.metrics.contentTopInset, bottom: 36 })
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
      '后台任务与通知',
      '长时任务、通知与事件总线联动',
      '#07101E',
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

  @Builder
  private buildTitleCard(): void {
    Column({ space: 8 }) {
      Text('后台任务与通知')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.panel_background'))
      Text('支持长时任务和通知机制，可在息屏或后台继续运行并报告进度。')
        .fontSize(13)
        .lineHeight(20)
        .fontColor($r('app.color.text_white_low'))
    }
    .width('100%')
    .padding(18)
    .linearGradient({
      angle: 140,
      colors: [['#1E3A8A', 0], ['#3B82F6', 1]]
    })
    .borderRadius(20)
    .shadow({ radius: 14, color: '#1A1E3A8A', offsetX: 0, offsetY: 8 })
  }

  private submitMockDownloadTask() {
    ngfSystem.submitTask('测试文件下载', async (taskId: string, updateCallback: (progress: number, total: number, message: string) => void) => {
      const totalSize = 100;
      let currentProgress = 0;
      updateCallback(0, totalSize, '准备下载...');
      
      for (let i = 0; i < 10; i++) {
        await this.delay(500);
        currentProgress += 10;
        updateCallback(currentProgress, totalSize, `正在下载 (${currentProgress}%)`);
      }
      updateCallback(totalSize, totalSize, '下载完成');
    }).then((taskId: string) => {
      const context = this.getUIContext().getHostContext();
      if (context) {
        this.getUIContext().getPromptAction().showToast({ message: `任务已提交: ${taskId}` });
      }
    }).catch((e: Error) => {
      const context = this.getUIContext().getHostContext();
      if (context) {
        this.getUIContext().getPromptAction().showToast({ message: `任务提交失败: ${e.message}` });
      }
    });
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  private getStateColor(state: string): ResourceColor {
    switch (state) {
      case NGFTaskState.RUNNING: return $r('app.color.tag_green');
      case NGFTaskState.COMPLETED: return $r('app.color.text_primary');
      case NGFTaskState.FAILED: return $r('app.color.tag_red');
      default: return $r('app.color.text_tertiary');
    }
  }
  private testBasicNotification() {
    const req = new NGFNotificationRequest(
      30001, '基础通知', '这是一条普通的基础文本通知', NGFNotificationType.BASIC
    );
    ngfSystem.publishNotification(req);
  }

  private testLongTextNotification() {
    const req = new NGFNotificationRequest(
      30002, '长文本通知', '这是简短摘要内容...', NGFNotificationType.LONG_TEXT
    );
    req.longText = '这是一段非常长的文本内容。它展示了如果通知内容较多时，系统通知栏是如何将其折叠和展开的。用户可以通过下拉手势查看更多详细信息，非常适合用于展示详细错误日志或说明。';
    ngfSystem.publishNotification(req);
  }

  private testMultiLineNotification() {
    const req = new NGFNotificationRequest(
      30003, '多行通知测试', '您有3条新消息', NGFNotificationType.MULTILINE
    );
    req.lines = ['消息1: 你好', '消息2: 请查看附件', '消息3: 会议时间改了'];
    ngfSystem.publishNotification(req);
  }

  private testCustomNotification() {
    const req = new NGFNotificationRequest(
      30004, '下载中', '测试自定义文件.zip', NGFNotificationType.CUSTOM
    );
    req.templateName = 'downloadTemplate';
    let data: Record<string, Object> = {
      'title': '正在下载(自定义)' as Object,
      'fileName': '测试自定义文件.zip' as Object,
      'progressValue': 60 as Object,
      'progressMaxValue': 100 as Object
    };
    req.templateData = data;
    ngfSystem.publishNotification(req);
  }
}

@Component
struct TaskListItem {
  @ObjectLink task: NGFTaskInfo;

  build() {
    Column({ space: 8 }) {
      Row() {
        Text(this.task.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text(this.task.state)
          .fontSize(12)
          .fontColor(this.getStateColor(this.task.state))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor($r('app.color.background_secondary'))
          .borderRadius(12)
      }
      .width('100%')

      Text(this.task.message)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))

      if (this.task.total > 0) {
        Progress({ value: this.task.progress, total: this.task.total, type: ProgressType.Linear })
          .width('100%')
          .color($r('app.color.button_primary'))
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(12)
    .border({ width: 1, color: $r('app.color.panel_border') })
    .shadow({ radius: 10, color: $r('app.color.card_shadow_demo'), offsetX: 0, offsetY: 4 })
  }

  private getStateColor(state: string): ResourceColor {
    switch (state) {
      case NGFTaskState.RUNNING: return $r('app.color.tag_green');
      case NGFTaskState.COMPLETED: return $r('app.color.text_primary');
      case NGFTaskState.FAILED: return $r('app.color.tag_red');
      default: return $r('app.color.text_tertiary');
    }
  }
}
