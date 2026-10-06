/**
 * NGF 无障碍语义契约（P3）
 *
 * 设计目标：把组件的无障碍语义从“页面里零散调用 ArkUI 属性”提升为可复用的命名模型，
 * 由 UI helper 层统一映射到 ArkUI 通用属性。
 *
 * 证据来源（全部来自本机 API 26 SDK 声明，非推测）：
 * - 文件：G:\DevEco Studio 26\DevEco Studio\sdk\default\openharmony\ets\component\common.d.ts
 *   - accessibilityGroup(value: boolean) / accessibilityGroup(isGroup, accessibilityOptions)
 *   - accessibilityText(value: string | Resource)
 *   - accessibilityTextHint(value: string)
 *   - accessibilityDescription(value: string | Resource)
 *   - accessibilityLevel(value: string) —— 文档明确列出 auto / yes / no / no-hide-descendants
 *   - accessibilityRole(role: AccessibilityRoleType)
 *   - accessibilityChecked(isCheck: boolean) / accessibilitySelected(isSelect: boolean)
 *   - accessibilityStateDescription(description: string | Resource | undefined)
 *   - accessibilityNextFocusId(nextId: string)
 *   - accessibilityDefaultFocus(focus: boolean)
 *   - accessibilityScrollTriggerable(isTriggerable: boolean)
 *   - onAccessibilityFocus(callback: AccessibilityFocusCallback)
 *   - onAccessibilityActionIntercept(callback: AccessibilityActionInterceptCallback)
 * - 文件：...\ets\api\@ohos.accessibility.d.ts
 *   - type Action = 'click' | 'longClick' | 'select' | 'setText' | ... | 'executeCustomAction'
 *
 * 重要边界（不得在实现中越过）：
 * 1. ArkUI 26 没有 accessibilityEnabled / accessibilityExpanded 之类的属性；
 *    enabled 由组件自身的 enabled 状态表达，expanded 只能通过 accessibilityStateDescription 文本表达。
 * 2. ArkUI 26 的 AccessibilityAction 只有 UNDEFINED_ACTION 与 ACCESSIBILITY_CLICK，
 *    因此 NGF 的 actions 只作为“语义描述”，唯一可拦截执行的动作是点击。
 * 3. ArkUI 26 没有数值型遍历顺序属性；traversalOrder 是 NGF 自己的排序意图，
 *    真正能下发给系统的只有 traversalNextId（映射 accessibilityNextFocusId）。
 */

/**
 * NGF 无障碍语义角色。
 *
 * 这是 ArkUI `AccessibilityRoleType`（API 26 共 125 个成员，@since 18）的**精选子集**：
 * 每个成员都与 ArkUI 同名成员 1:1 对应，映射表由平台适配层（P4）实现。
 * 未列入的角色在评审后按需扩展，不要在页面层直接使用 ArkUI 枚举绕过本契约。
 */
export enum NGFAccessibilityRole {
  /** 无特定角色；映射 ArkUI ROLE_NONE */
  NONE = 'none',
  BUTTON = 'button',
  HYPERLINK = 'hyperlink',
  IMAGE = 'image',
  TEXT = 'text',
  LIST = 'list',
  LIST_ITEM = 'list_item',
  TABS = 'tabs',
  TAB_BAR = 'tab_bar',
  TAB_CONTENT = 'tab_content',
  DIALOG = 'dialog',
  ALERT_DIALOG = 'alert_dialog',
  MENU = 'menu',
  MENU_ITEM = 'menu_item',
  CHECKBOX = 'checkbox',
  RADIO = 'radio',
  SWITCH = 'switch',
  SLIDER = 'slider',
  TEXT_INPUT = 'text_input',
  TEXT_AREA = 'text_area',
  TEXT_FIELD = 'text_field',
  SEARCH = 'search',
  PROGRESS = 'progress',
  LOADING_PROGRESS = 'loading_progress',
  NAVIGATION = 'navigation',
  NAV_DESTINATION = 'nav_destination',
  NAVIGATION_BAR = 'navigation_bar',
  BACK_BUTTON = 'back_button',
  TITLE_BAR = 'title_bar',
  SCROLL = 'scroll',
  GRID = 'grid',
  GRID_ITEM = 'grid_item',
  WATER_FLOW = 'water_flow',
  FLOW_ITEM = 'flow_item',
  TOGGLER = 'toggler',
  SELECT = 'select',
  STEPPER = 'stepper',
  STEPPER_ITEM = 'stepper_item',
  DATE_PICKER = 'date_picker',
  TIME_PICKER = 'time_picker',
  CALENDAR_PICKER = 'calendar_picker',
  TEXT_PICKER = 'text_picker',
  WEB = 'web',
  VIDEO = 'video',
  RATING = 'rating',
  DIVIDER = 'divider',
  BLANK = 'blank',
  REFRESH = 'refresh',
  SWIPER = 'swiper',
  QRCODE = 'qrcode',
  MARQUEE = 'marquee',
  BADGE_COMPONENT = 'badge_component'
}

