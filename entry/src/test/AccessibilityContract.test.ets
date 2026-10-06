import { describe, it, expect } from '@ohos/hypium';
import {
  NGFAccessibilityAction,
  NGFAccessibilityLevel,
  NGFAccessibilityRole,
  NGFAccessibilitySemantics,
  NGFAccessibilitySemanticsIssueCode,
  NGFAccessibilitySemanticsAudit,
  NGFAccessibilityStateSnapshot,
  NGFAccessibilityState,
  NGFTouchMode,
  NGFContrastPolicy,
  NGFDensityPolicy,
  NGFInclusiveDesignMetrics,
  NGF_APP_FONT_SIZE_MAX_SCALE,
  NGF_ELDERLY_MODE_ALIASES_ZH,
  NGF_ELDERLY_MODE_ALL_KEYWORDS_ZH,
  NGF_ELDERLY_MODE_STANDARD_NAME_ZH,
  matchesElderlyModeKeyword,
  isElderlyModeSearchHit,
  filterElderlyModeKeywords,
  NGFAnnouncementMode,
  NGFAnnouncementRequest,
  resolveAnnouncementEventType,
  isAnnouncementDeliverable,
  NGF_INCLUSIVE_DESIGN_METRICS,
  NGFInclusiveDesignPolicy,
  NGFMotionPolicy,
  NGFTextScalePolicy,
  NGFTouchTargetPolicy,
  NGFUiContext,
  auditAccessibilitySemantics,
  ngfAccessibilityFacade,
  parseContrastPolicy,
  parseDensityPolicy,
  parseMotionPolicy,
  parseTextScalePolicy,
  parseTouchTargetPolicy,
  resolveAccessibilityAttributes,
  resolveInclusiveDesignPolicy,
  resolveA11ySignalSource,
  NGFA11ySignalSource,
  NGFA11yTextScale,
  resolveA11yTextScale,
  a11yTouchTarget,
  NGFA11yModifierSet,
  NGFA11yTextModifier,
  NGFA11yButtonModifier,
  NGFA11yToggleModifier,
  NGFA11ySymbolModifier,
  resolveInclusiveDesignTokens,
  resolveRequiredBodyFontDp,
  resolveRequiredTouchTargetDp,
  resolveUiContextForPolicy,
  NGFAccessibilityResolvedAttributes,
  NGFAccessibilityUnresolvedKind,
  NGFAccessibilityBindingListener,
  NGFAccessibilityCustomAction,
  NGFAccessibilityLifecycleBinding,
  NGFFormFieldSemanticsConfig,
  buildFormFieldSemantics,
  NGFInclusiveDesignPolicyListener,
  NGFInclusiveDesignResolved,
  NGFInclusiveDesignTokens,
  NGFDialogClosePosition,
  NGF_DIALOG_CLOSE_ALLOWED_POSITIONS,
  NGF_MAX_GESTURE_FINGER_COUNT,
  isDialogClosePositionAllowed,
  isGestureFingerCountAllowed,
  calculateContrastRatio,
  checkNonTextContrast,
  checkTextContrast,
  compositeOver,
  linearizeChannel,
  parseHexAlpha,
  parseHexColor,
  relativeLuminance,
  requiredContrastRatio,
  NGF_LARGE_TEXT_FONT_DP,
  NGF_SRGB_LINEAR_THRESHOLD,
  NGF_SRGB_LINEAR_THRESHOLD_LEGACY,
  NGFColorRgb,
  NGFContrastCheckResult
} from 'ngf_framework';

function hasIssue(audit: NGFAccessibilitySemanticsAudit, code: NGFAccessibilitySemanticsIssueCode): boolean {
  for (let i: number = 0; i < audit.issues.length; i++) {
    if (audit.issues[i].code === code) {
      return true;
    }
  }
  return false;
}

/** 记录绑定器实际收到的策略回调，用于验证订阅/取消是否真的生效 */
class BindingObserver implements NGFAccessibilityBindingListener {
  private readonly sink: Array<NGFInclusiveDesignPolicy>;

  readonly onInclusiveDesignChanged: (resolved: NGFInclusiveDesignResolved) => void =
    (resolved: NGFInclusiveDesignResolved): void => {
      this.sink.push(resolved.policy);
    };

  readonly onAccessibilityStateChanged: (snapshot: NGFAccessibilityStateSnapshot) => void =
    (snapshot: NGFAccessibilityStateSnapshot): void => {
      // 本用例只关心策略通道，状态通道留空
    };

  constructor(sink: Array<NGFInclusiveDesignPolicy>) {
    this.sink = sink;
  }
}

/** 浮点近似比较；比断言精确相等更稳，失败时也能从数值看出偏差 */
function closeEnough(actual: number, expected: number, tolerance: number): boolean {
  return Math.abs(actual - expected) <= tolerance;
}

