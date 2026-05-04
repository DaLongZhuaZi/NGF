import { ConfigurationConstant } from '@kit.AbilityKit';
import { NGFThemeMode } from '../../Framework/NGF/uiTheme/contracts/IThemeManager';
import { ngfThemeManagerFacade } from '../../Framework/NGF/uiTheme/facades/ThemeManagerFacade';
import { ngfI18nManagerFacade } from '../../Framework/NGF/i18n/facades/I18nManagerFacade';
import { uiContextManager } from '../../Framework/NGF/platformOhos/UIContextManager';
import { logger } from '../../Framework/NGF/utils/Logger';

const TAG: string = 'NGFSettingsPage';

@Component
export struct NGFSettingsPage {
  @StorageProp('ngf_current_theme') private currentTheme: string = 'auto';
  @StorageProp('ngf_current_locale') private currentLocale: string = '';
  @StorageProp('ngf_is_dark_mode') private isDarkMode: boolean = false;
  @StorageProp('ngf_visual_effects_material_mode') private materialMode: string = 'adaptive';
  @StorageProp('ngf_visual_effects_effective_material_level') private effectiveLevel: number = 3;
  @StorageProp('ngf_visual_effects_supports_immersive') private supportsImmersive: boolean = false;
  @StorageProp('ngf_holding_awareness_available') private holdingAvailable: boolean = false;
  @StorageProp('ngf_holding_awareness_detect_gesture_granted') private detectGestureGranted: boolean = false;
  @StorageProp('ngf_holding_awareness_activity_motion_granted') private activityMotionGranted: boolean = false;

  build() {
    Column({ space: 12 }) {
      this.buildThemeCard()
      this.buildLanguageCard()
      this.buildVisualEffectsCard()
      this.buildHoldingCard()
      this.buildAboutCard()
    }
    .width('100%')
    .padding(16)
  }

