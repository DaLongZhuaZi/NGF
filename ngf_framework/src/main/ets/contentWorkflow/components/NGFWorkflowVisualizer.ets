import {
  NGFAccessibilityBindingListener,
  NGFAccessibilityLifecycleBinding
} from '../../uiShell/utils/NGFAccessibilityLifecycleBinding';
import { NGFInclusiveDesignResolved } from '../../deviceAwareness/contracts/IAccessibilityManager';
import { NGFA11yTextScale, resolveA11yTextScale, resolveA11yTextScaleForCurrent } from '../../uiShell/utils/NGFA11yTextScale';
import { ngfAccessibilityFacade } from '../../deviceAwareness/facades/AccessibilityFacade';
import { logger } from '../../utils/Logger';

@Component
export struct NGFWorkflowVisualizer {
  /** 适老呈现层：字号经缩放器取；普通档原样返回（零视觉回归） */
  @State private a11yScale: NGFA11yTextScale = resolveA11yTextScaleForCurrent();
  private a11yBinding: NGFAccessibilityLifecycleBinding | null = null;

  /** 订阅平台适老策略；与 detach 成对（SDK 硬性要求） */
  private attachA11yBinding(): void {
    if (this.a11yBinding === null) {
      const listener: NGFAccessibilityBindingListener = {
        onInclusiveDesignChanged: (resolved: NGFInclusiveDesignResolved): void => {
          this.a11yScale = resolveA11yTextScaleForCurrent();
        }
      };
      this.a11yBinding = new NGFAccessibilityLifecycleBinding(listener);
      this.a11yBinding.attach();
    }
  }

  @State workflows: Array<string> = [];
  @State selectedWorkflow: string = '';
  @State isExecuting: boolean = false;
  @State executionResult: string = '';

  aboutToAppear(): void {
    this.attachA11yBinding();
    logger.info('NGFWorkflowVisualizer', '可视化调试器初始化');
    // 在真实场景下这里会调用 ngfWorkflowDefinitionManagerFacade.listWorkflowNames()
    // 此处简化为 UI 骨架
    this.workflows = ['example_workflow_1', 'example_parallel_workflow'];
  }

  aboutToDisappear(): void {
    const binding: NGFAccessibilityLifecycleBinding | null = this.a11yBinding;
    if (binding !== null) {
      binding.detach();
      this.a11yBinding = null;
    }
  }

  build() {
    Column({ space: this.a11yScale.groupSpacing(16) }) {
      Text('Workflow Visual Debugger')
        .fontSize(this.a11yScale.font(24))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(24)))
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16 })

      List({ space: 8 }) {
        ForEach(this.workflows, (wfName: string) => {
          ListItem() {
            Row() {
              Text(wfName)
                .fontSize(this.a11yScale.font(16))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
                .fontColor(this.selectedWorkflow === wfName ? Color.Blue : Color.Black)
              Blank()
              Button('Run')
                .onClick(() => {
                  this.selectedWorkflow = wfName;
                  this.runWorkflow(wfName);
                })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
          }
        }, (item: string) => item)
      }
      .width('100%')
      .layoutWeight(1)

      Divider()

      Column({ space: this.a11yScale.groupSpacing(8) }) {
        Text('Execution Log:')
          .fontWeight(FontWeight.Bold)
        Scroll() {
          Text(this.executionResult)
            .fontSize(this.a11yScale.font(14))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
            .fontFamily('monospace')
            .fontColor(this.isExecuting ? Color.Orange : (this.executionResult.includes('FAILED') ? Color.Red : Color.Green))
        }
        .width('100%')
        .height(150)
        .backgroundColor('#1E1E1E')
        .padding(8)
        .borderRadius(8)
      }
      .width('100%')
      .padding({ bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }

  private runWorkflow(name: string): void {
    this.isExecuting = true;
    this.executionResult = '[' + String(new Date().toISOString()) + '] Starting workflow: ' + name + '...\\n';
    
    // 模拟工作流执行过程，真实中通过 ngfWorkflowEngineFacade 调度
    setTimeout(() => {
      this.isExecuting = false;
      this.executionResult += '[' + String(new Date().toISOString()) + '] Workflow ' + name + ' COMPLETED successfully.';
    }, 2000);
  }
}