/**
 * 无障碍层级，取值与 ArkUI `accessibilityLevel(value: string)` 文档一致。
 * 证据：common.d.ts 第 22215 行注释明确列出四个取值。
 */
export enum NGFAccessibilityLevel {
  /** 由无障碍分组服务与 ArkUI 自行判定（默认值） */
  AUTO = 'auto',
  /** 可被无障碍服务识别 */
  YES = 'yes',
  /** 不被无障碍服务识别 */
  NO = 'no',
  /** 自身与所有子组件都不被无障碍服务识别 */
  NO_HIDE_DESCENDANTS = 'no-hide-descendants'
}

/**
 * 语义动作。
 *
 * 词表来源：`@ohos.accessibility` 的 `type Action`（API 26 声明），
 * 这里取与组件语义最相关的子集。它描述“该节点支持哪些动作”，用于朗读与测试断言。
 *
 * 注意（2026-10-05 证据复核后修订）：
 * - 点击可通过 `onAccessibilityActionIntercept` 拦截（对应 `ACCESSIBILITY_CLICK`）；
 * - **任意自定义动作**可通过 API 26 新增的 `accessibilityCustomActions(Array<AccessibilityCustomAction>)`
 *   （`@since 26.0.0`）下发，配套类型 `AccessibilityCustomAction { name: ResourceStr; onAction: VoidCallback }`
 *   （`@since 26.0.0`，定义在 `units.d.ts`）；
 * - 无障碍滚动步长可通过 `accessibilityActionOptions({ scrollStep })`（`@since 23`）设置；
 * - 其余动作（如 `SET_TEXT`、`BACK`）在当前版本仍无独立下发入口，属待探针项。
 */
export enum NGFAccessibilityAction {
  CLICK = 'click',
  LONG_CLICK = 'longClick',
  SELECT = 'select',
  SET_TEXT = 'setText',
  SCROLL_FORWARD = 'scrollForward',
  SCROLL_BACKWARD = 'scrollBackward',
  FOCUS = 'focus',
  CLEAR_FOCUS = 'clearFocus',
  BACK = 'back',
  EXECUTE_CUSTOM_ACTION = 'executeCustomAction'
}

/**
 * 自定义无障碍动作（API 26 新增）。
 *
 * 对应 ArkUI `AccessibilityCustomAction`（`@since 26.0.0`）：
 * `{ name: ResourceStr; onAction: VoidCallback }`。
 * NGF 保持与 SDK **完全一致**的形态，不做额外包装 —— 多包一层只会产生无法下发的抽象。
 *
 * `name` 走 `ResourceStr`，强制调用方使用 i18n 资源；
 * `onAction` 是无参回调（ArkUI 侧就是 `VoidCallback`），不要试图在这里传业务参数。
 */
export interface NGFAccessibilityCustomAction {
  /** 动作名称（必须走 i18n 资源） */
  name: ResourceStr;
  /** 动作处理，无参 */
  onAction: () => void;
}

/**
 * 语义状态。
 *
 * 每一项都标注了在 ArkUI 26 中的真实表达方式，避免把“设计意图”误当成“已有属性”。
 */
