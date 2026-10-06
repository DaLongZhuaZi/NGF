/**
 * NGF 无障碍与适老化框架验证页
 *
 * 目的：把 P3/P4 建立的契约、策略、令牌与可复用组件接入**真实页面**，
 * 消除"只有编译证据、没有页面接入"的缺口。页面本身就是验证矩阵的一部分：
 *
 * 1. 平台状态快照 —— 系统无障碍开关 / 读屏 / 触摸探索 / 触摸模式 / 减少动效 / 适老模式，实时刷新；
 * 2. 生效策略与设计令牌 —— 策略五档 + 关键数值（字号 / 点击区 / 行高 / 对比度 / 动效倍率）；
 * 3. 适老模式与用户策略控制 —— 调用系统 API 读写本应用适老模式，并演示策略持久化；
 * 4. 可复用组件样例 —— NGFAccessibleButton / NGFAccessibleListItem / NGFAccessibleDialogCloseButton；
 * 5. 语义审计 —— 用 auditAccessibilitySemantics() 把"语义清单"变成页面可见的结论。
 *
 * 订阅生命周期：页面用 NGFAccessibilityLifecycleBinding 在 aboutToAppear 订阅、
 * aboutToDisappear 取消，符合 API 26 SDK 对 on/off 配对的硬性要求。
 *
 * 窗口策略：本页不自定义显示模式，因此只取动态顶部避让，不注册 NGFPageWindowProfile；
 * 离开时恢复主菜单策略。
 *
 * 注意：页面上展示的布尔值 / 枚举值 / 数值都是**诊断数据**，不是面向用户的文案，
 * 因此按原样展示；所有**标签**一律走 i18n 资源。
 */

import { HdsNavDestination } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import {
  auditAccessibilitySemantics,
  logger,
  NGFContrastPolicy,
  NGFDensityPolicy,
  NGFHdsTitleBarOptionsFactory,
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay,
  NGFInclusiveDesignMetrics,
  NGFInclusiveDesignPolicy,
  NGFInclusiveDesignResolved,
  NGFInclusiveDesignTokens,
  NGFMotionPolicy,
  NGFTextScalePolicy,
  NGFTouchTargetPolicy,
  NGFUiContext,
  NGFAccessibilityAction,
  NGFAccessibilityBindingListener,
  NGFAccessibilityLevel,
  NGFAccessibilityLifecycleBinding,
  NGFAccessibilityRole,
  NGFAccessibilitySemantics,
  NGFAccessibilitySemanticsAudit,
  NGFAccessibilityState,
  NGFAccessibilityStateSnapshot,
  NGFAccessibleButton,
  NGFAccessibleDialogCloseButton,
  NGFAccessibleFormField,
  NGFAccessibleListItem,
  NGFAccessibilityAttributeModifier,
  NGFA11yTextScale,
  NGFA11yModifierSet,
  a11yTouchTarget,
  resolveA11yTextScaleForCurrent,
  NGFDialogClosePosition,
  NGFTouchMode,
  NGFFormFieldSemanticsConfig,
  NGFHdsTitleBarAccessibilityConfig,
  buildFormFieldSemantics,
  ngfAccessibilityFacade,
  resolveInclusiveDesignTokens,
  resolveResourceString,
  resolveUiContextForPolicy
} from 'ngf_framework';
import { NGFPageWindowSupport } from './NGFPageWindowSupport';

const TAG: string = 'NGFAccessibilityShowcasePage';

const A11Y_TOP_CHROME: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#07101E', '#0C2341', '#0A1626', '#2854F0E8', '#32A4F2D8', 168, 88
);

// 监听器直接用**对象字面量**传给 NGFAccessibilityLifecycleBinding 即可 ——
// 已在 API 26 上实测编译通过（原先需要一个具名类做中转，现已确认不必）。

@Component
export struct NGFAccessibilityShowcasePage {
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


