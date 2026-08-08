import { ConfigurationConstant } from '@kit.AbilityKit';
import { ComponentContent } from '@kit.ArkUI';
import uiMaterial from '@ohos.arkui.uiMaterial';
import { NGFThemeMode } from 'ngf_framework';
import { ngfThemeManagerFacade } from 'ngf_framework';
import { ngfI18nManagerFacade } from 'ngf_framework';
import { resolveResourceString } from 'ngf_framework';
import { uiContextManager } from 'ngf_framework';
import { NGFControlStyleTokens } from 'ngf_framework';
import { NGFMaterialBackgroundEffectOptions } from 'ngf_framework';
import { NGFMaterialSheetOptions } from 'ngf_framework';
import { NGFMaterialShadowOptions } from 'ngf_framework';
import { NGFMaterialSurfaceTokens } from 'ngf_framework';
import { NGFSystemMaterialPolicy } from 'ngf_framework';
import { NGFVisualEffectsMaterialMode } from 'ngf_framework';
import { ngfVisualEffectsFacade } from 'ngf_framework';
import { AboutSheetContent } from 'ngf_framework';
import { logger } from 'ngf_framework';

const TAG: string = 'NGFSettingsPage';

@Builder
function buildAboutSheetContent(): void {
  AboutSheetContent()
}

