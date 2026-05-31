/**
 * 路由拦截结果
 */
export class NGFRouteInterceptResult {
  readonly proceed: boolean;
  readonly redirectPage: string;
  readonly modifiedParams: string;

  constructor(proceed: boolean, redirectPage: string = '', modifiedParams: string = '') {
    this.proceed = proceed;
    this.redirectPage = redirectPage;
    this.modifiedParams = modifiedParams;
  }

  static allow(): NGFRouteInterceptResult {
    return new NGFRouteInterceptResult(true);
  }

  static block(): NGFRouteInterceptResult {
    return new NGFRouteInterceptResult(false);
  }

  static redirect(pageName: string, params: string = ''): NGFRouteInterceptResult {
    return new NGFRouteInterceptResult(true, pageName, params);
  }
}

/**
 * 路由拦截器接口
 */
export interface IRouteInterceptor {
  readonly interceptorName: string;
  readonly priority: number;
  intercept(pageName: string, paramsJson: string): Promise<NGFRouteInterceptResult>;
}

/**
 * 路由拦截管理器接口
 */
export interface IRouteInterceptorManager {
  addInterceptor(interceptor: IRouteInterceptor): void;
  removeInterceptor(interceptorName: string): boolean;
  listInterceptors(): Array<string>;
  processNavigation(pageName: string, paramsJson: string): Promise<NGFRouteInterceptResult>;
}
