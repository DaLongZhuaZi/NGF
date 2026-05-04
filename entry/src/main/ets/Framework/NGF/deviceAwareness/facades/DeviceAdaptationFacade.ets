// 文件路径: entry/src/main/ets/Framework/NGF/deviceAwareness/facades/DeviceAdaptationFacade.ets
// 职责: 设备感知门面，处理多设备、多屏幕尺寸、多方向的适配逻辑
// 从 manxia DeviceAdaptationManager 移植，适配 NGF 框架模式

import { display } from '@kit.ArkUI';
import { window } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
import { logger } from '../../utils/Logger';
import {
  IDeviceAdaptationManager,
  NGFDeviceInfo,
  NGFDeviceType,
  NGFScreenOrientation,
  NGFBreakpoint,
  NGFFoldStatus,
  NGFDeviceChangeListener
} from '../contracts/IDeviceAdaptationManager';

const TAG = 'NGFDeviceAdaptationFacade';

// AppStorage 键名常量 - ngf_ 前缀
const STORAGE_KEY_DEVICE_TYPE: string = 'ngf_device_type';
const STORAGE_KEY_ORIENTATION: string = 'ngf_device_orientation';
const STORAGE_KEY_BREAKPOINT: string = 'ngf_device_breakpoint';
const STORAGE_KEY_SCREEN_WIDTH: string = 'ngf_device_screen_width';
const STORAGE_KEY_SCREEN_HEIGHT: string = 'ngf_device_screen_height';
const STORAGE_KEY_IS_TABLET: string = 'ngf_device_is_tablet';
const STORAGE_KEY_IS_FOLDABLE: string = 'ngf_device_is_foldable';
const STORAGE_KEY_FOLD_STATUS: string = 'ngf_device_fold_status';
const STORAGE_KEY_IS_LANDSCAPE: string = 'ngf_device_is_landscape';

/**
 * 设备信息日志接口（用于日志输出）
 */
interface DeviceInfoLog {
  deviceType: string;
  orientation: string;
  breakpoint: string;
  screenWidth: string;
  screenHeight: string;
  isFoldable: boolean;
  foldStatus: string;
}

/**
 * 断点顺序映射，用于断点比较
 */
const BREAKPOINT_ORDER: NGFBreakpoint[] = [
  NGFBreakpoint.XS,
  NGFBreakpoint.SM,
  NGFBreakpoint.MD,
  NGFBreakpoint.LG
];

/**
 * 设备适配门面
 * 单例模式，全局管理设备信息和适配逻辑
 * 实现 IDeviceAdaptationManager 接口，通过 AppStorage 发布设备状态
 */
export class NGFDeviceAdaptationManager implements IDeviceAdaptationManager {
  private static instance: NGFDeviceAdaptationManager;
  private currentDeviceInfo: NGFDeviceInfo | null = null;
  private listeners: Set<NGFDeviceChangeListener> = new Set<NGFDeviceChangeListener>();
  private displayObj: display.Display | null = null;
  private isFoldableDevice: boolean = false;
  private isTablet: boolean = false;
  private currentFoldStatus: NGFFoldStatus = NGFFoldStatus.UNKNOWN;
  private destroyed: boolean = false;

  private constructor() {
    this.initialize();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): NGFDeviceAdaptationManager {
    if (!NGFDeviceAdaptationManager.instance) {
      NGFDeviceAdaptationManager.instance = new NGFDeviceAdaptationManager();
    }
    return NGFDeviceAdaptationManager.instance;
  }

  /**
   * 初始化
   */
  private initialize(): void {
    try {
      // 获取默认显示对象
      this.displayObj = display.getDefaultDisplaySync();

      // 检测是否是折叠屏设备
      this.detectFoldableDevice();

      // 检测是否是平板、二合一类设备
      this.detectTabletDevice();

      // 更新设备信息并发布到 AppStorage
      this.updateDeviceInfo();

      // 监听屏幕变化
      this.registerDisplayListener();

      // 如果是折叠屏，监听折叠状态变化
      if (this.isFoldableDevice) {
        this.registerFoldStatusListener();
      }

      logger.info(TAG, '设备适配管理器初始化完成');
    } catch (error) {
      logger.error(TAG, '设备适配管理器初始化失败', String(error));
    }
  }

