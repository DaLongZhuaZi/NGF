import { HdsNavDestination } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import { logger } from '../../Framework/NGF/utils/Logger';
import {
  NGFConflictStrategy,
  NGFSyncOperation,
  NGFSyncQueueItem,
  NGFSyncResult
} from '../../Framework/NGF/data/contracts/ISyncManager';
import { ISyncDataHandler } from '../../Framework/NGF/data/contracts/ISyncManager';
import { ngfSyncManagerFacade } from '../../Framework/NGF/data/index';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from '../../Framework/NGF/uiShell/components/NGFImmersiveTopChrome';
import { NGFHdsTitleBarOptionsFactory } from '../../Framework/NGF/uiShell/components/HdsNavigationSupport';
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
    logger.debug(TAG, `远程推送: entity=${item.entityName}, op=${item.operation}`);
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
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private topInsetVp: number = 108;
  @State private isOnline: boolean = false;
  @State private conflictStrategy: NGFConflictStrategy = NGFConflictStrategy.CLIENT_WINS;
  @State private queueItems: Array<NGFSyncQueueDisplay> = [];
  @State private queueSize: number = 0;
  @State private lastResult: NGFSyncResultDisplay | null = null;
  @State private statusMessage: ResourceStr = '';
  private handler: DemoSyncHandler = new DemoSyncHandler(false);
  private nextItemId: number = 1;

  aboutToAppear(): void {
    NGFPageWindowSupport.loadDynamicTopInset(this.getUIContext(), 108, 108, (inset) => {
      this.topInsetVp = inset;
    });
    NGFPageWindowSupport.apply(NGFPageWindowName.DEMO_WORKFLOW);
    ngfSyncManagerFacade.setSyncHandler(this.handler);
    ngfSyncManagerFacade.setConflictStrategy(this.conflictStrategy);
    this.refreshQueueDisplay();
  }

  aboutToDisappear(): void {
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
    logger.info(TAG, `模拟网络状态: online=${this.isOnline}`);
  }

  private handleEnqueue(op: NGFSyncOperation): void {
    const id = `item_${this.nextItemId}`;
    this.nextItemId++;
    const item = new NGFSyncQueueItem(
      id,
      'UserProfile',
      `user_${this.nextItemId}`,
      op,
      `{"name":"User${this.nextItemId}","ts":${Date.now()}}`,
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
    logger.info(TAG, `入队: id=${id}, op=${op}`);
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
    logger.info(TAG, `同步完成: synced=${result.syncedCount}, failed=${result.failedCount}`);
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
          Column({ space: 12 }) {
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
    Column({ space: 8 }) {
      Text($r('app.string.demo_sync_title'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.panel_background'))
      Text($r('app.string.demo_sync_desc'))
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

  @Builder
  private buildNetworkCard(): void {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        Column({ space: 4 }) {
          Text($r('app.string.sync_network_label'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_body'))
          Text(this.isOnline ? $r('app.string.sync_online') : $r('app.string.sync_offline'))
            .fontSize(13)
            .fontColor(this.isOnline ? $r('app.color.tag_green') : $r('app.color.tag_red'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button(this.isOnline ? $r('app.string.sync_go_offline') : $r('app.string.sync_go_online'))
          .height(36)
          .fontSize(13)
          .borderRadius(10)
          .backgroundColor(this.isOnline ? $r('app.color.tag_red') : $r('app.color.tag_green'))
          .onClick((): void => {
            this.handleToggleNetwork();
          })
      }
      .width('100%')

      if ((typeof this.statusMessage === 'string' ? this.statusMessage : '').length > 0) {
        Row({ space: 6 }) {
          SymbolGlyph($r('sys.symbol.info_circle'))
            .fontSize(12)
            .fontColor([$r('app.color.text_muted')])
          Text(this.statusMessage)
            .fontSize(12)
            .fontColor($r('app.color.text_muted'))
            .layoutWeight(1)
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

  @Builder
  private buildQueueCard(): void {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text($r('app.string.sync_queue_label'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_body'))
          .layoutWeight(1)
        Text(`${this.queueSize}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.button_primary'))
      }
      .width('100%')

      Text($r('app.string.sync_queue_hint'))
        .fontSize(12)
        .fontColor($r('app.color.text_tertiary'))

      Row({ space: 8 }) {
        Button() {
          Row({ space: 4 }) {
            SymbolGlyph($r('sys.symbol.plus'))
              .fontSize(14)
              .fontColor(['#FFFFFF'])
            Text($r('app.string.sync_enqueue_create'))
              .fontSize(12)
              .fontColor('#FFFFFF')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
        .layoutWeight(1)
        .height(36)
        .borderRadius(10)
        .backgroundColor($r('app.color.tag_green'))
        .onClick((): void => {
          this.handleEnqueue(NGFSyncOperation.CREATE);
        })

        Button() {
          Row({ space: 4 }) {
            SymbolGlyph($r('sys.symbol.square_and_pencil'))
              .fontSize(14)
              .fontColor(['#FFFFFF'])
            Text($r('app.string.sync_enqueue_update'))
              .fontSize(12)
              .fontColor('#FFFFFF')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
        .layoutWeight(1)
        .height(36)
        .borderRadius(10)
        .backgroundColor('#FF2563EB')
        .onClick((): void => {
          this.handleEnqueue(NGFSyncOperation.UPDATE);
        })

        Button() {
          Row({ space: 4 }) {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(14)
              .fontColor(['#FFFFFF'])
            Text($r('app.string.sync_enqueue_delete'))
              .fontSize(12)
              .fontColor('#FFFFFF')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
        .layoutWeight(1)
        .height(36)
        .borderRadius(10)
        .backgroundColor($r('app.color.tag_red'))
        .onClick((): void => {
          this.handleEnqueue(NGFSyncOperation.DELETE);
        })
      }
      .width('100%')

      Row({ space: 8 }) {
        Button($r('app.string.sync_flush_btn'))
          .layoutWeight(2)
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor($r('app.color.button_primary'))
          .onClick((): void => {
            void this.handleFlush();
          })

        Button($r('app.string.sync_clear_btn'))
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor($r('app.color.background_surface'))
          .fontColor($r('app.color.text_body'))
          .onClick((): void => {
            this.handleClearQueue();
          })
      }
      .width('100%')

      if (this.queueItems.length > 0) {
        Column({ space: 4 }) {
          ForEach(this.queueItems, (item: NGFSyncQueueDisplay) => {
            Row({ space: 8 }) {
              Text(item.operation)
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.button_primary'))
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor($r('app.color.background_surface'))
                .borderRadius(4)

              Text(item.payload)
                .fontSize(11)
                .fontColor($r('app.color.text_muted'))
                .maxLines(1)
                .layoutWeight(1)
            }
            .width('100%')
            .padding({ top: 5, bottom: 5, left: 10, right: 10 })
            .backgroundColor($r('app.color.background_surface'))
            .borderRadius(8)
          }, (item: NGFSyncQueueDisplay): string => `q_${item.id}`)
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

  @Builder
  private buildStrategyCard(): void {
    Column({ space: 10 }) {
      Text($r('app.string.sync_strategy_label'))
        .fontSize(16)
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
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.card_border') })
    .shadow({ radius: 10, color: $r('app.color.card_shadow_demo'), offsetX: 0, offsetY: 4 })
  }

  @Builder
  private buildStrategyButton(strategy: NGFConflictStrategy, label: ResourceStr): void {
    Button(label)
      .layoutWeight(1)
      .height(36)
      .fontSize(12)
      .borderRadius(10)
      .backgroundColor(this.conflictStrategy === strategy
        ? $r('app.color.button_primary')
        : $r('app.color.background_surface'))
      .fontColor(this.conflictStrategy === strategy
        ? $r('app.color.panel_background')
        : $r('app.color.text_body'))
      .onClick((): void => {
        this.handleSetStrategy(strategy);
      })
  }

  @Builder
  private buildResultCard(): void {
    if (this.lastResult !== null) {
      Column({ space: 8 }) {
        Text($r('app.string.sync_result_label'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_body'))

        Row({ space: 12 }) {
          this.buildResultStat($r('app.string.sync_stat_synced'), `${(this.lastResult as NGFSyncResultDisplay).syncedCount}`, '#16A34A')
          this.buildResultStat($r('app.string.sync_stat_failed'), `${(this.lastResult as NGFSyncResultDisplay).failedCount}`, '#E11D48')
          this.buildResultStat($r('app.string.sync_stat_conflict'), `${(this.lastResult as NGFSyncResultDisplay).conflictCount}`, '#D97706')
        }
        .width('100%')

        Row({ space: 6 }) {
          SymbolGlyph((this.lastResult as NGFSyncResultDisplay).success ? $r('sys.symbol.checkmark_circle') : $r('sys.symbol.exclamationmark_triangle'))
            .fontSize(14)
            .fontColor([(this.lastResult as NGFSyncResultDisplay).success ? $r('app.color.tag_green') : $r('app.color.tag_red')])
          Text((this.lastResult as NGFSyncResultDisplay).success ? $r('app.string.sync_result_success') : $r('app.string.sync_result_partial'))
            .fontSize(13)
            .fontColor((this.lastResult as NGFSyncResultDisplay).success ? $r('app.color.tag_green') : $r('app.color.tag_red'))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.panel_background'))
      .borderRadius(16)
      .border({ width: 1, color: $r('app.color.card_border') })
      .shadow({ radius: 10, color: $r('app.color.card_shadow_demo'), offsetX: 0, offsetY: 4 })
    }
  }

  @Builder
  private buildResultStat(label: ResourceStr, value: string, color: string): void {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(11)
        .fontColor($r('app.color.text_muted'))
    }
    .layoutWeight(1)
    .padding({ top: 10, bottom: 10 })
    .backgroundColor($r('app.color.background_surface'))
    .borderRadius(12)
    .alignItems(HorizontalAlign.Center)
  }
}
