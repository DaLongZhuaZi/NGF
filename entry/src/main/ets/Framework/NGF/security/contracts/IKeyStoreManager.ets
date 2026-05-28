export interface IKeyStoreManager {
  /**
   * 存储极度敏感数据 (如支付密码、长期 Token) 到芯片级安全环境
   * @param alias 数据别名
   * @param secretString 敏感数据明文
   * @returns 是否存储成功
   */
  addSecret(alias: string, secretString: string): Promise<boolean>;

  /**
   * 读取极度敏感数据
   * @param alias 数据别名
   * @returns 解密后的明文，不存在则返回 null
   */
  querySecret(alias: string): Promise<string | null>;

  /**
   * 删除敏感数据
   * @param alias 数据别名
   * @returns 是否删除成功
   */
  removeSecret(alias: string): Promise<boolean>;
}