  /**
   * 检测是否是折叠屏设备
   */
  private detectFoldableDevice(): void {
    try {
      this.isFoldableDevice = display.isFoldable();
      if (this.isFoldableDevice) {
        this.currentFoldStatus = this.convertFoldStatus(display.getFoldStatus());
        logger.info(TAG, `检测到折叠屏设备，当前状态: ${this.getFoldStatusName(this.currentFoldStatus)}`);
      } else {
        logger.info(TAG, '非折叠屏设备');
      }
    } catch (error) {
      logger.warn(TAG, '折叠屏检测失败，假定为非折叠屏设备', String(error));
      this.isFoldableDevice = false;
      this.currentFoldStatus = NGFFoldStatus.UNKNOWN;
    }
  }

  /**
   * 检测是否是平板、二合一类设备
   */
  private detectTabletDevice(): void {
    try {
      const deviceTypeStr: string = deviceInfo.deviceType;
      this.isTablet = deviceTypeStr === 'tablet' || deviceTypeStr === '2in1';
      logger.info(TAG, `平板类设备检测结果: ${this.isTablet}`);
    } catch (error) {
      logger.warn(TAG, '平板类设备检测失败', String(error));
      this.isTablet = false;
    }
  }

  /**
   * 转换折叠状态枚举
   */
  private convertFoldStatus(status: display.FoldStatus): NGFFoldStatus {
    switch (status) {
      case display.FoldStatus.FOLD_STATUS_EXPANDED:
        return NGFFoldStatus.EXPANDED;
      case display.FoldStatus.FOLD_STATUS_FOLDED:
        return NGFFoldStatus.FOLDED;
      case display.FoldStatus.FOLD_STATUS_HALF_FOLDED:
        return NGFFoldStatus.HALF_FOLDED;
      default:
        return NGFFoldStatus.UNKNOWN;
    }
  }

