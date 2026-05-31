import { logger } from '../../utils/Logger';
import { IModuleConfig, NGFModuleConfigEntry } from '../contracts/IModuleConfig';

const TAG: string = 'NGFModuleConfigFacade';

export class ModuleConfigFacade implements IModuleConfig {
  private readonly configMap: Map<string, boolean> = new Map<string, boolean>();
  private readonly reasonMap: Map<string, string> = new Map<string, string>();

  loadConfig(jsonContent: string): void {
    const trimmed = jsonContent.trim();
    if (trimmed.length <= 0) {
      logger.warn(TAG, '加载配置忽略: JSON 为空');
      return;
    }
    try {
      const parsed = JSON.parse(trimmed) as object;
      const entries = Object.entries(parsed) as [string, boolean][];
      for (let index = 0; index < entries.length; index++) {
        const entry = entries[index];
        const moduleName = entry[0].trim();
        if (moduleName.length > 0) {
          this.configMap.set(moduleName, entry[1]);
        }
      }
      logger.info(TAG, `加载模块配置: ${entries.length} 项`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `加载模块配置失败: ${message}`);
    }
  }

  isEnabled(moduleName: string): boolean {
    const name = moduleName.trim();
    if (name.length <= 0) {
      return true;
    }
    const enabled = this.configMap.get(name);
    if (enabled === undefined) {
      return true;
    }
    return enabled;
  }

  setEnabled(moduleName: string, enabled: boolean): void {
    const name = moduleName.trim();
    if (name.length <= 0) {
      return;
    }
    this.configMap.set(name, enabled);
    this.reasonMap.delete(name);
    logger.info(TAG, `设置模块状态: ${name}=${enabled}`);
  }

  setDisabled(moduleName: string, reason: string): void {
    const name = moduleName.trim();
    if (name.length <= 0) {
      return;
    }
    this.configMap.set(name, false);
    this.reasonMap.set(name, reason);
    logger.info(TAG, `禁用模块: ${name}, 原因=${reason}`);
  }

  listConfig(): Array<NGFModuleConfigEntry> {
    const result: Array<NGFModuleConfigEntry> = [];
    const keys = this.configMap.keys();
    for (const key of keys) {
      const enabled = this.configMap.get(key) as boolean;
      const reason = this.reasonMap.get(key);
      result.push(new NGFModuleConfigEntry(key, enabled, reason !== undefined ? reason : ''));
    }
    return result;
  }

  reset(): void {
    this.configMap.clear();
    this.reasonMap.clear();
    logger.info(TAG, '重置模块配置');
  }
}

export const ngfModuleConfigFacade: ModuleConfigFacade = new ModuleConfigFacade();
