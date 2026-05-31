import { logger } from '../../utils/Logger';

@Component
export struct NGFWorkflowVisualizer {
  @State workflows: Array<string> = [];
  @State selectedWorkflow: string = '';
  @State isExecuting: boolean = false;
  @State executionResult: string = '';

  aboutToAppear(): void {
    logger.info('NGFWorkflowVisualizer', '可视化调试器初始化');
    // 在真实场景下这里会调用 ngfWorkflowDefinitionManagerFacade.listWorkflowNames()
    // 此处简化为 UI 骨架
    this.workflows = ['example_workflow_1', 'example_parallel_workflow'];
  }

  build() {
    Column({ space: 16 }) {
      Text('Workflow Visual Debugger')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16 })

      List({ space: 8 }) {
        ForEach(this.workflows, (wfName: string) => {
          ListItem() {
            Row() {
              Text(wfName)
                .fontSize(16)
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

      Column({ space: 8 }) {
        Text('Execution Log:')
          .fontWeight(FontWeight.Bold)
        Scroll() {
          Text(this.executionResult)
            .fontSize(14)
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
    this.executionResult = `[${new Date().toISOString()}] Starting workflow: ${name}...\n`;
    
    // 模拟工作流执行过程，真实中通过 ngfWorkflowEngineFacade 调度
    setTimeout(() => {
      this.isExecuting = false;
      this.executionResult += `[${new Date().toISOString()}] Workflow ${name} COMPLETED successfully.`;
    }, 2000);
  }
}
