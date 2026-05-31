/**
 * 设备能力类型
 */
export enum NGFCapabilityType {
  CAMERA = 'camera',
  GPS = 'gps',
  NFC = 'nfc',
  BLUETOOTH = 'bluetooth',
  WIFI = 'wifi',
  VIBRATION = 'vibration',
  FINGERPRINT = 'fingerprint',
  FACE_RECOGNITION = 'face_recognition',
  ACCELEROMETER = 'accelerometer',
  GYROSCOPE = 'gyroscope',
  BAROMETER = 'barometer',
  AMBIENT_LIGHT = 'ambient_light',
  PROXIMITY = 'proximity'
}

/**
 * 设备能力检测结果
 */
export class NGFCapabilityResult {
  readonly capability: NGFCapabilityType;
  readonly available: boolean;
  readonly detail: string;

  constructor(capability: NGFCapabilityType, available: boolean, detail: string) {
    this.capability = capability;
    this.available = available;
    this.detail = detail;
  }
}

/**
 * 设备能力检测器接口
 */
export interface IDeviceCapabilityDetector {
  checkCapability(type: NGFCapabilityType): NGFCapabilityResult;
  checkAll(): Array<NGFCapabilityResult>;
  isAvailable(type: NGFCapabilityType): boolean;
  getAvailableCapabilities(): Array<NGFCapabilityType>;
}
