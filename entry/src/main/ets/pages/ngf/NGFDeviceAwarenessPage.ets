import { hdsMaterial } from '@kit.UIDesignKit';
import {
  NGFBreakpoint,
  NGFDeviceChangeListener,
  NGFDeviceInfo,
  NGFDeviceType,
  NGFFoldStatus,
  NGFHoldingAwarenessConfidence,
  NGFHoldingAwarenessListener,
  NGFHoldingAwarenessSide,
  NGFHoldingAwarenessSnapshot,
  NGFHoldingAwarenessSource,
  NGFHoldingUiAnchor,
  NGFScreenOrientation,
  NGFVisualEffectsMaterialMode,
  NGFVisualEffectsState,
  NGFVisualEffectsStateListener,
  ngfDeviceAdaptationFacade,
  ngfHoldingAwarenessFacade,
  ngfVisualEffectsFacade
} from '../../Framework/NGF/deviceAwareness/index';
import { logger } from '../../Framework/NGF/utils/Logger';

const TAG: string = 'NGFDeviceAwarenessPage';

@Component
struct NGFDeviceAwarenessStatusRow {
  @Prop label: string = '';
  @Prop value: string = '';

  build() {
    Row() {
      Text(this.label)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
      Text(this.value)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
  }
}

@Component
export struct NGFDeviceAwarenessPage {
  @State private preferredAnchor: NGFHoldingUiAnchor = NGFHoldingUiAnchor.RIGHT;
  @State private holdingSide: NGFHoldingAwarenessSide = NGFHoldingAwarenessSide.UNKNOWN;
  @State private holdingSource: NGFHoldingAwarenessSource = NGFHoldingAwarenessSource.DEFAULT;
  @State private holdingConfidence: NGFHoldingAwarenessConfidence = NGFHoldingAwarenessConfidence.FALLBACK;
  @State private holdingAvailable: boolean = false;
  @State private preciseSupported: boolean = false;
  @State private operatingHandSupported: boolean = true;
  @State private detectGestureGranted: boolean = false;
  @State private activityMotionGranted: boolean = false;
  @State private holdingUpdatedAt: number = 0;

  @State private deviceType: NGFDeviceType = NGFDeviceType.PHONE;
  @State private deviceOrientation: NGFScreenOrientation = NGFScreenOrientation.PORTRAIT;
  @State private deviceBreakpoint: NGFBreakpoint = NGFBreakpoint.XS;
  @State private deviceScreenWidth: number = 0;
  @State private deviceScreenHeight: number = 0;
  @State private isTablet: boolean = false;
  @State private isFoldable: boolean = false;
  @State private foldStatus: NGFFoldStatus = NGFFoldStatus.UNKNOWN;
  @State private isLandscape: boolean = false;
  @State private deviceUpdatedAt: number = 0;
  @State private deviceUpdateReason: string = 'initial';

  @State private materialMode: NGFVisualEffectsMaterialMode = NGFVisualEffectsMaterialMode.ADAPTIVE;
  @State private effectiveLevel: hdsMaterial.MaterialLevel = hdsMaterial.MaterialLevel.ADAPTIVE;
  @State private supportsImmersive: boolean = false;

  private listenersAttached: boolean = false;
  private readonly deviceChangeListener: NGFDeviceChangeListener = (info: NGFDeviceInfo): void => {
    this.applyDeviceInfo(info);
  };
  private readonly holdingChangeListener: NGFHoldingAwarenessListener = (snapshot: NGFHoldingAwarenessSnapshot): void => {
    this.applyHoldingSnapshot(snapshot);
  };
  private readonly visualEffectsListener: NGFVisualEffectsStateListener = (state: NGFVisualEffectsState): void => {
    this.applyVisualEffectsState(state);
  };

  aboutToAppear(): void {
    this.attachLiveStateListeners();
    this.applyDeviceInfo(ngfDeviceAdaptationFacade.getDeviceInfo());
    this.applyHoldingSnapshot(ngfHoldingAwarenessFacade.getSnapshot());
    this.applyVisualEffectsState(ngfVisualEffectsFacade.getState());
    logger.lifecycle(TAG, '设备感知页面出现，刷新设备与握持状态');
    ngfDeviceAdaptationFacade.refresh('device_awareness_page_appear');
    void ngfHoldingAwarenessFacade.resume();
  }

