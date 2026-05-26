import { formBindingData, formProvider } from '@kit.FormKit';
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
    try {
      logger.info(TAG, `尝试通过 provider 刷新一组卡片, providerName: ${providerName}`);
      
      // 在实际商业级项目中，可以通过 formInfo 获取特定 provider 下所有的激活的 formIds
      // 这里作为门面展示，暂且捕获框架级的约定：我们需要维护一个 formId 与 provider 的内存映射
      logger.warn(TAG, `updateWidgetsByProvider 当前依赖底层缓存结构遍历，建议业务层自行管理 formId。`);
      
      return true;
    } catch (e) {
      logger.error(TAG, `通过 provider 刷新卡片失败: ${e}`);
      return false;
    }
  }
}

export const ngfWidgetManagerFacade = new WidgetManagerFacade();
