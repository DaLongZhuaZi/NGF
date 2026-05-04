import { logger } from '../../utils/Logger';
import { ISourceRegistry } from '../contracts/ISourceRegistry';

const TAG: string = 'NGFSourceRegistryFacade';

class NGFSourceRegistryEntry {
  sourceId: string;
  pkg: string;
  registeredAt: number;

  constructor(sourceId: string, pkg: string, registeredAt: number) {
    this.sourceId = sourceId;
    this.pkg = pkg;
    this.registeredAt = registeredAt;
  }
}

export class SourceRegistryFacade implements ISourceRegistry {
  private entries: Map<string, NGFSourceRegistryEntry> = new Map<string, NGFSourceRegistryEntry>();

  registerSource(sourceId: string, pkg: string): boolean {
    const normalizedSourceId = sourceId.trim();
    const normalizedPkg = pkg.trim();
    if (normalizedSourceId.length <= 0 || normalizedPkg.length <= 0) {
      logger.warn(TAG, `注册源忽略: sourceId=${normalizedSourceId}, pkg=${normalizedPkg}`);
      return false;
    }

    const existing = this.entries.get(normalizedSourceId);
    if (existing && existing.pkg === normalizedPkg) {
      logger.debug(TAG, `源已注册: sourceId=${normalizedSourceId}, pkg=${normalizedPkg}`);
      return true;
    }

    if (existing) {
      logger.info(TAG, `更新源包绑定: sourceId=${normalizedSourceId}, pkg=${normalizedPkg}`);
    } else {
      logger.info(TAG, `注册源: sourceId=${normalizedSourceId}, pkg=${normalizedPkg}`);
    }

    this.entries.set(
      normalizedSourceId,
      new NGFSourceRegistryEntry(normalizedSourceId, normalizedPkg, Date.now())
    );
    return true;
  }

  unregisterSource(sourceId: string): boolean {
    const normalizedSourceId = sourceId.trim();
    if (normalizedSourceId.length <= 0) {
      logger.warn(TAG, '注销源忽略: sourceId为空');
      return false;
    }
    if (!this.entries.has(normalizedSourceId)) {
      logger.debug(TAG, `注销源跳过: sourceId=${normalizedSourceId} 未找到`);
      return false;
    }
    this.entries.delete(normalizedSourceId);
    logger.info(TAG, `注销源: sourceId=${normalizedSourceId}`);
    return true;
  }

  hasSource(sourceId: string): boolean {
    const normalizedSourceId = sourceId.trim();
    if (normalizedSourceId.length <= 0) {
      logger.debug(TAG, '检查源存在性忽略: sourceId为空');
      return false;
    }

    const exists = this.entries.has(normalizedSourceId);
    logger.debug(TAG, `检查源存在: sourceId=${normalizedSourceId}, 存在=${exists}`);
    return exists;
  }

  listSourceIds(): string[] {
    const sourceIds = Array.from(this.entries.keys());
    logger.debug(TAG, `列出源ID: 数量=${sourceIds.length}`);
    return sourceIds;
  }
}

export const ngfSourceRegistryFacade = new SourceRegistryFacade();
