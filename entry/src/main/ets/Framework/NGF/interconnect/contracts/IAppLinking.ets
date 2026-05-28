export interface IAppLinking {
  /**
   * 创建一个从外部跳转进入当前 App 的通用链接（App Linking）
   * @param domain 应用关联的域名
   * @param deepLink 应用内深度链接
   * @param linkPath 可选路径
   * @returns 生成的 URL，失败返回 null
   */
  createLink(domain: string, deepLink: string, linkPath: string): Promise<string | null>;

  /**
   * 打开系统共享面板，分享内容给其他应用或超级终端
   * @param text 要分享的文本内容
   */
  shareText(text: string): void;
}
