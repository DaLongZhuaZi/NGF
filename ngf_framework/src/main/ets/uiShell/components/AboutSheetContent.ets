import { bundleManager, common, Want } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { hdsEffect } from '@kit.UIDesignKit';
import { NGFHdsBackgroundEffectOptions } from './NGFHdsEffectPresets';
import { uiContextManager } from '../../platformOhos/UIContextManager';
import { logger } from '../../utils/Logger';

const TAG: string = 'AboutSheetContent';

interface ModuleStatus {
  label: Resource;
  active: boolean;
}

class AboutSheetGlassFactory {
  static buildSheetSurfaceEffect(): VisualEffect {
    const pointLightOptions = new NGFHdsPointLightOptionsImpl($r('app.color.glass_surface_overlay'), 0.32, 30, 0.22);
    const pointLightEffect = new NGFHdsPointLightEffectImpl(
      hdsEffect.PointLightSourceType.SOFT,
      hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
      pointLightOptions
    );
    return new hdsEffect.HdsEffectBuilder()
      .pointLight(pointLightEffect)
      .buildEffect();
  }

  static buildCardEffect(): VisualEffect {
    const pointLightOptions = new NGFHdsPointLightOptionsImpl($r('app.color.glass_chip_overlay'), 0.22, 24, 0.16);
    const pointLightEffect = new NGFHdsPointLightEffectImpl(
      hdsEffect.PointLightSourceType.SOFT,
      hdsEffect.PointLightIlluminatedType.BORDER,
      pointLightOptions
    );
    return new hdsEffect.HdsEffectBuilder()
      .pointLight(pointLightEffect)
      .buildEffect();
  }
}

class NGFHdsPointLightOptionsImpl implements hdsEffect.PointLightOptions {
  color?: ResourceColor;
  intensity?: number;
  height?: Dimension;
  bloom?: number;

  constructor(color: ResourceColor, intensity: number, height: Dimension, bloom: number) {
    this.color = color;
    this.intensity = intensity;
    this.height = height;
    this.bloom = bloom;
  }
}

class NGFHdsPointLightEffectImpl implements hdsEffect.PointLightEffect {
  sourceType?: hdsEffect.PointLightSourceType;
  illuminatedType?: hdsEffect.PointLightIlluminatedType;
  options?: hdsEffect.PointLightOptions;

  constructor(
    sourceType: hdsEffect.PointLightSourceType,
    illuminatedType: hdsEffect.PointLightIlluminatedType,
    options: hdsEffect.PointLightOptions
  ) {
    this.sourceType = sourceType;
    this.illuminatedType = illuminatedType;
    this.options = options;
  }
}

@Component
export struct AboutSheetContent {
  @State private appName: string = 'NGF';
  @State private bundleName: string = 'com.dlzz.ngf';
  @State private versionName: string = '1.0.0';
  @State private versionCode: number = 1000000;
  @State private buildVersion: string = '1';
  @State private sdkApiVersion: string = '23';
  @State private deviceModel: string = '';
  @State private osFullName: string = '';
  @State private brand: string = '';
  @State private vendor: string = 'DaLongzhuazi';
  @State private modules: Array<ModuleStatus> = [
    { label: $r('app.string.about_module_core'), active: true },
    { label: $r('app.string.about_module_data'), active: true },
    { label: $r('app.string.about_module_platform'), active: true },
    { label: $r('app.string.about_module_workflow'), active: true },
    { label: $r('app.string.about_module_source'), active: true },
    { label: $r('app.string.about_module_uishell'), active: true },
    { label: $r('app.string.about_module_i18n'), active: true },
    { label: $r('app.string.about_module_theme'), active: true },
    { label: $r('app.string.about_module_device'), active: true },
    { label: $r('app.string.about_module_security'), active: true }
  ];

  aboutToAppear(): void {
    this.loadBundleInfo();
    this.loadDeviceInfo();
  }

  private loadBundleInfo(): void {
    try {
      bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
        .then((info: bundleManager.BundleInfo): void => {
          if (info.name.length > 0) {
            this.bundleName = info.name;
          }
          if (info.versionName.length > 0) {
            this.versionName = info.versionName;
          }
          this.versionCode = info.versionCode;
          if (info.vendor.length > 0) {
            this.vendor = info.vendor;
          }
        })
        .catch((_err: Error): void => {});
    } catch (_error) {}
  }

  private loadDeviceInfo(): void {
    try {
      this.deviceModel = deviceInfo.productModel;
      this.osFullName = deviceInfo.osFullName;
      this.brand = deviceInfo.brand;
      const apiVersion = deviceInfo.sdkApiVersion;
      if (apiVersion > 0) {
        this.sdkApiVersion = String(apiVersion);
      }
    } catch (_error) {}
  }

