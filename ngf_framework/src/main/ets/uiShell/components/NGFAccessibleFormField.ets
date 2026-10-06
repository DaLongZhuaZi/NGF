/**
 * NGF 无障碍表单字段（P4）
 *
 * ## 为什么不分组（关键设计决策）
 *
 * 直觉上应该对"标签 + 输入框 + 错误提示"整块用
 * `accessibilityGroup(isGroup=true)` 合并成一个语义节点，让读屏一次念完。
 * **但这是错的**：API 26 声明里明确写着
 *
 * > When accessibility grouping is enabled, the component and all its children are treated as a
 * > **single selectable unit**, and the accessibility service will **no longer focus on the individual
 * > child components**.
 *
 * 也就是说，一旦分组，`TextInput` 会失去独立焦点 —— **用户无法再聚焦并编辑它**。
 * 所以表单字段**必须不分组**，改为：
 *
 * 1. 组件只负责**布局**与**非颜色冗余表达**（必填标记、错误前缀都是文字，不是只有颜色）；
 * 2. 标签与错误的"朗读绑定"由调用方通过 `buildFormFieldSemantics()` 产出的语义，
 *    用 `NGFAccessibilityAttributeModifier` 施加到**真正的输入控件**上。
 *
 * ## 重复朗读 vs 静默丢失
 *
 * 如果调用方把标签绑到了输入控件上，标签文本节点仍会单独被朗读一次（重复）。
 * `hideLabelWhenBound` 可以把它从无障碍树移除 —— 但**默认是 false**：
 * 宁可重复朗读，也不能因为调用方漏绑而让标签彻底读不出来。
 */

import { a11yFontFor, a11yGroupSpacingFor, a11yLineHeightFor, a11yTouchTarget } from '../utils/NGFA11yTextScale';
import {
  NGFAccessibilityAction,
  NGFAccessibilityLevel,
  NGFAccessibilityRole,
  NGFAccessibilitySemantics,
  NGFAccessibilitySemanticState
} from '../../deviceAwareness/contracts/NGFAccessibilitySemantics';

/**
 * 表单字段语义配置。
 *
 * 只做**优先级选择**，不做字符串拼接 —— ArkTS 下 `ResourceStr` 无法拼接，
 * 而硬编码分隔符会引入未本地化的标点。
 */
export interface NGFFormFieldSemanticsConfig {
  /** 组件逻辑 ID，应与输入控件的 .id() 一致 */
  id: string;
  /** 字段名（必填信息请并入该资源文案，理由见下方 description 优先级说明） */
  label: ResourceStr;
  /** 控件角色，默认 TEXT_INPUT */
  role?: NGFAccessibilityRole;
  /** 错误文本，优先级最高 */
  errorText?: ResourceStr;
  /** 帮助文本 */
  helpText?: ResourceStr;
  /** 单位 */
  unit?: ResourceStr;
  /** 必填标记，优先级最低 */
  requiredMarker?: ResourceStr;
  /** 是否可用 */
  enabled: boolean;
}

/**
 * 为表单输入控件生成语义。
 *
 * `description` 按 `errorText > helpText > unit > requiredMarker` 取**第一个存在**的值：
 * 错误最紧急，所以排最前；必填排最后 —— 如果同时存在错误/帮助/单位，"必填"不会被朗读，
 * 这种情况请把必填信息并入 `label` 资源文案。
 *
 * 被禁用时不声明动作：禁用的控件本来就没有可执行动作，
 * 审计也会相应放过（见 `INTERACTIVE_WITHOUT_ACTION`）。
 */
export function buildFormFieldSemantics(config: NGFFormFieldSemanticsConfig): NGFAccessibilitySemantics {
  let description: ResourceStr | undefined = config.errorText;
  if (description === undefined) {
    description = config.helpText;
  }
  if (description === undefined) {
    description = config.unit;
  }
  if (description === undefined) {
    description = config.requiredMarker;
  }

  const state: NGFAccessibilitySemanticState = { enabled: config.enabled };

  const semantics: NGFAccessibilitySemantics = {
    id: config.id,
    role: config.role ?? NGFAccessibilityRole.TEXT_INPUT,
    label: config.label,
    description: description,
    state: state
  };
  if (config.enabled) {
    semantics.actions = [NGFAccessibilityAction.CLICK];
  }
  return semantics;
}

