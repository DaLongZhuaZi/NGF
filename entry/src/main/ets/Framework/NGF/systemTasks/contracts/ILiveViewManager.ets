export interface ILiveViewManager {
  /**
   * 启动实况窗
   * @param id 实况窗任务唯一标识
   * @param title 实况窗主标题
   * @param content 实况窗初始内容
   * @returns 成功返回 true
   */
  startLiveView(id: string, title: string, content: string): Promise<boolean>;

  /**
   * 更新实况窗进度与内容
   * @param id 实况窗任务唯一标识
   * @param progress 当前进度百分比 (0-100)
   * @param content 进度说明文本
   * @returns 成功返回 true
   */
  updateLiveView(id: string, progress: number, content: string): Promise<boolean>;

  /**
   * 结束实况窗
   * @param id 实况窗任务唯一标识
   * @returns 成功返回 true
   */
  stopLiveView(id: string): Promise<boolean>;
}
