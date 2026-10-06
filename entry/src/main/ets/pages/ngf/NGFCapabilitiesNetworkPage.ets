import {
  NGFAccessibilityBindingListener,
  NGFAccessibilityLifecycleBinding,
  NGFA11yTextScale,
  NGFInclusiveDesignResolved,
  a11yTouchTarget,
  ngfAccessibilityFacade,
  resolveA11yTextScaleForCurrent
} from 'ngf_framework';
import { HdsNavDestination } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import { logger } from 'ngf_framework';
import { NGFMaterialSurfaceTokens } from 'ngf_framework';
import { ngfVisualEffectsFacade } from 'ngf_framework';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from 'ngf_framework';
import { NGFHdsTitleBarOptionsFactory } from 'ngf_framework';
import { NGFPageWindowName, NGFPageWindowSupport } from './NGFPageWindowSupport';
import { ngfNetworkClient } from 'ngf_framework';

const TAG: string = 'NGFCapabilitiesNetworkPage';

const DEMO_TOP_CHROME: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#1A0F08', '#3D2508', '#1A1005', '#F59E0BD8', '#FCD34DD8', 160, 88
);

@Component
export struct NGFCapabilitiesNetworkPage {
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


  @State private pathStack: NavPathStack = new NavPathStack();
  @State private topInsetVp: number = 108;
  @State private statusMessage: ResourceStr = '';
  @State private responseData: string = '';
  @StorageProp('ngf_visual_effects_should_use_system_material_surface') private useSysMat: boolean = true;

  aboutToAppear(): void {
    this.attachA11yBinding();
    NGFPageWindowSupport.loadDynamicTopInset(this.getUIContext(), 108, 108, (inset) => {
      this.topInsetVp = inset;
    });
    // NGFPageWindowSupport 恢复使用默认页面设置（如有需要可新增常数）
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: DEMO_TOP_CHROME })

        Scroll() {
          Column({ space: this.a11yScale.paragraphSpacing(12, 18) }) {
            this.buildTitleCard()
            this.buildNetworkActionCard()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: this.topInsetVp, bottom: 36 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        .backgroundColor($r('app.color.background_transparent'))
      }
      .width('100%')
      .height('100%')
    }
    .titleBar(NGFHdsTitleBarOptionsFactory.build(
      $r('app.string.card_network_title'),
      $r('app.string.card_network_desc'),
      '#1A0F08',
      hdsMaterial.MaterialLevel.GENTLE,
      true,
      false
    ))
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .onReady((context: NavDestinationContext): void => {
      this.pathStack = context.pathStack;
    })
    .onBackPressed((): boolean => {
      NGFPageWindowSupport.restoreMainMenu();
      this.pathStack.pop();
      return true;
    })
  }

  aboutToDisappear(): void {
    this.detachA11yBinding();
    NGFPageWindowSupport.restoreMainMenu();
  }

  @Builder
  private buildTitleCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
      Text($r('app.string.card_network_title'))
        .fontSize(this.a11yScale.font(22))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(22)))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text($r('app.string.card_network_desc'))
        .fontSize(this.a11yScale.font(13))
        .lineHeight(this.a11yScale.explicitLineHeight(this.a11yScale.font(13), 20))
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(18)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwareProminentBackgroundEffect(this.useSysMat))
    .borderRadius(NGFMaterialSurfaceTokens.PROMINENT_RADIUS)
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwareProminentShadow(this.useSysMat))
  }

  @Builder
  private buildNetworkActionCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Button($r('app.string.btn_fetch_data'))
        .width('100%')
        .height(44)
        .fontSize(this.a11yScale.font(14))
        .borderRadius(12)
        .fontColor($r('app.color.text_primary'))
        .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
        .onClick((): void => {
          void this.handleFetchData();
        })

      if (this.responseData.length > 0) {
        Text(this.responseData)
          .fontSize(this.a11yScale.font(13))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
          .fontColor($r('app.color.text_body'))
          .width('100%')
          .padding(10)
          .borderRadius(10)
          .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_surface'), this.useSysMat))
      }

      if ((typeof this.statusMessage === "string" ? this.statusMessage : '').length > 0) {
        Text(this.statusMessage)
          .fontSize(this.a11yScale.font(12))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
          .fontColor($r('app.color.tag_green'))
          .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.panel_background'), this.useSysMat))
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect(this.useSysMat))
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1, this.useSysMat),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.card_border'), this.useSysMat)
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow(this.useSysMat))
  }

  private async handleFetchData(): Promise<void> {
    try {
      this.statusMessage = "Loading...";
      const response = await ngfNetworkClient.get('https://httpbin.org/get');
      this.responseData = 'Status: ' + response.statusCode + '\\n\\n' + String(response.body).substring(0, 300) + '...';
      this.statusMessage = "Success";
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.statusMessage = 'Error: ' + message;
    }
  }
}
