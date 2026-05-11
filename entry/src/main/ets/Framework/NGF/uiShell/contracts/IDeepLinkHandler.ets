/**
 * 深链接解析结果
 */
export class NGFDeepLinkResult {
  readonly matched: boolean;
  readonly pageName: string;
  readonly paramsJson: string;
  readonly originalUrl: string;

  constructor(matched: boolean, pageName: string, paramsJson: string, originalUrl: string) {
    this.matched = matched;
    this.pageName = pageName;
    this.paramsJson = paramsJson;
    this.originalUrl = originalUrl;
  }
}

/**
 * 深链接路由规则
 */
export class NGFDeepLinkRoute {
  readonly scheme: string;
  readonly host: string;
  readonly pathPattern: string;
  readonly pageName: string;

  constructor(scheme: string, host: string, pathPattern: string, pageName: string) {
    this.scheme = scheme;
    this.host = host;
    this.pathPattern = pathPattern;
    this.pageName = pageName;
  }
}

/**
 * 深链接处理器接口
 */
export interface IDeepLinkHandler {
  registerRoute(route: NGFDeepLinkRoute): void;
  unregisterRoute(scheme: string, host: string, pathPattern: string): boolean;
  resolve(url: string): NGFDeepLinkResult;
  navigate(url: string): boolean;
  listRoutes(): Array<NGFDeepLinkRoute>;
}
