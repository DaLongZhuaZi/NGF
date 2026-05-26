import web_webview from '@ohos.web.webview';
import { ngfWebBridge } from '../facades/WebManagerFacade';
import { logger } from '../../utils/Logger';

const TAG: string = 'NGFWebView';

@Component
export struct NGFWebView {
  @Prop src: string;
  private controller: web_webview.WebviewController = new web_webview.WebviewController();
  
  build() {
    Web({ src: this.src, controller: this.controller })
      .javaScriptAccess(true)
      .domStorageAccess(true)
      .mixedMode(MixedMode.All)
      .onControllerAttached(() => {
        logger.info(TAG, `WebView attached, injecting NGF WebBridge`);
        // 注入全局对象 NGFBridge
        this.controller.registerJavaScriptProxy(
          ngfWebBridge.getProxyObject(),
          'NGFBridge',
          [] // 方法名列表将在最新 API 中自动推断，或需显式列出（此版本简化）
        );
        this.controller.refresh();
      })
      .onConsole((event) => {
        logger.debug(TAG, `H5 Console [${event?.message.getMessageLevel()}]: ${event?.message.getMessage()}`);
        return false;
      })
  }
}
