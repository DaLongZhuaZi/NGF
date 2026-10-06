/**
 * NGF 无障碍语义 → ArkUI 属性绑定器（P4）
 *
 * 这一层把 `NGFAccessibilitySemantics` 翻译成 ArkUI 通用属性。
 * 它刻意拆成两半：
 *
 * 1. `resolveAccessibilityAttributes()` —— **纯函数**，只做 NGF 侧判定，
 *    不接触任何 ArkUI 类型，因此可以用 Hypium 本地单测断言；
 * 2. `applyAccessibilityAttributes()` —— 极薄的 ArkUI 调用层，
 *    只负责把已解析结果落到组件上。
 *
 * ## 必须保持的诚实边界
 *
 * 设计文档 §3.1 已用 API 26 SDK 声明逐行确认：ArkUI **没有**
 * `accessibilityEnabled` / `accessibilityExpanded` / `accessibilityBusy` 之类的属性。
 * 因此本文件不会假装它们存在，而是把这类语义收集进 `unresolved`，
 * 明确告诉调用方"这一项必须由你自己用文本或组件状态表达"。
 *
 * 同理，ArkUI 26 的 `AccessibilityAction` 只有 UNDEFINED_ACTION 与 ACCESSIBILITY_CLICK，
 * 所以 `actions` 只作为语义描述收集，不做成"可执行动作注册"。
 */

import {
  NGFAccessibilityCustomAction,
  NGFAccessibilityGrouping,
  NGFAccessibilityLevel,
  NGFAccessibilityRole,
  NGFAccessibilitySemantics,
  NGFAccessibilitySemanticState
} from '../../deviceAwareness/contracts/NGFAccessibilitySemantics';
import { resolveResourceString } from '../../i18n/utils/ResourceStringResolver';

/**
 * 无法用 ArkUI 属性直接表达、必须由调用方另行处理的语义类别。
 * 使用稳定机器可读码，便于单测断言。
 */
export enum NGFAccessibilityUnresolvedKind {
  /** 展开/折叠：无独立属性，需经 stateDescription 文本表达 */
  EXPANDED = 'expanded',
  /** 忙碌中：无独立属性，需经 stateDescription 文本或 role 表达 */
  BUSY = 'busy',
  /** 可用/禁用：由组件自身 enabled 状态表达，无独立无障碍属性 */
  ENABLED = 'enabled',
  /** 当前值：ArkUI 只有 accessibilityText 一个入口，与 label 的合并需走 i18n */
  VALUE = 'value',
  /** 支持的动作：ArkUI 26 只能拦截点击，其余仅为语义描述 */
  ACTIONS = 'actions',
  /** 数值型遍历顺序：ArkUI 26 无对应属性，仅能通过 nextFocusId 表达 */
  TRAVERSAL_ORDER = 'traversal_order'
}

/** 单条未解析说明 */
export interface NGFAccessibilityUnresolvedNote {
  kind: NGFAccessibilityUnresolvedKind;
  /** 开发者诊断文本（英文），不是面向用户的 UI 文案 */
  guidance: string;
}

/**
 * 已解析的无障碍属性集。
 * 字段与 ArkUI 属性的对应关系写在每个字段注释里，避免实现者猜。
 */
