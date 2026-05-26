import { NGFHdsDemoRouteName } from './HdsDemoRoutes';

@Component
export struct NGFCapabilitiesTabContent {
  onActionTap: (actionKey: string, label: ResourceStr) => void = () => {};

  build() {
    Column({ space: 12 }) {
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
        SymbolGlyph($r(icon))
          .fontSize(28)
          .fontColor([iconColor])
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.background_primary'))
      .borderRadius(14)
      .margin({ right: 14 })

      Column({ space: 4 }) {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_body'))
        Text(desc)
          .fontSize(13)
          .fontColor($r('app.color.text_tertiary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(20)
        .fontColor([$r('app.color.text_tertiary')])
        .margin({ left: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.card_border') })
    .shadow({ radius: 10, color: $r('app.color.card_shadow_demo'), offsetX: 0, offsetY: 4 })
    .onClick(() => {
      this.onActionTap(routeName, title);
    })
  }
}
