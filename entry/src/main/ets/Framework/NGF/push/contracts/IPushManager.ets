export interface IPushManager {
  /**
   * 获取设备的 Push Token
   * @returns Push Token 字符串，失败返回 null
   */
  getToken(): Promise<string | null>;

  /**
   * 订阅推送消息的数据回调
   * @param callback 消息到达时的回调函数
   */
  onMessageReceived(callback: (message: Object) => void): void;

  /**
   * 分发推送消息到已注册的回调
   * @param message 推送消息对象
   */
  dispatchMessage(message: Object): void;
}