export interface NGFAccessibilityResolvedAttributes {
  /** → accessibilityText(value: string | Resource) */
  text?: ResourceStr;
  /** → accessibilityDescription(value: string | Resource) */
  description?: ResourceStr;
  /** → accessibilityTextHint(value: string)。ArkUI 该重载只接受 string，Resource 需先解析 */
  textHint?: ResourceStr;
  /** → accessibilityStateDescription(description: string | Resource | undefined) */
  stateDescription?: ResourceStr;
  /** → accessibilityLevel(value: string) */
  level: NGFAccessibilityLevel;
  /** → accessibilityRole(role: AccessibilityRoleType) */
  role: NGFAccessibilityRole;
  /** → accessibilityGroup(isGroup, accessibilityOptions) */
  grouping?: NGFAccessibilityGrouping;
  /** → accessibilityChecked(isCheck) */
  checked?: boolean;
  /** → accessibilitySelected(isSelect) */
  selected?: boolean;
  /** → accessibilityNextFocusId(nextId) */
  nextFocusId?: string;
  /** → accessibilityNextFocusId(nextId, { isConsiderDescendants })（API 26） */
  traversalConsiderDescendants?: boolean;
  /** → accessibilityDefaultFocus(focus) */
  defaultFocus?: boolean;
  /** → accessibilityScrollTriggerable(isTriggerable) */
  scrollTriggerable?: boolean;
  /** → accessibilityCustomActions(actions)（API 26，@since 26.0.0） */
  customActions?: Array<NGFAccessibilityCustomAction>;
  /** → accessibilityActionOptions({ scrollStep })（API 23，@since 23） */
  scrollStep?: number;
  /** 无法直接落属性的语义，调用方必须自行处理 */
  unresolved: Array<NGFAccessibilityUnresolvedNote>;
}

function pushNote(target: Array<NGFAccessibilityUnresolvedNote>,
  kind: NGFAccessibilityUnresolvedKind, guidance: string): void {
  const note: NGFAccessibilityUnresolvedNote = { kind: kind, guidance: guidance };
  target.push(note);
}

/**
 * 把语义模型解析为可下发的属性集。**纯函数，不依赖 ArkUI 运行时。**
 */
export function resolveAccessibilityAttributes(
  semantics: NGFAccessibilitySemantics): NGFAccessibilityResolvedAttributes {
  const notes: Array<NGFAccessibilityUnresolvedNote> = [];
  const state: NGFAccessibilitySemanticState | undefined = semantics.state;

  if (semantics.value !== undefined) {
    pushNote(notes, NGFAccessibilityUnresolvedKind.VALUE,
      'ArkUI exposes a single accessibilityText entry; merge value into the announced text through i18n.');
  }
  if (state !== undefined) {
    if (state.expanded !== undefined) {
      pushNote(notes, NGFAccessibilityUnresolvedKind.EXPANDED,
        'No accessibilityExpanded attribute exists; express it through accessibilityStateDescription text.');
    }
    if (state.busy !== undefined) {
      pushNote(notes, NGFAccessibilityUnresolvedKind.BUSY,
        'No accessibilityBusy attribute exists; express it through accessibilityStateDescription text.');
    }
    if (state.enabled !== undefined) {
      pushNote(notes, NGFAccessibilityUnresolvedKind.ENABLED,
        'Use the component own enabled state; ArkUI has no accessibility-level enabled attribute.');
    }
  }
  const actions = semantics.actions;
  if (actions !== undefined && actions.length > 0) {
    pushNote(notes, NGFAccessibilityUnresolvedKind.ACTIONS,
      'ArkUI 26 only exposes onAccessibilityActionIntercept for ACCESSIBILITY_CLICK; other actions are descriptive only.');
  }
  if (semantics.traversalOrder !== undefined) {
    pushNote(notes, NGFAccessibilityUnresolvedKind.TRAVERSAL_ORDER,
      'ArkUI 26 has no numeric traversal order; only accessibilityNextFocusId can be sent to the system.');
  }

  const resolved: NGFAccessibilityResolvedAttributes = {
    text: semantics.label,
    description: semantics.description,
    textHint: semantics.textHint,
    stateDescription: semantics.stateDescription,
    level: semantics.level ?? NGFAccessibilityLevel.AUTO,
    role: semantics.role,
    grouping: semantics.grouping,
    checked: state !== undefined ? state.checked : undefined,
    selected: state !== undefined ? state.selected : undefined,
    nextFocusId: semantics.traversalNextId,
    traversalConsiderDescendants: semantics.traversalConsiderDescendants,
    defaultFocus: semantics.defaultFocus,
    scrollTriggerable: semantics.scrollTriggerable,
    customActions: semantics.customActions,
    scrollStep: semantics.scrollStep,
    unresolved: notes
  };
  return resolved;
}

