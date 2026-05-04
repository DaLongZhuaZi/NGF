export class NGFHdsTabRouteName {
  static readonly FRAMEWORK: string = 'tab.framework';
  static readonly SHOWCASE: string = 'tab.showcase';
  static readonly DEVICE: string = 'tab.device';
  static readonly SETTINGS: string = 'tab.settings';
}

export class NGFHdsTabConfig {
  readonly index: number;
  readonly title: string;
  readonly routeName: string;

  constructor(index: number, title: string, routeName: string) {
    this.index = index;
    this.title = title;
    this.routeName = routeName;
  }
}

export const NGF_HDS_TAB_CONFIGS: Array<NGFHdsTabConfig> = [
  new NGFHdsTabConfig(0, '框架', NGFHdsTabRouteName.FRAMEWORK),
  new NGFHdsTabConfig(1, '展示', NGFHdsTabRouteName.SHOWCASE),
  new NGFHdsTabConfig(2, '设备', NGFHdsTabRouteName.DEVICE),
  new NGFHdsTabConfig(3, '设置', NGFHdsTabRouteName.SETTINGS)
];
