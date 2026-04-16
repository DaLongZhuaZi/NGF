import { logger } from '../../utils/Logger';
import { DisplayMode } from '../../../../Utils/WindowManager';
import { PageWindowPolicy } from '../../../../Utils/PageWindowPolicy';
import { PageWindowRegistry } from '../../../../Utils/PageWindowRegistry';
import {
  IPageWindowPolicyResolver,
  NGFPageWindowPolicy,
  NGFPageWindowSpec
} from '../contracts/IPageWindowPolicyResolver';
import { NGFDisplayMode } from '../contracts/IPlatformWindowController';

const TAG: string = 'NGFPageWindowPolicyResolverFacade';

export class PageWindowPolicyResolverFacade implements IPageWindowPolicyResolver {
  private overrides: Map<string, NGFPageWindowSpec> = new Map<string, NGFPageWindowSpec>();

  register(spec: NGFPageWindowSpec): void {
    this.overrides.set(spec.pageName, spec);
    logger.info(TAG, `register page policy override: page=${spec.pageName}, policy=${spec.policy}, fallback=${spec.fallbackMode}`);
  }

  resolve(pageName: string): NGFPageWindowSpec | null {
    const overrideSpec = this.overrides.get(pageName);
    if (overrideSpec) {
      logger.debug(TAG, `resolve override policy: page=${pageName}`);
      return overrideSpec;
    }

    const legacySpec = PageWindowRegistry.getSpec(pageName);
    if (!legacySpec) {
      logger.debug(TAG, `resolve policy missed: page=${pageName}`);
      return null;
    }

    const fallbackMode = legacySpec.fallbackDisplayMode
      ? this.toNGFDisplayMode(legacySpec.fallbackDisplayMode)
      : NGFDisplayMode.DEFAULT;
    logger.debug(TAG, `resolve legacy policy: page=${pageName}, fallback=${fallbackMode}`);
    return new NGFPageWindowSpec(pageName, this.toNGFPolicy(legacySpec.policy), fallbackMode);
  }

  has(pageName: string): boolean {
    if (this.overrides.has(pageName)) {
      logger.debug(TAG, `has page policy=true: page=${pageName}, source=override`);
      return true;
    }

    const exists = PageWindowRegistry.getSpec(pageName) !== null;
    logger.debug(TAG, `has page policy=${exists}: page=${pageName}, source=legacy`);
    return exists;
  }

  private toNGFPolicy(policy: PageWindowPolicy): NGFPageWindowPolicy {
    switch (policy) {
      case PageWindowPolicy.FOLLOW_HOST:
        return NGFPageWindowPolicy.KEEP_HOST;
      case PageWindowPolicy.FULLSCREEN_READER:
        return NGFPageWindowPolicy.FULLSCREEN;
      case PageWindowPolicy.FULLSCREEN_READER_WITH_BARS:
        return NGFPageWindowPolicy.IMMERSIVE;
      case PageWindowPolicy.ROOT_MAIN_MENU:
      case PageWindowPolicy.NAV_STANDARD:
      case PageWindowPolicy.NAV_CUSTOM_HEADER:
      case PageWindowPolicy.TRANSIENT_MODAL:
      default:
        return NGFPageWindowPolicy.DEFAULT;
    }
  }

  private toNGFDisplayMode(mode: DisplayMode): NGFDisplayMode {
    switch (mode) {
      case DisplayMode.FULL_IMMERSIVE:
        return NGFDisplayMode.FULL_IMMERSIVE;
      case DisplayMode.IMMERSIVE_WITH_BARS:
        return NGFDisplayMode.IMMERSIVE_WITH_BARS;
      case DisplayMode.STATUS_SAFE_BOTTOM_IMMERSIVE:
        return NGFDisplayMode.STATUS_SAFE_BOTTOM_IMMERSIVE;
      case DisplayMode.DEFAULT:
      case DisplayMode.HIDE_STATUS_BAR:
      case DisplayMode.HIDE_NAVIGATION_BAR:
      default:
        return NGFDisplayMode.DEFAULT;
    }
  }
}

export const ngfPageWindowPolicyResolverFacade = new PageWindowPolicyResolverFacade();
