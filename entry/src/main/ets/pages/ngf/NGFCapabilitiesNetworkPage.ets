import { HdsNavDestination } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import { logger } from '../../Framework/NGF/utils/Logger';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from '../../Framework/NGF/uiShell/components/NGFImmersiveTopChrome';
import { NGFHdsTitleBarOptionsFactory } from '../../Framework/NGF/uiShell/components/HdsNavigationSupport';
import { NGFPageWindowName, NGFPageWindowSupport } from './NGFPageWindowSupport';
import { ngfNetworkClient } from '../../Framework/NGF/index';

const TAG: string = 'NGFCapabilitiesNetworkPage';

const DEMO_TOP_CHROME: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#1A0F08', '#3D2508', '#1A1005', '#F59E0BD8', '#FCD34DD8', 160, 88
);

@Component
export struct NGFCapabilitiesNetworkPage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private statusMessage: ResourceStr = '';
  @State private responseData: string = '';

  aboutToAppear(): void {
    // NGFPageWindowSupport 恢复使用默认页面设置（如有需要可新增常数）
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: DEMO_TOP_CHROME })

        Scroll() {
          Column({ space: 12 }) {
            this.buildTitleCard()
            this.buildNetworkActionCard()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: DEMO_TOP_CHROME.metrics.contentTopInset, bottom: 36 })
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
    NGFPageWindowSupport.restoreMainMenu();
  }

  @Builder
  private buildTitleCard(): void {
    Column({ space: 8 }) {
      Text($r('app.string.card_network_title'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.panel_background'))
      Text($r('app.string.card_network_desc'))
        .fontSize(13)
        .lineHeight(20)
        .fontColor($r('app.color.text_white_low'))
    }
    .width('100%')
    .padding(18)
    .linearGradient({
      angle: 140,
      colors: [['#78350F', 0], ['#F59E0B', 1]]
    })
    .borderRadius(20)
    .shadow({ radius: 14, color: '#1A78350F', offsetX: 0, offsetY: 8 })
  }

  @Builder
  private buildNetworkActionCard(): void {
    Column({ space: 10 }) {
      Button($r('app.string.btn_fetch_data'))
        .width('100%')
        .height(44)
        .fontSize(14)
        .borderRadius(12)
        .backgroundColor($r('app.color.button_primary'))
        .onClick((): void => {
          void this.handleFetchData();
        })

      if (this.responseData.length > 0) {
        Text(this.responseData)
          .fontSize(13)
          .fontColor($r('app.color.text_body'))
          .width('100%')
          .padding(10)
          .backgroundColor($r('app.color.background_surface'))
          .borderRadius(10)
      }

      if ((typeof this.statusMessage === "string" ? this.statusMessage : '').length > 0) {
        Text(this.statusMessage)
          .fontSize(12)
          .fontColor($r('app.color.tag_green'))
          .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.card_border') })
    .shadow({ radius: 10, color: $r('app.color.card_shadow_demo'), offsetX: 0, offsetY: 4 })
  }

  private async handleFetchData(): Promise<void> {
    try {
      this.statusMessage = "Loading...";
      const response = await ngfNetworkClient.get('https://httpbin.org/get');
      this.responseData = `Status: ${response.statusCode}\n\n${String(response.body).substring(0, 300)}...`;
      this.statusMessage = "Success";
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.statusMessage = `Error: ${message}`;
    }
  }
}