  aboutToDisappear(): void {
    this.detachLiveStateListeners();
  }

  build() {
    Column({ space: 12 }) {
      Column({ space: 4 }) {
        Text(`实时握持：${this.describeSide(this.holdingSide)} / ${this.describeConfidence(this.holdingConfidence)}`)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Text(`实时设备：${this.describeOrientation(this.deviceOrientation)} · ${this.formatVp(this.deviceScreenWidth)} x ${this.formatVp(this.deviceScreenHeight)} · ${this.describeUpdateReason(this.deviceUpdateReason)}`)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .padding(12)
      .backgroundColor($r('app.color.panel_background'))
      .borderRadius(16)
      .border({ width: 1, color: $r('app.color.panel_border') })

      this.buildHoldingCard()
      this.buildDeviceCard()
      this.buildVisualEffectsCard()
    }
    .width('100%')
    .padding(16)
  }

  @Builder
  private buildHoldingCard(): void {
    Column({ space: 8 }) {
      Text('握持感知')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      this.buildPreferredAnchorRow()
      this.buildHoldingSideRow()
      this.buildHoldingSourceRow()
      this.buildHoldingConfidenceRow()
      this.buildHoldingAvailableRow()
      this.buildPreciseSupportedRow()
      this.buildOperatingHandSupportedRow()
      this.buildDetectGestureRow()
      this.buildActivityMotionRow()
      this.buildHoldingUpdatedAtRow()
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildDeviceCard(): void {
    Column({ space: 8 }) {
      Text('设备信息')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      this.buildDeviceTypeRow()
      this.buildDeviceOrientationRow()
      this.buildDeviceBreakpointRow()
      this.buildDeviceWidthRow()
      this.buildDeviceHeightRow()
      this.buildIsTabletRow()
      this.buildIsFoldableRow()
      this.buildFoldStatusRow()
      this.buildIsLandscapeRow()
      this.buildDeviceUpdateReasonRow()
      this.buildDeviceUpdatedAtRow()
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildVisualEffectsCard(): void {
    Column({ space: 8 }) {
      Text('视觉效果')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      this.buildMaterialModeRow()
      this.buildMaterialLevelRow()
      this.buildSupportsImmersiveRow()
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildPreferredAnchorRow(): void {
    NGFDeviceAwarenessStatusRow({
      label: '推荐停靠',
      value: this.preferredAnchor === NGFHoldingUiAnchor.LEFT ? '左侧' : '右侧'
    })
  }

  @Builder
  private buildHoldingSideRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '握持侧', value: this.describeSide(this.holdingSide) })
  }

  @Builder
  private buildHoldingSourceRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '数据来源', value: this.describeSource(this.holdingSource) })
  }

  @Builder
  private buildHoldingConfidenceRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '置信度', value: this.describeConfidence(this.holdingConfidence) })
  }

  @Builder
  private buildHoldingAvailableRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '传感器可用', value: this.holdingAvailable ? '是' : '否' })
  }

  @Builder
  private buildPreciseSupportedRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '精确握姿支持', value: this.preciseSupported ? '是' : '否' })
  }

  @Builder
  private buildOperatingHandSupportedRow(): void {
    NGFDeviceAwarenessStatusRow({
      label: '操作手增强',
      value: this.operatingHandSupported ? '可用或可尝试' : '当前设备不支持'
    })
  }

  @Builder
  private buildDetectGestureRow(): void {
    NGFDeviceAwarenessStatusRow({ label: 'DETECT_GESTURE', value: this.detectGestureGranted ? '已授权' : '未授权' })
  }

  @Builder
  private buildActivityMotionRow(): void {
    NGFDeviceAwarenessStatusRow({ label: 'ACTIVITY_MOTION', value: this.activityMotionGranted ? '已授权' : '未授权' })
  }

  @Builder
  private buildHoldingUpdatedAtRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '握持刷新时间', value: this.formatUpdatedAt(this.holdingUpdatedAt) })
  }

  @Builder
  private buildDeviceTypeRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '设备类型', value: this.describeDeviceType(this.deviceType) })
  }

  @Builder
  private buildDeviceOrientationRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '屏幕方向', value: this.describeOrientation(this.deviceOrientation) })
  }

  @Builder
  private buildDeviceBreakpointRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '断点', value: this.deviceBreakpoint.toUpperCase() })
  }

  @Builder
  private buildDeviceWidthRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '视口宽度', value: this.formatVp(this.deviceScreenWidth) })
  }

  @Builder
  private buildDeviceHeightRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '视口高度', value: this.formatVp(this.deviceScreenHeight) })
  }

  @Builder
  private buildIsTabletRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '平板类设备', value: this.isTablet ? '是' : '否' })
  }

  @Builder
  private buildIsFoldableRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '折叠屏', value: this.isFoldable ? '是' : '否' })
  }

  @Builder
  private buildFoldStatusRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '折叠状态', value: this.describeFoldStatus(this.foldStatus) })
  }

  @Builder
  private buildIsLandscapeRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '横屏', value: this.isLandscape ? '是' : '否' })
  }

  @Builder
  private buildDeviceUpdateReasonRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '刷新来源', value: this.describeUpdateReason(this.deviceUpdateReason) })
  }

  @Builder
  private buildDeviceUpdatedAtRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '刷新时间', value: this.formatUpdatedAt(this.deviceUpdatedAt) })
  }

  @Builder
  private buildMaterialModeRow(): void {
    NGFDeviceAwarenessStatusRow({
      label: '材质模式',
      value: this.materialMode === NGFVisualEffectsMaterialMode.ADAPTIVE ? '系统自适应' : '手动固定'
    })
  }

  @Builder
  private buildMaterialLevelRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '当前材质等级', value: this.describeMaterialLevel(this.effectiveLevel) })
  }

  @Builder
  private buildSupportsImmersiveRow(): void {
    NGFDeviceAwarenessStatusRow({ label: '支持沉浸式材质', value: this.supportsImmersive ? '是' : '否' })
  }

  private attachLiveStateListeners(): void {
    if (this.listenersAttached) {
      return;
    }
    ngfDeviceAdaptationFacade.addListener(this.deviceChangeListener);
    ngfHoldingAwarenessFacade.addListener(this.holdingChangeListener);
    ngfVisualEffectsFacade.addListener(this.visualEffectsListener);
    this.listenersAttached = true;
  }

  private detachLiveStateListeners(): void {
    if (!this.listenersAttached) {
      return;
    }
    ngfDeviceAdaptationFacade.removeListener(this.deviceChangeListener);
    ngfHoldingAwarenessFacade.removeListener(this.holdingChangeListener);
    ngfVisualEffectsFacade.removeListener(this.visualEffectsListener);
    this.listenersAttached = false;
  }

  private applyDeviceInfo(info: NGFDeviceInfo): void {
    this.deviceType = info.deviceType;
    this.deviceOrientation = info.orientation;
    this.deviceBreakpoint = info.breakpoint;
    this.deviceScreenWidth = info.screenWidth;
    this.deviceScreenHeight = info.screenHeight;
    this.isTablet = info.isTablet;
    this.isFoldable = info.isFoldable;
    this.foldStatus = info.foldStatus;
    this.isLandscape = info.isLandscape;
    this.deviceUpdatedAt = info.updatedAt;
    this.deviceUpdateReason = info.updateReason;
  }

  private applyHoldingSnapshot(snapshot: NGFHoldingAwarenessSnapshot): void {
    this.preferredAnchor = snapshot.preferredAnchor;
    this.holdingSide = snapshot.side;
    this.holdingSource = snapshot.source;
    this.holdingConfidence = snapshot.confidence;
    this.holdingAvailable = snapshot.available;
    this.preciseSupported = snapshot.preciseSupported;
    this.operatingHandSupported = snapshot.operatingHandSupported;
    this.detectGestureGranted = snapshot.detectGestureGranted;
    this.activityMotionGranted = snapshot.activityMotionGranted;
    this.holdingUpdatedAt = snapshot.lastUpdatedAt;
  }

  private applyVisualEffectsState(state: NGFVisualEffectsState): void {
    this.materialMode = state.settings.materialMode;
    this.effectiveLevel = state.effectiveMaterialLevel;
    this.supportsImmersive = state.capability.supportsImmersiveMaterial;
  }

  private describeSide(side: NGFHoldingAwarenessSide): string {
    switch (side) {
      case NGFHoldingAwarenessSide.LEFT:
        return '左手握持';
      case NGFHoldingAwarenessSide.RIGHT:
        return '右手握持';
      case NGFHoldingAwarenessSide.BOTH:
        return '双手握持';
      case NGFHoldingAwarenessSide.NONE:
        return '未握持';
      default:
        return '未知';
    }
  }

  private describeSource(source: NGFHoldingAwarenessSource): string {
    switch (source) {
      case NGFHoldingAwarenessSource.HOLDING_HAND:
        return '智感握姿';
      case NGFHoldingAwarenessSource.OPERATING_HAND:
        return '操作手';
      case NGFHoldingAwarenessSource.COMBINED:
        return '握姿+操作手联合';
      default:
        return '默认回退';
    }
  }

  private describeConfidence(confidence: NGFHoldingAwarenessConfidence): string {
    switch (confidence) {
      case NGFHoldingAwarenessConfidence.EXACT:
        return '精确';
      case NGFHoldingAwarenessConfidence.INFERRED:
        return '推断';
      default:
        return '回退';
    }
  }

  private describeDeviceType(type: NGFDeviceType): string {
    switch (type) {
      case NGFDeviceType.PHONE:
        return '手机';
      case NGFDeviceType.TABLET:
        return '平板';
      case NGFDeviceType.FOLDABLE:
        return '折叠屏';
      case NGFDeviceType.TWO_IN_ONE:
        return '2in1设备';
      default:
        return String(type);
    }
  }

  private describeOrientation(orientation: NGFScreenOrientation): string {
    return orientation === NGFScreenOrientation.LANDSCAPE ? '横屏' : '竖屏';
  }

  private describeUpdateReason(reason: string): string {
    switch (reason) {
      case 'initialize':
        return '初始化';
      case 'bind_window_stage':
      case 'bind_same_window_stage':
        return '窗口绑定';
      case 'display_change':
        return '屏幕变化';
      case 'window_size_change':
        return '窗口尺寸变化';
      case 'fold_status_change':
        return '折叠状态变化';
      case 'configuration_update':
        return '系统配置变化';
      case 'ability_foreground':
        return '应用回到前台';
      case 'device_awareness_page_appear':
        return '页面出现';
      case 'clear_window_stage':
        return '窗口释放';
      default:
        return reason;
    }
  }

  private formatVp(value: number): string {
    if (value <= 0) {
      return '未知';
    }
    return `${value.toFixed(0)}vp`;
  }

  private formatUpdatedAt(value: number): string {
    if (value <= 0) {
      return '尚未刷新';
    }
    const date: Date = new Date(value);
    return `${this.pad2(date.getHours())}:${this.pad2(date.getMinutes())}:${this.pad2(date.getSeconds())}`;
  }

  private pad2(value: number): string {
    if (value < 10) {
      return `0${value}`;
    }
    return String(value);
  }

  private describeFoldStatus(status: NGFFoldStatus): string {
    switch (status) {
      case NGFFoldStatus.EXPANDED:
        return '展开';
      case NGFFoldStatus.FOLDED:
        return '折叠';
      case NGFFoldStatus.HALF_FOLDED:
        return '半折叠/悬停';
      default:
        return '未知';
    }
  }

  private describeMaterialLevel(level: hdsMaterial.MaterialLevel): string {
    switch (level) {
      case hdsMaterial.MaterialLevel.EXQUISITE:
        return '精美';
      case hdsMaterial.MaterialLevel.GENTLE:
        return '轻柔';
      case hdsMaterial.MaterialLevel.SMOOTH:
        return '流畅';
      case hdsMaterial.MaterialLevel.ADAPTIVE:
        return '系统自适应';
      default:
        return `未知(${level})`;
    }
  }
}
