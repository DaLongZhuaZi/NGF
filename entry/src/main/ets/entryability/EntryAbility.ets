import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { window } from '@kit.ArkUI';
import { clearContext, NGFAbilityContextLike, setContext } from '../GlobalContext';
import { uiContextManager } from '../Framework/NGF/platformOhos/UIContextManager';
import { ngfStarterKernel } from '../Framework/NGF/core/starter/index';
import { ngfPlatformWindowManagerFacade } from '../Framework/NGF/platformOhos';
import { ngfThemeManagerFacade } from '../Framework/NGF/uiTheme/facades/ThemeManagerFacade';
import { ngfI18nManagerFacade } from '../Framework/NGF/i18n/facades/I18nManagerFacade';
import { ngfHoldingAwarenessFacade } from '../Framework/NGF/deviceAwareness/facades/HoldingAwarenessFacade';
import { ngfDeviceAdaptationFacade } from '../Framework/NGF/deviceAwareness/facades/DeviceAdaptationFacade';
import { ngfVisualEffectsFacade } from '../Framework/NGF/deviceAwareness/facades/VisualEffectsFacade';
import { logger } from '../Framework/NGF/utils/Logger';

const TAG: string = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    const abilityContext = this.context as NGFAbilityContextLike;
    setContext(abilityContext);
    uiContextManager.bindAbilityContext(abilityContext);
    const bootstrapResult = ngfStarterKernel.bootstrap();
    logger.startup(TAG, 'NGF 引导启动完成', `成功=${bootstrapResult}`);

    /**
     * API 23 适配说明：
     * getApplicationContext().setColorMode() 在 API 21 已废弃
     * 颜色模式现在通过 ThemeManagerFacade 统一管理
     * 系统颜色模式变化通过 onConfigurationUpdate 监听
     */
    logger.info(TAG, '颜色模式由 ThemeManagerFacade 统一管理，无需手动设置');

    ngfThemeManagerFacade.initializeDefaults();
    ngfI18nManagerFacade.initializeDefaults();
    void ngfHoldingAwarenessFacade.initialize();
    void ngfVisualEffectsFacade.initialize();

    logger.lifecycle(TAG, '生命周期: onCreate');
  }

  onDestroy(): void {
    ngfHoldingAwarenessFacade.destroy();
    uiContextManager.clearAbilityContext();
    clearContext();
    logger.lifecycle(TAG, '生命周期: onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    logger.lifecycle(TAG, '生命周期: onWindowStageCreate');
    ngfPlatformWindowManagerFacade.bindWindowStage(windowStage);
    ngfDeviceAdaptationFacade.bindWindowStage(windowStage);

    windowStage.loadContent('pages/ngf/MainMenuPage', (err: BusinessError): void => {
      if (err.code !== 0) {
        logger.error(TAG, `加载页面内容失败: ${JSON.stringify(err)}`);
        return;
      }
      logger.info(TAG, '页面内容加载成功');
    });
  }

  onWindowStageDestroy(): void {
    ngfDeviceAdaptationFacade.clearWindowStage();
    ngfPlatformWindowManagerFacade.clearWindowStage();
    logger.lifecycle(TAG, '生命周期: onWindowStageDestroy');
  }

  onForeground(): void {
    logger.lifecycle(TAG, '生命周期: onForeground');
    ngfDeviceAdaptationFacade.refresh('ability_foreground');
    void ngfHoldingAwarenessFacade.resume();
  }

  onBackground(): void {
    logger.lifecycle(TAG, '生命周期: onBackground');
  }

  onConfigurationUpdate(config: Configuration): void {
    logger.info(TAG, `配置更新: colorMode=${config.colorMode}, language=${config.language}`);
    ngfDeviceAdaptationFacade.refresh('configuration_update');

    const colorMode = config.colorMode;
    if (colorMode !== undefined) {
      ngfThemeManagerFacade.handleSystemColorModeChanged(colorMode);
    }

    const language = config.language;
    if (language !== undefined) {
      ngfI18nManagerFacade.handleSystemLocaleChanged(language);
    }
  }
}
