import { HdsNavDestination } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import { logger } from '../../Framework/NGF/utils/Logger';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from '../../Framework/NGF/uiShell/components/NGFImmersiveTopChrome';
import { NGFHdsTitleBarOptionsFactory } from '../../Framework/NGF/uiShell/components/HdsNavigationSupport';
import { NGFPageWindowSupport } from './NGFPageWindowSupport';
import { ngfRdbManager } from '../../Framework/NGF/index';

const TAG: string = 'NGFCapabilitiesDatabasePage';

const DEMO_TOP_CHROME: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#1A0F08', '#3D2508', '#1A1005', '#F59E0BD8', '#FCD34DD8', 160, 88
);

export interface TaskRecord {
  id: number;
  content: string;
  timestamp: number;
}

@Component
export struct NGFCapabilitiesDatabasePage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private topInsetVp: number = 108;
  @State private isDbInitialized: boolean = false;
  @State private tasks: Array<TaskRecord> = [];
  @State private inputText: string = '';
  @State private isProcessing: boolean = false;

  async aboutToAppear(): Promise<void> {
    await this.initDatabase();
  }

  aboutToDisappear(): void {
    NGFPageWindowSupport.restoreMainMenu();
  }

  private async initDatabase(): Promise<void> {
    try {
      this.isProcessing = true;
      // 初始化数据库表
      const initSuccess = await ngfRdbManager.init({ name: 'NGFCapabilityDemo.db', securityLevel: 1 }, [
        'CREATE TABLE IF NOT EXISTS DemoTaskTable (id INTEGER PRIMARY KEY AUTOINCREMENT, content TEXT, timestamp INTEGER)'
      ]);
      if (!initSuccess) {
        throw new Error('ngfRdbManager.init 返回了 false');
      }
      this.isDbInitialized = true;
      await this.queryTasks();
    } catch (e) {
      logger.error(TAG, `DB init failed: ${e}`);
      this.isDbInitialized = false;
    } finally {
      this.isProcessing = false;
    }
  }

  private async queryTasks(): Promise<void> {
    if (!this.isDbInitialized) return;
    try {
      this.isProcessing = true;
      const rawResults = await ngfRdbManager.querySql('SELECT * FROM DemoTaskTable ORDER BY timestamp DESC');
      logger.info(TAG, `成功查询数据库，共查到 ${rawResults.length} 条记录`);
      
      const newTasks: Array<TaskRecord> = [];
      for (const row of rawResults) {
        newTasks.push({
          id: Number(row['id'] ?? 0),
          content: String(row['content'] ?? ''),
          timestamp: Number(row['timestamp'] ?? 0)
        });
      }
      this.tasks = newTasks;
    } catch (e) {
      logger.error(TAG, `Query tasks failed: ${e}`);
    } finally {
      this.isProcessing = false;
    }
  }

  private async handleAddTask(): Promise<void> {
    if (!this.inputText.trim() || !this.isDbInitialized) return;
    try {
      this.isProcessing = true;
      const content = this.inputText.trim();
      const ts = Date.now();
      await ngfRdbManager.executeSql('INSERT INTO DemoTaskTable (content, timestamp) VALUES (?, ?)', [content, ts]);
      logger.info(TAG, `成功向数据库插入记录: "${content}"`);
      this.inputText = '';
      await this.queryTasks();
    } catch (e) {
      logger.error(TAG, `Add task failed: ${e}`);
    } finally {
      this.isProcessing = false;
    }
  }

  private async handleDeleteTask(id: number): Promise<void> {
    if (!this.isDbInitialized) return;
    try {
      this.isProcessing = true;
      await ngfRdbManager.executeSql('DELETE FROM DemoTaskTable WHERE id = ?', [id]);
      logger.info(TAG, `成功删除数据库记录: ID=${id}`);
      await this.queryTasks();
    } catch (e) {
      logger.error(TAG, `Delete task failed: ${e}`);
    } finally {
      this.isProcessing = false;
    }
  }

  private async handleClearAll(): Promise<void> {
    if (!this.isDbInitialized) return;
    try {
      this.isProcessing = true;
      await ngfRdbManager.executeSql('DELETE FROM DemoTaskTable');
      logger.info(TAG, '成功清空数据库所有记录');
      await this.queryTasks();
    } catch (e) {
      logger.error(TAG, `Clear all failed: ${e}`);
    } finally {
      this.isProcessing = false;
    }
  }

  private formatTime(ts: number): string {
    const d = new Date(ts);
    const h = d.getHours().toString().padStart(2, '0');
    const m = d.getMinutes().toString().padStart(2, '0');
    const s = d.getSeconds().toString().padStart(2, '0');
    return `${h}:${m}:${s}`;
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: DEMO_TOP_CHROME })

        Column() {
          // Status Header
          this.buildTitleCard()

          // Input Section
          this.buildInputCard()

          // Data List Section
          this.buildDataList()
        }
        .width('100%')
        .height('100%')
        .padding({ left: 16, right: 16, top: this.topInsetVp, bottom: 36 })
      }
      .width('100%')
      .height('100%')
    }
    .titleBar(NGFHdsTitleBarOptionsFactory.build(
      $r('app.string.card_rdb_title'),
      $r('app.string.card_rdb_desc'),
      '#1A0F08',
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
      Row() {
        Text($r('app.string.card_rdb_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.panel_background'))
        Blank()
        if (this.isDbInitialized) {
          Text('已连接')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#34D399')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(8)
        } else {
          Text('未连接')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#EF4444')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(8)
        }
      }
      .width('100%')
      
      Text($r('app.string.card_rdb_desc'))
        .fontSize(13)
        .lineHeight(20)
        .fontColor($r('app.color.text_white_low'))
        .width('100%')
    }
    .width('100%')
    .padding(18)
    .linearGradient({
      angle: 140,
      colors: [['#78350F', 0], ['#F59E0B', 1]]
    })
    .borderRadius(20)
    .shadow({ radius: 14, color: '#1A78350F', offsetX: 0, offsetY: 8 })
    .margin({ bottom: 16 })
  }

  @Builder
  private buildInputCard(): void {
    Column({ space: 12 }) {
      TextInput({ placeholder: '输入新的记录内容...', text: this.inputText })
        .onChange((value: string) => {
          this.inputText = value;
        })
        .height(48)
        .width('100%')
        .backgroundColor($r('app.color.background_surface'))
        .onSubmit(() => {
          void this.handleAddTask();
        })

      Row({ space: 12 }) {
        Button('插入记录')
          .layoutWeight(1)
          .height(44)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor('#F59E0B')
          .enabled(this.isDbInitialized && this.inputText.trim().length > 0 && !this.isProcessing)
          .onClick(() => {
            void this.handleAddTask();
          })
          
        Button('清空全部')
          .layoutWeight(1)
          .height(44)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor('#EF4444')
          .enabled(this.isDbInitialized && this.tasks.length > 0 && !this.isProcessing)
          .onClick(() => {
            void this.handleClearAll();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .shadow({ radius: 10, color: $r('app.color.card_shadow_demo'), offsetX: 0, offsetY: 4 })
    .margin({ bottom: 16 })
  }

  @Builder
  private buildDataList(): void {
    Column({ space: 8 }) {
      Row() {
        Text(`数据库记录 (${this.tasks.length})`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_secondary'))
        Blank()
        if (this.isProcessing) {
          LoadingProgress().width(16).height(16).color($r('app.color.text_secondary'))
        }
      }
      .width('100%')
      .padding({ left: 4, right: 4 })

      if (this.tasks.length === 0) {
        Column() {
          Text('暂无记录')
            .fontSize(14)
            .fontColor($r('app.color.text_tertiary'))
        }
        .width('100%')
        .height(100)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.tasks, (task: TaskRecord) => {
            ListItem() {
              this.buildTaskItem(task)
            }
          }, (task: TaskRecord) => task.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  private buildTaskItem(task: TaskRecord): void {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text(task.content)
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`ID: ${task.id} · 创建于 ${this.formatTime(task.timestamp)}`)
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Button('删除')
        .width(60)
        .height(32)
        .fontSize(12)
        .backgroundColor($r('app.color.background_surface'))
        .fontColor('#EF4444')
        .borderRadius(8)
        .onClick(() => {
          void this.handleDeleteTask(task.id);
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(12)
    .border({ width: 1, color: $r('app.color.card_border') })
  }
}
