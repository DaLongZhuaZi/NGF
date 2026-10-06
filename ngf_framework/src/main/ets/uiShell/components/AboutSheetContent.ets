import { NGFAccessibilityLifecycleBinding, NGFAccessibilityBindingListener } from '../utils/NGFAccessibilityLifecycleBinding';
import { NGFInclusiveDesignResolved } from '../../deviceAwareness/contracts/IAccessibilityManager';
import { NGFA11yTextScale, a11yTouchTarget, resolveA11yTextScale, resolveA11yTextScaleForCurrent } from '../utils/NGFA11yTextScale';
import { ngfAccessibilityFacade } from '../../deviceAwareness/facades/AccessibilityFacade';
import { bundleManager, common, Want } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { uiContextManager } from '../../platformOhos/UIContextManager';
import { logger } from '../../utils/Logger';
import { ngfVisualEffectsFacade } from '../../deviceAwareness/facades/VisualEffectsFacade';
import { NGFMaterialSurfaceTokens } from './NGFMaterialSurfaceTokens';

const TAG: string = 'AboutSheetContent';

interface ModuleStatus {
  label: Resource;
  active: boolean;
}

/**
 * `buildLinkRow` 的参数。
 *
 * ⚠️ 必须是**对象**：ArkUI 的 `@Builder` 只有按引用传递参数时才建立状态依赖，
 * 用位置参数传基本类型会让内部文本停在首次构建的结果（项目规则 **PR-016**）。
 */
export interface NGFLinkRowParams {
  label: string;
  url: string;
}

/** `buildInfoRow` 的参数，理由同上 */
export interface NGFInfoRowParams {
  label: ResourceStr;
  value: ResourceStr;
}

@Component
export struct AboutSheetContent {
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


