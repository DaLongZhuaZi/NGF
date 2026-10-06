/**
 * NGF 无障碍订阅生命周期绑定（P4）
 *
 * ## 解决的问题
 *
 * 设计文档 §3.4 记录了 API 26 SDK 的官方硬性要求：
 * 每个 `accessibility.on*` 都必须在对象生命周期结束前用对应 `off` 取消，
 * **否则可能内存泄漏甚至崩溃**。
 *
 * 但页面侧容易犯两类错：
 * 1. 在 `aboutToAppear()` 里只订阅、忘记在 `aboutToDisappear()` 取消；
 * 2. 取消时传了一个新建的闭包，导致底层认不出原回调。
 *
 * 本类把"成对订阅 + 稳定回调引用 + 幂等"固化成一个可复用对象：
 *
 * ```typescript
 * private readonly a11y: NGFAccessibilityLifecycleBinding = new NGFAccessibilityLifecycleBinding(this);
 *
 * aboutToAppear(): void { this.a11y.attach(); }
 * aboutToDisappear(): void { this.a11y.detach(); }
 * ```
 *
 * `attach()` / `detach()` 都是幂等的：重复调用不会重复注册，也不会重复取消。
 */

import {
  NGFAccessibilityStateListener,
  NGFAccessibilityStateSnapshot,
  NGFInclusiveDesignPolicyListener,
  NGFInclusiveDesignResolved
} from '../../deviceAwareness/contracts/IAccessibilityManager';
import { ngfAccessibilityFacade } from '../../deviceAwareness/facades/AccessibilityFacade';

/**
 * 页面需要接收的无障碍回调，按需实现其中一个或两个。
 *
 * 这里用"可选函数类型属性"而不是"可选方法"：ArkTS 下把可选方法当属性读取
 * 不可靠（读取结果可能恒为 undefined，导致回调被静默丢弃），函数类型属性是稳定写法。
 */
export interface NGFAccessibilityBindingListener {
  /** 无障碍平台状态变化（系统开关 / 读屏 / 触摸探索 / 触摸模式 / 减少动效 / 适老模式） */
  onAccessibilityStateChanged?: (snapshot: NGFAccessibilityStateSnapshot) => void;
  /** 包容性设计策略变化（系统信号或用户显式设置） */
  onInclusiveDesignChanged?: (resolved: NGFInclusiveDesignResolved) => void;
}

export class NGFAccessibilityLifecycleBinding {
  private readonly listener: NGFAccessibilityBindingListener;
  private attached: boolean = false;
  /** 稳定回调引用：注册与取消必须用同一个对象，否则底层无法配对 */
  private readonly stateHandler: NGFAccessibilityStateListener;
  private readonly policyHandler: NGFInclusiveDesignPolicyListener;

  constructor(listener: NGFAccessibilityBindingListener) {
    this.listener = listener;
    this.stateHandler = (snapshot: NGFAccessibilityStateSnapshot): void => {
      const callback: ((snapshot: NGFAccessibilityStateSnapshot) => void) | undefined =
        this.listener.onAccessibilityStateChanged;
      if (callback !== undefined) {
        callback(snapshot);
      }
    };
    this.policyHandler = (resolved: NGFInclusiveDesignResolved): void => {
      const callback: ((resolved: NGFInclusiveDesignResolved) => void) | undefined =
        this.listener.onInclusiveDesignChanged;
      if (callback !== undefined) {
        callback(resolved);
      }
    };
  }

  /** 订阅。幂等：已订阅时直接返回，不会重复注册。 */
  attach(): void {
    if (this.attached) {
      return;
    }
    ngfAccessibilityFacade.addStateListener(this.stateHandler);
    ngfAccessibilityFacade.addPolicyListener(this.policyHandler);
    this.attached = true;
  }

  /** 取消订阅。幂等：未订阅时直接返回，不会重复取消。 */
  detach(): void {
    if (!this.attached) {
      return;
    }
    ngfAccessibilityFacade.removeStateListener(this.stateHandler);
    ngfAccessibilityFacade.removePolicyListener(this.policyHandler);
    this.attached = false;
  }

  isAttached(): boolean {
    return this.attached;
  }
}
