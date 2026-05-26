export interface IWidgetManager {
  /**
   * 刷新指定的卡片 (Service Widget) 数据
   * @param formId 卡片唯一标识
   * @param data 要刷新的 JSON 序列化数据
   * @returns 成功返回 true
   */
  updateWidgetData(formId: string, data: Record<string, string | number | boolean>): Promise<boolean>;

  /**
   * 触发所有关联该数据提供者的卡片刷新
   * @param providerName 数据提供方名称 (如某个特定的 FormExtensionAbility)
   * @param data 要刷新的数据
   */
  updateWidgetsByProvider(providerName: string, data: Record<string, string | number | boolean>): Promise<boolean>;
}
