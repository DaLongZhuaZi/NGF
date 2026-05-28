import { common, Want } from '@kit.AbilityKit';
import { IAppLinking } from '../contracts/IAppLinking';
import { uiContextManager } from '../../platformOhos/UIContextManager';
import { logger } from '../../utils/Logger';

const TAG: string = 'AppLinkingFacade';

export class AppLinkingFacade implements IAppLinking {

  /**
   * 创建一个从外部跳转进入当前 App 的通用链接（App Linking）。
   * 当前实现构造标准 HTTPS URL 并附带 deeplink 参数。
   * 如需使用华为 App Linking 短链服务，请集成 @kit.AppLinkingKit 并在
   * AppGallery Connect 后台配置域名后替换此实现。
   *
   * @param domain 应用关联的域名，例如 "https://example.com"
   * @param deepLink 应用内深度链接，例如 "myapp://page/detail?id=123"
   * @param linkPath 可选路径，默认为 "/applinking"
   */
  async createLink(domain: string, deepLink: string, linkPath: string = '/applinking'): Promise<string | null> {
    try {
      // 标准化域名：去除尾部斜杠
      let normalizedDomain = domain.trim();
      while (normalizedDomain.endsWith('/')) {
        normalizedDomain = normalizedDomain.substring(0, normalizedDomain.length - 1);
      }

      // 确保域名以 https:// 开头
      if (!normalizedDomain.startsWith('https://') && !normalizedDomain.startsWith('http://')) {
        normalizedDomain = `https://${normalizedDomain}`;
      }

      // 构造完整的 HTTPS URL，将 deepLink 作为编码后的查询参数
      const encodedDeepLink = encodeURIComponent(deepLink);
      const fullUrl = `${normalizedDomain}${linkPath}?link=${encodedDeepLink}`;
      logger.info(TAG, `生成 App Linking URL: ${fullUrl}`);
      return fullUrl;
    } catch (e) {
      logger.error(TAG, `生成 App Linking URL 失败: ${e}`);
      return null;
    }
  }

  /**
   * 打开系统共享面板，分享内容给其他应用或超级终端
   */
  shareText(text: string): void {
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

export const ngfAppLinkingFacade: IAppLinking = new AppLinkingFacade();
