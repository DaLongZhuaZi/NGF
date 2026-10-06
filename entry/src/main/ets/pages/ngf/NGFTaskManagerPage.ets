import {
  NGFAccessibilityBindingListener,
  NGFAccessibilityLifecycleBinding,
  NGFA11yTextScale,
  NGFInclusiveDesignResolved,
  a11yTouchTarget,
  ngfAccessibilityFacade,
  resolveA11yTextScaleForCurrent
} from 'ngf_framework';
import { HdsNavDestination, hdsMaterial } from '@kit.UIDesignKit';
import { NGFHdsTitleBarOptionsFactory } from 'ngf_framework';
import {
  NGFImmersiveTopChromeUnderlay,
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec
} from 'ngf_framework';
import { ngfSystem, NGFTaskInfo, NGFTaskState } from 'ngf_framework';
import { NGFNotificationRequest, NGFNotificationType } from 'ngf_framework';
import { NGFControlStyleTokens } from 'ngf_framework';
import { NGFMaterialSurfaceTokens } from 'ngf_framework';
import { ngfOverlayManagerFacade } from 'ngf_framework';
import { ngfVisualEffectsFacade } from 'ngf_framework';
import { NGFPageWindowSupport } from './NGFPageWindowSupport';
import { resolveResourceString } from 'ngf_framework';

const DEMO_TOP_CHROME_BLUE: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#07101E', '#0C2341', '#0A1626', '#3B82F6D8', '#22D3EED8', 160, 88
);





@Component
export struct NGFTaskManagerPage {
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


  @StorageProp('ngf_visual_effects_should_use_system_material_surface') private useSysMat: boolean = true;
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private tasks: Array<NGFTaskInfo> = [];
  @State private topInsetVp: number = DEMO_TOP_CHROME_BLUE.metrics.contentTopInset;
  private readonly listenerId = 'NGFTaskManagerPage_Listener';

  aboutToAppear(): void {
    this.attachA11yBinding();
    NGFPageWindowSupport.loadDynamicTopInset(this.getUIContext(), 108, DEMO_TOP_CHROME_BLUE.metrics.contentTopInset, (inset) => {
      this.topInsetVp = inset;
    });
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
    this.detachA11yBinding();
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
          Column({ space: this.a11yScale.paragraphSpacing(16, 18) }) {
            this.buildTitleCard()
            
            Text($r('app.string.task_manager_test_queue'))
              .fontSize(this.a11yScale.font(14))
              .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 8, bottom: -8 })

            Button($r('app.string.task_manager_submit_download'), { type: ButtonType.Capsule })
              .width('100%')
              .height(NGFControlStyleTokens.NORMAL_BUTTON_HEIGHT)
              .controlSize(ControlSize.NORMAL)
              .fontSize(this.a11yScale.font(14))
              .fontColor($r('app.color.text_primary'))
.backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
              .onClick(() => {
                this.submitMockDownloadTask();
              })

            Text($r('app.string.task_manager_test_notify'))
              .fontSize(this.a11yScale.font(14))
              .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 8, bottom: -8 })

            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
              Button($r('app.string.task_manager_basic_notify'), { type: ButtonType.Normal })
                .borderRadius(8)
                .width('48%')
                .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
                .controlSize(ControlSize.SMALL)
                .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
                .fontColor($r('app.color.text_primary'))
.backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
                .margin({ bottom: 12 })
                .onClick(() => this.testBasicNotification())

              Button($r('app.string.task_manager_longtext_notify'), { type: ButtonType.Normal })
                .borderRadius(8)
                .width('48%')
                .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
                .controlSize(ControlSize.SMALL)
                .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
                .fontColor($r('app.color.text_primary'))
.backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
                .margin({ bottom: 12 })
                .onClick(() => this.testLongTextNotification())

              Button($r('app.string.task_manager_multiline_notify'), { type: ButtonType.Normal })
                .borderRadius(8)
                .width('48%')
                .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
                .controlSize(ControlSize.SMALL)
                .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
                .fontColor($r('app.color.text_primary'))
.backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
                .margin({ bottom: 12 })
                .onClick(() => this.testMultiLineNotification())

              Button($r('app.string.task_manager_custom_notify'), { type: ButtonType.Normal })
                .borderRadius(8)
                .width('48%')
                .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
                .controlSize(ControlSize.SMALL)
                .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
                .fontColor($r('app.color.text_primary'))
.backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
                .margin({ bottom: 12 })
                .onClick(() => this.testCustomNotification())
            }
            .width('100%')

            List({ space: 12 }) {
              ForEach(this.tasks, (task: NGFTaskInfo) => {
                ListItem() {
                  TaskListItem({ task: task, useSysMat: this.useSysMat })
                }
              }, (task: NGFTaskInfo) => task.taskId)
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Auto)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: this.topInsetVp, bottom: 36 })
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
      $r('app.string.task_manager_route_label'),
      $r('app.string.task_manager_titlebar_sub'),
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
    Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
      Text($r('app.string.task_manager_route_label'))
        .fontSize(this.a11yScale.font(22))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(22)))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text($r('app.string.task_manager_intro'))
        .fontSize(this.a11yScale.font(13))
        .lineHeight(this.a11yScale.explicitLineHeight(this.a11yScale.font(13), 20))
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(18)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwareProminentBackgroundEffect(this.useSysMat))
    .borderRadius(NGFMaterialSurfaceTokens.PROMINENT_RADIUS)
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwareProminentShadow(this.useSysMat))
  }

  private submitMockDownloadTask() {
    const hostCtx = this.getUIContext().getHostContext();
    ngfSystem.submitTask(
      resolveResourceString(hostCtx, $r('app.string.task_manager_test_file')),
      async (taskId: string, updateCallback: (progress: number, total: number, message: string) => void) => {
      const totalSize = 100;
      let currentProgress = 0;
      updateCallback(0, totalSize, resolveResourceString(hostCtx, $r('app.string.task_manager_preparing')));
      
      for (let i = 0; i < 10; i++) {
        await this.delay(500);
        currentProgress += 10;
        const baseText = resolveResourceString(hostCtx, $r('app.string.task_manager_downloading'));
        updateCallback(currentProgress, totalSize, baseText + ' (' + currentProgress + '%)');
      }
      updateCallback(totalSize, totalSize, resolveResourceString(hostCtx, $r('app.string.task_manager_done')));
    }).then((taskId: string) => {
      if (hostCtx) {
        const baseText = resolveResourceString(hostCtx, $r('app.string.task_manager_submitted'));
        ngfOverlayManagerFacade.showToast(baseText + ' ' + taskId);
      }
    }).catch((e: Error) => {
      if (hostCtx) {
        const baseText = resolveResourceString(hostCtx, $r('app.string.task_manager_submit_failed'));
        ngfOverlayManagerFacade.showToast(baseText + ' ' + e.message);
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
      30001,
      resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.task_manager_basic_notify')),
      resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.task_manager_basic_body')),
      NGFNotificationType.BASIC
    );
    ngfSystem.publishNotification(req);
  }

  private testLongTextNotification() {
    const req = new NGFNotificationRequest(
      30002,
      resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.task_manager_longtext_title')),
      resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.task_manager_longtext_summary')),
      NGFNotificationType.LONG_TEXT
    );
    req.longText = resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.task_manager_longtext_body'));
    ngfSystem.publishNotification(req);
  }

  private testMultiLineNotification() {
    const req = new NGFNotificationRequest(
      30003,
      resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.task_manager_multiline_title')),
      resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.task_manager_multiline_body')),
      NGFNotificationType.MULTILINE
    );
    req.lines = [
      resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.task_manager_msg1')),
      resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.task_manager_msg2')),
      resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.task_manager_msg3'))
    ];
    ngfSystem.publishNotification(req);
  }

  private testCustomNotification() {
    const req = new NGFNotificationRequest(
      30004,
      resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.task_manager_download_title')),
      resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.task_manager_download_file')),
      NGFNotificationType.CUSTOM
    );
    req.templateName = 'downloadTemplate';
    let data: Record<string, Object> = {
      'title': resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.task_manager_download_custom')) as Object,
      'fileName': resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.task_manager_download_file')) as Object,
      'progressValue': 60 as Object,
      'progressMaxValue': 100 as Object
    };
    req.templateData = data;
    ngfSystem.publishNotification(req);
  }
}

@Component
struct TaskListItem {
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


  @ObjectLink task: NGFTaskInfo;
  @Prop useSysMat: boolean = true;
  aboutToAppear(): void {
    this.attachA11yBinding();
  }

  aboutToDisappear(): void {
    this.detachA11yBinding();
  }



  build() {
    Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
      Row() {
        Text(this.task.name)
          .fontSize(this.a11yScale.font(16))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text(this.task.state)
          .fontSize(this.a11yScale.font(12))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
          .fontColor(this.getStateColor(this.task.state))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_secondary'), this.useSysMat))
          .borderRadius(12)
      }
      .width('100%')

      Text(this.task.message)
        .fontSize(this.a11yScale.font(14))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
        .fontColor($r('app.color.text_secondary'))

      if (this.task.total > 0) {
        Progress({ value: this.task.progress, total: this.task.total, type: ProgressType.Linear })
          .width('100%')
          .color($r('app.color.button_primary'))
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect(this.useSysMat))
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.panel_border'), this.useSysMat)
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow(this.useSysMat))
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
