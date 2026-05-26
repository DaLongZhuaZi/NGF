import { logger } from '../../utils/Logger';
import {
  IPageTransitionManager,
  NGFPageTransitionConfig,
  NGFPageTransitionType
} from '../contracts/IPageTransitionManager';

const TAG: string = 'NGFPageTransitionManagerFacade';

const STORAGE_KEY: string = 'ngf_page_transition_type';

class PageTransitionManagerFacade implements IPageTransitionManager {
  private static instance: PageTransitionManagerFacade | null = null;
  private config: NGFPageTransitionConfig = new NGFPageTransitionConfig();

  private constructor() {
    const saved = AppStorage.get<string>(STORAGE_KEY);
    if (saved && saved.length > 0) {
      this.config = new NGFPageTransitionConfig(saved as NGFPageTransitionType);
    }
  }

  static getInstance(): PageTransitionManagerFacade {
    if (!PageTransitionManagerFacade.instance) {
      PageTransitionManagerFacade.instance = new PageTransitionManagerFacade();
    }
    return PageTransitionManagerFacade.instance;
  }

  setGlobalTransition(type: NGFPageTransitionType): void {
    this.config = new NGFPageTransitionConfig(type, this.config.duration, this.config.curve);
    AppStorage.setOrCreate<string>(STORAGE_KEY, type);
    logger.info(TAG, `全局转场已设置: type=${type}`);
  }

  setGlobalTransitionConfig(config: NGFPageTransitionConfig): void {
    this.config = config;
    AppStorage.setOrCreate<string>(STORAGE_KEY, config.type);
    logger.info(TAG, `全局转场配置已更新: type=${config.type}, duration=${config.duration}`);
  }

  getGlobalTransitionConfig(): NGFPageTransitionConfig {
    return this.config;
  }

  buildEnterTransition(config?: NGFPageTransitionConfig): TransitionEffect {
    const cfg = config ?? this.config;
    return this.resolveEnterEffect(cfg);
  }

  buildExitTransition(config?: NGFPageTransitionConfig): TransitionEffect {
    const cfg = config ?? this.config;
    return this.resolveExitEffect(cfg);
  }

  private resolveEnterEffect(cfg: NGFPageTransitionConfig): TransitionEffect {
    if (cfg.type === NGFPageTransitionType.FADE) {
      return TransitionEffect.OPACITY
        .animation({ duration: cfg.duration, curve: cfg.curve });
    }
    if (cfg.type === NGFPageTransitionType.SCALE) {
      return TransitionEffect.scale({ x: 0.85, y: 0.85 })
        .combine(TransitionEffect.OPACITY)
        .animation({ duration: cfg.duration, curve: cfg.curve });
    }
    if (cfg.type === NGFPageTransitionType.SLIDE_UP) {
      return TransitionEffect.translate({ y: '100%' })
        .combine(TransitionEffect.OPACITY)
        .animation({ duration: cfg.duration, curve: cfg.curve });
    }
    // Default: SLIDE (from right)
    return TransitionEffect.translate({ x: '100%' })
      .animation({ duration: cfg.duration, curve: cfg.curve });
  }

  private resolveExitEffect(cfg: NGFPageTransitionConfig): TransitionEffect {
    if (cfg.type === NGFPageTransitionType.FADE) {
      return TransitionEffect.OPACITY
        .animation({ duration: cfg.duration, curve: cfg.curve });
    }
    if (cfg.type === NGFPageTransitionType.SCALE) {
      return TransitionEffect.scale({ x: 1.08, y: 1.08 })
        .combine(TransitionEffect.OPACITY)
        .animation({ duration: cfg.duration, curve: cfg.curve });
    }
    if (cfg.type === NGFPageTransitionType.SLIDE_UP) {
      return TransitionEffect.translate({ y: '100%' })
        .combine(TransitionEffect.OPACITY)
        .animation({ duration: cfg.duration, curve: cfg.curve });
    }
    // Default: SLIDE (to left)
    return TransitionEffect.translate({ x: '-30%' })
      .combine(TransitionEffect.OPACITY)
      .animation({ duration: cfg.duration, curve: cfg.curve });
  }
}

export const ngfPageTransitionManager: PageTransitionManagerFacade = PageTransitionManagerFacade.getInstance();
