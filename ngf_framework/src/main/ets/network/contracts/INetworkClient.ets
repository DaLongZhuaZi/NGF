export interface NGFNetworkRequest {
  url: string;
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE';
  headers?: Record<string, string>;
  body?: string | Record<string, Object> | ArrayBuffer;
  timeoutMs?: number;
}

export interface NGFNetworkResponse {
  statusCode: number;
  headers: Record<string, string>;
  body: string; // 将 buffer 或对象序列化为 string 方便统一处理
}

export interface INetworkClient {
  /**
   * 发起网络请求
   */
  request(req: NGFNetworkRequest): Promise<NGFNetworkResponse>;

  /**
   * 快捷 GET 请求
   */
  get(url: string, headers?: Record<string, string>): Promise<NGFNetworkResponse>;

  /**
   * 快捷 POST 请求
   */
  post(url: string, body: string | Record<string, Object>, headers?: Record<string, string>): Promise<NGFNetworkResponse>;

  /**
   * 设置全局通用请求头（例如 Token、UA）
   */
  setGlobalHeader(key: string, value: string): void;

  /**
   * 移除全局通用请求头
   */
  removeGlobalHeader(key: string): void;
}
