import { NGFAnnouncementRequest } from './NGFAccessibilityAnnouncement';
import {
  NGFInclusiveDesignMetrics,
  NGFInclusiveDesignPolicy
} from './NGFInclusiveDesignPolicy';

/**
 * 无障碍管理器契约
 * 定义无障碍能力查询与辅助标签构建的标准接口。
 *
 * 兼容性说明：本节所有方法名与签名都保持既有形式，
 * 只做**追加**，不重命名、不删除，避免一次性破坏已有导入。
 */

export enum NGFAccessibilityState {
  ENABLED = 'enabled',
  DISABLED = 'disabled',
  UNKNOWN = 'unknown'
}

/**
 * 触摸模式。
 * 取值来源：`@ohos.accessibility.getTouchModeSync()` 文档（@since 20），
 * 明确列出 singleTouchMode / doubleTouchMode / none 三个字符串。
 * UNKNOWN 是 NGF 在查询失败或返回未知值时的收敛值。
 */
export enum NGFTouchMode {
  SINGLE = 'singleTouchMode',
  DOUBLE = 'doubleTouchMode',
  NONE = 'none',
  UNKNOWN = 'unknown'
}

/**
 * 无障碍平台状态快照。
 *
 * 字段语义边界（不要混用）：
 * - accessibilityEnabled：系统无障碍总开关
 * - touchGuideEnabled：触摸探索相关平台信号（不等同读屏）
 * - screenReaderEnabled：读屏服务状态
 * - touchMode：单指/双指触摸模式（none 表示触摸探索未启用）
 * - animationReduceEnabled：系统“减少动效”偏好
 * - seniorModeEnabled：系统级适老模式（API 26 @since 26.0.0，异步查询）
 * - appSeniorModeEnabled：本应用适老模式（API 26 @since 26.0.0）
 * - seniorModeResolved：上述两个异步查询是否已完成；未完成时不要把它们当作 false 结论
 * - systemFontScale：系统字体缩放倍率（1 = 未放大）。**这是与关怀模式独立的第二个适老信号**，
 *   用户只调大系统字体时同样需要适老布局（见 PR-011）
 */
export interface NGFAccessibilityStateSnapshot {
  accessibilityEnabled: NGFAccessibilityState;
  touchGuideEnabled: boolean;
  screenReaderEnabled: boolean;
  animationReduceEnabled: boolean;
  touchMode: NGFTouchMode;
  seniorModeEnabled: boolean;
  appSeniorModeEnabled: boolean;
  seniorModeResolved: boolean;
  systemFontScale: number;
  updatedAt: number;
}

export type NGFAccessibilityStateListener = (snapshot: NGFAccessibilityStateSnapshot) => void;

/** 系统字体缩放变化回调；参数为新的缩放倍率（1 = 未放大） */
export type NGFSystemFontScaleListener = (fontScale: number) => void;

/** 解析后的包容性设计配置：策略档位 + 生效门槛 */
export interface NGFInclusiveDesignResolved {
  policy: NGFInclusiveDesignPolicy;
  metrics: NGFInclusiveDesignMetrics;
}

export type NGFInclusiveDesignPolicyListener = (resolved: NGFInclusiveDesignResolved) => void;

export interface IAccessibilityManager {
  /**
   * 查询无障碍功能是否启用
   * @returns 当前无障碍状态
   */
  isAccessibilityEnabled(): NGFAccessibilityState;

  /**
   * 查询屏幕朗读（读屏服务）是否启用
   * @returns 启用返回 true
   */
  isScreenReaderEnabled(): boolean;

  /**
   * 查询触摸探索模式是否启用。
   */
  isTouchGuideEnabled(): boolean;

  /**
   * 查询系统是否启用减少动效偏好。
   */
  isAnimationReduceEnabled(): boolean;

  /**
   * 获取当前无障碍平台状态快照。
   */
  getStateSnapshot(): NGFAccessibilityStateSnapshot;

  /**
   * 查询系统字体缩放倍率（1 表示未放大）。
   *
   * 与"关怀模式"是**两个独立信号**：用户可能只调大了系统字体而没开关怀模式。
   * 此时系统会按 fp 自动放大文字，但 vp 单位的点击区/行距不会变，
   * 必须由适老呈现层补上（见 PR-011）。
   */
  getSystemFontScale(): number;

