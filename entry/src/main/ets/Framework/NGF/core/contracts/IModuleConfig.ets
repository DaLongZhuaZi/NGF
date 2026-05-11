/**
 * 模块配置项
 */
export class NGFModuleConfigEntry {
  readonly moduleName: string;
  readonly enabled: boolean;
  readonly reason: string;

  constructor(moduleName: string, enabled: boolean, reason: string = '') {
    this.moduleName = moduleName;
    this.enabled = enabled;
    this.reason = reason;
  }
}

/**
 * 模块配置管理接口
 */
export interface IModuleConfig {
  loadConfig(jsonContent: string): void;
  isEnabled(moduleName: string): boolean;
  setEnabled(moduleName: string, enabled: boolean): void;
  listConfig(): Array<NGFModuleConfigEntry>;
  reset(): void;
}
