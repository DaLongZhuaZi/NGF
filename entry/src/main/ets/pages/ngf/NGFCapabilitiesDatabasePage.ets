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
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from 'ngf_framework';
import { NGFHdsTitleBarOptionsFactory } from 'ngf_framework';
import { NGFPageWindowSupport } from './NGFPageWindowSupport';
import { ngfRdbManager } from 'ngf_framework';

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
  @State private isDbInitialized: boolean = false;
  @State private tasks: Array<TaskRecord> = [];
  @State private inputText: string = '';
  @State private isProcessing: boolean = false;
  @StorageProp('ngf_visual_effects_should_use_system_material_surface') private useSysMat: boolean = true;

  async aboutToAppear(): Promise<void> {
    this.attachA11yBinding();
    await this.initDatabase();
  }

  aboutToDisappear(): void {
    this.detachA11yBinding();
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
      logger.error(TAG, 'DB init failed: ' + e);
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
      logger.info(TAG, '成功查询数据库，共查到 ' + String(rawResults.length) + ' 条记录');
      
      const newTasks: Array<TaskRecord> = [];
      for (let i: number = 0; i < rawResults.length; i++) {
        const row = rawResults[i];
        newTasks.push({
          id: Number(row['id'] ?? 0),
          content: String(row['content'] ?? ''),
          timestamp: Number(row['timestamp'] ?? 0)
        });
      }
      this.tasks = newTasks;
    } catch (e) {
      logger.error(TAG, 'Query tasks failed: ' + e);
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
      logger.info(TAG, '成功向数据库插入记录: "' + content + '"');
      this.inputText = '';
      await this.queryTasks();
    } catch (e) {
      logger.error(TAG, 'Add task failed: ' + e);
    } finally {
      this.isProcessing = false;
    }
  }

  private async handleDeleteTask(id: number): Promise<void> {
    if (!this.isDbInitialized) return;
    try {
      this.isProcessing = true;
      await ngfRdbManager.executeSql('DELETE FROM DemoTaskTable WHERE id = ?', [id]);
      logger.info(TAG, '成功删除数据库记录: ID=' + id);
      await this.queryTasks();
    } catch (e) {
      logger.error(TAG, 'Delete task failed: ' + e);
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
      logger.error(TAG, 'Clear all failed: ' + e);
    } finally {
      this.isProcessing = false;
    }
  }

  private formatTime(ts: number): string {
    const d = new Date(ts);
    const h = d.getHours().toString().padStart(2, '0');
    const m = d.getMinutes().toString().padStart(2, '0');
    const s = d.getSeconds().toString().padStart(2, '0');
    return h + ':' + m + ':' + s;
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
    Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
      Row() {
        Text($r('app.string.card_rdb_title'))
          .fontSize(this.a11yScale.font(20))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(20)))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Blank()
        if (this.isDbInitialized) {
          Text($r('app.string.db_connected'))
            .fontSize(this.a11yScale.font(12))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
            .fontColor($r('app.color.text_primary'))
            .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(8)
        } else {
          Text($r('app.string.db_disconnected'))
            .fontSize(this.a11yScale.font(12))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
            .fontColor($r('app.color.text_primary'))
            .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(8)
        }
      }
      .width('100%')
      
      Text($r('app.string.card_rdb_desc'))
        .fontSize(this.a11yScale.font(13))
        .lineHeight(this.a11yScale.explicitLineHeight(this.a11yScale.font(13), 20))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
    }
    .width('100%')
    .padding(18)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwareProminentBackgroundEffect(this.useSysMat))
    .borderRadius(NGFMaterialSurfaceTokens.PROMINENT_RADIUS)
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwareProminentShadow(this.useSysMat))
    .margin({ bottom: 16 })
  }

  @Builder
  private buildInputCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(12, 18) }) {
      TextInput({ placeholder: $r('app.string.db_input_placeholder'), text: this.inputText })
        .onChange((value: string) => {
          this.inputText = value;
        })
        .height(48)
        .width('100%')
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_tertiary'))
        .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
        .borderRadius(12)
        .onSubmit(() => {
          void this.handleAddTask();
        })

      Row({ space: 12 }) {
        Button($r('app.string.db_btn_insert'))
          .layoutWeight(1)
          .height(44)
          .fontSize(this.a11yScale.font(14))
          .borderRadius(12)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .enabled(this.isDbInitialized && this.inputText.trim().length > 0 && !this.isProcessing)
          .onClick(() => {
            void this.handleAddTask();
          })
          
        Button($r('app.string.db_btn_clear_all'))
          .layoutWeight(1)
          .height(44)
          .fontSize(this.a11yScale.font(14))
          .borderRadius(12)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .enabled(this.isDbInitialized && this.tasks.length > 0 && !this.isProcessing)
          .onClick(() => {
            void this.handleClearAll();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect(this.useSysMat))
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow(this.useSysMat))
    .margin({ bottom: 16 })
  }

  @Builder
  private buildDataList(): void {
    Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
      Row() {
        Text($r('app.string.db_records_title', this.tasks.length))
          .fontSize(this.a11yScale.font(14))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
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
          Text($r('app.string.db_no_records'))
            .fontSize(this.a11yScale.font(14))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
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
      Column({ space: this.a11yScale.paragraphSpacing(4, 18) }) {
        Text(task.content)
          .fontSize(this.a11yScale.font(15))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text($r('app.string.db_record_item', task.id, this.formatTime(task.timestamp)))
          .fontSize(this.a11yScale.font(12))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
          .fontColor($r('app.color.text_tertiary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Button($r('app.string.db_btn_delete'))
        .width(60)
        .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
        .controlSize(ControlSize.SMALL)
        .fontSize(this.a11yScale.font(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE))
        .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
        .fontColor('#EF4444')
        .borderRadius(8)
        .onClick(() => {
          void this.handleDeleteTask(task.id);
        })
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
  }
}
