import { ConfigurationConstant } from '@kit.AbilityKit';
import { NGFThemeMode } from '../../Framework/NGF/uiTheme/contracts/IThemeManager';
import { ngfThemeManagerFacade } from '../../Framework/NGF/uiTheme/facades/ThemeManagerFacade';
import { ngfI18nManagerFacade } from '../../Framework/NGF/i18n/facades/I18nManagerFacade';
import { resolveResourceString } from '../../Framework/NGF/i18n/index';
import { uiContextManager } from '../../Framework/NGF/platformOhos/UIContextManager';
import { NGFVisualEffectsMaterialMode } from '../../Framework/NGF/deviceAwareness/contracts/IVisualEffectsManager';
import { ngfVisualEffectsFacade } from '../../Framework/NGF/deviceAwareness/facades/VisualEffectsFacade';
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
  }

  @Builder
  private buildThemeCard(): void {
    Column({ space: 8 }) {
      Text($r('app.string.ui_str_2415'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      this.buildSettingRow($r('app.string.ui_str_2416'), this.describeTheme(this.currentTheme))
      this.buildSettingRow($r('app.string.ui_str_2417'), this.isDarkMode ? $r('app.string.ui_str_2358') : $r('app.string.ui_str_2359'))
      Row({ space: 8 }) {
        Button($r('app.string.ui_str_2418'))
          .fontSize(13)
          .height(36)
          .backgroundColor(this.currentTheme === NGFThemeMode.AUTO ? $r('app.color.button_primary') : $r('app.color.button_inactive_bg'))
          .fontColor(this.currentTheme === NGFThemeMode.AUTO ? $r('app.color.panel_background') : $r('app.color.text_primary'))
          .borderRadius(18)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyTheme(NGFThemeMode.AUTO);
          })
        Button($r('app.string.ui_str_2419'))
          .fontSize(13)
          .height(36)
          .backgroundColor(this.currentTheme === NGFThemeMode.LIGHT ? $r('app.color.button_primary') : $r('app.color.button_inactive_bg'))
          .fontColor(this.currentTheme === NGFThemeMode.LIGHT ? $r('app.color.panel_background') : $r('app.color.text_primary'))
          .borderRadius(18)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyTheme(NGFThemeMode.LIGHT);
          })
        Button($r('app.string.ui_str_2420'))
          .fontSize(13)
          .height(36)
          .backgroundColor(this.currentTheme === NGFThemeMode.DARK ? $r('app.color.button_primary') : $r('app.color.button_inactive_bg'))
          .fontColor(this.currentTheme === NGFThemeMode.DARK ? $r('app.color.panel_background') : $r('app.color.text_primary'))
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
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildLanguageCard(): void {
    Column({ space: 8 }) {
      Text($r('app.string.ui_str_2421'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      this.buildSettingRow($r('app.string.ui_str_2422'), this.describeLocale(this.currentLocale))
      Row({ space: 8 }) {
        Button($r('app.string.ui_str_2418'))
          .fontSize(13)
          .height(36)
          .backgroundColor(this.currentLocale === '' ? $r('app.color.button_primary') : $r('app.color.button_inactive_bg'))
          .fontColor(this.currentLocale === '' ? $r('app.color.panel_background') : $r('app.color.text_primary'))
          .borderRadius(18)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyLanguage('');
          })
        Button($r('app.string.ui_str_2423'))
          .fontSize(13)
          .height(36)
          .backgroundColor(this.currentLocale === 'zh-Hans' ? $r('app.color.button_primary') : $r('app.color.button_inactive_bg'))
          .fontColor(this.currentLocale === 'zh-Hans' ? $r('app.color.panel_background') : $r('app.color.text_primary'))
          .borderRadius(18)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyLanguage('zh-Hans');
          })
        Button('English')
          .fontSize(13)
          .height(36)
          .backgroundColor(this.currentLocale === 'en' ? $r('app.color.button_primary') : $r('app.color.button_inactive_bg'))
          .fontColor(this.currentLocale === 'en' ? $r('app.color.panel_background') : $r('app.color.text_primary'))
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
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildVisualEffectsCard(): void {
    Column({ space: 8 }) {
      Text($r('app.string.ui_str_2350'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Row() {
        Text($r('app.string.ui_str_2424'))
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.materialMode === 'adaptive' })
          .selectedColor($r('app.color.button_primary'))
          .onChange((isOn: boolean): void => {
            this.applyImmersiveToggle(isOn);
          })
      }
      .width('100%')

      this.buildSettingRow($r('app.string.ui_str_2378'), this.materialMode === 'adaptive' ? $r('app.string.ui_str_2379') : $r('app.string.ui_str_2380'))
      this.buildSettingRow($r('app.string.ui_str_2381'), this.describeMaterialLevel(this.effectiveLevel))
      this.buildSettingRow($r('app.string.ui_str_2382'), this.supportsImmersive ? $r('app.string.ui_str_2358') : $r('app.string.ui_str_2359'))

      Text($r('app.string.ui_str_2425'))
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
      Row({ space: 8 }) {
        Button($r('app.string.ui_str_2414'))
          .fontSize(12)
          .height(32)
          .backgroundColor(this.effectiveLevel === 0 ? $r('app.color.button_primary') : $r('app.color.button_inactive_bg'))
          .fontColor(this.effectiveLevel === 0 ? $r('app.color.panel_background') : $r('app.color.text_primary'))
          .borderRadius(16)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyMaterialLevel(0);
          })
        Button($r('app.string.ui_str_2413'))
          .fontSize(12)
          .height(32)
          .backgroundColor(this.effectiveLevel === 1 ? $r('app.color.button_primary') : $r('app.color.button_inactive_bg'))
          .fontColor(this.effectiveLevel === 1 ? $r('app.color.panel_background') : $r('app.color.text_primary'))
          .borderRadius(16)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyMaterialLevel(1);
          })
        Button($r('app.string.ui_str_2412'))
          .fontSize(12)
          .height(32)
          .backgroundColor(this.effectiveLevel === 2 ? $r('app.color.button_primary') : $r('app.color.button_inactive_bg'))
          .fontColor(this.effectiveLevel === 2 ? $r('app.color.panel_background') : $r('app.color.text_primary'))
          .borderRadius(16)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyMaterialLevel(2);
          })
        Button($r('app.string.ui_str_2426'))
          .fontSize(12)
          .height(32)
          .backgroundColor(this.effectiveLevel === 3 ? $r('app.color.button_primary') : $r('app.color.button_inactive_bg'))
          .fontColor(this.effectiveLevel === 3 ? $r('app.color.panel_background') : $r('app.color.text_primary'))
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
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildHoldingCard(): void {
    Column({ space: 8 }) {
      Text($r('app.string.ui_str_2348'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      this.buildSettingRow($r('app.string.ui_str_2357'), this.holdingAvailable ? $r('app.string.ui_str_2358') : $r('app.string.ui_str_2359'))
      this.buildSettingRow('DETECT_GESTURE', this.detectGestureGranted ? $r('app.string.ui_str_2364') : $r('app.string.ui_str_2365'))
      this.buildSettingRow('ACTIVITY_MOTION', this.activityMotionGranted ? $r('app.string.ui_str_2364') : $r('app.string.ui_str_2365'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildAboutCard(): void {
    Column({ space: 8 }) {
      Text($r('app.string.ui_str_2427'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      this.buildSettingRow($r('app.string.ui_str_2428'), 'NGF')
      this.buildSettingRow($r('app.string.ui_str_2429'), '1.0.0')
      this.buildSettingRow($r('app.string.ui_str_2430'), '6.1.0(23)')
      this.buildSettingRow($r('app.string.ui_str_2431'), $r('app.string.ui_str_2432'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.panel_background'))
    .borderRadius(16)
    .border({ width: 1, color: $r('app.color.panel_border') })
  }

  @Builder
  private buildSettingRow(label: ResourceStr, value: ResourceStr): void {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
      Text(value)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
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
      const themeLabel = this.describeTheme(mode);
      logger.info(TAG, `主题已切换为: ${typeof themeLabel === 'string' ? themeLabel : resolveResourceString(this.getUIContext().getHostContext(), themeLabel)}`);
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
      const langLabel = this.describeLocale(locale);
      logger.info(TAG, `语言已切换为: ${typeof langLabel === 'string' ? langLabel : resolveResourceString(this.getUIContext().getHostContext(), langLabel)}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `切换语言失败: ${message}`);
    }
  }

  private applyImmersiveToggle(enabled: boolean): void {
    try {
      ngfVisualEffectsFacade.setMaterialMode(enabled ? NGFVisualEffectsMaterialMode.ADAPTIVE : NGFVisualEffectsMaterialMode.MANUAL);
      const stateLabel: ResourceStr = enabled ? $r('app.string.ui_str_2433') : $r('app.string.ui_str_2434');
      logger.info(TAG, `沉浸光效已${typeof stateLabel === 'string' ? stateLabel : resolveResourceString(this.getUIContext().getHostContext(), stateLabel)}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `切换沉浸光效失败: ${message}`);
    }
  }

  private applyMaterialLevel(level: number): void {
    try {
      if (level === 3) {
        ngfVisualEffectsFacade.setMaterialMode(NGFVisualEffectsMaterialMode.ADAPTIVE);
      } else {
        ngfVisualEffectsFacade.setMaterialMode(NGFVisualEffectsMaterialMode.MANUAL).then(() => {
          ngfVisualEffectsFacade.setManualMaterialLevel(level);
        });
      }
      const levelLabel = this.describeMaterialLevel(level);
      logger.info(TAG, `材质等级已切换为: ${typeof levelLabel === 'string' ? levelLabel : resolveResourceString(this.getUIContext().getHostContext(), levelLabel)}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `切换材质等级失败: ${message}`);
    }
  }

  private describeTheme(theme: string): ResourceStr {
    switch (theme) {
      case NGFThemeMode.LIGHT:
        return $r('app.string.ui_str_2419');
      case NGFThemeMode.DARK:
        return $r('app.string.ui_str_2420');
      default:
        return $r('app.string.ui_str_2418');
    }
  }

  private describeLocale(locale: string): ResourceStr {
    switch (locale) {
      case 'zh-Hans':
        return $r('app.string.ui_str_2423');
      case 'en':
        return 'English';
      default:
        return $r('app.string.ui_str_2418');
    }
  }

  private describeMaterialLevel(level: number): ResourceStr {
    switch (level) {
      case 0:
        return $r('app.string.ui_str_2414');
      case 1:
        return $r('app.string.ui_str_2413');
      case 2:
        return $r('app.string.ui_str_2412');
      case 3:
        return $r('app.string.ui_str_2379');
      default:
        return `未知(${level})`;
    }
  }
}
