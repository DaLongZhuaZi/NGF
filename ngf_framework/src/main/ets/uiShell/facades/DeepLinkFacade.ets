import { logger } from '../../utils/Logger';
import { IDeepLinkHandler, NGFDeepLinkResult, NGFDeepLinkRoute } from '../contracts/IDeepLinkHandler';
import { ngfNavigationShellFacade } from './NavigationShellFacade';

const TAG: string = 'NGFDeepLinkFacade';

class NGFParsedUrl {
  readonly scheme: string;
  readonly host: string;
  readonly path: string;
  readonly queryParams: string;

  constructor(scheme: string, host: string, path: string, queryParams: string) {
    this.scheme = scheme;
    this.host = host;
    this.path = path;
    this.queryParams = queryParams;
  }
}

export class DeepLinkFacade implements IDeepLinkHandler {
  private readonly routes: Array<NGFDeepLinkRoute> = [];

  registerRoute(route: NGFDeepLinkRoute): void {
    this.routes.push(route);
    logger.info(TAG, `注册深链接路由: ${route.scheme}://${route.host}${route.pathPattern} -> ${route.pageName}`);
  }

  unregisterRoute(scheme: string, host: string, pathPattern: string): boolean {
    for (let index = 0; index < this.routes.length; index++) {
      const route = this.routes[index];
      if (route.scheme === scheme && route.host === host && route.pathPattern === pathPattern) {
        this.routes.splice(index, 1);
        logger.info(TAG, `注销深链接路由: ${scheme}://${host}${pathPattern}`);
        return true;
      }
    }
    logger.warn(TAG, `注销深链接路由未找到: ${scheme}://${host}${pathPattern}`);
    return false;
  }

  resolve(url: string): NGFDeepLinkResult {
    const trimmedUrl = url.trim();
    if (trimmedUrl.length <= 0) {
      return new NGFDeepLinkResult(false, '', '', '');
    }

    const parsed = this.parseUrl(trimmedUrl);
    if (parsed === null) {
      logger.debug(TAG, `URL 解析失败: ${trimmedUrl}`);
      return new NGFDeepLinkResult(false, '', '', trimmedUrl);
    }

    for (let index = 0; index < this.routes.length; index++) {
      const route = this.routes[index];
      if (route.scheme !== parsed.scheme) {
        continue;
      }
      if (route.host !== parsed.host) {
        continue;
      }
      if (this.matchPath(route.pathPattern, parsed.path)) {
        const paramsJson = this.buildParamsJson(parsed);
        logger.info(TAG, `深链接匹配: ${trimmedUrl} -> ${route.pageName}`);
        return new NGFDeepLinkResult(true, route.pageName, paramsJson, trimmedUrl);
      }
    }

    logger.debug(TAG, `深链接未匹配: ${trimmedUrl}`);
    return new NGFDeepLinkResult(false, '', '', trimmedUrl);
  }

  navigate(url: string): boolean {
    const result = this.resolve(url);
    if (!result.matched) {
      logger.warn(TAG, `深链接导航失败: 未匹配, url=${url}`);
      return false;
    }
    return ngfNavigationShellFacade.push(result.pageName, result.paramsJson);
  }

  listRoutes(): Array<NGFDeepLinkRoute> {
    const copied: Array<NGFDeepLinkRoute> = [];
    for (let index = 0; index < this.routes.length; index++) {
      copied.push(this.routes[index]);
    }
    return copied;
  }

  private parseUrl(url: string): NGFParsedUrl | null {
    const schemeEnd = url.indexOf('://');
    if (schemeEnd < 0) {
      return null;
    }
    const scheme = url.substring(0, schemeEnd);
    const afterScheme = url.substring(schemeEnd + 3);

    const queryStart = afterScheme.indexOf('?');
    const hostPath = queryStart >= 0 ? afterScheme.substring(0, queryStart) : afterScheme;
    const queryParams = queryStart >= 0 ? afterScheme.substring(queryStart + 1) : '';

    const pathStart = hostPath.indexOf('/');
    const host = pathStart >= 0 ? hostPath.substring(0, pathStart) : hostPath;
    const path = pathStart >= 0 ? hostPath.substring(pathStart) : '/';

    if (host.length <= 0) {
      return null;
    }
    return new NGFParsedUrl(scheme, host, path, queryParams);
  }

  private matchPath(pattern: string, path: string): boolean {
    if (pattern === path) {
      return true;
    }
    if (pattern === '/*') {
      return true;
    }
    const patternParts = this.splitPath(pattern);
    const pathParts = this.splitPath(path);
    if (patternParts.length !== pathParts.length) {
      return false;
    }
    for (let index = 0; index < patternParts.length; index++) {
      const patternPart = patternParts[index];
      if (patternPart.startsWith(':')) {
        continue;
      }
      if (patternPart !== pathParts[index]) {
        return false;
      }
    }
    return true;
  }

  private splitPath(path: string): Array<string> {
    const parts: Array<string> = [];
    const segments = path.split('/');
    for (let index = 0; index < segments.length; index++) {
      const segment = segments[index].trim();
      if (segment.length > 0) {
        parts.push(segment);
      }
    }
    return parts;
  }

  private buildParamsJson(parsed: NGFParsedUrl): string {
    const params: Map<string, string> = new Map<string, string>();

    const pathParts = this.splitPath(parsed.path);
    for (let index = 0; index < pathParts.length; index++) {
      params.set(`path_${index}`, pathParts[index]);
    }

    if (parsed.queryParams.length > 0) {
      const pairs = parsed.queryParams.split('&');
      for (let index = 0; index < pairs.length; index++) {
        const pair = pairs[index];
        const eqIndex = pair.indexOf('=');
        if (eqIndex > 0) {
          const key = decodeURIComponent(pair.substring(0, eqIndex));
          const value = decodeURIComponent(pair.substring(eqIndex + 1));
          params.set(key, value);
        }
      }
    }

    const entries = params.keys();
    let json = '{';
    let first = true;
    for (const key of entries) {
      if (!first) {
        json += ',';
      }
      json += `"${key}":"${params.get(key)}"`;
      first = false;
    }
    json += '}';
    return json;
  }
}

export const ngfDeepLinkFacade: DeepLinkFacade = new DeepLinkFacade();
