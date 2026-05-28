import { formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { logger } from '../../utils/Logger';
import { IWidgetManager } from '../contracts/IWidgetManager';

const TAG: string = 'WidgetManagerFacade';

export class WidgetManagerFacade implements IWidgetManager {
  async updateWidgetData(formId: string, data: Record<string, string | number | boolean>): Promise<boolean> {
    try {
      logger.info(TAG, `正在更新卡片数据, formId: ${formId}`);
      const obj = formBindingData.createFormBindingData(data);

      // 调用鸿蒙底层 FormKit 刷新卡片
      await formProvider.updateForm(formId, obj);
      logger.info(TAG, `卡片更新成功, formId: ${formId}`);
      return true;
    } catch (e) {
      logger.error(TAG, `卡片更新失败, formId: ${formId}, error: ${e}`);
      return false;
    }
  }

  async updateWidgetsByProvider(providerName: string, data: Record<string, string | number | boolean>): Promise<boolean> {
    logger.warn(TAG, `updateWidgetsByProvider is not fully supported in this API version. Target providerName: ${providerName}`);
    return false;
  }
}

export const ngfWidgetManagerFacade = new WidgetManagerFacade();
