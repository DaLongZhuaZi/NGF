import { logger } from '../../utils/Logger';
import { IHttpInterceptor } from '../contracts/IHttpInterceptor';
import { NGFHttpRequestOptions, NGFHttpResponse } from '../contracts/IHttpClient';

const TAG: string = 'NGFLoggingInterceptor';

/**
 * 日志拦截器
 * 在 HTTP 请求和响应过程中记录详细日志，便于调试和监控
 */
export class LoggingInterceptorFacade implements IHttpInterceptor {
  private enabled: boolean = true;

  /**
   * 设置是否启用日志拦截器
   * @param enabled 是否启用
   */
  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
    logger.info(TAG, `日志拦截器已${enabled ? '启用' : '禁用'}`);
  }

  /**
   * 请求拦截：记录请求方法和 URL
   * @param options 原始请求配置
   * @returns 原始请求配置（不做修改）
   */
  async onRequest(options: NGFHttpRequestOptions): Promise<NGFHttpRequestOptions> {
    if (!this.enabled) {
      return options;
    }
    logger.info(TAG, `[请求] method=${options.method}, url=${options.url}`);
    if (options.extraData.length > 0) {
      logger.debug(TAG, `[请求体] length=${options.extraData.length}`);
    }
    return options;
  }

  /**
   * 响应拦截：记录响应状态码和数据大小
   * @param response 原始响应
   * @returns 原始响应（不做修改）
   */
  async onResponse(response: NGFHttpResponse): Promise<NGFHttpResponse> {
    if (!this.enabled) {
      return response;
    }
    const dataSize: number = response.result.length;
    logger.info(TAG, `[响应] status=${response.statusCode}, size=${dataSize} bytes`);
    if (!response.isOk()) {
      logger.warn(TAG, `[响应异常] 非 2xx 状态码: ${response.statusCode}`);
    }
    return response;
  }

  /**
   * 错误记录辅助方法
   * 供外部调用以记录请求过程中捕获的错误
   * @param url 请求 URL
   * @param error 错误对象
   */
  logError(url: string, error: Object | string | number | boolean): void {
    if (!this.enabled) {
      return;
    }
    let message: string;
    if (typeof error === 'string') {
      message = error;
    } else if (error instanceof Error) {
      message = error.message;
    } else {
      message = String(error);
    }
    logger.error(TAG, `[错误] url=${url}, error=${message}`);
  }
}

export const ngfLoggingInterceptor: LoggingInterceptorFacade = new LoggingInterceptorFacade();
