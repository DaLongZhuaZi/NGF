export interface NGFRdbConfig {
  name: string;
  securityLevel?: number; // e.g., relationalStore.SecurityLevel.S1
}

export interface IRelationalStore {
  /**
   * 初始化数据库，创建对应的表
   */
  init(config: NGFRdbConfig, createTableSqls: string[]): Promise<boolean>;

  /**
   * 执行原生 SQL (如 INSERT, UPDATE)
   */
  executeSql(sql: string, bindArgs?: Array<string | number | boolean>): Promise<void>;

  /**
   * 查询 SQL
   * @returns 每一行作为一个 Record 对象返回
   */
  querySql(sql: string, bindArgs?: Array<string | number | boolean>): Promise<Array<Record<string, string | number | boolean>>>;

  /**
   * 开启事务
   */
  beginTransaction(): Promise<void>;

  /**
   * 提交事务
   */
  commit(): Promise<void>;

  /**
   * 回滚事务
   */
  rollback(): Promise<void>;
}
