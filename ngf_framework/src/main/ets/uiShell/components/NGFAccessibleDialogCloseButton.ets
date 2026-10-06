/**
 * NGF 无障碍浮窗关闭键（P4）
 *
 * 直接固化工信厅信管函〔2021〕67号 附件2 §2.4：
 * 「关闭按钮只可在左上、右上、中央底部，且最小点击响应区域不能小于44×44dp/pt」
 *
 * 组件本身无法决定自己在父容器里的位置，所以这里做两件事：
 * 1. 提供 `resolveDialogCloseAlignment()` 把规范位置映射成 ArkUI 的 `Alignment`，由父容器使用；
 * 2. 在 `aboutToAppear()` 对**非法位置**和**过小点击区**主动告警，让不合规用法在开发期暴露。
 *
 * 注意：属性名不能用 `position`——它与 ArkUI `CustomComponent` 的成员冲突（实测编译报错），
 * 故用 `closePosition`。
 */

import { a11yFontFor, a11yLineHeightFor, a11yTouchTarget } from '../utils/NGFA11yTextScale';
import { logger } from '../../utils/Logger';
import {
  NGFAccessibilityAction,
  NGFAccessibilityRole,
  NGFAccessibilitySemantics
} from '../../deviceAwareness/contracts/NGFAccessibilitySemantics';
import { NGF_INCLUSIVE_DESIGN_METRICS } from '../../deviceAwareness/contracts/NGFInclusiveDesignPolicy';
import {
  NGFDialogClosePosition,
  isDialogClosePositionAllowed
} from './NGFInclusiveDesignTokens';
import { NGFAccessibilityAttributeModifier } from './NGFAccessibilityAttributeBinder';

const TAG: string = 'NGFAccessibleDialogClose';

/** 把规范允许的关闭键位置映射为 ArkUI 对齐方式 */
export function resolveDialogCloseAlignment(position: NGFDialogClosePosition): Alignment {
  if (position === NGFDialogClosePosition.TOP_LEFT) {
    return Alignment.TopStart;
  }
  if (position === NGFDialogClosePosition.TOP_RIGHT) {
    return Alignment.TopEnd;
  }
  return Alignment.Bottom;
}

@Component
export struct NGFAccessibleDialogCloseButton {
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
  componentId: string = 'ngf_accessible_dialog_close';
  /** 关闭键位置。附件2 §2.4 只允许左上 / 右上 / 中央底部 */
  closePosition: NGFDialogClosePosition = NGFDialogClosePosition.TOP_RIGHT;
  /** 无障碍朗读文案（走 i18n）。图标按钮必须提供，否则读屏只能读出"按钮" */
  label: ResourceStr = '';
  /** 点击区边长（vp），不得小于 44 */
  minTouchTarget: number = NGF_INCLUSIVE_DESIGN_METRICS.dialogCloseTargetDp;
  /** 关闭回调 */
  onClose: () => void = (): void => {};

  aboutToAppear(): void {
    if (!isDialogClosePositionAllowed(this.closePosition)) {
      logger.warn(TAG, '关闭键位置不符合附件2 §2.4，仅允许左上/右上/中央底部: ' + this.closePosition);
    }
    if (this.minTouchTarget < NGF_INCLUSIVE_DESIGN_METRICS.dialogCloseTargetDp) {
      logger.warn(TAG, '关闭键点击区小于附件2 §2.4 下限 '
        + String(NGF_INCLUSIVE_DESIGN_METRICS.dialogCloseTargetDp) + ': ' + String(this.minTouchTarget));
    }
  }

  private buildSemantics(): NGFAccessibilitySemantics {
    const semantics: NGFAccessibilitySemantics = {
      id: this.componentId,
      role: NGFAccessibilityRole.BUTTON,
      label: this.label,
      actions: [NGFAccessibilityAction.CLICK]
    };
    return semantics;
  }

  build() {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.xmark'))
        .fontSize(a11yFontFor(this.isElderly, 18, this.boostFont))
        .fontColor([$r('app.color.text_primary')])
    }
    .width(a11yTouchTarget(this.isElderly, this.minTouchTarget))
    .height(a11yTouchTarget(this.isElderly, this.minTouchTarget))
    .backgroundColor(Color.Transparent)
    .attributeModifier(new NGFAccessibilityAttributeModifier(this.buildSemantics()))
    .onClick(() => {
      this.onClose();
    })
  }
}
