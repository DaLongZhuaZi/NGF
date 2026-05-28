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
import { ngfMediaPickerFacade } from '../../Framework/NGF/index';

const TAG: string = 'NGFCapabilitiesMediaPage';

const DEMO_TOP_CHROME: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#1A0F08', '#3D2508', '#1A1005', '#F59E0BD8', '#FCD34DD8', 160, 88
);

@Component
export struct NGFCapabilitiesMediaPage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private topInsetVp: number = 108;
  @State private statusMessage: ResourceStr = '';
  @State private selectedUris: Array<string> = [];

  aboutToAppear(): void {
    NGFPageWindowSupport.loadDynamicTopInset(this.getUIContext(), 108, 108, (inset) => {
      this.topInsetVp = inset;
    });
  }

  build() {
    HdsNavDestination() {
      Stack({ alignContent: Alignment.TopStart }) {
        NGFImmersiveTopChromeUnderlay({ spec: DEMO_TOP_CHROME })

        Scroll() {
          Column({ space: 12 }) {
            this.buildTitleCard()
            this.buildActionCard()
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
      $r('app.string.card_media_title'),
      $r('app.string.card_media_desc'),
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
      Text($r('app.string.card_media_title'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.panel_background'))
      Text($r('app.string.card_media_desc'))
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
  private buildActionCard(): void {
    Column({ space: 10 }) {
      Button($r('app.string.btn_media_picker'))
        .width('100%')
        .height(44)
        .fontSize(14)
        .borderRadius(12)
        .backgroundColor($r('app.color.tag_cyan'))
        .onClick((): void => {
          void this.handlePickMedia();
        })

      if (this.selectedUris.length > 0) {
        Column({ space: 8 }) {
          ForEach(this.selectedUris, (uri: string) => {
            Image(uri)
              .width('100%')
              .height(200)
              .objectFit(ImageFit.Cover)
              .borderRadius(12)
          })
        }
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

  private async handlePickMedia(): Promise<void> {
    try {
      this.statusMessage = "Launching PhotoPicker...";
      const uris: Array<string> = await ngfMediaPickerFacade.pickImages(3) as Array<string>;
      this.selectedUris = uris;
      this.statusMessage = `Selected ${uris.length} media files`;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.statusMessage = `Error: ${message}`;
    }
  }
}
