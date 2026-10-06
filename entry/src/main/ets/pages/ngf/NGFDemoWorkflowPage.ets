import {
  NGFAccessibilityBindingListener,
  NGFAccessibilityLifecycleBinding,
  NGFA11yTextScale,
  NGFInclusiveDesignResolved,
  a11yTouchTarget,
  ngfAccessibilityFacade,
  resolveA11yTextScaleForCurrent
} from 'ngf_framework';
import { HdsNavDestination } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import { logger } from 'ngf_framework';
import { NGFControlStyleTokens } from 'ngf_framework';
import { NGFMaterialSurfaceTokens } from 'ngf_framework';
import { ngfVisualEffectsFacade } from 'ngf_framework';
import { resolveResourceString } from 'ngf_framework';
import {
  NGFWorkflowDefinition,
  NGFWorkflowStepDefinition,
  NGFWorkflowStepCondition,
  NGFWorkflowStepResult
} from 'ngf_framework';
import { ngfWorkflowDefinitionFacade } from 'ngf_framework';
import {
  NGFWorkflowPersistedState,
  ngfWorkflowPersistenceFacade
} from 'ngf_framework';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from 'ngf_framework';
import { NGFHdsTitleBarOptionsFactory } from 'ngf_framework';
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
  stepName: ResourceStr;
  actionType: ResourceStr;
  statusText: ResourceStr;
  statusColor: Resource;
  statusBg: Resource;

  constructor(id: number, stepName: ResourceStr, actionType: ResourceStr, statusText: ResourceStr, statusColor: Resource, statusBg: Resource) {
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


  @State private pathStack: NavPathStack = new NavPathStack();
  @State private topInsetVp: number = 108;
  @State private registeredName: string = '';
  @State private stepResults: Array<NGFDemoStepResultEntry> = [];
  @State private executionSuccess: boolean = false;
  @State private executionOutput: string = '';
  @State private savedStates: Array<NGFDemoSavedStateEntry> = [];
  @State private statusMessage: ResourceStr = '';
  @StorageProp('ngf_visual_effects_should_use_system_material_surface') private useSysMat: boolean = true;

  aboutToAppear(): void {
    this.attachA11yBinding();
    NGFPageWindowSupport.loadDynamicTopInset(this.getUIContext(), 108, 108, (inset) => {
      this.topInsetVp = inset;
    });
    NGFPageWindowSupport.apply(NGFPageWindowName.DEMO_WORKFLOW);
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: DEMO_WORKFLOW_TOP_CHROME })

        Scroll() {
          Column({ space: this.a11yScale.paragraphSpacing(12, 18) }) {
            this.buildTitleCard()
            this.buildDslSection()
            this.buildPersistenceSection()
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
      $r('app.string.ui_str_2051'),
      $r('app.string.ui_str_2315'),
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
    this.detachA11yBinding();
    NGFPageWindowSupport.restoreMainMenu();
  }

  @Builder
  private buildTitleCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
      Text($r('app.string.ui_str_2316'))
        .fontSize(this.a11yScale.font(22))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(22)))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text($r('app.string.ui_str_2317'))
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

  @Builder
  private buildDslSection(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Text($r('app.string.ui_str_2318'))
        .fontSize(this.a11yScale.font(16))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Text($r('app.string.ui_str_2319'))
        .fontSize(this.a11yScale.font(13))
        .lineHeight(this.a11yScale.explicitLineHeight(this.a11yScale.font(13), 19))
        .fontColor($r('app.color.text_tertiary'))

      Row({ space: 10 }) {
        Button($r('app.string.ui_str_2320'))
          .layoutWeight(1)
          .height(NGFControlStyleTokens.FORM_CONTROL_MIN_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.FORM_CONTROL_FONT_SIZE))
          .borderRadius(NGFControlStyleTokens.FORM_CONTROL_RADIUS)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            this.handleRegisterWorkflow();
          })
        Button($r('app.string.ui_str_2321'))
          .layoutWeight(1)
          .height(NGFControlStyleTokens.FORM_CONTROL_MIN_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.FORM_CONTROL_FONT_SIZE))
          .borderRadius(NGFControlStyleTokens.FORM_CONTROL_RADIUS)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            void this.handleExecuteWorkflow();
          })
      }
      .width('100%')

      if (this.registeredName.length > 0) {
        Text($r('app.string.ui_str_2322', this.registeredName))
          .fontSize(this.a11yScale.font(13))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
          .fontColor('#FF4F46E5')
          .fontWeight(FontWeight.Medium)
      }

      if (this.stepResults.length > 0) {
        Column({ space: this.a11yScale.paragraphSpacing(6, 18) }) {
          Text($r('app.string.ui_str_2325', this.executionSuccess ? $r('app.string.ui_str_2323') : $r('app.string.ui_str_2324')))
            .fontSize(this.a11yScale.font(14))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
            .fontWeight(FontWeight.Medium)
            .fontColor(this.executionSuccess ? $r('app.color.tag_green') : $r('app.color.tag_red'))

          ForEach(this.stepResults, (entry: NGFDemoStepResultEntry) => {
            Row() {
              Column({ space: this.a11yScale.paragraphSpacing(2, 18) }) {
                Text(entry.stepName)
                  .fontSize(this.a11yScale.font(13))
                  .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
                  .fontColor($r('app.color.text_body'))
                  .fontWeight(FontWeight.Medium)
                Text(entry.actionType)
                  .fontSize(this.a11yScale.font(11))
                  .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(11)))
                  .fontColor($r('app.color.text_muted'))
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text(entry.statusText)
                .fontSize(this.a11yScale.font(12))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
                .fontWeight(FontWeight.Medium)
                .fontColor(entry.statusColor)
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .backgroundColor(entry.statusBg)
                .borderRadius(8)
            }
            .width('100%')
            .padding({ top: 8, bottom: 8, left: 12, right: 12 })
            .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
            .borderRadius(10)
          }, (entry: NGFDemoStepResultEntry): string => 'step_' + entry.id)
        }
        .width('100%')
      }

      if (this.executionOutput.length > 0) {
        Column({ space: this.a11yScale.paragraphSpacing(4, 18) }) {
          Text($r('app.string.ui_str_2326'))
            .fontSize(this.a11yScale.font(12))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
            .fontColor($r('app.color.text_tertiary'))
          Text(this.executionOutput)
            .fontSize(this.a11yScale.font(11))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(11)))
            .fontColor($r('app.color.text_body'))
            .fontFamily('monospace')
            .maxLines(6)
            .width('100%')
            .padding(10)
            .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
            .borderRadius(10)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect(this.useSysMat))
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.card_border'), this.useSysMat)
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow(this.useSysMat))
  }

  @Builder
  private buildPersistenceSection(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Text($r('app.string.ui_str_2327'))
        .fontSize(this.a11yScale.font(16))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Row({ space: 8 }) {
        Button($r('app.string.ui_str_2328'))
          .layoutWeight(1)
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
          .borderRadius(10)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            this.handleSaveState();
          })
        Button($r('app.string.ui_str_2329'))
          .layoutWeight(1)
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
          .borderRadius(10)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            this.handleLoadState();
          })
        Button($r('app.string.ui_str_2330'))
          .layoutWeight(1)
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
          .borderRadius(10)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            this.handleListSaved();
          })
        Button($r('app.string.ui_str_2331'))
          .layoutWeight(1)
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
          .borderRadius(10)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            ngfWorkflowPersistenceFacade.clearAll();
            this.savedStates = [];
            this.statusMessage = $r('app.string.ui_str_2332');
          })
      }
      .width('100%')

      if ((typeof this.statusMessage === "string" ? this.statusMessage : '').length > 0) {
        Text(this.statusMessage)
          .fontSize(this.a11yScale.font(12))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
          .fontColor('#FF4F46E5')
          .width('100%')
      }

      if (this.savedStates.length > 0) {
        Column({ space: this.a11yScale.paragraphSpacing(4, 18) }) {
          ForEach(this.savedStates, (entry: NGFDemoSavedStateEntry) => {
            Row() {
              Text(entry.name)
                .fontSize(this.a11yScale.font(13))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
                .fontColor($r('app.color.text_body'))
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
              Text($r('app.string.ui_str_2333', entry.stepIndex))
                .fontSize(this.a11yScale.font(12))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
                .fontColor($r('app.color.text_tertiary'))
                .margin({ left: 8 })
              Text(entry.savedAtText)
                .fontSize(this.a11yScale.font(11))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(11)))
                .fontColor($r('app.color.text_muted'))
                .margin({ left: 8 })
            }
            .width('100%')
            .padding({ top: 6, bottom: 6, left: 10, right: 10 })
            .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
            .borderRadius(8)
          }, (entry: NGFDemoSavedStateEntry): string => 'saved_' + entry.id)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect(this.useSysMat))
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.card_border'), this.useSysMat)
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow(this.useSysMat))
  }

  private handleRegisterWorkflow(): void {
    const steps: Array<NGFWorkflowStepDefinition> = [];
    steps.push(new NGFWorkflowStepDefinition('数据获取', 'fetch', '{"url":"https://api.example.com/data"}'));
    steps.push(new NGFWorkflowStepDefinition(resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.ui_str_2334')), 'validate', '{"schema":"default"}'));
    steps.push(new NGFWorkflowStepDefinition(
      resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.ui_str_2335')),
      'transform',
      '{"mode":"enhanced"}',
      new NGFWorkflowStepCondition('validationPassed', 'equals', 'true')
    ));
    steps.push(new NGFWorkflowStepDefinition(resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.ui_str_2336')), 'cache', '{"ttl":300}'));

    const definition = new NGFWorkflowDefinition(
      'demo_workflow',
      resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.ui_str_2337')),
      steps
    );

    ngfWorkflowDefinitionFacade.registerWorkflow(definition);
    this.registeredName = definition.workflowName;
    this.statusMessage = $r('app.string.ui_str_2338', definition.workflowName, steps.length);
    logger.info(TAG, '注册工作流: name=' + definition.workflowName + ', steps=' + String(steps.length));
  }

  private async handleExecuteWorkflow(): Promise<void> {
    try {
      if (this.registeredName.length <= 0) {
        this.statusMessage = $r('app.string.ui_str_2339');
        return;
      }
      const contextJson = '{"userId":"demo_user","validationPassed":true}';
      const result = await ngfWorkflowDefinitionFacade.executeWorkflow(this.registeredName, contextJson);
      this.executionSuccess = result.success;
      this.executionOutput = result.outputJson;

      const stepEntries: Array<NGFDemoStepResultEntry> = [];
      for (let i = 0; i < result.stepResults.length; i++) {
        const step = result.stepResults[i];
        const statusText = step.skipped ? $r('app.string.ui_str_2340') : step.success ? $r('app.string.ui_str_2323') : $r('app.string.ui_str_2324');
        const statusColor = step.skipped ? $r('app.color.text_muted') : step.success ? $r('app.color.tag_green') : $r('app.color.tag_red');
        const statusBg = step.skipped ? $r('app.color.background_surface') : step.success ? $r('app.color.background_success') : $r('app.color.background_error');
        stepEntries.push(new NGFDemoStepResultEntry(i + 1, step.stepName, step.actionType, statusText, statusColor, statusBg));
      }
      this.stepResults = stepEntries;
      logger.info(TAG, '工作流执行完成: success=' + result.success + ', steps=' + String(stepEntries.length));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.statusMessage = $r('app.string.ui_str_2341', message);
    }
  }

  private handleSaveState(): void {
    if (this.registeredName.length <= 0) {
      this.statusMessage = $r('app.string.ui_str_2342');
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
    this.statusMessage = $r('app.string.ui_str_2343', this.registeredName);
    logger.info(TAG, '保存工作流状态: name=' + this.registeredName);
  }

  private handleLoadState(): void {
    if (this.registeredName.length <= 0) {
      this.statusMessage = $r('app.string.ui_str_2339');
      return;
    }
    const state = ngfWorkflowPersistenceFacade.loadState(this.registeredName);
    if (state !== null) {
      const date = new Date(state.savedAt);
      const timeText = String(this.pad2(date.getHours())) + ':' + String(this.pad2(date.getMinutes())) + ':' + String(this.pad2(date.getSeconds()));
      this.statusMessage = $r('app.string.ui_str_2344', state.currentStepIndex, timeText);
    } else {
      this.statusMessage = $r('app.string.ui_str_2345');
    }
  }

  private handleListSaved(): void {
    const names = ngfWorkflowPersistenceFacade.listSavedNames();
    const entries: Array<NGFDemoSavedStateEntry> = [];
    for (let i = 0; i < names.length; i++) {
      const state = ngfWorkflowPersistenceFacade.loadState(names[i]);
      if (state !== null) {
        const date = new Date(state.savedAt);
        const timeText = String(this.pad2(date.getHours())) + ':' + String(this.pad2(date.getMinutes())) + ':' + String(this.pad2(date.getSeconds()));
        entries.push(new NGFDemoSavedStateEntry(i + 1, names[i], state.currentStepIndex, timeText));
      }
    }
    this.savedStates = entries;
    this.statusMessage = $r('app.string.ui_str_2346', names.length);
  }

  private pad2(value: number): string {
    if (value >= 10) {
      return String(value);
    }
    return '0' + value;
  }
}
