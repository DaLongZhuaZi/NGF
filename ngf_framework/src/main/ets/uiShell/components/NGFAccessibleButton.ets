/**
 * NGF 无障碍按钮（P4）
 *
 * 设计要点：
 * 1. **不自己订阅**：触控目标等数值由调用方（页面）通过 `minTouchTarget` 传入，
 *    页面用 `NGFAccessibilityLifecycleBinding` 统一订阅策略变化并重算令牌。
 *    这样 N 个按钮不会变成 N 个全局监听器。
 * 2. **语义由 `NGFAccessibilitySemantics` 生成**，再经 `NGFAccessibilityAttributeModifier`
 *    下发，不在组件里散落手写 accessibilityXxx 调用。
 * 3. **点击区与视觉尺寸分离**：用 constraintSize 保证最小点击区。
 * 4. 文案一律走 `ResourceStr`，组件内不硬编码任何用户可见文字。
 *
 * 注意：属性名不能用 `enabled`——它与 ArkUI `CustomComponent` 的成员冲突（实测编译报错），
 * 故用 `isEnabled`。
 */

import { a11yFontFor, a11yLineHeightFor, a11yTouchTarget } from '../utils/NGFA11yTextScale';
import {
  NGFAccessibilityAction,
  NGFAccessibilityRole,
  NGFAccessibilitySemantics
} from '../../deviceAwareness/contracts/NGFAccessibilitySemantics';
import { NGFAccessibilityAttributeModifier } from './NGFAccessibilityAttributeBinder';

@Component
export struct NGFAccessibleButton {
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

  /** 组件逻辑 ID，应与页面内其它节点唯一 */
  componentId: string = 'ngf_accessible_button';
  /** 按钮主文案（走 i18n 资源） */
  label: ResourceStr = '';
  /** 语义补充说明：不可从文案推断的后果或上下文 */
  description?: ResourceStr;
  /** 是否可用 */
  isEnabled: boolean = true;
  /** 最小点击区边长（vp）。缺省 44 为附件2 §2.1「其他页面」下限，适老页请传 60 */
  minTouchTarget: number = 44;
  /** 视觉样式 */
  buttonType: ButtonType = ButtonType.Capsule;
  /** 点击回调 */
  onTap: () => void = (): void => {};

  private buildSemantics(): NGFAccessibilitySemantics {
    const semantics: NGFAccessibilitySemantics = {
      id: this.componentId,
      role: NGFAccessibilityRole.BUTTON,
      label: this.label,
      description: this.description,
      actions: [NGFAccessibilityAction.CLICK]
    };
    return semantics;
  }

  build() {
    Button(this.label)
      .type(this.buttonType)
      .enabled(this.isEnabled)
      .constraintSize({ minWidth: this.minTouchTarget, minHeight: this.minTouchTarget })
      .attributeModifier(new NGFAccessibilityAttributeModifier(this.buildSemantics()))
      .onClick(() => {
        this.onTap();
      })
  }
}