@Component
export struct NGFAccessibleFormField {
  /**
   * 是否由我们主动抬字号（= 关怀模式）。
   *
   * 与 `isElderly` **不同**：`isElderly` 还包含「系统字体缩放 > 1」。
   * ArkUI 的 `fontSize(number)` 单位是 fp，系统已按缩放放大过字号，
   * 我们再抬一次就是**双重放大**（见 PR-011）。
   */
  @Prop boostFont: boolean = true;

  /**
   * 是否处于适老档。
   *
   * 用 **原始类型 `@Prop`** 而不是传 `NGFA11yTextScale` 实例 ——
   * ArkTS 的 `@Prop` 会深拷贝对象，类实例经拷贝后原型可能丢失、方法不可用。
   * 默认 false，未传时行为与改造前完全一致（零视觉回归）。
   */
  @Prop isElderly: boolean = false;

  /** 组件逻辑 ID */
  componentId: string = 'ngf_accessible_form_field';
  /** 字段名 */
  label: ResourceStr = '';
  /** 必填标记文案（走 i18n）。必须提供**可见文字**，不能只用颜色或星号表达 */
  requiredMarker?: ResourceStr;
  /** 是否必填 */
  isRequired: boolean = false;
  /** 错误文本（走 i18n） */
  errorText?: ResourceStr;
  /** 错误前缀文案（走 i18n），保证错误不只靠颜色表达 */
  errorPrefix?: ResourceStr;
  /** 帮助文本 */
  helpText?: ResourceStr;
  /** 错误文字颜色；默认使用 NGF 错误文本令牌 */
  errorColor: ResourceColor = $r('app.color.ngf_text_error');
  /** 是否可用 */
  isEnabled: boolean = true;
  /** 最小点击区（vp） */
  minTouchTarget: number = 44;
  /**
   * 是否把标签与必填标记从无障碍树隐藏。
   * **仅当**调用方已把 `buildFormFieldSemantics()` 的结果绑到输入控件上时才应设为 true，
   * 否则标签将完全不可朗读。默认 false。
   */
  hideLabelWhenBound: boolean = false;
  @Builder defaultBuilder() {}
  /** 输入控件插槽：由调用方渲染真正的 TextInput / TextArea / 选择器等 */
  @BuilderParam controlBuilder: () => void = this.defaultBuilder;

  build() {
    Column({ space: a11yGroupSpacingFor(this.isElderly, 6) }) {
      Row({ space: 4 }) {
        Text(this.label)
          .fontSize(a11yFontFor(this.isElderly, 15, this.boostFont))
          .lineHeight(a11yLineHeightFor(this.isElderly, a11yFontFor(this.isElderly, 15, this.boostFont)))
          .fontColor($r('app.color.text_primary'))
          .accessibilityLevel(this.hideLabelWhenBound ? NGFAccessibilityLevel.NO : NGFAccessibilityLevel.AUTO)
        if (this.isRequired && this.requiredMarker !== undefined) {
          Text(this.requiredMarker)
            .fontSize(a11yFontFor(this.isElderly, 15, this.boostFont))
            .lineHeight(a11yLineHeightFor(this.isElderly, a11yFontFor(this.isElderly, 15, this.boostFont)))
            .fontColor($r('app.color.text_secondary'))
            .accessibilityLevel(this.hideLabelWhenBound ? NGFAccessibilityLevel.NO : NGFAccessibilityLevel.AUTO)
        }
      }
      .width('100%')

      this.controlBuilder()

      if (this.errorText !== undefined) {
        Row({ space: 4 }) {
          if (this.errorPrefix !== undefined) {
            Text(this.errorPrefix)
              .fontSize(a11yFontFor(this.isElderly, 13, this.boostFont))
              .lineHeight(a11yLineHeightFor(this.isElderly, a11yFontFor(this.isElderly, 13, this.boostFont)))
              .fontColor(this.errorColor)
          }
          Text(this.errorText)
            .fontSize(a11yFontFor(this.isElderly, 13, this.boostFont))
            .lineHeight(a11yLineHeightFor(this.isElderly, a11yFontFor(this.isElderly, 13, this.boostFont)))
            .fontColor(this.errorColor)
            .layoutWeight(1)
        }
        .width('100%')
      } else if (this.helpText !== undefined) {
        Text(this.helpText)
          .fontSize(a11yFontFor(this.isElderly, 13, this.boostFont))
          .lineHeight(a11yLineHeightFor(this.isElderly, a11yFontFor(this.isElderly, 13, this.boostFont)))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .constraintSize({ minHeight: this.minTouchTarget })
  }
}