  private openUrl(url: string): void {
    const context = uiContextManager.getFullAbilityContext();
    if (!context) {
      logger.error(TAG, 'openUrl failed: context not found.');
      return;
    }
    try {
      const want: Want = {
        action: 'ohos.want.action.viewData',
        uri: url
      };
      context.startAbility(want).catch((_err: Error): void => {
        logger.error(TAG, `startAbility failed for url: ${url}`);
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `openUrl failed: ${message}`);
    }
  }

  build() {
    Column({ space: 0 }) {
      this.buildTitleBar()
      List({ space: 12 }) {
        ListItem() { this.buildAppHeader() }
        ListItem() { this.buildBasicCard() }
        ListItem() { this.buildTechCard() }
        ListItem() { this.buildModulesCard() }
        ListItem() { this.buildOpenSourceCard() }
        ListItem() { this.buildDeveloperCard() }
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .padding({ top: 12, bottom: 16, left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .backgroundEffect(new NGFHdsBackgroundEffectOptions(40, 1.26, 1.06, $r('app.color.glass_bg_effect')))
    .visualEffect(AboutSheetGlassFactory.buildSheetSurfaceEffect())
  }

  @Builder
  private buildTitleBar(): void {
    Row() {
      Text($r('app.string.about_sheet_title'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
    }
    .width('100%')
    .padding({ top: 12, bottom: 4 })
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private buildAppHeader(): void {
    Column({ space: 12 }) {
      Image($r('app.media.startIcon'))
        .width(72)
        .height(72)
        .borderRadius(18)
        .shadow({ radius: 16, color: $r('app.color.card_shadow_light'), offsetX: 0, offsetY: 8 })

      Text(this.appName)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Text(`v${this.versionName} (${this.versionCode})`)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))

      Text(this.bundleName)
        .fontSize(12)
        .fontColor($r('app.color.text_glass_hint'))
        .opacity(0.7)
    }
    .width('100%')
    .padding({ top: 20, bottom: 20 })
    .alignItems(HorizontalAlign.Center)
    .backgroundEffect(new NGFHdsBackgroundEffectOptions(28, 1.2, 1.04, $r('app.color.glass_bg_effect_light')))
    .borderRadius(20)
    .border({ width: 1, color: $r('app.color.glass_border_light') })
    .shadow({ radius: 10, color: $r('app.color.card_shadow_light'), offsetX: 0, offsetY: 4 })
    .visualEffect(AboutSheetGlassFactory.buildCardEffect())
  }

  @Builder
  private buildBasicCard(): void {
    Column({ space: 10 }) {
      Text($r('app.string.about_section_basic'))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_glass_label'))
        .width('100%')

      this.buildInfoRow($r('app.string.about_app_name'), this.appName)
      this.buildDivider()
      this.buildInfoRow($r('app.string.about_bundle_name'), this.bundleName)
      this.buildDivider()
      this.buildInfoRow($r('app.string.about_version_name'), this.versionName)
      this.buildDivider()
      this.buildInfoRow($r('app.string.about_version_code'), String(this.versionCode))
      this.buildDivider()
      this.buildInfoRow($r('app.string.about_build_version'), this.buildVersion)
    }
    .width('100%')
    .padding(14)
    .backgroundEffect(new NGFHdsBackgroundEffectOptions(22, 1.16, 1.03, $r('app.color.glass_bg_effect_light')))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.glass_border_subtle') })
    .shadow({ radius: 8, color: $r('app.color.card_shadow_light'), offsetX: 0, offsetY: 3 })
    .visualEffect(AboutSheetGlassFactory.buildCardEffect())
  }

  @Builder
  private buildTechCard(): void {
    Column({ space: 10 }) {
      Text($r('app.string.about_section_tech'))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_glass_label'))
        .width('100%')

      this.buildInfoRow($r('app.string.about_sdk_api'), this.sdkApiVersion)
      this.buildDivider()
      this.buildInfoRow($r('app.string.about_device_model'), this.deviceModel.length > 0 ? `${this.brand} ${this.deviceModel}` : '-')
      this.buildDivider()
      this.buildInfoRow($r('app.string.about_os_version'), this.osFullName.length > 0 ? this.osFullName : '-')
    }
    .width('100%')
    .padding(14)
    .backgroundEffect(new NGFHdsBackgroundEffectOptions(22, 1.16, 1.03, $r('app.color.glass_bg_effect_light')))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.glass_border_subtle') })
    .shadow({ radius: 8, color: $r('app.color.card_shadow_light'), offsetX: 0, offsetY: 3 })
    .visualEffect(AboutSheetGlassFactory.buildCardEffect())
  }

  @Builder
  private buildModulesCard(): void {
    Column({ space: 10 }) {
      Text($r('app.string.about_section_modules'))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_glass_label'))
        .width('100%')

      Column({ space: 8 }) {
        Row({ space: 8 }) {
          this.buildModuleChip(this.modules[0])
          this.buildModuleChip(this.modules[1])
          this.buildModuleChip(this.modules[2])
        }
        .width('100%')
        Row({ space: 8 }) {
          this.buildModuleChip(this.modules[3])
          this.buildModuleChip(this.modules[4])
          this.buildModuleChip(this.modules[5])
        }
        .width('100%')
        Row({ space: 8 }) {
          this.buildModuleChip(this.modules[6])
          this.buildModuleChip(this.modules[7])
          this.buildModuleChip(this.modules[8])
        }
        .width('100%')
        Row({ space: 8 }) {
          this.buildModuleChip(this.modules[9])
        }
        .width('100%')
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundEffect(new NGFHdsBackgroundEffectOptions(22, 1.16, 1.03, $r('app.color.glass_bg_effect_light')))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.glass_border_subtle') })
    .shadow({ radius: 8, color: $r('app.color.card_shadow_light'), offsetX: 0, offsetY: 3 })
    .visualEffect(AboutSheetGlassFactory.buildCardEffect())
  }

  @Builder
  private buildOpenSourceCard(): void {
    Column({ space: 10 }) {
      Text($r('app.string.about_section_opensource'))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_glass_label'))
        .width('100%')

      this.buildLinkRow('GitHub', 'https://github.com/DaLongZhuaZi/NGF')
      this.buildDivider()
      this.buildLinkRow('GitCode', 'https://gitcode.com/dlzz/NGF')
    }
    .width('100%')
    .padding(14)
    .backgroundEffect(new NGFHdsBackgroundEffectOptions(22, 1.16, 1.03, $r('app.color.glass_bg_effect_light')))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.glass_border_subtle') })
    .shadow({ radius: 8, color: $r('app.color.card_shadow_light'), offsetX: 0, offsetY: 3 })
    .visualEffect(AboutSheetGlassFactory.buildCardEffect())
  }

  @Builder
  private buildDeveloperCard(): void {
    Column({ space: 10 }) {
      Text($r('app.string.about_section_developer'))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_glass_label'))
        .width('100%')

      this.buildInfoRow($r('app.string.about_vendor'), this.vendor)
      this.buildDivider()
      this.buildInfoRow($r('app.string.about_copyright'), $r('app.string.about_copyright_text'))
    }
    .width('100%')
    .padding(14)
    .backgroundEffect(new NGFHdsBackgroundEffectOptions(22, 1.16, 1.03, $r('app.color.glass_bg_effect_light')))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.glass_border_subtle') })
    .shadow({ radius: 8, color: $r('app.color.card_shadow_light'), offsetX: 0, offsetY: 3 })
    .visualEffect(AboutSheetGlassFactory.buildCardEffect())
  }

  @Builder
  private buildModuleChip(item: ModuleStatus): void {
    Row({ space: 6 }) {
      Circle()
        .width(6)
        .height(6)
        .fill(item.active ? $r('app.color.button_primary') : $r('app.color.text_secondary'))
        .opacity(item.active ? 1.0 : 0.4)
      Text(item.label)
        .fontSize(12)
        .fontColor(item.active ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
        .opacity(item.active ? 1.0 : 0.5)
    }
    .padding({ top: 6, bottom: 6, left: 10, right: 10 })
    .backgroundEffect(new NGFHdsBackgroundEffectOptions(14, 1.1, 1.02, $r('app.color.glass_bg_effect_light')))
    .borderRadius(12)
    .border({ width: 0.5, color: item.active ? $r('app.color.glass_border_light') : $r('app.color.glass_divider') })
    .layoutWeight(1)
  }

  @Builder
  private buildLinkRow(label: string, url: string): void {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
      Text(url)
        .fontSize(12)
        .fontColor($r('app.color.button_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(2)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .gesture(
      TapGesture()
        .onAction((_event: GestureEvent): void => {
          this.openUrl(url);
        })
    )
  }

  @Builder
  private buildInfoRow(label: ResourceStr, value: ResourceStr): void {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
      Text(value)
        .fontSize(13)
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Medium)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
  }

  @Builder
  private buildDivider(): void {
    Divider()
      .color($r('app.color.glass_divider'))
      .opacity(0.5)
  }
}
