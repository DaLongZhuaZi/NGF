import { logger } from '../../utils/Logger';
import {
  IPageWindowPolicyResolver,
  NGFPageWindowPolicy,
  NGFPageWindowSpec
} from '../contracts/IPageWindowPolicyResolver';
import { NGFDisplayMode } from '../contracts/IPlatformWindowController';

const TAG: string = 'NGFPageWindowPolicyResolverFacade';

// Legacy types inlined from Utils/ for backward-compatible policy mapping

enum LegacyDisplayMode {
  DEFAULT = 'default',
  FULL_IMMERSIVE = 'full_immersive',
  IMMERSIVE_WITH_BARS = 'immersive_with_bars',
  STATUS_SAFE_BOTTOM_IMMERSIVE = 'status_safe_bottom_immersive',
  HIDE_STATUS_BAR = 'hide_status_bar',
  HIDE_NAVIGATION_BAR = 'hide_navigation_bar'
}

enum LegacyPageWindowPolicy {
  FOLLOW_HOST = 'follow_host',
  FULLSCREEN_READER = 'fullscreen_reader',
  FULLSCREEN_READER_WITH_BARS = 'fullscreen_reader_with_bars',
  ROOT_MAIN_MENU = 'root_main_menu',
  NAV_STANDARD = 'nav_standard',
  NAV_CUSTOM_HEADER = 'nav_custom_header',
  TRANSIENT_MODAL = 'transient_modal'
}

class LegacyPageWindowSpec {
  pageName: string;
  policy: LegacyPageWindowPolicy;
  fallbackDisplayMode: LegacyDisplayMode;

  constructor(pageName: string, policy: LegacyPageWindowPolicy, fallbackDisplayMode: LegacyDisplayMode) {
    this.pageName = pageName;
    this.policy = policy;
    this.fallbackDisplayMode = fallbackDisplayMode;
  }
}

class LegacyPageWindowRegistry {
  private static initialized: boolean = false;
  private static readonly specs: Map<string, LegacyPageWindowSpec> = new Map<string, LegacyPageWindowSpec>();

  private static ensureDefaults(): void {
    if (LegacyPageWindowRegistry.initialized) {
      return;
    }
    LegacyPageWindowRegistry.initialized = true;
    LegacyPageWindowRegistry.register(
      new LegacyPageWindowSpec('pages/ngf/MainMenuPage', LegacyPageWindowPolicy.ROOT_MAIN_MENU, LegacyDisplayMode.DEFAULT)
    );
  }

  static register(spec: LegacyPageWindowSpec): void {
    LegacyPageWindowRegistry.specs.set(spec.pageName, spec);
  }

  static getSpec(pageName: string): LegacyPageWindowSpec | null {
    LegacyPageWindowRegistry.ensureDefaults();
    const spec = LegacyPageWindowRegistry.specs.get(pageName);
    return spec ? spec : null;
  }
}

export class PageWindowPolicyResolverFacade implements IPageWindowPolicyResolver {
  private overrides: Map<string, NGFPageWindowSpec> = new Map<string, NGFPageWindowSpec>();

  register(spec: NGFPageWindowSpec): void {
    this.overrides.set(spec.pageName, spec);
    logger.info(TAG, `注册页面策略覆盖: page=${spec.pageName}, policy=${spec.policy}, fallback=${spec.fallbackMode}`);
  }

  resolve(pageName: string): NGFPageWindowSpec | null {
    const overrideSpec = this.overrides.get(pageName);
    if (overrideSpec) {
      logger.debug(TAG, `解析覆盖策略: page=${pageName}`);
      return overrideSpec;
    }

    const legacySpec = LegacyPageWindowRegistry.getSpec(pageName);
    if (!legacySpec) {
      logger.debug(TAG, `解析策略未命中: page=${pageName}`);
      return null;
    }

    const fallbackMode = legacySpec.fallbackDisplayMode
      ? this.toNGFDisplayMode(legacySpec.fallbackDisplayMode)
      : NGFDisplayMode.DEFAULT;
    logger.debug(TAG, `解析旧版策略: page=${pageName}, fallback=${fallbackMode}`);
    return new NGFPageWindowSpec(pageName, this.toNGFPolicy(legacySpec.policy), fallbackMode);
  }

  has(pageName: string): boolean {
    if (this.overrides.has(pageName)) {
      logger.debug(TAG, `页面策略存在=true: page=${pageName}, 来源=覆盖`);
      return true;
    }

    const exists = LegacyPageWindowRegistry.getSpec(pageName) !== null;
    logger.debug(TAG, `页面策略存在=${exists}: page=${pageName}, 来源=旧版`);
    return exists;
  }

  private toNGFPolicy(policy: LegacyPageWindowPolicy): NGFPageWindowPolicy {
    switch (policy) {
      case LegacyPageWindowPolicy.FOLLOW_HOST:
        return NGFPageWindowPolicy.KEEP_HOST;
      case LegacyPageWindowPolicy.FULLSCREEN_READER:
        return NGFPageWindowPolicy.FULLSCREEN;
      case LegacyPageWindowPolicy.FULLSCREEN_READER_WITH_BARS:
        return NGFPageWindowPolicy.IMMERSIVE;
      case LegacyPageWindowPolicy.ROOT_MAIN_MENU:
      case LegacyPageWindowPolicy.NAV_STANDARD:
      case LegacyPageWindowPolicy.NAV_CUSTOM_HEADER:
      case LegacyPageWindowPolicy.TRANSIENT_MODAL:
      default:
        return NGFPageWindowPolicy.DEFAULT;
    }
  }

  private toNGFDisplayMode(mode: LegacyDisplayMode): NGFDisplayMode {
    switch (mode) {
      case LegacyDisplayMode.FULL_IMMERSIVE:
        return NGFDisplayMode.FULL_IMMERSIVE;
      case LegacyDisplayMode.IMMERSIVE_WITH_BARS:
        return NGFDisplayMode.IMMERSIVE_WITH_BARS;
      case LegacyDisplayMode.STATUS_SAFE_BOTTOM_IMMERSIVE:
        return NGFDisplayMode.STATUS_SAFE_BOTTOM_IMMERSIVE;
      case LegacyDisplayMode.DEFAULT:
      case LegacyDisplayMode.HIDE_STATUS_BAR:
      case LegacyDisplayMode.HIDE_NAVIGATION_BAR:
      default:
        return NGFDisplayMode.DEFAULT;
    }
  }
}

export const ngfPageWindowPolicyResolverFacade = new PageWindowPolicyResolverFacade();
