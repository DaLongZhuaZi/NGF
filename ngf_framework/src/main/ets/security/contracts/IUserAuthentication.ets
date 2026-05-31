import { userAuth } from '@kit.UserAuthenticationKit';

export interface IUserAuthentication {
  /**
   * 拉起系统指纹或人脸认证弹窗
   * @param challenge 认证挑战值，用于防重放攻击
   * @param title 自定义弹窗标题
   * @returns 认证是否通过
   */
  authenticate(challenge: Uint8Array, title: string): Promise<boolean>;

  /**
   * 检查设备是否支持指定的生物识别
   * @param authType 认证类型
   * @returns 是否支持
   */
  checkSupport(authType: userAuth.UserAuthType): boolean;
}
