import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { ISystemShare } from '../contracts/ISystemShare';
import { uiContextManager } from '../../platformOhos/UIContextManager';
import { logger } from '../../utils/Logger';

const TAG: string = 'SystemShareFacade';

export class SystemShareFacade implements ISystemShare {

  shareText(text: string): void {
    const context = uiContextManager.getFullAbilityContext();
    if (!context) {
      logger.error(TAG, '缺少 UIAbilityContext，无法拉起分享面板');
      return;
    }

    try {
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.PLAIN_TEXT,
        content: text
      });

      let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
      
      let contextUI = uiContextManager.getUIContext();
      if (!context) {
        logger.error(TAG, '缺少 UIAbilityContext');
        return;
      }
      
      controller.show(context as common.UIAbilityContext, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DETAIL
      }).then(() => {
        logger.info(TAG, '成功拉起原生系统 ShareKit 分享面板');
      }).catch((e: Error) => {
        logger.error(TAG, '拉起分享面板异常: ' + e);
      });
    } catch (e) {
      logger.error(TAG, '拉起分享面板失败: ' + e);
    }
  }
}

export const ngfSystemShareFacade: ISystemShare = new SystemShareFacade();
