import sensor from '@ohos.sensor';
import { logger } from '../../utils/Logger';

const TAG: string = 'SensorManagerFacade';

export class SensorManagerFacade {
  
  /**
   * 监听加速度传感器（例如用于摇一摇功能）
   * @ohos.permission ohos.permission.ACCELEROMETER
   */
  static startAccelerometerListener(onShake: (x: number, y: number, z: number) => void): boolean {
    try {
      sensor.on(sensor.SensorId.ACCELEROMETER, (data) => {
        // x, y, z 分别代表三轴加速度
        onShake(data.x, data.y, data.z);
      }, { interval: 100000000 }); // 采样间隔 100ms
      logger.info(TAG, '已启动加速度传感器监听');
      return true;
    } catch (e) {
      logger.error(TAG, `启动加速度传感器失败: ${e}`);
      return false;
    }
  }

  /**
   * @ohos.permission ohos.permission.ACCELEROMETER
   */
  static stopAccelerometerListener(): void {
    try {
      sensor.off(sensor.SensorId.ACCELEROMETER);
      logger.info(TAG, '已停止加速度传感器监听');
    } catch (e) {
      logger.error(TAG, `停止加速度传感器失败: ${e}`);
    }
  }
}
