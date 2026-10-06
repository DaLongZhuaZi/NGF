/**
 * NGF 无障碍列表项（P4）
 *
 * 设计要点：
 * 1. 用 `accessibilityGroup(isGroup=true, { accessibilityPreferred: true })` 把
 *    「标题 → 状态 → 辅助信息」合并成**一个**语义节点，避免父节点与子 Text 被重复朗读；
 *    这正是 API 26 SDK 注释描述的"优先拼接子节点 accessibilityText"行为。
 * 2. 默认不写 label，让系统按子节点文本顺序拼接；只有自动拼接不够好时才用 `accessibleLabel` 覆盖。
 * 3. 可点击时补 `CLICK` 动作，并保证最小点击区。
 */

import { a11yFontFor, a11yGroupSpacingFor, a11yLineHeightFor, a11yTouchTarget } from '../utils/NGFA11yTextScale';
import {
  NGFAccessibilityAction,
  NGFAccessibilityGrouping,
  NGFAccessibilityRole,
  NGFAccessibilitySemantics,
  NGFAccessibilitySemanticState
} from '../../deviceAwareness/contracts/NGFAccessibilitySemantics';
import { NGFAccessibilityAttributeModifier } from './NGFAccessibilityAttributeBinder';

@Component
export struct NGFAccessibleListItem {
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
  componentId: string = 'ngf_accessible_list_item';
  /** 主标题 */
  title: ResourceStr = '';
  /** 状态文本（已选中 / 加载中 / 已完成等），走 i18n；不要只用颜色表达状态 */
  stateText?: ResourceStr;
  /** 辅助信息（时间、来源、摘要等） */
  supportingText?: ResourceStr;
  /** 覆盖自动拼接的朗读文本；仅当子节点拼接顺序不理想时使用 */
  accessibleLabel?: ResourceStr;
  /** 是否可点击 */
  actionable: boolean = true;
  /** 是否可用。注意：不能命名为 enabled，会与 ArkUI CustomComponent 成员冲突 */
  isEnabled: boolean = true;
  /** 选中态 → accessibilitySelected */
  selected?: boolean;
  /** 最小点击区（vp）。缺省 44 为附件2 §2.1「其他页面」下限 */
  minTouchTarget: number = 44;
  /** 点击回调 */
  onTap: () => void = (): void => {};

  private buildSemantics(): NGFAccessibilitySemantics {
    const state: NGFAccessibilitySemanticState = {};
    if (this.selected !== undefined) {
      state.selected = this.selected;
    }
    state.enabled = this.isEnabled;

    const grouping: NGFAccessibilityGrouping = {
      isGroup: true,
      accessibilityPreferred: true
    };

    const semantics: NGFAccessibilitySemantics = {
      id: this.componentId,
      role: NGFAccessibilityRole.LIST_ITEM,
      label: this.accessibleLabel,
      state: state,
      grouping: grouping
    };
    if (this.actionable) {
      semantics.actions = [NGFAccessibilityAction.CLICK];
    }
    return semantics;
  }

  build() {
    Row() {
      Column({ space: a11yGroupSpacingFor(this.isElderly, 4) }) {
        Text(this.title)
          .fontSize(a11yFontFor(this.isElderly, 16, this.boostFont))
          .lineHeight(a11yLineHeightFor(this.isElderly, a11yFontFor(this.isElderly, 16, this.boostFont)))
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        if (this.stateText !== undefined) {
          Text(this.stateText)
            .fontSize(a11yFontFor(this.isElderly, 13, this.boostFont))
            .lineHeight(a11yLineHeightFor(this.isElderly, a11yFontFor(this.isElderly, 13, this.boostFont)))
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
        }
        if (this.supportingText !== undefined) {
          Text(this.supportingText)
            .fontSize(a11yFontFor(this.isElderly, 13, this.boostFont))
            .lineHeight(a11yLineHeightFor(this.isElderly, a11yFontFor(this.isElderly, 13, this.boostFont)))
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.actionable) {
        // 装饰箭头：ListItem 已有完整语义
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(a11yFontFor(this.isElderly, 16, this.boostFont))
          .fontColor([$r('app.color.text_secondary')])
          .accessibilityLevel('no')
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .constraintSize({ minHeight: this.minTouchTarget })
    .enabled(this.isEnabled)
    .attributeModifier(new NGFAccessibilityAttributeModifier(this.buildSemantics()))
    .onClick(() => {
      if (this.actionable) {
        this.onTap();
      }
    })
  }
}
