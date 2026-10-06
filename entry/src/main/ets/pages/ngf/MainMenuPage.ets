import { hdsEffect, hdsMaterial, HdsNavigation, HdsNavigationTitleMode, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';
import window from '@ohos.window';
import { uiContextManager } from 'ngf_framework';
import { resolveResourceString } from 'ngf_framework';
import { NGFErrorContext, NGFErrorSeverity } from 'ngf_framework';
import { NGFEventPayload } from 'ngf_framework';
import { NGFLogLevel } from 'ngf_framework';
import { NGFPhaseState } from 'ngf_framework';
import { NGFControlStyleTokens } from 'ngf_framework';

import { NGFMaterialSheetOptions } from 'ngf_framework';
import { NGFMaterialSurfaceTokens } from 'ngf_framework';
import { ngfOverlayManagerFacade } from 'ngf_framework';
import { ngfVisualEffectsFacade } from 'ngf_framework';
import {
  NGFFrameworkRuntimeSnapshot,
  NGFModuleBootstrapReport,
  NGFModuleRuntimeSnapshot
} from 'ngf_framework';
import { ngfDeviceAdaptationFacade } from 'ngf_framework';
import { NGFRuntimeStatus, NGFAppThreadInfo } from 'ngf_framework';
import { NGFStarterEventName, ngfStarterKernel } from 'ngf_framework';
import { common } from '@kit.AbilityKit';
import { ngfPlatformWindowManagerFacade } from 'ngf_framework';
import { HdsIntegratedShowcasePage } from './HdsIntegratedShowcasePage';
import {
  HdsNavigationOfficialEffectPage,
  HdsNavigationOfficialMaterialPage,
  HdsNavigationOfficialOverviewPage,
  HdsNavigationOfficialShowcasePage
} from './HdsNavigationOfficialShowcasePage';
import { NGFHdsDemoRouteName } from './HdsDemoRoutes';
import { NGFHdsTitleBarOptionsFactory } from 'ngf_framework';
import { NGFPageWindowName, NGFPageWindowSupport } from './NGFPageWindowSupport';
import { NGFDeviceAwarenessPage } from './NGFDeviceAwarenessPage';
import { NGFSettingsPage } from './NGFSettingsPage';
import { NGFDemoSecurityPerfPage } from './NGFDemoSecurityPerfPage';
import { NGFDemoDataStoragePage } from './NGFDemoDataStoragePage';
import { NGFDemoWorkflowPage } from './NGFDemoWorkflowPage';
import { NGFDemoDeviceDisplayPage } from './NGFDemoDeviceDisplayPage';
import { NGFSystemResourcePreviewPage } from './SystemResourcePreviewPage';
import { NGFTaskManagerPage } from './NGFTaskManagerPage';
import { NGFAccessibilityShowcasePage } from './NGFAccessibilityShowcasePage';
import { getElderlyModeDisplayName } from 'ngf_framework';
// ── 适老呈现层（.rules/skill-elderly-ui.md）──────────────────────────────
// 同一页面 + 策略切换：**不复制页面**，功能与普通版天然一致。
import {
  NGFAccessibilityBindingListener,
  NGFAccessibilityLifecycleBinding,
  NGFAccessibilityStateSnapshot,
  NGFInclusiveDesignPolicy,
  NGFInclusiveDesignResolved,
  NGFInclusiveDesignTokens,
  NGFUiContext,
  NGFAccessibleDialogCloseButton,
  NGFDialogClosePosition,
  ngfAccessibilityFacade,
  resolveInclusiveDesignTokens,
  resolveUiContextForPolicy
} from 'ngf_framework';
import { NGFCapabilitiesTabContent } from './NGFCapabilitiesTabContent';
import { NGFCapabilitiesNetworkPage } from './NGFCapabilitiesNetworkPage';
import { NGFCapabilitiesDatabasePage } from './NGFCapabilitiesDatabasePage';
import { NGFCapabilitiesWebBridgePage } from './NGFCapabilitiesWebBridgePage';
import { NGFCapabilitiesSecurityPage } from './NGFCapabilitiesSecurityPage';
import { NGFCapabilitiesHardwarePage } from './NGFCapabilitiesHardwarePage';
import { NGFCapabilitiesMediaPage } from './NGFCapabilitiesMediaPage';
import { NGFDemoErrorRecoveryPage } from './NGFDemoErrorRecoveryPage';
import { NGFDemoSyncManagerPage } from './NGFDemoSyncManagerPage';

const TAG: string = 'NGFStarterMainMenuPage';
const NGF_MAIN_MENU_CONTENT_TOP_INSET: number = 112;
const NGF_MAIN_MENU_HEADER_HEIGHT: number = 356;
const NGF_MAIN_MENU_HEADER_CONTENT_TOP_PADDING: number = 54;

// ── 适老呈现层常量（.rules/skill-elderly-ui.md）──────────────────────────
/** 适老版主要文字下限（vp）—— 工信厅信管函〔2021〕67号 附件2 §1.1「不小于 18 dp/pt」 */
const NGF_MAIN_MENU_ELDERLY_MIN_FONT_VP: number = 18;
/** 行距倍数 —— 附件2 §1.2「段落内文字的行距至少为 1.3 倍」 */
const NGF_MAIN_MENU_LINE_HEIGHT_RATIO: number = 1.3;
/**
 * 适老版底部标签栏高度（vp）。
 * 附件2 §2.1：适老版界面主要组件点击区不小于 60×60；标签栏是最主要导航组件，
 * 默认 56 vp 高度下实测标签项仅约 48 vp，故适老档抬到 72 以保证 ≥60。
 */
const NGF_MAIN_MENU_ELDERLY_TAB_BAR_HEIGHT: number = 72;

class NGFMainMenuActionKey {
  static readonly OPEN_OFFICIAL_NAVIGATION: string = NGFHdsDemoRouteName.OFFICIAL_NAVIGATION;
  static readonly OPEN_HDS_SHOWCASE: string = NGFHdsDemoRouteName.SHOWCASE;
  static readonly BOOTSTRAP: string = 'action.bootstrap';
  static readonly PUBLISH_EVENT: string = 'action.publish_event';
  static readonly ADVANCE_LIFECYCLE: string = 'action.advance_lifecycle';
  static readonly SIMULATE_ERROR: string = 'action.simulate_error';
  static readonly DEMO_SECURITY_PERF: string = NGFHdsDemoRouteName.DEMO_SECURITY_PERF;
  static readonly DEMO_DATA_STORAGE: string = NGFHdsDemoRouteName.DEMO_DATA_STORAGE;
  static readonly DEMO_WORKFLOW: string = NGFHdsDemoRouteName.DEMO_WORKFLOW;
  static readonly DEMO_DEVICE_DISPLAY: string = NGFHdsDemoRouteName.DEMO_DEVICE_DISPLAY;
  static readonly SYSTEM_RESOURCE_PREVIEW: string = NGFHdsDemoRouteName.SYSTEM_RESOURCE_PREVIEW;
  static readonly DEMO_TASK_MANAGER: string = NGFHdsDemoRouteName.TASK_MANAGER;
  static readonly DEMO_ERROR_RECOVERY: string = NGFHdsDemoRouteName.DEMO_ERROR_RECOVERY;
  static readonly DEMO_SYNC_MANAGER: string = NGFHdsDemoRouteName.DEMO_SYNC_MANAGER;
  static readonly ACCESSIBILITY_SHOWCASE: string = NGFHdsDemoRouteName.ACCESSIBILITY_SHOWCASE;
  static readonly DEMO_MULTITON_SYMBOL: string = 'action.demo_multiton_symbol';
  static readonly DEMO_MULTITON_DATA: string = 'action.demo_multiton_data';
  static readonly DEMO_SUB_WINDOW_SETTINGS: string = 'action.demo_sub_window_settings';
  static readonly DEMO_SUB_WINDOW_TASK: string = 'action.demo_sub_window_task';
  static readonly DEMO_CONTINUATION: string = 'action.demo_continuation';
  static readonly DEMO_SHARE_KIT: string = 'action.demo_share_kit';
}

class NGFStarterLogEntry {
  id: number;
  text: string;

  constructor(id: number, text: string) {
    this.id = id;
    this.text = text;
  }
}

class NGFStarterStatePayload {
  phaseName: string;
  progress: number;
  isCompleted: boolean;

  constructor(phaseName: string, progress: number, isCompleted: boolean) {
    this.phaseName = phaseName;
    this.progress = progress;
    this.isCompleted = isCompleted;
  }
}

class NGFStarterDemoPayload {
  sequence: number;
  source: string;
  timestamp: number;

  constructor(sequence: number, source: string, timestamp: number) {
    this.sequence = sequence;
    this.source = source;
    this.timestamp = timestamp;
  }
}

class NGFStarterModuleBootstrapSummary {
  phaseName: string;
  totalCount: number;
  successCount: number;
  failureCount: number;

  constructor(phaseName: string, totalCount: number, successCount: number, failureCount: number) {
    this.phaseName = phaseName;
    this.totalCount = totalCount;
    this.successCount = successCount;
    this.failureCount = failureCount;
  }
}

class NGFStarterModuleDetailEntry {
  id: number;
  moduleName: string;
  phaseName: string;
  dependencyText: ResourceStr;
  serviceTokenText: ResourceStr;
  statusText: ResourceStr;
  messageText: ResourceStr;

  constructor(
    id: number,
    moduleName: string,
    phaseName: string,
    dependencyText: ResourceStr,
    serviceTokenText: ResourceStr,
    statusText: ResourceStr,
    messageText: ResourceStr
  ) {
    this.id = id;
    this.moduleName = moduleName;
    this.phaseName = phaseName;
    this.dependencyText = dependencyText;
    this.serviceTokenText = serviceTokenText;
    this.statusText = statusText;
    this.messageText = messageText;
  }
}

class NGFHdsDemoRouteParam {
  routeName: string;
  source: string;

  constructor(routeName: string, source: string) {
    this.routeName = routeName;
    this.source = source;
  }
}

class NGFMainMenuPointLightOptions implements hdsEffect.PointLightOptions {
  color?: ResourceColor;
  intensity?: number;
  height?: Dimension;
  bloom?: number;

  constructor(color: ResourceColor, intensity: number, height: Dimension, bloom: number) {
    this.color = color;
    this.intensity = intensity;
    this.height = height;
    this.bloom = bloom;
  }
}

class NGFMainMenuPointLightEffect implements hdsEffect.PointLightEffect {
  sourceType?: hdsEffect.PointLightSourceType;
  illuminatedType?: hdsEffect.PointLightIlluminatedType;
  options?: hdsEffect.PointLightOptions;

  constructor(
    sourceType: hdsEffect.PointLightSourceType,
    illuminatedType: hdsEffect.PointLightIlluminatedType,
    options: hdsEffect.PointLightOptions
  ) {
    this.sourceType = sourceType;
    this.illuminatedType = illuminatedType;
    this.options = options;
  }
}

class NGFMainMenuBackgroundEffectOptions implements BackgroundEffectOptions {
  radius: number;
  saturation?: number;
  brightness?: number;
  color?: ResourceColor;
  adaptiveColor?: AdaptiveColor;

  constructor(radius: number, saturation: number, brightness: number, color: ResourceColor) {
    this.radius = radius;
    this.saturation = saturation;
    this.brightness = brightness;
    this.color = color;
    this.adaptiveColor = AdaptiveColor.DEFAULT;
  }
}

class NGFMainMenuEdgeEffectOptions implements EdgeEffectOptions {
  alwaysEnabled: boolean;

  constructor(alwaysEnabled: boolean) {
    this.alwaysEnabled = alwaysEnabled;
  }
}

class NGFMainMenuGlassEffectFactory {
  static buildHeroSurfaceEffect(): VisualEffect {
    const pointLightOptions = new NGFMainMenuPointLightOptions($r('app.color.glass_surface_overlay'), 0.38, 34, 0.26);
    const pointLightEffect = new NGFMainMenuPointLightEffect(
      hdsEffect.PointLightSourceType.SOFT,
      hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
      pointLightOptions
    );
    return new hdsEffect.HdsEffectBuilder()
      .pointLight(pointLightEffect)
      .buildEffect();
  }

  static buildHeroChipEffect(): VisualEffect {
    const pointLightOptions = new NGFMainMenuPointLightOptions($r('app.color.glass_chip_overlay'), 0.24, 26, 0.18);
    const pointLightEffect = new NGFMainMenuPointLightEffect(
      hdsEffect.PointLightSourceType.BRIGHT,
      hdsEffect.PointLightIlluminatedType.BORDER,
      pointLightOptions
    );
    return new hdsEffect.HdsEffectBuilder()
      .pointLight(pointLightEffect)
      .buildEffect();
  }

  static buildActionButtonEffect(): VisualEffect {
    const pointLightOptions = new NGFMainMenuPointLightOptions($r('app.color.glass_action_overlay'), 0.32, 28, 0.24);
    const pointLightEffect = new NGFMainMenuPointLightEffect(
      hdsEffect.PointLightSourceType.SOFT,
      hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
      pointLightOptions
    );
    return new hdsEffect.HdsEffectBuilder()
      .pointLight(pointLightEffect)
      .buildEffect();
  }

  static buildTabBarEffect(pressed: boolean): VisualEffect {
    const pointLightOptions = new NGFMainMenuPointLightOptions(
      $r('app.color.glass_surface_overlay'),
      pressed ? 0.52 : 0.34,
      pressed ? 38 : 30,
      pressed ? 0.36 : 0.24
    );
    const pointLightEffect = new NGFMainMenuPointLightEffect(
      pressed ? hdsEffect.PointLightSourceType.BRIGHT : hdsEffect.PointLightSourceType.SOFT,
      hdsEffect.PointLightIlluminatedType.CONTENT,
      pointLightOptions
    );
    return new hdsEffect.HdsEffectBuilder()
      .pressShadow(hdsEffect.PressShadowType.BLEND_GRADIENT)
      .pointLight(pointLightEffect)
      .buildEffect();
  }

  static buildTabItemGlowEffect(active: boolean): VisualEffect {
    if (!active) {
      return new hdsEffect.HdsEffectBuilder().buildEffect();
    }
    const pointLightOptions = new NGFMainMenuPointLightOptions($r('app.color.button_primary'), 0.58, 30, 0.45);
    const pointLightEffect = new NGFMainMenuPointLightEffect(
      hdsEffect.PointLightSourceType.BRIGHT,
      hdsEffect.PointLightIlluminatedType.CONTENT,
      pointLightOptions
    );
    return new hdsEffect.HdsEffectBuilder()
      .pointLight(pointLightEffect)
      .buildEffect();
  }
}

/**
 * `@Builder` 的**对象参数**。
 *
 * ## ⚠️ 为什么必须是对象（真机实测的 bug，与 NGFSettingsPage 同源）
 *
 * ArkUI 的 `@Builder` 只有**按引用传递参数**时才建立状态依赖。
 * 用位置参数传基本类型（`buildXxx(label, value)`）时，
 * 里面渲染的文本会**停在首次构建的结果**，之后状态变化不再刷新。
 *
 * 2026-10-06 真机实测（设置页）：点「深色」后按钮的 `selected` 已变成 `true`，
 * 但「当前主题」那一行**仍然显示「跟随系统」** —— 功能是通的，**显示行没更新**。
 *
 * 与根 `AGENTS.md` §7.4 的要求一致：
 * 「动态文本不要通过通用 `@Builder` 方法的字符串参数层层传递后再渲染」。
 */
export interface NGFPerfInfoRowParams {
  label: string;
  value: string;
}

/** `buildHeaderGlassChip` 的参数，理由同上 */
export interface NGFHeaderGlassChipParams {
  label: ResourceStr;
  value: ResourceStr;
}

@Entry

@Component
struct NGFStarterMainMenuPage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private isCoreReady: boolean = false;
  @State private lifecycleState: NGFPhaseState = new NGFPhaseState('not_started', 0, false);
  @State private demoEventCount: number = 0;
  @State private lastEventType: string = '-';
  @State private statusMessage: ResourceStr = $r('app.string.ui_str_2001');
  @State private logs: Array<NGFStarterLogEntry> = [];
  @State private modulePhaseName: string = '-';
  @State private moduleTotalCount: number = 0;
  @State private moduleSuccessCount: number = 0;
  @State private moduleFailureCount: number = 0;
  @State private moduleDetails: Array<NGFStarterModuleDetailEntry> = [];
  @State private nextPhaseIndex: number = 0;
  @State private selectedTabIndex: number = 0;
  @State private pressedTabIndex: number = -1;
  @State private tabGlowStrength: number = 0.88;
  @State private isStatusDetailSheetOpen: boolean = false;
  @State private isPerformanceSheetOpen: boolean = false;
  @State private runtimeStatus: NGFRuntimeStatus | null = null;
  private perfMonitorInterval: number = -1;
  @State private bottomInsetVp: number = 0;
  @State private topInsetVp: number = NGF_MAIN_MENU_CONTENT_TOP_INSET;
  @StorageProp('ngf_window_ready') private windowReady: boolean = false;
  @StorageProp('ngf_window_active_page') private windowActivePage: string = '';
  @StorageProp('ngf_window_display_mode') private windowDisplayMode: string = 'default';
  @StorageProp('ngf_window_status') private windowStatus: string = 'undefined';
  @StorageProp('ngf_window_snapshot_updated_at') private windowSnapshotUpdatedAt: number = 0;
  @StorageProp('ngf_window_snapshot_json') private windowSnapshotJson: string = '{}';
  @StorageProp('ngf_visual_effects_effective_material_level')
  private effectiveMaterialLevel: number = hdsMaterial.MaterialLevel.ADAPTIVE;
  @StorageProp('ngf_visual_effects_should_use_system_material_surface') private useSysMat: boolean = true;

  // ── 适老呈现层状态 ──────────────────────────────────────────────────
  /** 当前生效的包容性设计策略（用户显式选择优先于系统推导） */
  @State private a11yPolicy: NGFInclusiveDesignPolicy = ngfAccessibilityFacade.getPolicy();
  /** 由策略解析出的设计令牌：字号 / 行高 / 触控目标等一律从这里取 */
  @State private a11yTokens: NGFInclusiveDesignTokens = resolveInclusiveDesignTokens({
    policy: ngfAccessibilityFacade.getPolicy(),
    context: resolveUiContextForPolicy(ngfAccessibilityFacade.getPolicy())
  });
  /** 是否处于适老版界面（决定 §1.1/§1.2/§2.1 的档位） */
  @State private isElderlyUi: boolean =
    resolveUiContextForPolicy(ngfAccessibilityFacade.getPolicy()) === NGFUiContext.ELDERLY_PAGE;
  /** 系统/本应用适老模式是否可判定；不可判定时不得声称处于适老版 */
  @State private seniorModeResolved: boolean = ngfAccessibilityFacade.getStateSnapshot().seniorModeResolved;
  /** 本应用适老模式开关（附件2 §3.1「长辈版」） */
  @State private appSeniorMode: boolean = ngfAccessibilityFacade.getStateSnapshot().appSeniorModeEnabled;
  /**
   * **系统级**关怀模式是否开启。
   *
   * 与 `appSeniorMode` 必须分开：
   * - 系统开启时，**系统会接管**应用内开关 —— 即使我们写 `setSeniorModeStateForSelf(false)`，
   *   系统也会把它同步回来（官方：「重新开启系统关怀模式时，原先被关闭的App会同步恢复开启」）。
   * - 因此此时应用内开关应**禁用**，否则表现为「拨到关又立刻弹回开」，用户会以为开关坏了。
   */
  @State private systemSeniorMode: boolean = ngfAccessibilityFacade.getStateSnapshot().seniorModeEnabled;
  private a11yBinding: NGFAccessibilityLifecycleBinding | null = null;

  private readonly scroller0: Scroller = new Scroller();
  private readonly scroller1: Scroller = new Scroller();
  private readonly scroller2: Scroller = new Scroller();
  private readonly scroller3: Scroller = new Scroller();
  private readonly scroller4: Scroller = new Scroller();
  private readonly tabsController: HdsTabsController = new HdsTabsController();
  private readonly starter = ngfStarterKernel;
  private readonly phaseOrder: Array<string> = ['context_setup', 'core_services', 'ready'];
  private readonly stateListenerId: string = 'NGFStarterMainMenuPage_State';
  private readonly errorListenerId: string = 'NGFStarterMainMenuPage_Error';
  private readonly demoListenerId: string = 'NGFStarterMainMenuPage_Demo';
  private readonly moduleListenerId: string = 'NGFStarterMainMenuPage_Modules';
  private eventsAttached: boolean = false;

  aboutToAppear(): void {
    const uiContext = this.getUIContext();
    if (uiContext) {
      uiContextManager.bindUIContext(uiContext);
    }
    // 适老呈现层：订阅平台无障碍/包容性策略（与 aboutToDisappear 的 detach 成对）
    this.attachAccessibilityBinding();
    this.starter.logger.setLevel(NGFLogLevel.DEBUG);
    this.attachStarterEventListeners();
    this.isCoreReady = this.starter.bootstrap();
    this.lifecycleState = this.starter.lifecycle.getCurrentState();
    this.statusMessage = this.isCoreReady ? $r('app.string.ui_str_2002') : $r('app.string.ui_str_2003');
    this.syncModuleBootstrapReport();
    this.syncFrameworkRuntimeSnapshot();
    NGFPageWindowSupport.apply(NGFPageWindowName.MAIN_MENU);
    this.appendLog(this.statusMessage);
    this.readBottomInset();
  }

  private readBottomInset(): void {
    const uiCtx = this.getUIContext();
    if (!uiCtx) {
      return;
    }
    const hostCtx = uiCtx.getHostContext();
    if (!hostCtx) {
      return;
    }
    window.getLastWindow(hostCtx).then((lastWindow: window.Window): void => {
      const bottomArea: window.AvoidArea = lastWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      this.bottomInsetVp = uiCtx.px2vp(bottomArea.bottomRect.height);
      const topArea: window.AvoidArea = lastWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const statusBarHeightVp = uiCtx.px2vp(topArea.topRect.height);
      // TitleBar FULL mode: status bar + large title + subtitle + margins (≈144vp)
      this.topInsetVp = statusBarHeightVp + 108;
    }).catch((_err: Error): void => {
      this.bottomInsetVp = 0;
      this.topInsetVp = NGF_MAIN_MENU_CONTENT_TOP_INSET;
    });
  }

  private resolveEffectiveHdsMaterialLevel(): hdsMaterial.MaterialLevel {
    switch (this.effectiveMaterialLevel) {
      case hdsMaterial.MaterialLevel.EXQUISITE:
        return hdsMaterial.MaterialLevel.EXQUISITE;
      case hdsMaterial.MaterialLevel.GENTLE:
        return hdsMaterial.MaterialLevel.GENTLE;
      case hdsMaterial.MaterialLevel.SMOOTH:
        return hdsMaterial.MaterialLevel.SMOOTH;
      default:
        return hdsMaterial.MaterialLevel.ADAPTIVE;
    }
  }

  // ── 玻璃面板文字色 ──────────────────────────────────────────────────
  //
  // 注：曾一度在适老档改用浅色高对比文字来绕开对比度问题，但那只是**治标**。
  // 真正的根因是普通组件的系统材质不再生效、导致面板背景被置空
  // （见 NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface 的说明）。
  // 根因修好后，这里恢复成统一的玻璃面板文字色，普通档与适老档共用。

  private resolveGlassPrimaryTextColor(): ResourceColor {
    return $r('app.color.text_primary');
  }

  private resolveGlassSecondaryTextColor(): ResourceColor {
    return $r('app.color.text_secondary');
  }

  private resolveGlassMetaTextColor(): ResourceColor {
    return $r('app.color.text_tertiary');
  }

  aboutToDisappear(): void {
    // 官方硬性要求：订阅必须成对取消，否则可能在生命周期结束后回调导致崩溃
    const binding: NGFAccessibilityLifecycleBinding | null = this.a11yBinding;
    if (binding !== null) {
      binding.detach();
      this.a11yBinding = null;
    }
    this.detachStarterEventListeners();
    uiContextManager.clearUIContext();
  }

  // ── 适老呈现层：订阅 + 令牌刷新 ──────────────────────────────────────

  /** 订阅平台无障碍/包容性策略变化，并把令牌重新解析到 @State */
  private attachAccessibilityBinding(): void {
    if (this.a11yBinding !== null) {
      return;
    }
    const listener: NGFAccessibilityBindingListener = {
      onAccessibilityStateChanged: (snapshot: NGFAccessibilityStateSnapshot): void => {
        this.seniorModeResolved = snapshot.seniorModeResolved;
        this.appSeniorMode = snapshot.appSeniorModeEnabled;
        this.systemSeniorMode = snapshot.seniorModeEnabled;
        this.refreshInclusiveTokens();
      },
      onInclusiveDesignChanged: (resolved: NGFInclusiveDesignResolved): void => {
        this.a11yPolicy = resolved.policy;
        this.refreshInclusiveTokens();
      }
    };
    this.a11yBinding = new NGFAccessibilityLifecycleBinding(listener);
    this.a11yBinding.attach();
  }

  /** 重新解析令牌与适老档位（策略变化后必须调用） */
  private refreshInclusiveTokens(): void {
    const policy: NGFInclusiveDesignPolicy = this.a11yPolicy;
    const context: NGFUiContext = resolveUiContextForPolicy(policy);
    this.isElderlyUi = context === NGFUiContext.ELDERLY_PAGE;
    this.a11yTokens = resolveInclusiveDesignTokens({ policy: policy, context: context });
  }

  // ── 适老呈现层：字号 / 行高 / 触控目标 ───────────────────────────────
  //
  // 设计原则：**普通版视觉零回归**。
  // 普通档下 a11yFont 原样返回、a11yLineHeight 返回 0（SDK 语义：≤0 = 沿用默认行高），
  // 因此这些包装对现有普通版是完全透明的；只有适老档才抬到规范下限。

  /**
   * 适老版字号：附件2 §1.1「适老版界面……主要文字信息不小于 18 dp/pt」。
   * 普通档原样返回，不改动现有视觉。
   */
  private a11yFont(normalFontSize: number): number {
    if (!this.isElderlyUi) {
      return normalFontSize;
    }
    return Math.max(NGF_MAIN_MENU_ELDERLY_MIN_FONT_VP, normalFontSize);
  }

  /**
   * 适老版行高：附件2 §1.2「段落内文字的行距至少为 1.3 倍」。
   * 普通档返回 **0** —— SDK 明确「小于等于 0 时行高不受限、随字号自适应」，即默认行为。
   */
  private a11yLineHeight(fontSize: number): number {
    if (!this.isElderlyUi) {
      return 0;
    }
    return Math.round(fontSize * NGF_MAIN_MENU_LINE_HEIGHT_RATIO * 100) / 100;
  }

  /**
   * 适老版行高（原本已有显式行高的 Text 用）。
   * 普通档保留页面原有行高值，避免改变现有版式。
   */
  private a11yExplicitLineHeight(fontSize: number, normalLineHeight: number): number {
    if (!this.isElderlyUi) {
      return normalLineHeight;
    }
    return Math.round(fontSize * NGF_MAIN_MENU_LINE_HEIGHT_RATIO * 100) / 100;
  }

  /**
   * 浮窗选项。
   *
   * **关闭键（附件2 §2.4）**：规范要求「关闭按钮只可在左上、右上、中央底部，
   * 且最小点击响应区域不能小于 44×44 dp/pt」。
   * 实测 ArkUI/HDS 内置关闭键（`showClose: true`）位置合规（右上），但尺寸只有 **40×40 vp**，
   * 低于 §2.4 下限。因此本页浮窗**关掉内置键**，改由内容区提供
   * `NGFAccessibleDialogCloseButton`（点击区取 `dialogCloseTarget` = 44，位置右上）。
   */
  private buildSheetOptions(): NGFMaterialSheetOptions {
    const options: NGFMaterialSheetOptions = new NGFMaterialSheetOptions(
      ngfVisualEffectsFacade.buildSystemMaterialForSheet(),
      ngfVisualEffectsFacade.shouldUseSystemMaterialSurface()
    );
    options.showClose = false;
    return options;
  }

  /**
   * 段落间距：附件2 §1.2「段落间距至少比行距大 1.3 倍」。
   *
   * 适老档取令牌算出的 `paragraphSpacing`（= 正文行高 × 1.3 = 23.4 × 1.3 ≈ **30.4 vp**）；
   * 普通档原样返回，不改现有版式。
   *
   * **适用范围**：卡片之间、卡片内标题与说明之间这类**独立内容块**的分隔。
   * 卡片内「标签 / 值」这种成对且紧耦合的排版不按段落间距拉开，否则卡片会被撑得过高，
   * 反而降低一屏信息量（§2.3「充足操作时间」的意图是减少操作负担，不是减少可见信息）。
   */
  /**
   * 组内间距（标签/值、图标/文字等**紧耦合**元素之间）。
   * 适老档按 ×1.6 放大但不套用段落间距 —— 附件2 §1.2 的「段落间距」针对独立段落，
   * 把标签与值也拉到 30 vp 会撑高卡片、降低一屏信息量。
   */
  private a11yGroupSpacing(normalSpacing: number): number {
    return this.isElderlyUi ? Math.round(normalSpacing * 1.6) : normalSpacing;
  }

  private a11yParagraphSpacing(normalSpacing: number): number {
    if (!this.isElderlyUi) {
      return normalSpacing;
    }
    return Math.max(normalSpacing, this.a11yTokens.paragraphSpacing);
  }

  /**
   * 主要组件最小点击区：附件2 §2.1。
   * 适老版界面 60×60；其他页面 44×44（由令牌按上下文给出）。
   */
  private a11yTouchTarget(): number {
    return this.a11yTokens.minTouchTarget;
  }

  /**
   * 动效时长：随"减少动效"策略缩放。
   * **规范未规定动效**，这是 NGF 自有行为（系统只给布尔"减少动效"信号）。
   */
  /**
   * 切换本应用适老模式（附件2 §3.1「长辈版」）。
   * 关闭时回落普通版；两种模式是**同一页面**的两种呈现，功能集合完全一致。
   */
  private handleToggleSeniorMode(isOn: boolean): void {
    // 系统关怀模式接管时**不写入**：写了也会被系统同步回来，
    // 只会让开关闪烁、并与系统设置产生无意义的争抢。
    if (this.systemSeniorMode) {
      this.starter.logger.info(TAG, '系统关怀模式已接管，忽略应用内开关操作');
      return;
    }
    ngfAccessibilityFacade.setAppSeniorMode(isOn)
      .then((): void => {
        this.appSeniorMode = ngfAccessibilityFacade.getStateSnapshot().appSeniorModeEnabled;
        this.refreshInclusiveTokens();
      })
      .catch((error: Error): void => {
        // 失败时把开关拨回真实状态，避免 UI 与平台不一致
        this.appSeniorMode = ngfAccessibilityFacade.getStateSnapshot().appSeniorModeEnabled;
        this.starter.logger.warn(TAG, '切换长辈版失败: ' + error.message);
      });
  }

  private a11yMotionDuration(normalMs: number): number {
    return Math.round(normalMs * this.a11yTokens.motionDurationScale);
  }

  /** 底部标签栏高度：适老版需保证标签项点击区 ≥60（§2.1 主要组件） */
  private a11yTabBarHeight(): number {
    return this.isElderlyUi ? NGF_MAIN_MENU_ELDERLY_TAB_BAR_HEIGHT : 56;
  }

  /** 内容底部避让：跟随标签栏高度，避免最后一张卡片被浮动标签栏遮住 */
  private a11yContentBottomInset(): number {
    return this.a11yTabBarHeight() + 20;
  }

  private attachStarterEventListeners(): void {
    if (this.eventsAttached) {
      return;
    }

    const stateSubscribed = this.starter.eventBus.subscribe(
      NGFStarterEventName.CORE_STATE_CHANGED,
      this.stateListenerId,
      (payload: NGFEventPayload): void => {
        const state = this.parseStatePayload(payload.payloadJson);
        if (state) {
          this.lifecycleState = state;
          this.lastEventType = payload.payloadType;
          this.syncFrameworkRuntimeSnapshot();
          this.appendLog($r('app.string.ui_str_2004', state.phaseName, state.progress));
        }
      }
    );

    const errorSubscribed = this.starter.eventBus.subscribe(
      NGFStarterEventName.CORE_ERROR,
      this.errorListenerId,
      (_payload: NGFEventPayload): void => {
        this.lastEventType = 'ngf_core_error';
        this.statusMessage = $r('app.string.ui_str_2005', this.starter.errorHandler.getRecentErrorCount());
        this.appendLog(this.statusMessage);
      }
    );

    const demoSubscribed = this.starter.eventBus.subscribe(
      NGFStarterEventName.DEMO_EVENT,
      this.demoListenerId,
      (_payload: NGFEventPayload): void => {
        this.demoEventCount = this.demoEventCount + 1;
        this.lastEventType = NGFStarterEventName.DEMO_EVENT;
        this.appendLog($r('app.string.ui_str_2006', this.demoEventCount));
      }
    );

    const moduleSubscribed = this.starter.eventBus.subscribe(
      NGFStarterEventName.CORE_MODULES_BOOTSTRAPPED,
      this.moduleListenerId,
      (payload: NGFEventPayload): void => {
        const summary = this.parseModuleBootstrapReport(payload.payloadJson);
        if (summary) {
          this.applyModuleBootstrapSummary(summary);
          this.syncFrameworkRuntimeSnapshot();
          this.lastEventType = payload.payloadType;
          this.statusMessage = $r('app.string.ui_str_2007', summary.successCount, summary.totalCount);
          this.appendLog($r('app.string.ui_str_2008', summary.phaseName, summary.successCount, summary.failureCount));
        }
      }
    );

    this.eventsAttached = stateSubscribed || errorSubscribed || demoSubscribed || moduleSubscribed;
  }

  private detachStarterEventListeners(): void {
    if (!this.eventsAttached) {
      return;
    }
    this.starter.eventBus.unsubscribe(NGFStarterEventName.CORE_STATE_CHANGED, this.stateListenerId);
    this.starter.eventBus.unsubscribe(NGFStarterEventName.CORE_ERROR, this.errorListenerId);
    this.starter.eventBus.unsubscribe(NGFStarterEventName.DEMO_EVENT, this.demoListenerId);
    this.starter.eventBus.unsubscribe(NGFStarterEventName.CORE_MODULES_BOOTSTRAPPED, this.moduleListenerId);
    this.eventsAttached = false;
  }

  private handleBootstrapTap(): void {
    this.isCoreReady = this.starter.bootstrap();
    this.lifecycleState = this.starter.lifecycle.getCurrentState();
    this.syncModuleBootstrapReport();
    this.syncFrameworkRuntimeSnapshot();
    this.statusMessage = this.isCoreReady ? $r('app.string.ui_str_2009') : $r('app.string.ui_str_2010');
    this.appendLog(this.statusMessage);
  }

  private handlePublishDemoEventTap(): void {
    const payloadData = new NGFStarterDemoPayload(
      this.demoEventCount + 1,
      TAG,
      Date.now()
    );
    const payload = new NGFEventPayload(
      'ngf_demo_event',
      this.toJson(payloadData),
      Date.now()
    );
    this.starter.eventBus.publish(NGFStarterEventName.DEMO_EVENT, payload);
  }

  private handleAdvanceLifecycleTap(): void {
    if (this.lifecycleState.isCompleted) {
      this.appendLog($r('app.string.ui_str_2011'));
      return;
    }

    if (this.nextPhaseIndex >= this.phaseOrder.length) {
      this.starter.lifecycle.markCompleted();
      this.lifecycleState = this.starter.lifecycle.getCurrentState();
      this.publishLifecycleState();
      this.appendLog($r('app.string.ui_str_2012'));
      return;
    }

    const phaseName = this.phaseOrder[this.nextPhaseIndex];
    this.starter.lifecycle.beginPhase(phaseName);
    this.starter.lifecycle.completePhase(phaseName);
    this.nextPhaseIndex = this.nextPhaseIndex + 1;

    if (this.nextPhaseIndex >= this.phaseOrder.length) {
      this.starter.lifecycle.markCompleted();
    }

    this.lifecycleState = this.starter.lifecycle.getCurrentState();
    this.publishLifecycleState();
    this.appendLog($r('app.string.ui_str_2013', phaseName));
  }

  private handleSimulateErrorTap(): void {
    const context = new NGFErrorContext('starter', 'NGF_STARTER_DEMO_ERROR', TAG);
    void this.starter.errorHandler.handle(
      'StarterDemoError',
      resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.ui_str_2014')),
      NGFErrorSeverity.MEDIUM,
      context
    ).then((success: boolean) => {
      if (success) {
        this.appendLog($r('app.string.ui_str_2015'));
      }
    });
  }

  private handleOpenHdsDemoTap(routeName: string, label: string): void {
    try {
      this.pathStack.pushPathByName(routeName, new NGFHdsDemoRouteParam(routeName, TAG));
      this.starter.logger.info(TAG, '打开HDS演示: route=' + routeName + ', label=' + label);
      this.appendLog($r('app.string.ui_str_2016', label));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.appendLog($r('app.string.ui_str_2017', label, message));
    }
  }

  private handleFeatureActionTap(actionKey: string, label: ResourceStr): void {
    const labelStr = resolveResourceString(this.getUIContext().getHostContext(), label);
    if (actionKey === NGFMainMenuActionKey.OPEN_OFFICIAL_NAVIGATION ||
      actionKey === NGFMainMenuActionKey.OPEN_HDS_SHOWCASE) {
      this.handleOpenHdsDemoTap(actionKey, labelStr);
      return;
    }

    if (actionKey === NGFMainMenuActionKey.DEMO_SECURITY_PERF ||
      actionKey === NGFMainMenuActionKey.DEMO_DATA_STORAGE ||
      actionKey === NGFMainMenuActionKey.DEMO_WORKFLOW ||
      actionKey === NGFMainMenuActionKey.DEMO_DEVICE_DISPLAY ||
      actionKey === NGFMainMenuActionKey.SYSTEM_RESOURCE_PREVIEW ||
      actionKey === NGFMainMenuActionKey.DEMO_TASK_MANAGER ||
      actionKey === NGFMainMenuActionKey.DEMO_ERROR_RECOVERY ||
      actionKey === NGFMainMenuActionKey.DEMO_SYNC_MANAGER ||
      actionKey === NGFMainMenuActionKey.ACCESSIBILITY_SHOWCASE) {
      this.handleOpenHdsDemoTap(actionKey, labelStr);
      return;
    }

    if (actionKey === NGFHdsDemoRouteName.CAPABILITY_NETWORK ||
        actionKey === NGFHdsDemoRouteName.CAPABILITY_RDB ||
        actionKey === NGFHdsDemoRouteName.CAPABILITY_WEB_BRIDGE ||
        actionKey === NGFHdsDemoRouteName.CAPABILITY_SECURITY ||
        actionKey === NGFHdsDemoRouteName.CAPABILITY_HARDWARE ||
        actionKey === NGFHdsDemoRouteName.CAPABILITY_MEDIA) {
      this.handleOpenHdsDemoTap(actionKey, labelStr);
      return;
    }

    if (actionKey === NGFMainMenuActionKey.BOOTSTRAP) {
      this.handleBootstrapTap();
      return;
    }
    if (actionKey === NGFMainMenuActionKey.PUBLISH_EVENT) {
      this.handlePublishDemoEventTap();
      return;
    }
    if (actionKey === NGFMainMenuActionKey.ADVANCE_LIFECYCLE) {
      this.handleAdvanceLifecycleTap();
      return;
    }
    if (actionKey === NGFMainMenuActionKey.SIMULATE_ERROR) {
      this.handleSimulateErrorTap();
      return;
    }
    if (actionKey === NGFMainMenuActionKey.DEMO_MULTITON_SYMBOL) {
      try {
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        context.startAbility({
          bundleName: 'com.dlzz.ngf',
          abilityName: 'MultitonEntryAbility',
          parameters: {
            'targetRouteName': 'SystemResourcePreview',
            'targetTitle': 'Symbol 预览'
          }
        });
        this.appendLog('启动多实例任务: Symbol 预览器');
      } catch (err) {
        this.appendLog('启动多实例任务失败: ' + err);
      }
      return;
    }
    if (actionKey === NGFMainMenuActionKey.DEMO_MULTITON_DATA) {
      try {
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        context.startAbility({
          bundleName: 'com.dlzz.ngf',
          abilityName: 'MultitonEntryAbility',
          parameters: {
            'targetRouteName': 'NGFDemoDataStorage',
            'targetTitle': '数据沙箱'
          }
        });
        this.appendLog('启动多实例任务: 数据沙箱');
      } catch (err) {
        this.appendLog('启动多实例任务失败: ' + err);
      }
      return;
    }
    if (actionKey === NGFMainMenuActionKey.DEMO_SUB_WINDOW_SETTINGS) {
      try {
        ngfPlatformWindowManagerFacade.createSubWindow('sub_window_settings').then((subWindow: window.Window) => {
          AppStorage.setOrCreate('CurrentSubWindowRoute', 'NGFSettings');
          subWindow.setUIContent('pages/ngf/NGFDemoSubWindowPage', () => {
            subWindow.showWindow();
            this.appendLog('打开应用内子窗口: 设置面板');
          });
        });
      } catch (err) {
        this.appendLog('打开应用内子窗口失败: ' + err);
      }
      return;
    }
    if (actionKey === NGFMainMenuActionKey.DEMO_SUB_WINDOW_TASK) {
      try {
        ngfPlatformWindowManagerFacade.createSubWindow('sub_window_task').then((subWindow: window.Window) => {
          AppStorage.setOrCreate('CurrentSubWindowRoute', 'NGFTaskManager');
          subWindow.setUIContent('pages/ngf/NGFDemoSubWindowPage', () => {
            subWindow.showWindow();
            this.appendLog('打开应用内子窗口: 任务管理');
          });
        });
      } catch (err) {
        this.appendLog('打开应用内子窗口失败: ' + err);
      }
      return;
    }
    if (actionKey === NGFMainMenuActionKey.DEMO_CONTINUATION) {
      this.appendLog('当前页面状态已保存到 ContinuationFacade，请在另一台鸿蒙设备通过多设备控制中心触发流转。');
      try {
        ngfOverlayManagerFacade.showToast('流转数据准备就绪');
      } catch (err) {
        this.appendLog('显示Toast失败: ' + err);
      }
      return;
    }
    if (actionKey === NGFMainMenuActionKey.DEMO_SHARE_KIT) {
      try {
        const text = '发现宝藏鸿蒙框架 NGF！当前核心服务就绪: ' + this.isCoreReady + '，最后事件: ' + this.lastEventType;
        import('ngf_framework').then(module => {
          module.ngfSystemShareFacade.shareText(text);
          this.appendLog('已拉起原生系统 ShareKit 分享面板');
        });
      } catch (err) {
        this.appendLog('分享拉起失败: ' + err);
      }
      return;
    }

    this.appendLog($r('app.string.ui_str_2018', actionKey));
  }

  private publishLifecycleState(): void {
    const state = this.starter.lifecycle.getCurrentState();
    const payload = new NGFEventPayload(
      'ngf_core_state',
      this.toJson(new NGFStarterStatePayload(state.phaseName, state.progress, state.isCompleted)),
      Date.now()
    );
    this.starter.eventBus.publish(NGFStarterEventName.CORE_STATE_CHANGED, payload);
  }

  private parseStatePayload(payloadJson: string): NGFPhaseState | null {
    if (payloadJson.trim().length <= 0) {
      return null;
    }
    try {
      const parsed = JSON.parse(payloadJson) as NGFStarterStatePayload;
      const phaseName = parsed.phaseName && typeof parsed.phaseName === 'string' ? parsed.phaseName : 'not_started';
      const progress = parsed.progress && typeof parsed.progress === 'number' ? parsed.progress : 0;
      const isCompleted = parsed.isCompleted && typeof parsed.isCompleted === 'boolean' ? parsed.isCompleted : false;
      return new NGFPhaseState(phaseName, progress, isCompleted);
    } catch {
      return null;
    }
  }

  private syncModuleBootstrapReport(): void {
    const report = this.starter.getLastModuleBootstrapReport();
    if (!report) {
      return;
    }
    const summary = new NGFStarterModuleBootstrapSummary(
      report.phaseName,
      report.totalCount,
      report.successCount,
      report.failureCount
    );
    this.applyModuleBootstrapSummary(summary);
    this.appendLog($r('app.string.ui_str_2019', summary.phaseName, summary.successCount, summary.failureCount));
  }

  private syncFrameworkRuntimeSnapshot(): void {
    const snapshot = this.starter.getFrameworkRuntimeSnapshot();
    this.applyFrameworkRuntimeSnapshot(snapshot);
  }

  private parseModuleBootstrapReport(payloadJson: string): NGFStarterModuleBootstrapSummary | null {
    if (payloadJson.trim().length <= 0) {
      return null;
    }

    try {
      const parsed = JSON.parse(payloadJson) as NGFModuleBootstrapReport;
      const phaseName = parsed.phaseName && typeof parsed.phaseName === 'string' ? parsed.phaseName : 'core_services';
      const totalCount = parsed.totalCount && typeof parsed.totalCount === 'number' ? parsed.totalCount : 0;
      const successCount = parsed.successCount && typeof parsed.successCount === 'number' ? parsed.successCount : 0;
      const failureCount = parsed.failureCount && typeof parsed.failureCount === 'number' ? parsed.failureCount : 0;
      return new NGFStarterModuleBootstrapSummary(phaseName, totalCount, successCount, failureCount);
    } catch {
      return null;
    }
  }

  private applyModuleBootstrapSummary(summary: NGFStarterModuleBootstrapSummary): void {
    this.modulePhaseName = summary.phaseName;
    this.moduleTotalCount = summary.totalCount;
    this.moduleSuccessCount = summary.successCount;
    this.moduleFailureCount = summary.failureCount;
  }

  private applyFrameworkRuntimeSnapshot(snapshot: NGFFrameworkRuntimeSnapshot): void {
    this.isCoreReady = snapshot.coreReady;
    this.lifecycleState = new NGFPhaseState(
      snapshot.lifecyclePhaseName,
      snapshot.lifecycleProgress,
      snapshot.lifecycleCompleted
    );
    this.moduleTotalCount = snapshot.moduleCount;
    this.moduleSuccessCount = snapshot.successfulModuleCount;
    this.moduleFailureCount = snapshot.failedModuleCount;
    this.moduleDetails = this.buildModuleDetailEntries(snapshot.modules);
  }

  private buildModuleDetailEntries(modules: Array<NGFModuleRuntimeSnapshot>): Array<NGFStarterModuleDetailEntry> {
    const entries: Array<NGFStarterModuleDetailEntry> = [];
    for (let index = 0; index < modules.length; index++) {
      const moduleSnapshot = modules[index];
      const dependencyText = this.joinText(moduleSnapshot.dependencies);
      const serviceTokenText = this.joinText(moduleSnapshot.serviceTokens);
      const statusText = this.resolveModuleStatusText(moduleSnapshot);
      entries.push(
        new NGFStarterModuleDetailEntry(
          index + 1,
          moduleSnapshot.moduleName,
          moduleSnapshot.phaseName,
          dependencyText,
          serviceTokenText,
          statusText,
          moduleSnapshot.lastMessage
        )
      );
    }
    return entries;
  }

  private joinText(values: Array<string>): string {
    if (values.length <= 0) {
      return '-';
    }
    let result = '';
    for (let index = 0; index < values.length; index++) {
      if (index > 0) {
        result = result + ', ';
      }
      result = result + values[index];
    }
    return result;
  }

  private resolveModuleStatusText(snapshot: NGFModuleRuntimeSnapshot): string {
    if (!snapshot.hasBootstrapResult) {
      return snapshot.isBootstrapped ? 'ready_without_report' : 'not_bootstrapped';
    }
    if (snapshot.lastSuccess) {
      return snapshot.isBootstrapped ? 'bootstrapped' : 'reported_success_but_not_ready';
    }
    return 'bootstrap_failed';
  }

  private appendLog(message: ResourceStr): void {
    let msgStr = '';
    if (typeof message === 'string') {
      msgStr = message;
    } else {
      try {
        const hostCtx = this.getUIContext()?.getHostContext();
        if (hostCtx) {
          msgStr = resolveResourceString(hostCtx, message);
        }
      } catch (e) {
        msgStr = 'Unknown resource';
      }
    }
    const now = new Date();
    const timeText = String(this.pad2(now.getHours())) + ':' + String(this.pad2(now.getMinutes())) + ':' + String(this.pad2(now.getSeconds()));
    const nextId = this.logs.length > 0 ? this.logs[this.logs.length - 1].id + 1 : 1;
    const nextLogs: Array<NGFStarterLogEntry> = [];
    for (let i = 0; i < this.logs.length; i++) {
      nextLogs.push(this.logs[i]);
    }
    nextLogs.push(new NGFStarterLogEntry(nextId, timeText + '  ' + msgStr));
    while (nextLogs.length > 12) {
      nextLogs.shift();
    }
    this.logs = nextLogs;
  }

  private pad2(value: number): string {
    if (value >= 10) {
      return String(value);
    }
    return '0' + value;
  }

  private toJson(value: NGFStarterDemoPayload | NGFStarterStatePayload): string {
    try {
      const serialized = JSON.stringify(value);
      if (serialized === undefined) {
        return '{}';
      }
      return serialized;
    } catch {
      return '{}';
    }
  }

  build() {
    HdsNavigation(this.pathStack) {
      Stack({ alignContent: Alignment.TopStart }) {
        this.buildFullscreenBackgroundUnderlay()

        HdsTabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
          TabContent() {
            Scroll(this.scroller0) {
              Column({ space: this.a11yParagraphSpacing(12) }) {
                this.buildHeaderActionSwiper()
                this.buildHdsDemoCard()
                this.buildStatusCard()
                this.buildWindowMonitorCard()
              }
              .width('100%')
              .padding({
                left: 16,
                right: 16,
                top: this.topInsetVp,
                bottom: this.a11yContentBottomInset()
              })
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring, new NGFMainMenuEdgeEffectOptions(true))
            .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.PARENT_FIRST })
            .backgroundColor($r('app.color.background_transparent'))
          }
          .tabBar(this.buildTabItem($r('app.string.tab_framework'), 'sys.symbol.house', 0))

          TabContent() {
            Scroll(this.scroller1) {
              Column({ space: this.a11yParagraphSpacing(12) }) {
                this.buildDemoTaskManagerCard()
                this.buildDemoSecurityPerfCard()
                this.buildDemoDataStorageCard()
                this.buildDemoWorkflowCard()
                this.buildDemoDeviceDisplayCard()
                this.buildSystemResourcePreviewCard()
                this.buildDemoErrorRecoveryCard()
                this.buildDemoSyncManagerCard()
                this.buildAccessibilityShowcaseCard()
                this.buildDemoMultitonSymbolCard()
                this.buildDemoMultitonDataCard()
                this.buildDemoSubWindowSettingsCard()
                this.buildDemoSubWindowTaskCard()
                this.buildDemoContinuationCard()
                this.buildDemoShareKitCard()
              }
              .width('100%')
              .padding({
                left: 16,
                right: 16,
                top: this.topInsetVp,
                bottom: this.a11yContentBottomInset()
              })
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring, new NGFMainMenuEdgeEffectOptions(true))
            .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.PARENT_FIRST })
            .backgroundColor($r('app.color.background_transparent'))
          }
          .tabBar(this.buildTabItem($r('app.string.tab_features'), 'sys.symbol.more', 1))

          TabContent() {
            Scroll(this.scroller2) {
              Column({ space: this.a11yParagraphSpacing(12) }) {
                NGFCapabilitiesTabContent({
                  onActionTap: (actionKey: string, label: ResourceStr) => {
                    this.handleFeatureActionTap(actionKey, label);
                  }
                })
              }
              .width('100%')
              .padding({
                left: 16,
                right: 16,
                top: this.topInsetVp,
                bottom: this.a11yContentBottomInset()
              })
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring, new NGFMainMenuEdgeEffectOptions(true))
            .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.PARENT_FIRST })
            .backgroundColor($r('app.color.background_transparent'))
          }
          .tabBar(this.buildTabItem($r('app.string.tab_capabilities'), 'sys.symbol.grid', 2))

          TabContent() {
            Scroll(this.scroller3) {
              Column({ space: this.a11yParagraphSpacing(12) }) {
                NGFDeviceAwarenessPage()
              }
              .width('100%')
              .padding({
                left: 16,
                right: 16,
                top: this.topInsetVp,
                bottom: this.a11yContentBottomInset()
              })
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring, new NGFMainMenuEdgeEffectOptions(true))
            .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.PARENT_FIRST })
            .backgroundColor($r('app.color.background_transparent'))
          }
          .tabBar(this.buildTabItem($r('app.string.tab_device'), 'sys.symbol.scroll_vertical', 3))

          TabContent() {
            Scroll(this.scroller4) {
              Column({ space: this.a11yParagraphSpacing(12) }) {
                // 附件2 §3.1「长辈版」入口 —— 普通版与适老版共用同一个开关
                this.buildElderlyModeCard()
                NGFSettingsPage()
              }
              .width('100%')
              .padding({
                left: 16,
                right: 16,
                top: this.topInsetVp,
                bottom: this.a11yContentBottomInset()
              })
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring, new NGFMainMenuEdgeEffectOptions(true))
            .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.PARENT_FIRST })
            .backgroundColor($r('app.color.background_transparent'))
          }
          .tabBar(this.buildTabItem($r('app.string.tab_settings'), 'sys.symbol.gearshape', 4))
        }
        .width('100%')
        .height('100%')
        .barMode(BarMode.Fixed)
        // 适老档抬高标签栏，保证标签项点击区高度 ≥60（附件2 §2.1）
        //
        // ⚠️ 不要在这里用 .barWidth() 去拉宽 —— 2026-10-06 实测：
        // 设置 barWidth 会让浮动底栏的**背景胶囊与图标错位**（普通档下前两个图标
        // 完全落在胶囊外），且百分比语义与预期相反（'100%' 反而比 '40%' 更窄）。
        // 宽度交给 HDS 浮动样式自行计算，见 .agent-rules/project-rules.md PR-010。
        .barHeight(this.a11yTabBarHeight())
        .barOverlap(true)
        .barFloatingStyle({
          adaptToHandedness: true,
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.IMMERSIVE,
            materialLevel: this.resolveEffectiveHdsMaterialLevel()
          },
          thermoCtrl: true,
          barOpacity: 0.95,
          barBottomMargin: this.bottomInsetVp
        })
        .scrollable(true)
        .onChange((index: number): void => {
          this.selectedTabIndex = index;
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_primary'), this.useSysMat))
    }
    .titleBar(NGFHdsTitleBarOptionsFactory.build(
      'NGF MainMenuPage',
      $r('app.string.ui_str_2020'),
      // 标题栏文字由工厂**硬编码为白色**（app.color.text_white），
      // 因此它的底色必须是深色或透明。原先传的是 background_primary（浅色 #F3F7FB）——
      // 系统材质正常时走材质、这条回退从没被走到过；材质失效后回退到浅色，
      // 白字压浅底实测不可读。改为透明，让页面自己的沉浸底板（深色渐变）透上来。
      Color.Transparent,
      this.resolveEffectiveHdsMaterialLevel(),
      true,
      false
    ))
    .titleMode(HdsNavigationTitleMode.FREE)
    .hideBackButton(true)
    .navDestination(this.buildNavDestination)
    .mode(NavigationMode.Stack)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
    .width('100%')
    .height('100%')
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_primary'), this.useSysMat))
    .bindToScrollable([this.scroller0, this.scroller1, this.scroller2, this.scroller3, this.scroller4])
  }

  @Builder
  private buildTabItem(title: ResourceStr, symbolName: string, tabIndex: number): void {
    Column({ space: this.a11yGroupSpacing(4) }) {
      // 底栏图标：标签文字已提供语义
      SymbolGlyph($r(symbolName))
        .fontSize(this.a11yFont(this.selectedTabIndex === tabIndex ? 24 : 22))
        .fontWeight(this.selectedTabIndex === tabIndex ? FontWeight.Bold : FontWeight.Normal)
        .fontColor([this.selectedTabIndex === tabIndex
          ? $r('app.color.button_primary')
          : $r('app.color.text_secondary')])
        .symbolEffect(new BounceSymbolEffect(EffectScope.WHOLE, EffectDirection.UP), this.selectedTabIndex === tabIndex)
        .accessibilityLevel('no')
      Text(title)
        .fontSize(this.a11yFont(11))
        .lineHeight(this.a11yLineHeight(this.a11yFont(11)))
        .fontColor(this.selectedTabIndex === tabIndex
          ? $r('app.color.button_primary')
          : $r('app.color.text_secondary'))
        .fontWeight(this.selectedTabIndex === tabIndex ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    // 附件2 §2.1：适老版主要组件点击区 ≥60×60；标签栏是最主要的导航组件
    .constraintSize({ minHeight: this.a11yTouchTarget() })
    // 附件2 §1.4：颜色不得是唯一区分手段 —— 适老档给选中项再加一层**形状**冗余
    // （圆角底片 + 描边），这样即使色觉异常也能分辨当前所在标签。
    .borderRadius(this.isElderlyUi ? 16 : 0)
    .backgroundColor(this.isElderlyUi && this.selectedTabIndex === tabIndex
      ? $r('app.color.glass_chip_overlay')
      : $r('app.color.background_transparent'))
    .border({
      width: this.isElderlyUi && this.selectedTabIndex === tabIndex ? 2 : 0,
      color: this.isElderlyUi && this.selectedTabIndex === tabIndex
        ? $r('app.color.button_primary')
        : $r('app.color.background_transparent')
    })
    .scale(this.pressedTabIndex === tabIndex
      ? { x: 0.92, y: 0.92 }
      : { x: 1, y: 1 })
    .opacity(this.pressedTabIndex === tabIndex ? 0.8 : 1)
    .animation({ duration: this.a11yMotionDuration(180), curve: Curve.EaseOut })
    // 无障碍：底栏标签是**互斥单选**语义 → accessibilitySelected（不是 accessibilityChecked）。
    // 官方对照表：Selected 用于「单选列表、标签页等互斥选择」；
    // Checked 用于「复选框、开关等二态/三态组件」—— 用错会被读成「已勾选」。
    .accessibilitySelected(this.selectedTabIndex === tabIndex)
    .onTouch((event: TouchEvent): void => {
      if (event.type === TouchType.Down) {
        this.pressedTabIndex = tabIndex;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedTabIndex = -1;
        if (event.type === TouchType.Up) {
          this.tabsController.changeIndex(tabIndex);
        }
      }
    })
  }


  @Builder
  private buildFullscreenBackgroundUnderlay(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {}
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 150,
          colors: [
            ['#07101E', 0],
            ['#0C2341', 0.28],
            ['#143964', 0.58],
            ['#0B2747', 0.82],
            ['#0A1626', 1]
          ]
        })

      Column() {}
        .width(176)
        .height(176)
        .borderRadius(176)
        .backgroundColor($r('app.color.glow_circle_blue'))
        .opacity(0.22)
        .margin({ left: 192, top: 12 })
        .shadow({ radius: 82, color: $r('app.color.glow_circle_blue_shadow'), offsetX: 10, offsetY: 6 })

      Column() {}
        .width(148)
        .height(148)
        .borderRadius(148)
        .backgroundColor($r('app.color.glow_circle_cyan'))
        .opacity(0.18)
        .margin({ left: 18, top: 28 })
        .shadow({ radius: 74, color: $r('app.color.glow_circle_cyan_shadow'), offsetX: -8, offsetY: 8 })

      Column() {}
        .width(260)
        .height(260)
        .borderRadius(260)
        .backgroundColor($r('app.color.glow_circle_blue'))
        .opacity(0.12)
        .position({ right: -96, bottom: 104 })
        .shadow({ radius: 112, color: $r('app.color.glow_circle_blue_shadow'), offsetX: -18, offsetY: -12 })

      Column() {}
        .width(220)
        .height(220)
        .borderRadius(220)
        .backgroundColor($r('app.color.glow_circle_cyan'))
        .opacity(0.10)
        .position({ left: -72, bottom: 28 })
        .shadow({ radius: 96, color: $r('app.color.glow_circle_cyan_shadow'), offsetX: 16, offsetY: -10 })

      Column() {}
        .width('86%')
        .height(1)
        .backgroundColor($r('app.color.glass_divider'))
        .opacity(0.52)
        .margin({ left: 16, top: 94 })

      Column() {}
        .width('100%')
        .height('100%')
        .backgroundEffect(new NGFMainMenuBackgroundEffectOptions(42, 1.24, 1.05, $r('app.color.glass_bg_effect')))
        .visualEffect(NGFMainMenuGlassEffectFactory.buildHeroSurfaceEffect())
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder
  private buildNavDestination(name: string, _param: Object): void {
    if (name === NGFHdsDemoRouteName.SHOWCASE) {
      HdsIntegratedShowcasePage()
    } else if (name === NGFHdsDemoRouteName.OFFICIAL_NAVIGATION) {
      HdsNavigationOfficialShowcasePage()
    } else if (name === NGFHdsDemoRouteName.OFFICIAL_NAVIGATION_OVERVIEW) {
      HdsNavigationOfficialOverviewPage()
    } else if (name === NGFHdsDemoRouteName.OFFICIAL_NAVIGATION_MATERIAL) {
      HdsNavigationOfficialMaterialPage()
    } else if (name === NGFHdsDemoRouteName.OFFICIAL_NAVIGATION_EFFECT) {
      HdsNavigationOfficialEffectPage()
    } else if (name === NGFHdsDemoRouteName.DEMO_SECURITY_PERF) {
      NGFDemoSecurityPerfPage()
    } else if (name === NGFHdsDemoRouteName.DEMO_DATA_STORAGE) {
      NGFDemoDataStoragePage()
    } else if (name === NGFHdsDemoRouteName.DEMO_WORKFLOW) {
      NGFDemoWorkflowPage()
    } else if (name === NGFHdsDemoRouteName.DEMO_DEVICE_DISPLAY) {
      NGFDemoDeviceDisplayPage()
    } else if (name === NGFHdsDemoRouteName.SYSTEM_RESOURCE_PREVIEW) {
      NGFSystemResourcePreviewPage()
    } else if (name === NGFHdsDemoRouteName.TASK_MANAGER) {
      NGFTaskManagerPage()
    } else if (name === NGFHdsDemoRouteName.CAPABILITY_NETWORK) {
      NGFCapabilitiesNetworkPage()
    } else if (name === NGFHdsDemoRouteName.CAPABILITY_RDB) {
      NGFCapabilitiesDatabasePage()
    } else if (name === NGFHdsDemoRouteName.CAPABILITY_WEB_BRIDGE) {
      NGFCapabilitiesWebBridgePage()
    } else if (name === NGFHdsDemoRouteName.CAPABILITY_SECURITY) {
      NGFCapabilitiesSecurityPage()
    } else if (name === NGFHdsDemoRouteName.CAPABILITY_HARDWARE) {
      NGFCapabilitiesHardwarePage()
    } else if (name === NGFHdsDemoRouteName.CAPABILITY_MEDIA) {
      NGFCapabilitiesMediaPage()
    } else if (name === NGFHdsDemoRouteName.DEMO_ERROR_RECOVERY) {
      NGFDemoErrorRecoveryPage()
    } else if (name === NGFHdsDemoRouteName.DEMO_SYNC_MANAGER) {
      NGFDemoSyncManagerPage()
    } else if (name === NGFHdsDemoRouteName.ACCESSIBILITY_SHOWCASE) {
      NGFAccessibilityShowcasePage()
    }
  }

  @Builder
  private buildHeaderActionSwiper(): void {
    Swiper() {
      this.buildHeaderCard()
      this.buildActionCard()
    }
    .width('100%')
    .height(NGF_MAIN_MENU_HEADER_HEIGHT)
    .loop(true)
    .autoPlay(false)
    .itemSpace(16)
    .displayCount(1)
    .nextMargin(24)
    .prevMargin(24)
    .indicator(
      Indicator.dot()
        .itemWidth(8)
        .itemHeight(8)
        .selectedItemWidth(24)
        .selectedItemHeight(8)
        .color($r('app.color.glass_divider_strong'))
        .selectedColor($r('app.color.text_primary'))
    )
  }

  @Builder
  private buildHeaderCard(): void {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column() {}
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)
        .borderRadius(NGFMaterialSurfaceTokens.PROMINENT_RADIUS)

      Column({ space: this.a11yGroupSpacing(14) }) {
        Text('NGF MainMenuPage')
          .fontSize(this.a11yFont(28))
          .lineHeight(this.a11yLineHeight(this.a11yFont(28)))
          .fontWeight(FontWeight.Bold)
          .fontColor(this.resolveGlassPrimaryTextColor())

        Text(this.statusMessage)
          .fontSize(this.a11yFont(13))
          .lineHeight(this.a11yExplicitLineHeight(this.a11yFont(13), 20))
          .fontColor(this.resolveGlassSecondaryTextColor())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Column({ space: this.a11yGroupSpacing(10) }) {
          Row({ space: 10 }) {
            this.buildHeaderGlassChip({ label: $r('app.string.ui_str_2026'), value: this.lifecycleState.phaseName + ' · ' + this.lifecycleState.progress + '%' })
            this.buildHeaderGlassChip({ label: $r('app.string.ui_str_2027'), value: this.moduleSuccessCount + '/' + this.moduleTotalCount })
          }
          .width('100%')

          Row({ space: 10 }) {
            this.buildHeaderGlassChip({ label: $r('app.string.ui_str_2028'), value: this.windowDisplayMode + ' · ' + this.windowStatus })
            this.buildHeaderGlassChip({ label: $r('app.string.ui_str_2029'), value: String(this.demoEventCount) })
          }
          .width('100%')
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
      .padding({ top: NGF_MAIN_MENU_HEADER_CONTENT_TOP_PADDING, right: 20, bottom: 24, left: 20 })
      .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
      .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwareProminentBackgroundEffect(this.useSysMat))
      .borderRadius(NGFMaterialSurfaceTokens.PROMINENT_RADIUS)
      .border({
        width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
        color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.glass_border_strong'), this.useSysMat)
      })
      .visualEffect(NGFMainMenuGlassEffectFactory.buildHeroSurfaceEffect())
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildActionCard(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {}
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)
        .borderRadius(NGFMaterialSurfaceTokens.PROMINENT_RADIUS)

      Column({ space: this.a11yParagraphSpacing(12) }) {
        Text($r('app.string.ui_str_2037'))
          .fontSize(this.a11yFont(18))
          .lineHeight(this.a11yLineHeight(this.a11yFont(18)))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.resolveGlassPrimaryTextColor())

        Row({ space: 12 }) {
          this.buildSmallActionButton('CORE', $r('app.string.ui_str_2039'), NGFMainMenuActionKey.BOOTSTRAP)
          this.buildSmallActionButton('EVENT', $r('app.string.ui_str_2041'), NGFMainMenuActionKey.PUBLISH_EVENT)
        }
        .width('100%')
        .layoutWeight(1)

        Row({ space: 12 }) {
          this.buildSmallActionButton('LIFECYCLE', $r('app.string.ui_str_2043'), NGFMainMenuActionKey.ADVANCE_LIFECYCLE)
          this.buildSmallActionButton('ERROR', $r('app.string.ui_str_2045'), NGFMainMenuActionKey.SIMULATE_ERROR)
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(18)
      .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
      .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwareProminentBackgroundEffect(this.useSysMat))
      .borderRadius(NGFMaterialSurfaceTokens.PROMINENT_RADIUS)
      .border({
        width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
        color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.glass_border_medium'), this.useSysMat)
      })
      .shadow(NGFMaterialSurfaceTokens.buildMaterialAwareProminentShadow(this.useSysMat))
      .visualEffect(NGFMainMenuGlassEffectFactory.buildHeroSurfaceEffect())
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildHeaderGlassChip(params: NGFHeaderGlassChipParams): void {
    Column({ space: this.a11yGroupSpacing(4) }) {
      Text(params.label)
        .fontSize(this.a11yFont(11))
        .lineHeight(this.a11yLineHeight(this.a11yFont(11)))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveGlassMetaTextColor())

      Text(params.value)
        .fontSize(this.a11yFont(12))
        .lineHeight(this.a11yLineHeight(this.a11yFont(12)))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveGlassPrimaryTextColor())
        .maxLines(2)
    }
    .width('48%')
    .padding({ top: 10, right: 12, bottom: 10, left: 12 })
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwareControlBackgroundEffect(this.useSysMat))
    .borderRadius(18)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.glass_border_light'), this.useSysMat)
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwareControlShadow(this.useSysMat))
    .visualEffect(NGFMainMenuGlassEffectFactory.buildHeroChipEffect())
    // 无障碍分组（官方「使用建议」：对复杂布局减少冗余播报）。
    // 不分组时读屏把「标签」与「数值」当成**两个独立节点**，
    // 用户会听到一个孤立的数值，不知道它属于哪个标签。
    .accessibilityGroup(true)
  }

  @Builder
  private buildFeatureActionButton(
    badge: string,
    title: ResourceStr,
    subtitle: ResourceStr,
    actionKey: string
  ): void {
    Button() {
      Stack({ alignContent: Alignment.Start }) {
        Row({ space: 12 }) {
          Column({ space: this.a11yGroupSpacing(6) }) {
            Text(badge)
              .fontSize(this.a11yFont(10))
              .lineHeight(this.a11yLineHeight(this.a11yFont(10)))
              .fontWeight(FontWeight.Medium)
              .fontColor(this.resolveGlassMetaTextColor())

            Text(title)
              .width('100%')
              .fontSize(this.a11yFont(15))
              .lineHeight(this.a11yLineHeight(this.a11yFont(15)))
              .fontWeight(FontWeight.Medium)
              .fontColor(this.resolveGlassPrimaryTextColor())
              .maxLines(2)

            Text(subtitle)
              .width('100%')
              .fontSize(this.a11yFont(12))
              .lineHeight(this.a11yExplicitLineHeight(this.a11yFont(12), 18))
              .fontColor(this.resolveGlassSecondaryTextColor())
              .maxLines(2)
          }
          .width('82%')
          .alignItems(HorizontalAlign.Start)

          Row() {
            Text('›')
              .fontSize(this.a11yFont(22))
              .lineHeight(this.a11yLineHeight(this.a11yFont(22)))
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .margin({ bottom: 4 })
          }
          .width(28)
          .height(28)
          .borderRadius(14)
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding({
          left: 16,
          right: 16,
          top: this.isElderlyUi ? 20 : 14,
          bottom: this.isElderlyUi ? 20 : 14
        })
        .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
        .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect(this.useSysMat))
        .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
        .border({
          width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
          color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.glass_border_light'), this.useSysMat)
        })
        .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow(this.useSysMat))
        .visualEffect(NGFMainMenuGlassEffectFactory.buildActionButtonEffect())
      }
      .width('100%')
    }
    .width('100%')
    .padding(0)
    // 附件2 §2.1：主要组件点击区下限（适老版 60×60 / 其他页面 44×44）
    .constraintSize({ minHeight: this.a11yTouchTarget() })
    .backgroundColor($r('app.color.background_transparent'))
    .buttonStyle(ButtonStyleMode.NORMAL)
    .controlSize(ControlSize.NORMAL)
    .onClick((): void => {
      this.handleFeatureActionTap(actionKey, title);
    })
  }

  @Builder
  private buildSmallActionButton(
    badge: string,
    title: ResourceStr,
    actionKey: string
  ): void {
    Button() {
      Stack({ alignContent: Alignment.Start }) {
        Column() {}
          .width('100%')
          .height('100%')
          .backgroundColor(Color.Transparent)
          .borderRadius(NGFMaterialSurfaceTokens.CONTROL_RADIUS)

        Column({ space: this.a11yGroupSpacing(8) }) {
          Text(badge)
            .fontSize(this.a11yFont(10))
            .lineHeight(this.a11yLineHeight(this.a11yFont(10)))
            .fontWeight(FontWeight.Medium)
            .fontColor(this.resolveGlassMetaTextColor())

          Text(title)
            .fontSize(this.a11yFont(14))
            .lineHeight(this.a11yLineHeight(this.a11yFont(14)))
            .fontWeight(FontWeight.Medium)
            .fontColor(this.resolveGlassPrimaryTextColor())
            .maxLines(1)
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })
        .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
        .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwareControlBackgroundEffect(this.useSysMat))
        .borderRadius(NGFMaterialSurfaceTokens.CONTROL_RADIUS)
        .border({
          width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
          color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.glass_border_light'), this.useSysMat)
        })
        .shadow(NGFMaterialSurfaceTokens.buildMaterialAwareControlShadow(this.useSysMat))
        .visualEffect(NGFMainMenuGlassEffectFactory.buildActionButtonEffect())
      }
      .width('100%')
    }
    .layoutWeight(1)
    .height('100%')
    .constraintSize({ minHeight: this.a11yTouchTarget() })
    .backgroundColor($r('app.color.background_transparent'))
    .buttonStyle(ButtonStyleMode.NORMAL)
    .controlSize(ControlSize.SMALL)
    .onClick((): void => {
      const labelStr = typeof title === 'string' ? title : resolveResourceString(this.getUIContext().getHostContext(), title);
      ngfOverlayManagerFacade.showToast(labelStr, { duration: 2000 });
      this.handleFeatureActionTap(actionKey, title);
    })
  }

  @Builder
  private buildHdsDemoCard(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      Column({ space: this.a11yParagraphSpacing(12) }) {
        Text($r('app.string.ui_str_2030'))
          .fontSize(this.a11yFont(18))
          .lineHeight(this.a11yLineHeight(this.a11yFont(18)))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.resolveGlassPrimaryTextColor())

        Text($r('app.string.ui_str_2031'))
          .fontSize(this.a11yFont(13))
          .lineHeight(this.a11yExplicitLineHeight(this.a11yFont(13), 20))
          .fontColor(this.resolveGlassSecondaryTextColor())

        Text($r('app.string.ui_str_2032'))
          .fontSize(this.a11yFont(13))
          .lineHeight(this.a11yExplicitLineHeight(this.a11yFont(13), 20))
          .fontColor(this.resolveGlassSecondaryTextColor())

        this.buildFeatureActionButton(
          'OFFICIAL',
          $r('app.string.ui_str_2033'),
          $r('app.string.ui_str_2034'),
          NGFMainMenuActionKey.OPEN_OFFICIAL_NAVIGATION
        )
        this.buildFeatureActionButton(
          'INTEGRATED',
          $r('app.string.ui_str_2035'),
          $r('app.string.ui_str_2036'),
          NGFMainMenuActionKey.OPEN_HDS_SHOWCASE
        )
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(18)
      .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
      .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwareProminentBackgroundEffect(this.useSysMat))
      .borderRadius(NGFMaterialSurfaceTokens.PROMINENT_RADIUS)
      .border({
        width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
        color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.glass_border_subtle'), this.useSysMat)
      })
      .shadow(NGFMaterialSurfaceTokens.buildMaterialAwareProminentShadow(this.useSysMat))
      .visualEffect(NGFMainMenuGlassEffectFactory.buildHeroSurfaceEffect())
    }
    .width('100%')
  }


  @Builder
  private buildDemoSecurityPerfCard(): void {
    this.buildFeatureActionButton(
      'SECURITY',
      $r('app.string.ui_str_2047'),
      $r('app.string.ui_str_2048'),
      NGFMainMenuActionKey.DEMO_SECURITY_PERF
    )
  }

  @Builder
  private buildDemoDataStorageCard(): void {
    this.buildFeatureActionButton(
      'STORAGE',
      $r('app.string.ui_str_2049'),
      $r('app.string.ui_str_2050'),
      NGFMainMenuActionKey.DEMO_DATA_STORAGE
    )
  }

  @Builder
  private buildDemoWorkflowCard(): void {
    this.buildFeatureActionButton(
      'WORKFLOW',
      $r('app.string.ui_str_2051'),
      $r('app.string.ui_str_2052'),
      NGFMainMenuActionKey.DEMO_WORKFLOW
    )
  }

  @Builder
  private buildDemoDeviceDisplayCard(): void {
    this.buildFeatureActionButton(
      'DEVICE',
      $r('app.string.ui_str_2053'),
      $r('app.string.ui_str_2054'),
      NGFMainMenuActionKey.DEMO_DEVICE_DISPLAY
    )
  }

  @Builder
  private buildSystemResourcePreviewCard(): void {
    this.buildFeatureActionButton(
      'SYMBOL',
      $r('app.string.ui_str_2055'),
      $r('app.string.ui_str_2056'),
      NGFMainMenuActionKey.SYSTEM_RESOURCE_PREVIEW
    )
  }

  @Builder
  private buildDemoErrorRecoveryCard(): void {
    this.buildFeatureActionButton(
      'ERROR',
      $r('app.string.demo_error_recovery_title'),
      $r('app.string.demo_error_recovery_desc'),
      NGFMainMenuActionKey.DEMO_ERROR_RECOVERY
    )
  }

  @Builder
  private buildDemoSyncManagerCard(): void {
    this.buildFeatureActionButton(
      'SYNC',
      $r('app.string.demo_sync_title'),
      $r('app.string.demo_sync_desc'),
      NGFMainMenuActionKey.DEMO_SYNC_MANAGER
    )
  }

  @Builder
  private buildAccessibilityShowcaseCard(): void {
    this.buildFeatureActionButton(
      'A11Y',
      $r('app.string.a11y_showcase_title'),
      $r('app.string.a11y_showcase_subtitle'),
      NGFMainMenuActionKey.ACCESSIBILITY_SHOWCASE
    )
  }

  /**
   * 「长辈版」入口卡片（附件2 §3.1）
   *
   * 规范原文要求：**应将「长辈版」作为标准功能名**，并设置「亲情版」「关爱版」「关怀版」
   * 等别名作为**搜索关键字**。因此这里：
   * - 显示名走 i18n（`getElderlyModeDisplayName()`），zh_CN 下即「长辈版」；
   * - 别名原样列出，作为可被搜索命中的关键字提示。
   *
   * §1.4：开关状态**不能只靠颜色**表达，所以同时给出「已开启 / 已关闭」文字。
   */
  /**
   * 描述**生效**的适老状态与来源。
   *
   * 三个信号来源必须能区分，否则用户看到「已关闭」却是大字会无从判断：
   * 1. 应用内开关开启 → 已开启
   * 2. 仅系统关怀模式开启 → 已生效 · 由系统关怀模式开启
   * 3. 都没有 → 已关闭
   */
  private describeElderlyEffectiveState(): ResourceStr {
    if (!this.isElderlyUi) {
      return $r('app.string.elderly_mode_state_off');
    }
    // 系统接管时**一律**显示「由系统关怀模式开启」——
    // 即使应用内开关恰好也是开的，真正的控制方仍是系统（开关已锁定）。
    if (this.systemSeniorMode) {
      return $r('app.string.elderly_mode_state_system');
    }
    if (this.appSeniorMode) {
      return $r('app.string.elderly_mode_state_on');
    }
    return $r('app.string.elderly_mode_state_off');
  }

  @Builder
  private buildElderlyModeCard(): void {
    Column({ space: this.isElderlyUi ? 14 : 10 }) {
      Row() {
        Column({ space: this.a11yGroupSpacing(6) }) {
          Text($r('app.string.elderly_mode_badge'))
            .fontSize(this.a11yFont(10))
            .lineHeight(this.a11yLineHeight(this.a11yFont(10)))
            .fontWeight(FontWeight.Medium)
            .fontColor(this.resolveGlassMetaTextColor())

          Text(getElderlyModeDisplayName())
            .width('100%')
            .fontSize(this.a11yFont(15))
            .lineHeight(this.a11yLineHeight(this.a11yFont(15)))
            .fontWeight(FontWeight.Medium)
            .fontColor(this.resolveGlassPrimaryTextColor())
            .maxLines(1)

          Text($r('app.string.elderly_mode_desc'))
            .width('100%')
            .fontSize(this.a11yFont(12))
            .lineHeight(this.a11yLineHeight(this.a11yFont(12)))
            .fontColor(this.resolveGlassSecondaryTextColor())
            .maxLines(3)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // ⚠️ 开关位置必须反映**生效**状态：
        // 系统关怀模式开启时，应用内开关即使为关，界面也已经是适老档 ——
        // 此时开关若显示为关，用户会以为功能没生效（2026-10-06 用户实际报告过）。
        Toggle({ type: ToggleType.Switch, isOn: this.isElderlyUi })
          // 无障碍：开关与左侧的文字是**兄弟节点**，不关联的话读屏只会念
          // 「开关，开启」，用户不知道这是「长辈版」的开关。
          // ⚠️ 必须先解析成 **string** 再传：
          // ArkUI 的 accessibilityText 是 `(value: string)` 与 `(text: Resource)`
          // **两个独立重载**，**不接受 `ResourceStr` 联合类型**（实测编译报
          // "Type 'string' is not assignable to type 'Resource'"）。
          // 这与框架内部处理 `textHint` 的方式一致（见 NGFAccessibilityAttributeBinder）。
          .accessibilityText(resolveResourceString(this.getUIContext().getHostContext(), getElderlyModeDisplayName()))
          // 补充说明当前是「谁在生效」—— 系统接管时应用内开关是锁定的，
          // 只说「已禁用」不足以解释原因（见 PR-013 / PR-015）。
          .accessibilityDescription(resolveResourceString(this.getUIContext().getHostContext(), this.describeElderlyEffectiveState()))
          .constraintSize({ minWidth: this.a11yTouchTarget(), minHeight: this.a11yTouchTarget() })
          // 系统关怀模式接管时**禁用**应用内开关：
          // 此时写 setSeniorModeStateForSelf 会被系统同步回来，
          // 表现为「拨到关又立刻弹回开」，用户会以为开关坏了 —— 这就是「和系统设置打架」。
          .enabled(this.seniorModeResolved && !this.systemSeniorMode)
          .onChange((isOn: boolean): void => {
            this.handleToggleSeniorMode(isOn);
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // §1.4 非颜色冗余：状态用文字表达；§3.1 别名作为可搜索关键字提示
      Row({ space: 10 }) {
        // ⚠️ 必须显示**生效**状态，而不是只显示应用内开关。
        // 系统关怀模式开启时，应用内开关可能仍是关的，但界面已经是适老档 ——
        // 只显示开关状态会出现「显示已关闭、界面却是大字」的自相矛盾，
        // 用户无法判断到底是哪个信号在起作用。
        Text(this.describeElderlyEffectiveState())
          .fontSize(this.a11yFont(12))
          .lineHeight(this.a11yLineHeight(this.a11yFont(12)))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.resolveGlassPrimaryTextColor())

        Text($r('app.string.elderly_mode_aliases_hint'))
          .layoutWeight(1)
          .fontSize(this.a11yFont(12))
          .lineHeight(this.a11yLineHeight(this.a11yFont(12)))
          .fontColor(this.resolveGlassSecondaryTextColor())
          .maxLines(2)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: 16,
      right: 16,
      top: this.isElderlyUi ? 20 : 14,
      bottom: this.isElderlyUi ? 20 : 14
    })
    .constraintSize({ minHeight: this.a11yTouchTarget() })
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect(this.useSysMat))
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.glass_border_light'), this.useSysMat)
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow(this.useSysMat))
    // 面板材质必须与卡片一致：缺了这两行，文字会直接压在沉浸式渐变上，
    // 实测对比度只有 1.3~2.3（附件2 §1.3 要求 ≥4.5），见 .agent-state 的像素实测记录。
    .visualEffect(NGFMainMenuGlassEffectFactory.buildActionButtonEffect())
  }

  @Builder
  private buildDemoMultitonSymbolCard(): void {
    this.buildFeatureActionButton(
      'MULTI',
      $r('app.string.feat_multiton_symbol_title'),
      $r('app.string.feat_multiton_symbol_desc'),
      NGFMainMenuActionKey.DEMO_MULTITON_SYMBOL
    )
  }

  @Builder
  private buildDemoMultitonDataCard(): void {
    this.buildFeatureActionButton(
      'MULTI',
      $r('app.string.feat_multiton_data_title'),
      $r('app.string.feat_multiton_data_desc'),
      NGFMainMenuActionKey.DEMO_MULTITON_DATA
    )
  }

  @Builder
  private buildDemoSubWindowSettingsCard(): void {
    this.buildFeatureActionButton(
      'SUBWIN',
      $r('app.string.feat_subwin_settings_title'),
      $r('app.string.feat_subwin_settings_desc'),
      NGFMainMenuActionKey.DEMO_SUB_WINDOW_SETTINGS
    )
  }

  @Builder
  private buildDemoSubWindowTaskCard(): void {
    this.buildFeatureActionButton(
      'SUBWIN',
      $r('app.string.feat_subwin_task_title'),
      $r('app.string.feat_subwin_task_desc'),
      NGFMainMenuActionKey.DEMO_SUB_WINDOW_TASK
    )
  }

  @Builder
  private buildStatusCard(): void {
    Column({ space: this.a11yGroupSpacing(8) }) {
      Text($r('app.string.ui_str_2057'))
        .fontSize(this.a11yFont(16))
        .lineHeight(this.a11yLineHeight(this.a11yFont(16)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Text($r('app.string.ui_str_2058', this.isCoreReady ? 'ready' : 'not_ready'))
        .fontSize(this.a11yFont(13))
        .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2059', this.lifecycleState.phaseName))
        .fontSize(this.a11yFont(13))
        .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2060', String(this.lifecycleState.progress)))
        .fontSize(this.a11yFont(13))
        .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2061', this.lifecycleState.isCompleted ? 'true' : 'false'))
        .fontSize(this.a11yFont(13))
        .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2062', String(this.demoEventCount)))
        .fontSize(this.a11yFont(13))
        .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2063', String(this.lastEventType)))
        .fontSize(this.a11yFont(13))
        .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2005', String(this.starter.errorHandler.getRecentErrorCount())))
        .fontSize(this.a11yFont(13))
        .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2064', String(this.modulePhaseName)))
        .fontSize(this.a11yFont(13))
        .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2065', String(this.moduleSuccessCount), String(this.moduleTotalCount)))
        .fontSize(this.a11yFont(13))
        .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2066', String(this.moduleFailureCount)))
        .fontSize(this.a11yFont(13))
        .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(14)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect(this.useSysMat))
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.panel_border'), this.useSysMat)
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow(this.useSysMat))
    .onClick(() => {
      this.isStatusDetailSheetOpen = true;
    })
    .bindSheet(
      $$this.isStatusDetailSheetOpen,
      this.buildStatusDetailSheetContent(),
      this.buildSheetOptions()
    )
  }

  @Builder
  private buildStatusDetailSheetContent(): void {
    Column({ space: this.a11yGroupSpacing(0) }) {
      // 附件2 §2.4：关闭键只在右上（等三种位置之一），且点击区 ≥44×44
      Stack({ alignContent: Alignment.TopEnd }) {
        Row() {
          Text($r('app.string.ui_str_2057'))
            .fontSize(this.a11yFont(18))
            .lineHeight(this.a11yLineHeight(this.a11yFont(18)))
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        NGFAccessibleDialogCloseButton({
          componentId: 'a11y_status_sheet_close',
          closePosition: NGFDialogClosePosition.TOP_RIGHT,
          label: $r('app.string.a11y_sheet_close'),
          minTouchTarget: this.a11yTokens.dialogCloseTarget,
          onClose: (): void => {
            this.isStatusDetailSheetOpen = false;
          }
        })
        .margin({ right: 10, top: 6 })
      }
      .width('100%')
      .padding({ top: 12, bottom: 4 })

      List({ space: 12 }) {
        ListItem() { this.buildModuleDetailCard() }
        ListItem() { this.buildLogCard() }
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .padding({ top: 12, bottom: 16, left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  @Builder
  private buildWindowMonitorCard(): void {
    Column({ space: this.a11yGroupSpacing(8) }) {
      Text($r('app.string.ui_str_2067'))
        .fontSize(this.a11yFont(16))
        .lineHeight(this.a11yLineHeight(this.a11yFont(16)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Text($r('app.string.ui_str_2068', this.windowReady ? 'true' : 'false'))
        .fontSize(this.a11yFont(13))
        .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2069', this.windowActivePage.length > 0 ? this.windowActivePage : '-'))
        .fontSize(this.a11yFont(13))
        .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2070', this.windowDisplayMode))
        .fontSize(this.a11yFont(13))
        .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2071', this.windowStatus))
        .fontSize(this.a11yFont(13))
        .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
        .fontColor($r('app.color.text_secondary'))
      Text($r('app.string.ui_str_2072', this.resolveWindowUpdatedAtText()))
        .fontSize(this.a11yFont(13))
        .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
        .fontColor($r('app.color.text_secondary'))
      Text(this.windowSnapshotJson)
        .width('100%')
        .fontSize(this.a11yFont(11))
        .lineHeight(this.a11yLineHeight(this.a11yFont(11)))
        .fontColor($r('app.color.text_secondary'))
        .maxLines(6)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect(this.useSysMat))
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.panel_border'), this.useSysMat)
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow(this.useSysMat))
    .onClick(() => {
      this.runtimeStatus = ngfDeviceAdaptationFacade.getDeviceRuntimeStatus();
      this.isPerformanceSheetOpen = true;
    })
    .bindSheet(
      $$this.isPerformanceSheetOpen,
      this.buildPerformanceSheetContent(),
      this.buildSheetOptions()
    )
  }

  @Builder
  private buildPerformanceSheetContent(): void {
    Column({ space: this.a11yGroupSpacing(0) }) {
      // 附件2 §2.4：关闭键只在右上（等三种位置之一），且点击区 ≥44×44
      Stack({ alignContent: Alignment.TopEnd }) {
        Row() {
          Text($r('app.string.monitor_panel_title'))
            .fontSize(this.a11yFont(18))
            .lineHeight(this.a11yLineHeight(this.a11yFont(18)))
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        NGFAccessibleDialogCloseButton({
          componentId: 'a11y_perf_sheet_close',
          closePosition: NGFDialogClosePosition.TOP_RIGHT,
          label: $r('app.string.a11y_sheet_close'),
          minTouchTarget: this.a11yTokens.dialogCloseTarget,
          onClose: (): void => {
            this.isPerformanceSheetOpen = false;
          }
        })
        .margin({ right: 10, top: 6 })
      }
      .width('100%')
      .padding({ top: 12, bottom: 4 })

      List({ space: 12 }) {
        ListItem() { this.buildPerfProcessCard() }
        ListItem() { this.buildPerfMemoryCard() }
        ListItem() { this.buildPerfCpuCard() }
        ListItem() { this.buildPerfBatteryCard() }
        ListItem() { this.buildPerfThreadsCard() }
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .padding({ top: 12, bottom: 16, left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .onAppear(() => this.startPerformanceMonitor())
    .onDisAppear(() => this.stopPerformanceMonitor())
  }

  private startPerformanceMonitor(): void {
    this.runtimeStatus = ngfDeviceAdaptationFacade.getDeviceRuntimeStatus();
    this.perfMonitorInterval = setInterval(() => {
      this.runtimeStatus = ngfDeviceAdaptationFacade.getDeviceRuntimeStatus();
    }, 1000);
  }

  private stopPerformanceMonitor(): void {
    if (this.perfMonitorInterval !== -1) {
      clearInterval(this.perfMonitorInterval);
      this.perfMonitorInterval = -1;
    }
  }

  private formatUptime(uptime: number | undefined): string {
    if (uptime === undefined || uptime < 0) return '0s';
    const hours = Math.floor(uptime / 3600);
    const minutes = Math.floor((uptime % 3600) / 60);
    const seconds = Math.floor(uptime % 60);
    let result = '';
    if (hours > 0) result += hours + 'h ';
    if (minutes > 0 || hours > 0) result += minutes + 'm ';
    result += seconds + 's';
    return result;
  }

  @Builder
  private buildPerfProcessCard(): void {
    Column({ space: this.a11yGroupSpacing(10) }) {
      Text($r('app.string.monitor_process_uptime'))
        .fontSize(this.a11yFont(14))
        .lineHeight(this.a11yLineHeight(this.a11yFont(14)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      this.buildPerfInfoRow({ label: 'PID / UID', value: String(this.runtimeStatus?.processId) + ' / ' + String(this.runtimeStatus?.uid) })
      this.buildPerfDivider()
      this.buildPerfInfoRow({ label: '架构', value: this.runtimeStatus?.is64Bit ? '64-bit' : '32-bit' })
      this.buildPerfDivider()
      this.buildPerfInfoRow({ label: '运行时间 (uptime)', value: this.formatUptime(this.runtimeStatus?.uptime) })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwareControlBackgroundEffect(this.useSysMat))
    .borderRadius(16)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.glass_border_subtle'), this.useSysMat)
    })
  }

  @Builder
  private buildPerfMemoryCard(): void {
    Column({ space: this.a11yGroupSpacing(10) }) {
      Text($r('app.string.monitor_memory_info'))
        .fontSize(this.a11yFont(14))
        .lineHeight(this.a11yLineHeight(this.a11yFont(14)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      this.buildPerfInfoRow({ label: 'App 内存限制', value: String(this.runtimeStatus?.appMemoryLimit || 0) + ' MB' })
      this.buildPerfDivider()
      
      Text($r('app.string.monitor_native_memory'))
        .fontSize(this.a11yFont(13))
        .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
      
      Progress({ value: (this.runtimeStatus?.appNativeMemSize || 0) / 1024, total: this.runtimeStatus?.appMemoryLimit || 1024, type: ProgressType.Capsule })
        .width('100%')
        .height(16)
        .color($r('app.color.button_primary'))
        
      Text(String(((this.runtimeStatus?.appNativeMemSize || 0) / 1024).toFixed(1)) + ' MB')
        .fontSize(this.a11yFont(12))
        .lineHeight(this.a11yLineHeight(this.a11yFont(12)))
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwareControlBackgroundEffect(this.useSysMat))
    .borderRadius(16)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.glass_border_subtle'), this.useSysMat)
    })
  }

  @Builder
  private buildPerfCpuCard(): void {
    Column({ space: this.a11yGroupSpacing(10) }) {
      Text($r('app.string.monitor_cpu_usage'))
        .fontSize(this.a11yFont(14))
        .lineHeight(this.a11yLineHeight(this.a11yFont(14)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      Row() {
        Column({ space: this.a11yGroupSpacing(8) }) {
          Progress({ value: (this.runtimeStatus?.systemCpuUsage || 0) * 100, total: 100, type: ProgressType.Ring })
            .width(64)
            .height(64)
            .color($r('app.color.button_primary'))
            .style({ strokeWidth: 6 })
          Text('系统 CPU\\n' + String(((this.runtimeStatus?.systemCpuUsage || 0) * 100).toFixed(1)) + '%')
            .fontSize(this.a11yFont(12))
            .lineHeight(this.a11yLineHeight(this.a11yFont(12)))
            .fontColor($r('app.color.text_primary'))
            .textAlign(TextAlign.Center)
        }.layoutWeight(1)

        Column({ space: this.a11yGroupSpacing(8) }) {
          Progress({ value: (this.runtimeStatus?.appCpuUsage || 0) * 100, total: 100, type: ProgressType.Ring })
            .width(64)
            .height(64)
            .color($r('app.color.button_primary'))
            .style({ strokeWidth: 6 })
          Text('APP CPU\\n' + String(((this.runtimeStatus?.appCpuUsage || 0) * 100).toFixed(1)) + '%')
            .fontSize(this.a11yFont(12))
            .lineHeight(this.a11yLineHeight(this.a11yFont(12)))
            .fontColor($r('app.color.text_primary'))
            .textAlign(TextAlign.Center)
        }.layoutWeight(1)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwareControlBackgroundEffect(this.useSysMat))
    .borderRadius(16)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.glass_border_subtle'), this.useSysMat)
    })
  }

  @Builder
  private buildPerfBatteryCard(): void {
    Column({ space: this.a11yGroupSpacing(10) }) {
      Text($r('app.string.monitor_battery_temp'))
        .fontSize(this.a11yFont(14))
        .lineHeight(this.a11yLineHeight(this.a11yFont(14)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      Row({ space: 8 }) {
        Text($r('app.string.monitor_battery_level'))
          .fontSize(this.a11yFont(13))
          .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
          .fontColor($r('app.color.text_secondary'))
        Progress({ value: this.runtimeStatus?.batterySOC || 0, total: 100, type: ProgressType.Capsule })
          .layoutWeight(1)
          .height(14)
          .color(this.runtimeStatus?.batterySOC && this.runtimeStatus.batterySOC < 20 ? Color.Red : 
                (this.runtimeStatus?.isCharging ? Color.Green : $r('app.color.button_primary')))
        Text(String(this.runtimeStatus?.batterySOC || 0) + '%')
          .fontSize(this.a11yFont(13))
          .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
      }.width('100%')
      
      this.buildPerfDivider()
      this.buildPerfInfoRow({ label: '温度', value: String(((this.runtimeStatus?.batteryTemperature || 0) / 10).toFixed(1)) + ' °C' })
      this.buildPerfDivider()
      this.buildPerfInfoRow({ label: '充电状态', value: this.runtimeStatus?.isCharging ? '充电中 / 已满' : '未充电' })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwareControlBackgroundEffect(this.useSysMat))
    .borderRadius(16)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.glass_border_subtle'), this.useSysMat)
    })
  }

  @Builder
  private buildPerfThreadsCard(): void {
    Column({ space: this.a11yGroupSpacing(10) }) {
      Text($r('app.string.monitor_thread_info'))
        .fontSize(this.a11yFont(14))
        .lineHeight(this.a11yLineHeight(this.a11yFont(14)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      if (this.runtimeStatus && this.runtimeStatus.threads && this.runtimeStatus.threads.length > 0) {
        ForEach(this.runtimeStatus.threads.slice(0, 10), (thread: NGFAppThreadInfo, index: number) => {
          Row({ space: 8 }) {
            Text('TID: ' + thread.threadId)
              .fontSize(this.a11yFont(12))
              .lineHeight(this.a11yLineHeight(this.a11yFont(12)))
              .fontColor($r('app.color.text_secondary'))
              .width(60)
            Progress({ value: thread.cpuUsage * 100, total: 100, type: ProgressType.Linear })
              .layoutWeight(1)
              .color($r('app.color.button_primary'))
            Text(String((thread.cpuUsage * 100).toFixed(1)) + '%')
              .fontSize(this.a11yFont(12))
              .lineHeight(this.a11yLineHeight(this.a11yFont(12)))
              .fontColor($r('app.color.text_primary'))
              .width(44)
              .textAlign(TextAlign.End)
          }.width('100%')
          
          if (index < Math.min(this.runtimeStatus!.threads.length, 10) - 1) {
            this.buildPerfDivider()
          }
        }, (thread: NGFAppThreadInfo) => String(thread.threadId))
      } else {
        Text($r('app.string.monitor_no_thread_data'))
          .fontSize(this.a11yFont(13))
          .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
          .fontColor($r('app.color.text_secondary'))
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwareControlBackgroundEffect(this.useSysMat))
    .borderRadius(16)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.glass_border_subtle'), this.useSysMat)
    })
  }

  @Builder
  private buildPerfInfoRow(params: NGFPerfInfoRowParams): void {
    Row() {
      Text(params.label)
        .fontSize(this.a11yFont(13))
        .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
      Text(params.value)
        .fontSize(this.a11yFont(13))
        .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    // 无障碍分组（官方「使用建议」：对复杂布局减少冗余播报）。
    // 不分组时读屏把「标签」与「数值」当成**两个独立节点**，
    // 用户会听到一个孤立的数值，不知道它属于哪个标签。
    .accessibilityGroup(true)
  }

  @Builder
  private buildPerfDivider(): void {
    Divider()
      .color($r('app.color.glass_divider'))
      .opacity(0.5)
  }

  private resolveWindowUpdatedAtText(): string {
    if (this.windowSnapshotUpdatedAt <= 0) {
      return '-';
    }
    const date = new Date(this.windowSnapshotUpdatedAt);
    return String(this.pad2(date.getHours())) + ':' + String(this.pad2(date.getMinutes())) + ':' + String(this.pad2(date.getSeconds()));
  }

  @Builder
  private buildModuleDetailCard(): void {
    Column({ space: this.a11yGroupSpacing(8) }) {
      Text($r('app.string.ui_str_2073'))
        .fontSize(this.a11yFont(16))
        .lineHeight(this.a11yLineHeight(this.a11yFont(16)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      if (this.moduleDetails.length <= 0) {
        Text($r('app.string.ui_str_2074'))
          .width('100%')
          .fontSize(this.a11yFont(12))
          .lineHeight(this.a11yLineHeight(this.a11yFont(12)))
          .fontColor($r('app.color.text_secondary'))
      } else {
        Column({ space: this.a11yGroupSpacing(8) }) {
          ForEach(this.moduleDetails, (entry: NGFStarterModuleDetailEntry) => {
            Column({ space: this.a11yGroupSpacing(4) }) {
              Text(entry.id + '. ' + entry.moduleName)
                .width('100%')
                .fontSize(this.a11yFont(13))
                .lineHeight(this.a11yLineHeight(this.a11yFont(13)))
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
              Text($r('app.string.ui_str_2075', entry.phaseName))
                .width('100%')
                .fontSize(this.a11yFont(12))
                .lineHeight(this.a11yLineHeight(this.a11yFont(12)))
                .fontColor($r('app.color.text_secondary'))
              Text($r('app.string.ui_str_2076', entry.statusText))
                .width('100%')
                .fontSize(this.a11yFont(12))
                .lineHeight(this.a11yLineHeight(this.a11yFont(12)))
                .fontColor($r('app.color.text_secondary'))
              Text($r('app.string.ui_str_2077', entry.dependencyText))
                .width('100%')
                .fontSize(this.a11yFont(12))
                .lineHeight(this.a11yLineHeight(this.a11yFont(12)))
                .fontColor($r('app.color.text_secondary'))
              Text($r('app.string.ui_str_2078', entry.serviceTokenText))
                .width('100%')
                .fontSize(this.a11yFont(12))
                .lineHeight(this.a11yLineHeight(this.a11yFont(12)))
                .fontColor($r('app.color.text_secondary'))
              Text($r('app.string.ui_str_2079', entry.messageText))
                .width('100%')
                .fontSize(this.a11yFont(12))
                .lineHeight(this.a11yLineHeight(this.a11yFont(12)))
                .fontColor($r('app.color.text_secondary'))
            }
            .width('100%')
            .padding(10)
            .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_secondary'), this.useSysMat))
            .borderRadius(10)
          }, (entry: NGFStarterModuleDetailEntry): string => 'starter_module_' + entry.id)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect(this.useSysMat))
    .borderRadius(14)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.panel_border'), this.useSysMat)
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow(this.useSysMat))
  }

  @Builder
  private buildLogCard(): void {
    Column({ space: this.a11yGroupSpacing(8) }) {
      Text($r('app.string.ui_str_2080'))
        .fontSize(this.a11yFont(16))
        .lineHeight(this.a11yLineHeight(this.a11yFont(16)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Column({ space: this.a11yGroupSpacing(4) }) {
        ForEach(this.logs, (entry: NGFStarterLogEntry) => {
          Text(entry.text)
            .width('100%')
            .fontSize(this.a11yFont(12))
            .lineHeight(this.a11yLineHeight(this.a11yFont(12)))
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Start)
        }, (entry: NGFStarterLogEntry): string => 'starter_log_' + entry.id)
      }
      .width('100%')
      .padding(10)
      .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_secondary'), this.useSysMat))
      .borderRadius(10)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect(this.useSysMat))
    .borderRadius(14)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.panel_border'), this.useSysMat)
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow(this.useSysMat))
  }

  @Builder
  private buildDemoTaskManagerCard(): void {
    this.buildFeatureActionButton(
      'TASK',
      $r('app.string.task_manager_title'),
      $r('app.string.task_manager_desc'),
      NGFMainMenuActionKey.DEMO_TASK_MANAGER
    )
  }

  @Builder
  private buildDemoContinuationCard(): void {
    this.buildFeatureActionButton(
      'FLOW',
      $r('app.string.feat_continuation_title'),
      $r('app.string.feat_continuation_desc'),
      NGFMainMenuActionKey.DEMO_CONTINUATION
    )
  }

  @Builder
  private buildDemoShareKitCard(): void {
    this.buildFeatureActionButton(
      'SHARE',
      $r('app.string.feat_sharekit_title'),
      $r('app.string.feat_sharekit_desc'),
      NGFMainMenuActionKey.DEMO_SHARE_KIT
    )
  }
}