  /**
   * 获取折叠状态名称
   */
  private getFoldStatusName(status: NGFFoldStatus): string {
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

  /**
   * 注册折叠状态变化监听器
   */
  private registerFoldStatusListener(): void {
    try {
      display.on('foldStatusChange', (status: display.FoldStatus) => {
        this.currentFoldStatus = this.convertFoldStatus(status);
        logger.info(TAG, `折叠状态变化: ${this.getFoldStatusName(this.currentFoldStatus)}`);
        // 折叠状态变化时更新设备信息
        this.updateDeviceInfo();
      });
      logger.debug(TAG, '折叠状态监听器注册成功');
    } catch (error) {
      logger.warn(TAG, '注册折叠状态监听器失败', String(error));
    }
  }

  /**
   * 注册屏幕变化监听
   */
  private registerDisplayListener(): void {
    try {
      // 监听屏幕变化（包括旋转、分辨率改变等）
      display.on('change', (displayId: number) => {
        logger.info(TAG, `屏幕发生变化: displayId=${displayId}`);
        this.updateDeviceInfo();
      });
      logger.debug(TAG, '屏幕变化监听器注册成功');
    } catch (error) {
      logger.error(TAG, '注册屏幕变化监听失败', String(error));
    }
  }

  /**
   * 更新设备信息并发布到 AppStorage
   */
  private updateDeviceInfo(): void {
    try {
      // 重要：每次都重新获取 display 对象，因为旋转后属性会变化
      this.displayObj = display.getDefaultDisplaySync();

      const widthPx: number = this.displayObj.width;
      const heightPx: number = this.displayObj.height;
      const density: number = this.displayObj.densityDPI / 160;

      // 转换为vp单位
      const widthVp: number = widthPx / density;
      const heightVp: number = heightPx / density;

      // 判断屏幕方向
      const displayOrientation: number = this.displayObj.orientation;
      const isLandscape: boolean = (
        displayOrientation === display.Orientation.LANDSCAPE ||
        displayOrientation === display.Orientation.LANDSCAPE_INVERTED
      );
      const orientation: NGFScreenOrientation = isLandscape
        ? NGFScreenOrientation.LANDSCAPE
        : NGFScreenOrientation.PORTRAIT;

      logger.debug(TAG, `方向检测: displayOrientation=${displayOrientation}, isLandscape=${isLandscape}, 宽=${widthVp.toFixed(2)}, 高=${heightVp.toFixed(2)}`);

      // 判断断点（基于宽度）
      const breakpoint: NGFBreakpoint = this.calculateBreakpoint(widthVp);

      // 获取设备类型
      const deviceType: NGFDeviceType = this.getDeviceTypeFromAPI();

      // 构建设备信息
      const newDeviceInfo: NGFDeviceInfo = {
        deviceType,
        orientation,
        breakpoint,
        screenWidth: widthVp,
        screenHeight: heightVp,
        screenWidthPx: widthPx,
        screenHeightPx: heightPx,
        density,
        isTablet: deviceType === NGFDeviceType.TABLET || deviceType === NGFDeviceType.TWO_IN_ONE,
        isFoldable: this.isFoldableDevice,
        foldStatus: this.currentFoldStatus,
        isLandscape
      };

      // 检查是否有变化
      const hasChanged: boolean = this.hasDeviceInfoChanged(newDeviceInfo);

      this.currentDeviceInfo = newDeviceInfo;

      // 发布到 AppStorage
      this.publishToAppStorage(newDeviceInfo);

      const logInfo: DeviceInfoLog = {
        deviceType: newDeviceInfo.deviceType,
        orientation: newDeviceInfo.orientation,
        breakpoint: newDeviceInfo.breakpoint,
        screenWidth: newDeviceInfo.screenWidth.toFixed(2),
        screenHeight: newDeviceInfo.screenHeight.toFixed(2),
        isFoldable: newDeviceInfo.isFoldable,
        foldStatus: this.getFoldStatusName(newDeviceInfo.foldStatus)
      };

      logger.info(TAG, `设备信息: ${JSON.stringify(logInfo)}`);

      // 如果有变化，通知监听器
      if (hasChanged) {
        this.notifyListeners(newDeviceInfo);
      }
    } catch (error) {
      logger.error(TAG, '更新设备信息失败', String(error));
    }
  }

  /**
   * 发布设备信息到 AppStorage
   */
  private publishToAppStorage(info: NGFDeviceInfo): void {
    try {
      AppStorage.setOrCreate<string>(STORAGE_KEY_DEVICE_TYPE, info.deviceType);
      AppStorage.setOrCreate<string>(STORAGE_KEY_ORIENTATION, info.orientation);
      AppStorage.setOrCreate<string>(STORAGE_KEY_BREAKPOINT, info.breakpoint);
      AppStorage.setOrCreate<number>(STORAGE_KEY_SCREEN_WIDTH, info.screenWidth);
      AppStorage.setOrCreate<number>(STORAGE_KEY_SCREEN_HEIGHT, info.screenHeight);
      AppStorage.setOrCreate<boolean>(STORAGE_KEY_IS_TABLET, info.isTablet);
      AppStorage.setOrCreate<boolean>(STORAGE_KEY_IS_FOLDABLE, info.isFoldable);
      AppStorage.setOrCreate<number>(STORAGE_KEY_FOLD_STATUS, info.foldStatus);
      AppStorage.setOrCreate<boolean>(STORAGE_KEY_IS_LANDSCAPE, info.isLandscape);
    } catch (error) {
      logger.error(TAG, '发布设备信息到 AppStorage 失败', String(error));
    }
  }

  /**
   * 从官方API获取设备类型
   */
  private getDeviceTypeFromAPI(): NGFDeviceType {
    try {
      const systemDeviceType: string = deviceInfo.deviceType;

      // 如果是折叠屏，优先返回折叠屏类型
      if (this.isFoldableDevice) {
        logger.debug(TAG, `设备类型: ${systemDeviceType} (折叠屏)`);
        return NGFDeviceType.FOLDABLE;
      }

      // 根据系统返回的设备类型映射
      switch (systemDeviceType) {
        case 'phone':
          return NGFDeviceType.PHONE;
        case 'tablet':
          return NGFDeviceType.TABLET;
        case '2in1':
          return NGFDeviceType.TWO_IN_ONE;
        default:
          // 如果无法识别，根据屏幕尺寸判断
          logger.warn(TAG, `未知设备类型: ${systemDeviceType}，使用屏幕尺寸判断`);
          return this.fallbackDeviceTypeDetection();
      }
    } catch (error) {
      logger.error(TAG, '获取设备类型失败，使用备用方案', String(error));
      return this.fallbackDeviceTypeDetection();
    }
  }

  /**
   * 备用设备类型检测（基于屏幕尺寸）
   */
  private fallbackDeviceTypeDetection(): NGFDeviceType {
    if (!this.displayObj) {
      return NGFDeviceType.PHONE;
    }

    const density: number = this.displayObj.densityDPI / 160;
    const widthVp: number = this.displayObj.width / density;
    const heightVp: number = this.displayObj.height / density;
    // 使用短边判断，避免横屏手机被误判为平板
    const shortSideVp: number = Math.min(widthVp, heightVp);
    const longSideVp: number = Math.max(widthVp, heightVp);

    if (shortSideVp >= 840 || longSideVp >= 1280) {
      return NGFDeviceType.TWO_IN_ONE;
    } else if (shortSideVp >= 600) {
      return NGFDeviceType.TABLET;
    } else {
      return NGFDeviceType.PHONE;
    }
  }

  /**
   * 计算断点（基于宽度vp）
   */
  private calculateBreakpoint(widthVp: number): NGFBreakpoint {
    if (widthVp < 600) {
      return NGFBreakpoint.XS;
    } else if (widthVp < 840) {
      return NGFBreakpoint.SM;
    } else if (widthVp < 1024) {
      return NGFBreakpoint.MD;
    } else {
      return NGFBreakpoint.LG;
    }
  }

  /**
   * 检查设备信息是否有变化
   */
  private hasDeviceInfoChanged(newInfo: NGFDeviceInfo): boolean {
    if (!this.currentDeviceInfo) {
      return true;
    }

    return this.currentDeviceInfo.deviceType !== newInfo.deviceType ||
      this.currentDeviceInfo.orientation !== newInfo.orientation ||
      this.currentDeviceInfo.breakpoint !== newInfo.breakpoint ||
      this.currentDeviceInfo.foldStatus !== newInfo.foldStatus;
  }

  /**
   * 通知所有监听器
   */
  private notifyListeners(info: NGFDeviceInfo): void {
    this.listeners.forEach((listener: NGFDeviceChangeListener) => {
      try {
        listener(info);
      } catch (error) {
        logger.error(TAG, '监听器回调执行失败', String(error));
      }
    });
  }

  /**
   * 获取当前设备信息
   */
  public getDeviceInfo(): NGFDeviceInfo {
    if (!this.currentDeviceInfo) {
      this.updateDeviceInfo();
    }
    return this.currentDeviceInfo as NGFDeviceInfo;
  }

  /**
   * 添加设备变化监听器
   */
  public addListener(listener: NGFDeviceChangeListener): void {
    this.listeners.add(listener);
    logger.debug(TAG, `添加监听器，当前监听器数量: ${this.listeners.size}`);
  }

  /**
   * 移除设备变化监听器
   */
  public removeListener(listener: NGFDeviceChangeListener): void {
    this.listeners.delete(listener);
    logger.debug(TAG, `移除监听器，当前监听器数量: ${this.listeners.size}`);
  }

  /**
   * 判断是否是手机竖屏
   */
  public isPhonePortrait(): boolean {
    const info: NGFDeviceInfo = this.getDeviceInfo();
    return info.deviceType === NGFDeviceType.PHONE && info.orientation === NGFScreenOrientation.PORTRAIT;
  }

  /**
   * 判断是否是平板、二合一或更大的设备
   */
  public isTabletOrLarger(): boolean {
    const info: NGFDeviceInfo = this.getDeviceInfo();
    return info.isTablet || (info.isFoldable && info.foldStatus !== NGFFoldStatus.FOLDED);
  }

  /**
   * 判断是否是横屏
   */
  public isLandscape(): boolean {
    return this.getDeviceInfo().isLandscape;
  }

  /**
   * 获取当前断点
   */
  public getCurrentBreakpoint(): NGFBreakpoint {
    return this.getDeviceInfo().breakpoint;
  }

  /**
   * 判断当前断点是否大于等于目标断点
   */
  public isBreakpointGreaterOrEqual(targetBreakpoint: NGFBreakpoint): boolean {
    const currentIndex: number = BREAKPOINT_ORDER.indexOf(this.getCurrentBreakpoint());
    const targetIndex: number = BREAKPOINT_ORDER.indexOf(targetBreakpoint);
    return currentIndex >= targetIndex;
  }

  /**
   * 销毁管理器，释放资源
   */
  public destroy(): void {
    if (this.destroyed) {
      return;
    }
    try {
      display.off('change');
      this.listeners.clear();
      this.currentDeviceInfo = null;
      this.displayObj = null;
      this.destroyed = true;
      logger.info(TAG, '设备适配管理器已销毁');
    } catch (error) {
      logger.error(TAG, '销毁设备适配管理器失败', String(error));
    }
  }
}

/**
 * 导出单例门面实例
 */
export const ngfDeviceAdaptationFacade: NGFDeviceAdaptationManager = NGFDeviceAdaptationManager.getInstance();
