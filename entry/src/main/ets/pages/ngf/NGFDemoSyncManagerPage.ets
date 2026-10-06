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
  NGFConflictStrategy,
  NGFSyncOperation,
  NGFSyncQueueItem,
  NGFSyncResult
} from 'ngf_framework';
import { ISyncDataHandler } from 'ngf_framework';
import { ngfSyncManagerFacade } from 'ngf_framework';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from 'ngf_framework';
import { NGFHdsTitleBarOptionsFactory } from 'ngf_framework';
import { NGFPageWindowName, NGFPageWindowSupport } from './NGFPageWindowSupport';

const TAG: string = 'NGFDemoSyncManagerPage';

const DEMO_TOP_CHROME: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#0A0F1A', '#142040', '#08101E', '#3B82F6D8', '#93C5FDD8', 160, 88
);

class NGFSyncQueueDisplay {
  id: number;
  entityName: string;
  operation: string;
  payload: string;
  retryCount: number;

  constructor(id: number, entityName: string, operation: string, payload: string, retryCount: number) {
    this.id = id;
    this.entityName = entityName;
    this.operation = operation;
    this.payload = payload;
    this.retryCount = retryCount;
  }
}

class NGFSyncResultDisplay {
  success: boolean;
  syncedCount: number;
  failedCount: number;
  conflictCount: number;

  constructor(success: boolean, syncedCount: number, failedCount: number, conflictCount: number) {
    this.success = success;
    this.syncedCount = syncedCount;
    this.failedCount = failedCount;
    this.conflictCount = conflictCount;
  }
}

// 模拟远程同步处理器 — 随机成功/失败模拟网络波动
class DemoSyncHandler implements ISyncDataHandler {
  private networkOnline: boolean;

  constructor(networkOnline: boolean) {
    this.networkOnline = networkOnline;
  }

  async push(item: NGFSyncQueueItem): Promise<boolean> {
    if (!this.networkOnline) {
      return false;
    }
    // 模拟异步网络请求
    await new Promise<void>((resolve: () => void) => {
      setTimeout(resolve, 20);
    });
    logger.debug(TAG, '远程推送: entity=' + item.entityName + ', op=' + item.operation);
    return true;
  }

  async pull(_entityName: string, _sinceTimestamp: number): Promise<string> {
    return '{"remoteVersion":2,"data":"server_payload"}';
  }

  async resolveConflict(
    _local: NGFSyncQueueItem,
    _remote: string,
    strategy: NGFConflictStrategy
  ): Promise<string> {
    return strategy === NGFConflictStrategy.CLIENT_WINS ? _local.payload : _remote;
  }

  setOnline(online: boolean): void {
    this.networkOnline = online;
  }
}

@Component
export struct NGFDemoSyncManagerPage {
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
  @State private isOnline: boolean = false;
  @State private conflictStrategy: NGFConflictStrategy = NGFConflictStrategy.CLIENT_WINS;
  @State private queueItems: Array<NGFSyncQueueDisplay> = [];
  @State private queueSize: number = 0;
  @State private lastResult: NGFSyncResultDisplay | null = null;
  @State private statusMessage: ResourceStr = '';
  @StorageProp('ngf_visual_effects_should_use_system_material_surface') private useSysMat: boolean = true;
  private handler: DemoSyncHandler = new DemoSyncHandler(false);
  private nextItemId: number = 1;

  aboutToAppear(): void {
    this.attachA11yBinding();
    NGFPageWindowSupport.loadDynamicTopInset(this.getUIContext(), 108, 108, (inset) => {
      this.topInsetVp = inset;
    });
    NGFPageWindowSupport.apply(NGFPageWindowName.DEMO_WORKFLOW);
    ngfSyncManagerFacade.setSyncHandler(this.handler);
    ngfSyncManagerFacade.setConflictStrategy(this.conflictStrategy);
    this.refreshQueueDisplay();
  }

  aboutToDisappear(): void {
    this.detachA11yBinding();
    NGFPageWindowSupport.restoreMainMenu();
  }

  private refreshQueueDisplay(): void {
    this.queueSize = ngfSyncManagerFacade.queueSize();
  }