  /**
   * 订阅系统字体缩放变化。
   *
   * 底层是 `ApplicationContext.onSystemConfigurationUpdated`（**@since 24**）。
   * 必须在页面销毁时调用 `removeFontScaleListener` 取消，避免生命周期结束后回调。
   */
  addFontScaleListener(listener: NGFSystemFontScaleListener): void;

  /** 取消订阅系统字体缩放变化。 */
  removeFontScaleListener(listener: NGFSystemFontScaleListener): void;

  /**
   * 订阅系统无障碍状态变化。
   */
  addStateListener(listener: NGFAccessibilityStateListener): void;

  /**
   * 取消订阅系统无障碍状态变化。
   */
  removeStateListener(listener: NGFAccessibilityStateListener): void;

  /**
   * 构建无障碍描述标签文本
   * @param componentId 组件逻辑 ID
   * @param label 朗读描述文字
   * @returns 处理后的标签文本
   */
  buildAccessibilityLabel(componentId: string, label: string): string;

  /**
   * 生成推荐的无障碍提示文本（hint）。
   *
   * 兼容保留：早期实现会拼接硬编码中文“双击执行”，既违反国际化，
   * 也与读屏服务自身的动作播报重复。现在改为原样返回调用方传入的**已本地化**文本。
   * 新代码请改用 `NGFAccessibilitySemantics.textHint` 并通过 i18n 资源生成。
   *
   * @param action 已本地化的操作描述
   * @returns 传入文本本身
   */
  buildAccessibilityHint(action: string): string;

  /**
   * 向读屏播报一段文本。
   *
   * 用于**视觉之外的状态变化**（画面变了但焦点没变）：切换长辈版成功、
   * 表单校验失败、列表加载完成等。
   *
   * 底层是 `accessibility.sendAccessibilityEvent`（**@since 9**）+
   * `EventType: 'announceForAccessibility'`（**@since 12**），
   * 证据见设计文档 §3.8.2。
   *
   * @param request 播报请求；文本为空白时不发送事件
   */
  announce(request: NGFAnnouncementRequest): Promise<void>;

  // ------------------------------------------------------------------
  // P3 追加：适老模式与包容性设计策略
  // ------------------------------------------------------------------

  /**
   * 系统级适老模式是否开启。
   * 异步 API 结果未就绪时返回 false，必须结合 getStateSnapshot().seniorModeResolved 判断。
   */
  isSeniorModeEnabled(): boolean;

  /** 本应用适老模式是否开启 */
  isAppSeniorModeEnabled(): boolean;

  /** 主动刷新适老模式（异步 API，返回后快照与策略同步更新） */
  refreshSeniorMode(): Promise<void>;

  /** 设置本应用适老模式（用户可控，可关闭） */
  setAppSeniorMode(enabled: boolean): Promise<void>;

  /** 获取当前生效的包容性设计策略 */
  getPolicy(): NGFInclusiveDesignPolicy;

  /** 获取当前策略对应的量化门槛 */
  getMetrics(): NGFInclusiveDesignMetrics;

  /** 设置用户显式选择的策略；设置后系统信号不再覆盖它 */
  setUserPolicy(policy: NGFInclusiveDesignPolicy): void;

  /** 清除用户显式策略，回到由系统信号推导 */
  clearUserPolicy(): void;

  /**
   * 从持久化存储恢复用户显式策略。
   *
   * 持久化读取依赖 SettingsManager 的内存缓存，而该缓存是异步初始化的；
   * 因此本方法可在设置模块就绪后调用。门面自身也会在读取策略时惰性补做一次，
   * 避免应用忘记调用时用户选择丢失。
   */
  restoreUserPolicy(): void;

  /** 订阅策略变化（系统信号或用户设置变化都会触发） */
  addPolicyListener(listener: NGFInclusiveDesignPolicyListener): void;

  /** 取消订阅策略变化 */
  removePolicyListener(listener: NGFInclusiveDesignPolicyListener): void;

  /**
   * 释放系统监听。
   *
   * 官方文档明确要求：注册的监听必须在对象生命周期结束前用对应的 off 取消，
   * 否则可能造成内存泄漏甚至崩溃。单例门面在进程内长期存活，
   * 仍需提供显式释放入口，供测试和受控关闭场景使用。
   */
  release(): void;
}
