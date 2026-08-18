import { common } from '@kit.AbilityKit';
import { logger } from '../../utils/Logger';
import { SettingsManager } from '../../data/SettingsManager';
import { IScreenKeepAwakeManager, NGFScreenKeepAwakeSettingKeys } from '../contracts/IScreenKeepAwakeManager';
import { ngfPlatformWindowManagerFacade } from './PlatformWindowManagerFacade';

const TAG: string = 'NGFScreenKeepAwakeFacade';

export class ScreenKeepAwakeFacade implements IScreenKeepAwakeManager {
  private static instance: ScreenKeepAwakeFacade | null = null;
  private readonly settingsManager: SettingsManager = SettingsManager.getInstance();
  private initialized: boolean = false;
  private initializationPromise: Promise<void> | null = null;
  private abilityContext: common.UIAbilityContext | null = null;
  private enabled: boolean = false;
  private foreground: boolean = false;
  private lifecycleGeneration: number = 0;
  private windowUpdateQueue: Promise<void> = Promise.resolve();

  private constructor() {
  }

  static getInstance(): ScreenKeepAwakeFacade {
    if (ScreenKeepAwakeFacade.instance === null) {
      ScreenKeepAwakeFacade.instance = new ScreenKeepAwakeFacade();
    }
    return ScreenKeepAwakeFacade.instance;
  }

  async initialize(context: common.UIAbilityContext | undefined): Promise<void> {
    // 依赖容器的无参生命周期钩子(NGFServiceLifecycleAware.initialize)可能以 undefined 误调用本方法；
    // 本方法要求有效 AbilityContext 才能初始化 Preferences，无有效上下文时静默返回，
    // 等待宿主 Ability 显式传入有效上下文后再真正初始化，避免污染 abilityContext 与 initializationPromise。
    if (context === undefined || context === null) {
      logger.debug(TAG, 'initialize 忽略：未提供有效的 AbilityContext');
      return;
    }
    this.abilityContext = context;
    if (this.initialized) {
      return;
    }

    const pending = this.initializationPromise;
    if (pending !== null) {
      await pending;
      return;
    }

    const initializationTask: Promise<void> = this.initializeInternal(context);
    this.initializationPromise = initializationTask;
    try {
      await initializationTask;
    } finally {
      this.initializationPromise = null;
    }
  }

  setEnabled(enabled: boolean): Promise<void> {
    return this.setEnabledInternal(enabled);
  }

  isEnabled(): boolean {
    return this.enabled;
  }

  onForeground(): void {
    this.foreground = true;
    this.lifecycleGeneration += 1;
    const generation: number = this.lifecycleGeneration;
    void this.applyForegroundState(generation);
  }

  onBackground(): void {
    this.foreground = false;
    this.lifecycleGeneration += 1;
    void this.enqueueWindowUpdate(false, 'ability_background');
  }

  onWindowStageCreate(): void {
    if (!this.foreground) {
      return;
    }
    this.lifecycleGeneration += 1;
    const generation: number = this.lifecycleGeneration;
    void this.applyForegroundState(generation);
  }

  onWindowStageDestroy(): void {
    this.foreground = false;
    this.lifecycleGeneration += 1;
    void this.enqueueWindowUpdate(false, 'window_stage_destroy');
  }

  private async initializeInternal(context: common.UIAbilityContext): Promise<void> {
    await this.settingsManager.initialize(context);
    this.enabled = this.settingsManager.getBoolean(NGFScreenKeepAwakeSettingKeys.KEEP_SCREEN_ON, false);
    this.syncToAppStorage();
    this.initialized = true;
    logger.info(TAG, '屏幕常亮设置初始化完成: enabled=' + String(this.enabled));
  }

  private async setEnabledInternal(enabled: boolean): Promise<void> {
    const context: common.UIAbilityContext | null = this.abilityContext;
    if (!this.initialized && context !== null) {
      await this.initialize(context);
    }

    this.enabled = enabled;
    this.syncToAppStorage();
    try {
      await this.settingsManager.setBoolean(NGFScreenKeepAwakeSettingKeys.KEEP_SCREEN_ON, enabled);
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, '持久化屏幕常亮设置失败: ' + message);
    }

    if (this.foreground) {
      await this.enqueueWindowUpdate(enabled, 'setting_changed');
    }
    logger.info(TAG, '屏幕常亮设置已更新: enabled=' + String(enabled));
  }

  private async applyForegroundState(generation: number): Promise<void> {
    const context = this.abilityContext;
    if (!this.initialized && context !== null) {
      await this.initialize(context);
    }
    if (!this.foreground || generation !== this.lifecycleGeneration) {
      return;
    }

    if (this.initialized) {
      this.enabled = this.settingsManager.getBoolean(NGFScreenKeepAwakeSettingKeys.KEEP_SCREEN_ON, this.enabled);
      this.syncToAppStorage();
    }
    await this.enqueueWindowUpdate(this.enabled, 'ability_foreground');
  }

  private syncToAppStorage(): void {
    AppStorage.setOrCreate<boolean>(NGFScreenKeepAwakeSettingKeys.KEEP_SCREEN_ON, this.enabled);
  }

  private enqueueWindowUpdate(enabled: boolean, reason: string): Promise<void> {
    const update: Promise<void> = this.windowUpdateQueue.then((): Promise<void> => {
      return ngfPlatformWindowManagerFacade.setWindowKeepScreenOn(enabled);
    });
    this.windowUpdateQueue = update.catch((error: Error): void => {
      const message: string = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, '应用屏幕常亮状态失败: enabled=' + String(enabled) + ', reason=' + reason + ', error=' + message);
    });
    return this.windowUpdateQueue;
  }
}

export const ngfScreenKeepAwakeFacade: ScreenKeepAwakeFacade = ScreenKeepAwakeFacade.getInstance();
