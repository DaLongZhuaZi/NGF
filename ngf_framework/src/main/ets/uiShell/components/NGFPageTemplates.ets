/**
 * 通用 HDS 页面骨架模板组件
 *
 * 提供三种开箱即用的页面骨架：
 *  - NGFListPageTemplate   — 列表页（可配置 header + 滚动区域 + item slot）
 *  - NGFDetailPageTemplate — 详情页（KeyValue 双列布局）
 *  - NGFFormPageTemplate   — 表单页（字段 slot + Submit 按钮）
 */

import {
  NGFImmersiveTopChromePresetFactory,
  NGFImmersiveTopChromeSpec,
  NGFImmersiveTopChromeUnderlay
} from './NGFImmersiveTopChrome';

// ──────────────────────────────────────────────────────────────────
// 通用 KeyValue 数据类型
// ──────────────────────────────────────────────────────────────────

export class NGFKeyValueEntry {
  readonly label: ResourceStr;
  readonly value: string;

  constructor(label: ResourceStr, value: string) {
    this.label = label;
    this.value = value;
  }
}

// ──────────────────────────────────────────────────────────────────
// NGFListPageTemplate — 列表页骨架
// ──────────────────────────────────────────────────────────────────

@Component
export struct NGFListPageTemplate {
  /** 顶部沉浸底板色彩配置 */
  spec: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
    '#07111F', '#0C2540', '#08121E', '#3B82F6D8', '#93C5FDD8', 160, 88
  );
  /** 页面标题 */
  title: ResourceStr = '';
  /** 副标题/描述 */
  subtitle: ResourceStr = '';
  /** 列表数据源（每项为 string） */
  items: Array<string> = [];
  /** 列表项点击回调 */
  onItemTap: (item: string, index: number) => void = (_i: string, _idx: number): void => {};
  /** 空列表提示文字 */
  emptyHint: ResourceStr = '暂无数据';
  @Builder defaultBuilder() {}

  /** 顶部自定义头部区域（标题下方、列表上方） */
  @BuilderParam headerBuilder: () => void = this.defaultBuilder;
  /** 自定义列表内容区域，若提供则替代默认 items 列表 */
  @BuilderParam contentBuilder: () => void = this.defaultBuilder;
  /** 底部自定义区域（列表下方） */
  @BuilderParam footerBuilder: () => void = this.defaultBuilder;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      NGFImmersiveTopChromeUnderlay({ spec: this.spec })

      Scroll() {
        Column({ space: 10 }) {
          // 标题卡片
          Column({ space: 6 }) {
            Text(this.title)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            if ((typeof this.subtitle === 'string' ? this.subtitle : '').length > 0) {
              Text(this.subtitle)
                .fontSize(13)
                .fontColor($r('app.color.text_tertiary'))
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // 自定义头部
          this.headerBuilder()

          // 列表内容：优先使用 contentBuilder，否则使用默认 items
          if (this.items.length === 0) {
            Text(this.emptyHint)
              .fontSize(14)
              .fontColor($r('app.color.text_muted'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 40, bottom: 40 })
          } else {
            Column({ space: 6 }) {
              ForEach(this.items, (item: string, index: number) => {
                Row({ space: 12 }) {
                  Text(item)
                    .fontSize(14)
                    .fontColor($r('app.color.text_body'))
                    .layoutWeight(1)
                  SymbolGlyph($r('sys.symbol.chevron_right'))
                    .fontSize(16)
                    .fontColor([$r('app.color.text_muted')])
                }
                .width('100%')
                .padding({ left: 14, right: 14, top: 12, bottom: 12 })
                .backgroundColor($r('app.color.panel_background'))
                .borderRadius(12)
                .border({ width: 1, color: $r('app.color.card_border') })
                .onClick((): void => {
                  this.onItemTap(item, index);
                })
              }, (item: string, index: number): string => `list_${index}_${item}`)
            }
            .width('100%')
          }

          // 自定义列表内容（与 items 并存，外部可只传 contentBuilder 不传 items）
          this.contentBuilder()

          // 底部自定义区域
          this.footerBuilder()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: this.spec.metrics.contentTopInset, bottom: 36 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .width('100%')
    .height('100%')
  }
}

// ──────────────────────────────────────────────────────────────────
// NGFDetailPageTemplate — 详情页骨架（KeyValue 双列布局）
// ──────────────────────────────────────────────────────────────────

@Component
export struct NGFDetailPageTemplate {
  spec: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
    '#0A0F1A', '#142040', '#08101E', '#6366F1D8', '#A5B4FCD8', 160, 88
  );
  title: ResourceStr = '';
  subtitle: ResourceStr = '';
  entries: Array<NGFKeyValueEntry> = [];
  @Builder defaultBuilder() {}

  /** 底部操作区 Slot */
  @BuilderParam footerSlot: () => void = this.defaultBuilder;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      NGFImmersiveTopChromeUnderlay({ spec: this.spec })

      Scroll() {
        Column({ space: 12 }) {
          // 标题区
          Column({ space: 6 }) {
            Text(this.title)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            if ((typeof this.subtitle === 'string' ? this.subtitle : '').length > 0) {
              Text(this.subtitle)
                .fontSize(13)
                .fontColor($r('app.color.text_tertiary'))
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // KeyValue 列表
          Column({ space: 1 }) {
            ForEach(this.entries, (entry: NGFKeyValueEntry, index: number) => {
              Row({ space: 12 }) {
                Text(entry.label)
                  .fontSize(13)
                  .fontColor($r('app.color.text_tertiary'))
                  .width('38%')
                Text(entry.value)
                  .fontSize(13)
                  .fontColor($r('app.color.text_body'))
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .maxLines(2)
              }
              .width('100%')
              .padding({ left: 14, right: 14, top: 12, bottom: 12 })
              .backgroundColor(index % 2 === 0
                ? $r('app.color.panel_background')
                : $r('app.color.background_surface'))
            }, (entry: NGFKeyValueEntry, index: number): string => `kv_${index}`)
          }
          .width('100%')
          .borderRadius(14)
          .border({ width: 1, color: $r('app.color.card_border') })
          .clip(true)

          // 底部操作区
          this.footerSlot()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: this.spec.metrics.contentTopInset, bottom: 36 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .width('100%')
    .height('100%')
  }
}

// ──────────────────────────────────────────────────────────────────
// NGFFormPageTemplate — 表单页骨架
// ──────────────────────────────────────────────────────────────────

@Component
export struct NGFFormPageTemplate {
  spec: NGFImmersiveTopChromeSpec = NGFImmersiveTopChromePresetFactory.build(
    '#0F0A1A', '#1E1145', '#0A0618', '#818CF8D8', '#C7D2FED8', 160, 88
  );
  title: ResourceStr = '';
  subtitle: ResourceStr = '';
  submitLabel: ResourceStr = '提交';
  submitEnabled: boolean = true;
  onSubmit: () => void = (): void => {};
  @Builder defaultBuilder() {}

  /** 表单字段 Slot */
  @BuilderParam formFields: () => void = this.defaultBuilder;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      NGFImmersiveTopChromeUnderlay({ spec: this.spec })

      Scroll() {
        Column({ space: 14 }) {
          // 标题区
          Column({ space: 6 }) {
            Text(this.title)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            if ((typeof this.subtitle === 'string' ? this.subtitle : '').length > 0) {
              Text(this.subtitle)
                .fontSize(13)
                .fontColor($r('app.color.text_tertiary'))
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // 表单内容区
          Column({ space: 12 }) {
            this.formFields()
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.panel_background'))
          .borderRadius(16)
          .border({ width: 1, color: $r('app.color.card_border') })

          // Submit 按钮
          Button(this.submitLabel)
            .width('100%')
            .height(46)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .borderRadius(14)
            .backgroundColor(this.submitEnabled
              ? $r('app.color.button_primary')
              : $r('app.color.background_surface'))
            .fontColor(this.submitEnabled
              ? $r('app.color.panel_background')
              : $r('app.color.text_muted'))
            .enabled(this.submitEnabled)
            .onClick((): void => {
              this.onSubmit();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: this.spec.metrics.contentTopInset, bottom: 36 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .width('100%')
    .height('100%')
  }
}
