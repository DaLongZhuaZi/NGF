export interface IWebBridge {
  /**
   * 注册供 H5 调用的原生方法
   */
  registerMethod(methodName: string, callback: (params: string) => Promise<string>): void;

  /**
   * 移除已注册的原生方法
   */
  unregisterMethod(methodName: string): void;

  /**
   * 获取所有注册的方法代理对象（用于注入到 webview）
   */
  getProxyObject(): Object;
}
