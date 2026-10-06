import { logger } from '../../utils/Logger';
import { accessibility } from '@kit.AccessibilityKit';
import { bundleManager, common, Configuration, systemConfiguration } from '@kit.AbilityKit';
import { uiContextManager } from '../../platformOhos/UIContextManager';
import { BusinessError } from '@kit.BasicServicesKit';
import { SettingsManager } from '../../data/SettingsManager';
import {
  isAnnouncementDeliverable,
  NGFAnnouncementMode,
  NGFAnnouncementRequest,
  resolveAnnouncementEventType
} from '../contracts/NGFAccessibilityAnnouncement';
import {
  IAccessibilityManager,
  NGFAccessibilityState,
  NGFAccessibilityStateListener,
  NGFAccessibilityStateSnapshot,
  NGFInclusiveDesignPolicyListener,
  NGFInclusiveDesignResolved,
  NGFSystemFontScaleListener,
  NGFTouchMode
} from '../contracts/IAccessibilityManager';
import {
  NGFA11ySignalSource,
  NGF_INCLUSIVE_DESIGN_METRICS,
  NGF_INCLUSIVE_DESIGN_POLICY_DEFAULT,
  NGFInclusiveDesignMetrics,
  NGFInclusiveDesignPolicy,
  NGFInclusiveDesignPolicyInput,
  resolveA11ySignalSource,
  parseContrastPolicy,
  parseDensityPolicy,
  parseMotionPolicy,
  parseTextScalePolicy,
  parseTouchTargetPolicy,
  resolveInclusiveDesignPolicy
} from '../contracts/NGFInclusiveDesignPolicy';

const TAG: string = 'NGFAccessibilityFacade';

/** 已注册的系统事件键，用于保证 on/off 严格配对 */
const EVENT_ACCESSIBILITY_STATE: string = 'accessibilityStateChange';
const EVENT_TOUCH_GUIDE_STATE: string = 'touchGuideStateChange';
const EVENT_SCREEN_READER_STATE: string = 'screenReaderStateChange';
const EVENT_ANIMATION_REDUCE: string = 'animationReduceStateChange';
const EVENT_SENIOR_MODE: string = 'seniorModeStateChange';
const EVENT_SENIOR_MODE_SELF: string = 'seniorModeStateChangeForSelf';
const EVENT_SYSTEM_CONFIGURATION: string = 'systemConfigurationUpdated';

/**
 * 无障碍/包容性设计持久化键。
 * 命名风格与 NGFVisualEffectsSettingKeys 保持一致。
 */
export class NGFAccessibilitySettingKeys {
  static readonly USER_POLICY_ENABLED: string = 'ngf_accessibility_user_policy_enabled';
  static readonly USER_POLICY_TEXT_SCALE: string = 'ngf_accessibility_user_policy_text_scale';
  static readonly USER_POLICY_TOUCH_TARGET: string = 'ngf_accessibility_user_policy_touch_target';
  static readonly USER_POLICY_CONTRAST: string = 'ngf_accessibility_user_policy_contrast';
  static readonly USER_POLICY_MOTION: string = 'ngf_accessibility_user_policy_motion';
  static readonly USER_POLICY_DENSITY: string = 'ngf_accessibility_user_policy_density';
}

/**
 * 无障碍门面 — 提供无障碍状态查询、语义标签工具与包容性设计策略。
 *
 * 生命周期要求（来自 API 26 SDK 官方注释，不是 NGF 自定规则）：
 * 所有 `accessibility.on*` 注册的监听都必须在对象生命周期结束前用对应的
 * `off*` 取消，否则可能造成内存泄漏甚至崩溃；回调必须使用命名函数，
 * 不能使用匿名函数，否则每次注册都会创建新的底层对象。
 * 本门面因此：
 * 1. 全部使用类的箭头函数属性作为稳定回调引用；
 * 2. 用 registeredEvents 记录真正注册成功的事件，release() 只取消已注册项；
 * 3. 每个事件单独 try/catch，单个能力缺失不会连带跳过其余注册。
 */
