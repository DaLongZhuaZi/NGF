import { HdsNavDestination } from '@kit.UIDesignKit';
import { hdsMaterial } from '@kit.UIDesignKit';
import { logger } from 'ngf_framework';
import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from 'ngf_framework';
import { NGFHdsTitleBarOptionsFactory } from 'ngf_framework';
import { NGFPageWindowName, NGFPageWindowSupport } from './NGFPageWindowSupport';
import { ngfLocationManagerFacade, ngfSensorManagerFacade } from 'ngf_framework';
import { ngfPermissionManagerFacade } from 'ngf_framework';

const TAG: string = 'NGFCapabilitiesHardwarePage';

const DEMO_TOP_CHROME: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
  '#1A0F08', '#3D2508', '#1A1005', '#F59E0BD8', '#FCD34DD8', 160, 88
);

@Component
export struct NGFCapabilitiesHardwarePage {
  @State private pathStack: NavPathStack = new NavPathStack();
  @State private topInsetVp: number = 108;
  @State private statusMessage: ResourceStr = '';
  @State private hardwareData: string = '';

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
      $r('app.string.card_hardware_title'),
      $r('app.string.card_hardware_desc'),
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
    ngfSensorManagerFacade.stopAccelerometerListener();
  }

  @Builder
  private buildTitleCard(): void {
    Column({ space: 8 }) {
      Text($r('app.string.card_hardware_title'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.panel_background'))
      Text($r('app.string.card_hardware_desc'))
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
      Row({ space: 10 }) {
        Button($r('app.string.btn_hardware_location'))
          .layoutWeight(1)
          .height(44)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor($r('app.color.tag_amber'))
          .onClick((): void => {
            void this.handleGetLocation();
          })
        
        Button($r('app.string.btn_hardware_sensor'))
          .layoutWeight(1)
          .height(44)
          .fontSize(14)
          .borderRadius(12)
          .backgroundColor($r('app.color.tag_purple'))
          .onClick((): void => {
            void this.handleStartShake();
          })
      }.width('100%')

      if (this.hardwareData.length > 0) {
        Text(this.hardwareData)
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

  /**
   * @ohos.permission ohos.permission.APPROXIMATELY_LOCATION
   */
  private async handleGetLocation(): Promise<void> {
    try {
      this.statusMessage = "Requesting location permission...";
      const granted = await ngfPermissionManagerFacade.requestPermissions(['ohos.permission.APPROXIMATELY_LOCATION']);
      if (!granted) {
        this.statusMessage = "Location permission denied by user";
        return;
      }

      this.statusMessage = "Requesting location...";
      const location: Record<string, number> | null = await ngfLocationManagerFacade.getCurrentLocation() as Object as Record<string, number> | null;
      if (location) {
        this.hardwareData = `Latitude: ${location.latitude}\nLongitude: ${location.longitude}`;
        this.statusMessage = "Location retrieved";
      } else {
        this.statusMessage = "Location access denied or unavailable";
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.statusMessage = `Error: ${message}`;
    }
  }

  /**
   * @ohos.permission ohos.permission.ACCELEROMETER
   */
  private async handleStartShake(): Promise<void> {
    this.statusMessage = "Requesting sensor permission...";
    const granted = await ngfPermissionManagerFacade.requestPermissions(['ohos.permission.ACCELEROMETER']);
    if (!granted) {
      this.statusMessage = "Sensor permission denied by user";
      return;
    }

    this.statusMessage = "Shake listener started. Shake device!";
    ngfSensorManagerFacade.startAccelerometerListener(() => {
      this.hardwareData = `Shake detected at ${new Date().toLocaleTimeString()}!`;
    });
  }
}
