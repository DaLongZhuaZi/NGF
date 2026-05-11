/**
 * 服务元数据
 */
export class NGFServiceMetadataResult {
  readonly token: string;
  readonly implementationName: string;

  constructor(token: string, implementationName: string) {
    this.token = token;
    this.implementationName = implementationName;
  }
}

/**
 * NGF 服务注册信息
 * @class NGFServiceRegistration
 * @description 封装服务注册所需的信息
 */
export class NGFServiceRegistration {
  /** 服务令牌/标识符 */
  readonly token: string;
  /** 实现类名称 */
  readonly implementationName: string;
  /** 服务实例 */
  readonly service: object;

  /**
   * 创建服务注册信息
   * @param token 服务令牌/标识符
   * @param implementationName 实现类名称
   * @param service 服务实例
   */
  constructor(token: string, implementationName: string, service: object) {
    this.token = token;
    this.implementationName = implementationName;
    this.service = service;
  }

  /**
   * 获取服务元数据
   * @returns 服务的元数据信息
   */
  getMetadata(): NGFServiceMetadataResult {
    return new NGFServiceMetadataResult(this.token, this.implementationName);
  }
}
