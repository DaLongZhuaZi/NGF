import { http } from '@kit.NetworkKit';
import { logger } from '../../utils/Logger';
import { IHttpClient, NGFHttpRequestOptions, NGFHttpResponse, NGFHttpMethod } from '../contracts/IHttpClient';
import { IHttpInterceptor } from '../contracts/IHttpInterceptor';

const TAG: string = 'NGFHttpClientFacade';

export class HttpClientFacade implements IHttpClient {
  private interceptors: IHttpInterceptor[] = [];

  public addInterceptor(interceptor: IHttpInterceptor): void {
    this.interceptors.push(interceptor);
  }

  async request(options: NGFHttpRequestOptions): Promise<NGFHttpResponse> {
    let finalOptions = options;
    for (let i = 0; i < this.interceptors.length; i++) {
      finalOptions = await this.interceptors[i].onRequest(finalOptions);
    }

    let finalResponse: NGFHttpResponse | null = null;
    let attempts = 0;
    const maxAttempts = finalOptions.maxRetries + 1;
    let lastError: Error | null = null;

    while (attempts < maxAttempts) {
      const httpRequest = http.createHttp();
      try {
        const response = await httpRequest.request(
          finalOptions.url,
          this.buildOptions(finalOptions)
        ) as http.HttpResponse;
        const headerStr = this.stringifyHeaders(response.header as object);
        const rawResult = response.result;
        const resultStr = typeof rawResult === 'string' ? rawResult : '';
        const cookies = response.cookies !== undefined ? response.cookies : '';
        logger.debug(TAG, `请求完成: url=${finalOptions.url}, status=${response.responseCode}`);
        finalResponse = new NGFHttpResponse(response.responseCode, headerStr, resultStr, cookies);
        httpRequest.destroy();
        break; // 成功则跳出循环
      } catch (error) {
        attempts++;
        const message = this.errorToString(error as Object | string | number | boolean);
        logger.warn(TAG, `请求尝试失败: url=${finalOptions.url}, attempt=${attempts}, error=${message}`);
        lastError = new Error(`HTTP request failed: ${message}`);
        httpRequest.destroy();
        
        if (attempts >= maxAttempts) {
          logger.error(TAG, `请求重试耗尽: url=${finalOptions.url}, maxRetries=${finalOptions.maxRetries}`);
        } else {
          await this.sleep(1000 * attempts);
        }
      }
    }

    if (!finalResponse) {
      throw lastError || new Error('HTTP request failed');
    }

    for (let i = this.interceptors.length - 1; i >= 0; i--) {
      finalResponse = await this.interceptors[i].onResponse(finalResponse);
    }

    return finalResponse;
  }

  private async sleep(durationMs: number): Promise<void> {
    await new Promise<void>((resolve: () => void) => {
      setTimeout((): void => {
        resolve();
      }, durationMs);
    });
  }

  private buildOptions(options: NGFHttpRequestOptions): http.HttpRequestOptions {
    const result: http.HttpRequestOptions = {
      method: this.mapMethod(options.method),
      connectTimeout: options.connectTimeout,
      readTimeout: options.readTimeout
    };
    if (options.header.length > 0) {
      result.header = options.header;
    }
    if (options.extraData.length > 0) {
      result.extraData = options.extraData;
    }
    return result;
  }

  private mapMethod(method: NGFHttpMethod): http.RequestMethod {
    if (method === NGFHttpMethod.GET) {
      return http.RequestMethod.GET;
    }
    if (method === NGFHttpMethod.POST) {
      return http.RequestMethod.POST;
    }
    if (method === NGFHttpMethod.PUT) {
      return http.RequestMethod.PUT;
    }
    if (method === NGFHttpMethod.DELETE) {
      return http.RequestMethod.DELETE;
    }
    if (method === NGFHttpMethod.PATCH) {
      return http.RequestMethod.POST;
    }
    if (method === NGFHttpMethod.HEAD) {
      return http.RequestMethod.HEAD;
    }
    return http.RequestMethod.GET;
  }

  private stringifyHeaders(header: object): string {
    try {
      const entries = Object.entries(header) as [string, string][];
      if (entries.length <= 0) {
        return '';
      }
      const parts: Array<string> = [];
      for (let index = 0; index < entries.length; index++) {
        const entry = entries[index];
        parts.push(`${entry[0]}: ${entry[1]}`);
      }
      return parts.join('\r\n');
    } catch {
      return '';
    }
  }

  private errorToString(error: Object | string | number | boolean): string {
    if (typeof error === 'string') {
      return error;
    }
    if (typeof error === 'number' || typeof error === 'boolean') {
      return String(error);
    }
    if (error instanceof Error) {
      return error.message;
    }
    return String(error);
  }
}

export const ngfHttpClientFacade: HttpClientFacade = new HttpClientFacade();