class AccessibilityFacade implements IAccessibilityManager {
  private static instance: AccessibilityFacade | null = null;
  private readonly stateListeners: Set<NGFAccessibilityStateListener> = new Set<NGFAccessibilityStateListener>();
  private readonly policyListeners: Set<NGFInclusiveDesignPolicyListener> = new Set<NGFInclusiveDesignPolicyListener>();
  private readonly registeredEvents: Set<string> = new Set<string>();
  private stateSnapshot: NGFAccessibilityStateSnapshot;
  private policy: NGFInclusiveDesignPolicy;
  private metrics: NGFInclusiveDesignMetrics;
  private userPolicy: NGFInclusiveDesignPolicy | undefined = undefined;
  private seniorModeEnabled: boolean = false;
  private appSeniorModeEnabled: boolean = false;
  private seniorModeResolved: boolean = false;
  private userPolicyRestored: boolean = false;
  /**
   * 系统字体缩放倍率（1 = 未放大）。
   *
   * **这是与关怀模式完全独立的第二个适老信号**（PR-011）：
   * 用户可能只调大了系统字体而没开关怀模式。此时系统按 fp 自动放大文字，
   * 但 vp 单位的点击区/行距不会变，必须由适老呈现层补上。
   */
  private systemFontScale: number = 1;
  private readonly fontScaleListeners: Set<NGFSystemFontScaleListener> = new Set<NGFSystemFontScaleListener>();
  private fontScaleSubscribed: boolean = false;

  private constructor() {
    this.stateSnapshot = this.readStateSnapshot();
    this.policy = resolveInclusiveDesignPolicy(this.buildPolicyInput());
    this.metrics = NGF_INCLUSIVE_DESIGN_METRICS;
    this.registerSystemListeners();
    // 设置模块可能尚未完成异步初始化；此处先试一次，失败则由读取策略时惰性补做。
    this.ensureUserPolicyRestored();
    // 适老模式只有异步 API，构造阶段先给出 resolved=false 的快照，
    // 查询完成后再刷新，避免把“尚未查询”误报成“未开启”。
    void this.refreshSeniorMode();
  }

  static getInstance(): AccessibilityFacade {
    if (!AccessibilityFacade.instance) {
      AccessibilityFacade.instance = new AccessibilityFacade();
    }
    return AccessibilityFacade.instance;
  }

  /**
   * 查询无障碍功能是否启用
   */
  isAccessibilityEnabled(): NGFAccessibilityState {
    return this.readAccessibilityState();
  }

  /**
   * 查询屏幕朗读（读屏服务）是否启用
   */
  isScreenReaderEnabled(): boolean {
    try {
      return accessibility.isScreenReaderOpenSync();
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      logger.warn(TAG, '屏幕朗读状态查询失败: code=' + businessError.code + ', message=' + businessError.message);
      return false;
    }
  }

  isTouchGuideEnabled(): boolean {
    try {
      return accessibility.isOpenTouchGuideSync();
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      logger.warn(TAG, '触摸探索状态查询失败: code=' + businessError.code + ', message=' + businessError.message);
      return false;
    }
  }

  isAnimationReduceEnabled(): boolean {
    try {
      return accessibility.isAnimationReduceEnabledSync();
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      logger.warn(TAG, '减少动效状态查询失败: code=' + businessError.code + ', message=' + businessError.message);
      return false;
    }
  }

  getStateSnapshot(): NGFAccessibilityStateSnapshot {
    return this.stateSnapshot;
  }

  addStateListener(listener: NGFAccessibilityStateListener): void {
    this.stateListeners.add(listener);
  }

  removeStateListener(listener: NGFAccessibilityStateListener): void {
    this.stateListeners.delete(listener);
  }

  getSystemFontScale(): number {
    return this.systemFontScale;
  }

  /**
   * 当前适老信号来源（两个独立信号的合成结果）。
   *
   * 页面与组件应通过它构造 `NGFA11yTextScale`，
   * 而不是自己判断 `policy.density` —— 后者无法区分「关怀模式」与「系统字体缩放」，
   * 会对字体缩放档**双重放大字号**（见 PR-011 与 `NGFA11yTextScale.font()`）。
   */
  getA11ySignalSource(): NGFA11ySignalSource {
    this.ensureSystemListeners();
    return resolveA11ySignalSource(this.buildPolicyInput());
  }