  @Builder
  private buildThemeCard(): void {
    Column({ space: 8 }) {
      Text('外观主题')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C2430')

      this.buildSettingRow('当前主题', this.describeTheme(this.currentTheme))
      this.buildSettingRow('深色模式', this.isDarkMode ? '是' : '否')
      Row({ space: 8 }) {
        Button('跟随系统')
          .fontSize(13)
          .height(36)
          .backgroundColor(this.currentTheme === NGFThemeMode.AUTO ? '#0B57D0' : '#E6EEF8')
          .fontColor(this.currentTheme === NGFThemeMode.AUTO ? '#FFFFFFFF' : '#1C2430')
          .borderRadius(18)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyTheme(NGFThemeMode.AUTO);
          })
        Button('浅色')
          .fontSize(13)
          .height(36)
          .backgroundColor(this.currentTheme === NGFThemeMode.LIGHT ? '#0B57D0' : '#E6EEF8')
          .fontColor(this.currentTheme === NGFThemeMode.LIGHT ? '#FFFFFFFF' : '#1C2430')
          .borderRadius(18)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyTheme(NGFThemeMode.LIGHT);
          })
        Button('深色')
          .fontSize(13)
          .height(36)
          .backgroundColor(this.currentTheme === NGFThemeMode.DARK ? '#0B57D0' : '#E6EEF8')
          .fontColor(this.currentTheme === NGFThemeMode.DARK ? '#FFFFFFFF' : '#1C2430')
          .borderRadius(18)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyTheme(NGFThemeMode.DARK);
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#D5DEE9' })
  }

  @Builder
  private buildLanguageCard(): void {
    Column({ space: 8 }) {
      Text('语言设置')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C2430')

      this.buildSettingRow('当前语言', this.describeLocale(this.currentLocale))
      Row({ space: 8 }) {
        Button('跟随系统')
          .fontSize(13)
          .height(36)
          .backgroundColor(this.currentLocale === '' ? '#0B57D0' : '#E6EEF8')
          .fontColor(this.currentLocale === '' ? '#FFFFFFFF' : '#1C2430')
          .borderRadius(18)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyLanguage('');
          })
        Button('简体中文')
          .fontSize(13)
          .height(36)
          .backgroundColor(this.currentLocale === 'zh-Hans' ? '#0B57D0' : '#E6EEF8')
          .fontColor(this.currentLocale === 'zh-Hans' ? '#FFFFFFFF' : '#1C2430')
          .borderRadius(18)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyLanguage('zh-Hans');
          })
        Button('English')
          .fontSize(13)
          .height(36)
          .backgroundColor(this.currentLocale === 'en' ? '#0B57D0' : '#E6EEF8')
          .fontColor(this.currentLocale === 'en' ? '#FFFFFFFF' : '#1C2430')
          .borderRadius(18)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyLanguage('en');
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#D5DEE9' })
  }

  @Builder
  private buildVisualEffectsCard(): void {
    Column({ space: 8 }) {
      Text('视觉效果')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C2430')

      Row() {
        Text('沉浸光效')
          .fontSize(14)
          .fontColor('#4F5F73')
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.materialMode === 'adaptive' })
          .selectedColor('#0B57D0')
          .onChange((isOn: boolean): void => {
            this.applyImmersiveToggle(isOn);
          })
      }
      .width('100%')

      this.buildSettingRow('材质模式', this.materialMode === 'adaptive' ? '系统自适应' : '手动固定')
      this.buildSettingRow('当前材质等级', this.describeMaterialLevel(this.effectiveLevel))
      this.buildSettingRow('支持沉浸式材质', this.supportsImmersive ? '是' : '否')

      Text('材质等级')
        .fontSize(14)
        .fontColor('#4F5F73')
        .width('100%')
      Row({ space: 8 }) {
        Button('流畅')
          .fontSize(12)
          .height(32)
          .backgroundColor(this.effectiveLevel === 0 ? '#0B57D0' : '#E6EEF8')
          .fontColor(this.effectiveLevel === 0 ? '#FFFFFFFF' : '#1C2430')
          .borderRadius(16)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyMaterialLevel(0);
          })
        Button('轻柔')
          .fontSize(12)
          .height(32)
          .backgroundColor(this.effectiveLevel === 1 ? '#0B57D0' : '#E6EEF8')
          .fontColor(this.effectiveLevel === 1 ? '#FFFFFFFF' : '#1C2430')
          .borderRadius(16)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyMaterialLevel(1);
          })
        Button('精美')
          .fontSize(12)
          .height(32)
          .backgroundColor(this.effectiveLevel === 2 ? '#0B57D0' : '#E6EEF8')
          .fontColor(this.effectiveLevel === 2 ? '#FFFFFFFF' : '#1C2430')
          .borderRadius(16)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyMaterialLevel(2);
          })
        Button('自适应')
          .fontSize(12)
          .height(32)
          .backgroundColor(this.effectiveLevel === 3 ? '#0B57D0' : '#E6EEF8')
          .fontColor(this.effectiveLevel === 3 ? '#FFFFFFFF' : '#1C2430')
          .borderRadius(16)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyMaterialLevel(3);
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#D5DEE9' })
  }

  @Builder
  private buildHoldingCard(): void {
    Column({ space: 8 }) {
      Text('握持感知')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C2430')

      this.buildSettingRow('传感器可用', this.holdingAvailable ? '是' : '否')
      this.buildSettingRow('DETECT_GESTURE', this.detectGestureGranted ? '已授权' : '未授权')
      this.buildSettingRow('ACTIVITY_MOTION', this.activityMotionGranted ? '已授权' : '未授权')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#D5DEE9' })
  }

  @Builder
  private buildAboutCard(): void {
    Column({ space: 8 }) {
      Text('关于')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C2430')

      this.buildSettingRow('框架名称', 'NGF')
      this.buildSettingRow('版本', '1.0.0')
      this.buildSettingRow('SDK 版本', '6.1.0(23)')
      this.buildSettingRow('HDS 设计系统', '已接入')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#D5DEE9' })
  }

  @Builder
  private buildSettingRow(label: string, value: string): void {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#4F5F73')
        .layoutWeight(1)
      Text(value)
        .fontSize(14)
        .fontColor('#1C2430')
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
  }

  private applyTheme(mode: NGFThemeMode): void {
    try {
      ngfThemeManagerFacade.setThemeOverride(mode);
      const context = uiContextManager.getFullAbilityContext();
      if (context) {
        if (mode === NGFThemeMode.DARK) {
          context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
        } else if (mode === NGFThemeMode.LIGHT) {
          context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
        } else {
          context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
        }
      }
      logger.info(TAG, `主题已切换为: ${this.describeTheme(mode)}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `切换主题失败: ${message}`);
    }
  }

  private applyLanguage(locale: string): void {
    try {
      if (locale.length > 0) {
        ngfI18nManagerFacade.setLocaleOverride(locale);
      } else {
        ngfI18nManagerFacade.clearLocaleOverride();
      }
      logger.info(TAG, `语言已切换为: ${this.describeLocale(locale)}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `切换语言失败: ${message}`);
    }
  }

  private applyImmersiveToggle(enabled: boolean): void {
    try {
      AppStorage.set<string>('ngf_visual_effects_material_mode', enabled ? 'adaptive' : 'manual');
      logger.info(TAG, `沉浸光效已${enabled ? '开启' : '关闭'}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `切换沉浸光效失败: ${message}`);
    }
  }

  private applyMaterialLevel(level: number): void {
    try {
      AppStorage.set<number>('ngf_visual_effects_effective_material_level', level);
      if (level === 3) {
        AppStorage.set<string>('ngf_visual_effects_material_mode', 'adaptive');
      } else {
        AppStorage.set<string>('ngf_visual_effects_material_mode', 'manual');
        AppStorage.set<number>('ngf_visual_effects_manual_material_level', level);
      }
      logger.info(TAG, `材质等级已切换为: ${this.describeMaterialLevel(level)}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `切换材质等级失败: ${message}`);
    }
  }

  private describeTheme(theme: string): string {
    switch (theme) {
      case NGFThemeMode.LIGHT:
        return '浅色';
      case NGFThemeMode.DARK:
        return '深色';
      default:
        return '跟随系统';
    }
  }

  private describeLocale(locale: string): string {
    switch (locale) {
      case 'zh-Hans':
        return '简体中文';
      case 'en':
        return 'English';
      default:
        return '跟随系统';
    }
  }

  private describeMaterialLevel(level: number): string {
    switch (level) {
      case 0:
        return '流畅';
      case 1:
        return '轻柔';
      case 2:
        return '精美';
      case 3:
        return '系统自适应';
      default:
        return `未知(${level})`;
    }
  }
}
