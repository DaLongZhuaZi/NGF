import { logger } from '../../utils/Logger';

const TAG: string = 'NGFComponentThemeOverride';

/**
 * 组件级主题覆盖配置
 * 允许向特定组件下发独立的颜色，而不影响全局主题 Token。
 */
export class NGFComponentThemeOverride {
  readonly backgroundColor: ResourceColor;
  readonly textColor: ResourceColor;
  readonly borderColor: ResourceColor;
  readonly accentColor: ResourceColor;

  constructor(
    backgroundColor: ResourceColor,
    textColor: ResourceColor,
    borderColor: ResourceColor,
    accentColor: ResourceColor
  ) {
    this.backgroundColor = backgroundColor;
    this.textColor = textColor;
    this.borderColor = borderColor;
    this.accentColor = accentColor;
  }
}

/**
 * 预设覆盖主题工厂
 */
export class NGFThemeOverridePresets {
  static danger(): NGFComponentThemeOverride {
    return new NGFComponentThemeOverride('#2D0A0F', '#F43F5E', '#881337', '#FB7185');
  }

  static success(): NGFComponentThemeOverride {
    return new NGFComponentThemeOverride('#051F0D', '#22C55E', '#14532D', '#4ADE80');
  }

  static warning(): NGFComponentThemeOverride {
    return new NGFComponentThemeOverride('#1F1407', '#F59E0B', '#78350F', '#FCD34D');
  }

  static info(): NGFComponentThemeOverride {
    return new NGFComponentThemeOverride('#0A1020', '#3B82F6', '#1E3A8A', '#93C5FD');
  }

  static purple(): NGFComponentThemeOverride {
    return new NGFComponentThemeOverride('#0F0825', '#818CF8', '#312E81', '#C7D2FE');
  }
}

/**
 * 组件级主题覆盖门面
 * 管理多个具名覆盖配置，供 UI 层按 key 获取并应用。
 */
class ComponentThemeOverrideFacade {
  private static instance: ComponentThemeOverrideFacade | null = null;
  private readonly overrides: Map<string, NGFComponentThemeOverride> = new Map<string, NGFComponentThemeOverride>();

  private constructor() {}

  static getInstance(): ComponentThemeOverrideFacade {
    if (!ComponentThemeOverrideFacade.instance) {
      ComponentThemeOverrideFacade.instance = new ComponentThemeOverrideFacade();
    }
    return ComponentThemeOverrideFacade.instance;
  }

  /**
   * 注册一个具名主题覆盖
   */
  registerOverride(name: string, override: NGFComponentThemeOverride): void {
    this.overrides.set(name, override);
    logger.debug(TAG, `注册主题覆盖: name=${name}`);
  }

  /**
   * 获取具名主题覆盖（不存在则返回 null）
   */
  getOverride(name: string): NGFComponentThemeOverride | null {
    const found = this.overrides.get(name);
    return found !== undefined ? found : null;
  }

  /**
   * 获取具名主题覆盖，不存在则返回 fallback
   */
  getOverrideOrDefault(name: string, fallback: NGFComponentThemeOverride): NGFComponentThemeOverride {
    const found = this.overrides.get(name);
    return found !== undefined ? found : fallback;
  }

  /**
   * 移除具名主题覆盖
   */
  removeOverride(name: string): void {
    this.overrides.delete(name);
    logger.debug(TAG, `移除主题覆盖: name=${name}`);
  }

  /**
   * 列出所有已注册的覆盖名称
   */
  listOverrideNames(): Array<string> {
    const names: Array<string> = [];
    const keys = this.overrides.keys();
    for (const key of keys) {
      names.push(key);
    }
    return names;
  }
}

export const ngfComponentThemeOverride: ComponentThemeOverrideFacade = ComponentThemeOverrideFacade.getInstance();
