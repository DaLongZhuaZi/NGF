import { NGFBreakpoint } from './IDeviceAdaptationManager';

/**
 * 断点布局配置项
 * 为每个断点定义一个值
 */
export class NGFBreakpointLayoutConfig {
  readonly configName: string;
  readonly xs: string;
  readonly sm: string;
  readonly md: string;
  readonly lg: string;

  constructor(configName: string, xs: string, sm: string, md: string, lg: string) {
    this.configName = configName;
    this.xs = xs;
    this.sm = sm;
    this.md = md;
    this.lg = lg;
  }

  resolve(breakpoint: NGFBreakpoint): string {
    if (breakpoint === NGFBreakpoint.LG) {
      return this.lg;
    }
    if (breakpoint === NGFBreakpoint.MD) {
      return this.md;
    }
    if (breakpoint === NGFBreakpoint.SM) {
      return this.sm;
    }
    return this.xs;
  }
}

/**
 * 自适应布局管理接口
 */
export interface IAdaptiveLayout {
  registerConfig(config: NGFBreakpointLayoutConfig): void;
  unregisterConfig(configName: string): boolean;
  resolveConfig(configName: string): string;
  hasConfig(configName: string): boolean;
}
