import { common } from '@kit.AbilityKit';

export class NGFScreenKeepAwakeSettingKeys {
  static readonly KEEP_SCREEN_ON: string = 'ngf_keep_screen_on';
}

export interface IScreenKeepAwakeManager {
  initialize(context: common.UIAbilityContext | undefined): Promise<void>;
  setEnabled(enabled: boolean): Promise<void>;
  isEnabled(): boolean;
  onForeground(): void;
  onBackground(): void;
  onWindowStageCreate(): void;
  onWindowStageDestroy(): void;
}
