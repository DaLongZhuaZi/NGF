import { hdsMaterial, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';

export class NGFHdsTabItem {
  readonly title: string;

  constructor(title: string) {
    this.title = title;
  }
}

@Component
export struct NGFHdsImmersiveTabs {
  private controller: HdsTabsController = new HdsTabsController();
  private items: Array<NGFHdsTabItem> = [];
  @Prop private selectedIndex: number = 0;
  private onChangeCallback: (index: number) => void = (): void => {};
  @Builder defaultBuilder(index: number) {}
  @BuilderParam contentBuilder: (index: number) => void = this.defaultBuilder;

  build(): void {
    HdsTabs({ controller: this.controller }) {
      ForEach(this.items, (item: NGFHdsTabItem, index: number): void => {
        TabContent() {
          this.contentBuilder(index);
        }
        .tabBar(this.buildTabBarItem(item, this.selectedIndex === index))
      }, (item: NGFHdsTabItem, index: number): string => `${index}_${item.title}`)
    }
    .barPosition(BarPosition.End)
    .barMode(BarMode.Fixed)
    .barOverlap(true)
    .barFloatingStyle({
      adaptToHandedness: true,
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.IMMERSIVE,
        materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
      },
      thermoCtrl: true,
      barOpacity: 0.92
    })
    .onChange((index: number): void => {
      this.onChangeCallback(index);
    })
  }

  @Builder
  private buildTabBarItem(item: NGFHdsTabItem, isSelected: boolean): void {
    Column({ space: 4 }) {
      Text(item.title)
        .fontSize(11)
        .fontColor(isSelected ? $r('app.color.button_primary') : $r('app.color.text_secondary'))
        .fontWeight(isSelected ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 8, bottom: 8 })
  }
}
