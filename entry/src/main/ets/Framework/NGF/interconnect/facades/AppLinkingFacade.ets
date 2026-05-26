import { common, Want } from '@kit.AbilityKit';
import { uiContextManager } from '../../platformOhos/UIContextManager';
import { logger } from '../../utils/Logger';

const TAG: string = 'AppLinkingFacade';

export class AppLinkingFacade {
  
  /**
   * 创建一个从外部跳转进入当前 App 的通用链接（App Linking）
   * 需要在开发者后台配置 domain
   */
  static async createLink(domain: string, deepLink: string): Promise<string | null> {
    try {
      const mockShortLink = `${domain}?link=${encodeURIComponent(deepLink)}`;
      logger.info(TAG, `生成短链接成功: ${mockShortLink}`);
      return mockShortLink;
    } catch (e) {
      logger.error(TAG, `生成短链接失败: ${e}`);
      return null;
    }
  }

  /**
   * 打开系统共享面板，分享内容给其他应用或超级终端
   */
  static shareText(text: string): void {
    const context: common.UIAbilityContext | null = uiContextManager.getFullAbilityContext();
    if (!context) {
      logger.error(TAG, '缺少 UIAbilityContext，无法拉起分享面板');
      return;
    }

    try {
      const want: Want = {
        action: 'ohos.want.action.sendData',
        type: 'text/plain',
        parameters: {
          'ability.params.stream': text
        }
      };
      context!.startAbility(want).then(() => {
        logger.info(TAG, '成功拉起分享面板');
      }).catch((e: Error) => {
        logger.error(TAG, `拉起分享面板异常: ${e}`);
      });
    } catch (e) {
      logger.error(TAG, `拉起分享面板失败: ${e}`);
    }
  }
}