/**
 * NGF 语义角色 → ArkUI `AccessibilityRoleType` 的显式映射。
 *
 * 该表已用脚本核验：`NGFAccessibilityRole` 的全部 52 个成员在 ArkUI
 * 125 成员枚举中均 1:1 存在（0 缺口）。这里仍然写显式 switch，
 * 而不是依赖名称约定，避免未来任一端的重命名造成静默错配。
 */
export function resolveArkUiRole(role: NGFAccessibilityRole): AccessibilityRoleType {
  switch (role) {
    case NGFAccessibilityRole.BUTTON: return AccessibilityRoleType.BUTTON;
    case NGFAccessibilityRole.HYPERLINK: return AccessibilityRoleType.HYPERLINK;
    case NGFAccessibilityRole.IMAGE: return AccessibilityRoleType.IMAGE;
    case NGFAccessibilityRole.TEXT: return AccessibilityRoleType.TEXT;
    case NGFAccessibilityRole.LIST: return AccessibilityRoleType.LIST;
    case NGFAccessibilityRole.LIST_ITEM: return AccessibilityRoleType.LIST_ITEM;
    case NGFAccessibilityRole.TABS: return AccessibilityRoleType.TABS;
    case NGFAccessibilityRole.TAB_BAR: return AccessibilityRoleType.TAB_BAR;
    case NGFAccessibilityRole.TAB_CONTENT: return AccessibilityRoleType.TAB_CONTENT;
    case NGFAccessibilityRole.DIALOG: return AccessibilityRoleType.DIALOG;
    case NGFAccessibilityRole.ALERT_DIALOG: return AccessibilityRoleType.ALERT_DIALOG;
    case NGFAccessibilityRole.MENU: return AccessibilityRoleType.MENU;
    case NGFAccessibilityRole.MENU_ITEM: return AccessibilityRoleType.MENU_ITEM;
    case NGFAccessibilityRole.CHECKBOX: return AccessibilityRoleType.CHECKBOX;
    case NGFAccessibilityRole.RADIO: return AccessibilityRoleType.RADIO;
    case NGFAccessibilityRole.SWITCH: return AccessibilityRoleType.SWITCH;
    case NGFAccessibilityRole.SLIDER: return AccessibilityRoleType.SLIDER;
    case NGFAccessibilityRole.TEXT_INPUT: return AccessibilityRoleType.TEXT_INPUT;
    case NGFAccessibilityRole.TEXT_AREA: return AccessibilityRoleType.TEXT_AREA;
    case NGFAccessibilityRole.TEXT_FIELD: return AccessibilityRoleType.TEXT_FIELD;
    case NGFAccessibilityRole.SEARCH: return AccessibilityRoleType.SEARCH;
    case NGFAccessibilityRole.PROGRESS: return AccessibilityRoleType.PROGRESS;
    case NGFAccessibilityRole.LOADING_PROGRESS: return AccessibilityRoleType.LOADING_PROGRESS;
    case NGFAccessibilityRole.NAVIGATION: return AccessibilityRoleType.NAVIGATION;
    case NGFAccessibilityRole.NAV_DESTINATION: return AccessibilityRoleType.NAV_DESTINATION;
    case NGFAccessibilityRole.NAVIGATION_BAR: return AccessibilityRoleType.NAVIGATION_BAR;
    case NGFAccessibilityRole.BACK_BUTTON: return AccessibilityRoleType.BACK_BUTTON;
    case NGFAccessibilityRole.TITLE_BAR: return AccessibilityRoleType.TITLE_BAR;
    case NGFAccessibilityRole.SCROLL: return AccessibilityRoleType.SCROLL;
    case NGFAccessibilityRole.GRID: return AccessibilityRoleType.GRID;
    case NGFAccessibilityRole.GRID_ITEM: return AccessibilityRoleType.GRID_ITEM;
    case NGFAccessibilityRole.WATER_FLOW: return AccessibilityRoleType.WATER_FLOW;
    case NGFAccessibilityRole.FLOW_ITEM: return AccessibilityRoleType.FLOW_ITEM;
    case NGFAccessibilityRole.TOGGLER: return AccessibilityRoleType.TOGGLER;
    case NGFAccessibilityRole.SELECT: return AccessibilityRoleType.SELECT;
    case NGFAccessibilityRole.STEPPER: return AccessibilityRoleType.STEPPER;
    case NGFAccessibilityRole.STEPPER_ITEM: return AccessibilityRoleType.STEPPER_ITEM;
    case NGFAccessibilityRole.DATE_PICKER: return AccessibilityRoleType.DATE_PICKER;
    case NGFAccessibilityRole.TIME_PICKER: return AccessibilityRoleType.TIME_PICKER;
    case NGFAccessibilityRole.CALENDAR_PICKER: return AccessibilityRoleType.CALENDAR_PICKER;
    case NGFAccessibilityRole.TEXT_PICKER: return AccessibilityRoleType.TEXT_PICKER;
    case NGFAccessibilityRole.WEB: return AccessibilityRoleType.WEB;
    case NGFAccessibilityRole.VIDEO: return AccessibilityRoleType.VIDEO;
    case NGFAccessibilityRole.RATING: return AccessibilityRoleType.RATING;
    case NGFAccessibilityRole.DIVIDER: return AccessibilityRoleType.DIVIDER;
    case NGFAccessibilityRole.BLANK: return AccessibilityRoleType.BLANK;
    case NGFAccessibilityRole.REFRESH: return AccessibilityRoleType.REFRESH;
    case NGFAccessibilityRole.SWIPER: return AccessibilityRoleType.SWIPER;
    case NGFAccessibilityRole.QRCODE: return AccessibilityRoleType.QRCODE;
    case NGFAccessibilityRole.MARQUEE: return AccessibilityRoleType.MARQUEE;
    case NGFAccessibilityRole.BADGE_COMPONENT: return AccessibilityRoleType.BADGE_COMPONENT;
    default: return AccessibilityRoleType.ROLE_NONE;
  }
}

