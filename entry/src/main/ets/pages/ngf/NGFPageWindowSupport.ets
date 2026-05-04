import { logger } from '../../Framework/NGF/utils/Logger';
import { ngfPagePolicyHostFacade } from '../../Framework/NGF/uiShell/facades/PagePolicyHostFacade';
import { NGFDisplayMode } from '../../Framework/NGF/platformOhos/contracts/IPlatformWindowController';
import {
  NGFPageWindowProfile,
  NGFWindowOrientationPreference,
  NGFWindowSystemBarPolicy,
  NGFWindowSystemBarStyle
} from '../../Framework/NGF/platformOhos/contracts/IPlatformWindowManager';
import { ngfPlatformWindowManagerFacade } from '../../Framework/NGF/platformOhos/facades/PlatformWindowManagerFacade';
import { NGFHdsDemoRouteName } from './HdsDemoRoutes';

const TAG: string = 'NGFPageWindowSupport';

export class NGFPageWindowName {
  static readonly MAIN_MENU: string = 'pages/ngf/MainMenuPage';
  static readonly HDS_SHOWCASE: string = NGFHdsDemoRouteName.SHOWCASE;
  static readonly HDS_OFFICIAL_NAVIGATION: string = NGFHdsDemoRouteName.OFFICIAL_NAVIGATION;
  static readonly HDS_OFFICIAL_NAVIGATION_OVERVIEW: string = NGFHdsDemoRouteName.OFFICIAL_NAVIGATION_OVERVIEW;
  static readonly HDS_OFFICIAL_NAVIGATION_MATERIAL: string = NGFHdsDemoRouteName.OFFICIAL_NAVIGATION_MATERIAL;
  static readonly HDS_OFFICIAL_NAVIGATION_EFFECT: string = NGFHdsDemoRouteName.OFFICIAL_NAVIGATION_EFFECT;
}

class NGFPageWindowStyleFactory {
  static buildTransparentLightStyle(): NGFWindowSystemBarStyle {
    const style = new NGFWindowSystemBarStyle();
    style.enabled = true;
    style.statusBarColor = '#00000000';
    style.navigationBarColor = '#00000000';
    style.statusBarContentColor = '#FFFFFFFF';
    style.navigationBarContentColor = '#FFFFFFFF';
    style.isStatusBarLightIcon = true;
    style.isNavigationBarLightIcon = true;
    style.enableStatusBarAnimation = true;
    style.enableNavigationBarAnimation = true;
    return style;
  }

  static buildSurfaceDarkTextStyle(): NGFWindowSystemBarStyle {
    const style = new NGFWindowSystemBarStyle();
    style.enabled = true;
    style.statusBarColor = '#FFF8FAFC';
    style.navigationBarColor = '#FFF8FAFC';
    style.statusBarContentColor = '#FF0F172A';
    style.navigationBarContentColor = '#FF0F172A';
    style.isStatusBarLightIcon = false;
    style.isNavigationBarLightIcon = false;
    style.enableStatusBarAnimation = true;
    style.enableNavigationBarAnimation = true;
    return style;
  }
}

export class NGFPageWindowSupport {
  private static initialized: boolean = false;

  static ensureProfilesRegistered(): void {
    if (NGFPageWindowSupport.initialized) {
      return;
    }

    const profiles: Array<NGFPageWindowProfile> = [];
    profiles.push(
      NGFPageWindowSupport.buildProfile(
        NGFPageWindowName.MAIN_MENU,
        NGFDisplayMode.IMMERSIVE_WITH_BARS,
        NGFPageWindowStyleFactory.buildTransparentLightStyle(),
        0
      )
    );
    profiles.push(
      NGFPageWindowSupport.buildProfile(
        NGFPageWindowName.HDS_SHOWCASE,
        NGFDisplayMode.IMMERSIVE_WITH_BARS,
        NGFPageWindowStyleFactory.buildTransparentLightStyle(),
        48
      )
    );
    profiles.push(
      NGFPageWindowSupport.buildProfile(
        NGFPageWindowName.HDS_OFFICIAL_NAVIGATION,
        NGFDisplayMode.IMMERSIVE_WITH_BARS,
        NGFPageWindowStyleFactory.buildTransparentLightStyle(),
        48
      )
    );
    profiles.push(
      NGFPageWindowSupport.buildProfile(
        NGFPageWindowName.HDS_OFFICIAL_NAVIGATION_OVERVIEW,
        NGFDisplayMode.IMMERSIVE_WITH_BARS,
        NGFPageWindowStyleFactory.buildTransparentLightStyle(),
        48
      )
    );
    profiles.push(
      NGFPageWindowSupport.buildProfile(
        NGFPageWindowName.HDS_OFFICIAL_NAVIGATION_MATERIAL,
        NGFDisplayMode.IMMERSIVE_WITH_BARS,
        NGFPageWindowStyleFactory.buildTransparentLightStyle(),
        48
      )
    );
    profiles.push(
      NGFPageWindowSupport.buildProfile(
        NGFPageWindowName.HDS_OFFICIAL_NAVIGATION_EFFECT,
        NGFDisplayMode.IMMERSIVE_WITH_BARS,
        NGFPageWindowStyleFactory.buildTransparentLightStyle(),
        48
      )
    );

    for (let index = 0; index < profiles.length; index++) {
      ngfPlatformWindowManagerFacade.registerPageProfile(profiles[index]);
    }

    NGFPageWindowSupport.initialized = true;
    logger.info(TAG, `注册演示窗口配置: 数量=${profiles.length}`);
  }

  static apply(pageName: string): void {
    NGFPageWindowSupport.ensureProfilesRegistered();
    ngfPagePolicyHostFacade.applyPolicy(pageName);
    ngfPagePolicyHostFacade.reapplyPolicy(pageName);
  }

  static restore(pageName: string): void {
    NGFPageWindowSupport.apply(pageName);
  }

  static restoreMainMenu(): void {
    NGFPageWindowSupport.apply(NGFPageWindowName.MAIN_MENU);
  }

  private static buildProfile(
    pageName: string,
    displayMode: NGFDisplayMode,
    style: NGFWindowSystemBarStyle,
    reapplyDelayMs: number
  ): NGFPageWindowProfile {
    return new NGFPageWindowProfile(
      pageName,
      displayMode,
      NGFWindowOrientationPreference.UNSPECIFIED,
      displayMode !== NGFDisplayMode.DEFAULT,
      NGFPageWindowSupport.buildSystemBarPolicy(displayMode, style),
      reapplyDelayMs
    );
  }

  private static buildSystemBarPolicy(
    displayMode: NGFDisplayMode,
    style: NGFWindowSystemBarStyle
  ): NGFWindowSystemBarPolicy {
    switch (displayMode) {
      case NGFDisplayMode.FULL_IMMERSIVE:
        return new NGFWindowSystemBarPolicy(false, false, false, true, style);
      case NGFDisplayMode.STATUS_SAFE_BOTTOM_IMMERSIVE:
        return new NGFWindowSystemBarPolicy(true, false, false, true, style);
      case NGFDisplayMode.IMMERSIVE_WITH_BARS:
        return new NGFWindowSystemBarPolicy(true, true, true, true, style);
      case NGFDisplayMode.DEFAULT:
      default:
        return new NGFWindowSystemBarPolicy(true, true, true, true, style);
    }
  }
}
