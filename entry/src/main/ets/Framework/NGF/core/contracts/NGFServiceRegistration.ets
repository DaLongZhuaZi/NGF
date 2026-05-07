import { INGFService } from './INGFService';

/**
 * NGF 服务注册信息
 * @class NGFServiceRegistration
 * @description 封装服务注册所需的信息
 * @note API 23 适配：使用 INGFService 替代 object 类型，消除 as object 断言
 */
export class NGFServiceRegistration {
  /** 服务令牌/标识符 */
  readonly token: string;
  /** 实现类名称 */
  readonly implementationName: string;
  /** 服务实例 */
  readonly service: INGFService;

  /**
   * 创建服务注册信息
   * @param token 服务令牌/标识符
   * @param implementationName 实现类名称
   * @param service 服务实例，必须实现 INGFService 接口
   */
  constructor(token: string, implementationName: string, service: INGFService) {
    this.token = token;
    this.implementationName = implementationName;
    this.service = service;
  }

  /**
   * 获取服务元数据
   * @returns 服务的元数据信息
   */
  getMetadata(): { token: string; implementationName: string; serviceId: string } {
    return {
      token: this.token,
      implementationName: this.implementationName,
      serviceId: this.service.serviceId
    };
  }
}
