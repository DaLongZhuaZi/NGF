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
import { NGFErrorContext, NGFErrorSeverity } from 'ngf_framework';
import { ngfVisualEffectsFacade } from 'ngf_framework';
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
  @State private statusMessage: ResourceStr = '';
  @State private errorLog: Array<NGFErrorLogEntry> = [];
  @State private recentErrorCount: number = 0;
  @State private strategyRegistered: boolean = false;
  @StorageProp('ngf_visual_effects_should_use_system_material_surface') private useSysMat: boolean = true;

  aboutToAppear(): void {
    this.attachA11yBinding();
    NGFPageWindowSupport.loadDynamicTopInset(this.getUIContext(), 108, 108, (inset) => {
      this.topInsetVp = inset;
    });
    NGFPageWindowSupport.apply(NGFPageWindowName.DEMO_WORKFLOW);
    this.registerRecoveryStrategy();
  }

  aboutToDisappear(): void {
    this.detachA11yBinding();
    NGFPageWindowSupport.restoreMainMenu();
  }

  private registerRecoveryStrategy(): void {
    ngfStarterKernel.errorHandler.registerRecoverStrategy('demo_recovery', async (
      errorName: string,
      message: string,
      severity: NGFErrorSeverity,
      _context: NGFErrorContext
    ): Promise<boolean> => {
      logger.info(TAG, '恢复策略触发: name=' + errorName + ', severity=' + severity);
      if (severity === NGFErrorSeverity.CRITICAL) {
        logger.warn(TAG, 'CRITICAL 错误 — 降级为安全模式: ' + message);
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
    const h = d.getHours() >= 10 ? String(d.getHours()) : '0' + String(d.getHours());
    const m = d.getMinutes() >= 10 ? String(d.getMinutes()) : '0' + String(d.getMinutes());
    const s = d.getSeconds() >= 10 ? String(d.getSeconds()) : '0' + String(d.getSeconds());
    return h + ':' + m + ':' + s;
  }

  private async handleTriggerError(severity: NGFErrorSeverity): Promise<void> {
    const context = new NGFErrorContext('demo', 'DEMO_MANUAL_TRIGGER', TAG);
    const message = '模拟错误 [' + severity + '] — ' + String(this.now());
    const recovered = await ngfStarterKernel.errorHandler.handle('demo_error_' + severity, message, severity, context);
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
    logger.info(TAG, '错误处理结果: severity=' + severity + ', recovered=' + recovered);
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: DEMO_TOP_CHROME })

        Scroll() {
          Column({ space: this.a11yScale.paragraphSpacing(12, 18) }) {
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
    Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
      Text($r('app.string.demo_error_recovery_title'))
        .fontSize(this.a11yScale.font(22))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(22)))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text($r('app.string.demo_error_recovery_desc'))
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
  private buildTriggerCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Text($r('app.string.err_trigger_section'))
        .fontSize(this.a11yScale.font(16))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      Text($r('app.string.err_trigger_desc'))
        .fontSize(this.a11yScale.font(13))
        .lineHeight(this.a11yScale.explicitLineHeight(this.a11yScale.font(13), 19))
        .fontColor($r('app.color.text_tertiary'))

      Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
        Button($r('app.string.err_trigger_low'))
          .width('100%')
          .height(NGFControlStyleTokens.FORM_CONTROL_MIN_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.FORM_CONTROL_FONT_SIZE))
          .fontColor($r('app.color.text_primary'))
          .borderRadius(NGFControlStyleTokens.FORM_CONTROL_RADIUS)
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            void this.handleTriggerError(NGFErrorSeverity.LOW);
          })

        Button($r('app.string.err_trigger_medium'))
          .width('100%')
          .height(NGFControlStyleTokens.FORM_CONTROL_MIN_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.FORM_CONTROL_FONT_SIZE))
          .fontColor($r('app.color.text_primary'))
          .borderRadius(NGFControlStyleTokens.FORM_CONTROL_RADIUS)
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            void this.handleTriggerError(NGFErrorSeverity.MEDIUM);
          })

        Button($r('app.string.err_trigger_high'))
          .width('100%')
          .height(NGFControlStyleTokens.FORM_CONTROL_MIN_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.FORM_CONTROL_FONT_SIZE))
          .fontColor($r('app.color.text_primary'))
          .borderRadius(NGFControlStyleTokens.FORM_CONTROL_RADIUS)
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            void this.handleTriggerError(NGFErrorSeverity.HIGH);
          })

        Button($r('app.string.err_trigger_critical'))
          .width('100%')
          .height(NGFControlStyleTokens.FORM_CONTROL_MIN_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.FORM_CONTROL_FONT_SIZE))
          .fontColor($r('app.color.text_primary'))
          .borderRadius(NGFControlStyleTokens.FORM_CONTROL_RADIUS)
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .onClick((): void => {
            void this.handleTriggerError(NGFErrorSeverity.CRITICAL);
          })
      }
      .width('100%')

      if ((typeof this.statusMessage === 'string' ? this.statusMessage : '').length > 0) {
        Text(this.statusMessage)
          .fontSize(this.a11yScale.font(13))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
          .fontColor($r('app.color.text_body'))
          .width('100%')
          .padding({ top: 4 })
      }

      Row({ space: 8 }) {
        Text($r('app.string.err_recent_count'))
          .fontSize(this.a11yScale.font(13))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
          .fontColor($r('app.color.text_tertiary'))
        Text(String(this.recentErrorCount))
          .fontSize(this.a11yScale.font(14))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.tag_red'))
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
    Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
      Row({ space: 8 }) {
        Text($r('app.string.err_strategy_section'))
          .fontSize(this.a11yScale.font(16))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_body'))
          .layoutWeight(1)
        Text(this.strategyRegistered ? $r('app.string.err_strategy_active') : $r('app.string.err_strategy_inactive'))
          .fontSize(this.a11yScale.font(12))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.strategyRegistered ? $r('app.color.tag_green') : $r('app.color.tag_red'))
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
          .borderRadius(8)
      }
      .width('100%')

      Column({ space: this.a11yScale.paragraphSpacing(6, 18) }) {
        this.buildStrategyRule($r('app.string.err_rule_low'), $r('app.string.err_rule_low_desc'))
        this.buildStrategyRule($r('app.string.err_rule_medium'), $r('app.string.err_rule_medium_desc'))
        this.buildStrategyRule($r('app.string.err_rule_high'), $r('app.string.err_rule_high_desc'))
        this.buildStrategyRule($r('app.string.err_rule_critical'), $r('app.string.err_rule_critical_desc'))
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
  private buildStrategyRule(level: ResourceStr, desc: ResourceStr): void {
    Row({ space: 10 }) {
      Column() {}
        .width(4)
        .height(32)
        .borderRadius(2)
        .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))

      Column({ space: this.a11yScale.paragraphSpacing(2, 18) }) {
        Text(level)
          .fontSize(this.a11yScale.font(13))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_body'))
        Text(desc)
          .fontSize(this.a11yScale.font(11))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(11)))
          .fontColor($r('app.color.text_muted'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .borderRadius(10)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
    // 无障碍分组（官方「使用建议」：对复杂布局减少冗余播报）。
    // 不分组时读屏把「标签」与「数值」当成**两个独立节点**，
    // 用户会听到一个孤立的数值，不知道它属于哪个标签。
    .accessibilityGroup(true)
  }

  @Builder
  private buildLogCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
      Text($r('app.string.err_log_section'))
        .fontSize(this.a11yScale.font(16))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_body'))

      if (this.errorLog.length === 0) {
        Text($r('app.string.err_log_empty'))
          .fontSize(this.a11yScale.font(13))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
          .fontColor($r('app.color.text_muted'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 12, bottom: 12 })
      } else {
        Column({ space: this.a11yScale.paragraphSpacing(6, 18) }) {
          ForEach(this.errorLog, (entry: NGFErrorLogEntry) => {
            Row() {
              Column({ space: this.a11yScale.paragraphSpacing(2, 18) }) {
                Text(entry.label)
                  .fontSize(this.a11yScale.font(12))
                  .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
                  .fontColor($r('app.color.text_body'))
                  .maxLines(1)
                Text(entry.timestamp)
                  .fontSize(this.a11yScale.font(11))
                  .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(11)))
                  .fontColor($r('app.color.text_muted'))
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text(entry.recovered ? $r('app.string.err_recovered_tag') : $r('app.string.err_failed_tag'))
                .fontSize(this.a11yScale.font(11))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(11)))
                .fontWeight(FontWeight.Medium)
                .fontColor(entry.recovered ? $r('app.color.tag_green') : $r('app.color.tag_red'))
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
                .borderRadius(6)
            }
            .width('100%')
            .padding({ top: 6, bottom: 6, left: 10, right: 10 })
            .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
            .borderRadius(10)
          }, (entry: NGFErrorLogEntry): string => 'err_' + entry.id)
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
}
