import { HdsNavDestination } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import { logger } from '../../Framework/NGF/utils/Logger';
import {
  NGFWorkflowDefinition,
  NGFWorkflowStepDefinition,
  NGFWorkflowStepCondition,
  NGFWorkflowStepResult
} from '../../Framework/NGF/contentWorkflow/contracts/IWorkflowDefinition';
import { ngfWorkflowDefinitionFacade } from '../../Framework/NGF/contentWorkflow/index';
import {
  NGFWorkflowPersistedState,
  ngfWorkflowPersistenceFacade
} from '../../Framework/NGF/contentWorkflow/index';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from '../../Framework/NGF/uiShell/components/NGFImmersiveTopChrome';
import { NGFHdsTitleBarOptionsFactory } from '../../Framework/NGF/uiShell/components/HdsNavigationSupport';
import { NGFPageWindowName, NGFPageWindowSupport } from './NGFPageWindowSupport';

const TAG: string = 'NGFDemoWorkflowPage';

const DEMO_WORKFLOW_TOP_CHROME: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#0F0828',
  '#1E1145',
  '#0A0618',
  '#818CF8D8',
  '#C7D2FED8',
  160,
  88
);

class NGFDemoStepResultEntry {
  id: number;
  stepName: string;
  actionType: string;
  statusText: string;
  statusColor: Resource;
  statusBg: Resource;

  constructor(id: number, stepName: string, actionType: string, statusText: string, statusColor: Resource, statusBg: Resource) {
    this.id = id;
    this.stepName = stepName;
    this.actionType = actionType;
    this.statusText = statusText;
    this.statusColor = statusColor;
    this.statusBg = statusBg;
  }
}

class NGFDemoSavedStateEntry {
  id: number;
  name: string;
  stepIndex: number;
  savedAtText: string;

  constructor(id: number, name: string, stepIndex: number, savedAtText: string) {
    this.id = id;
    this.name = name;
    this.stepIndex = stepIndex;
    this.savedAtText = savedAtText;
  }
}