  addFontScaleListener(listener: NGFSystemFontScaleListener): void {
    this.fontScaleListeners.add(listener);
    // 首次订阅时补读一次，避免页面在订阅前就错过变化。
    this.refreshSystemFontScale();
  }

  removeFontScaleListener(listener: NGFSystemFontScaleListener): void {
    this.fontScaleListeners.delete(listener);
  }

  /**
   * 惰性补订阅系统字体缩放。
   *
   * **为什么需要**：门面在**构造函数**里就调用 `registerSystemListeners()`，
   * 但那一刻 `UIAbilityContext` 往往**还没就绪**（AbilityStage 尚未创建完），
   * 于是 `systemConfigurationUpdated` 注册失败 —— 实测日志：
   *
   * ```text
   * ⚠️ 无障碍事件注册失败: systemConfigurationUpdated,
   *    message=NGF: UIAbilityContext 尚未就绪，字体缩放订阅延后
   * ```
   *
   * 之前**没有重试**，导致字体缩放信号在整个进程生命周期内**永远是 1**。
   * 现在改为在读取策略时惰性补订阅 —— 此时页面已在渲染，上下文必然就绪。
   * `tryRegister` 自身幂等（已注册则跳过），重复调用无副作用。
   *
   * 与 `ensureUserPolicyRestored` 是同一个模式。
   */
  private ensureSystemListeners(): void {
    if (this.fontScaleSubscribed) {
      return;
    }
    this.registerSystemListeners();
  }

  /**
   * 读取当前系统字体缩放倍率。
   *
   * 来源：`ApplicationContext.getApplicationContext().getConfiguration()` 的
   * `fontSizeScale`（**@since 12**）。
   *
   * ⚠️ 只有在 `app.json5` 配了 `configuration` 且
   * `fontSizeScale` 为 `followSystem` 时，该值才会随系统字体变化；
   * 缺省（`nonFollowSystem`）时恒为 1。
   */
  private readSystemFontScale(): number {
    try {
      const context: common.UIAbilityContext | null = uiContextManager.getFullAbilityContext();
      if (context === null) {
        return this.systemFontScale;
      }
      // UIAbilityContext.config 是当前生效的 Configuration（SDK: config: Configuration）
      const scale: number | undefined = context.config.fontSizeScale;
      if (scale !== undefined && scale > 0) {
        return scale;
      }
      return 1;
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      logger.warn(TAG, '系统字体缩放读取失败: code=' + businessError.code
        + ', message=' + businessError.message);
      return this.systemFontScale;
    }
  }

  /** 重新读取系统字体缩放；有变化时通知监听者并刷新策略 */
  private refreshSystemFontScale(): void {
    this.applySystemFontScale(this.readSystemFontScale());
  }

  /** 应用新的字体缩放倍率；无变化时直接返回，避免无谓重绘 */
  private applySystemFontScale(next: number): void {
    const normalized: number = next > 0 ? next : 1;
    if (normalized === this.systemFontScale) {
      return;
    }
    // 适老化长按放大弹窗的触发条件是「系统字体 > 1 倍」。
    // 这条日志让人能一眼确认应用读到的缩放值，不必靠猜。
    logger.info(TAG, '系统字体缩放=' + normalized
      + (normalized > 1 ? '（>1，适老化长按放大弹窗应可触发）' : '（=1，长按放大弹窗不会触发）'));
    this.systemFontScale = normalized;
    logger.info(TAG, '系统字体缩放变化: ' + normalized);
    this.fontScaleListeners.forEach((listener: NGFSystemFontScaleListener) => {
      try {
        listener(normalized);
      } catch (error) {
        const businessError: BusinessError = error as BusinessError;
        logger.warn(TAG, '字体缩放监听回调失败: code=' + businessError.code
          + ', message=' + businessError.message);
      }
    });
    this.refreshStateSnapshot();
  }

