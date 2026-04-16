import { DisplayMode } from './WindowManager';
import { PageWindowPolicy } from './PageWindowPolicy';

export class PageWindowSpec {
  pageName: string;
  policy: PageWindowPolicy;
  fallbackDisplayMode: DisplayMode;

  constructor(pageName: string, policy: PageWindowPolicy, fallbackDisplayMode: DisplayMode) {
    this.pageName = pageName;
    this.policy = policy;
    this.fallbackDisplayMode = fallbackDisplayMode;
  }
}

export class PageWindowRegistry {
  private static initialized: boolean = false;
  private static readonly specs: Map<string, PageWindowSpec> = new Map<string, PageWindowSpec>();

  private static ensureDefaults(): void {
    if (PageWindowRegistry.initialized) {
      return;
    }

    PageWindowRegistry.initialized = true;
    PageWindowRegistry.register(
      new PageWindowSpec('pages/ngf/MainMenuPage', PageWindowPolicy.ROOT_MAIN_MENU, DisplayMode.DEFAULT)
    );
  }

  static register(spec: PageWindowSpec): void {
    PageWindowRegistry.specs.set(spec.pageName, spec);
  }

  static getSpec(pageName: string): PageWindowSpec | null {
    PageWindowRegistry.ensureDefaults();
    const spec = PageWindowRegistry.specs.get(pageName);
    return spec ? spec : null;
  }

  static clear(): void {
    PageWindowRegistry.specs.clear();
    PageWindowRegistry.initialized = false;
  }
}
