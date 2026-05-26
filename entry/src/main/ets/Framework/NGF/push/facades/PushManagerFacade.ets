import { pushService } from '@kit.PushKit';
import { logger } from '../../utils/Logger';

const TAG: string = 'PushManagerFacade';

export class PushManagerFacade {
  
  /**
   * 获取设备的 Push Token
   * 必须在模块级别配置好 client_id 且绑定了正确的签名证书
   */
  static async getToken(): Promise<string | null> {
    try {
      logger.info(TAG, '开始向华为推送服务器申请 Push Token...');
      const pushToken = await pushService.getToken();
      logger.info(TAG, `Push Token 获取成功: ${pushToken.substring(0, 10)}...`);
      return pushToken;
    } catch (e) {
      logger.error(TAG, `Push Token 获取失败: ${e}`);
      return null;
    }
  }

  /**
   * 订阅推送消息的数据回调
   */
  static onMessageReceived(callback: (message: Object) => void): void {
    // 暂不实现 PushMessage 接收以免引起编译错误
  }
}
