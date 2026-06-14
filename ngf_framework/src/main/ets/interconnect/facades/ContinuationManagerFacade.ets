import { IContinuationManager } from '../contracts/IContinuationManager';
import { logger } from '../../utils/Logger';

const TAG: string = 'ContinuationManagerFacade';
const CONTINUATION_DATA_KEY = 'ngf_continuation_data';

export class ContinuationManagerFacade implements IContinuationManager {
  private producers: Map<string, () => Record<string, Object>> = new Map();
  private receivedData: Map<string, Record<string, Object>> = new Map();

  registerContinuationDataProducer(pageId: string, callback: () => Record<string, Object>): void {
    this.producers.set(pageId, callback);
    logger.info(TAG, '注册流转数据生产者: ' + pageId);
  }

  unregisterContinuationDataProducer(pageId: string): void {
    this.producers.delete(pageId);
    logger.info(TAG, '注销流转数据生产者: ' + pageId);
  }

  consumeContinuationData(pageId: string): Record<string, Object> | null {
    if (this.receivedData.has(pageId)) {
      const data = this.receivedData.get(pageId) as Record<string, Object>;
      this.receivedData.delete(pageId);
      logger.info(TAG, '消费流转数据: ' + pageId);
      return data;
    }
    return null;
  }

  collectAllContinuationData(wantParam: Record<string, Object>): void {
    const allData: Record<string, Record<string, Object>> = {};
    const entries = Array.from(this.producers.entries());
    for (let i = 0; i < entries.length; i++) {
      const pageId = entries[i][0];
      const producer = entries[i][1];
      try {
        allData[pageId] = producer();
      } catch (e) {
        logger.error(TAG, '收集流转数据异常 [' + pageId + ']: ' + e);
      }
    }
    
    // 将所有页面的数据序列化后存入 wantParam
    wantParam[CONTINUATION_DATA_KEY] = JSON.stringify(allData);
    logger.info(TAG, '成功收集流转数据，包含 ' + String(Object.keys(allData).length) + ' 个页面状态');
  }

  receiveContinuationData(wantParam: Record<string, Object>): void {
    if (wantParam && typeof wantParam[CONTINUATION_DATA_KEY] === 'string') {
      try {
        const jsonStr = wantParam[CONTINUATION_DATA_KEY] as string;
        const allData = JSON.parse(jsonStr) as Record<string, Record<string, Object>>;
        
        const allDataKeys = Object.keys(allData);
        for (let i: number = 0; i < allDataKeys.length; i++) {
          this.receivedData.set(allDataKeys[i], allData[allDataKeys[i]]);
        }
        logger.info(TAG, '成功解析流转恢复数据，包含 ' + String(Object.keys(allData).length) + ' 个页面状态');
      } catch (e) {
        logger.error(TAG, '解析流转恢复数据失败: ' + e);
      }
    } else {
      logger.info(TAG, '本次启动不包含流转恢复数据');
    }
  }
}

export const ngfContinuationManagerFacade: IContinuationManager = new ContinuationManagerFacade();
