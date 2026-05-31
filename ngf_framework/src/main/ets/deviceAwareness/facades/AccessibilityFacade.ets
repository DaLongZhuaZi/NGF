import { logger } from '../../utils/Logger';
import { accessibility } from '@kit.AccessibilityKit';
import { IAccessibilityManager } from '../contracts/IAccessibilityManager';

const TAG: string = 'NGFAccessibilityFacade';

/**
 * 无障碍能力状态
 */
export enum NGFAccessibilityState {
  ENABLED = 'enabled',
  DISABLED = 'disabled',
  UNKNOWN = 'unknown'
}

/**
 * 无障碍门面 — 提供无障碍状态查询和语义标签工具
 * Phase F1：接口预埋，部分方法依赖设备能力。
 */
class AccessibilityFacade implements IAccessibilityManager {
  private static instance: AccessibilityFacade | null = null;

  private constructor() {}

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
    try {
      const isEnabled: boolean = accessibility.isOpenAccessibilitySync();
      logger.info(TAG, `无障碍状态: ${isEnabled}`);
      return isEnabled ? NGFAccessibilityState.ENABLED : NGFAccessibilityState.DISABLED;
    } catch (e) {
      logger.warn(TAG, `无障碍状态查询失败: ${e}`);
      return NGFAccessibilityState.UNKNOWN;
    }
  }

  /**
   * 查询屏幕朗读（TalkBack/读屏）是否启用
   */
  isScreenReaderEnabled(): boolean {
    try {
      return accessibility.isOpenTouchGuideSync();
    } catch (e) {
      logger.warn(TAG, `屏幕朗读状态查询失败: ${e}`);
      return false;
    }
  }

  /**
   * 为组件设置无障碍描述标签（供 .accessibilityText() 使用的推荐辅助工具）
   * @param componentId 组件逻辑 ID（建议与 .id() 保持一致）
   * @param label 朗读描述文字
   */
  buildAccessibilityLabel(componentId: string, label: string): string {
    logger.debug(TAG, `无障碍标签绑定: id=${componentId}, label=${label}`);
    return label;
  }

  /**
   * 生成推荐的无障碍提示文本（hint）
   */
  buildAccessibilityHint(action: string): string {
    return `双击执行: ${action}`;
  }
}

export const ngfAccessibilityFacade: AccessibilityFacade = AccessibilityFacade.getInstance();