/**
 * 把语义模型落到 ArkUI 组件上。
 *
 * ## 为什么用 `AttributeModifier` 而不是普通函数
 *
 * 最初写成 `applyAccessibilityAttributes<T extends CommonMethod<T>>(component, semantics): T`，
 * 结果 ArkTS 报 **"does not meet UI component syntax"**：ArkUI 的声明式 `build()` 只接受
 * 组件调用与属性链，**不允许把"返回组件的普通函数调用"当作组件根节点**。
 *
 * 官方支持的复用属性集方式是 `AttributeModifier`（API 26 声明：
 * `attributeModifier(modifier: AttributeModifier<T>): T` @since 12，
 * 文档明确写 "You need a custom class to implement the AttributeModifier API"）。
 * 它在属性链里调用，因此可以正常出现在 `build()` 中：
 *
 * ```typescript
 * Button(this.label)
 *   .attributeModifier(new NGFAccessibilityAttributeModifier(this.buildSemantics()))
 * ```
 *
 * `applyNormalAttribute` 用**类字段箭头函数**实现而不是成员方法：见候选规则 PR-C001，
 * ArkTS 下可选方法当属性读取不可靠，实现方用类字段更稳。
 */
export class NGFAccessibilityAttributeModifier implements AttributeModifier<CommonAttribute> {
  private readonly semantics: NGFAccessibilitySemantics;
  private readonly context: Context | undefined;

  constructor(semantics: NGFAccessibilitySemantics, context?: Context) {
    this.semantics = semantics;
    this.context = context;
  }

