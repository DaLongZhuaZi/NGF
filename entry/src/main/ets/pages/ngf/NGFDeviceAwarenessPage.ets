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
import { resolveResourceString } from '../../Framework/NGF/i18n/index';

const TAG: string = 'NGFDeviceAwarenessPage';

@Component
struct NGFDeviceAwarenessStatusRow {
  @Prop label: ResourceStr = '';
  @Prop value: ResourceStr = '';

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
    logger.lifecycle(TAG, resolveResourceString(this.getUIContext().getHostContext(), $r('app.string.ui_str_2347')));
    ngfDeviceAdaptationFacade.refresh('device_awareness_page_appear');
    void ngfHoldingAwarenessFacade.resume();
  }

  aboutToDisappear(): void {
    this.detachLiveStateListeners();
  }

  build() {
    Column({ space: 12 }) {
      Column({ space: 4 }) {
        Text(this.buildHoldingSummary())
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Text(this.buildDeviceSummary())
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
  }

  @Builder
  private buildHoldingCard(): void {
    Column({ space: 8 }) {
      Text($r('app.string.ui_str_2348'))
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
      Text($r('app.string.ui_str_2349'))
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
      Text($r('app.string.ui_str_2350'))
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
      label: $r('app.string.ui_str_2351'),
      value: this.preferredAnchor === NGFHoldingUiAnchor.LEFT ? $r('app.string.ui_str_2352') : $r('app.string.ui_str_2353')
    })
  }

  @Builder
  private buildHoldingSideRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2354'), value: this.describeSide(this.holdingSide) })
  }

  @Builder
  private buildHoldingSourceRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2355'), value: this.describeSource(this.holdingSource) })
  }

  @Builder
  private buildHoldingConfidenceRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2356'), value: this.describeConfidence(this.holdingConfidence) })
  }

  @Builder
  private buildHoldingAvailableRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2357'), value: this.holdingAvailable ? $r('app.string.ui_str_2358') : $r('app.string.ui_str_2359') })
  }

  @Builder
  private buildPreciseSupportedRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2360'), value: this.preciseSupported ? $r('app.string.ui_str_2358') : $r('app.string.ui_str_2359') })
  }

  @Builder
  private buildOperatingHandSupportedRow(): void {
    NGFDeviceAwarenessStatusRow({
      label: $r('app.string.ui_str_2361'),
      value: this.operatingHandSupported ? $r('app.string.ui_str_2362') : $r('app.string.ui_str_2363')
    })
  }

  @Builder
  private buildDetectGestureRow(): void {
    NGFDeviceAwarenessStatusRow({ label: 'DETECT_GESTURE', value: this.detectGestureGranted ? $r('app.string.ui_str_2364') : $r('app.string.ui_str_2365') })
  }

  @Builder
  private buildActivityMotionRow(): void {
    NGFDeviceAwarenessStatusRow({ label: 'ACTIVITY_MOTION', value: this.activityMotionGranted ? $r('app.string.ui_str_2364') : $r('app.string.ui_str_2365') })
  }

  @Builder
  private buildHoldingUpdatedAtRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2366'), value: this.formatUpdatedAt(this.holdingUpdatedAt) })
  }

  @Builder
  private buildDeviceTypeRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2367'), value: this.describeDeviceType(this.deviceType) })
  }

  @Builder
  private buildDeviceOrientationRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2368'), value: this.describeOrientation(this.deviceOrientation) })
  }

  @Builder
  private buildDeviceBreakpointRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2369'), value: this.deviceBreakpoint.toUpperCase() })
  }

  @Builder
  private buildDeviceWidthRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2370'), value: this.formatVp(this.deviceScreenWidth) })
  }

  @Builder
  private buildDeviceHeightRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2371'), value: this.formatVp(this.deviceScreenHeight) })
  }

  @Builder
  private buildIsTabletRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2372'), value: this.isTablet ? $r('app.string.ui_str_2358') : $r('app.string.ui_str_2359') })
  }

  @Builder
  private buildIsFoldableRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2373'), value: this.isFoldable ? $r('app.string.ui_str_2358') : $r('app.string.ui_str_2359') })
  }

  @Builder
  private buildFoldStatusRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2374'), value: this.describeFoldStatus(this.foldStatus) })
  }

  @Builder
  private buildIsLandscapeRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2375'), value: this.isLandscape ? $r('app.string.ui_str_2358') : $r('app.string.ui_str_2359') })
  }

  @Builder
  private buildDeviceUpdateReasonRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2376'), value: this.describeUpdateReason(this.deviceUpdateReason) })
  }

  @Builder
  private buildDeviceUpdatedAtRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2377'), value: this.formatUpdatedAt(this.deviceUpdatedAt) })
  }

  @Builder
  private buildMaterialModeRow(): void {
    NGFDeviceAwarenessStatusRow({
      label: $r('app.string.ui_str_2378'),
      value: this.materialMode === NGFVisualEffectsMaterialMode.ADAPTIVE ? $r('app.string.ui_str_2379') : $r('app.string.ui_str_2380')
    })
  }

  @Builder
  private buildMaterialLevelRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2381'), value: this.describeMaterialLevel(this.effectiveLevel) })
  }

  @Builder
  private buildSupportsImmersiveRow(): void {
    NGFDeviceAwarenessStatusRow({ label: $r('app.string.ui_str_2382'), value: this.supportsImmersive ? $r('app.string.ui_str_2358') : $r('app.string.ui_str_2359') })
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

  private buildHoldingSummary(): string {
    const sideLabel = this.describeSide(this.holdingSide);
    const confidenceLabel = this.describeConfidence(this.holdingConfidence);
    const sideStr = resolveResourceString(this.getUIContext().getHostContext(), sideLabel);
    const confidenceStr = resolveResourceString(this.getUIContext().getHostContext(), confidenceLabel);
    return `实时握持：${sideStr} / ${confidenceStr}`;
  }

  private buildDeviceSummary(): string {
    const orientationLabel = this.describeOrientation(this.deviceOrientation);
    const updateReasonLabel = this.describeUpdateReason(this.deviceUpdateReason);
    const orientationStr = resolveResourceString(this.getUIContext().getHostContext(), orientationLabel);
    const widthStr = resolveResourceString(this.getUIContext().getHostContext(), this.formatVp(this.deviceScreenWidth));
    const heightStr = resolveResourceString(this.getUIContext().getHostContext(), this.formatVp(this.deviceScreenHeight));
    const reasonStr = resolveResourceString(this.getUIContext().getHostContext(), updateReasonLabel);
    return `实时设备：${orientationStr} · ${widthStr} x ${heightStr} · ${reasonStr}`;
  }

  private describeSide(side: NGFHoldingAwarenessSide): ResourceStr {
    switch (side) {
      case NGFHoldingAwarenessSide.LEFT:
        return $r('app.string.ui_str_2383');
      case NGFHoldingAwarenessSide.RIGHT:
        return $r('app.string.ui_str_2384');
      case NGFHoldingAwarenessSide.BOTH:
        return $r('app.string.ui_str_2385');
      case NGFHoldingAwarenessSide.NONE:
        return $r('app.string.ui_str_2386');
      default:
        return $r('app.string.ui_str_2387');
    }
  }

  private describeSource(source: NGFHoldingAwarenessSource): ResourceStr {
    switch (source) {
      case NGFHoldingAwarenessSource.HOLDING_HAND:
        return $r('app.string.ui_str_2388');
      case NGFHoldingAwarenessSource.OPERATING_HAND:
        return $r('app.string.ui_str_2389');
      case NGFHoldingAwarenessSource.COMBINED:
        return $r('app.string.ui_str_2390');
      default:
        return $r('app.string.ui_str_2391');
    }
  }

  private describeConfidence(confidence: NGFHoldingAwarenessConfidence): ResourceStr {
    switch (confidence) {
      case NGFHoldingAwarenessConfidence.EXACT:
        return $r('app.string.ui_str_2392');
      case NGFHoldingAwarenessConfidence.INFERRED:
        return $r('app.string.ui_str_2393');
      default:
        return $r('app.string.ui_str_2394');
    }
  }

  private describeDeviceType(type: NGFDeviceType): ResourceStr {
    switch (type) {
      case NGFDeviceType.PHONE:
        return $r('app.string.ui_str_2395');
      case NGFDeviceType.TABLET:
        return $r('app.string.ui_str_2396');
      case NGFDeviceType.FOLDABLE:
        return $r('app.string.ui_str_2373');
      case NGFDeviceType.TWO_IN_ONE:
        return $r('app.string.ui_str_2397');
      default:
        return String(type);
    }
  }

  private describeOrientation(orientation: NGFScreenOrientation): ResourceStr {
    return orientation === NGFScreenOrientation.LANDSCAPE ? $r('app.string.ui_str_2375') : $r('app.string.ui_str_2398');
  }

  private describeUpdateReason(reason: string): ResourceStr {
    switch (reason) {
      case 'initialize':
        return $r('app.string.ui_str_2399');
      case 'bind_window_stage':
      case 'bind_same_window_stage':
        return $r('app.string.ui_str_2400');
      case 'display_change':
        return $r('app.string.ui_str_2401');
      case 'window_size_change':
        return $r('app.string.ui_str_2402');
      case 'fold_status_change':
        return $r('app.string.ui_str_2403');
      case 'configuration_update':
        return $r('app.string.ui_str_2404');
      case 'ability_foreground':
        return $r('app.string.ui_str_2405');
      case 'device_awareness_page_appear':
        return $r('app.string.ui_str_2406');
      case 'clear_window_stage':
        return $r('app.string.ui_str_2407');
      default:
        return reason;
    }
  }

  private formatVp(value: number): ResourceStr {
    if (value <= 0) {
      return $r('app.string.ui_str_2387');
    }
    return `${value.toFixed(0)}vp`;
  }

  private formatUpdatedAt(value: number): ResourceStr {
    if (value <= 0) {
      return $r('app.string.ui_str_2408');
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

  private describeFoldStatus(status: NGFFoldStatus): ResourceStr {
    switch (status) {
      case NGFFoldStatus.EXPANDED:
        return $r('app.string.ui_str_2409');
      case NGFFoldStatus.FOLDED:
        return $r('app.string.ui_str_2410');
      case NGFFoldStatus.HALF_FOLDED:
        return $r('app.string.ui_str_2411');
      default:
        return $r('app.string.ui_str_2387');
    }
  }

  private describeMaterialLevel(level: hdsMaterial.MaterialLevel): ResourceStr {
    switch (level) {
      case hdsMaterial.MaterialLevel.EXQUISITE:
        return $r('app.string.ui_str_2412');
      case hdsMaterial.MaterialLevel.GENTLE:
        return $r('app.string.ui_str_2413');
      case hdsMaterial.MaterialLevel.SMOOTH:
        return $r('app.string.ui_str_2414');
      case hdsMaterial.MaterialLevel.ADAPTIVE:
        return $r('app.string.ui_str_2379');
      default:
        return `未知(${level})`;
    }
  }
}