  /**
   * 系统字体缩放变化回调。
   *
   * ⚠️ `systemConfiguration.UpdatedCallback` 是**带可选属性的对象**，
   * **不是函数** —— 必须传 `{ onFontSizeScaleUpdated: fn }`。
   * 回调签名：`OnFontSizeScaleUpdatedFn = (fontSizeScale: number) => void`（@since 24）。
   *
   * 用**类的箭头函数属性**作为稳定引用 —— SDK 要求不能用匿名函数，
   * 否则每次注册都会创建新的底层对象，导致无法正确取消订阅。
   */
  private readonly handleFontSizeScaleUpdated = (fontSizeScale: number): void => {
    this.applySystemFontScale(fontSizeScale);
  };

  /** 传给 onSystemConfigurationUpdated 的回调对象（只关心字体缩放） */
  private readonly systemConfigCallback: systemConfiguration.UpdatedCallback = {
    onFontSizeScaleUpdated: this.handleFontSizeScaleUpdated
  };

  /**
   * 为组件设置无障碍描述标签（供 .accessibilityText() 使用的推荐辅助工具）
   * @param componentId 组件逻辑 ID（建议与 .id() 保持一致）
   * @param label 朗读描述文字
   */
  buildAccessibilityLabel(componentId: string, label: string): string {
    logger.debug(TAG, '无障碍标签绑定: id=' + componentId + ', label=' + label);
    return label;
  }

  /**
   * 兼容保留：不再拼接硬编码中文“双击执行”。
   * 读屏服务会自行播报可执行动作，应用侧只需提供本地化的动作语义。
   */
  buildAccessibilityHint(action: string): string {
    return action;
  }

  // ------------------------------------------------------------------
  // 播报（sendAccessibilityEvent，@since 9；证据见设计文档 §3.8.2）
  // ------------------------------------------------------------------

  /**
   * 向读屏播报一段文本。
   *
   * 用于**视觉之外的状态变化**：例如切换长辈版成功、表单校验失败、
   * 列表加载完成等"画面变了但焦点没变"的场景。
   *
   * `Resource` 文本经 `textResourceAnnouncedForAccessibility`（@since 18）下发，
   * **不需要 Context 解析**；`string` 文本经 `textAnnouncedForAccessibility`（@since 12）下发。
   *
   * 文本为空白时**直接返回不发事件** —— 空播报对读屏用户只是噪声。
   *
   * **证据等级：仅编译验证。** 按用户决定（PP-001）本阶段不做真机验证，
   * 因此不得声称"播报已可用"。
   */
  async announce(request: NGFAnnouncementRequest): Promise<void> {
    const rawText: ResourceStr = request.text;
    if (typeof rawText === 'string' && !isAnnouncementDeliverable(rawText)) {
      logger.debug(TAG, '播报文本为空，跳过');
      return;
    }
    try {
      const mode: NGFAnnouncementMode = request.mode ?? NGFAnnouncementMode.INTERRUPT;
      const event: accessibility.EventInfo = new accessibility.EventInfo(
        resolveAnnouncementEventType(mode) as accessibility.EventType,
        this.resolveBundleName(),
        'common'
      );
      if (typeof rawText === 'string') {
        event.textAnnouncedForAccessibility = rawText;
      } else {
        event.textResourceAnnouncedForAccessibility = rawText;
      }
      if (request.componentId !== undefined) {
        event.componentType = request.componentId;
      }
      await accessibility.sendAccessibilityEvent(event);
      logger.debug(TAG, '已发送播报: mode=' + mode + ', len=' + String(rawText.toString().length));
    } catch (error) {
      const businessError = error as BusinessError;
      logger.warn(TAG, '播报失败: code=' + String(businessError.code) + ', message=' + businessError.message);
    }
  }

  /** 自身 bundleName，供 EventInfo 使用；取不到时回退为空串并由上层日志暴露 */
  private resolveBundleName(): string {
    try {
      const info: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      return info.name;
    } catch (error) {
      const businessError = error as BusinessError;
      logger.warn(TAG, '获取 bundleName 失败: code=' + String(businessError.code));
      return '';
    }
  }

  // ------------------------------------------------------------------
  // 适老模式（API 26 @since 26.0.0）
  // ------------------------------------------------------------------

  isSeniorModeEnabled(): boolean {
    return this.seniorModeEnabled;
  }