  @State private topInsetVp: number = 108;
  @State private snapshot: NGFAccessibilityStateSnapshot = ngfAccessibilityFacade.getStateSnapshot();
  @State private policy: NGFInclusiveDesignPolicy = ngfAccessibilityFacade.getPolicy();
  @State private tokens: NGFInclusiveDesignTokens =
    resolveInclusiveDesignTokens({ policy: ngfAccessibilityFacade.getPolicy(), context: NGFUiContext.STANDARD_PAGE });
  @State private logLines: Array<string> = [];
  /** 表单字段演示：输入值 */
  @State private fieldValue: string = '';
  /** 表单字段演示：错误态开关（用于验证错误态下的描述优先级） */
  @State private fieldHasError: boolean = false;
  private readonly scroller: Scroller = new Scroller();
  private binding: NGFAccessibilityLifecycleBinding | null = null;

  /**
   * 适老修饰器工厂（演示框架用法）。
   *
   * 用 getter 而非字段：`AttributeModifier` 是命令式下发属性的，
   * **实例被替换**才会重新执行 `applyNormalAttribute`；
   * 只改实例内部字段不会重新下发。getter 每次 build 新建实例，保证缩放变化后一定生效。
   */
  private get a11y(): NGFA11yModifierSet {
    return new NGFA11yModifierSet(this.a11yScale);
  }

  aboutToAppear(): void {
    this.attachA11yBinding();
    NGFPageWindowSupport.loadDynamicTopInset(this.getUIContext(), 108, 108, (inset: number) => {
      this.topInsetVp = inset;
    });

    // 探针：对象字面量形式的监听器是否可用（若不可用则回退到具名类写法）
    const listener: NGFAccessibilityBindingListener = {
      onAccessibilityStateChanged: (snapshot: NGFAccessibilityStateSnapshot): void => {
        this.snapshot = snapshot;
      },
      onInclusiveDesignChanged: (resolved: NGFInclusiveDesignResolved): void => {
        this.policy = resolved.policy;
        this.refreshTokens();
      }
    };
    this.binding = new NGFAccessibilityLifecycleBinding(listener);
    this.binding.attach();

    this.snapshot = ngfAccessibilityFacade.getStateSnapshot();
    this.policy = ngfAccessibilityFacade.getPolicy();
    this.refreshTokens();
    logger.lifecycle(TAG, '无障碍验证页已订阅平台状态');
  }

  aboutToDisappear(): void {
    this.detachA11yBinding();
    const current: NGFAccessibilityLifecycleBinding | null = this.binding;
    if (current !== null) {
      current.detach();
      this.binding = null;
    }
    NGFPageWindowSupport.restoreMainMenu();
    logger.lifecycle(TAG, '无障碍验证页已取消订阅');
  }

  private refreshTokens(): void {
    const context: NGFUiContext = resolveUiContextForPolicy(this.policy);
    this.tokens = resolveInclusiveDesignTokens({ policy: this.policy, context: context });
  }

  private appendLog(message: string): void {
    const next: Array<string> = this.logLines.slice();
    next.push(message);
    this.logLines = next;
  }

  /**
   * 把 ResourceStr 解析成字符串。
   * 注意：不使用带 %s 参数的重载——getStringSync(resId) 不会做参数替换，
   * 因此日志统一用「前缀 + 分隔符 + 已本地化标签」拼接，避免出现未替换的 %s。
   */
  private resolveText(value: ResourceStr): string {
    return resolveResourceString(this.getUIContext().getHostContext(), value);
  }

  private logEvent(label: ResourceStr): void {
    this.appendLog(this.resolveText($r('app.string.a11y_log_prefix')) + ': ' + this.resolveText(label));
  }

  private formatBool(value: boolean): string {
    return value ? 'true' : 'false';
  }

  private formatNumber(value: number): string {
    return String(value);
  }

  private touchModeText(): string {
    const mode: NGFTouchMode = this.snapshot.touchMode;
    return mode;
  }

