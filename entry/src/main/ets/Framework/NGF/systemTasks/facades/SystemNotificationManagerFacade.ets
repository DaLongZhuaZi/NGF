import { notificationManager } from '@kit.NotificationKit';
import { uiContextManager } from '../../platformOhos/UIContextManager';
import { ISystemNotificationManager, NGFNotificationRequest, NGFNotificationType } from '../contracts/ISystemNotificationManager';
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
      let notificationContent: notificationManager.NotificationContent;

      switch (request.type) {
        case NGFNotificationType.LONG_TEXT:
          notificationContent = {
            notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_LONG_TEXT,
            longText: {
              title: request.title,
              text: request.content,
              longText: request.longText || request.content,
              briefText: request.content,
              expandedTitle: request.title
            }
          };
          break;
        case NGFNotificationType.MULTILINE:
          notificationContent = {
            notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_MULTILINE,
            multiLine: {
              title: request.title,
              text: request.content,
              briefText: request.content,
              longTitle: request.title,
              lines: request.lines || [request.content]
            }
          };
          break;
        // PICTURE can be handled similarly if needed, defaulting to basic for now if no picture is provided
        case NGFNotificationType.BASIC:
        case NGFNotificationType.PROGRESS:
        case NGFNotificationType.CUSTOM:
        default:
          let displayText = request.content;
          if (request.type === NGFNotificationType.BASIC && request.progressMax > 0) {
            const percentage = Math.floor((request.progressValue / request.progressMax) * 100);
            displayText += ` [${percentage}%]`;
          }
          notificationContent = {
            notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
            normal: {
              title: request.title,
              text: displayText
            }
          };
          break;
      }

      const req: notificationManager.NotificationRequest = {
        id: request.id,
        content: notificationContent,
        isOngoing: request.isOngoing
      };

      if (request.type === NGFNotificationType.PROGRESS) {
        let defaultData: Record<string, Object> = {
          'title': request.title as Object,
          'fileName': request.content as Object,
          'progressValue': request.progressValue as Object,
          'progressMaxValue': request.progressMax as Object,
          'isProgressIndeterminate': (request.progressMax <= 0) as Object
        };

        req.template = {
          name: request.templateName || 'downloadTemplate',
          data: request.templateData || defaultData
        };
      } else if (request.type === NGFNotificationType.CUSTOM && request.templateName) {
        let emptyData: Record<string, Object> = {};
        req.template = {
          name: request.templateName,
          data: request.templateData || emptyData
        };
      }

      await notificationManager.publish(req);
      logger.debug(TAG, `发送通知成功: ID=${request.id}, 类型=${request.type}`);
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