  isAppSeniorModeEnabled(): boolean {
    return this.appSeniorModeEnabled;
  }

  async refreshSeniorMode(): Promise<void> {
    const wasResolved: boolean = this.seniorModeResolved;
    let changed: boolean = false;

    try {
      const systemSenior: boolean = await accessibility.isSeniorModeEnabled();
      if (systemSenior !== this.seniorModeEnabled) {
        this.seniorModeEnabled = systemSenior;
        changed = true;
      }
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      logger.warn(TAG, '系统适老模式查询失败: code=' + businessError.code + ', message=' + businessError.message);
    }

    try {
      const selfSenior: boolean = await accessibility.getSeniorModeStateForSelf();
      if (selfSenior !== this.appSeniorModeEnabled) {
        this.appSeniorModeEnabled = selfSenior;
        changed = true;
      }
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      logger.warn(TAG, '本应用适老模式查询失败: code=' + businessError.code + ', message=' + businessError.message);
    }

    this.seniorModeResolved = true;
    if (changed || !wasResolved) {
      this.refreshStateSnapshot();
    }
  }

  async setAppSeniorMode(enabled: boolean): Promise<void> {
    try {
      await accessibility.setSeniorModeStateForSelf(enabled);
      this.appSeniorModeEnabled = enabled;
      this.seniorModeResolved = true;
      logger.info(TAG, '本应用适老模式已设置为: ' + enabled);
      this.refreshStateSnapshot();
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      logger.error(TAG, '本应用适老模式设置失败: code=' + businessError.code + ', message=' + businessError.message);
      // ArkTS 限制：throw 只能抛出 Error 类型，不能直接抛 BusinessError。
      throw new Error('NGF setAppSeniorMode failed: code=' + businessError.code
        + ', message=' + businessError.message);
    }
  }

  // ------------------------------------------------------------------
  // 包容性设计策略
  // ------------------------------------------------------------------

  getPolicy(): NGFInclusiveDesignPolicy {
    this.ensureUserPolicyRestored();
    this.ensureSystemListeners();
    return this.policy;
  }

  getMetrics(): NGFInclusiveDesignMetrics {
    this.ensureUserPolicyRestored();
    return this.metrics;
  }

  setUserPolicy(policy: NGFInclusiveDesignPolicy): void {
    this.userPolicy = policy;
    this.userPolicyRestored = true;
    this.recomputePolicy();
    void this.writeUserPolicy(SettingsManager.getInstance(), policy);
  }

  clearUserPolicy(): void {
    this.userPolicy = undefined;
    this.userPolicyRestored = true;
    this.recomputePolicy();
    void this.eraseUserPolicy(SettingsManager.getInstance());
  }

  restoreUserPolicy(): void {
    this.userPolicyRestored = false;
    this.ensureUserPolicyRestored();
  }

  addPolicyListener(listener: NGFInclusiveDesignPolicyListener): void {
    this.policyListeners.add(listener);
  }

  removePolicyListener(listener: NGFInclusiveDesignPolicyListener): void {
    this.policyListeners.delete(listener);
  }

  // ------------------------------------------------------------------
  // 生命周期
  // ------------------------------------------------------------------

  release(): void {
    this.unregisterSystemListeners();
    this.stateListeners.clear();
    this.policyListeners.clear();
  }

  // ------------------------------------------------------------------
  // 内部实现
  // ------------------------------------------------------------------

  private readStateSnapshot(): NGFAccessibilityStateSnapshot {
    return {
      accessibilityEnabled: this.readAccessibilityState(),
      touchGuideEnabled: this.isTouchGuideEnabled(),
      screenReaderEnabled: this.isScreenReaderEnabled(),
      animationReduceEnabled: this.isAnimationReduceEnabled(),
      touchMode: this.readTouchMode(),
      seniorModeEnabled: this.seniorModeEnabled,
      appSeniorModeEnabled: this.appSeniorModeEnabled,
      seniorModeResolved: this.seniorModeResolved,
      systemFontScale: this.systemFontScale,
      updatedAt: Date.now()
    };
  }

