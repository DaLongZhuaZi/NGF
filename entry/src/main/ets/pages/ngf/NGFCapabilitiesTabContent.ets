import {
  NGFAccessibilityBindingListener,
  NGFAccessibilityLifecycleBinding,
  NGFAccessibilityStateSnapshot,
  NGFA11yTextScale,
  NGFInclusiveDesignResolved,
  ngfAccessibilityFacade,
  resolveA11yTextScaleForCurrent
} from 'ngf_framework';
import { NGFHdsDemoRouteName } from './HdsDemoRoutes';
import { NGFMaterialSurfaceTokens } from 'ngf_framework';
import { ngfVisualEffectsFacade } from 'ngf_framework';

@Component
export struct NGFCapabilitiesTabContent {
  /**
   * 适老呈现层（.rules/skill-elderly-ui.md）：字号 / 行高一律经缩放器取，
   * 普通档原样返回，适老档抬到附件2 §1.1（≥18）与 §1.2（行距 ≥1.3 倍）。
   */
  @State private a11yScale: NGFA11yTextScale = resolveA11yTextScaleForCurrent();
  private a11yBinding: NGFAccessibilityLifecycleBinding | null = null;

  /** 订阅平台策略变化；与 aboutToDisappear 的 detach 严格成对 */
  private attachA11yBinding(): void {
    if (this.a11yBinding !== null) {
      return;
    }
    const listener: NGFAccessibilityBindingListener = {
      onInclusiveDesignChanged: (resolved: NGFInclusiveDesignResolved): void => {
        this.a11yScale = resolveA11yTextScaleForCurrent();
      },
      onAccessibilityStateChanged: (snapshot: NGFAccessibilityStateSnapshot): void => {
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

  aboutToAppear(): void {
    this.attachA11yBinding();
  }

  aboutToDisappear(): void {
    this.detachA11yBinding();
  }


  onActionTap: (actionKey: string, label: ResourceStr) => void = () => {};
  @StorageProp('ngf_visual_effects_should_use_system_material_surface') private useSysMat: boolean = true;

  build() {
    Column({ space: this.a11yScale.groupSpacing(12) }) {
      this.buildCapabilityCard(
        $r('app.string.card_network_title'),
        $r('app.string.card_network_desc'),
        'sys.symbol.ohos_wifi',
        $r('app.color.tag_blue'),
        NGFHdsDemoRouteName.CAPABILITY_NETWORK
      )
      this.buildCapabilityCard(
        $r('app.string.card_rdb_title'),
        $r('app.string.card_rdb_desc'),
        'sys.symbol.doc_text',
        $r('app.color.tag_green'),
        NGFHdsDemoRouteName.CAPABILITY_RDB
      )
      this.buildCapabilityCard(
        $r('app.string.card_web_title'),
        $r('app.string.card_web_desc'),
        'sys.symbol.globe_and_keyboard',
        $r('app.color.tag_cyan'),
        NGFHdsDemoRouteName.CAPABILITY_WEB_BRIDGE
      )
      this.buildCapabilityCard(
        $r('app.string.card_security_title'),
        $r('app.string.card_security_desc'),
        'sys.symbol.security_shield',
        $r('app.color.tag_purple'),
        NGFHdsDemoRouteName.CAPABILITY_SECURITY
      )
      this.buildCapabilityCard(
        $r('app.string.card_hardware_title'),
        $r('app.string.card_hardware_desc'),
        'sys.symbol.location_up',
        $r('app.color.tag_amber'),
        NGFHdsDemoRouteName.CAPABILITY_HARDWARE
      )
      this.buildCapabilityCard(
        $r('app.string.card_media_title'),
        $r('app.string.card_media_desc'),
        'sys.symbol.ohos_photo',
        $r('app.color.tag_purple'),
        NGFHdsDemoRouteName.CAPABILITY_MEDIA
      )
    }
    .width('100%')
  }

  @Builder
  private buildCapabilityCard(title: ResourceStr, desc: ResourceStr, icon: string, iconColor: ResourceColor, routeName: string): void {
    Row() {
      Column() {
        // 装饰图标：卡片标题与描述已提供语义
        SymbolGlyph($r(icon))
          .fontSize(this.a11yScale.font(28))
          .fontColor([iconColor])
          .accessibilityLevel('no')
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(NGFMaterialSurfaceTokens.buildMaterialAwareSurfaceBackground($r('app.color.background_primary'), this.useSysMat))
      .borderRadius(14)
      .margin({ right: 14 })

      Column({ space: this.a11yScale.groupSpacing(4) }) {
        Text(title)
          .fontSize(this.a11yScale.font(16))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(16)))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_body'))
        Text(desc)
          .fontSize(this.a11yScale.font(13))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(13)))
          .fontColor($r('app.color.text_tertiary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 纯装饰箭头：卡片本身已有标题与描述文本，箭头不应单独成为无障碍焦点
      // （官方「使用建议」：对复杂布局减少冗余播报）
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(this.a11yScale.font(20))
        .fontColor([$r('app.color.text_tertiary')])
        .margin({ left: 8 })
        .accessibilityLevel('no')
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
    .onClick(() => {
      this.onActionTap(routeName, title);
    })
    // 无障碍分组（官方「使用建议」：对复杂布局减少冗余播报）。
    // 不分组时读屏把「标题」与「描述」当成**两个独立节点**，
    // 用户会听到一个孤立的描述，不知道它属于哪个功能。
    // 注意：卡片本身没有 Button 子节点（onClick 挂在外层 Row 上），分组不会破坏交互。
    .accessibilityGroup(true)
  }
}