  private accessibilityStateText(): string {
    const state: NGFAccessibilityState = this.snapshot.accessibilityEnabled;
    return state;
  }

  /** 演示用语义模型：与页面上实际渲染的组件保持一致，供审计使用 */
  private buildDemoButtonSemantics(): NGFAccessibilitySemantics {
    const semantics: NGFAccessibilitySemantics = {
      id: 'a11y_showcase_button',
      role: NGFAccessibilityRole.BUTTON,
      label: $r('app.string.a11y_demo_button'),
      description: $r('app.string.a11y_demo_button_desc'),
      actions: [NGFAccessibilityAction.CLICK]
    };
    return semantics;
  }

  private buildDemoListSemantics(): NGFAccessibilitySemantics {
    const semantics: NGFAccessibilitySemantics = {
      id: 'a11y_showcase_list_item',
      role: NGFAccessibilityRole.LIST_ITEM,
      actions: [NGFAccessibilityAction.CLICK],
      state: { selected: true, enabled: true },
      grouping: { isGroup: true, accessibilityPreferred: true }
    };
    return semantics;
  }

  private buildDemoCloseSemantics(): NGFAccessibilitySemantics {
    const semantics: NGFAccessibilitySemantics = {
      id: 'a11y_showcase_dialog_close',
      role: NGFAccessibilityRole.BUTTON,
      label: $r('app.string.a11y_demo_dialog_close'),
      actions: [NGFAccessibilityAction.CLICK]
    };
    return semantics;
  }

  private auditAllPassed(): boolean {
    const a: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(this.buildDemoButtonSemantics());
    const b: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(this.buildDemoListSemantics());
    const c: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(this.buildDemoCloseSemantics());
    return a.valid && b.valid && c.valid;
  }

  private auditIssueCount(): number {
    const a: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(this.buildDemoButtonSemantics());
    const b: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(this.buildDemoListSemantics());
    const c: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(this.buildDemoCloseSemantics());
    return a.issues.length + b.issues.length + c.issues.length;
  }

  private handleToggleSeniorMode(): void {
    const next: boolean = !this.snapshot.appSeniorModeEnabled;
    const label: ResourceStr = next
      ? $r('app.string.a11y_action_enable_senior')
      : $r('app.string.a11y_action_disable_senior');
    ngfAccessibilityFacade.setAppSeniorMode(next)
      .then((): void => {
        this.snapshot = ngfAccessibilityFacade.getStateSnapshot();
        this.logEvent(label);
      })
      .catch((error: Error): void => {
        logger.warn(TAG, '设置本应用适老模式失败: ' + error.message);
      });
  }

  private handleApplyEnhancedPolicy(): void {
    const enhanced: NGFInclusiveDesignPolicy = {
      textScale: NGFTextScalePolicy.ENHANCED,
      touchTarget: NGFTouchTargetPolicy.LARGE,
      contrast: NGFContrastPolicy.ENHANCED,
      motion: NGFMotionPolicy.REDUCED,
      density: NGFDensityPolicy.ELDERLY
    };
    ngfAccessibilityFacade.setUserPolicy(enhanced);
    this.policy = ngfAccessibilityFacade.getPolicy();
    this.refreshTokens();
    this.logEvent($r('app.string.a11y_action_set_user_policy'));
  }

  private handleClearUserPolicy(): void {
    ngfAccessibilityFacade.clearUserPolicy();
    this.policy = ngfAccessibilityFacade.getPolicy();
    this.refreshTokens();
    this.logEvent($r('app.string.a11y_action_clear_user_policy'));
  }

  /** 表单字段的语义配置：错误态时把 errorText 提到最高优先级 */
  private buildFieldConfig(): NGFFormFieldSemanticsConfig {
    const config: NGFFormFieldSemanticsConfig = {
      id: 'a11y_showcase_field_input',
      label: $r('app.string.a11y_demo_field_label'),
      requiredMarker: $r('app.string.a11y_demo_field_required'),
      helpText: $r('app.string.a11y_demo_field_help'),
      enabled: true
    };
    if (this.fieldHasError) {
      config.errorText = $r('app.string.a11y_demo_field_error');
    }
    return config;
  }

