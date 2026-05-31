import { logger } from '../../utils/Logger';
import { IHttpInterceptor } from '../contracts/IHttpInterceptor';
import { NGFHttpRequestOptions, NGFHttpResponse } from '../contracts/IHttpClient';

const TAG: string = 'NGFAuthInterceptor';

/**
 * 鉴权拦截器
 * 在 HTTP 请求发出前自动注入鉴权 Token 到请求头
 */
export class AuthInterceptorFacade implements IHttpInterceptor {
  private tokenProvider: () => string = (): string => '';
  private headerName: string = 'Authorization';
  private prefix: string = 'Bearer ';

  /**
   * 设置 Token 提供者函数
   * 该函数在每次请求时被调用以获取最新的 Token
   * @param provider 返回 Token 字符串的函数
   */
  setTokenProvider(provider: () => string): void {
    this.tokenProvider = provider;
    logger.info(TAG, 'Token 提供者已设置');
  }

  /**
   * 设置鉴权头名称
   * @param name 请求头名称，默认 'Authorization'
   */
  setHeaderName(name: string): void {
    this.headerName = name;
    logger.info(TAG, `鉴权头名称已设置为: ${name}`);
  }

  /**
   * 设置 Token 前缀
   * @param prefix Token 前缀，默认 'Bearer '
   */
  setPrefix(prefix: string): void {
    this.prefix = prefix;
    logger.info(TAG, `Token 前缀已设置为: ${prefix}`);
  }

  /**
   * 请求拦截：注入鉴权头
   * @param options 原始请求配置
   * @returns 注入鉴权头后的请求配置
   */
  async onRequest(options: NGFHttpRequestOptions): Promise<NGFHttpRequestOptions> {
    const token: string = this.tokenProvider();
    if (token.length <= 0) {
      logger.debug(TAG, 'Token 为空，跳过注入');
      return options;
    }

    const authHeaderValue: string = `${this.prefix}${token}`;
    let updatedHeader: string;
    if (options.header.length > 0) {
      updatedHeader = `${options.header}\r\n${this.headerName}: ${authHeaderValue}`;
    } else {
      updatedHeader = `${this.headerName}: ${authHeaderValue}`;
    }

    logger.debug(TAG, `已注入鉴权头: ${this.headerName}`);
    return new NGFHttpRequestOptions(
      options.method,
      options.url,
      updatedHeader,
      options.extraData,
      options.connectTimeout,
      options.readTimeout
    );
  }

  /**
   * 响应拦截（透传，不做处理）
   * @param response 原始响应
   * @returns 原始响应
   */
  async onResponse(response: NGFHttpResponse): Promise<NGFHttpResponse> {
    return response;
  }
}

export const ngfAuthInterceptor: AuthInterceptorFacade = new AuthInterceptorFacade();