  readonly applyNormalAttribute: (instance: CommonAttribute) => void =
    (instance: CommonAttribute): void => {
      const resolved: NGFAccessibilityResolvedAttributes = resolveAccessibilityAttributes(this.semantics);

      const text: ResourceStr | undefined = resolved.text;
      if (text !== undefined) {
        if (typeof text === 'string') {
          instance.accessibilityText(text);
        } else {
          instance.accessibilityText(text);
        }
      }

      const description: ResourceStr | undefined = resolved.description;
      if (description !== undefined) {
        if (typeof description === 'string') {
          instance.accessibilityDescription(description);
        } else {
          instance.accessibilityDescription(description);
        }
      }

      const hint: ResourceStr | undefined = resolved.textHint;
      if (hint !== undefined) {
        // accessibilityTextHint 只接受 string；Resource 必须先用 context 解析。
        const hintText: string = resolveResourceString(this.context, hint);
        if (hintText.length > 0) {
          instance.accessibilityTextHint(hintText);
        }
      }

      const stateDescription: ResourceStr | undefined = resolved.stateDescription;
      if (stateDescription !== undefined) {
        instance.accessibilityStateDescription(stateDescription);
      }

      instance.accessibilityLevel(resolved.level);
      instance.accessibilityRole(resolveArkUiRole(resolved.role));

      const grouping: NGFAccessibilityGrouping | undefined = resolved.grouping;
      if (grouping !== undefined) {
        const options: AccessibilityOptions = {};
        if (grouping.accessibilityPreferred !== undefined) {
          options.accessibilityPreferred = grouping.accessibilityPreferred;
        }
        if (grouping.stateControllerRole !== undefined) {
          options.stateControllerRoleType = resolveArkUiRole(grouping.stateControllerRole);
        }
        if (grouping.stateControllerId !== undefined) {
          options.stateControllerId = grouping.stateControllerId;
        }
        if (grouping.actionControllerRole !== undefined) {
          options.actionControllerRoleType = resolveArkUiRole(grouping.actionControllerRole);
        }
        if (grouping.actionControllerId !== undefined) {
          options.actionControllerId = grouping.actionControllerId;
        }
        instance.accessibilityGroup(grouping.isGroup, options);
      }

      const checked: boolean | undefined = resolved.checked;
      if (checked !== undefined) {
        instance.accessibilityChecked(checked);
      }

      const selected: boolean | undefined = resolved.selected;
      if (selected !== undefined) {
        instance.accessibilitySelected(selected);
      }

      const nextFocusId: string | undefined = resolved.nextFocusId;
      if (nextFocusId !== undefined) {
        const consider: boolean | undefined = resolved.traversalConsiderDescendants;
        if (consider !== undefined) {
          // API 26（@since 26.0.0）双参重载
          const params: AccessibilityNextFocusParams = { isConsiderDescendants: consider };
          instance.accessibilityNextFocusId(nextFocusId, params);
        } else {
          instance.accessibilityNextFocusId(nextFocusId);
        }
      }

      const defaultFocus: boolean | undefined = resolved.defaultFocus;
      if (defaultFocus !== undefined) {
        instance.accessibilityDefaultFocus(defaultFocus);
      }

      const scrollTriggerable: boolean | undefined = resolved.scrollTriggerable;
      if (scrollTriggerable !== undefined) {
        instance.accessibilityScrollTriggerable(scrollTriggerable);
      }

      // API 26（@since 26.0.0）：自定义无障碍动作
      const customActions: Array<NGFAccessibilityCustomAction> | undefined = resolved.customActions;
      if (customActions !== undefined && customActions.length > 0) {
        const actions: Array<AccessibilityCustomAction> = [];
        for (let i = 0; i < customActions.length; i++) {
          const action: AccessibilityCustomAction = {
            name: customActions[i].name,
            onAction: customActions[i].onAction
          };
          actions.push(action);
        }
        instance.accessibilityCustomActions(actions);
      }

      // API 23（@since 23）：无障碍滚动步长
      const scrollStep: number | undefined = resolved.scrollStep;
      if (scrollStep !== undefined) {
        const options: AccessibilityActionOptions = { scrollStep: scrollStep };
        instance.accessibilityActionOptions(options);
      }
    };
}

