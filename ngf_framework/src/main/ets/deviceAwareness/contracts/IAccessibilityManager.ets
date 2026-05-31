import { NGFAccessibilityState } from '../facades/AccessibilityFacade';

/**
 * 无障碍管理器契约
 * 定义无障碍能力查询与辅助标签构建的标准接口。
 */
export interface IAccessibilityManager {
  /**
   * 查询无障碍功能是否启用
   * @returns 当前无障碍状态
   */
  isAccessibilityEnabled(): NGFAccessibilityState;

  /**
   * 查询屏幕朗读（TalkBack/读屏）是否启用
   * @returns 启用返回 true
   */
  isScreenReaderEnabled(): boolean;

  /**
   * 构建无障碍描述标签文本
   * @param componentId 组件逻辑 ID
   * @param label 朗读描述文字
   * @returns 处理后的标签文本
   */
  buildAccessibilityLabel(componentId: string, label: string): string;

  /**
   * 生成推荐的无障碍提示文本（hint）
   * @param action 操作描述
   * @returns 提示文本
   */
  buildAccessibilityHint(action: string): string;
}
