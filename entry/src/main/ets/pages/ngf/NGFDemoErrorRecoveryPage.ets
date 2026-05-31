import { HdsNavDestination } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import { logger } from 'ngf_framework';
import { NGFErrorContext, NGFErrorSeverity } from 'ngf_framework';
import { ngfStarterKernel } from 'ngf_framework';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from 'ngf_framework';
import { NGFHdsTitleBarOptionsFactory } from 'ngf_framework';
import { NGFPageWindowName, NGFPageWindowSupport } from './NGFPageWindowSupport';

const TAG: string = 'NGFDemoErrorRecoveryPage';

const DEMO_TOP_CHROME: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#1A0508', '#3D0812', '#1A0308', '#F43F5ED8', '#FDA4AFD8', 160, 88
);

class NGFErrorLogEntry {
  id: number;
  label: string;
  severity: string;
  recovered: boolean;
  timestamp: string;

  constructor(id: number, label: string, severity: string, recovered: boolean, timestamp: string) {
    this.id = id;
    this.label = label;
    this.severity = severity;
    this.recovered = recovered;
    this.timestamp = timestamp;
  }
}

@Component
export struct NGFDemoErrorRecoveryPage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private topInsetVp: number = 108;
  @State private statusMessage: ResourceStr = '';
  @State private errorLog: Array<NGFErrorLogEntry> = [];
  @State private recentErrorCount: number = 0;
  @State private strategyRegistered: boolean = false;

  aboutToAppear(): void {
    NGFPageWindowSupport.loadDynamicTopInset(this.getUIContext(), 108, 108, (inset) => {
      this.topInsetVp = inset;
    });
    NGFPageWindowSupport.apply(NGFPageWindowName.DEMO_WORKFLOW);
    this.registerRecoveryStrategy();
  }

  aboutToDisappear(): void {
    NGFPageWindowSupport.restoreMainMenu();
  }

  private registerRecoveryStrategy(): void {
    ngfStarterKernel.errorHandler.registerRecoverStrategy('demo_recovery', async (
      errorName: string,
      message: string,
      severity: NGFErrorSeverity,
      _context: NGFErrorContext
    ): Promise<boolean> => {
      logger.info(TAG, `恢复策略触发: name=${errorName}, severity=${severity}`);
      if (severity === NGFErrorSeverity.CRITICAL) {
        logger.warn(TAG, `CRITICAL 错误 — 降级为安全模式: ${message}`);
        return false;
      }
      return true;
    });
    this.strategyRegistered = true;
    this.statusMessage = $r('app.string.err_strategy_registered');
    logger.info(TAG, '已注册错误恢复策略: demo_recovery');
  }

  private now(): string {
    const d = new Date();
    const h = d.getHours() >= 10 ? `${d.getHours()}` : `0${d.getHours()}`;
    const m = d.getMinutes() >= 10 ? `${d.getMinutes()}` : `0${d.getMinutes()}`;
    const s = d.getSeconds() >= 10 ? `${d.getSeconds()}` : `0${d.getSeconds()}`;
    return `${h}:${m}:${s}`;
  }

  private async handleTriggerError(severity: NGFErrorSeverity): Promise<void> {
    const context = new NGFErrorContext('demo', 'DEMO_MANUAL_TRIGGER', TAG);
    const message = `模拟错误 [${severity}] — ${this.now()}`;
    const recovered = await ngfStarterKernel.errorHandler.handle(`demo_error_${severity}`, message, severity, context);
    this.recentErrorCount = ngfStarterKernel.errorHandler.getRecentErrorCount();
    const entry = new NGFErrorLogEntry(
      this.errorLog.length + 1,
      message,
      severity,
      recovered,
      this.now()
    );
    const next: Array<NGFErrorLogEntry> = [entry];
    for (let i = 0; i < this.errorLog.length && i < 9; i++) {
      next.push(this.errorLog[i]);
    }
    this.errorLog = next;
    this.statusMessage = recovered
      ? $r('app.string.err_recovered', severity)
      : $r('app.string.err_not_recovered', severity);
    logger.info(TAG, `错误处理结果: severity=${severity}, recovered=${recovered}`);
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: DEMO_TOP_CHROME })

        Scroll() {
          Column({ space: 12 }) {
            this.buildTitleCard()
            this.buildTriggerCard()
            this.buildStrategyCard()
            this.buildLogCard()
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
      $r('app.string.demo_error_recovery_title'),
      $r('app.string.demo_error_recovery_desc'),
      '#1A0508',
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
      Text($r('app.string.demo_error_recovery_title'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.panel_background'))
      Text($r('app.string.demo_error_recovery_desc'))
        .fontSize(13)
        .lineHeight(20)
        .fontColor($r('app.color.text_white_low'))
    }
    .width('100%')
    .padding(18)
    .linearGradient({
      angle: 140,
      colors: [['#881337', 0], ['#F43F5E', 1]]
    })
    .borderRadius(20)
    .shadow({ radius: 14, color: '#1A881337', offsetX: 0, offsetY: 8 })
  }

  @Builder
  private buildTriggerCard(): void {
    Column({ space: 10 }) {
      Text($r('app.string.err_trigger_section'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Text($r('app.string.err_trigger_desc'))
        .fontSize(13)
        .lineHeight(19)
        .fontColor($r('app.color.text_tertiary'))

      Column({ space: 8 }) {
        Button($r('app.string.err_trigger_low'))
          .width('100%')
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor('#FF16A34A')
          .onClick((): void => {
            void this.handleTriggerError(NGFErrorSeverity.LOW);
          })

        Button($r('app.string.err_trigger_medium'))
          .width('100%')
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor('#FFD97706')
          .onClick((): void => {
            void this.handleTriggerError(NGFErrorSeverity.MEDIUM);
          })

        Button($r('app.string.err_trigger_high'))
          .width('100%')
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor('#FFEA580C')
          .onClick((): void => {
            void this.handleTriggerError(NGFErrorSeverity.HIGH);
          })

        Button($r('app.string.err_trigger_critical'))
          .width('100%')
          .height(40)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor('#FFE11D48')
          .onClick((): void => {
            void this.handleTriggerError(NGFErrorSeverity.CRITICAL);
          })
      }
      .width('100%')

      if ((typeof this.statusMessage === 'string' ? this.statusMessage : '').length > 0) {
        Text(this.statusMessage)
          .fontSize(13)
          .fontColor($r('app.color.text_body'))
          .width('100%')
          .padding({ top: 4 })
      }

      Row({ space: 8 }) {
        Text($r('app.string.err_recent_count'))
          .fontSize(13)
          .fontColor($r('app.color.text_tertiary'))
        Text(`${this.recentErrorCount}`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.tag_red'))
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
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text($r('app.string.err_strategy_section'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_body'))
          .layoutWeight(1)
        Text(this.strategyRegistered ? $r('app.string.err_strategy_active') : $r('app.string.err_strategy_inactive'))
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.strategyRegistered ? $r('app.color.tag_green') : $r('app.color.tag_red'))
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .backgroundColor($r('app.color.background_surface'))
          .borderRadius(8)
      }
      .width('100%')

      Column({ space: 6 }) {
        this.buildStrategyRule($r('app.string.err_rule_low'), $r('app.string.err_rule_low_desc'), '#16A34A')
        this.buildStrategyRule($r('app.string.err_rule_medium'), $r('app.string.err_rule_medium_desc'), '#D97706')
        this.buildStrategyRule($r('app.string.err_rule_high'), $r('app.string.err_rule_high_desc'), '#EA580C')
        this.buildStrategyRule($r('app.string.err_rule_critical'), $r('app.string.err_rule_critical_desc'), '#E11D48')
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
  private buildStrategyRule(level: ResourceStr, desc: ResourceStr, color: string): void {
    Row({ space: 10 }) {
      Column() {}
        .width(4)
        .height(32)
        .borderRadius(2)
        .backgroundColor(color)

      Column({ space: 2 }) {
        Text(level)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_body'))
        Text(desc)
          .fontSize(11)
          .fontColor($r('app.color.text_muted'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .backgroundColor($r('app.color.background_surface'))
    .borderRadius(10)
  }

  @Builder
  private buildLogCard(): void {
    Column({ space: 8 }) {
      Text($r('app.string.err_log_section'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      if (this.errorLog.length === 0) {
        Text($r('app.string.err_log_empty'))
          .fontSize(13)
          .fontColor($r('app.color.text_muted'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 12, bottom: 12 })
      } else {
        Column({ space: 6 }) {
          ForEach(this.errorLog, (entry: NGFErrorLogEntry) => {
            Row() {
              Column({ space: 2 }) {
                Text(entry.label)
                  .fontSize(12)
                  .fontColor($r('app.color.text_body'))
                  .maxLines(1)
                Text(entry.timestamp)
                  .fontSize(11)
                  .fontColor($r('app.color.text_muted'))
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text(entry.recovered ? $r('app.string.err_recovered_tag') : $r('app.string.err_failed_tag'))
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor(entry.recovered ? $r('app.color.tag_green') : $r('app.color.tag_red'))
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .backgroundColor($r('app.color.background_surface'))
                .borderRadius(6)
            }
            .width('100%')
            .padding({ top: 6, bottom: 6, left: 10, right: 10 })
            .backgroundColor($r('app.color.background_surface'))
            .borderRadius(10)
          }, (entry: NGFErrorLogEntry): string => `err_${entry.id}`)
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
}