/**
 * 互斥选项按钮（分段控件）的无障碍修饰器。
 *
 * ## 它解决什么问题
 *
 * 设置页里「主题」「语言」这类设置，常见布局是：
 *
 * ```
 * 主题            跟随系统      ← 只读的「标签 + 值」行
 * [自动] [浅色] [深色]          ← 真正的选项按钮
 * ```
 *
 * 三个选项按钮**在无障碍树里是完全孤立的**：读屏用户听到的是
 * 「自动」「浅色」「深色」三个词，**不知道它们是「主题」的选项**，
 * 也**不知道当前选中的是哪个** —— 选中态只由背景色/描边表达，读屏读不到。
 *
 * 这个修饰器做两件事：
 * 1. `accessibilityText` = 「组名，选项名」→ 例如「主题，自动」
 * 2. `accessibilitySelected` = 是否选中 → 读屏会念「已选中」
 *
 * ## 为什么用 `accessibilitySelected` 而不是 `accessibilityChecked`
 *
 * 官方对照表：`Selected` 用于「单选列表、标签页等**互斥选择**场景」；
 * `Checked` 用于「复选框、开关等二态/三态组件」。
 * 分段控件是互斥单选 → 必须用 Selected；用错会被读成「已勾选」。
 *
 * ## 用法
 *
 * ```ts
 * Button($r('app.string.theme_auto'))
 *   .attributeModifier(new NGFAccessibilityOptionModifier(
 *     $r('app.string.ui_str_2416'),              // 组名「主题」
 *     $r('app.string.ui_str_2418'),              // 选项名「自动」
 *     this.currentTheme === NGFThemeMode.AUTO,   // 是否选中
 *     this.getUIContext()?.getHostContext()      // 解析 Resource 用
 *   ))
 * ```
 *
 * > ⚠️ 与 `NGFAccessibilityAttributeModifier` 同一条硬约束：
 * > 修饰器实例**不要**在 `build()` 路径里用 getter 现场构造 —— 会破坏渲染。
 * > 选项按钮数量固定时，直接在链上 `new` 是安全的（每次 build 都会重建，
 * > 但这里没有跨帧缓存的状态需要保持）。
 */
export class NGFAccessibilityOptionModifier implements AttributeModifier<ButtonAttribute> {
  private readonly context: Context | undefined;
  private readonly groupLabel: ResourceStr;
  private readonly optionLabel: ResourceStr;
  private readonly selected: boolean;

  constructor(groupLabel: ResourceStr, optionLabel: ResourceStr, selected: boolean, context?: Context) {
    this.groupLabel = groupLabel;
    this.optionLabel = optionLabel;
    this.selected = selected;
    this.context = context;
  }

  /**
   * 拼出「组名，选项名」。
   *
   * ⚠️ **绝不能写成 `$r('...') + '，' + label`** —— `$r()` 与字符串相加会渲染成
   * `[object Object]`（项目规则 **PR-C004**）。必须先用 `resolveResourceString()` 解析。
   */
  private buildAccessibilityText(): string {
    const group: string = resolveResourceString(this.context, this.groupLabel);
    const option: string = resolveResourceString(this.context, this.optionLabel);
    if (group.length === 0) {
      return option;
    }
    if (option.length === 0) {
      return group;
    }
    return `${group}，${option}`;
  }

  readonly applyNormalAttribute: (instance: ButtonAttribute) => void =
    (instance: ButtonAttribute): void => {
      instance.accessibilityText(this.buildAccessibilityText());
      // 互斥单选语义 —— 读屏据此播报「已选中」
      instance.accessibilitySelected(this.selected);
    };
}
