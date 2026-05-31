export interface ISensorManager {
  /**
   * 监听加速度传感器（例如用于摇一摇功能）
   * @param onShake 回调函数，接收 x/y/z 三轴加速度
   * @returns 是否启动成功
   */
  startAccelerometerListener(onShake: (x: number, y: number, z: number) => void): boolean;

  /**
   * 停止加速度传感器监听
   */
  stopAccelerometerListener(): void;
}