export interface NGFAccessibilitySemanticState {
  /** 已勾选 → accessibilityChecked(isCheck) */
  checked?: boolean;
  /** 已选中 → accessibilitySelected(isSelect) */
  selected?: boolean;
  /** 可用/禁用 → 由组件自身 enabled 状态表达，无独立无障碍属性 */
  enabled?: boolean;
  /** 展开/折叠 → 无独立属性，需经 stateDescription 文本表达 */
  expanded?: boolean;
  /** 忙碌中 → 无独立属性，需经 stateDescription 文本或 role 表达 */
  busy?: boolean;
}

/**
 * 语义分组配置。
 * 对应 ArkUI `accessibilityGroup(isGroup, accessibilityOptions)`；
 * 其中 accessibilityPreferred @since 14，stateController 与 actionController 系列 @since 23，
 * 均由 API 26 SDK 声明确认可用。
 */
export interface NGFAccessibilityGrouping {
  /** 是否把本节点及其子节点合并为单一可聚焦单元 */
  isGroup: boolean;
  /** 合并朗读时优先使用子节点的 accessibilityText，而不是通用文本 */
  accessibilityPreferred?: boolean;
  /** 由组内第一个匹配该角色的组件接管状态属性与朗读 */
  stateControllerRole?: NGFAccessibilityRole;
  /** 由组内第一个匹配该 id 的组件接管状态属性与朗读 */
  stateControllerId?: string;
  /** 由组内第一个匹配该角色的组件接管部分无障碍动作 */
  actionControllerRole?: NGFAccessibilityRole;
  /** 由组内第一个匹配该 id 的组件接管部分无障碍动作 */
  actionControllerId?: string;
}

/**
 * NGF 无障碍语义模型。
 *
 * 所有面向用户的文本字段统一使用 `ResourceStr`，强制调用方传入 `$r('app.string.xxx')`
 * 或已本地化的字符串，从契约层面阻止在框架 helper 中硬编码中文提示。
 */
export interface NGFAccessibilitySemantics {
  /** 组件逻辑 ID，应与组件 .id() 保持一致 */
  id: string;
  /** 语义角色 */
  role: NGFAccessibilityRole;
  /** 朗读主文本 → accessibilityText */
  label?: ResourceStr;
  /** 补充说明（后果、上下文）→ accessibilityDescription */
  description?: ResourceStr;
  /** 当前值 → accessibilityText 的值部分，由 helper 组合，不直接下发 */
  value?: ResourceStr;
  /** 操作提示 → accessibilityTextHint */
  textHint?: ResourceStr;
  /** 状态文本 → accessibilityStateDescription */
  stateDescription?: ResourceStr;
  /** 状态集合 */
  state?: NGFAccessibilitySemanticState;
  /** 支持的动作（语义描述） */
  actions?: Array<NGFAccessibilityAction>;
  /**
   * 自定义无障碍动作 → accessibilityCustomActions（API 26，@since 26.0.0）。
   * 与 actions 是**互补**关系：actions 是词表内的标准动作，customActions 是业务自定义动作。
   */
  customActions?: Array<NGFAccessibilityCustomAction>;
  /**
   * 无障碍滚动步长 → accessibilityActionOptions({ scrollStep })（API 23，@since 23）。
   * 仅对可滚动组件有意义。
   */
  scrollStep?: number;
  /** 分组配置 */
  grouping?: NGFAccessibilityGrouping;
  /** 无障碍层级 */
  level?: NGFAccessibilityLevel;
  /** NGF 排序意图（ArkUI 26 无数值型遍历属性，仅供 NGF 自身排序/断言使用） */
  traversalOrder?: number;
  /** 显式指定下一个无障碍焦点目标 → accessibilityNextFocusId */
  traversalNextId?: string;
  /**
   * 焦点跳转时是否把目标的**后代可聚焦节点**也纳入搜索 →
   * accessibilityNextFocusId(nextId, { isConsiderDescendants })（API 26，@since 26.0.0）。
   * 仅当同时设置了 traversalNextId 才有意义。
   */
  traversalConsiderDescendants?: boolean;
  /** 是否为无障碍默认焦点 → accessibilityDefaultFocus */
  defaultFocus?: boolean;
  /** 是否允许无障碍滚动触发 → accessibilityScrollTriggerable */
  scrollTriggerable?: boolean;
}