@Component
export struct NGFSettingsPage {
  @StorageProp('ngf_current_theme') private currentTheme: string = 'auto';
  @StorageProp('ngf_current_locale') private currentLocale: string = '';
  @StorageProp('ngf_is_dark_mode') private isDarkMode: boolean = false;
  @StorageProp('ngf_visual_effects_material_mode') private materialMode: string = 'adaptive';
  @StorageProp('ngf_visual_effects_effective_material_level') private effectiveLevel: number = 3;
  @StorageProp('ngf_visual_effects_supports_immersive') private supportsImmersive: boolean = false;
  @StorageProp('ngf_visual_effects_system_material_policy') private systemMaterialPolicy: string = 'auto';
  @StorageProp('ngf_visual_effects_system_material_state') private systemMaterialState: number = 0;
  @StorageProp('ngf_visual_effects_system_material_type') private systemMaterialType: number = 2;
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
          .fontSize(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE)
          .height(NGFControlStyleTokens.DENSE_BUTTON_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.currentTheme === NGFThemeMode.AUTO))
          .fontColor(this.resolveSegmentButtonFontColor(this.currentTheme === NGFThemeMode.AUTO))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.currentTheme === NGFThemeMode.AUTO))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .systemMaterial(this.resolveSegmentButtonMaterial(this.currentTheme === NGFThemeMode.AUTO))
          .layoutWeight(1)
          .onClick((): void => {
            this.applyTheme(NGFThemeMode.AUTO);
          })
        Button($r('app.string.ui_str_2419'))
          .fontSize(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE)
          .height(NGFControlStyleTokens.DENSE_BUTTON_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.currentTheme === NGFThemeMode.LIGHT))
          .fontColor(this.resolveSegmentButtonFontColor(this.currentTheme === NGFThemeMode.LIGHT))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.currentTheme === NGFThemeMode.LIGHT))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .systemMaterial(this.resolveSegmentButtonMaterial(this.currentTheme === NGFThemeMode.LIGHT))
          .layoutWeight(1)
          .onClick((): void => {
            this.applyTheme(NGFThemeMode.LIGHT);
          })
        Button($r('app.string.ui_str_2420'))
          .fontSize(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE)
          .height(NGFControlStyleTokens.DENSE_BUTTON_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.currentTheme === NGFThemeMode.DARK))
          .fontColor(this.resolveSegmentButtonFontColor(this.currentTheme === NGFThemeMode.DARK))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.currentTheme === NGFThemeMode.DARK))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .systemMaterial(this.resolveSegmentButtonMaterial(this.currentTheme === NGFThemeMode.DARK))
          .layoutWeight(1)
          .onClick((): void => {
            this.applyTheme(NGFThemeMode.DARK);
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.resolveGlassPanelBackground())
    .backgroundEffect(this.buildGlassPanelBackgroundEffect())
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({ width: this.resolveGlassPanelBorderWidth(), color: this.resolveGlassPanelBorderColor() })
    .shadow(this.buildGlassPanelShadow())
    .systemMaterial(ngfVisualEffectsFacade.buildSystemMaterialForPanel())
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
          .fontSize(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE)
          .height(NGFControlStyleTokens.DENSE_BUTTON_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.currentLocale === ''))
          .fontColor(this.resolveSegmentButtonFontColor(this.currentLocale === ''))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.currentLocale === ''))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .systemMaterial(this.resolveSegmentButtonMaterial(this.currentLocale === ''))
          .layoutWeight(1)
          .onClick((): void => {
            this.applyLanguage('');
          })
        Button($r('app.string.ui_str_2423'))
          .fontSize(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE)
          .height(NGFControlStyleTokens.DENSE_BUTTON_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.currentLocale === 'zh-Hans'))
          .fontColor(this.resolveSegmentButtonFontColor(this.currentLocale === 'zh-Hans'))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.currentLocale === 'zh-Hans'))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .systemMaterial(this.resolveSegmentButtonMaterial(this.currentLocale === 'zh-Hans'))
          .layoutWeight(1)
          .onClick((): void => {
            this.applyLanguage('zh-Hans');
          })
        Button($r('app.string.settings_language_english'))
          .fontSize(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE)
          .height(NGFControlStyleTokens.DENSE_BUTTON_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.currentLocale === 'en'))
          .fontColor(this.resolveSegmentButtonFontColor(this.currentLocale === 'en'))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.currentLocale === 'en'))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .systemMaterial(this.resolveSegmentButtonMaterial(this.currentLocale === 'en'))
          .layoutWeight(1)
          .onClick((): void => {
            this.applyLanguage('en');
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.resolveGlassPanelBackground())
    .backgroundEffect(this.buildGlassPanelBackgroundEffect())
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({ width: this.resolveGlassPanelBorderWidth(), color: this.resolveGlassPanelBorderColor() })
    .shadow(this.buildGlassPanelShadow())
    .systemMaterial(ngfVisualEffectsFacade.buildSystemMaterialForPanel())
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
          .backgroundColor(Color.Transparent)
          .systemMaterial(this.resolveDefaultComponentMaterial())
          .onChange((isOn: boolean): void => {
            this.applyImmersiveToggle(isOn);
          })
      }
      .width('100%')

      this.buildSettingRow($r('app.string.ui_str_2378'), this.materialMode === 'adaptive' ? $r('app.string.ui_str_2379') : $r('app.string.ui_str_2380'))
      this.buildSettingRow($r('app.string.ui_str_2381'), this.describeMaterialLevel(this.effectiveLevel))
      this.buildSettingRow($r('app.string.ui_str_2382'), this.supportsImmersive ? $r('app.string.ui_str_2358') : $r('app.string.ui_str_2359'))
      this.buildSettingRow($r('app.string.settings_system_material_policy'), this.describeSystemMaterialPolicy(this.systemMaterialPolicy))
      this.buildSettingRow($r('app.string.settings_system_material_state'), this.describeSystemMaterialState(this.systemMaterialState))
      this.buildSettingRow($r('app.string.settings_system_material_type'), this.describeSystemMaterialType(this.systemMaterialType))

      Row({ space: 8 }) {
        Button($r('app.string.settings_system_material_auto'))
          .fontSize(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE)
          .height(NGFControlStyleTokens.DENSE_BUTTON_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.systemMaterialPolicy === NGFSystemMaterialPolicy.AUTO))
          .fontColor(this.resolveSegmentButtonFontColor(this.systemMaterialPolicy === NGFSystemMaterialPolicy.AUTO))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.systemMaterialPolicy === NGFSystemMaterialPolicy.AUTO))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .systemMaterial(this.resolveSegmentButtonMaterial(this.systemMaterialPolicy === NGFSystemMaterialPolicy.AUTO))
          .layoutWeight(1)
          .onClick((): void => {
            this.applySystemMaterialPolicy(NGFSystemMaterialPolicy.AUTO);
          })
        Button($r('app.string.settings_system_material_force'))
          .fontSize(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE)
          .height(NGFControlStyleTokens.DENSE_BUTTON_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.systemMaterialPolicy === NGFSystemMaterialPolicy.FORCE_IMMERSIVE))
          .fontColor(this.resolveSegmentButtonFontColor(this.systemMaterialPolicy === NGFSystemMaterialPolicy.FORCE_IMMERSIVE))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.systemMaterialPolicy === NGFSystemMaterialPolicy.FORCE_IMMERSIVE))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .systemMaterial(this.resolveSegmentButtonMaterial(this.systemMaterialPolicy === NGFSystemMaterialPolicy.FORCE_IMMERSIVE))
          .layoutWeight(1)
          .onClick((): void => {
            this.applySystemMaterialPolicy(NGFSystemMaterialPolicy.FORCE_IMMERSIVE);
          })
        Button($r('app.string.settings_system_material_disabled'))
          .fontSize(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE)
          .height(NGFControlStyleTokens.DENSE_BUTTON_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED))
          .fontColor(this.resolveSegmentButtonFontColor(this.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .systemMaterial(this.resolveSegmentButtonMaterial(this.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED))
          .layoutWeight(1)
          .onClick((): void => {
            this.applySystemMaterialPolicy(NGFSystemMaterialPolicy.DISABLED);
          })
      }
      .width('100%')

      Text($r('app.string.ui_str_2425'))
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
      Row({ space: 8 }) {
        Button($r('app.string.ui_str_2414'))
          .fontSize(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE)
          .height(NGFControlStyleTokens.DENSE_BUTTON_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.effectiveLevel === 0))
          .fontColor(this.resolveSegmentButtonFontColor(this.effectiveLevel === 0))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.effectiveLevel === 0))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .systemMaterial(this.resolveSegmentButtonMaterial(this.effectiveLevel === 0))
          .layoutWeight(1)
          .onClick((): void => {
            this.applyMaterialLevel(0);
          })
        Button($r('app.string.ui_str_2413'))
          .fontSize(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE)
          .height(NGFControlStyleTokens.DENSE_BUTTON_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.effectiveLevel === 1))
          .fontColor(this.resolveSegmentButtonFontColor(this.effectiveLevel === 1))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.effectiveLevel === 1))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .systemMaterial(this.resolveSegmentButtonMaterial(this.effectiveLevel === 1))
          .layoutWeight(1)
          .onClick((): void => {
            this.applyMaterialLevel(1);
          })
        Button($r('app.string.ui_str_2412'))
          .fontSize(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE)
          .height(NGFControlStyleTokens.DENSE_BUTTON_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.effectiveLevel === 2))
          .fontColor(this.resolveSegmentButtonFontColor(this.effectiveLevel === 2))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.effectiveLevel === 2))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .systemMaterial(this.resolveSegmentButtonMaterial(this.effectiveLevel === 2))
          .layoutWeight(1)
          .onClick((): void => {
            this.applyMaterialLevel(2);
          })
        Button($r('app.string.ui_str_2426'))
          .fontSize(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE)
          .height(NGFControlStyleTokens.DENSE_BUTTON_HEIGHT)
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.effectiveLevel === 3))
          .fontColor(this.resolveSegmentButtonFontColor(this.effectiveLevel === 3))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.effectiveLevel === 3))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .systemMaterial(this.resolveSegmentButtonMaterial(this.effectiveLevel === 3))
          .layoutWeight(1)
          .onClick((): void => {
            this.applyMaterialLevel(3);
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.resolveGlassPanelBackground())
    .backgroundEffect(this.buildGlassPanelBackgroundEffect())
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({ width: this.resolveGlassPanelBorderWidth(), color: this.resolveGlassPanelBorderColor() })
    .shadow(this.buildGlassPanelShadow())
    .systemMaterial(ngfVisualEffectsFacade.buildSystemMaterialForPanel())
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
    .backgroundColor(this.resolveGlassPanelBackground())
    .backgroundEffect(this.buildGlassPanelBackgroundEffect())
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({ width: this.resolveGlassPanelBorderWidth(), color: this.resolveGlassPanelBorderColor() })
    .shadow(this.buildGlassPanelShadow())
    .systemMaterial(ngfVisualEffectsFacade.buildSystemMaterialForPanel())
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
      this.buildSettingRow($r('app.string.settings_api_version_label'), '26.0.0')
      this.buildSettingRow($r('app.string.ui_str_2431'), $r('app.string.ui_str_2432'))
      this.buildSettingRow($r('app.string.api26_visual_migration_title'), $r('app.string.api26_visual_migration_done'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.resolveGlassPanelBackground())
    .backgroundEffect(this.buildGlassPanelBackgroundEffect())
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({ width: this.resolveGlassPanelBorderWidth(), color: this.resolveGlassPanelBorderColor() })
    .shadow(this.buildGlassPanelShadow())
    .systemMaterial(ngfVisualEffectsFacade.buildSystemMaterialForClickablePanel())
    .gesture(
      TapGesture()
        .onAction((_event: GestureEvent): void => {
          this.openAboutSheet();
        })
    )
  }

  private openAboutSheet(): void {
    const uiContext = uiContextManager.getUIContext();
    if (!uiContext) {
      logger.error(TAG, 'openAboutSheet failed: UIContext not found.');
      return;
    }

    try {
      const content = new ComponentContent(uiContext, wrapBuilder(buildAboutSheetContent));
      const options = new NGFMaterialSheetOptions(
        ngfVisualEffectsFacade.buildSystemMaterialForSheet(),
        ngfVisualEffectsFacade.shouldUseSystemMaterialSurface()
      );
      uiContext.openBindSheet(content, options).catch((_err: Error): void => {
        logger.error(TAG, 'openBindSheet promise rejected.');
      });
      logger.info(TAG, 'openAboutSheet triggered.');
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, 'openAboutSheet failed: ' + message);
    }
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

  private shouldUseTransparentSystemMaterialSurface(): boolean {
    if (this.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED) {
      return false;
    }
    if (this.systemMaterialPolicy === NGFSystemMaterialPolicy.FORCE_IMMERSIVE) {
      return true;
    }
    return this.systemMaterialState !== uiMaterial.MaterialState.DISABLE;
  }

  private resolveGlassPanelBackground(): ResourceColor {
    return this.shouldUseTransparentSystemMaterialSurface() ? Color.Transparent : $r('app.color.panel_background');
  }

  private resolveGlassPanelBorderColor(): ResourceColor {
    return this.shouldUseTransparentSystemMaterialSurface() ? Color.Transparent : $r('app.color.panel_border');
  }

  private resolveGlassPanelBorderWidth(): number {
    return this.shouldUseTransparentSystemMaterialSurface() ? 0 : NGFMaterialSurfaceTokens.BORDER_WIDTH;
  }

  private buildGlassPanelBackgroundEffect(): NGFMaterialBackgroundEffectOptions | undefined {
    if (this.shouldUseTransparentSystemMaterialSurface()) {
      return undefined;
    }
    return NGFMaterialSurfaceTokens.buildMaterialAwarePanelBackgroundEffect();
  }

  private buildGlassPanelShadow(): NGFMaterialShadowOptions | undefined {
    if (this.shouldUseTransparentSystemMaterialSurface()) {
      return undefined;
    }
    return NGFMaterialSurfaceTokens.buildMaterialAwarePanelShadow();
  }

  private resolveSegmentButtonBackground(selected: boolean): ResourceColor {
    if (this.shouldUseTransparentSystemMaterialSurface()) {
      return Color.Transparent;
    }
    if (selected) {
      return $r('app.color.background_surface');
    }
    return Color.Transparent;
  }

  private resolveSegmentButtonFontColor(selected: boolean): ResourceColor {
    if (this.shouldUseTransparentSystemMaterialSurface()) {
      return selected ? $r('app.color.text_primary') : $r('app.color.text_secondary');
    }
    return selected ? $r('app.color.text_primary') : $r('app.color.text_secondary');
  }

  private resolveSegmentButtonFontWeight(selected: boolean): FontWeight {
    return selected ? FontWeight.Bold : FontWeight.Normal;
  }

  private resolveSegmentButtonMaterial(selected: boolean): uiMaterial.Material | undefined {
    if (this.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED) {
      return uiMaterial.Material.empty;
    }
    if (!this.shouldUseTransparentSystemMaterialSurface()) {
      return undefined;
    }
    return selected
      ? ngfVisualEffectsFacade.buildSystemMaterialForFloatingControl()
      : ngfVisualEffectsFacade.buildSystemMaterialForLightEffectControl();
  }

  private resolveDefaultComponentMaterial(): uiMaterial.Material | undefined {
    return this.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED ? uiMaterial.Material.empty : undefined;
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
      logger.info(TAG, '主题已切换为: ' + String(typeof themeLabel === 'string' ? themeLabel : resolveResourceString(this.getUIContext().getHostContext(), themeLabel)));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, '切换主题失败: ' + message);
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
      logger.info(TAG, '语言已切换为: ' + String(typeof langLabel === 'string' ? langLabel : resolveResourceString(this.getUIContext().getHostContext(), langLabel)));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, '切换语言失败: ' + message);
    }
  }

  private applyImmersiveToggle(enabled: boolean): void {
    try {
      ngfVisualEffectsFacade.setMaterialMode(enabled ? NGFVisualEffectsMaterialMode.ADAPTIVE : NGFVisualEffectsMaterialMode.MANUAL);
      const stateLabel: ResourceStr = enabled ? $r('app.string.ui_str_2433') : $r('app.string.ui_str_2434');
      logger.info(TAG, '沉浸光效已' + String(typeof stateLabel === 'string' ? stateLabel : resolveResourceString(this.getUIContext().getHostContext(), stateLabel)));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, '切换沉浸光效失败: ' + message);
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
      logger.info(TAG, '材质等级已切换为: ' + String(typeof levelLabel === 'string' ? levelLabel : resolveResourceString(this.getUIContext().getHostContext(), levelLabel)));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, '切换材质等级失败: ' + message);
    }
  }

  private applySystemMaterialPolicy(policy: NGFSystemMaterialPolicy): void {
    try {
      ngfVisualEffectsFacade.setSystemMaterialPolicy(policy);
      const policyLabel = this.describeSystemMaterialPolicy(policy);
      logger.info(TAG, '系统材质策略已切换为: ' + String(typeof policyLabel === 'string' ? policyLabel : resolveResourceString(this.getUIContext().getHostContext(), policyLabel)));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, '切换系统材质策略失败: ' + message);
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
        return $r('app.string.settings_language_english');
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
        return '未知(' + level + ')';
    }
  }

  private describeSystemMaterialPolicy(policy: string): ResourceStr {
    switch (policy) {
      case NGFSystemMaterialPolicy.FORCE_IMMERSIVE:
        return $r('app.string.settings_system_material_force');
      case NGFSystemMaterialPolicy.DISABLED:
        return $r('app.string.settings_system_material_disabled');
      default:
        return $r('app.string.settings_system_material_auto');
    }
  }

  private describeSystemMaterialState(state: number): string {
    switch (state) {
      case uiMaterial.MaterialState.ENABLE:
        return 'ENABLE';
      case uiMaterial.MaterialState.DISABLE:
        return 'DISABLE';
      default:
        return 'DEFAULT';
    }
  }

  private describeSystemMaterialType(type: number): string {
    if (type === uiMaterial.MaterialType.IMMERSIVE) {
      return 'IMMERSIVE';
    }
    return String(type);
  }
}
