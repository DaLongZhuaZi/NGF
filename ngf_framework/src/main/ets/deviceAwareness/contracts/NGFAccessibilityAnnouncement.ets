/**
 * NGF 无障碍播报契约（P4）
 *
 * ## 证据（`@ohos.accessibility`，已逐条核对）
 *
 * | 能力 | 声明 | @since |
 * |---|---|---|
 * | 发送无障碍事件 | `sendAccessibilityEvent(event: EventInfo): Promise<void>` | **9** |
 * | 打断式播报 | `EventType` 含 `'announceForAccessibility'` | **12** |
 * | 排队式播报 | `EventType` 含 `'announceForAccessibilityNotInterrupt'` | **18** |
 * | 播报文本（字符串） | `EventInfo.textAnnouncedForAccessibility?: string` | **12** |
 * | 播报文本（资源） | `EventInfo.textResourceAnnouncedForAccessibility?: Resource` | **18** |
 * | 事件构造 | `new EventInfo(type, bundleName, triggerAction)` | **11** |
 *
 * **这不是 API 26 新增能力** —— `sendAccessibilityEvent` 从 API 9 就有。
 * 设计文档 §3.8.2 记录了这一点：此前把它记成"未见公开入口"是**错的**。
 *
 * ## 为什么文本要分两个字段下发
 *
 * `Resource` 形式的播报文本**不需要 Context 解析** —— SDK 直接提供了
 * `textResourceAnnouncedForAccessibility`（@since 18）。
 * 这样契约层不必持有 UIContext，也就不会把 i18n 解析责任推给调用方。
 */

/** 播报模式 */
export enum NGFAnnouncementMode {
  /** 打断当前播报，立即播报本条（`'announceForAccessibility'`，@since 12） */
  INTERRUPT = 'interrupt',
  /** 排队播报，不打断当前内容（`'announceForAccessibilityNotInterrupt'`，@since 18） */
  QUEUE = 'queue'
}

/** 播报请求 */
export interface NGFAnnouncementRequest {
  /** 播报文本。`Resource` 走 i18n 资源，`string` 走已本地化文本 */
  text: ResourceStr;
  /** 播报模式，缺省为 `INTERRUPT` */
  mode?: NGFAnnouncementMode;
  /**
   * 该播报对应的组件 ID（可选）。
   * 填了有助于读屏把播报与具体控件关联；不填也不影响播报本身。
   */
  componentId?: string;
}

/**
 * NGF 播报模式 → ArkUI `EventType` 取值。
 *
 * 之所以要这层映射：NGF 的模式名是**语义名**（interrupt / queue），
 * 而 SDK 的取值是**历史命名**（`announceForAccessibility` /
 * `announceForAccessibilityNotInterrupt`），两者拼写不同，直接硬编码容易写错。
 */
export function resolveAnnouncementEventType(mode: NGFAnnouncementMode): string {
  return mode === NGFAnnouncementMode.QUEUE
    ? 'announceForAccessibilityNotInterrupt'
    : 'announceForAccessibility';
}

/** 播报是否可用：文本为空时不应发送事件（空播报对读屏用户是噪声） */
export function isAnnouncementDeliverable(text: string): boolean {
  return text.trim().length > 0;
}
