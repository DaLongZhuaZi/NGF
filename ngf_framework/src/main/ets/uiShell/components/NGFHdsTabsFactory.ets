import {
  NGFAccessibilityBindingListener,
  NGFAccessibilityLifecycleBinding
} from '../utils/NGFAccessibilityLifecycleBinding';
import { NGFInclusiveDesignResolved } from '../../deviceAwareness/contracts/IAccessibilityManager';
import { NGFA11yTextScale, resolveA11yTextScale, resolveA11yTextScaleForCurrent } from '../utils/NGFA11yTextScale';
import { ngfAccessibilityFacade } from '../../deviceAwareness/facades/AccessibilityFacade';
import { hdsMaterial, HdsTabs, HdsTabsController, HdsTabsFloatingStyle, SystemMaterialParams } from '@kit.UIDesignKit';

class NGFHdsTabsSystemMaterialParams implements SystemMaterialParams {
  materialType?: hdsMaterial.MaterialType;
  materialLevel?: hdsMaterial.MaterialLevel;

  constructor(materialLevel: hdsMaterial.MaterialLevel) {
    this.materialType = hdsMaterial.MaterialType.IMMERSIVE;
    this.materialLevel = materialLevel;
  }
}

class NGFHdsTabsFloatingStyle implements HdsTabsFloatingStyle {
  adaptToHandedness?: boolean;
  systemMaterialEffect?: SystemMaterialParams;
  thermoCtrl?: boolean;
  barOpacity?: number;

  constructor(materialLevel: hdsMaterial.MaterialLevel) {
    this.adaptToHandedness = true;
    this.systemMaterialEffect = new NGFHdsTabsSystemMaterialParams(materialLevel);
    this.thermoCtrl = true;
    this.barOpacity = 0.92;
  }
}

export class NGFHdsTabItem {
  readonly title: string;

  constructor(title: string) {
    this.title = title;
  }
}

@Component
export struct NGFHdsImmersiveTabs {
  /** 适老呈现层：字号经缩放器取；普通档原样返回 */
  @State private a11yScale: NGFA11yTextScale = resolveA11yTextScaleForCurrent();
  private a11yBinding: NGFAccessibilityLifecycleBinding | null = null;

  aboutToAppear(): void {
    if (this.a11yBinding === null) {
      const listener: NGFAccessibilityBindingListener = {
        onInclusiveDesignChanged: (resolved: NGFInclusiveDesignResolved): void => {
          this.a11yScale = resolveA11yTextScaleForCurrent();
        }
      };
      this.a11yBinding = new NGFAccessibilityLifecycleBinding(listener);
      this.a11yBinding.attach();
    }
  }

  aboutToDisappear(): void {
    const binding: NGFAccessibilityLifecycleBinding | null = this.a11yBinding;
    if (binding !== null) {
      binding.detach();
      this.a11yBinding = null;
    }
  }


  private controller: HdsTabsController = new HdsTabsController();
  private items: Array<NGFHdsTabItem> = [];
  @Prop private selectedIndex: number = 0;
  @StorageProp('ngf_visual_effects_effective_material_level')
  private effectiveMaterialLevel: number = hdsMaterial.MaterialLevel.ADAPTIVE;
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
      }, (item: NGFHdsTabItem, index: number): string => index + '_' + item.title)
    }
    .barPosition(BarPosition.End)
    .barMode(BarMode.Fixed)
    .barOverlap(true)
    .barFloatingStyle(new NGFHdsTabsFloatingStyle(this.resolveMaterialLevel()))
    .onChange((index: number): void => {
      this.onChangeCallback(index);
    })
  }

  private resolveMaterialLevel(): hdsMaterial.MaterialLevel {
    switch (this.effectiveMaterialLevel) {
      case hdsMaterial.MaterialLevel.EXQUISITE:
        return hdsMaterial.MaterialLevel.EXQUISITE;
      case hdsMaterial.MaterialLevel.GENTLE:
        return hdsMaterial.MaterialLevel.GENTLE;
      case hdsMaterial.MaterialLevel.SMOOTH:
        return hdsMaterial.MaterialLevel.SMOOTH;
      default:
        return hdsMaterial.MaterialLevel.ADAPTIVE;
    }
  }

  @Builder
  private buildTabBarItem(item: NGFHdsTabItem, isSelected: boolean): void {
    Column({ space: this.a11yScale.paragraphSpacing(4, 18) }) {
      Text(item.title)
        .fontSize(this.a11yScale.font(11))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(11)))
        .fontColor(isSelected ? $r('app.color.button_primary') : $r('app.color.text_secondary'))
        .fontWeight(isSelected ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ top: 8, bottom: 8 })
  }
}
