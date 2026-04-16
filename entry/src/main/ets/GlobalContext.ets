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

  getContext(): NGFAbilityContextLike {
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

export function getContext(): NGFAbilityContextLike {
  return globalContextHolder.getContext();
}
