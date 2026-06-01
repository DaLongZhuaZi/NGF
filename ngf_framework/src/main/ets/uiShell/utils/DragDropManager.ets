import unifiedDataChannel from '@ohos.data.unifiedDataChannel';
import uniformTypeDescriptor from '@ohos.data.uniformTypeDescriptor';
import { logger } from '../../utils/Logger';

const TAG: string = 'DragDropManagerFacade';

export class DragDropManagerFacade {
  
  /**
   * 构造全局纯文本拖拽数据，可用于 `onDragStart` 事件返回
   * @param text 拖拽的文本内容
   */
  createPlainTextDragData(text: string): unifiedDataChannel.UnifiedData | null {
    try {
      let plainText = new unifiedDataChannel.PlainText();
      plainText.textContent = text;
      
      let unifiedData = new unifiedDataChannel.UnifiedData(plainText);
      logger.info(TAG, `生成文本拖拽数据，内容长度: ${text.length}`);
      return unifiedData;
    } catch (e) {
      logger.error(TAG, `生成文本拖拽数据失败: ${e}`);
      return null;
    }
  }

  /**
   * 构造全局超链接拖拽数据
   * @param url 拖拽的 URL
   * @param title 可选标题
   */
  createHyperlinkDragData(url: string, title?: string): unifiedDataChannel.UnifiedData | null {
    try {
      let hyperlink = new unifiedDataChannel.Hyperlink();
      hyperlink.url = url;
      if (title) {
        hyperlink.description = title;
      }
      
      let unifiedData = new unifiedDataChannel.UnifiedData(hyperlink);
      logger.info(TAG, `生成链接拖拽数据: ${url}`);
      return unifiedData;
    } catch (e) {
      logger.error(TAG, `生成链接拖拽数据失败: ${e}`);
      return null;
    }
  }

  /**
   * 解析拖放事件中收到的文本内容 (通常在 onDrop 中使用)
   */
  extractPlainText(unifiedData: unifiedDataChannel.UnifiedData): string | null {
    try {
      const records = unifiedData.getRecords();
      for (let i = 0; i < records.length; i++) {
        const record = records[i];
        if (record.getType() === uniformTypeDescriptor.UniformDataType.PLAIN_TEXT) {
          const plainText = record as unifiedDataChannel.PlainText;
          return plainText.textContent || null;
        }
      }
      return null;
    } catch (e) {
      logger.error(TAG, `解析拖放文本失败: ${e}`);
      return null;
    }
  }
}

export const ngfDragDropManagerFacade = new DragDropManagerFacade();
