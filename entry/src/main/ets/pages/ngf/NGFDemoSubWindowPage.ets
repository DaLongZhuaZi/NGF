import { ngfPlatformWindowManagerFacade } from 'ngf_framework';
import { NGFSettingsPage } from './NGFSettingsPage';
import { NGFTaskManagerPage } from './NGFTaskManagerPage';
import { HdsNavigation } from '@kit.UIDesignKit';

@Entry
@Component
struct NGFDemoSubWindowPage {
  @State targetRouteName: string = '';
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private isVisible: boolean = false;

  aboutToAppear() {
    this.targetRouteName = AppStorage.get('CurrentSubWindowRoute') as string || '';
    if (this.targetRouteName === 'NGFTaskManager') {
      this.pathStack.pushPathByName('NGFTaskManager', null, false);
      this.pathStack.setInterception({
        willShow: (from: NavDestinationContext | "navBar", to: NavDestinationContext | "navBar", operation: NavigationOperation, animated: boolean) => {
          if (operation === NavigationOperation.POP && to === 'navBar') {
            this.closeSubWindow('sub_window_task');
          }
        }
      });
    }

    setTimeout(() => {
      this.getUIContext()?.animateTo({ duration: 300, curve: Curve.Friction }, () => {
        this.isVisible = true;
      });
    }, 50);
  }

  private closeSubWindow(windowName: string) {
    this.getUIContext().animateTo({ duration: 250, curve: Curve.Friction, onFinish: () => {
      ngfPlatformWindowManagerFacade.destroySubWindow(windowName);
    }}, () => {
      this.isVisible = false;
    });
  }

  @Builder
  buildNavDestination(name: string, param: Object) {
    if (name === 'NGFTaskManager') {
      NGFTaskManagerPage()
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.isVisible) {
        if (this.targetRouteName === 'NGFSettings') {
          Column() {
            Row() {
              Text($r('app.string.subwin_settings_title'))
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
              Blank()
              Button($r('app.string.subwin_btn_close'))
                .type(ButtonType.Capsule)
                .backgroundColor($r('app.color.button_primary'))
                .fontColor($r('app.color.text_white'))
                .onClick(() => this.closeSubWindow('sub_window_settings'))
            }.width('100%').padding(16)
            
            Scroll() {
              NGFSettingsPage()
            }.layoutWeight(1).width('100%')
          }
          .width('90%')
          .height('85%')
          .backgroundColor($r('app.color.background_primary'))
          .borderRadius(16)
          .clip(true)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.9, y: 0.9 })))
        } else if (this.targetRouteName === 'NGFTaskManager') {
          Column() {
            Row() {
              Text($r('app.string.subwin_task_title'))
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
              Blank()
              Button($r('app.string.subwin_btn_close'))
                .type(ButtonType.Capsule)
                .backgroundColor($r('app.color.button_primary'))
                .fontColor($r('app.color.text_white'))
                .onClick(() => this.closeSubWindow('sub_window_task'))
            }.width('100%').padding(16).zIndex(10)

            HdsNavigation(this.pathStack) { }
            .navDestination(this.buildNavDestination)
            .hideTitleBar(true)
            .layoutWeight(1)
            .width('100%')
          }
          .width('90%')
          .height('85%')
          .backgroundColor($r('app.color.background_primary'))
          .borderRadius(16)
          .clip(true)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.9, y: 0.9 })))
        } else {
          Text($r('app.string.subwin_unknown_content')).fontColor(Color.White)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isVisible ? '#40000000' : '#00000000') // 随动画变色
  }
}
