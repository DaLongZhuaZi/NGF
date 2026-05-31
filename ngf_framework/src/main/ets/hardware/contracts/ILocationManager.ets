import { geoLocationManager } from '@kit.LocationKit';

export interface ILocationManager {
  /**
   * 检查是否开启了位置服务
   */
  isLocationEnabled(): boolean;

  /**
   * 获取当前位置（单次）
   * @returns 位置信息，失败返回 null
   */
  getCurrentLocation(): Promise<geoLocationManager.Location | null>;
}
