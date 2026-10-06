import {
  NGFAccessibilityBindingListener,
  NGFAccessibilityLifecycleBinding,
  NGFAccessibilityStateSnapshot,
  NGFA11yTextScale,
  NGFA11yModifierSet,
  NGFInclusiveDesignResolved,
  a11yTouchTarget,
  ngfAccessibilityFacade,
  resolveA11yTextScaleForCurrent
} from 'ngf_framework';
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
import { NGFAccessibilityOptionModifier } from 'ngf_framework';
import { NGFMaterialShadowOptions } from 'ngf_framework';
import { NGFMaterialSurfaceTokens } from 'ngf_framework';
import { NGFSystemMaterialPolicy } from 'ngf_framework';
import { NGFVisualEffectsMaterialMode } from 'ngf_framework';
import { ngfVisualEffectsFacade } from 'ngf_framework';
import { AboutSheetContent } from 'ngf_framework';
import { logger } from 'ngf_framework';
import { ngfScreenKeepAwakeFacade } from 'ngf_framework';

const TAG: string = 'NGFSettingsPage';

@Builder
function buildAboutSheetContent(): void {
  AboutSheetContent()
}

/**
 * `buildSettingRow` 的参数。
 *
 * ## ⚠️ 为什么必须是**对象**而不是两个位置参数（真机实测的 bug）
 *
 * ArkUI 的 `@Builder` 只有**按引用传递参数**时才会建立状态依赖：
 * - `buildSettingRow(label, value)` —— 按值传递 ✗
 *   → 里面渲染的文本**永远停在首次构建的结果**，切换主题/语言后显示行不更新。
 *   2026-10-06 真机实测：点「深色」后按钮的 `selected` 已变成 `true`（功能是通的），
 *   但「当前主题」这一行**仍然显示「跟随系统」**。
 * - `buildSettingRow({ label, value })` —— 按引用传递 ✓ 状态变化会刷新。
 *
 * 这条与根 `AGENTS.md` §7.4 的要求一致：
 * 「动态文本不要通过通用 `@Builder` 方法的字符串参数层层传递后再渲染」。
 */
export interface NGFSettingsRowParams {
  label: ResourceStr;
  value: ResourceStr;
}

@Component
export struct NGFSettingsPage {
  /**
   * 适老呈现层（.rules/skill-elderly-ui.md）：字号 / 行高一律经缩放器取，
   * 普通档原样返回，适老档抬到附件2 §1.1（≥18）与 §1.2（行距 ≥1.3 倍）。
   */
  @State private a11yScale: NGFA11yTextScale = resolveA11yTextScaleForCurrent();
  /**
   * 适老修饰器集（实验：验证 AttributeModifier 路径）。
   *
   * ⚠️ **必须是 @State 字段，不能在 build() 路径里用 getter 现场构造** ——
   * 2026-10-06 实测：在 MainMenuPage 用 getter 构造后，设置页整页渲染异常
   * （文本从 21 条掉到 7 条、大片空白）。这里刻意用字段 + 在策略变化时替换。
   */
  @State private a11yMods: NGFA11yModifierSet = new NGFA11yModifierSet(resolveA11yTextScaleForCurrent());
  private a11yBinding: NGFAccessibilityLifecycleBinding | null = null;

  /** 订阅平台策略变化；与 aboutToDisappear 的 detach 严格成对 */
  private attachA11yBinding(): void {
    if (this.a11yBinding !== null) {
      return;
    }
    const listener: NGFAccessibilityBindingListener = {
      onInclusiveDesignChanged: (resolved: NGFInclusiveDesignResolved): void => {
        this.a11yScale = resolveA11yTextScaleForCurrent();
        this.a11yMods = new NGFA11yModifierSet(this.a11yScale);
      },
      onAccessibilityStateChanged: (snapshot: NGFAccessibilityStateSnapshot): void => {
        this.a11yScale = resolveA11yTextScaleForCurrent();
        this.a11yMods = new NGFA11yModifierSet(this.a11yScale);
      }
    };
    this.a11yBinding = new NGFAccessibilityLifecycleBinding(listener);
    this.a11yBinding.attach();
  }

