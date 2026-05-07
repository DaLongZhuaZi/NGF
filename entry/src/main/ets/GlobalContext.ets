export interface NGFAbilityContextLike {
  filesDir: string;
}

class GlobalContextHolder {
  private static instance: GlobalContextHolder | null = null;
  private abilityContext: NGFAbilityContextLike | null = null;

  static getInstance(): GlobalContextHolder {
    if (!GlobalContextHolder.instance) {
      GlobalContextHolder.instance = new GlobalContextHolder();
    }
    return GlobalContextHolder.instance;
  }

  setContext(context: NGFAbilityContextLike): void {
    this.abilityContext = context;
  }

  clearContext(): void {
    this.abilityContext = null;
  }

  isInitialized(): boolean {
    return this.abilityContext !== null;
  }

  getNGFContext(): NGFAbilityContextLike {
    if (!this.abilityContext) {
      throw new Error('Global context is not initialized');
    }
    return this.abilityContext;
  }
}

const globalContextHolder: GlobalContextHolder = GlobalContextHolder.getInstance();

export function setContext(context: NGFAbilityContextLike): void {
  globalContextHolder.setContext(context);
}

export function clearContext(): void {
  globalContextHolder.clearContext();
}

export function isInitialized(): boolean {
  return globalContextHolder.isInitialized();
}

/**
 * 获取 NGF 全局 AbilityContext
 * @returns NGFAbilityContextLike 能力上下文
 * @throws Error 当全局上下文未初始化时抛出
 * @note API 23 适配：重命名以避免与系统废弃的 getContext() API 混淆
 */
export function getNGFContext(): NGFAbilityContextLike {
  return globalContextHolder.getNGFContext();
}

/**
 * @deprecated 请使用 getNGFContext() 替代，以避免与系统废弃 API 混淆
 */
export function getContext(): NGFAbilityContextLike {
  return globalContextHolder.getNGFContext();
}