@Component
export struct NGFDemoWorkflowPage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private registeredName: string = '';
  @State private stepResults: Array<NGFDemoStepResultEntry> = [];
  @State private executionSuccess: boolean = false;
  @State private executionOutput: string = '';
  @State private savedStates: Array<NGFDemoSavedStateEntry> = [];
  @State private statusMessage: string = '';

  aboutToAppear(): void {
    NGFPageWindowSupport.apply(NGFPageWindowName.DEMO_WORKFLOW);
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: DEMO_WORKFLOW_TOP_CHROME })

        Scroll() {
          Column({ space: 12 }) {
            this.buildTitleCard()
            this.buildDslSection()
            this.buildPersistenceSection()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: DEMO_WORKFLOW_TOP_CHROME.metrics.contentTopInset, bottom: 36 })
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
      '流程编排',
      '工作流 DSL / 条件分支 / 状态持久化',
      '#0F0828',
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

  aboutToDisappear(): void {
    NGFPageWindowSupport.restoreMainMenu();
  }

  @Builder
  private buildTitleCard(): void {
    Column({ space: 8 }) {
      Text('流程编排演示')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.panel_background'))
      Text('WorkflowDefinition DSL 多步骤工作流 + 条件分支 / WorkflowPersistence 状态持久化')
        .fontSize(13)
        .lineHeight(20)
        .fontColor($r('app.color.text_white_low'))
    }
    .width('100%')
    .padding(18)
    .linearGradient({
      angle: 140,
      colors: [['#312E81', 0], ['#6366F1', 1]]
    })
    .borderRadius(20)
    .shadow({ radius: 14, color: '#1A312E81', offsetX: 0, offsetY: 8 })
  }

  @Builder
  private buildDslSection(): void {
    Column({ space: 10 }) {
      Text('工作流 DSL')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Text('注册一个包含 4 个步骤的示例工作流（含条件分支），然后执行它。')
        .fontSize(13)
        .lineHeight(19)
        .fontColor($r('app.color.text_tertiary'))

      Row({ space: 10 }) {
        Button('注册示例工作流')
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor('#FF4F46E5')
          .onClick((): void => {
            this.handleRegisterWorkflow();
          })
        Button('执行工作流')
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor($r('app.color.tag_purple'))
          .onClick((): void => {
            void this.handleExecuteWorkflow();
          })
      }
      .width('100%')

      if (this.registeredName.length > 0) {
        Text(`已注册: ${this.registeredName}`)
          .fontSize(13)
          .fontColor('#FF4F46E5')
          .fontWeight(FontWeight.Medium)
      }

      if (this.stepResults.length > 0) {
        Column({ space: 6 }) {
          Text(`执行结果: ${this.executionSuccess ? '成功' : '失败'}`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.executionSuccess ? $r('app.color.tag_green') : $r('app.color.tag_red'))

          ForEach(this.stepResults, (entry: NGFDemoStepResultEntry) => {
            Row() {
              Column({ space: 2 }) {
                Text(entry.stepName)
                  .fontSize(13)
                  .fontColor($r('app.color.text_body'))
                  .fontWeight(FontWeight.Medium)
                Text(entry.actionType)
                  .fontSize(11)
                  .fontColor($r('app.color.text_muted'))
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text(entry.statusText)
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor(entry.statusColor)
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .backgroundColor(entry.statusBg)
                .borderRadius(8)
            }
            .width('100%')
            .padding({ top: 8, bottom: 8, left: 12, right: 12 })
            .backgroundColor($r('app.color.background_surface'))
            .borderRadius(10)
          }, (entry: NGFDemoStepResultEntry): string => `step_${entry.id}`)
        }
        .width('100%')
      }

      if (this.executionOutput.length > 0) {
        Column({ space: 4 }) {
          Text('输出 JSON')
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
          Text(this.executionOutput)
            .fontSize(11)
            .fontColor($r('app.color.text_body'))
            .fontFamily('monospace')
            .maxLines(6)
            .width('100%')
            .padding(10)
            .backgroundColor($r('app.color.background_surface'))
            .borderRadius(10)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.card_border') })
    .shadow({ radius: 10, color: $r('app.color.card_shadow_demo'), offsetX: 0, offsetY: 4 })
  }

  @Builder
  private buildPersistenceSection(): void {
    Column({ space: 10 }) {
      Text('工作流持久化')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Row({ space: 8 }) {
        Button('保存状态')
          .layoutWeight(1)
          .height(36)
          .fontSize(13)
          .borderRadius(10)
          .backgroundColor($r('app.color.tag_green'))
          .onClick((): void => {
            this.handleSaveState();
          })
        Button('加载状态')
          .layoutWeight(1)
          .height(36)
          .fontSize(13)
          .borderRadius(10)
          .backgroundColor($r('app.color.button_primary'))
          .onClick((): void => {
            this.handleLoadState();
          })
        Button('列出已保存')
          .layoutWeight(1)
          .height(36)
          .fontSize(13)
          .borderRadius(10)
          .backgroundColor($r('app.color.tag_purple'))
          .onClick((): void => {
            this.handleListSaved();
          })
        Button('清除全部')
          .layoutWeight(1)
          .height(36)
          .fontSize(13)
          .borderRadius(10)
          .backgroundColor($r('app.color.tag_red'))
          .onClick((): void => {
            ngfWorkflowPersistenceFacade.clearAll();
            this.savedStates = [];
            this.statusMessage = '已清除所有保存的工作流状态';
          })
      }
      .width('100%')

      if (this.statusMessage.length > 0) {
        Text(this.statusMessage)
          .fontSize(12)
          .fontColor('#FF4F46E5')
          .width('100%')
      }

      if (this.savedStates.length > 0) {
        Column({ space: 4 }) {
          ForEach(this.savedStates, (entry: NGFDemoSavedStateEntry) => {
            Row() {
              Text(entry.name)
                .fontSize(13)
                .fontColor($r('app.color.text_body'))
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
              Text(`步骤 ${entry.stepIndex}`)
                .fontSize(12)
                .fontColor($r('app.color.text_tertiary'))
                .margin({ left: 8 })
              Text(entry.savedAtText)
                .fontSize(11)
                .fontColor($r('app.color.text_muted'))
                .margin({ left: 8 })
            }
            .width('100%')
            .padding({ top: 6, bottom: 6, left: 10, right: 10 })
            .backgroundColor($r('app.color.background_surface'))
            .borderRadius(8)
          }, (entry: NGFDemoSavedStateEntry): string => `saved_${entry.id}`)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.card_border') })
    .shadow({ radius: 10, color: $r('app.color.card_shadow_demo'), offsetX: 0, offsetY: 4 })
  }

  private handleRegisterWorkflow(): void {
    const steps: Array<NGFWorkflowStepDefinition> = [];
    steps.push(new NGFWorkflowStepDefinition('数据获取', 'fetch', '{"url":"https://api.example.com/data"}'));
    steps.push(new NGFWorkflowStepDefinition('数据校验', 'validate', '{"schema":"default"}'));
    steps.push(new NGFWorkflowStepDefinition(
      '条件处理',
      'transform',
      '{"mode":"enhanced"}',
      new NGFWorkflowStepCondition('validationPassed', 'equals', 'true')
    ));
    steps.push(new NGFWorkflowStepDefinition('结果缓存', 'cache', '{"ttl":300}'));

    const definition = new NGFWorkflowDefinition(
      'demo_workflow',
      '演示用多步骤工作流（含条件分支）',
      steps
    );

    ngfWorkflowDefinitionFacade.registerWorkflow(definition);
    this.registeredName = definition.workflowName;
    this.statusMessage = `已注册工作流: ${definition.workflowName}, 步骤数=${steps.length}`;
    logger.info(TAG, `注册工作流: name=${definition.workflowName}, steps=${steps.length}`);
  }

  private async handleExecuteWorkflow(): Promise<void> {
    try {
      if (this.registeredName.length <= 0) {
        this.statusMessage = '请先注册工作流';
        return;
      }
      const contextJson = '{"userId":"demo_user","validationPassed":true}';
      const result = await ngfWorkflowDefinitionFacade.executeWorkflow(this.registeredName, contextJson);
      this.executionSuccess = result.success;
      this.executionOutput = result.outputJson;

      const stepEntries: Array<NGFDemoStepResultEntry> = [];
      for (let i = 0; i < result.stepResults.length; i++) {
        const step = result.stepResults[i];
        const statusText = step.skipped ? '跳过' : step.success ? '成功' : '失败';
        const statusColor = step.skipped ? $r('app.color.text_muted') : step.success ? $r('app.color.tag_green') : $r('app.color.tag_red');
        const statusBg = step.skipped ? $r('app.color.background_surface') : step.success ? $r('app.color.background_success') : $r('app.color.background_error');
        stepEntries.push(new NGFDemoStepResultEntry(i + 1, step.stepName, step.actionType, statusText, statusColor, statusBg));
      }
      this.stepResults = stepEntries;
      logger.info(TAG, `工作流执行完成: success=${result.success}, steps=${stepEntries.length}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.statusMessage = `执行异常: ${message}`;
    }
  }

  private handleSaveState(): void {
    if (this.registeredName.length <= 0) {
      this.statusMessage = '请先注册并执行工作流';
      return;
    }
    const state = new NGFWorkflowPersistedState(
      this.registeredName,
      2,
      '{"userId":"demo_user","step2Output":"cached"}',
      '{"steps":[]}',
      Date.now()
    );
    ngfWorkflowPersistenceFacade.saveState(state);
    this.statusMessage = `已保存工作流状态: ${this.registeredName}`;
    logger.info(TAG, `保存工作流状态: name=${this.registeredName}`);
  }

  private handleLoadState(): void {
    if (this.registeredName.length <= 0) {
      this.statusMessage = '请先注册工作流';
      return;
    }
    const state = ngfWorkflowPersistenceFacade.loadState(this.registeredName);
    if (state !== null) {
      const date = new Date(state.savedAt);
      const timeText = `${this.pad2(date.getHours())}:${this.pad2(date.getMinutes())}:${this.pad2(date.getSeconds())}`;
      this.statusMessage = `已加载: stepIndex=${state.currentStepIndex}, savedAt=${timeText}`;
    } else {
      this.statusMessage = '未找到已保存的状态';
    }
  }

  private handleListSaved(): void {
    const names = ngfWorkflowPersistenceFacade.listSavedNames();
    const entries: Array<NGFDemoSavedStateEntry> = [];
    for (let i = 0; i < names.length; i++) {
      const state = ngfWorkflowPersistenceFacade.loadState(names[i]);
      if (state !== null) {
        const date = new Date(state.savedAt);
        const timeText = `${this.pad2(date.getHours())}:${this.pad2(date.getMinutes())}:${this.pad2(date.getSeconds())}`;
        entries.push(new NGFDemoSavedStateEntry(i + 1, names[i], state.currentStepIndex, timeText));
      }
    }
    this.savedStates = entries;
    this.statusMessage = `已保存的工作流: ${names.length} 个`;
  }

  private pad2(value: number): string {
    if (value >= 10) {
      return `${value}`;
    }
    return `0${value}`;
  }
}