  private readAccessibilityState(): NGFAccessibilityState {
    try {
      return accessibility.isOpenAccessibilitySync()
        ? NGFAccessibilityState.ENABLED
        : NGFAccessibilityState.DISABLED;
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      logger.warn(TAG, '无障碍状态查询失败: code=' + businessError.code + ', message=' + businessError.message);
      return NGFAccessibilityState.UNKNOWN;
    }
  }

  private readTouchMode(): NGFTouchMode {
    try {
      const rawMode: string = accessibility.getTouchModeSync();
      if (rawMode === NGFTouchMode.SINGLE) {
        return NGFTouchMode.SINGLE;
      }
      if (rawMode === NGFTouchMode.DOUBLE) {
        return NGFTouchMode.DOUBLE;
      }
      if (rawMode === NGFTouchMode.NONE) {
        return NGFTouchMode.NONE;
      }
      logger.warn(TAG, '未知触摸模式取值: ' + rawMode);
      return NGFTouchMode.UNKNOWN;
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      logger.warn(TAG, '触摸模式查询失败: code=' + businessError.code + ', message=' + businessError.message);
      return NGFTouchMode.UNKNOWN;
    }
  }

  /**
   * 惰性恢复用户策略。
   *
   * SettingsManager 的内存缓存由应用启动时的异步 initialize() 填充，
   * 门面可能在它之前就被构造；因此这里在没有就绪时直接返回，
   * 保留 userPolicyRestored=false，等下次读取策略时再试，避免用户选择静默丢失。
   */
  private ensureUserPolicyRestored(): void {
    if (this.userPolicyRestored) {
      return;
    }
    const settings: SettingsManager = SettingsManager.getInstance();
    if (!settings.isInitialized()) {
      return;
    }
    this.userPolicyRestored = true;
    if (!settings.getBoolean(NGFAccessibilitySettingKeys.USER_POLICY_ENABLED, false)) {
      return;
    }
    const fallback: NGFInclusiveDesignPolicy = NGF_INCLUSIVE_DESIGN_POLICY_DEFAULT;
    const restored: NGFInclusiveDesignPolicy = {
      textScale: parseTextScalePolicy(
        settings.getString(NGFAccessibilitySettingKeys.USER_POLICY_TEXT_SCALE, fallback.textScale),
        fallback.textScale),
      touchTarget: parseTouchTargetPolicy(
        settings.getString(NGFAccessibilitySettingKeys.USER_POLICY_TOUCH_TARGET, fallback.touchTarget),
        fallback.touchTarget),
      contrast: parseContrastPolicy(
        settings.getString(NGFAccessibilitySettingKeys.USER_POLICY_CONTRAST, fallback.contrast),
        fallback.contrast),
      motion: parseMotionPolicy(
        settings.getString(NGFAccessibilitySettingKeys.USER_POLICY_MOTION, fallback.motion),
        fallback.motion),
      density: parseDensityPolicy(
        settings.getString(NGFAccessibilitySettingKeys.USER_POLICY_DENSITY, fallback.density),
        fallback.density)
    };
    this.userPolicy = restored;
    this.recomputePolicy();
    logger.info(TAG, '已从持久化存储恢复用户包容性设计策略');
  }

  private async writeUserPolicy(settings: SettingsManager, policy: NGFInclusiveDesignPolicy): Promise<void> {
    try {
      await settings.setBoolean(NGFAccessibilitySettingKeys.USER_POLICY_ENABLED, true);
      await settings.setString(NGFAccessibilitySettingKeys.USER_POLICY_TEXT_SCALE, policy.textScale);
      await settings.setString(NGFAccessibilitySettingKeys.USER_POLICY_TOUCH_TARGET, policy.touchTarget);
      await settings.setString(NGFAccessibilitySettingKeys.USER_POLICY_CONTRAST, policy.contrast);
      await settings.setString(NGFAccessibilitySettingKeys.USER_POLICY_MOTION, policy.motion);
      await settings.setString(NGFAccessibilitySettingKeys.USER_POLICY_DENSITY, policy.density);
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      logger.warn(TAG, '用户策略持久化失败: code=' + businessError.code + ', message=' + businessError.message);
    }
  }

