import { http } from '@kit.NetworkKit';
import { logger } from '../../utils/Logger';
import { IHttpClient, NGFHttpRequestOptions, NGFHttpResponse, NGFHttpMethod } from '../contracts/IHttpClient';

const TAG: string = 'NGFHttpClientFacade';

export class HttpClientFacade implements IHttpClient {
  async request(options: NGFHttpRequestOptions): Promise<NGFHttpResponse> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(
        options.url,
        this.buildOptions(options)
      ) as http.HttpResponse;
      const headerStr = this.stringifyHeaders(response.header as object);
      const rawResult = response.result;
      const resultStr = typeof rawResult === 'string' ? rawResult : '';
      const cookies = response.cookies !== undefined ? response.cookies : '';
      logger.debug(TAG, `请求完成: url=${options.url}, status=${response.responseCode}`);
      return new NGFHttpResponse(response.responseCode, headerStr, resultStr, cookies);
    } catch (error) {
      const message = this.errorToString(error as Object | string | number | boolean);
      logger.error(TAG, `请求失败: url=${options.url}, error=${message}`);
      throw new Error(`HTTP request failed: ${message}`);
    } finally {
      httpRequest.destroy();
    }
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