  /**
   * 输入控件本体：语义经 buildFormFieldSemantics() + AttributeModifier 绑到**真正的输入框**上，
   * 而不是靠容器分组 —— 分组会让输入框失去独立焦点、无法编辑。
   */
  @Builder
  private buildFieldInput() {
    TextInput({ text: this.fieldValue, placeholder: $r('app.string.a11y_demo_field_placeholder') })
      .id('a11y_showcase_field_input')
      .width('100%')
      .constraintSize({ minHeight: this.tokens.minTouchTarget })
      .onChange((value: string): void => {
        this.fieldValue = value;
      })
      .attributeModifier(new NGFAccessibilityAttributeModifier(
        buildFormFieldSemantics(this.buildFieldConfig())
      ))
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: A11Y_TOP_CHROME })

        Scroll(this.scroller) {
          Column({ space: this.a11yScale.paragraphSpacing(16, 18) }) {

            // ── 1. 平台状态快照 ──────────────────────────────────────────
            Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
              // ⚠️ 演示：基础组件一行接入适老放大（NGFA11yModifierSet）
              // 对比上面的手工写法 —— 修饰器把「字号抬到 18 + 行高 ×1.3」打包成一个方法，
              // 开发者不需要记住要改哪几个属性。
              Text($r('app.string.a11y_section_snapshot'))
                .attributeModifier(this.a11y.text(18))
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary')).width('100%')
              Text(this.resolveText($r('app.string.a11y_label_accessibility')) + '：' + this.accessibilityStateText())
                .attributeModifier(this.a11y.text(15))
                .fontColor($r('app.color.text_primary')).width('100%')
              Text(this.resolveText($r('app.string.a11y_label_screen_reader')) + '：' + this.formatBool(this.snapshot.screenReaderEnabled))
                .attributeModifier(this.a11y.text(15))
                .fontColor($r('app.color.text_primary')).width('100%')
              Text(this.resolveText($r('app.string.a11y_label_touch_guide')) + '：' + this.formatBool(this.snapshot.touchGuideEnabled))
                .fontSize(this.a11yScale.font(15)).fontColor($r('app.color.text_primary')).width('100%')
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
              Text(this.resolveText($r('app.string.a11y_label_touch_mode')) + '：' + this.touchModeText())
                .fontSize(this.a11yScale.font(15)).fontColor($r('app.color.text_primary')).width('100%')
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
              Text(this.resolveText($r('app.string.a11y_label_animation_reduce')) + '：' + this.formatBool(this.snapshot.animationReduceEnabled))
                .fontSize(this.a11yScale.font(15)).fontColor($r('app.color.text_primary')).width('100%')
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
              Text(this.resolveText($r('app.string.a11y_label_senior_mode')) + '：'
                + (this.snapshot.seniorModeResolved
                  ? this.formatBool(this.snapshot.seniorModeEnabled)
                  : this.resolveText($r('app.string.a11y_senior_unresolved'))))
                .fontSize(this.a11yScale.font(15)).fontColor($r('app.color.text_primary')).width('100%')
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
              Text(this.resolveText($r('app.string.a11y_label_app_senior_mode')) + '：'
                + (this.snapshot.seniorModeResolved
                  ? this.formatBool(this.snapshot.appSeniorModeEnabled)
                  : this.resolveText($r('app.string.a11y_senior_unresolved'))))
                .fontSize(this.a11yScale.font(15)).fontColor($r('app.color.text_primary')).width('100%')
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
            }
            .width('100%')
            .padding(16)
            .backgroundColor($r('app.color.glass_chip_overlay'))
            .borderRadius(16)

            // ── 2. 生效策略与设计令牌 ────────────────────────────────────
            Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
              Text($r('app.string.a11y_section_policy'))
                .fontSize(this.a11yScale.font(18)).fontWeight(FontWeight.Bold)
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(18)))
                .fontColor($r('app.color.text_primary')).width('100%')
              Text(this.resolveText($r('app.string.a11y_label_text_scale')) + '：' + this.policy.textScale)
                .fontSize(this.a11yScale.font(15)).fontColor($r('app.color.text_primary')).width('100%')
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
              Text(this.resolveText($r('app.string.a11y_label_touch_target_policy')) + '：' + this.policy.touchTarget)
                .fontSize(this.a11yScale.font(15)).fontColor($r('app.color.text_primary')).width('100%')
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
              Text(this.resolveText($r('app.string.a11y_label_contrast')) + '：' + this.policy.contrast)
                .fontSize(this.a11yScale.font(15)).fontColor($r('app.color.text_primary')).width('100%')
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
              Text(this.resolveText($r('app.string.a11y_label_motion')) + '：' + this.policy.motion)
                .fontSize(this.a11yScale.font(15)).fontColor($r('app.color.text_primary')).width('100%')
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
              Text(this.resolveText($r('app.string.a11y_label_density')) + '：' + this.policy.density)
                .fontSize(this.a11yScale.font(15)).fontColor($r('app.color.text_primary')).width('100%')
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
              Divider().color($r('app.color.text_secondary')).opacity(0.3)
              Text(this.resolveText($r('app.string.a11y_token_font')) + '：' + this.formatNumber(this.tokens.bodyFontSize))
                .fontSize(this.a11yScale.font(15)).fontColor($r('app.color.text_primary')).width('100%')
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
              Text(this.resolveText($r('app.string.a11y_token_touch')) + '：' + this.formatNumber(this.tokens.minTouchTarget))
                .fontSize(this.a11yScale.font(15)).fontColor($r('app.color.text_primary')).width('100%')
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
              Text(this.resolveText($r('app.string.a11y_token_line_height')) + '：' + this.formatNumber(this.tokens.bodyLineHeight))
                .fontSize(this.a11yScale.font(15)).fontColor($r('app.color.text_primary')).width('100%')
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
              Text(this.resolveText($r('app.string.a11y_token_contrast')) + '：' + this.formatNumber(this.tokens.textContrastRatio))
                .fontSize(this.a11yScale.font(15)).fontColor($r('app.color.text_primary')).width('100%')
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
              Text(this.resolveText($r('app.string.a11y_token_motion_scale')) + '：' + this.formatNumber(this.tokens.motionDurationScale))
                .fontSize(this.a11yScale.font(15)).fontColor($r('app.color.text_primary')).width('100%')
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
              Text(this.resolveText($r('app.string.a11y_token_dialog_close')) + '：' + this.formatNumber(this.tokens.dialogCloseTarget))
                .fontSize(this.a11yScale.font(15)).fontColor($r('app.color.text_primary')).width('100%')
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
            }
            .width('100%')
            .padding(16)
            .backgroundColor($r('app.color.glass_chip_overlay'))
            .borderRadius(16)

            // ── 3. 适老模式与用户策略控制 ────────────────────────────────
            Column({ space: this.a11yScale.paragraphSpacing(12, 18) }) {
              NGFAccessibleButton({
              isElderly: this.a11yScale.isElderly,
                componentId: 'a11y_toggle_senior',
                label: this.snapshot.appSeniorModeEnabled
                  ? $r('app.string.a11y_action_disable_senior')
                  : $r('app.string.a11y_action_enable_senior'),
                minTouchTarget: this.tokens.minTouchTarget,
                onTap: (): void => {
                  this.handleToggleSeniorMode();
                }
              })
              NGFAccessibleButton({
              isElderly: this.a11yScale.isElderly,
                componentId: 'a11y_apply_policy',
                label: $r('app.string.a11y_action_set_user_policy'),
                minTouchTarget: this.tokens.minTouchTarget,
                onTap: (): void => {
                  this.handleApplyEnhancedPolicy();
                }
              })
              NGFAccessibleButton({
              isElderly: this.a11yScale.isElderly,
                componentId: 'a11y_clear_policy',
                label: $r('app.string.a11y_action_clear_user_policy'),
                minTouchTarget: this.tokens.minTouchTarget,
                onTap: (): void => {
                  this.handleClearUserPolicy();
                }
              })
            }
            .width('100%')

            // ── 4. 可复用组件样例 ────────────────────────────────────────
            Column({ space: this.a11yScale.paragraphSpacing(12, 18) }) {
              Text($r('app.string.a11y_section_components'))
                .fontSize(this.a11yScale.font(18)).fontWeight(FontWeight.Bold)
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(18)))
                .fontColor($r('app.color.text_primary')).width('100%')

              NGFAccessibleButton({
              isElderly: this.a11yScale.isElderly,
                componentId: 'a11y_showcase_button',
                label: $r('app.string.a11y_demo_button'),
                description: $r('app.string.a11y_demo_button_desc'),
                minTouchTarget: this.tokens.minTouchTarget,
                onTap: (): void => {
                  this.logEvent($r('app.string.a11y_demo_button'));
                }
              })

              NGFAccessibleButton({
              isElderly: this.a11yScale.isElderly,
                componentId: 'a11y_announce_demo',
                label: $r('app.string.a11y_action_announce_status'),
                minTouchTarget: this.tokens.minTouchTarget,
                onTap: (): void => {
                  // 播报：画面变了但焦点没变时，读屏用户需要被主动告知
                  ngfAccessibilityFacade.announce({ text: $r('app.string.a11y_announce_demo') })
                    .then((): void => {
                      this.logEvent($r('app.string.a11y_action_announce_status'));
                    })
                    .catch((error: Error): void => {
                      logger.warn(TAG, '播报失败: ' + error.message);
                    });
                }
              })

              NGFAccessibleListItem({
              isElderly: this.a11yScale.isElderly,
                componentId: 'a11y_showcase_list_item',
                title: $r('app.string.a11y_demo_list_title'),
                stateText: $r('app.string.a11y_demo_list_state'),
                supportingText: $r('app.string.a11y_demo_list_support'),
                selected: true,
                minTouchTarget: this.tokens.minTouchTarget,
                onTap: (): void => {
                  this.logEvent($r('app.string.a11y_demo_list_title'));
                }
              })

              Row({ space: 12 }) {
                Text($r('app.string.a11y_demo_dialog_close'))
                  .fontSize(this.a11yScale.font(15)).fontColor($r('app.color.text_primary')).layoutWeight(1)
                  .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
                NGFAccessibleDialogCloseButton({
              isElderly: this.a11yScale.isElderly,
                  componentId: 'a11y_showcase_dialog_close',
                  closePosition: NGFDialogClosePosition.TOP_RIGHT,
                  label: $r('app.string.a11y_demo_dialog_close'),
                  minTouchTarget: this.tokens.dialogCloseTarget,
                  onClose: (): void => {
                    this.logEvent($r('app.string.a11y_demo_dialog_close'));
                  }
                })
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor($r('app.color.glass_chip_overlay'))
            .borderRadius(16)

            // ── 5. 表单字段（不分组方案） ────────────────────────────────
            Column({ space: this.a11yScale.paragraphSpacing(12, 18) }) {
              Text($r('app.string.a11y_section_form'))
                .fontSize(this.a11yScale.font(18)).fontWeight(FontWeight.Bold)
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(18)))
                .fontColor($r('app.color.text_primary')).width('100%')
              Text($r('app.string.a11y_note_form_not_grouped'))
                .fontSize(this.a11yScale.font(13)).fontColor($r('app.color.text_secondary')).width('100%')
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))

              NGFAccessibleFormField({
              isElderly: this.a11yScale.isElderly,
                componentId: 'a11y_showcase_field',
                label: $r('app.string.a11y_demo_field_label'),
                requiredMarker: $r('app.string.a11y_demo_field_required'),
                isRequired: true,
                errorText: this.fieldHasError ? $r('app.string.a11y_demo_field_error') : undefined,
                errorPrefix: this.fieldHasError ? $r('app.string.a11y_demo_field_error_prefix') : undefined,
                helpText: this.fieldHasError ? undefined : $r('app.string.a11y_demo_field_help'),
                isEnabled: true,
                minTouchTarget: this.tokens.minTouchTarget,
                // 已把语义绑到输入框上，所以标签节点从无障碍树移除以避免重复朗读
                hideLabelWhenBound: true
              }) {
                this.buildFieldInput()
              }

              NGFAccessibleButton({
              isElderly: this.a11yScale.isElderly,
                componentId: 'a11y_toggle_field_error',
                label: $r('app.string.a11y_action_toggle_field_error'),
                minTouchTarget: this.tokens.minTouchTarget,
                onTap: (): void => {
                  this.fieldHasError = !this.fieldHasError;
                }
              })
            }
            .width('100%')
            .padding(16)
            .backgroundColor($r('app.color.glass_chip_overlay'))
            .borderRadius(16)

            // ── 6. 语义审计 ──────────────────────────────────────────────
            Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
              Text($r('app.string.a11y_section_audit'))
                .fontSize(this.a11yScale.font(18)).fontWeight(FontWeight.Bold)
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(18)))
                .fontColor($r('app.color.text_primary')).width('100%')
              Text(this.auditAllPassed()
                ? $r('app.string.a11y_audit_pass')
                : $r('app.string.a11y_audit_issues', this.formatNumber(this.auditIssueCount())))
                .fontSize(this.a11yScale.font(15)).fontColor($r('app.color.text_primary')).width('100%')
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(15)))
            }
            .width('100%')
            .padding(16)
            .backgroundColor($r('app.color.glass_chip_overlay'))
            .borderRadius(16)

            // ── 6. 验证日志 ──────────────────────────────────────────────
            Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
              Text($r('app.string.a11y_log_prefix'))
                .fontSize(this.a11yScale.font(18)).fontWeight(FontWeight.Bold)
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(18)))
                .fontColor($r('app.color.text_primary')).width('100%')
              if (this.logLines.length === 0) {
                Text($r('app.string.a11y_log_empty'))
                  .fontSize(this.a11yScale.font(14)).fontColor($r('app.color.text_secondary')).width('100%')
                  .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
              } else {
                ForEach(this.logLines, (line: string): void => {
                  Text(line)
                    .fontSize(this.a11yScale.font(14)).fontColor($r('app.color.text_secondary')).width('100%')
                    .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
                })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor($r('app.color.glass_chip_overlay'))
            .borderRadius(16)

          }
          .width('100%')
          .padding({ left: 16, right: 16, top: this.topInsetVp, bottom: 76 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.SELF_FIRST })
      }
      .width('100%')
      .height('100%')
    }
    .titleBar(NGFHdsTitleBarOptionsFactory.build(
      $r('app.string.a11y_showcase_title'),
      $r('app.string.a11y_showcase_subtitle'),
      // 标题栏文字由工厂硬编码为白色，底色必须深色或透明。
      // 原先传 background_primary（浅色 #F3F7FB）→ 白字压浅底，实测不可读。
      Color.Transparent,
      hdsMaterial.MaterialLevel.EXQUISITE,
      true,
      false,
      // HDS 标题无障碍只能经 content.title 下发，见 NGFHdsTitleBarAccessibilityConfig
      {
        mainTitleAccessibilityText: $r('app.string.a11y_showcase_title'),
        subTitleAccessibilityText: $r('app.string.a11y_showcase_subtitle'),
        mainTitleId: 'a11y_showcase_title_node'
      }
    ))
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_primary'))
  }
}
