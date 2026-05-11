/**
 * HTTP 请求方法枚举
 */
export enum NGFHttpMethod {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  DELETE = 'DELETE',
  PATCH = 'PATCH',
  HEAD = 'HEAD'
}

/**
 * HTTP 请求配置
 */
export class NGFHttpRequestOptions {
  readonly method: NGFHttpMethod;
  readonly url: string;
  readonly header: string;
  readonly extraData: string;
  readonly connectTimeout: number;
  readonly readTimeout: number;

  constructor(
    method: NGFHttpMethod,
    url: string,
    header: string = '',
    extraData: string = '',
    connectTimeout: number = 30000,
    readTimeout: number = 30000
  ) {
    this.method = method;
    this.url = url;
    this.header = header;
    this.extraData = extraData;
    this.connectTimeout = connectTimeout;
    this.readTimeout = readTimeout;
  }
}

/**
 * HTTP 响应结果
 */
export class NGFHttpResponse {
  readonly statusCode: number;
  readonly header: string;
  readonly result: string;
  readonly cookies: string;

  constructor(statusCode: number, header: string, result: string, cookies: string) {
    this.statusCode = statusCode;
    this.header = header;
    this.result = result;
    this.cookies = cookies;
  }

  isOk(): boolean {
    return this.statusCode >= 200 && this.statusCode < 300;
  }
}

/**
 * HTTP 客户端接口
 */
export interface IHttpClient {
  request(options: NGFHttpRequestOptions): Promise<NGFHttpResponse>;
}
