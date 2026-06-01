import { AbilityConstant, Configuration, UIAbility, Want, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { window } from '@kit.ArkUI';
import { logger } from 'ngf_framework';
import { uiContextManager } from 'ngf_framework';

const TAG: string = 'MultitonEntryAbility';

export default class MultitonEntryAbility extends UIAbility {
  private targetPage: string = 'pages/ngf/NGFDemoMultitonPage';

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    logger.lifecycle(TAG, '生命周期: onCreate (Multiton)');
    
    if (want.parameters && typeof want.parameters['targetRouteName'] === 'string') {
      this.targetPage = want.parameters['targetRouteName'] as string;
    }
    if (this.targetPage) {
      logger.info(TAG, `从 Want 中解析到 targetRouteName: ${this.targetPage}`);
    }

    // 作为一个新的实例启动，我们可以在此处进行一些特定的初始化
    uiContextManager.bindAbilityContext(this.context as common.UIAbilityContext);
    
    if (want.parameters && typeof want.parameters['targetTitle'] === 'string') {
      const title = want.parameters['targetTitle'] as string;
      this.context.setMissionLabel(title).then(() => {
        logger.info(TAG, `任务栏名称已更新为: ${title}`);
      }).catch((err: Error) => {
        logger.warn(TAG, `设置任务栏名称失败: ${err.message}`);
      });
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    logger.lifecycle(TAG, '生命周期: onNewWant (Multiton)');
    if (want.parameters && typeof want.parameters['targetRouteName'] === 'string') {
      this.targetPage = want.parameters['targetRouteName'] as string;
      logger.info(TAG, `从 Want 中解析到新 targetRouteName: ${this.targetPage}`);
    }
    if (want.parameters && typeof want.parameters['targetTitle'] === 'string') {
      const title = want.parameters['targetTitle'] as string;
      this.context.setMissionLabel(title).catch(() => {});
    }
  }

  onDestroy(): void {
    uiContextManager.clearAbilityContext();
    logger.lifecycle(TAG, '生命周期: onDestroy (Multiton)');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    logger.lifecycle(TAG, '生命周期: onWindowStageCreate (Multiton)');
    
    // 我们不绑定全局的 ngfPlatformWindowManagerFacade，因为全局的 WindowManager 可能主要用于单例主窗口
    // 在实际复杂项目中，如果是 Multiton，可能需要实例化的 WindowManager。但作为演示，我们加载指定页面
    AppStorage.setOrCreate('CurrentMultitonRoute', this.targetPage);
    
    windowStage.loadContent('pages/ngf/NGFDemoMultitonPage', (err: BusinessError): void => {
      if (err.code !== 0) {
        logger.error(TAG, `加载页面内容失败: ${JSON.stringify(err)}`);
        return;
      }
      logger.info(TAG, '页面内容加载成功');
      
      try {
        let mainWindow = windowStage.getMainWindowSync();
        mainWindow.setWindowLayoutFullScreen(true);
        let sysBarProps: window.SystemBarProperties = {
          statusBarColor: '#00000000',
          navigationBarColor: '#00000000',
          isStatusBarLightIcon: true,
          isNavigationBarLightIcon: true
        };
        mainWindow.setWindowSystemBarProperties(sysBarProps);
      } catch (e) {
        logger.error(TAG, `配置窗口失败: ${e}`);
      }
    });
  }

  onWindowStageDestroy(): void {
    logger.lifecycle(TAG, '生命周期: onWindowStageDestroy (Multiton)');
  }

  onForeground(): void {
    logger.lifecycle(TAG, '生命周期: onForeground (Multiton)');
  }

  onBackground(): void {
    logger.lifecycle(TAG, '生命周期: onBackground (Multiton)');
  }

  onConfigurationUpdate(config: Configuration): void {
    logger.info(TAG, `配置更新: colorMode=${config.colorMode}, language=${config.language}`);
  }
}
