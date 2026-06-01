export interface IContinuationManager {
  /**
   * 注册页面流转数据回调。当跨设备接续发生时，此回调将被触发用于保存页面状态。
   * @param pageId 页面唯一标识，通常为组件的类名
   * @param callback 回调函数，返回需要保存的状态对象
   */
  registerContinuationDataProducer(pageId: string, callback: () => Record<string, Object>): void;

  /**
   * 取消注册页面流转数据回调。
   * @param pageId 页面唯一标识
   */
  unregisterContinuationDataProducer(pageId: string): void;

  /**
   * 消费（读取并移除）指定页面的流转恢复数据。
   * @param pageId 页面唯一标识
   * @returns 恢复的数据对象，若无则返回 null
   */
  consumeContinuationData(pageId: string): Record<string, Object> | null;

  /**
   * 由 EntryAbility 的 onContinue 生命周期调用，收集所有已注册页面的流转数据
   * @param wantParam 传入的 wantParam 引用，将数据写入此对象
   */
  collectAllContinuationData(wantParam: Record<string, Object>): void;

  /**
   * 由 EntryAbility 的 onCreate 或 onNewWant 调用，接收从另一台设备传来的流转数据
   * @param wantParam 传入的 wantParam 引用
   */
  receiveContinuationData(wantParam: Record<string, Object>): void;
}
