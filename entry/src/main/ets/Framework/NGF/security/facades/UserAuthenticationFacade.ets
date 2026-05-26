import { userAuth } from '@kit.UserAuthenticationKit';
import { logger } from '../../utils/Logger';

const TAG: string = 'UserAuthenticationFacade';

export class UserAuthenticationFacade {
  /**
   * 拉起系统指纹或人脸认证弹窗
   * @param challenge 认证挑战值，用于防重放攻击
   * @param title 自定义弹窗标题
   * @ohos.permission ohos.permission.ACCESS_BIOMETRIC
   */
  static async authenticate(challenge: Uint8Array, title: string = '安全验证'): Promise<boolean> {
    logger.info(TAG, '发起用户身份验证');

    const authParam: userAuth.AuthParam = {
      challenge: challenge,
      authType: [userAuth.UserAuthType.PIN, userAuth.UserAuthType.FINGERPRINT, userAuth.UserAuthType.FACE],
      authTrustLevel: userAuth.AuthTrustLevel.ATL3
    };

    const widgetParam: userAuth.WidgetParam = {
      title: title
    };

    try {
      const userAuthInstance = userAuth.getUserAuthInstance(authParam, widgetParam);
      
      return new Promise((resolve) => {
        userAuthInstance.on('result', {
          onResult(result) {
            logger.info(TAG, `身份验证结果: ${result.result}`);
            if (result.result === userAuth.UserAuthResultCode.SUCCESS) {
              resolve(true);
            } else {
              resolve(false);
            }
            try {
              userAuthInstance.off('result');
            } catch (e) {
              logger.error(TAG, `off() failed: ${e}`);
            }
          }
        });
        try {
          userAuthInstance.start();
        } catch (e) {
          logger.error(TAG, `start() thrown error: ${e}`);
          resolve(false);
        }
      });
    } catch (e) {
      logger.error(TAG, `调起身份验证失败: ${e}`);
      return false;
    }
  }

  /**
   * 检查设备是否支持指定的生物识别
   * @ohos.permission ohos.permission.ACCESS_BIOMETRIC
   */
  static checkSupport(authType: userAuth.UserAuthType): boolean {
    try {
      userAuth.getAvailableStatus(authType, userAuth.AuthTrustLevel.ATL1);
      return true;
    } catch (e) {
      logger.warn(TAG, `设备不支持认证类型 ${authType}`);
      return false;
    }
  }
}
