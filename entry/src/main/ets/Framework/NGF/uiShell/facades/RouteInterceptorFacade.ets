import { logger } from '../../utils/Logger';
import {
  IRouteInterceptor,
  IRouteInterceptorManager,
  NGFRouteInterceptResult
} from '../contracts/IRouteInterceptor';

const TAG: string = 'NGFRouteInterceptorFacade';

export class RouteInterceptorFacade implements IRouteInterceptorManager {
  private readonly interceptors: Array<IRouteInterceptor> = [];

  addInterceptor(interceptor: IRouteInterceptor): void {
    for (let index = 0; index < this.interceptors.length; index++) {
      if (this.interceptors[index].interceptorName === interceptor.interceptorName) {
        logger.warn(TAG, `拦截器已存在: ${interceptor.interceptorName}`);
        return;
      }
    }
    this.interceptors.push(interceptor);
    this.interceptors.sort((a: IRouteInterceptor, b: IRouteInterceptor) => {
      return a.priority - b.priority;
    });
    logger.info(TAG, `添加拦截器: name=${interceptor.interceptorName}, priority=${interceptor.priority}`);
  }

  removeInterceptor(interceptorName: string): boolean {
    for (let index = 0; index < this.interceptors.length; index++) {
      if (this.interceptors[index].interceptorName === interceptorName) {
        this.interceptors.splice(index, 1);
        logger.info(TAG, `移除拦截器: name=${interceptorName}`);
        return true;
      }
    }
    logger.warn(TAG, `移除拦截器未找到: name=${interceptorName}`);
    return false;
  }

  listInterceptors(): Array<string> {
    const names: Array<string> = [];
    for (let index = 0; index < this.interceptors.length; index++) {
      names.push(this.interceptors[index].interceptorName);
    }
    return names;
  }

  async processNavigation(pageName: string, paramsJson: string): Promise<NGFRouteInterceptResult> {
    if (this.interceptors.length <= 0) {
      return NGFRouteInterceptResult.allow();
    }

    let currentPage: string = pageName;
    let currentParams: string = paramsJson;

    for (let index = 0; index < this.interceptors.length; index++) {
      const interceptor = this.interceptors[index];
      logger.debug(TAG, `执行拦截器: name=${interceptor.interceptorName}, page=${currentPage}`);
      try {
        const result = await interceptor.intercept(currentPage, currentParams);
        if (!result.proceed) {
          logger.info(TAG, `导航被拦截: interceptor=${interceptor.interceptorName}, page=${currentPage}`);
          return NGFRouteInterceptResult.block();
        }
        if (result.redirectPage.length > 0 && result.redirectPage !== currentPage) {
          logger.info(TAG, `导航重定向: ${currentPage} -> ${result.redirectPage}, interceptor=${interceptor.interceptorName}`);
          currentPage = result.redirectPage;
        }
        if (result.modifiedParams.length > 0) {
          currentParams = result.modifiedParams;
        }
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        logger.error(TAG, `拦截器异常: name=${interceptor.interceptorName}, error=${message}`);
      }
    }

    if (currentPage !== pageName) {
      return NGFRouteInterceptResult.redirect(currentPage, currentParams);
    }
    return NGFRouteInterceptResult.allow();
  }
}

export const ngfRouteInterceptorFacade: RouteInterceptorFacade = new RouteInterceptorFacade();