  /** 取消订阅（幂等） */
  private detachA11yBinding(): void {
    const binding: NGFAccessibilityLifecycleBinding | null = this.a11yBinding;
    if (binding !== null) {
      binding.detach();
      this.a11yBinding = null;
    }
  }

  aboutToAppear(): void {
    this.attachA11yBinding();
  }

  aboutToDisappear(): void {
    this.detachA11yBinding();
  }


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
  @StorageProp('ngf_keep_screen_on') private keepScreenOn: boolean = false;

  build() {
    Column({ space: this.a11yScale.paragraphSpacing(12, 18) }) {
      this.buildThemeCard()
      this.buildLanguageCard()
      this.buildScreenCard()
      this.buildVisualEffectsCard()
      this.buildHoldingCard()
      this.buildAboutCard()
    }
    .width('100%')
  }

  @Builder
  private buildThemeCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
      Text($r('app.string.ui_str_2415'))
        .fontSize(this.a11yScale.font(18))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(18)))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      this.buildSettingRow({ label: $r('app.string.ui_str_2416'), value: this.describeTheme(this.currentTheme) })
      this.buildSettingRow({ label: $r('app.string.ui_str_2417'), value: this.isDarkMode ? $r('app.string.ui_str_2358') : $r('app.string.ui_str_2359') })
      Row({ space: 8 }) {
        Button($r('app.string.ui_str_2418'))
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.currentTheme === NGFThemeMode.AUTO))
          // 附件2 §1.4：颜色不得是唯一区分手段 —— 适老档给选中项再加一层**形状**冗余（描边）
          .border({
            width: this.a11yScale.isElderly && this.currentTheme === NGFThemeMode.AUTO ? 2 : 0,
            color: this.a11yScale.isElderly && this.currentTheme === NGFThemeMode.AUTO ? $r('app.color.button_primary') : $r('app.color.background_transparent')
          })
          .fontColor(this.resolveSegmentButtonFontColor(this.currentTheme === NGFThemeMode.AUTO))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.currentTheme === NGFThemeMode.AUTO))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .layoutWeight(1)
          // 无障碍：选项按钮在无障碍树里是孤立的 —— 补上「组名，选项名」与互斥选中态，
          // 否则读屏只会念「自动」，用户不知道它是「主题」的选项、也不知道当前选的是哪个。
          .attributeModifier(new NGFAccessibilityOptionModifier(
            $r('app.string.ui_str_2416'), $r('app.string.ui_str_2418'), this.currentTheme === NGFThemeMode.AUTO,
            this.getUIContext()?.getHostContext()))
          .onClick((): void => {
            this.applyTheme(NGFThemeMode.AUTO);
          })
        Button($r('app.string.ui_str_2419'))
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.currentTheme === NGFThemeMode.LIGHT))
          // 附件2 §1.4：颜色不得是唯一区分手段 —— 适老档给选中项再加一层**形状**冗余（描边）
          .border({
            width: this.a11yScale.isElderly && this.currentTheme === NGFThemeMode.LIGHT ? 2 : 0,
            color: this.a11yScale.isElderly && this.currentTheme === NGFThemeMode.LIGHT ? $r('app.color.button_primary') : $r('app.color.background_transparent')
          })
          .fontColor(this.resolveSegmentButtonFontColor(this.currentTheme === NGFThemeMode.LIGHT))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.currentTheme === NGFThemeMode.LIGHT))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .layoutWeight(1)
          // 无障碍：选项按钮在无障碍树里是孤立的 —— 补上「组名，选项名」与互斥选中态，
          // 否则读屏只会念「自动」，用户不知道它是「主题」的选项、也不知道当前选的是哪个。
          .attributeModifier(new NGFAccessibilityOptionModifier(
            $r('app.string.ui_str_2416'), $r('app.string.ui_str_2419'), this.currentTheme === NGFThemeMode.LIGHT,
            this.getUIContext()?.getHostContext()))
          .onClick((): void => {
            this.applyTheme(NGFThemeMode.LIGHT);
          })
        Button($r('app.string.ui_str_2420'))
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.currentTheme === NGFThemeMode.DARK))
          // 附件2 §1.4：颜色不得是唯一区分手段 —— 适老档给选中项再加一层**形状**冗余（描边）
          .border({
            width: this.a11yScale.isElderly && this.currentTheme === NGFThemeMode.DARK ? 2 : 0,
            color: this.a11yScale.isElderly && this.currentTheme === NGFThemeMode.DARK ? $r('app.color.button_primary') : $r('app.color.background_transparent')
          })
          .fontColor(this.resolveSegmentButtonFontColor(this.currentTheme === NGFThemeMode.DARK))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.currentTheme === NGFThemeMode.DARK))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .layoutWeight(1)
          // 无障碍：选项按钮在无障碍树里是孤立的 —— 补上「组名，选项名」与互斥选中态，
          // 否则读屏只会念「自动」，用户不知道它是「主题」的选项、也不知道当前选的是哪个。
          .attributeModifier(new NGFAccessibilityOptionModifier(
            $r('app.string.ui_str_2416'), $r('app.string.ui_str_2420'), this.currentTheme === NGFThemeMode.DARK,
            this.getUIContext()?.getHostContext()))
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
  }

  @Builder
  private buildScreenCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
      Text($r('app.string.settings_screen_title'))
        .fontSize(this.a11yScale.font(18))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(18)))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Row() {
        Text($r('app.string.settings_keep_screen_on'))
          .fontSize(this.a11yScale.font(14))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
          .fontColor($r('app.color.text_secondary'))
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.keepScreenOn })
          // 无障碍：开关与左侧文字标签是**兄弟节点**，不关联的话读屏只会念
          // 「开关，关闭」，用户不知道它控制什么。用 accessibilityText 补上标签。
          // （见 .rules/skill-accessibility.md）
          .accessibilityText($r('app.string.settings_keep_screen_on'))
          // 附件2 §2.1：适老版主要组件点击区 ≥60×60（普通档 minWidth/minHeight 为 0，等于不加约束）
          .constraintSize({
            minWidth: a11yTouchTarget(this.a11yScale.isElderly, 0),
            minHeight: a11yTouchTarget(this.a11yScale.isElderly, 0)
          })
          .backgroundColor(Color.Transparent)
          .onChange((isOn: boolean): void => {
            this.applyKeepScreenOnToggle(isOn);
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
  }

  @Builder
  private buildLanguageCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
      // 实验：AttributeModifier 一行下发（对照上面的手工 fontSize + lineHeight）
      Text($r('app.string.ui_str_2421'))
        .attributeModifier(this.a11yMods.text(18))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      this.buildSettingRow({ label: $r('app.string.ui_str_2422'), value: this.describeLocale(this.currentLocale) })
      Row({ space: 8 }) {
        Button($r('app.string.ui_str_2418'))
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.currentLocale === ''))
          // 附件2 §1.4：颜色不得是唯一区分手段 —— 适老档给选中项再加一层**形状**冗余（描边）
          .border({
            width: this.a11yScale.isElderly && this.currentLocale === '' ? 2 : 0,
            color: this.a11yScale.isElderly && this.currentLocale === '' ? $r('app.color.button_primary') : $r('app.color.background_transparent')
          })
          .fontColor(this.resolveSegmentButtonFontColor(this.currentLocale === ''))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.currentLocale === ''))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .layoutWeight(1)
          // 无障碍：选项按钮在无障碍树里是孤立的 —— 补上「组名，选项名」与互斥选中态，
          // 否则读屏只会念「自动」，用户不知道它是「主题」的选项、也不知道当前选的是哪个。
          .attributeModifier(new NGFAccessibilityOptionModifier(
            $r('app.string.ui_str_2422'), $r('app.string.ui_str_2418'), this.currentLocale === '',
            this.getUIContext()?.getHostContext()))
          .onClick((): void => {
            this.applyLanguage('');
          })
        Button($r('app.string.ui_str_2423'))
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.currentLocale === 'zh-Hans'))
          // 附件2 §1.4：颜色不得是唯一区分手段 —— 适老档给选中项再加一层**形状**冗余（描边）
          .border({
            width: this.a11yScale.isElderly && this.currentLocale === 'zh-Hans' ? 2 : 0,
            color: this.a11yScale.isElderly && this.currentLocale === 'zh-Hans' ? $r('app.color.button_primary') : $r('app.color.background_transparent')
          })
          .fontColor(this.resolveSegmentButtonFontColor(this.currentLocale === 'zh-Hans'))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.currentLocale === 'zh-Hans'))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .layoutWeight(1)
          // 无障碍：选项按钮在无障碍树里是孤立的 —— 补上「组名，选项名」与互斥选中态，
          // 否则读屏只会念「自动」，用户不知道它是「主题」的选项、也不知道当前选的是哪个。
          .attributeModifier(new NGFAccessibilityOptionModifier(
            $r('app.string.ui_str_2422'), $r('app.string.ui_str_2423'), this.currentLocale === 'zh-Hans',
            this.getUIContext()?.getHostContext()))
          .onClick((): void => {
            this.applyLanguage('zh-Hans');
          })
        Button($r('app.string.settings_language_english'))
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.currentLocale === 'en'))
          // 附件2 §1.4：颜色不得是唯一区分手段 —— 适老档给选中项再加一层**形状**冗余（描边）
          .border({
            width: this.a11yScale.isElderly && this.currentLocale === 'en' ? 2 : 0,
            color: this.a11yScale.isElderly && this.currentLocale === 'en' ? $r('app.color.button_primary') : $r('app.color.background_transparent')
          })
          .fontColor(this.resolveSegmentButtonFontColor(this.currentLocale === 'en'))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.currentLocale === 'en'))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .layoutWeight(1)
          // 无障碍：选项按钮在无障碍树里是孤立的 —— 补上「组名，选项名」与互斥选中态，
          // 否则读屏只会念「自动」，用户不知道它是「主题」的选项、也不知道当前选的是哪个。
          .attributeModifier(new NGFAccessibilityOptionModifier(
            $r('app.string.ui_str_2422'), $r('app.string.settings_language_english'), this.currentLocale === 'en',
            this.getUIContext()?.getHostContext()))
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
  }

  @Builder
  private buildVisualEffectsCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
      Text($r('app.string.ui_str_2350'))
        .fontSize(this.a11yScale.font(18))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(18)))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Row() {
        Text($r('app.string.ui_str_2424'))
          .fontSize(this.a11yScale.font(14))
          .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
          .fontColor($r('app.color.text_secondary'))
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.materialMode === 'adaptive' })
          // 无障碍：同上的兄弟节点问题，补上标签
          .accessibilityText($r('app.string.ui_str_2424'))
          // 附件2 §2.1：适老版主要组件点击区 ≥60×60
          .constraintSize({
            minWidth: a11yTouchTarget(this.a11yScale.isElderly, 0),
            minHeight: a11yTouchTarget(this.a11yScale.isElderly, 0)
          })
          .backgroundColor(Color.Transparent)
          .onChange((isOn: boolean): void => {
            this.applyImmersiveToggle(isOn);
          })
      }
      .width('100%')

      this.buildSettingRow({ label: $r('app.string.ui_str_2378'), value: this.materialMode === 'adaptive' ? $r('app.string.ui_str_2379') : $r('app.string.ui_str_2380') })
      this.buildSettingRow({ label: $r('app.string.ui_str_2381'), value: this.describeMaterialLevel(this.effectiveLevel) })
      this.buildSettingRow({ label: $r('app.string.ui_str_2382'), value: this.supportsImmersive ? $r('app.string.ui_str_2358') : $r('app.string.ui_str_2359') })
      this.buildSettingRow({ label: $r('app.string.settings_system_material_policy'), value: this.describeSystemMaterialPolicy(this.systemMaterialPolicy) })
      // 适老化长按放大弹窗的触发条件是「系统字体 > 1 倍」。
      // 这一行让人不用敲 hdc 命令就能确认当前值 —— 也是自查测试是否到位的关键读数。
      this.buildSettingRow({ label: $r('app.string.settings_font_scale'), value: this.describeSystemFontScale() })
      this.buildSettingRow({ label: $r('app.string.settings_system_material_state'), value: this.describeSystemMaterialState(this.systemMaterialState) })
      this.buildSettingRow({ label: $r('app.string.settings_system_material_type'), value: this.describeSystemMaterialType(this.systemMaterialType) })

      Row({ space: 8 }) {
        Button($r('app.string.settings_system_material_auto'))
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.systemMaterialPolicy === NGFSystemMaterialPolicy.AUTO))
          // 附件2 §1.4：颜色不得是唯一区分手段 —— 适老档给选中项再加一层**形状**冗余（描边）
          .border({
            width: this.a11yScale.isElderly && this.systemMaterialPolicy === NGFSystemMaterialPolicy.AUTO ? 2 : 0,
            color: this.a11yScale.isElderly && this.systemMaterialPolicy === NGFSystemMaterialPolicy.AUTO ? $r('app.color.button_primary') : $r('app.color.background_transparent')
          })
          .fontColor(this.resolveSegmentButtonFontColor(this.systemMaterialPolicy === NGFSystemMaterialPolicy.AUTO))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.systemMaterialPolicy === NGFSystemMaterialPolicy.AUTO))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .layoutWeight(1)
          .onClick((): void => {
            this.applySystemMaterialPolicy(NGFSystemMaterialPolicy.AUTO);
          })
        Button($r('app.string.settings_system_material_force'))
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.systemMaterialPolicy === NGFSystemMaterialPolicy.FORCE_IMMERSIVE))
          // 附件2 §1.4：颜色不得是唯一区分手段 —— 适老档给选中项再加一层**形状**冗余（描边）
          .border({
            width: this.a11yScale.isElderly && this.systemMaterialPolicy === NGFSystemMaterialPolicy.FORCE_IMMERSIVE ? 2 : 0,
            color: this.a11yScale.isElderly && this.systemMaterialPolicy === NGFSystemMaterialPolicy.FORCE_IMMERSIVE ? $r('app.color.button_primary') : $r('app.color.background_transparent')
          })
          .fontColor(this.resolveSegmentButtonFontColor(this.systemMaterialPolicy === NGFSystemMaterialPolicy.FORCE_IMMERSIVE))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.systemMaterialPolicy === NGFSystemMaterialPolicy.FORCE_IMMERSIVE))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .layoutWeight(1)
          .onClick((): void => {
            this.applySystemMaterialPolicy(NGFSystemMaterialPolicy.FORCE_IMMERSIVE);
          })
        Button($r('app.string.settings_system_material_disabled'))
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.SEGMENT_BUTTON_FONT_SIZE))
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED))
          // 附件2 §1.4：颜色不得是唯一区分手段 —— 适老档给选中项再加一层**形状**冗余（描边）
          .border({
            width: this.a11yScale.isElderly && this.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED ? 2 : 0,
            color: this.a11yScale.isElderly && this.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED ? $r('app.color.button_primary') : $r('app.color.background_transparent')
          })
          .fontColor(this.resolveSegmentButtonFontColor(this.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.systemMaterialPolicy === NGFSystemMaterialPolicy.DISABLED))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .layoutWeight(1)
          .onClick((): void => {
            this.applySystemMaterialPolicy(NGFSystemMaterialPolicy.DISABLED);
          })
      }
      .width('100%')

      Text($r('app.string.ui_str_2425'))
        .fontSize(this.a11yScale.font(14))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
      Row({ space: 8 }) {
        Button($r('app.string.ui_str_2414'))
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE))
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.effectiveLevel === 0))
          // 附件2 §1.4：颜色不得是唯一区分手段 —— 适老档给选中项再加一层**形状**冗余（描边）
          .border({
            width: this.a11yScale.isElderly && this.effectiveLevel === 0 ? 2 : 0,
            color: this.a11yScale.isElderly && this.effectiveLevel === 0 ? $r('app.color.button_primary') : $r('app.color.background_transparent')
          })
          .fontColor(this.resolveSegmentButtonFontColor(this.effectiveLevel === 0))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.effectiveLevel === 0))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyMaterialLevel(0);
          })
        Button($r('app.string.ui_str_2413'))
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE))
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.effectiveLevel === 1))
          // 附件2 §1.4：颜色不得是唯一区分手段 —— 适老档给选中项再加一层**形状**冗余（描边）
          .border({
            width: this.a11yScale.isElderly && this.effectiveLevel === 1 ? 2 : 0,
            color: this.a11yScale.isElderly && this.effectiveLevel === 1 ? $r('app.color.button_primary') : $r('app.color.background_transparent')
          })
          .fontColor(this.resolveSegmentButtonFontColor(this.effectiveLevel === 1))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.effectiveLevel === 1))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyMaterialLevel(1);
          })
        Button($r('app.string.ui_str_2412'))
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE))
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.effectiveLevel === 2))
          // 附件2 §1.4：颜色不得是唯一区分手段 —— 适老档给选中项再加一层**形状**冗余（描边）
          .border({
            width: this.a11yScale.isElderly && this.effectiveLevel === 2 ? 2 : 0,
            color: this.a11yScale.isElderly && this.effectiveLevel === 2 ? $r('app.color.button_primary') : $r('app.color.background_transparent')
          })
          .fontColor(this.resolveSegmentButtonFontColor(this.effectiveLevel === 2))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.effectiveLevel === 2))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
          .layoutWeight(1)
          .onClick((): void => {
            this.applyMaterialLevel(2);
          })
        Button($r('app.string.ui_str_2426'))
          .fontSize(this.a11yScale.font(NGFControlStyleTokens.DENSE_BUTTON_FONT_SIZE))
          .height(a11yTouchTarget(this.a11yScale.isElderly, NGFControlStyleTokens.DENSE_BUTTON_HEIGHT))
          .controlSize(ControlSize.SMALL)
          .backgroundColor(this.resolveSegmentButtonBackground(this.effectiveLevel === 3))
          // 附件2 §1.4：颜色不得是唯一区分手段 —— 适老档给选中项再加一层**形状**冗余（描边）
          .border({
            width: this.a11yScale.isElderly && this.effectiveLevel === 3 ? 2 : 0,
            color: this.a11yScale.isElderly && this.effectiveLevel === 3 ? $r('app.color.button_primary') : $r('app.color.background_transparent')
          })
          .fontColor(this.resolveSegmentButtonFontColor(this.effectiveLevel === 3))
          .fontWeight(this.resolveSegmentButtonFontWeight(this.effectiveLevel === 3))
          .borderRadius(NGFControlStyleTokens.DENSE_BUTTON_RADIUS)
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
  }

  @Builder
  private buildHoldingCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
      Text($r('app.string.ui_str_2348'))
        .fontSize(this.a11yScale.font(18))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(18)))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      this.buildSettingRow({ label: $r('app.string.ui_str_2357'), value: this.holdingAvailable ? $r('app.string.ui_str_2358') : $r('app.string.ui_str_2359') })
      this.buildSettingRow({ label: 'DETECT_GESTURE', value: this.detectGestureGranted ? $r('app.string.ui_str_2364') : $r('app.string.ui_str_2365') })
      this.buildSettingRow({ label: 'ACTIVITY_MOTION', value: this.activityMotionGranted ? $r('app.string.ui_str_2364') : $r('app.string.ui_str_2365') })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.resolveGlassPanelBackground())
    .backgroundEffect(this.buildGlassPanelBackgroundEffect())
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({ width: this.resolveGlassPanelBorderWidth(), color: this.resolveGlassPanelBorderColor() })
    .shadow(this.buildGlassPanelShadow())
  }

  @Builder
  private buildAboutCard(): void {
    Column({ space: this.a11yScale.paragraphSpacing(8, 18) }) {
      Text($r('app.string.ui_str_2427'))
        .fontSize(this.a11yScale.font(18))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(18)))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      this.buildSettingRow({ label: $r('app.string.ui_str_2428'), value: 'NGF' })
      this.buildSettingRow({ label: $r('app.string.ui_str_2429'), value: '1.0.0' })
      this.buildSettingRow({ label: $r('app.string.settings_api_version_label'), value: '26.0.0' })
      this.buildSettingRow({ label: $r('app.string.ui_str_2431'), value: $r('app.string.ui_str_2432') })
      this.buildSettingRow({ label: $r('app.string.api26_visual_migration_title'), value: $r('app.string.api26_visual_migration_done') })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.resolveGlassPanelBackground())
    .backgroundEffect(this.buildGlassPanelBackgroundEffect())
    .borderRadius(NGFMaterialSurfaceTokens.PANEL_RADIUS)
    .border({ width: this.resolveGlassPanelBorderWidth(), color: this.resolveGlassPanelBorderColor() })
    .shadow(this.buildGlassPanelShadow())
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
  private buildSettingRow(params: NGFSettingsRowParams): void {
    Row() {
      Text(params.label)
        .fontSize(this.a11yScale.font(14))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
      Text(params.value)
        .fontSize(this.a11yScale.font(14))
        .lineHeight(this.a11yScale.lineHeight(this.a11yScale.font(14)))
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    // 无障碍分组（官方「使用建议」第 3 条：对复杂布局减少冗余播报）。
    // 不分组时读屏把「标签」与「值」当成**两个独立节点**，
    // 用户会听到一个孤立的「跟随系统」，不知道是什么的「跟随系统」。
    // 分组后拼成「主题 跟随系统」一次播报。
    .accessibilityGroup(true)
  }

  /**
   * 是否改用「系统材质」的透明表面。
   *
   * ⚠️ **不要在这里再写一份判断。**
   * 本方法原先**复制**了 `NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface()` 的逻辑，
   * 于是「普通组件不再使用系统材质」这个决策（项目规则 **PR-006**）传不到本页：
   * 面板背景被判为透明、模糊与描边一并被置空，深色文字直接压在沉浸式渐变上，
   * 实测对比度只有 1.5~2.3:1（附件2 §1.3 要求 4.5:1）。
   * 现统一委托给令牌层，**决策只保留一处**。
   */
  private shouldUseTransparentSystemMaterialSurface(): boolean {
    return NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface();
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

  /**
   * 描述系统字体缩放，并直接说明「长按放大弹窗」能否触发。
   *
   * 触发条件是**系统字体 > 1 倍** —— 关怀模式本身**不够**。
   * 把判断结论直接显示出来，避免测试时靠猜。
   */
  private describeSystemFontScale(): ResourceStr {
    const scale: number = ngfAccessibilityFacade.getSystemFontScale();
    if (scale > 1) {
      return String(scale) + ' × · 长按放大可触发';
    }
    return '1 × · 调大系统字体后长按放大才会触发';
  }

  private applyKeepScreenOnToggle(enabled: boolean): void {
    void ngfScreenKeepAwakeFacade.setEnabled(enabled);
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
