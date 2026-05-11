import { deviceInfo } from '@kit.BasicServicesKit';
import { logger } from '../../utils/Logger';
import {
  IDeviceCapabilityDetector,
  NGFCapabilityResult,
  NGFCapabilityType
} from '../contracts/IDeviceCapabilityDetector';

const TAG: string = 'NGFDeviceCapabilityDetectorFacade';

export class DeviceCapabilityDetectorFacade implements IDeviceCapabilityDetector {
  private readonly cache: Map<NGFCapabilityType, NGFCapabilityResult> = new Map<NGFCapabilityType, NGFCapabilityResult>();

  checkCapability(type: NGFCapabilityType): NGFCapabilityResult {
    const cached = this.cache.get(type);
    if (cached !== undefined) {
      return cached;
    }
    const result = this.detectCapability(type);
    this.cache.set(type, result);
    return result;
  }

  checkAll(): Array<NGFCapabilityResult> {
    const results: Array<NGFCapabilityResult> = [];
    const types: Array<NGFCapabilityType> = [
      NGFCapabilityType.CAMERA,
      NGFCapabilityType.GPS,
      NGFCapabilityType.NFC,
      NGFCapabilityType.BLUETOOTH,
      NGFCapabilityType.WIFI,
      NGFCapabilityType.VIBRATION,
      NGFCapabilityType.FINGERPRINT,
      NGFCapabilityType.FACE_RECOGNITION,
      NGFCapabilityType.ACCELEROMETER,
      NGFCapabilityType.GYROSCOPE,
      NGFCapabilityType.BAROMETER,
      NGFCapabilityType.AMBIENT_LIGHT,
      NGFCapabilityType.PROXIMITY
    ];
    for (let index = 0; index < types.length; index++) {
      results.push(this.checkCapability(types[index]));
    }
    logger.info(TAG, `设备能力检测完成: total=${results.length}`);
    return results;
  }

  isAvailable(type: NGFCapabilityType): boolean {
    return this.checkCapability(type).available;
  }

  getAvailableCapabilities(): Array<NGFCapabilityType> {
    const available: Array<NGFCapabilityType> = [];
    const all = this.checkAll();
    for (let index = 0; index < all.length; index++) {
      if (all[index].available) {
        available.push(all[index].capability);
      }
    }
    return available;
  }

  private detectCapability(type: NGFCapabilityType): NGFCapabilityResult {
    try {
      const deviceType = deviceInfo.deviceType;
      switch (type) {
        case NGFCapabilityType.CAMERA:
          return this.detectCamera(deviceType);
        case NGFCapabilityType.GPS:
          return new NGFCapabilityResult(type, true, '位置服务由系统提供');
        case NGFCapabilityType.NFC:
          return this.detectNfc(deviceType);
        case NGFCapabilityType.BLUETOOTH:
          return new NGFCapabilityResult(type, true, '蓝牙由系统支持');
        case NGFCapabilityType.WIFI:
          return new NGFCapabilityResult(type, true, 'WiFi 由系统支持');
        case NGFCapabilityType.VIBRATION:
          return this.detectVibration(deviceType);
        case NGFCapabilityType.FINGERPRINT:
          return new NGFCapabilityResult(type, true, '生物识别由系统框架提供');
        case NGFCapabilityType.FACE_RECOGNITION:
          return new NGFCapabilityResult(type, true, '生物识别由系统框架提供');
        case NGFCapabilityType.ACCELEROMETER:
          return this.detectSensor(deviceType, 'accelerometer');
        case NGFCapabilityType.GYROSCOPE:
          return this.detectSensor(deviceType, 'gyroscope');
        case NGFCapabilityType.BAROMETER:
          return this.detectSensor(deviceType, 'barometer');
        case NGFCapabilityType.AMBIENT_LIGHT:
          return this.detectSensor(deviceType, 'ambient_light');
        case NGFCapabilityType.PROXIMITY:
          return this.detectSensor(deviceType, 'proximity');
        default:
          return new NGFCapabilityResult(type, false, '未知能力类型');
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `检测能力异常: type=${type}, error=${message}`);
      return new NGFCapabilityResult(type, false, `检测异常: ${message}`);
    }
  }

  private detectCamera(deviceType: string): NGFCapabilityResult {
    if (deviceType === 'phone' || deviceType === 'foldable') {
      return new NGFCapabilityResult(NGFCapabilityType.CAMERA, true, '手机/折叠屏设备通常配备摄像头');
    }
    if (deviceType === 'tablet' || deviceType === '2in1') {
      return new NGFCapabilityResult(NGFCapabilityType.CAMERA, true, '平板/二合一设备通常配备摄像头');
    }
    if (deviceType === 'wearable') {
      return new NGFCapabilityResult(NGFCapabilityType.CAMERA, false, '穿戴设备通常无摄像头');
    }
    if (deviceType === 'default' || deviceType === 'liteWearable' || deviceType === 'smartVision') {
      return new NGFCapabilityResult(NGFCapabilityType.CAMERA, false, '该设备类型可能无摄像头');
    }
    return new NGFCapabilityResult(NGFCapabilityType.CAMERA, true, '假设设备配备摄像头');
  }

  private detectNfc(deviceType: string): NGFCapabilityResult {
    if (deviceType === 'phone' || deviceType === 'foldable') {
      return new NGFCapabilityResult(NGFCapabilityType.NFC, true, '手机/折叠屏设备通常支持 NFC');
    }
    return new NGFCapabilityResult(NGFCapabilityType.NFC, false, `${deviceType} 设备通常不支持 NFC`);
  }

  private detectVibration(deviceType: string): NGFCapabilityResult {
    if (deviceType === 'phone' || deviceType === 'foldable' || deviceType === 'wearable') {
      return new NGFCapabilityResult(NGFCapabilityType.VIBRATION, true, '该设备类型通常支持振动');
    }
    return new NGFCapabilityResult(NGFCapabilityType.VIBRATION, false, `${deviceType} 设备通常不支持振动`);
  }

  private detectSensor(deviceType: string, sensorName: string): NGFCapabilityResult {
    if (deviceType === 'phone' || deviceType === 'foldable' || deviceType === 'wearable') {
      return new NGFCapabilityResult(
        sensorName as NGFCapabilityType,
        true,
        `${deviceType} 设备通常配备 ${sensorName} 传感器`
      );
    }
    if (deviceType === 'tablet' || deviceType === '2in1') {
      if (sensorName === 'accelerometer' || sensorName === 'gyroscope') {
        return new NGFCapabilityResult(sensorName as NGFCapabilityType, true, `平板通常配备 ${sensorName} 传感器`);
      }
      return new NGFCapabilityResult(sensorName as NGFCapabilityType, false, `平板可能不配备 ${sensorName} 传感器`);
    }
    return new NGFCapabilityResult(sensorName as NGFCapabilityType, false, `${deviceType} 设备传感器状态未知`);
  }
}

export const ngfDeviceCapabilityDetectorFacade: DeviceCapabilityDetectorFacade = new DeviceCapabilityDetectorFacade();