/**
 * 语义审计问题码。
 * 使用稳定机器可读码，便于 Hypium 断言和后续回归；
 * message 是开发者诊断文本，不是面向用户的 UI 文案，因此不进 i18n 资源。
 */
export enum NGFAccessibilitySemanticsIssueCode {
  EMPTY_ID = 'empty_id',
  MISSING_LABEL = 'missing_label',
  INTERACTIVE_WITHOUT_ACTION = 'interactive_without_action',
  STATE_ROLE_MISMATCH = 'state_role_mismatch',
  SELF_TRAVERSAL_NEXT_ID = 'self_traversal_next_id',
  IMAGE_WITHOUT_LABEL = 'image_without_label',
  DECORATIVE_WITH_LABEL = 'decorative_with_label',
  /** 自定义动作缺少可朗读名称；空名称的动作对读屏用户不可用 */
  CUSTOM_ACTION_WITHOUT_NAME = 'custom_action_without_name',
  /** 滚动步长必须是正数，否则无障碍滚动会无效或方向错误 */
  INVALID_SCROLL_STEP = 'invalid_scroll_step',
  /** 设置了焦点跳转参数却没有设置跳转目标，参数不会生效 */
  ORPHAN_TRAVERSAL_PARAM = 'orphan_traversal_param'
}

/** 单条审计问题 */
export interface NGFAccessibilitySemanticsIssue {
  code: NGFAccessibilitySemanticsIssueCode;
  message: string;
}

/** 一次语义审计结果，对应设计文档 §7「语义」验收面的最小证据 */
export interface NGFAccessibilitySemanticsAudit {
  id: string;
  valid: boolean;
  issues: Array<NGFAccessibilitySemanticsIssue>;
}

/** 需要具备名称与动作的可操作角色 */
const NGF_INTERACTIVE_ROLES: Array<NGFAccessibilityRole> = [
  NGFAccessibilityRole.BUTTON,
  NGFAccessibilityRole.HYPERLINK,
  NGFAccessibilityRole.CHECKBOX,
  NGFAccessibilityRole.RADIO,
  NGFAccessibilityRole.SWITCH,
  NGFAccessibilityRole.SLIDER,
  NGFAccessibilityRole.TOGGLER,
  NGFAccessibilityRole.SELECT,
  NGFAccessibilityRole.TEXT_INPUT,
  NGFAccessibilityRole.TEXT_AREA,
  NGFAccessibilityRole.TEXT_FIELD,
  NGFAccessibilityRole.SEARCH,
  NGFAccessibilityRole.MENU_ITEM,
  NGFAccessibilityRole.STEPPER_ITEM,
  NGFAccessibilityRole.TAB_CONTENT
];

/** 允许携带 checked 状态的角色 */
const NGF_CHECKABLE_ROLES: Array<NGFAccessibilityRole> = [
  NGFAccessibilityRole.CHECKBOX,
  NGFAccessibilityRole.RADIO,
  NGFAccessibilityRole.SWITCH,
  NGFAccessibilityRole.TOGGLER
];

function pushIssue(target: Array<NGFAccessibilitySemanticsIssue>,
  code: NGFAccessibilitySemanticsIssueCode, message: string): void {
  const issue: NGFAccessibilitySemanticsIssue = { code: code, message: message };
  target.push(issue);
}

/**
 * 审计一份语义模型是否满足 NGF 基线。
 *
 * 这不是运行时能力，而是设计期/测试期检查：
 * 让“语义清单”从人工评审变成可断言的代码证据。
 */
