import { HdsNavigation, hdsMaterial, HdsNavigationTitleMode } from '@kit.UIDesignKit';
import { common } from '@kit.AbilityKit';
import { NGFImmersiveTopChromeUnderlay } from 'ngf_framework';
import { NGFHdsTitleBarOptionsFactory } from 'ngf_framework';
import { NGFSystemResourcePreviewPage } from './SystemResourcePreviewPage';
import { NGFDemoDataStoragePage } from './NGFDemoDataStoragePage';

@Entry
@Component
struct NGFDemoMultitonPage {
  @State targetRouteName: string = '';
  @State private pathStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.targetRouteName = AppStorage.get('CurrentMultitonRoute') as string || '';
    if (this.targetRouteName) {
      this.pathStack.pushPathByName(this.targetRouteName, null, false);
      this.pathStack.setInterception({
        willShow: (from: NavDestinationContext | "navBar", to: NavDestinationContext | "navBar", operation: NavigationOperation, animated: boolean) => {
          if (operation === NavigationOperation.POP && to === 'navBar') {
            let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
            context.terminateSelf();
          }
        }
      });
    }
  }

  @Builder
  buildNavDestination(name: string, param: Object) {
    if (name === 'SystemResourcePreview') {
      NGFSystemResourcePreviewPage()
    } else if (name === 'NGFDemoDataStorage') {
      NGFDemoDataStoragePage()
    }
  }

  build() {
    HdsNavigation(this.pathStack) {
      Stack({ alignContent: Alignment.Center }) {
        NGFImmersiveTopChromeUnderlay()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background_primary'))
    }
    .navDestination(this.buildNavDestination)
    .titleBar(NGFHdsTitleBarOptionsFactory.build($r('app.string.multiton_window_title'), 'Multiton', $r('app.color.background_primary'), hdsMaterial.MaterialLevel.EXQUISITE))
    .titleMode(HdsNavigationTitleMode.FREE)
    .hideTitleBar(true) // 隐藏根页面的标题栏，依靠子页面的标题栏
    .hideBackButton(true)
  }
}
