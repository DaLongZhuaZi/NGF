import { common } from '@kit.AbilityKit';
import { UIContext } from '@kit.ArkUI';
import { logger } from '../utils/Logger';

const TAG: string = 'NGFUIContextManager';

/**
 * UIContext 管理器
 * @note API 23 适配：使用具体的 UIContext 类型替代 Object，启用完整类型支持
 */
class UIContextManager {
  private static instance: UIContextManager | null = null;
  private uiContext: UIContext | null = null;
  private abilityContext: common.UIAbilityContext | null = null;

  private constructor() {
    // 私有构造函数，确保单例模式
  }

  static getInstance(): UIContextManager {
    if (!UIContextManager.instance) {
      UIContextManager.instance = new UIContextManager();
    }
    return UIContextManager.instance;
  }

  /**
   * 绑定 UIContext
   * @param context UIContext 实例
   * @note API 23 适配：参数类型从 Object 改为 UIContext
   */
  bindUIContext(context: UIContext): void {
    this.uiContext = context;
    logger.info(TAG, '绑定 UIContext');
  }

  clearUIContext(): void {
    this.uiContext = null;
    logger.info(TAG, '清除 UIContext');
  }

  /**
   * 获取 UIContext
   * @returns UIContext 实例或 null
   * @note API 23 适配：返回类型从 Object 改为 UIContext，可直接使用 UIContext 新方法
   */
  getUIContext(): UIContext | null {
    return this.uiContext;
  }

  bindAbilityContext(context: common.UIAbilityContext): void {
    this.abilityContext = context;
    logger.info(TAG, `绑定 Ability 上下文: filesDir=${context.filesDir}`);
  }

  clearAbilityContext(): void {
    this.abilityContext = null;
    logger.info(TAG, '清除 Ability 上下文');
  }

  getAbilityContext(): common.UIAbilityContext | null {
    return this.abilityContext;
  }

  getFullAbilityContext(): common.UIAbilityContext | null {
    return this.abilityContext;
  }
}

export const uiContextManager: UIContextManager = UIContextManager.getInstance();
