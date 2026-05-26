import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { logger } from '../../utils/Logger';
import { uiContextManager } from '../../platformOhos/UIContextManager';

const TAG: string = 'MediaPickerFacade';

export class MediaPickerFacade {
  /**
   * 调起系统安全的图片选择器 (PhotoPicker)
   * 鸿蒙特性：不需要应用显式申请相册读权限，系统 Picker 选取后会直接返回临时授权的 URI
   */
  static async pickImages(maxSelectNumber: number = 1): Promise<Array<string>> {
    const context = uiContextManager.getFullAbilityContext();
    if (!context) {
      logger.error(TAG, '缺少 UIAbilityContext，无法拉起图片选择器');
      return [];
    }

    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      // 限定仅选择图片
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = maxSelectNumber;

      const photoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const photoSelectResult = await photoViewPicker.select(photoSelectOptions);
      
      const uris = photoSelectResult.photoUris;
      logger.info(TAG, `成功拾取 ${uris.length} 张图片`);
      return uris;
    } catch (e) {
      logger.error(TAG, `图片拾取失败: ${e}`);
      return [];
    }
  }

  /**
   * 调起系统安全的视频选择器
   */
  static async pickVideos(maxSelectNumber: number = 1): Promise<Array<string>> {
    const context = uiContextManager.getFullAbilityContext();
    if (!context) {
      logger.error(TAG, '缺少 UIAbilityContext');
      return [];
    }

    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE;
      photoSelectOptions.maxSelectNumber = maxSelectNumber;

      const photoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const photoSelectResult = await photoViewPicker.select(photoSelectOptions);
      
      return photoSelectResult.photoUris;
    } catch (e) {
      logger.error(TAG, `视频拾取失败: ${e}`);
      return [];
    }
  }
}