export default function accessibilityContractTest() {
  describe('AccessibilityContractTest', () => {

    // ------------------------------------------------------------------
    // 语义审计
    // ------------------------------------------------------------------

    it('testAuditPassesForCompleteButton', 0, () => {
      const semantics: NGFAccessibilitySemantics = {
        id: 'submit_btn',
        role: NGFAccessibilityRole.BUTTON,
        label: 'Submit',
        actions: [NGFAccessibilityAction.CLICK]
      };
      const audit: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(semantics);
      expect(audit.valid).assertTrue();
      expect(audit.issues.length).assertEqual(0);
    });

    it('testAuditFlagsInteractiveWithoutLabel', 0, () => {
      const semantics: NGFAccessibilitySemantics = {
        id: 'submit_btn',
        role: NGFAccessibilityRole.BUTTON,
        actions: [NGFAccessibilityAction.CLICK]
      };
      const audit: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(semantics);
      expect(audit.valid).assertFalse();
      expect(hasIssue(audit, NGFAccessibilitySemanticsIssueCode.MISSING_LABEL)).assertTrue();
    });

    it('testAuditFlagsInteractiveWithoutAction', 0, () => {
      const semantics: NGFAccessibilitySemantics = {
        id: 'submit_btn',
        role: NGFAccessibilityRole.BUTTON,
        label: 'Submit'
      };
      const audit: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(semantics);
      expect(hasIssue(audit, NGFAccessibilitySemanticsIssueCode.INTERACTIVE_WITHOUT_ACTION)).assertTrue();
    });

    it('testAuditFlagsEmptyId', 0, () => {
      const semantics: NGFAccessibilitySemantics = {
        id: '',
        role: NGFAccessibilityRole.TEXT,
        label: 'Hello'
      };
      const audit: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(semantics);
      expect(hasIssue(audit, NGFAccessibilitySemanticsIssueCode.EMPTY_ID)).assertTrue();
    });

    it('testAuditFlagsCheckedOnNonCheckableRole', 0, () => {
      const semantics: NGFAccessibilitySemantics = {
        id: 'label_1',
        role: NGFAccessibilityRole.TEXT,
        label: 'Hello',
        state: { checked: true }
      };
      const audit: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(semantics);
      expect(hasIssue(audit, NGFAccessibilitySemanticsIssueCode.STATE_ROLE_MISMATCH)).assertTrue();
    });

    it('testAuditAcceptsCheckedOnCheckbox', 0, () => {
      const semantics: NGFAccessibilitySemantics = {
        id: 'agree_box',
        role: NGFAccessibilityRole.CHECKBOX,
        label: 'Agree',
        actions: [NGFAccessibilityAction.CLICK],
        state: { checked: true }
      };
      const audit: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(semantics);
      expect(audit.valid).assertTrue();
    });

    it('testAuditFlagsDecorativeWithLabel', 0, () => {
      const semantics: NGFAccessibilitySemantics = {
        id: 'bg_decoration',
        role: NGFAccessibilityRole.IMAGE,
        label: 'should not be announced',
        level: NGFAccessibilityLevel.NO
      };
      const audit: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(semantics);
      expect(hasIssue(audit, NGFAccessibilitySemanticsIssueCode.DECORATIVE_WITH_LABEL)).assertTrue();
    });

    it('testAuditFlagsSelfTraversalNextId', 0, () => {
      const semantics: NGFAccessibilitySemantics = {
        id: 'self_ref',
        role: NGFAccessibilityRole.TEXT,
        label: 'Hello',
        traversalNextId: 'self_ref'
      };
      const audit: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(semantics);
      expect(hasIssue(audit, NGFAccessibilitySemanticsIssueCode.SELF_TRAVERSAL_NEXT_ID)).assertTrue();
    });

    // ------------------------------------------------------------------
    // 策略推导
    // ------------------------------------------------------------------

    it('testPolicyDefaultsWithoutSignals', 0, () => {
      const policy: NGFInclusiveDesignPolicy = resolveInclusiveDesignPolicy({
        animationReduceEnabled: false,
        seniorModeEnabled: false,
        systemFontScale: 1,
      });
      expect(policy.textScale).assertEqual(NGFTextScalePolicy.SYSTEM);
      expect(policy.touchTarget).assertEqual(NGFTouchTargetPolicy.STANDARD);
      expect(policy.contrast).assertEqual(NGFContrastPolicy.STANDARD);
      expect(policy.motion).assertEqual(NGFMotionPolicy.FULL);
      expect(policy.density).assertEqual(NGFDensityPolicy.STANDARD);
    });

    it('testPolicySeniorModeRaisesTiers', 0, () => {
      const policy: NGFInclusiveDesignPolicy = resolveInclusiveDesignPolicy({
        animationReduceEnabled: false,
        seniorModeEnabled: true,
        systemFontScale: 1,
      });
      expect(policy.textScale).assertEqual(NGFTextScalePolicy.ENHANCED);
      expect(policy.touchTarget).assertEqual(NGFTouchTargetPolicy.LARGE);
      expect(policy.contrast).assertEqual(NGFContrastPolicy.ENHANCED);
      expect(policy.density).assertEqual(NGFDensityPolicy.ELDERLY);
      expect(policy.motion).assertEqual(NGFMotionPolicy.FULL);
    });

    // ------------------------------------------------------------------
    // 双适老信号（PR-011）：关怀模式 与 系统字体缩放 相互独立
    // ------------------------------------------------------------------

    it('testFontScaleAloneRaisesElderlyTiers', 0, () => {
      // 用户只调大了系统字体、没开关怀模式 —— 同样必须进入适老档，
      // 否则会出现「字变大了、按钮没变大」。
      const policy: NGFInclusiveDesignPolicy = resolveInclusiveDesignPolicy({
        animationReduceEnabled: false,
        seniorModeEnabled: false,
        systemFontScale: 1.75
      });
      expect(policy.density).assertEqual(NGFDensityPolicy.ELDERLY);
      expect(policy.touchTarget).assertEqual(NGFTouchTargetPolicy.LARGE);
      expect(policy.textScale).assertEqual(NGFTextScalePolicy.ENHANCED);
    });

    it('testFontScaleOfOneIsNotElderly', 0, () => {
      const policy: NGFInclusiveDesignPolicy = resolveInclusiveDesignPolicy({
        animationReduceEnabled: false,
        seniorModeEnabled: false,
        systemFontScale: 1
      });
      expect(policy.density).assertEqual(NGFDensityPolicy.STANDARD);
    });

    it('testSignalSourceDistinguishesCareModeFromFontScale', 0, () => {
      // 关键区别：字体缩放时字号已被系统按 fp 放大过，**不应再抬一次**（双重放大）；
      // 关怀模式时系统不会放大，必须由我们抬到 §1.1 的 18 dp。
      const byCareMode: NGFA11ySignalSource = resolveA11ySignalSource({
        animationReduceEnabled: false,
        seniorModeEnabled: true,
        systemFontScale: 1
      });
      expect(byCareMode.isElderly).assertTrue();
      expect(byCareMode.boostFont).assertTrue();

      const byFontScale: NGFA11ySignalSource = resolveA11ySignalSource({
        animationReduceEnabled: false,
        seniorModeEnabled: false,
        systemFontScale: 1.75
      });
      expect(byFontScale.isElderly).assertTrue();
      expect(byFontScale.boostFont).assertFalse();
      expect(byFontScale.systemFontScale).assertEqual(1.75);
    });

    it('testScaleSuppressesFontBoostForFontScaleOnly', 0, () => {
      const scale: NGFA11yTextScale = resolveA11yTextScale(
        resolveInclusiveDesignPolicy({
          animationReduceEnabled: false,
          seniorModeEnabled: false,
          systemFontScale: 2
        }),
        resolveA11ySignalSource({
          animationReduceEnabled: false,
          seniorModeEnabled: false,
          systemFontScale: 2
        })
      );
      expect(scale.isElderly).assertTrue();
      expect(scale.font(14)).assertEqual(14);          // 不双重放大（系统已按 fp 放大）
      expect(scale.lineHeight(18)).assertEqual(23.4);  // 行距仍按 §1.2 补
      expect(a11yTouchTarget(scale.isElderly, 40)).assertEqual(60);
    });

    it('testCareModePlusFontScaleDoesNotDoubleBoost', 0, () => {
      // 🔴 回归用例：关怀模式 ON **且** 系统字体也放大时，**不能**双重放大。
      // 系统已按 fp 放大过，我们再抬就是 18 × 1.75 = 31.5，版式会炸。
      const both: NGFA11ySignalSource = resolveA11ySignalSource({
        animationReduceEnabled: false,
        seniorModeEnabled: true,
        systemFontScale: 1.75
      });
      expect(both.isElderly).assertTrue();
      expect(both.boostFont).assertFalse();   // ← 关键：不抬
      expect(both.fromCareMode).assertTrue();
      expect(both.fromFontScale).assertTrue();
    });

    it('testScaleBoostsFontForCareMode', 0, () => {
      const scale: NGFA11yTextScale = resolveA11yTextScale(
        resolveInclusiveDesignPolicy({
          animationReduceEnabled: false,
          seniorModeEnabled: true,
          systemFontScale: 1
        }),
        resolveA11ySignalSource({
          animationReduceEnabled: false,
          seniorModeEnabled: true,
          systemFontScale: 1
        })
      );
      expect(scale.boostFont).assertTrue();
      expect(scale.font(14)).assertEqual(18);  // §1.1 抬到 18
    });

    // ------------------------------------------------------------------
    // 适老属性修饰器框架：让任意基础组件一行接入
    // ------------------------------------------------------------------

    it('testModifierSetTextAppliesFontAndLineHeight', 0, () => {
      const elderly: NGFA11yModifierSet = new NGFA11yModifierSet(
        new NGFA11yTextScale(true, true, 1, true, false));
      const m: NGFA11yTextModifier = elderly.text(14);
      expect(m.fontSizeVp).assertEqual(18);        // §1.1 抬到 18
      expect(m.lineHeightVp).assertEqual(23.4);    // §1.2 行距 1.3 倍
    });

    it('testModifierSetTextIsTransparentInStandardMode', 0, () => {
      const standard: NGFA11yModifierSet = new NGFA11yModifierSet(
        new NGFA11yTextScale(false, false, 1, false, false));
      const m: NGFA11yTextModifier = standard.text(14);
      expect(m.fontSizeVp).assertEqual(14);  // 原样
      expect(m.lineHeightVp).assertEqual(0); // 0 = 随字号自适应（默认行为）
    });

    it('testModifierSetButtonRaisesTouchTarget', 0, () => {
      const elderly: NGFA11yModifierSet = new NGFA11yModifierSet(
        new NGFA11yTextScale(true, true, 1, true, false));
      const m: NGFA11yButtonModifier = elderly.button(14, 40);
      expect(m.fontSizeVp).assertEqual(18);
      expect(m.touchTargetVp).assertEqual(60);  // §2.1 适老 ≥60

      const standard: NGFA11yModifierSet = new NGFA11yModifierSet(
        new NGFA11yTextScale(false, false, 1, false, false));
      expect(standard.button(14, 40).touchTargetVp).assertEqual(40);  // 普通档不抬
    });

    it('testModifierSetToggleAndIcon', 0, () => {
      const elderly: NGFA11yModifierSet = new NGFA11yModifierSet(
        new NGFA11yTextScale(true, true, 1, true, false));
      const t: NGFA11yToggleModifier = elderly.toggle(0);
      expect(t.touchTargetVp).assertEqual(60);
      const icon: NGFA11ySymbolModifier = elderly.icon(20);
      expect(icon.fontSizeVp).assertEqual(26);  // 图标按 1.3 倍
    });

    it('testModifierSetFontScaleOnlyDoesNotDoubleBoostFont', 0, () => {
      // 只调大系统字体的用户：字号不抬（系统已按 fp 放大），但点击区仍要补
      const fontScaleOnly: NGFA11yModifierSet = new NGFA11yModifierSet(
        new NGFA11yTextScale(true, false, 2, false, true));
      expect(fontScaleOnly.text(14).fontSizeVp).assertEqual(14);     // 不双重放大
      // 行高按**实际字号**算：14 × 1.3 = 18.2。
      // 该值是 fp，会随系统缩放一起再放大 → 实际比值仍是 1.3 ✓
      expect(fontScaleOnly.text(14).lineHeightVp).assertEqual(18.2);
      expect(fontScaleOnly.button(14, 40).touchTargetVp).assertEqual(60);  // §2.1 仍补
    });

    it('testPolicyAnimationReduceOnlyAffectsMotion', 0, () => {
      const policy: NGFInclusiveDesignPolicy = resolveInclusiveDesignPolicy({
        animationReduceEnabled: true,
        seniorModeEnabled: false,
        systemFontScale: 1,
      });
      expect(policy.motion).assertEqual(NGFMotionPolicy.REDUCED);
      expect(policy.textScale).assertEqual(NGFTextScalePolicy.SYSTEM);
      expect(policy.density).assertEqual(NGFDensityPolicy.STANDARD);
    });

    it('testUserPolicyOverridesSystemSignals', 0, () => {
      const userChoice: NGFInclusiveDesignPolicy = {
        textScale: NGFTextScalePolicy.STANDARD,
        touchTarget: NGFTouchTargetPolicy.STANDARD,
        contrast: NGFContrastPolicy.STANDARD,
        motion: NGFMotionPolicy.NONE,
        density: NGFDensityPolicy.STANDARD
      };
      const policy: NGFInclusiveDesignPolicy = resolveInclusiveDesignPolicy({
        userPolicy: userChoice,
        animationReduceEnabled: true,
        seniorModeEnabled: true,
        systemFontScale: 1,
      });
      expect(policy.motion).assertEqual(NGFMotionPolicy.NONE);
      expect(policy.density).assertEqual(NGFDensityPolicy.STANDARD);
      expect(policy.textScale).assertEqual(NGFTextScalePolicy.STANDARD);
    });

    it('testUiContextFollowsDensity', 0, () => {
      const elderly: NGFInclusiveDesignPolicy = {
        textScale: NGFTextScalePolicy.ENHANCED,
        touchTarget: NGFTouchTargetPolicy.LARGE,
        contrast: NGFContrastPolicy.ENHANCED,
        motion: NGFMotionPolicy.REDUCED,
        density: NGFDensityPolicy.ELDERLY
      };
      expect(resolveUiContextForPolicy(elderly)).assertEqual(NGFUiContext.ELDERLY_PAGE);
      const standard: NGFInclusiveDesignPolicy = resolveInclusiveDesignPolicy({
        animationReduceEnabled: false,
        seniorModeEnabled: false,
        systemFontScale: 1,
      });
      expect(resolveUiContextForPolicy(standard)).assertEqual(NGFUiContext.STANDARD_PAGE);
    });

    // ------------------------------------------------------------------
    // 官方规范数值（工信厅信管函〔2021〕67号 附件2 §2.1）
    // ------------------------------------------------------------------

    it('testTouchTargetMatchesOfficialStandard', 0, () => {
      expect(resolveRequiredTouchTargetDp(NGFUiContext.STANDARD_PAGE)).assertEqual(44);
      expect(resolveRequiredTouchTargetDp(NGFUiContext.ELDERLY_PAGE)).assertEqual(60);
      expect(resolveRequiredTouchTargetDp(NGFUiContext.STANDALONE_ELDERLY_HOME)).assertEqual(48);
    });

    it('testBodyFontMatchesOfficialStandard', 0, () => {
      expect(resolveRequiredBodyFontDp(NGFUiContext.ELDERLY_PAGE)).assertEqual(18);
      expect(resolveRequiredBodyFontDp(NGFUiContext.STANDALONE_ELDERLY_HOME)).assertEqual(18);
      // 普通页面规范未给下限，这里回落 NGF 自有基线 16
      expect(resolveRequiredBodyFontDp(NGFUiContext.STANDARD_PAGE)).assertEqual(16);
    });

    it('testMetricsCarryOfficialValues', 0, () => {
      const m: NGFInclusiveDesignMetrics = NGF_INCLUSIVE_DESIGN_METRICS;
      expect(m.supportedMaxFontDp).assertEqual(30);
      expect(m.minLineHeightRatio).assertEqual(1.3);
      expect(m.minParagraphSpacingRatio).assertEqual(1.3);
      expect(m.minTextContrastRatio).assertEqual(4.5);
      expect(m.minLargeTextContrastRatio).assertEqual(3);
      expect(m.dialogCloseTargetDp).assertEqual(44);
    });

    // ------------------------------------------------------------------
    // 持久化解析
    // ------------------------------------------------------------------

    it('testParsersAcceptValidValues', 0, () => {
      expect(parseTextScalePolicy('enhanced', NGFTextScalePolicy.SYSTEM)).assertEqual(NGFTextScalePolicy.ENHANCED);
      expect(parseTouchTargetPolicy('large', NGFTouchTargetPolicy.STANDARD)).assertEqual(NGFTouchTargetPolicy.LARGE);
      expect(parseContrastPolicy('enhanced', NGFContrastPolicy.STANDARD)).assertEqual(NGFContrastPolicy.ENHANCED);
      expect(parseMotionPolicy('none', NGFMotionPolicy.FULL)).assertEqual(NGFMotionPolicy.NONE);
      expect(parseDensityPolicy('elderly', NGFDensityPolicy.STANDARD)).assertEqual(NGFDensityPolicy.ELDERLY);
    });

    it('testParsersFallBackOnUnknownValues', 0, () => {
      expect(parseTextScalePolicy('garbage', NGFTextScalePolicy.SYSTEM)).assertEqual(NGFTextScalePolicy.SYSTEM);
      expect(parseTouchTargetPolicy('', NGFTouchTargetPolicy.STANDARD)).assertEqual(NGFTouchTargetPolicy.STANDARD);
      expect(parseMotionPolicy('fast', NGFMotionPolicy.REDUCED)).assertEqual(NGFMotionPolicy.REDUCED);
    });

    // ------------------------------------------------------------------
    // 属性解析（诚实边界）
    // ------------------------------------------------------------------

    it('testResolvedDefaultsLevelToAuto', 0, () => {
      const semantics: NGFAccessibilitySemantics = {
        id: 'title',
        role: NGFAccessibilityRole.TEXT,
        label: 'Title'
      };
      const resolved: NGFAccessibilityResolvedAttributes = resolveAccessibilityAttributes(semantics);
      expect(resolved.level).assertEqual(NGFAccessibilityLevel.AUTO);
      expect(resolved.unresolved.length).assertEqual(0);
    });

    it('testResolvedReportsSemanticsWithoutArkUiAttribute', 0, () => {
      const semantics: NGFAccessibilitySemantics = {
        id: 'row_1',
        role: NGFAccessibilityRole.LIST_ITEM,
        label: 'Row',
        value: '3 items',
        actions: [NGFAccessibilityAction.CLICK],
        traversalOrder: 2,
        state: { expanded: true, busy: false, enabled: true }
      };
      const resolved: NGFAccessibilityResolvedAttributes = resolveAccessibilityAttributes(semantics);
      let sawValue: boolean = false;
      let sawActions: boolean = false;
      let sawTraversal: boolean = false;
      let sawExpanded: boolean = false;
      let sawBusy: boolean = false;
      let sawEnabled: boolean = false;
      for (let i: number = 0; i < resolved.unresolved.length; i++) {
        const kind: NGFAccessibilityUnresolvedKind = resolved.unresolved[i].kind;
        if (kind === NGFAccessibilityUnresolvedKind.VALUE) { sawValue = true; }
        if (kind === NGFAccessibilityUnresolvedKind.ACTIONS) { sawActions = true; }
        if (kind === NGFAccessibilityUnresolvedKind.TRAVERSAL_ORDER) { sawTraversal = true; }
        if (kind === NGFAccessibilityUnresolvedKind.EXPANDED) { sawExpanded = true; }
        if (kind === NGFAccessibilityUnresolvedKind.BUSY) { sawBusy = true; }
        if (kind === NGFAccessibilityUnresolvedKind.ENABLED) { sawEnabled = true; }
      }
      expect(sawValue).assertTrue();
      expect(sawActions).assertTrue();
      expect(sawTraversal).assertTrue();
      expect(sawExpanded).assertTrue();
      expect(sawBusy).assertTrue();
      expect(sawEnabled).assertTrue();
    });

    it('testResolvedMapsStateAndFocus', 0, () => {
      const semantics: NGFAccessibilitySemantics = {
        id: 'opt_1',
        role: NGFAccessibilityRole.CHECKBOX,
        label: 'Option',
        traversalNextId: 'opt_2',
        defaultFocus: true,
        scrollTriggerable: false,
        state: { checked: true, selected: false }
      };
      const resolved: NGFAccessibilityResolvedAttributes = resolveAccessibilityAttributes(semantics);
      expect(resolved.checked).assertTrue();
      expect(resolved.selected).assertFalse();
      expect(resolved.nextFocusId).assertEqual('opt_2');
      expect(resolved.defaultFocus).assertTrue();
      expect(resolved.scrollTriggerable).assertFalse();
    });

    // ------------------------------------------------------------------
    // 快照契约（不依赖设备：只断言形状与字段独立性）
    // ------------------------------------------------------------------

    it('testSnapshotKeepsSignalsSeparate', 0, () => {
      const snapshot: NGFAccessibilityStateSnapshot = ngfAccessibilityFacade.getStateSnapshot();
      // 四个信号必须各自独立存在，不允许互相代替
      expect(snapshot.accessibilityEnabled !== undefined).assertTrue();
      expect(snapshot.screenReaderEnabled !== undefined).assertTrue();
      expect(snapshot.touchGuideEnabled !== undefined).assertTrue();
      expect(snapshot.touchMode !== undefined).assertTrue();
      expect(snapshot.updatedAt > 0).assertTrue();
      // 适老模式是异步 API，必须带 resolved 标记
      expect(snapshot.seniorModeResolved !== undefined).assertTrue();
    });

    it('testTouchModeEnumMatchesApiValues', 0, () => {
      expect(NGFTouchMode.SINGLE).assertEqual('singleTouchMode');
      expect(NGFTouchMode.DOUBLE).assertEqual('doubleTouchMode');
      expect(NGFTouchMode.NONE).assertEqual('none');
      expect(NGFAccessibilityState.ENABLED).assertEqual('enabled');
    });

    // ------------------------------------------------------------------
    // 设计令牌（把策略变成页面能用的数值）
    // ------------------------------------------------------------------

    it('testTokensFollowStandardPerContext', 0, () => {
      const policy: NGFInclusiveDesignPolicy = resolveInclusiveDesignPolicy({
        animationReduceEnabled: false,
        seniorModeEnabled: true,
        systemFontScale: 1,
      });

      const elderly: NGFInclusiveDesignTokens = resolveInclusiveDesignTokens({
        policy: policy,
        context: NGFUiContext.ELDERLY_PAGE
      });
      // 附件2 §1.1：适老版主要文字不小于 18 dp/pt
      expect(elderly.bodyFontSize).assertEqual(18);
      // 附件2 §2.1：适老版界面主要组件点击区不小于 60×60 dp/pt
      expect(elderly.minTouchTarget).assertEqual(60);
      // 附件2 §2.4：浮窗关闭键不小于 44×44 dp/pt
      expect(elderly.dialogCloseTarget).assertEqual(44);
      // 附件2 §1.1：最大字体不小于 30 dp/pt
      expect(elderly.maxSupportedFontSize).assertEqual(30);
      // 附件2 §1.2：行距 1.3 倍 → 18 × 1.3；段距 ≥ 行距 × 1.3
      expect(elderly.bodyLineHeight).assertEqual(23.4);
      expect(elderly.paragraphSpacing).assertEqual(30.42);
      // 附件2 §1.3：4.5:1，字号大于 18 时 3:1
      expect(elderly.textContrastRatio).assertEqual(4.5);
      expect(elderly.largeTextContrastRatio).assertEqual(3);
      // 附件2 §1.4：颜色不得是唯一区分手段
      expect(elderly.requireNonColorRedundancy).assertTrue();

      const standard: NGFInclusiveDesignTokens = resolveInclusiveDesignTokens({
        policy: policy,
        context: NGFUiContext.STANDARD_PAGE
      });
      expect(standard.bodyFontSize).assertEqual(16);
      expect(standard.minTouchTarget).assertEqual(44);

      const standalone: NGFInclusiveDesignTokens = resolveInclusiveDesignTokens({
        policy: policy,
        context: NGFUiContext.STANDALONE_ELDERLY_HOME
      });
      expect(standalone.bodyFontSize).assertEqual(18);
      expect(standalone.minTouchTarget).assertEqual(48);
    });

    it('testTokensRespectBaseFontFloor', 0, () => {
      const policy: NGFInclusiveDesignPolicy = resolveInclusiveDesignPolicy({
        animationReduceEnabled: false,
        seniorModeEnabled: false,
        systemFontScale: 1,
      });
      const larger: NGFInclusiveDesignTokens = resolveInclusiveDesignTokens({
        policy: policy,
        context: NGFUiContext.STANDARD_PAGE,
        baseBodyFontSize: 20
      });
      // 页面基准高于下限时保留页面基准，不强行压回
      expect(larger.bodyFontSize).assertEqual(20);

      const smaller: NGFInclusiveDesignTokens = resolveInclusiveDesignTokens({
        policy: policy,
        context: NGFUiContext.STANDARD_PAGE,
        baseBodyFontSize: 10
      });
      // 页面基准低于下限时抬到下限
      expect(smaller.bodyFontSize).assertEqual(16);
    });

    it('testTokensMotionDegradation', 0, () => {
      const full: NGFInclusiveDesignPolicy = resolveInclusiveDesignPolicy({
        animationReduceEnabled: false,
        seniorModeEnabled: false,
        systemFontScale: 1,
      });
      const fullTokens: NGFInclusiveDesignTokens = resolveInclusiveDesignTokens({
        policy: full,
        context: NGFUiContext.STANDARD_PAGE
      });
      expect(fullTokens.motionDurationScale).assertEqual(1);
      expect(fullTokens.allowDecorativeMotion).assertTrue();

      const reduced: NGFInclusiveDesignPolicy = resolveInclusiveDesignPolicy({
        animationReduceEnabled: true,
        seniorModeEnabled: false,
        systemFontScale: 1,
      });
      const reducedTokens: NGFInclusiveDesignTokens = resolveInclusiveDesignTokens({
        policy: reduced,
        context: NGFUiContext.STANDARD_PAGE
      });
      expect(reducedTokens.motionDurationScale).assertEqual(0.5);
      expect(reducedTokens.allowDecorativeMotion).assertFalse();

      const none: NGFInclusiveDesignPolicy = {
        textScale: NGFTextScalePolicy.SYSTEM,
        touchTarget: NGFTouchTargetPolicy.STANDARD,
        contrast: NGFContrastPolicy.STANDARD,
        motion: NGFMotionPolicy.NONE,
        density: NGFDensityPolicy.STANDARD
      };
      const noneTokens: NGFInclusiveDesignTokens = resolveInclusiveDesignTokens({
        policy: none,
        context: NGFUiContext.STANDARD_PAGE
      });
      expect(noneTokens.motionDurationScale).assertEqual(0);
      expect(noneTokens.allowDecorativeMotion).assertFalse();
    });

    it('testDialogClosePositionConstraintMatchesStandard', 0, () => {
      // 附件2 §2.4：只可在左上、右上、中央底部
      expect(NGF_DIALOG_CLOSE_ALLOWED_POSITIONS.length).assertEqual(3);
      expect(isDialogClosePositionAllowed(NGFDialogClosePosition.TOP_LEFT)).assertTrue();
      expect(isDialogClosePositionAllowed(NGFDialogClosePosition.TOP_RIGHT)).assertTrue();
      expect(isDialogClosePositionAllowed(NGFDialogClosePosition.BOTTOM_CENTER)).assertTrue();
    });

    it('testGestureFingerCountConstraintMatchesStandard', 0, () => {
      // 附件2 §2.2：避免需 3 个或以上手指才能完成的复杂手势
      expect(NGF_MAX_GESTURE_FINGER_COUNT).assertEqual(2);
      expect(isGestureFingerCountAllowed(1)).assertTrue();
      expect(isGestureFingerCountAllowed(2)).assertTrue();
      expect(isGestureFingerCountAllowed(3)).assertFalse();
      expect(isGestureFingerCountAllowed(0)).assertFalse();
    });

    // ------------------------------------------------------------------
    // 订阅生命周期绑定（官方要求 on/off 必须配对）
    // ------------------------------------------------------------------

    it('testFacadeNotifiesPolicyListenerDirectly', 0, () => {
      const received: Array<NGFInclusiveDesignPolicy> = [];
      const listener: NGFInclusiveDesignPolicyListener =
        (resolved: NGFInclusiveDesignResolved): void => {
          received.push(resolved.policy);
        };
      ngfAccessibilityFacade.addPolicyListener(listener);

      const elderly: NGFInclusiveDesignPolicy = {
        textScale: NGFTextScalePolicy.ENHANCED,
        touchTarget: NGFTouchTargetPolicy.LARGE,
        contrast: NGFContrastPolicy.ENHANCED,
        motion: NGFMotionPolicy.REDUCED,
        density: NGFDensityPolicy.ELDERLY
      };
      ngfAccessibilityFacade.setUserPolicy(elderly);
      const deliveredDirectly: number = received.length;

      ngfAccessibilityFacade.removePolicyListener(listener);
      ngfAccessibilityFacade.clearUserPolicy();
      expect(deliveredDirectly >= 1).assertTrue();
    });

    it('testLifecycleBindingIsIdempotentAndDelivers', 0, () => {
      const received: Array<NGFInclusiveDesignPolicy> = [];
      const binding: NGFAccessibilityLifecycleBinding =
        new NGFAccessibilityLifecycleBinding(new BindingObserver(received));

      expect(binding.isAttached()).assertFalse();
      binding.attach();
      expect(binding.isAttached()).assertTrue();
      // 幂等：重复 attach 不应重复注册
      binding.attach();
      expect(binding.isAttached()).assertTrue();

      const elderly: NGFInclusiveDesignPolicy = {
        textScale: NGFTextScalePolicy.ENHANCED,
        touchTarget: NGFTouchTargetPolicy.LARGE,
        contrast: NGFContrastPolicy.ENHANCED,
        motion: NGFMotionPolicy.REDUCED,
        density: NGFDensityPolicy.ELDERLY
      };
      ngfAccessibilityFacade.setUserPolicy(elderly);
      expect(received.length >= 1).assertTrue();
      expect(ngfAccessibilityFacade.getPolicy().density).assertEqual(NGFDensityPolicy.ELDERLY);

      const afterAttach: number = received.length;
      binding.detach();
      expect(binding.isAttached()).assertFalse();
      // 幂等：重复 detach 不应报错，也不应误取消别人的监听
      binding.detach();
      expect(binding.isAttached()).assertFalse();

      // 取消订阅后不得再收到回调
      ngfAccessibilityFacade.clearUserPolicy();
      expect(received.length).assertEqual(afterAttach);
      // 清理全局状态，避免影响后续用例
      ngfAccessibilityFacade.clearUserPolicy();
    });

    // ------------------------------------------------------------------
    // 对比度核验（附件2 §1.3 阈值 + WCAG 相对亮度公式）
    // ------------------------------------------------------------------

    it('testLuminanceMatchesWcagCoefficients', 0, () => {
      const white: NGFColorRgb = { r: 255, g: 255, b: 255 };
      const black: NGFColorRgb = { r: 0, g: 0, b: 0 };
      const red: NGFColorRgb = { r: 255, g: 0, b: 0 };
      const green: NGFColorRgb = { r: 0, g: 255, b: 0 };
      const blue: NGFColorRgb = { r: 0, g: 0, b: 255 };

      // 白 = 1，黑 = 0
      expect(closeEnough(relativeLuminance(white), 1, 0.000001)).assertTrue();
      expect(closeEnough(relativeLuminance(black), 0, 0.000001)).assertTrue();
      // 纯色通道直接等于 WCAG 系数 0.2126 / 0.7152 / 0.0722
      expect(closeEnough(relativeLuminance(red), 0.2126, 0.000001)).assertTrue();
      expect(closeEnough(relativeLuminance(green), 0.7152, 0.000001)).assertTrue();
      expect(closeEnough(relativeLuminance(blue), 0.0722, 0.000001)).assertTrue();
    });

    it('testContrastRatioExtremesAndSymmetry', 0, () => {
      const white: NGFColorRgb = { r: 255, g: 255, b: 255 };
      const black: NGFColorRgb = { r: 0, g: 0, b: 0 };
      const gray: NGFColorRgb = { r: 136, g: 136, b: 136 };

      // 黑白对比度恒为 21:1（(1+0.05)/(0+0.05)）
      expect(closeEnough(calculateContrastRatio(white, black), 21, 0.000001)).assertTrue();
      // 同色恒为 1:1
      expect(closeEnough(calculateContrastRatio(gray, gray), 1, 0.000001)).assertTrue();
      // 对称
      expect(closeEnough(calculateContrastRatio(white, gray), calculateContrastRatio(gray, white), 0.0000001))
        .assertTrue();
    });

    it('testHexColorParsingRejectsInvalidInput', 0, () => {
      const full: NGFColorRgb | undefined = parseHexColor('#FFFFFF');
      expect(full !== undefined).assertTrue();
      if (full !== undefined) {
        expect(full.r).assertEqual(255);
        expect(full.g).assertEqual(255);
        expect(full.b).assertEqual(255);
      }

      const short: NGFColorRgb | undefined = parseHexColor('#000');
      expect(short !== undefined).assertTrue();
      if (short !== undefined) {
        expect(short.r).assertEqual(0);
        expect(short.b).assertEqual(0);
      }

      const noHash: NGFColorRgb | undefined = parseHexColor('3B82F6');
      expect(noHash !== undefined).assertTrue();
      if (noHash !== undefined) {
        expect(noHash.r).assertEqual(59);
        expect(noHash.g).assertEqual(130);
        expect(noHash.b).assertEqual(246);
      }

      // 非法输入必须返回 undefined，不能静默兜底成黑色
      expect(parseHexColor('#GGGGGG') === undefined).assertTrue();
      expect(parseHexColor('#FFFF') === undefined).assertTrue();
      expect(parseHexColor('') === undefined).assertTrue();
    });

    it('testRequiredContrastFollowsStandardClause13', 0, () => {
      // 附件2 §1.3：至少 4.5:1；字号**大于** 18 时放宽到 3:1
      expect(NGF_LARGE_TEXT_FONT_DP).assertEqual(18);
      expect(requiredContrastRatio(16)).assertEqual(4.5);
      expect(requiredContrastRatio(18)).assertEqual(4.5);
      expect(requiredContrastRatio(19)).assertEqual(3);
      expect(requiredContrastRatio(30)).assertEqual(3);
    });

    it('testTextContrastCheckUsesBothThresholds', 0, () => {
      const white: NGFColorRgb = { r: 255, g: 255, b: 255 };
      const black: NGFColorRgb = { r: 0, g: 0, b: 0 };
      // #888888 在白底上约 3.54:1
      const gray888: NGFColorRgb = { r: 136, g: 136, b: 136 };

      expect(checkTextContrast(black, white, 16).passed).assertTrue();
      expect(checkTextContrast(black, black, 16).passed).assertFalse();
      // 同一组颜色：普通字号不达标，大字号达标 —— 正好验证两档阈值
      expect(checkTextContrast(gray888, white, 16).passed).assertFalse();
      expect(checkTextContrast(gray888, white, 19).passed).assertTrue();

      const result: NGFContrastCheckResult = checkTextContrast(gray888, white, 16);
      expect(result.required).assertEqual(4.5);
      // 期望值在测试内**按公式独立重算**，不写手算常数 ——
      // 手算的 3.5425 与实现真实值相差约 0.003，曾导致误报。
      const expectedLuminance: number = Math.pow((136 / 255 + 0.055) / 1.055, 2.4);
      const expectedRatio: number = 1.05 / (expectedLuminance + 0.05);
      expect(closeEnough(result.ratio, expectedRatio, 1e-9)).assertTrue();
      // 并确认它确实落在 3:1 与 4.5:1 之间，两档阈值才有区分意义
      expect(result.ratio > 3 && result.ratio < 4.5).assertTrue();
    });

    it('testNonTextContrastUsesNgfBaseline', 0, () => {
      const white: NGFColorRgb = { r: 255, g: 255, b: 255 };
      const black: NGFColorRgb = { r: 0, g: 0, b: 0 };
      const result: NGFContrastCheckResult = checkNonTextContrast(white, black);
      expect(result.required).assertEqual(3);
      expect(result.passed).assertTrue();
    });

    it('testSrgbThresholdDiscrepancyIsImmaterialFor8Bit', 0, () => {
      // 两个 W3C 来源的分段阈值不同（0.03928 vs 0.04045）。
      // 穷举 256 个 8bit 通道值证明：对 8bit 输入两者结果完全一致，
      // 因为 (0.03928*255, 0.04045*255) = (10.0164, 10.3114) 内没有整数。
      expect(NGF_SRGB_LINEAR_THRESHOLD).assertEqual(0.04045);
      expect(NGF_SRGB_LINEAR_THRESHOLD_LEGACY).assertEqual(0.03928);

      let mismatches: number = 0;
      for (let v: number = 0; v < 256; v++) {
        const current: number = linearizeChannel(v, NGF_SRGB_LINEAR_THRESHOLD);
        const legacy: number = linearizeChannel(v, NGF_SRGB_LINEAR_THRESHOLD_LEGACY);
        if (Math.abs(current - legacy) > 1e-12) {
          mismatches++;
        }
      }
      expect(mismatches).assertEqual(0);
    });

    // ------------------------------------------------------------------
    // API 26 自定义无障碍动作 + API 23 滚动步长（证据复核后补齐）
    // ------------------------------------------------------------------

    it('testCustomActionsSatisfyInteractiveActionRequirement', 0, () => {
      const custom: Array<NGFAccessibilityCustomAction> = [
        { name: '标记已读', onAction: (): void => {} }
      ];
      // 只挂自定义动作、没有词表内动作，也必须被认为"有动作"
      const withCustom: NGFAccessibilitySemantics = {
        id: 'a11y_custom_only',
        role: NGFAccessibilityRole.BUTTON,
        label: '示例',
        customActions: custom
      };
      const auditCustom: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(withCustom);
      expect(auditCustom.valid).assertTrue();

      // 既无词表动作也无自定义动作 → 仍然报错
      const withoutAny: NGFAccessibilitySemantics = {
        id: 'a11y_no_action',
        role: NGFAccessibilityRole.BUTTON,
        label: '示例'
      };
      const auditNone: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(withoutAny);
      expect(auditNone.valid).assertFalse();
      expect(auditNone.issues[0].code)
        .assertEqual(NGFAccessibilitySemanticsIssueCode.INTERACTIVE_WITHOUT_ACTION);
    });

    it('testCustomActionWithoutNameIsFlagged', 0, () => {
      const semantics: NGFAccessibilitySemantics = {
        id: 'a11y_nameless_action',
        role: NGFAccessibilityRole.BUTTON,
        label: '示例',
        customActions: [{ name: '', onAction: (): void => {} }]
      };
      const audit: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(semantics);
      expect(audit.valid).assertFalse();
      let found: boolean = false;
      for (let i = 0; i < audit.issues.length; i++) {
        if (audit.issues[i].code === NGFAccessibilitySemanticsIssueCode.CUSTOM_ACTION_WITHOUT_NAME) {
          found = true;
        }
      }
      expect(found).assertTrue();
    });

    it('testInvalidScrollStepIsFlagged', 0, () => {
      const zero: NGFAccessibilitySemantics = {
        id: 'a11y_scroll_zero',
        role: NGFAccessibilityRole.SCROLL,
        scrollStep: 0
      };
      const auditZero: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(zero);
      expect(auditZero.valid).assertFalse();
      expect(auditZero.issues[0].code).assertEqual(NGFAccessibilitySemanticsIssueCode.INVALID_SCROLL_STEP);

      const negative: NGFAccessibilitySemantics = {
        id: 'a11y_scroll_negative',
        role: NGFAccessibilityRole.SCROLL,
        scrollStep: -8
      };
      expect(auditAccessibilitySemantics(negative).valid).assertFalse();

      const positive: NGFAccessibilitySemantics = {
        id: 'a11y_scroll_ok',
        role: NGFAccessibilityRole.SCROLL,
        scrollStep: 48
      };
      expect(auditAccessibilitySemantics(positive).valid).assertTrue();
    });

    it('testResolvedPassesCustomActionsAndScrollStepThrough', 0, () => {
      const custom: Array<NGFAccessibilityCustomAction> = [
        { name: '删除', onAction: (): void => {} },
        { name: '归档', onAction: (): void => {} }
      ];
      const semantics: NGFAccessibilitySemantics = {
        id: 'a11y_passthrough',
        role: NGFAccessibilityRole.LIST,
        customActions: custom,
        scrollStep: 64
      };
      const resolved: NGFAccessibilityResolvedAttributes = resolveAccessibilityAttributes(semantics);
      expect(resolved.customActions !== undefined).assertTrue();
      if (resolved.customActions !== undefined) {
        expect(resolved.customActions.length).assertEqual(2);
      }
      expect(resolved.scrollStep).assertEqual(64);
      // 这两个语义现在**可以**落到属性上，不应再出现在 unresolved 列表里
      expect(resolved.unresolved.length).assertEqual(0);
    });

    it('testTraversalConsiderDescendantsRequiresTarget', 0, () => {
      // 只设参数不设目标 → 参数不会生效，必须报错
      const orphan: NGFAccessibilitySemantics = {
        id: 'a11y_orphan_traversal',
        role: NGFAccessibilityRole.BUTTON,
        label: '示例',
        actions: [NGFAccessibilityAction.CLICK],
        traversalConsiderDescendants: true
      };
      const auditOrphan: NGFAccessibilitySemanticsAudit = auditAccessibilitySemantics(orphan);
      expect(auditOrphan.valid).assertFalse();
      expect(auditOrphan.issues[0].code)
        .assertEqual(NGFAccessibilitySemanticsIssueCode.ORPHAN_TRAVERSAL_PARAM);

      // 目标 + 参数一起给 → 通过，且两者都被透传
      const complete: NGFAccessibilitySemantics = {
        id: 'a11y_traversal_ok',
        role: NGFAccessibilityRole.BUTTON,
        label: '示例',
        actions: [NGFAccessibilityAction.CLICK],
        traversalNextId: 'a11y_next',
        traversalConsiderDescendants: true
      };
      expect(auditAccessibilitySemantics(complete).valid).assertTrue();
      const resolved: NGFAccessibilityResolvedAttributes = resolveAccessibilityAttributes(complete);
      expect(resolved.nextFocusId).assertEqual('a11y_next');
      expect(resolved.traversalConsiderDescendants).assertTrue();
    });

    // ------------------------------------------------------------------
    // 表单字段语义（不分组方案）
    // ------------------------------------------------------------------

    it('testFormFieldSemanticsDescriptionPriority', 0, () => {
      const full: NGFFormFieldSemanticsConfig = {
        id: 'field_full',
        label: '手机号',
        errorText: '格式不正确',
        helpText: '用于接收验证码',
        unit: '位',
        requiredMarker: '必填',
        enabled: true
      };
      // 错误最紧急，优先级最高
      expect(buildFormFieldSemantics(full).description).assertEqual('格式不正确');

      const noError: NGFFormFieldSemanticsConfig = {
        id: 'field_help', label: '手机号', helpText: '用于接收验证码', unit: '位',
        requiredMarker: '必填', enabled: true
      };
      expect(buildFormFieldSemantics(noError).description).assertEqual('用于接收验证码');

      const onlyUnit: NGFFormFieldSemanticsConfig = {
        id: 'field_unit', label: '身高', unit: '厘米', requiredMarker: '必填', enabled: true
      };
      expect(buildFormFieldSemantics(onlyUnit).description).assertEqual('厘米');

      // 必填优先级最低 —— 这是**已知取舍**，不是缺陷：必填信息应并入 label 资源文案
      const onlyRequired: NGFFormFieldSemanticsConfig = {
        id: 'field_required', label: '身高', requiredMarker: '必填', enabled: true
      };
      expect(buildFormFieldSemantics(onlyRequired).description).assertEqual('必填');
    });

    it('testFormFieldSemanticsOmitsActionWhenDisabled', 0, () => {
      const enabledField: NGFFormFieldSemanticsConfig = {
        id: 'field_on', label: '手机号', enabled: true
      };
      const enabledSemantics: NGFAccessibilitySemantics = buildFormFieldSemantics(enabledField);
      expect(enabledSemantics.role).assertEqual(NGFAccessibilityRole.TEXT_INPUT);
      expect(enabledSemantics.actions !== undefined && enabledSemantics.actions.length === 1).assertTrue();
      expect(auditAccessibilitySemantics(enabledSemantics).valid).assertTrue();

      const disabledField: NGFFormFieldSemanticsConfig = {
        id: 'field_off', label: '手机号', enabled: false
      };
      const disabledSemantics: NGFAccessibilitySemantics = buildFormFieldSemantics(disabledField);
      expect(disabledSemantics.actions === undefined).assertTrue();
      // 禁用的可操作控件没有动作是合理的，审计必须放过
      expect(auditAccessibilitySemantics(disabledSemantics).valid).assertTrue();
    });

    it('testDisabledInteractiveWithoutActionIsAccepted', 0, () => {
      // 通用规则：state.enabled === false 时不再要求声明动作
      const disabled: NGFAccessibilitySemantics = {
        id: 'a11y_disabled_button',
        role: NGFAccessibilityRole.BUTTON,
        label: '提交',
        state: { enabled: false }
      };
      expect(auditAccessibilitySemantics(disabled).valid).assertTrue();

      // 但"没声明 enabled 状态 + 没有动作"仍然要报
      const unspecified: NGFAccessibilitySemantics = {
        id: 'a11y_enabled_button',
        role: NGFAccessibilityRole.BUTTON,
        label: '提交'
      };
      expect(auditAccessibilitySemantics(unspecified).valid).assertFalse();
    });

    // ------------------------------------------------------------------
    // 应用字体缩放（适老化：让应用跟随系统字体大小）
    // ------------------------------------------------------------------

    it('testAppFontScaleSatisfiesRequiredMaxFont', 0, () => {
      const m: NGFInclusiveDesignMetrics = NGF_INCLUSIVE_DESIGN_METRICS;
      // 对应 configuration.json 里 fontSizeMaxScale 的枚举值 "2"
      expect(NGF_APP_FONT_SIZE_MAX_SCALE).assertEqual(2);

      // 不变式：规范要求的最大字体 <= 最小正文字号 × 应用字体倍率上限
      const reachable: number = m.ngfMinBodyFontVp * NGF_APP_FONT_SIZE_MAX_SCALE;
      expect(reachable >= m.supportedMaxFontDp).assertTrue();

      // 反过来证明"为什么不能选 1.75"：16 × 1.75 = 28 < 30，不满足附件2 §1.1
      expect(m.ngfMinBodyFontVp * 1.75 >= m.supportedMaxFontDp).assertFalse();
      // 也不该低于 1.875 这个理论下限
      expect(m.supportedMaxFontDp / m.ngfMinBodyFontVp > 1.75).assertTrue();
    });


    it('testEightDigitArgBColorIsParsedIgnoringAlpha', 0, () => {
      const parsed: NGFColorRgb | undefined = parseHexColor('#FFF8FAFC');
      expect(parsed !== undefined).assertTrue();
      if (parsed !== undefined) {
        expect(parsed.r).assertEqual(248);
        expect(parsed.g).assertEqual(250);
        expect(parsed.b).assertEqual(252);
      }
      // 六位写法应得到同一结果
      const six: NGFColorRgb | undefined = parseHexColor('#F8FAFC');
      expect(six !== undefined && parsed !== undefined && six.r === parsed.r && six.b === parsed.b).assertTrue();
    });

    it('testErrorTextTokenMeetsContrastInBothThemes', 0, () => {
      // 浅色主题：ngf_text_error #DC2626 在 ngf_background_surface #FFF8FAFC 上
      const lightFg: NGFColorRgb | undefined = parseHexColor('#DC2626');
      const lightBg: NGFColorRgb | undefined = parseHexColor('#FFF8FAFC');
      expect(lightFg !== undefined && lightBg !== undefined).assertTrue();
      if (lightFg !== undefined && lightBg !== undefined) {
        const light: NGFContrastCheckResult = checkTextContrast(lightFg, lightBg, 13);
        expect(light.required).assertEqual(4.5);
        expect(light.passed).assertTrue();
      }

      // 深色主题：ngf_text_error #F87171 在 ngf_background_surface #1E1E1E 上
      const darkFg: NGFColorRgb | undefined = parseHexColor('#F87171');
      const darkBg: NGFColorRgb | undefined = parseHexColor('#1E1E1E');
      expect(darkFg !== undefined && darkBg !== undefined).assertTrue();
      if (darkFg !== undefined && darkBg !== undefined) {
        const dark: NGFContrastCheckResult = checkTextContrast(darkFg, darkBg, 13);
        expect(dark.required).assertEqual(4.5);
        expect(dark.passed).assertTrue();
      }
    });

    // ------------------------------------------------------------------
    // 适老模式命名契约（附件2 §3.1）
    // ------------------------------------------------------------------

    it('testElderlyModeNamingMatchesStandardClause31', 0, () => {
      // 规范原文：标准功能名「长辈版」，别名「亲情版」「关爱版」「关怀版」
      expect(NGF_ELDERLY_MODE_STANDARD_NAME_ZH).assertEqual('长辈版');
      expect(NGF_ELDERLY_MODE_ALIASES_ZH.length).assertEqual(3);
      expect(NGF_ELDERLY_MODE_ALIASES_ZH[0]).assertEqual('亲情版');
      expect(NGF_ELDERLY_MODE_ALIASES_ZH[1]).assertEqual('关爱版');
      expect(NGF_ELDERLY_MODE_ALIASES_ZH[2]).assertEqual('关怀版');
      // 标准名必须在可匹配关键字里排第一
      expect(NGF_ELDERLY_MODE_ALL_KEYWORDS_ZH.length).assertEqual(4);
      expect(NGF_ELDERLY_MODE_ALL_KEYWORDS_ZH[0]).assertEqual(NGF_ELDERLY_MODE_STANDARD_NAME_ZH);
    });

    it('testElderlyModeKeywordMatching', 0, () => {
      expect(matchesElderlyModeKeyword('长辈版')).assertTrue();
      expect(matchesElderlyModeKeyword('亲情版')).assertTrue();
      expect(matchesElderlyModeKeyword('关爱版')).assertTrue();
      expect(matchesElderlyModeKeyword('关怀版')).assertTrue();
      // 去首尾空白后仍应命中
      expect(matchesElderlyModeKeyword('  长辈版  ')).assertTrue();
      // 非关键字
      expect(matchesElderlyModeKeyword('标准版')).assertFalse();
      expect(matchesElderlyModeKeyword('')).assertFalse();
      expect(matchesElderlyModeKeyword('   ')).assertFalse();
    });

    it('testElderlyModeSearchHitSupportsIncrementalTyping', 0, () => {
      // 用户逐字输入时应逐步命中
      expect(isElderlyModeSearchHit('长')).assertTrue();
      expect(isElderlyModeSearchHit('长辈')).assertTrue();
      expect(isElderlyModeSearchHit('长辈版')).assertTrue();
      // 别名同样可增量命中
      expect(isElderlyModeSearchHit('关')).assertTrue();
      expect(isElderlyModeSearchHit('亲情')).assertTrue();
      // 无关输入与空输入不命中
      expect(isElderlyModeSearchHit('下载')).assertFalse();
      expect(isElderlyModeSearchHit('')).assertFalse();
    });

    it('testFilterElderlyModeKeywordsKeepsOrderAndDropsOthers', 0, () => {
      const input: Array<string> = ['设置', '长辈版', '下载', '关怀版', '关于'];
      const matched: Array<string> = filterElderlyModeKeywords(input);
      expect(matched.length).assertEqual(2);
      expect(matched[0]).assertEqual('长辈版');
      expect(matched[1]).assertEqual('关怀版');
      // 空输入返回空数组，不应抛错
      expect(filterElderlyModeKeywords([]).length).assertEqual(0);
    });

    // ------------------------------------------------------------------
    // 播报契约（sendAccessibilityEvent @since 9）
    // ------------------------------------------------------------------

    it('testAnnouncementEventTypeMatchesSdkStrings', 0, () => {
      // 必须与 @ohos.accessibility 的 EventType 取值逐字一致，
      // 拼错不会编译报错，只会在运行时静默失败 —— 所以在这里钉死。
      expect(resolveAnnouncementEventType(NGFAnnouncementMode.INTERRUPT))
        .assertEqual('announceForAccessibility');
      expect(resolveAnnouncementEventType(NGFAnnouncementMode.QUEUE))
        .assertEqual('announceForAccessibilityNotInterrupt');
      // NGF 的模式名是语义名，与 SDK 取值拼写不同，两者不可混用
      expect(NGFAnnouncementMode.INTERRUPT).assertEqual('interrupt');
      expect(NGFAnnouncementMode.QUEUE).assertEqual('queue');
    });

    it('testAnnouncementDeliverability', 0, () => {
      expect(isAnnouncementDeliverable('已切换到长辈版')).assertTrue();
      expect(isAnnouncementDeliverable('  ok  ')).assertTrue();
      // 空/纯空白文本不发送事件 —— 空播报对读屏用户只是噪声
      expect(isAnnouncementDeliverable('')).assertFalse();
      expect(isAnnouncementDeliverable('   ')).assertFalse();
    });

    it('testAnnouncementRequestShape', 0, () => {
      // 文本可以是 string 或 Resource，两者走不同 SDK 字段
      const plain: NGFAnnouncementRequest = { text: '已完成' };
      expect(typeof plain.text === 'string').assertTrue();
      // mode / componentId 都是可选的
      expect(plain.mode === undefined).assertTrue();
      const queued: NGFAnnouncementRequest = {
        text: '已完成',
        mode: NGFAnnouncementMode.QUEUE,
        componentId: 'a11y_list'
      };
      expect(queued.mode).assertEqual(NGFAnnouncementMode.QUEUE);
      expect(queued.componentId).assertEqual('a11y_list');
    });

    it('testTranslucentSurfaceContrastAgainstWorstCaseBackdrops', 0, () => {
      // 真问题：NGF 的毛玻璃令牌是半透明的（glass_chip_overlay = #CCFFFFFF），
      // 对比度公式只对不透明颜色成立，所以**必须先把 alpha 取出来再合成**。
      const overlayAlpha: number = parseHexAlpha('#CCFFFFFF');
      expect(closeEnough(overlayAlpha, 0.8, 0.002)).assertTrue();
      // 6 位写法视为完全不透明
      expect(parseHexAlpha('#FFFFFF')).assertEqual(1);

      const overlay: NGFColorRgb | undefined = parseHexColor('#CCFFFFFF');
      const textPrimary: NGFColorRgb | undefined = parseHexColor('#1C2430');
      expect(overlay !== undefined && textPrimary !== undefined).assertTrue();
      if (overlay === undefined || textPrimary === undefined) {
        return;
      }

      // 背景可能是渐变/图片，所以对**最暗与最亮**两种最坏情况各算一次
      const black: NGFColorRgb = { r: 0, g: 0, b: 0 };
      const white: NGFColorRgb = { r: 255, g: 255, b: 255 };
      const overDark: NGFContrastCheckResult =
        checkTextContrast(textPrimary, compositeOver(overlay, overlayAlpha, black), 15);
      const overLight: NGFContrastCheckResult =
        checkTextContrast(textPrimary, compositeOver(overlay, overlayAlpha, white), 15);

      // 两种极端背景都要达标，才算这个毛玻璃表面安全
      expect(overDark.passed).assertTrue();
      expect(overLight.passed).assertTrue();
      // 并且把实际比值也钉住，防止将来改色后静默退化
      expect(overDark.ratio > 4.5).assertTrue();
      expect(overLight.ratio > 4.5).assertTrue();
    });

    it('testCompositeOverEdgeAlphas', 0, () => {
      const top: NGFColorRgb = { r: 204, g: 0, b: 0 };
      const bottom: NGFColorRgb = { r: 0, g: 0, b: 255 };
      // alpha=1 → 完全取上层
      const opaque: NGFColorRgb = compositeOver(top, 1, bottom);
      expect(opaque.r).assertEqual(204);
      expect(opaque.b).assertEqual(0);
      // alpha=0 → 完全取下层
      const transparent: NGFColorRgb = compositeOver(top, 0, bottom);
      expect(transparent.r).assertEqual(0);
      expect(transparent.b).assertEqual(255);
      // 越界 alpha 被夹紧，不应产生越界通道值
      const clamped: NGFColorRgb = compositeOver(top, 5, bottom);
      expect(clamped.r).assertEqual(204);
      const negative: NGFColorRgb = compositeOver(top, -1, bottom);
      expect(negative.b).assertEqual(255);
    });
  });
}
