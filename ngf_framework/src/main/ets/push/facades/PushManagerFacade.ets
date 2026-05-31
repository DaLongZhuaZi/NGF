import { pushService } from '@kit.PushKit';
import { IPushManager } from '../contracts/IPushManager';
import { logger } from '../../utils/Logger';

const TAG: string = 'PushManagerFacade';

export class PushManagerFacade implements IPushManager {
  private messageCallback: ((message: Object) => void) | null = null;

  /**
   * 获取设备的 Push Token
   * 必须在模块级别配置好 client_id 且绑定了正确的签名证书
   */
  async getToken(): Promise<string | null> {
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
   * 订阅推送消息的数据回调。
   * 注意：HarmonyOS PushKit 的消息到达机制基于 Want 分发，
   * 实际推送消息会通过 UIAbility 的 onNewWant 生命周期回调传递。
   * 注册此回调后，请在 UIAbility 的 onNewWant 中调用
   * PushManagerFacade.dispatchMessage(want) 将消息转发至此回调。
   */
  onMessageReceived(callback: (message: Object) => void): void {
    this.messageCallback = callback;
    logger.info(TAG, '推送消息回调已注册');
  }

  /**
   * 分发推送消息到已注册的回调。
   * 应在 UIAbility 的 onNewWant 中调用此方法。
   */
  dispatchMessage(message: Object): void {
    if (this.messageCallback !== null) {
      try {
        this.messageCallback(message);
      } catch (e) {
        logger.error(TAG, `推送消息回调执行异常: ${e}`);
      }
    } else {
      logger.warn(TAG, '推送消息到达但未注册回调，消息已丢弃');
    }
  }
}

export const ngfPushManagerFacade: IPushManager = new PushManagerFacade();