  private handleToggleNetwork(): void {
    this.isOnline = !this.isOnline;
    this.handler.setOnline(this.isOnline);
    this.statusMessage = this.isOnline
      ? $r('app.string.sync_network_on')
      : $r('app.string.sync_network_off');
    logger.info(TAG, '模拟网络状态: online=' + this.isOnline);
  }

  private handleEnqueue(op: NGFSyncOperation): void {
    const id = 'item_' + this.nextItemId;
    this.nextItemId++;
    const item = new NGFSyncQueueItem(
      id,
      'UserProfile',
      'user_' + this.nextItemId,
      op,
      '{"name":"User' + this.nextItemId + '","ts":' + String(Date.now()) + '}',
      Date.now()
    );
    ngfSyncManagerFacade.enqueue(item);
    this.refreshQueueDisplay();

    const display = new NGFSyncQueueDisplay(
      this.nextItemId,
      item.entityName,
      op,
      item.payload.substring(0, 40),
      0
    );
    const next: Array<NGFSyncQueueDisplay> = [display];
    for (let i = 0; i < this.queueItems.length && i < 4; i++) {
      next.push(this.queueItems[i]);
    }
    this.queueItems = next;
    this.statusMessage = $r('app.string.sync_enqueued', id);
    logger.info(TAG, '入队: id=' + id + ', op=' + op);
  }

  private async handleFlush(): Promise<void> {
    this.statusMessage = $r('app.string.sync_flushing');
    const result: NGFSyncResult = await ngfSyncManagerFacade.flush();
    this.lastResult = new NGFSyncResultDisplay(
      result.success,
      result.syncedCount,
      result.failedCount,
      result.conflicts.length
    );
    this.refreshQueueDisplay();
    this.statusMessage = result.success
      ? $r('app.string.sync_flush_success', result.syncedCount)
      : $r('app.string.sync_flush_partial', result.syncedCount, result.failedCount);
    logger.info(TAG, '同步完成: synced=' + result.syncedCount + ', failed=' + result.failedCount);
  }

  private handleClearQueue(): void {
    ngfSyncManagerFacade.clearQueue();
    this.queueItems = [];
    this.refreshQueueDisplay();
    this.statusMessage = $r('app.string.sync_queue_cleared');
  }