export function auditAccessibilitySemantics(semantics: NGFAccessibilitySemantics): NGFAccessibilitySemanticsAudit {
  const issues: Array<NGFAccessibilitySemanticsIssue> = [];
  const role: NGFAccessibilityRole = semantics.role;
  const isInteractive: boolean = NGF_INTERACTIVE_ROLES.includes(role);
  const hasLabel: boolean = semantics.label !== undefined;
  const actions: Array<NGFAccessibilityAction> | undefined = semantics.actions;
  const customActions: Array<NGFAccessibilityCustomAction> | undefined = semantics.customActions;
  // 自定义动作同样构成"可执行动作"，否则只挂自定义动作的节点会被误判为无动作
  const hasAction: boolean = (actions !== undefined && actions.length > 0)
    || (customActions !== undefined && customActions.length > 0);
  const level: NGFAccessibilityLevel = semantics.level ?? NGFAccessibilityLevel.AUTO;
  const decorative: boolean = level === NGFAccessibilityLevel.NO || level === NGFAccessibilityLevel.NO_HIDE_DESCENDANTS;

  if (semantics.id.length === 0) {
    pushIssue(issues, NGFAccessibilitySemanticsIssueCode.EMPTY_ID,
      'Semantics id must not be empty; keep it identical to the component .id().');
  }
  if (isInteractive && !hasLabel) {
    pushIssue(issues, NGFAccessibilitySemanticsIssueCode.MISSING_LABEL,
      'Interactive role requires a label so the screen reader can announce it.');
  }
  const state: NGFAccessibilitySemanticState | undefined = semantics.state;
  // 被禁用的可操作控件本来就没有可执行动作，不应因此被判为问题
  const disabled: boolean = state !== undefined && state.enabled === false;
  if (isInteractive && !hasAction && !disabled) {
    pushIssue(issues, NGFAccessibilitySemanticsIssueCode.INTERACTIVE_WITHOUT_ACTION,
      'Interactive role should declare at least one accessibility action unless it is disabled.');
  }
  if (role === NGFAccessibilityRole.IMAGE && !hasLabel && !decorative) {
    pushIssue(issues, NGFAccessibilitySemanticsIssueCode.IMAGE_WITHOUT_LABEL,
      'Informative image requires a label; decorative image must set level to NO.');
  }
  if (decorative && hasLabel) {
    pushIssue(issues, NGFAccessibilitySemanticsIssueCode.DECORATIVE_WITH_LABEL,
      'Decorative node is excluded from the accessibility tree; its label will never be announced.');
  }
  if (state !== undefined && state.checked !== undefined && !NGF_CHECKABLE_ROLES.includes(role)) {
    pushIssue(issues, NGFAccessibilitySemanticsIssueCode.STATE_ROLE_MISMATCH,
      'checked state is only meaningful for checkable roles.');
  }
  const nextId: string | undefined = semantics.traversalNextId;
  if (nextId !== undefined && nextId === semantics.id) {
    pushIssue(issues, NGFAccessibilitySemanticsIssueCode.SELF_TRAVERSAL_NEXT_ID,
      'traversalNextId must not point to the node itself.');
  }
  if (customActions !== undefined) {
    for (let i = 0; i < customActions.length; i++) {
      const name: ResourceStr = customActions[i].name;
      if (typeof name === 'string' && name.length === 0) {
        pushIssue(issues, NGFAccessibilitySemanticsIssueCode.CUSTOM_ACTION_WITHOUT_NAME,
          'Custom action requires a non-empty name; a nameless action cannot be announced.');
      }
    }
  }
  const scrollStep: number | undefined = semantics.scrollStep;
  if (scrollStep !== undefined && !(scrollStep > 0)) {
    pushIssue(issues, NGFAccessibilitySemanticsIssueCode.INVALID_SCROLL_STEP,
      'scrollStep must be greater than zero when specified.');
  }
  if (semantics.traversalConsiderDescendants !== undefined && nextId === undefined) {
    pushIssue(issues, NGFAccessibilitySemanticsIssueCode.ORPHAN_TRAVERSAL_PARAM,
      'traversalConsiderDescendants only takes effect together with traversalNextId.');
  }

  const audit: NGFAccessibilitySemanticsAudit = {
    id: semantics.id,
    valid: issues.length === 0,
    issues: issues
  };
  return audit;
}
