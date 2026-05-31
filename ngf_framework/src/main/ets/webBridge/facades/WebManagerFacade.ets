import { IWebBridge } from '../contracts/IWebBridge';
import { logger } from '../../utils/Logger';

const TAG: string = 'WebManagerFacade';

export class WebManagerFacade implements IWebBridge {
  private methods: Map<string, (params: string) => Promise<string>> = new Map();

  registerMethod(methodName: string, callback: (params: string) => Promise<string>): void {
    this.methods.set(methodName, callback);
    logger.debug(TAG, `注册 WebBridge 方法: ${methodName}`);
  }

  unregisterMethod(methodName: string): void {
    this.methods.delete(methodName);
    logger.debug(TAG, `移除 WebBridge 方法: ${methodName}`);
  }

  getProxyObject(): Object {
    // 创建一个代理对象，将所有注册的方法包装后返回
    const proxy: Record<string, Function> = {};
    
    // ArkWeb 要求注入的对象方法必须是同步形式，内部可通过 Promise 配合 WebJSBridge 实现异步，
    // 这里做最简单的同步接口暴露（H5 端需配合异步回调封装）
    this.methods.forEach((callback, methodName) => {
      proxy[methodName] = (paramsJson: string) => {
        logger.info(TAG, `H5 调用原生方法: ${methodName}, 参数: ${paramsJson}`);
        // 实际开发中通常返回一个 Promise，或者接受一个 callbackId，由原生执行完毕后再调用 WebViewController.runJavaScript 返回结果
        // 这里简化为直接返回 Promise 字符串，需要使用 ArkWeb 的新异步注入机制
        return callback(paramsJson);
      };
    });

    return proxy;
  }
}

export const ngfWebBridge: IWebBridge = new WebManagerFacade();