  private async eraseUserPolicy(settings: SettingsManager): Promise<void> {
    try {
      await settings.deleteSetting(NGFAccessibilitySettingKeys.USER_POLICY_ENABLED);
      await settings.deleteSetting(NGFAccessibilitySettingKeys.USER_POLICY_TEXT_SCALE);
      await settings.deleteSetting(NGFAccessibilitySettingKeys.USER_POLICY_TOUCH_TARGET);
      await settings.deleteSetting(NGFAccessibilitySettingKeys.USER_POLICY_CONTRAST);
      await settings.deleteSetting(NGFAccessibilitySettingKeys.USER_POLICY_MOTION);
      await settings.deleteSetting(NGFAccessibilitySettingKeys.USER_POLICY_DENSITY);
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      logger.warn(TAG, '用户策略清除失败: code=' + businessError.code + ', message=' + businessError.message);
    }
  }

  private buildPolicyInput(): NGFInclusiveDesignPolicyInput {
    const input: NGFInclusiveDesignPolicyInput = {
      userPolicy: this.userPolicy,
      animationReduceEnabled: this.isAnimationReduceEnabled(),
      seniorModeEnabled: this.seniorModeEnabled || this.appSeniorModeEnabled,
      systemFontScale: this.systemFontScale
    };
    return input;
  }

  private recomputePolicy(): void {
    const nextPolicy: NGFInclusiveDesignPolicy = resolveInclusiveDesignPolicy(this.buildPolicyInput());
    const changed: boolean = !this.policyEquals(this.policy, nextPolicy);
    this.policy = nextPolicy;
    this.metrics = NGF_INCLUSIVE_DESIGN_METRICS;
    if (changed) {
      this.notifyPolicyListeners();
    }
  }

  private policyEquals(left: NGFInclusiveDesignPolicy, right: NGFInclusiveDesignPolicy): boolean {
    return left.textScale === right.textScale
      && left.touchTarget === right.touchTarget
      && left.contrast === right.contrast
      && left.motion === right.motion
      && left.density === right.density;
  }

  private notifyPolicyListeners(): void {
    const resolved: NGFInclusiveDesignResolved = {
      policy: this.policy,
      metrics: this.metrics
    };
    this.policyListeners.forEach((listener: NGFInclusiveDesignPolicyListener) => {
      try {
        listener(resolved);
      } catch (error) {
        const businessError: BusinessError = error as BusinessError;
        logger.warn(TAG, '策略监听回调失败: code=' + businessError.code + ', message=' + businessError.message);
      }
    });
  }

  private registerSystemListeners(): void {
    this.tryRegister(EVENT_ACCESSIBILITY_STATE, (): void => {
      accessibility.on('accessibilityStateChange', this.handleAccessibilityStateChange);
    });
    this.tryRegister(EVENT_TOUCH_GUIDE_STATE, (): void => {
      accessibility.on('touchGuideStateChange', this.handleTouchGuideStateChange);
    });
    this.tryRegister(EVENT_SCREEN_READER_STATE, (): void => {
      accessibility.on('screenReaderStateChange', this.handleScreenReaderStateChange);
    });
    this.tryRegister(EVENT_ANIMATION_REDUCE, (): void => {
      accessibility.onAnimationReduceStateChange(this.handleAnimationReduceStateChange);
    });
    this.tryRegister(EVENT_SENIOR_MODE, (): void => {
      accessibility.onSeniorModeStateChange(this.handleSeniorModeStateChange);
    });
    this.tryRegister(EVENT_SENIOR_MODE_SELF, (): void => {
      accessibility.onSeniorModeStateChangeForSelf(this.handleSeniorModeSelfStateChange);
    });
    // 系统字体缩放（第二个适老信号）。@since 24；用 ApplicationContext 而非 accessibility，
    // 因此单独判断可用性，缺失时只降级为「字体缩放恒为 1」，不影响其余无障碍能力。
    this.tryRegister(EVENT_SYSTEM_CONFIGURATION, (): void => {
      const context: common.UIAbilityContext | null = uiContextManager.getFullAbilityContext();
      if (context === null) {
        throw new Error('NGF: UIAbilityContext 尚未就绪，字体缩放订阅延后');
      }
      context.getApplicationContext().onSystemConfigurationUpdated(this.systemConfigCallback);
      this.fontScaleSubscribed = true;
      // 订阅成功后立刻补读一次当前值。
      const current: number = this.readSystemFontScale();
      logger.info(TAG, '字体缩放订阅成功，当前系统字体缩放=' + current);
      this.applySystemFontScale(current);
    });
  }

