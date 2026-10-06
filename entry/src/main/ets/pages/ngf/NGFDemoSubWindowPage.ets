import {
  NGFAccessibilityBindingListener,
  NGFAccessibilityLifecycleBinding,
  NGFA11yTextScale,
  NGFInclusiveDesignResolved,
  a11yTouchTarget,
  ngfAccessibilityFacade,
  resolveA11yTextScaleForCurrent
} from 'ngf_framework';
import { ngfPlatformWindowManagerFacade } from 'ngf_framework';
import { NGFMaterialSurfaceTokens } from 'ngf_framework';
import { ngfVisualEffectsFacade } from 'ngf_framework';
import { NGFSettingsPage } from './NGFSettingsPage';
import { NGFTaskManagerPage } from './NGFTaskManagerPage';
import { HdsNavigation } from '@kit.UIDesignKit';

@Entry
@Component
struct NGFDemoSubWindowPage {
  /**
   * 适老呈现层（.rules/skill-elderly-ui.md）：字号 / 行高 / 点击区一律经缩放器取。
   * 普通档原样返回（零视觉回归），适老档抬到附件2 §1.1（≥18）与 §1.2（行距 ≥1.3 倍）。
   */
  @State private a11yScale: NGFA11yTextScale = resolveA11yTextScaleForCurrent();
  private a11yBinding: NGFAccessibilityLifecycleBinding | null = null;

  /** 订阅平台策略变化；与 detach 严格成对 */
  private attachA11yBinding(): void {
    if (this.a11yBinding !== null) {
      return;
    }
    const listener: NGFAccessibilityBindingListener = {
      onInclusiveDesignChanged: (resolved: NGFInclusiveDesignResolved): void => {
        this.a11yScale = resolveA11yTextScaleForCurrent();
      }
    };
    this.a11yBinding = new NGFAccessibilityLifecycleBinding(listener);
    this.a11yBinding.attach();
  }

  /** 取消订阅（幂等） */
  private detachA11yBinding(): void {
    const binding: NGFAccessibilityLifecycleBinding | null = this.a11yBinding;
    if (binding !== null) {
      binding.detach();
      this.a11yBinding = null;
    }
  }


  @State targetRouteName: string = '';
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private isVisible: boolean = false;
  @StorageProp('ngf_visual_effects_should_use_system_material_surface') private useSysMat: boolean = true;

  aboutToAppear() {
    // 适老呈现层：订阅平台策略（与下面的 aboutToDisappear 成对，SDK 硬性要求）
    this.attachA11yBinding();
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

  aboutToDisappear() {
    // 与 aboutToAppear 的 attach 成对：不取消可能在生命周期结束后回调导致崩溃
    this.detachA11yBinding();
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
                .fontSize(this.a11yScale.font(18))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(18)))
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
              Blank()
              Button($r('app.string.subwin_btn_close'))
                .type(ButtonType.Capsule)
                .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
                .fontColor($r('app.color.text_primary'))
                .onClick(() => this.closeSubWindow('sub_window_settings'))
            }.width('100%').padding(16)
            
            Scroll() {
              NGFSettingsPage()
            }.layoutWeight(1).width('100%')
          }
          .width('90%')
          .height('85%')
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_primary'), this.useSysMat))
          .borderRadius(16)
          .clip(true)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.9, y: 0.9 })))
        } else if (this.targetRouteName === 'NGFTaskManager') {
          Column() {
            Row() {
              Text($r('app.string.subwin_task_title'))
                .fontSize(this.a11yScale.font(18))
                .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(18)))
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
              Blank()
              Button($r('app.string.subwin_btn_close'))
                .type(ButtonType.Capsule)
                .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
                .fontColor($r('app.color.text_primary'))
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
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_primary'), this.useSysMat))
          .borderRadius(16)
          .clip(true)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.9, y: 0.9 })))
        } else {
          Text($r('app.string.subwin_unknown_content')).fontColor($r('app.color.text_primary'))
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isVisible ? '#40000000' : '#00000000') // 随动画变色
  }
}