  @State private appName: string = 'NGF';
  @State private bundleName: string = 'com.dlzz.ngf';
  @State private versionName: string = '1.0.0';
  @State private versionCode: number = 1000000;
  @State private buildVersion: string = '1';
  @State private sdkApiVersion: string = '26';
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
    this.attachA11yBinding();
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
        logger.error(TAG, 'startAbility failed for url: ' + url);
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, 'openUrl failed: ' + message);
    }
  }

  aboutToDisappear(): void {
    // 与 aboutToAppear 的 attach 成对：不取消可能在生命周期结束后回调导致崩溃
    this.detachA11yBinding();
  }

  build() {
    Column({ space: this.a11yScale.paragraphSpacing(0, 18) }) {
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
  }

  @Builder
  private buildTitleBar(): void {
    Row() {
      Text($r('app.string.about_sheet_title'))
        .fontSize(this.a11yScale.font(18))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(18)))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
    }
    .width('100%')
    .padding({ top: 12, bottom: 4 })
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private buildAppHeader(): void {
    Column({ space: this.a11yScale.paragraphSpacing(12, 18) }) {
      // 应用图标：应用名紧随其后
      Image($r('app.media.startIcon'))
        .width(72)
        .height(72)
        .borderRadius(18)
        .shadow({ radius: 16, color: $r('app.color.card_shadow_light'), offsetX: 0, offsetY: 8 })
        .accessibilityLevel('no')

      Text(this.appName)
        .fontSize(this.a11yScale.font(24))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(24)))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Text('v' + this.versionName + ' (' + this.versionCode + ')')
        .fontSize(this.a11yScale.font(14))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
        .fontColor($r('app.color.text_secondary'))

      Text(this.bundleName)
        .fontSize(this.a11yScale.font(12))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
        .fontColor($r('app.color.text_secondary'))
        .opacity(0.7)
    }
    .width('100%')
    .padding({ top: 20, bottom: 20 })
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.Transparent)
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwareProminentBackgroundEffect())
    .borderRadius(20)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.glass_border_light'))
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwareProminentShadow())
  }

  @Builder
  private buildBasicCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Text($r('app.string.about_section_basic'))
        .fontSize(this.a11yScale.font(14))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      this.buildInfoRow({ label: $r('app.string.about_app_name'), value: this.appName })
      this.buildDivider()
      this.buildInfoRow({ label: $r('app.string.about_bundle_name'), value: this.bundleName })
      this.buildDivider()
      this.buildInfoRow({ label: $r('app.string.about_version_name'), value: this.versionName })
      this.buildDivider()
      this.buildInfoRow({ label: $r('app.string.about_version_code'), value: String(this.versionCode) })
      this.buildDivider()
      this.buildInfoRow({ label: $r('app.string.about_build_version'), value: this.buildVersion })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.Transparent)
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect())
    .borderRadius(16)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.glass_border_subtle'))
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow())
  }

  @Builder
  private buildTechCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Text($r('app.string.about_section_tech'))
        .fontSize(this.a11yScale.font(14))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      this.buildInfoRow({ label: $r('app.string.about_sdk_api'), value: this.sdkApiVersion })
      this.buildDivider()
      this.buildInfoRow({ label: $r('app.string.about_device_model'), value: this.deviceModel.length > 0 ? this.brand + ' ' + this.deviceModel : '-' })
      this.buildDivider()
      this.buildInfoRow({ label: $r('app.string.about_os_version'), value: this.osFullName.length > 0 ? this.osFullName : '-' })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.Transparent)
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect())
    .borderRadius(16)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.glass_border_subtle'))
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow())
  }

  @Builder
  private buildModulesCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Text($r('app.string.about_section_modules'))
        .fontSize(this.a11yScale.font(14))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
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
    .backgroundColor(Color.Transparent)
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect())
    .borderRadius(16)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.glass_border_subtle'))
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow())
  }

  @Builder
  private buildOpenSourceCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Text($r('app.string.about_section_opensource'))
        .fontSize(this.a11yScale.font(14))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      this.buildLinkRow({ label: 'GitHub', url: 'https://github.com/DaLongZhuaZi/NGF' })
      this.buildDivider()
      this.buildLinkRow({ label: 'GitCode', url: 'https://gitcode.com/dlzz/NGF' })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.Transparent)
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect())
    .borderRadius(16)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.glass_border_subtle'))
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow())
  }

  @Builder
  private buildDeveloperCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(10, 18) }) {
      Text($r('app.string.about_section_developer'))
        .fontSize(this.a11yScale.font(14))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      this.buildInfoRow({ label: $r('app.string.about_vendor'), value: this.vendor })
      this.buildDivider()
      this.buildInfoRow({ label: $r('app.string.about_copyright'), value: $r('app.string.about_copyright_text') })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.Transparent)
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect())
    .borderRadius(16)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(1),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor($r('app.color.glass_border_subtle'))
    })
    .shadow(NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow())
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
        .fontSize(this.a11yScale.font(12))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
        .fontColor(item.active ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
        .opacity(item.active ? 1.0 : 0.5)
    }
    .padding({ top: 6, bottom: 6, left: 10, right: 10 })
    .backgroundColor(Color.Transparent)
    .backgroundEffect(NGFMaterialSurfaceTokens.buildMaterialAwareControlBackgroundEffect())
    .borderRadius(12)
    .border({
      width: NGFMaterialSurfaceTokens.buildMaterialAwareBorderWidth(0.5),
      color: NGFMaterialSurfaceTokens.buildMaterialAwareBorderColor(item.active ? $r('app.color.glass_border_light') : $r('app.color.glass_divider'))
    })
    .layoutWeight(1)
  }

  @Builder
  private buildLinkRow(params: NGFLinkRowParams): void {
    Row() {
      Text(params.label)
        .fontSize(this.a11yScale.font(13))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
      Text(params.url)
        .fontSize(this.a11yScale.font(12))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(12)))
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(2)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .gesture(
      TapGesture()
        .onAction((_event: GestureEvent): void => {
          this.openUrl(params.url);
        })
    )
    // 无障碍分组：不分组时读屏把「链接名」与「URL」当成两个孤立节点。
    // 这里没有 Button 子节点（手势挂在外层 Row 上），分组不会破坏交互。
    .accessibilityGroup(true)
  }

  @Builder
  private buildInfoRow(params: NGFInfoRowParams): void {
    Row() {
      Text(params.label)
        .fontSize(this.a11yScale.font(13))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
      Text(params.value)
        .fontSize(this.a11yScale.font(13))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Medium)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    // 无障碍分组（官方「使用建议」：对复杂布局减少冗余播报）。
    // 不分组时读屏把「标签」与「数值」当成**两个独立节点**，
    // 用户会听到一个孤立的数值，不知道它属于哪个标签。
    .accessibilityGroup(true)
  }

  @Builder
  private buildDivider(): void {
    Divider()
      .color($r('app.color.glass_divider'))
      .opacity(0.5)
  }
}
