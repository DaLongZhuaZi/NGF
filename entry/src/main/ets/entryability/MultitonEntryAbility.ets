import { AbilityConstant, Configuration, UIAbility, Want, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { window } from '@kit.ArkUI';
import { isInitialized, setContext, NGFAbilityContextLike, clearContext } from '../GlobalContext';
import { uiContextManager, ngfStarterKernel, ngfPlatformWindowManagerFacade, ngfThemeManagerFacade, ngfI18nManagerFacade, ngfHoldingAwarenessFacade, ngfDeviceAdaptationFacade, ngfVisualEffectsFacade, logger, crashAnalytics, ngfContinuationManagerFacade } from 'ngf_framework';

const TAG: string = 'MultitonEntryAbility';

export default class MultitonEntryAbility extends UIAbility {
  private targetPage: string = 'pages/ngf/NGFDemoMultitonPage';

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    logger.lifecycle(TAG, '生命周期: onCreate (Multiton)');
    
    if (want.parameters && typeof want.parameters['targetRouteName'] === 'string') {
      this.targetPage = want.parameters['targetRouteName'] as string;
    }
    if (this.targetPage) {
      logger.info(TAG, '从 Want 中解析到 targetRouteName: ' + this.targetPage);
    }

    if (!isInitialized()) {
      logger.info(TAG, '检测到全局环境未初始化，执行框架初始化');
      const abilityContext = this.context as NGFAbilityContextLike;
      setContext(abilityContext);
      uiContextManager.bindAbilityContext(this.context as common.UIAbilityContext);
      const bootstrapResult = ngfStarterKernel.bootstrap();
      crashAnalytics.initialize();
      logger.startup(TAG, 'NGF 引导启动完成', '成功=' + bootstrapResult);

      ngfThemeManagerFacade.initializeDefaults();
      ngfI18nManagerFacade.initializeDefaults();
      void ngfHoldingAwarenessFacade.initialize();
      void ngfVisualEffectsFacade.initialize();
    } else {
      logger.info(TAG, '全局环境已初始化，仅绑定当前 AbilityContext');
      uiContextManager.bindAbilityContext(this.context as common.UIAbilityContext);
    }
    
    // 解析流转数据
    if (want.parameters) {
      ngfContinuationManagerFacade.receiveContinuationData(want.parameters as Record<string, Object>);
    }

    if (want.parameters && typeof want.parameters['targetTitle'] === 'string') {
      const title = want.parameters['targetTitle'] as string;
      this.context.setMissionLabel(title).then(() => {
        logger.info(TAG, '任务栏名称已更新为: ' + title);
      }).catch((err: Error) => {
        logger.warn(TAG, '设置任务栏名称失败: ' + err.message);
      });
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    logger.lifecycle(TAG, '生命周期: onNewWant (Multiton)');
    if (want.parameters && typeof want.parameters['targetRouteName'] === 'string') {
      this.targetPage = want.parameters['targetRouteName'] as string;
      logger.info(TAG, '从 Want 中解析到新 targetRouteName: ' + this.targetPage);
    }
    if (want.parameters) {
      ngfContinuationManagerFacade.receiveContinuationData(want.parameters as Record<string, Object>);
    }
    if (want.parameters && typeof want.parameters['targetTitle'] === 'string') {
      const title = want.parameters['targetTitle'] as string;
      this.context.setMissionLabel(title).catch(() => {});
    }
  }

  onDestroy(): void {
    uiContextManager.clearAbilityContext();
    // 只有当没有其他实例在使用时才清理，但作为演示直接清理可能影响其他实例
    logger.lifecycle(TAG, '生命周期: onDestroy (Multiton)');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    logger.lifecycle(TAG, '生命周期: onWindowStageCreate (Multiton)');
    
    ngfPlatformWindowManagerFacade.bindWindowStage(windowStage);
    ngfDeviceAdaptationFacade.bindWindowStage(windowStage);

    AppStorage.setOrCreate('CurrentMultitonRoute', this.targetPage);
    
    windowStage.loadContent('pages/ngf/NGFDemoMultitonPage', (err: BusinessError): void => {
      if (err.code !== 0) {
        logger.error(TAG, '加载页面内容失败: ' + JSON.stringify(err));
        return;
      }
      logger.info(TAG, '页面内容加载成功');
    });
  }

  onWindowStageDestroy(): void {
    ngfDeviceAdaptationFacade.clearWindowStage();
    ngfPlatformWindowManagerFacade.clearWindowStage();
    logger.lifecycle(TAG, '生命周期: onWindowStageDestroy (Multiton)');
  }

  onForeground(): void {
    logger.lifecycle(TAG, '生命周期: onForeground (Multiton)');
    ngfDeviceAdaptationFacade.refresh('ability_foreground');
    void ngfHoldingAwarenessFacade.resume();
  }

  onBackground(): void {
    logger.lifecycle(TAG, '生命周期: onBackground (Multiton)');
  }

  onConfigurationUpdate(config: Configuration): void {
    logger.info(TAG, '配置更新: colorMode=' + config.colorMode + ', language=' + config.language);
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
