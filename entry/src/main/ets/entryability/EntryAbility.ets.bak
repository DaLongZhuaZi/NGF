import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { window } from '@kit.ArkUI';
import { clearContext, NGFAbilityContextLike, setContext } from '../GlobalContext';
import { uiContextManager } from '../Framework/Managers/UIContextManager';
import { ngfStarterKernel } from '../Framework/NGF/core/starter/index';
import { logger } from '../Framework/NGF/utils/Logger';

const TAG: string = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    const abilityContext = this.context as NGFAbilityContextLike;
    setContext(abilityContext);
    uiContextManager.bindAbilityContext(abilityContext);
    const bootstrapResult = ngfStarterKernel.bootstrap();
    logger.startup(TAG, 'NGF starter bootstrap', `success=${bootstrapResult}`);

    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `Failed to set colorMode. Cause: ${message}`);
    }
    logger.lifecycle(TAG, 'onCreate');
  }

  onDestroy(): void {
    uiContextManager.clearAbilityContext();
    clearContext();
    logger.lifecycle(TAG, 'onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    logger.lifecycle(TAG, 'onWindowStageCreate');

    windowStage.loadContent('pages/ngf/MainMenuPage', (err: BusinessError): void => {
      if (err.code !== 0) {
        logger.error(TAG, `Failed to load the content. Cause: ${JSON.stringify(err)}`);
        return;
      }
      logger.info(TAG, 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    logger.lifecycle(TAG, 'onWindowStageDestroy');
  }

  onForeground(): void {
    logger.lifecycle(TAG, 'onForeground');
  }

  onBackground(): void {
    logger.lifecycle(TAG, 'onBackground');
  }
}
