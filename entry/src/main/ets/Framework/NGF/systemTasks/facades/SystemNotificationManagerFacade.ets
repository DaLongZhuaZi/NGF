import { notificationManager } from '@kit.NotificationKit';
import { uiContextManager } from '../../platformOhos/UIContextManager';
import { ISystemNotificationManager, NGFNotificationRequest } from '../contracts/ISystemNotificationManager';
import { logger } from '../../utils/Logger';

const TAG: string = 'SystemNotificationManagerFacade';

class SystemNotificationManagerFacade implements ISystemNotificationManager {
  async requestPermission(): Promise<boolean> {
    const context = uiContextManager.getFullAbilityContext();
    if (!context) {
      logger.warn(TAG, '无 UIAbilityContext，无法申请通知权限');
      return false;
    }
    try {
      await notificationManager.requestEnableNotification(context);
      logger.info(TAG, '通知权限申请完成');
      return true;
    } catch (e) {
      logger.error(TAG, `申请通知权限失败: ${e}`);
      return false;
    }
  }

  async publish(request: NGFNotificationRequest): Promise<void> {
    try {
      let displayText = request.content;
      if (request.progressMax > 0) {
        const percentage = Math.floor((request.progressValue / request.progressMax) * 100);
        displayText += ` [${percentage}%]`;
      }

      const req: notificationManager.NotificationRequest = {
        id: request.id,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: request.title,
            text: displayText
          }
        },
        isOngoing: request.isOngoing
      };
      await notificationManager.publish(req);
      logger.debug(TAG, `发送通知成功: ID=${request.id}`);
    } catch (e) {
      logger.error(TAG, `发送通知失败: ${e}`);
    }
  }

  async cancel(id: number): Promise<void> {
    try {
      await notificationManager.cancel(id);
      logger.debug(TAG, `取消通知成功: ID=${id}`);
    } catch (e) {
      logger.error(TAG, `取消通知失败: ${e}`);
    }
  }
}

export const ngfSystemNotificationManager: ISystemNotificationManager = new SystemNotificationManagerFacade();
