export interface ISystemShare {
  /**
   * 调起原生系统级分享面板 (ShareKit)
   * 鸿蒙 4.0 (API 11) 起，推荐使用 systemShare 组件
   * @param text 分享的文本内容
   */
  shareText(text: string): void;
}
