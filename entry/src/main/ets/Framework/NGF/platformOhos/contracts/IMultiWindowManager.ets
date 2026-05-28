export enum NGFWindowMode {
  FULLSCREEN = 'fullscreen',
  SPLIT_SCREEN = 'split_screen',
  FLOATING = 'floating',
  UNKNOWN = 'unknown'
}

export interface IMultiWindowManager {
  /**
   * 获取当前窗口模式
   */
  getCurrentWindowMode(): NGFWindowMode;

  /**
   * 监听窗口尺寸或模式改变
   * @param callback 触发回调
   */
  onWindowModeChanged(callback: (mode: NGFWindowMode) => void): void;

  /**
   * 取消监听窗口模式改变
   * @param callback 触发回调
   */
  offWindowModeChanged(callback: (mode: NGFWindowMode) => void): void;

  /**
   * 设置当前窗口模式
   * @param mode 期望的窗口模式
   */
  setWindowMode(mode: NGFWindowMode): Promise<void>;
}