  private handleSetStrategy(strategy: NGFConflictStrategy): void {
    this.conflictStrategy = strategy;
    ngfSyncManagerFacade.setConflictStrategy(strategy);
    this.statusMessage = $r('app.string.sync_strategy_set', strategy);
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: DEMO_TOP_CHROME })

        Scroll() {
          Column({ space: this.a11yScale.paragraphSpacing(12, 18) }) {
            this.buildTitleCard()
            this.buildNetworkCard()
            this.buildQueueCard()
            this.buildStrategyCard()
            this.buildResultCard()
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
      $r('app.string.demo_sync_title'),
      $r('app.string.demo_sync_desc'),
      '#0A0F1A',
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
      Text($r('app.string.demo_sync_title'))
        .fontSize(this.a11yScale.font(22))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(22)))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text($r('app.string.demo_sync_desc'))
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
  private buildNetworkCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Row({ space: 10 }) {
        Column({ space: this.a11yScale.paragraphSpacing(4, 18) }) {
          Text($r('app.string.sync_network_label'))
            .fontSize(this.a11yScale.font(16))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_body'))
          Text(this.isOnline ? $r('app.string.sync_online') : $r('app.string.sync_offline'))
            .fontSize(this.a11yScale.font(13))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
            .fontColor(this.isOnline ? $r('app.color.tag_green') : $r('app.color.tag_red'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button(this.isOnline ? $r('app.string.sync_go_offline') : $r('app.string.sync_go_online'))
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
          .fontColor($r('app.color.text_primary'))
          .borderRadius(10)
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            this.handleToggleNetwork();
          })
      }
      .width('100%')

      if ((typeof this.statusMessage === 'string' ? this.statusMessage : '').length > 0) {
        Row({ space: 6 }) {
          // 装饰图标：状态说明文字在右侧，图标不应单独成为焦点
          // 装饰图标：旁边已有文字，避免冗余播报
          SymbolGlyph($r('sys.symbol.info_circle'))
            .fontSize(this.a11yScale.font(12))
            .fontColor([$r('app.color.text_muted')])
            .accessibilityLevel('no')
            .accessibilityLevel('no')
          Text(this.statusMessage)
            .fontSize(this.a11yScale.font(12))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
            .fontColor($r('app.color.text_muted'))
            .layoutWeight(1)
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

  @Builder
  private buildQueueCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Row({ space: 8 }) {
        Text($r('app.string.sync_queue_label'))
          .fontSize(this.a11yScale.font(16))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_body'))
          .layoutWeight(1)
        Text(String(this.queueSize))
          .fontSize(this.a11yScale.font(18))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(18)))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')

      Text($r('app.string.sync_queue_hint'))
        .fontSize(this.a11yScale.font(12))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
        .fontColor($r('app.color.text_tertiary'))

      Row({ space: 8 }) {
        Button() {
          Row({ space: 4 }) {
            // 装饰图标：旁边已有文字，避免冗余播报
            SymbolGlyph($r('sys.symbol.plus'))
              .fontSize(this.a11yScale.font(14))
              .fontColor([$r('app.color.text_primary')])
              .accessibilityLevel('no')
            Text($r('app.string.sync_enqueue_create'))
              .fontSize(this.a11yScale.font(12))
              .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
              .fontColor($r('app.color.text_primary'))
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
        .layoutWeight(1)
        .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
        .controlSize(ControlSize.SMALL)
        .borderRadius(10)
        .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
        .onClick((): void => {
          this.handleEnqueue(NGFSyncOperation.CREATE);
        })

        Button() {
          Row({ space: 4 }) {
            // 装饰图标：旁边已有文字，避免冗余播报
            SymbolGlyph($r('sys.symbol.square_and_pencil'))
              .fontSize(this.a11yScale.font(14))
              .fontColor([$r('app.color.text_primary')])
              .accessibilityLevel('no')
            Text($r('app.string.sync_enqueue_update'))
              .fontSize(this.a11yScale.font(12))
              .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
              .fontColor($r('app.color.text_primary'))
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
        .layoutWeight(1)
        .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
        .controlSize(ControlSize.SMALL)
        .borderRadius(10)
        .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
        .onClick((): void => {
          this.handleEnqueue(NGFSyncOperation.UPDATE);
        })

        Button() {
          Row({ space: 4 }) {
            // 装饰图标：旁边已有文字，避免冗余播报
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(this.a11yScale.font(14))
              .fontColor([$r('app.color.text_primary')])
              .accessibilityLevel('no')
            Text($r('app.string.sync_enqueue_delete'))
              .fontSize(this.a11yScale.font(12))
              .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
              .fontColor($r('app.color.text_primary'))
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
        .layoutWeight(1)
        .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
        .controlSize(ControlSize.SMALL)
        .borderRadius(10)
        .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
        .onClick((): void => {
          this.handleEnqueue(NGFSyncOperation.DELETE);
        })
      }
      .width('100%')

      Row({ space: 8 }) {
        Button($r('app.string.sync_flush_btn'))
          .layoutWeight(2)
          .height(NGFControlStyleTokens.FORM_CONTROL_MIN_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.FORM_CONTROL_FONT_SIZE))
          .fontColor($r('app.color.text_primary'))
          .borderRadius(NGFControlStyleTokens.FORM_CONTROL_RADIUS)
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            void this.handleFlush();
          })

        Button($r('app.string.sync_clear_btn'))
          .layoutWeight(1)
          .height(NGFControlStyleTokens.FORM_CONTROL_MIN_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.FORM_CONTROL_FONT_SIZE))
          .borderRadius(NGFControlStyleTokens.FORM_CONTROL_RADIUS)
          .fontColor($r('app.color.text_body'))
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            this.handleClearQueue();
          })
      }
      .width('100%')

      if (this.queueItems.length > 0) {
        Column({ space: this.a11yScale.paragraphSpacing(4, 18) }) {
          ForEach(this.queueItems, (item: NGFSyncQueueDisplay) => {
            Row({ space: 8 }) {
              Text(item.operation)
                .fontSize(this.a11yScale.font(11))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(11)))
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
                .borderRadius(4)

              Text(item.payload)
                .fontSize(this.a11yScale.font(11))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(11)))
                .fontColor($r('app.color.text_muted'))
                .maxLines(1)
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ top: 5, bottom: 5, left: 10, right: 10 })
            .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
            .borderRadius(8)
          }, (item: NGFSyncQueueDisplay): string => 'q_' + item.id)
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

  @Builder
  private buildStrategyCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Text($r('app.string.sync_strategy_label'))
        .fontSize(this.a11yScale.font(16))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Row({ space: 8 }) {
        this.buildStrategyButton(NGFConflictStrategy.CLIENT_WINS, $r('app.string.sync_client_wins'))
        this.buildStrategyButton(NGFConflictStrategy.SERVER_WINS, $r('app.string.sync_server_wins'))
        this.buildStrategyButton(NGFConflictStrategy.MANUAL, $r('app.string.sync_manual'))
      }
      .width('100%')
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
  private buildStrategyButton(strategy: NGFConflictStrategy, label: ResourceStr): void {
    Button(label)
      .layoutWeight(1)
      .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
      .controlSize(ControlSize.SMALL)
      .fontSize(this.a11yScale.font(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE))
      .borderRadius(10)
      .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
      .fontColor(this.conflictStrategy === strategy
        ? $r('app.color.text_primary')
        : $r('app.color.text_secondary'))
      .fontWeight(this.conflictStrategy === strategy ? FontWeight.Bold : FontWeight.Normal)
      .onClick((): void => {
        this.handleSetStrategy(strategy);
      })
  }

  @Builder
  private buildResultCard(): void {
    if (this.lastResult !== null) {
      Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
        Text($r('app.string.sync_result_label'))
          .fontSize(this.a11yScale.font(16))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_body'))

        Row({ space: 12 }) {
          this.buildResultStat($r('app.string.sync_stat_synced'), String((this.lastResult as NGFSyncResultDisplay).syncedCount), '#16A34A')
          this.buildResultStat($r('app.string.sync_stat_failed'), String((this.lastResult as NGFSyncResultDisplay).failedCount), '#E11D48')
          this.buildResultStat($r('app.string.sync_stat_conflict'), String((this.lastResult as NGFSyncResultDisplay).conflictCount), '#D97706')
        }
        .width('100%')

        Row({ space: 6 }) {
          // 装饰图标：旁边已有文字，避免冗余播报
          SymbolGlyph((this.lastResult as NGFSyncResultDisplay).success ? $r('sys.symbol.checkmark_circle') : $r('sys.symbol.exclamationmark_triangle'))
            .fontSize(this.a11yScale.font(14))
            .fontColor([(this.lastResult as NGFSyncResultDisplay).success ? $r('app.color.tag_green') : $r('app.color.tag_red')])
            .accessibilityLevel('no')
          Text((this.lastResult as NGFSyncResultDisplay).success ? $r('app.string.sync_result_success') : $r('app.string.sync_result_partial'))
            .fontSize(this.a11yScale.font(13))
            .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
            .fontColor((this.lastResult as NGFSyncResultDisplay).success ? $r('app.color.tag_green') : $r('app.color.tag_red'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
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
  }

  @Builder
  private buildResultStat(label: ResourceStr, value: string, color: string): void {
    Column({ space: this.a11yScale.paragraphSpacing(4, 18) }) {
      Text(value)
        .fontSize(this.a11yScale.font(22))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(22)))
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(this.a11yScale.font(11))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(11)))
        .fontColor($r('app.color.text_muted'))
    }
    .layoutWeight(1)
    .padding({ top: 10, bottom: 10 })
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
    .borderRadius(12)
    .alignItems(HorizontalAlign.Center)
    // 无障碍分组（官方「使用建议」：对复杂布局减少冗余播报）。
    // 不分组时读屏把「标签」与「数值」当成**两个独立节点**，
    // 用户会听到一个孤立的数值，不知道它属于哪个标签。
    .accessibilityGroup(true)
  }
}
