import { HdsNavDestination, hdsMaterial } from '@kit.UIDesignKit';
import { NGFHdsTitleBarOptionsFactory } from '../../Framework/NGF/uiShell/components/HdsNavigationSupport';
import { NGFImmersiveTopChromeUnderlay, NGFImmersiveTopChromePresetFactory } from '../../Framework/NGF/uiShell/components/NGFImmersiveTopChrome';
import { ngfSystem, NGFTaskInfo, NGFTaskState } from '../../Framework/NGF/systemTasks/index';
import { promptAction } from '@kit.ArkUI';

@Component
export struct NGFTaskManagerPage {
  @StorageProp('ngf_tasks_map') tasksMap: Map<string, NGFTaskInfo> = new Map();

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.Top }) {
        NGFImmersiveTopChromeUnderlay({
          spec: NGFImmersiveTopChromePresetFactory.build(
            '#07101E',
            '#0C2341',
            '#0A1626',
            '#3B82F6D8',
            '#22D3EED8',
            120,
            80
          )
        })

        Column({ space: 16 }) {
          Button('提交模拟下载任务', { type: ButtonType.Capsule })
            .width('100%')
            .height(48)
            .onClick(() => {
              this.submitMockDownloadTask();
            })

          List({ space: 12 }) {
            ForEach(Array.from(this.tasksMap.values()), (task: NGFTaskInfo) => {
              ListItem() {
                Column({ space: 8 }) {
                  Row() {
                    Text(task.name)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.text_primary'))
                      .layoutWeight(1)
                    Text(task.state)
                      .fontSize(12)
                      .fontColor(this.getStateColor(task.state))
                      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                      .backgroundColor($r('app.color.background_secondary'))
                      .borderRadius(12)
                  }
                  .width('100%')

                  Text(task.message)
                    .fontSize(14)
                    .fontColor($r('app.color.text_secondary'))

                  if (task.total > 0) {
                    Progress({ value: task.progress, total: task.total, type: ProgressType.Linear })
                      .width('100%')
                      .color($r('app.color.button_primary'))
                  }
                }
                .width('100%')
                .padding(16)
                .backgroundColor($r('app.color.panel_background'))
                .borderRadius(12)
                .border({ width: 1, color: $r('app.color.panel_border') })
              }
            }, (task: NGFTaskInfo) => task.taskId)
          }
          .width('100%')
          .height('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Auto)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 16, right: 16, top: 120, bottom: 24 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background_primary'))
    }
    .titleBar(NGFHdsTitleBarOptionsFactory.build(
      '后台任务与通知',
      '长时任务、通知与事件总线联动',
      $r('app.color.background_primary'),
      hdsMaterial.MaterialLevel.EXQUISITE,
      true,
      true
    ))
  }

  private submitMockDownloadTask() {
    ngfSystem.submitTask('测试文件下载', async (taskId: string, updateCallback: (progress: number, total: number, message: string) => void) => {
      const totalSize = 100;
      let currentProgress = 0;
      updateCallback(0, totalSize, '准备下载...');
      
      // 模拟下载过程，每隔 500ms 增加 10
      for (let i = 0; i < 10; i++) {
        await this.delay(500);
        currentProgress += 10;
        updateCallback(currentProgress, totalSize, `正在下载 (${currentProgress}%)`);
      }
      updateCallback(totalSize, totalSize, '下载完成');
    }).then((taskId: string) => {
      this.getUIContext().getPromptAction().showToast({ message: `任务已提交: ${taskId}` });
    }).catch((e: Error) => {
      this.getUIContext().getPromptAction().showToast({ message: `任务提交失败: ${e}` });
    });
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  private getStateColor(state: string): ResourceColor {
    switch (state) {
      case NGFTaskState.RUNNING: return $r('app.color.button_primary');
      case NGFTaskState.COMPLETED: return $r('app.color.text_primary');
      case NGFTaskState.FAILED: return $r('app.color.text_primary');
      default: return $r('app.color.text_tertiary');
    }
  }
}