  private unregisterSystemListeners(): void {
    this.tryUnregister(EVENT_ACCESSIBILITY_STATE, (): void => {
      accessibility.off('accessibilityStateChange', this.handleAccessibilityStateChange);
    });
    this.tryUnregister(EVENT_TOUCH_GUIDE_STATE, (): void => {
      accessibility.off('touchGuideStateChange', this.handleTouchGuideStateChange);
    });
    this.tryUnregister(EVENT_SCREEN_READER_STATE, (): void => {
      accessibility.off('screenReaderStateChange', this.handleScreenReaderStateChange);
    });
    this.tryUnregister(EVENT_ANIMATION_REDUCE, (): void => {
      accessibility.offAnimationReduceStateChange(this.handleAnimationReduceStateChange);
    });
    this.tryUnregister(EVENT_SENIOR_MODE, (): void => {
      accessibility.offSeniorModeStateChange(this.handleSeniorModeStateChange);
    });
    this.tryUnregister(EVENT_SENIOR_MODE_SELF, (): void => {
      accessibility.offSeniorModeStateChangeForSelf(this.handleSeniorModeSelfStateChange);
    });
    this.tryUnregister(EVENT_SYSTEM_CONFIGURATION, (): void => {
      const context: common.UIAbilityContext | null = uiContextManager.getFullAbilityContext();
      if (context !== null) {
        context.getApplicationContext().offSystemConfigurationUpdated(this.systemConfigCallback);
      }
      this.fontScaleSubscribed = false;
    });
  }

  private tryRegister(eventKey: string, register: () => void): void {
    if (this.registeredEvents.has(eventKey)) {
      return;
    }
    try {
      register();
      this.registeredEvents.add(eventKey);
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      logger.warn(TAG, '无障碍事件注册失败: ' + eventKey
        + ', code=' + businessError.code + ', message=' + businessError.message);
    }
  }

  private tryUnregister(eventKey: string, unregister: () => void): void {
    if (!this.registeredEvents.has(eventKey)) {
      return;
    }
    try {
      unregister();
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      logger.warn(TAG, '无障碍事件取消失败: ' + eventKey
        + ', code=' + businessError.code + ', message=' + businessError.message);
    }
    this.registeredEvents.delete(eventKey);
  }

  private readonly handleAccessibilityStateChange = (_enabled: boolean): void => {
    this.refreshStateSnapshot();
  };

  private readonly handleTouchGuideStateChange = (_enabled: boolean): void => {
    this.refreshStateSnapshot();
  };

  private readonly handleScreenReaderStateChange = (_enabled: boolean): void => {
    this.refreshStateSnapshot();
  };

  private readonly handleAnimationReduceStateChange = (_enabled: boolean): void => {
    this.refreshStateSnapshot();
  };

  private readonly handleSeniorModeStateChange = (enabled: boolean): void => {
    this.seniorModeEnabled = enabled;
    this.seniorModeResolved = true;
    this.refreshStateSnapshot();
  };

  private readonly handleSeniorModeSelfStateChange = (enabled: boolean): void => {
    this.appSeniorModeEnabled = enabled;
    this.seniorModeResolved = true;
    this.refreshStateSnapshot();
  };

  private refreshStateSnapshot(): void {
    this.stateSnapshot = this.readStateSnapshot();
    this.recomputePolicy();
    this.stateListeners.forEach((listener: NGFAccessibilityStateListener) => {
      try {
        listener(this.stateSnapshot);
      } catch (error) {
        const businessError: BusinessError = error as BusinessError;
        logger.warn(TAG, '无障碍状态监听回调失败: code=' + businessError.code + ', message=' + businessError.message);
      }
    });
  }
}

export const ngfAccessibilityFacade: AccessibilityFacade = AccessibilityFacade.getInstance();
