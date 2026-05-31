import { NGFHttpRequestOptions, NGFHttpResponse } from './IHttpClient';

/**
 * HTTP 请求与响应拦截器接口
 */
export interface IHttpInterceptor {
  /**
   * 在请求发出前进行拦截和处理（如：注入 Token，修改 Header）
   * @param options 原始请求配置
   * @returns 处理后的请求配置，返回 Promise 允许异步操作（如无感刷新 Token 的前置校验）
   */
  onRequest(options: NGFHttpRequestOptions): Promise<NGFHttpRequestOptions>;

  /**
   * 在响应返回前进行拦截和处理（如：统一日志打印，401 鉴权拦截）
   * @param response 原始响应
   * @returns 处理后的响应
   */
  onResponse(response: NGFHttpResponse): Promise<NGFHttpResponse>;
}
