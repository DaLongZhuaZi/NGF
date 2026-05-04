import { hdsMaterial } from '@kit.UIDesignKit';
import { logger } from '../../Framework/NGF/utils/Logger';

const TAG: string = 'NGFDeviceAwarenessPage';

@Component
export struct NGFDeviceAwarenessPage {
  @StorageProp('ngf_holding_awareness_preferred_anchor') private preferredAnchor: string = 'right';
  @StorageProp('ngf_holding_awareness_side') private holdingSide: string = 'unknown';
  @StorageProp('ngf_holding_awareness_source') private holdingSource: string = 'default';
  @StorageProp('ngf_holding_awareness_confidence') private holdingConfidence: string = 'fallback';
  @StorageProp('ngf_holding_awareness_available') private holdingAvailable: boolean = false;
  @StorageProp('ngf_holding_awareness_precise_supported') private preciseSupported: boolean = false;
  @StorageProp('ngf_holding_awareness_detect_gesture_granted') private detectGestureGranted: boolean = false;
  @StorageProp('ngf_holding_awareness_activity_motion_granted') private activityMotionGranted: boolean = false;

  @StorageProp('ngf_device_type') private deviceType: string = 'phone';
  @StorageProp('ngf_device_orientation') private deviceOrientation: string = 'portrait';
  @StorageProp('ngf_device_breakpoint') private deviceBreakpoint: string = 'xs';
  @StorageProp('ngf_device_is_tablet') private isTablet: boolean = false;
  @StorageProp('ngf_device_is_foldable') private isFoldable: boolean = false;
  @StorageProp('ngf_device_fold_status') private foldStatus: number = 0;
  @StorageProp('ngf_device_is_landscape') private isLandscape: boolean = false;

  @StorageProp('ngf_visual_effects_material_mode') private materialMode: string = 'adaptive';
  @StorageProp('ngf_visual_effects_effective_material_level') private effectiveLevel: number = 3;
  @StorageProp('ngf_visual_effects_supports_immersive') private supportsImmersive: boolean = false;

  build() {
    Column({ space: 12 }) {
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
        .fontColor('#1C2430')

      this.buildStatusRow('推荐停靠', this.preferredAnchor === 'left' ? '左侧' : '右侧')
      this.buildStatusRow('握持侧', this.describeSide(this.holdingSide))
      this.buildStatusRow('数据来源', this.describeSource(this.holdingSource))
      this.buildStatusRow('置信度', this.describeConfidence(this.holdingConfidence))
      this.buildStatusRow('传感器可用', this.holdingAvailable ? '是' : '否')
      this.buildStatusRow('精确握姿支持', this.preciseSupported ? '是' : '否')
      this.buildStatusRow('DETECT_GESTURE', this.detectGestureGranted ? '已授权' : '未授权')
      this.buildStatusRow('ACTIVITY_MOTION', this.activityMotionGranted ? '已授权' : '未授权')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#D5DEE9' })
  }

  @Builder
  private buildDeviceCard(): void {
    Column({ space: 8 }) {
      Text('设备信息')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C2430')

      this.buildStatusRow('设备类型', this.describeDeviceType(this.deviceType))
      this.buildStatusRow('屏幕方向', this.deviceOrientation === 'landscape' ? '横屏' : '竖屏')
      this.buildStatusRow('断点', this.deviceBreakpoint.toUpperCase())
      this.buildStatusRow('平板类设备', this.isTablet ? '是' : '否')
      this.buildStatusRow('折叠屏', this.isFoldable ? '是' : '否')
      this.buildStatusRow('折叠状态', this.describeFoldStatus(this.foldStatus))
      this.buildStatusRow('横屏', this.isLandscape ? '是' : '否')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#D5DEE9' })
  }

  @Builder
  private buildVisualEffectsCard(): void {
    Column({ space: 8 }) {
      Text('视觉效果')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C2430')

      this.buildStatusRow('材质模式', this.materialMode === 'adaptive' ? '系统自适应' : '手动固定')
      this.buildStatusRow('当前材质等级', this.describeMaterialLevel(this.effectiveLevel))
      this.buildStatusRow('支持沉浸式材质', this.supportsImmersive ? '是' : '否')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#D5DEE9' })
  }

  @Builder
  private buildStatusRow(label: string, value: string): void {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#4F5F73')
        .layoutWeight(1)
      Text(value)
        .fontSize(14)
        .fontColor('#1C2430')
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
  }

  private describeSide(side: string): string {
    switch (side) {
      case 'left':
        return '左手握持';
      case 'right':
        return '右手握持';
      case 'both':
        return '双手握持';
      case 'none':
        return '未握持';
      default:
        return '未知';
    }
  }

  private describeSource(source: string): string {
    switch (source) {
      case 'holding_hand':
        return '智感握姿';
      case 'operating_hand':
        return '操作手';
      case 'combined':
        return '握姿+操作手联合';
      default:
        return '默认回退';
    }
  }

  private describeConfidence(confidence: string): string {
    switch (confidence) {
      case 'exact':
        return '精确';
      case 'inferred':
        return '推断';
      default:
        return '回退';
    }
  }

  private describeDeviceType(type: string): string {
    switch (type) {
      case 'phone':
        return '手机';
      case 'tablet':
        return '平板';
      case 'foldable':
        return '折叠屏';
      case 'two_in_one':
        return '2in1设备';
      default:
        return type;
    }
  }

  private describeFoldStatus(status: number): string {
    switch (status) {
      case 1:
        return '展开';
      case 2:
        return '折叠';
      case 3:
        return '半折叠/悬停';
      default:
        return '未知';
    }
  }

  private describeMaterialLevel(level: number): string {
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
