import { geoLocationManager } from '@kit.LocationKit';
import { ILocationManager } from '../contracts/ILocationManager';
import { logger } from '../../utils/Logger';

const TAG: string = 'LocationManagerFacade';

export class LocationManagerFacade implements ILocationManager {
  /**
   * 检查是否开启了位置服务
   */
  isLocationEnabled(): boolean {
    try {
      return geoLocationManager.isLocationEnabled();
    } catch (e) {
      logger.error(TAG, `检查位置服务状态失败: ${e}`);
      return false;
    }
  }

  /**
   * 获取当前位置（单次）
   * 需要预先申请 ohos.permission.APPROXIMATELY_LOCATION 或 ohos.permission.LOCATION 权限
   * @ohos.permission ohos.permission.APPROXIMATELY_LOCATION
   */
  async getCurrentLocation(): Promise<geoLocationManager.Location | null> {
    try {
      const requestInfo: geoLocationManager.CurrentLocationRequest = {
        priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
        scenario: geoLocationManager.LocationRequestScenario.UNSET,
        maxAccuracy: 0
      };
      const location = await geoLocationManager.getCurrentLocation(requestInfo);
      logger.info(TAG, `获取位置成功: lat=${location.latitude}, lon=${location.longitude}`);
      return location;
    } catch (e) {
      logger.error(TAG, `获取当前位置失败: ${e}`);
      return null;
    }
  }
}

export const ngfLocationManagerFacade: ILocationManager = new LocationManagerFacade();
