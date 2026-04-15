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
      logger.warn(TAG, `registerSource ignored: sourceId=${normalizedSourceId}, pkg=${normalizedPkg}`);
      return false;
    }

    const existing = this.entries.get(normalizedSourceId);
    if (existing && existing.pkg === normalizedPkg) {
      logger.debug(TAG, `source already registered: sourceId=${normalizedSourceId}, pkg=${normalizedPkg}`);
      return true;
    }

    if (existing) {
      logger.info(TAG, `update source package binding: sourceId=${normalizedSourceId}, pkg=${normalizedPkg}`);
    } else {
      logger.info(TAG, `register source: sourceId=${normalizedSourceId}, pkg=${normalizedPkg}`);
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
      logger.warn(TAG, 'unregisterSource ignored: sourceId is empty');
      return false;
    }
    if (!this.entries.has(normalizedSourceId)) {
      logger.debug(TAG, `unregisterSource skipped: sourceId=${normalizedSourceId} not found`);
      return false;
    }
    this.entries.delete(normalizedSourceId);
    logger.info(TAG, `unregister source: sourceId=${normalizedSourceId}`);
    return true;
  }

  hasSource(sourceId: string): boolean {
    const normalizedSourceId = sourceId.trim();
    if (normalizedSourceId.length <= 0) {
      logger.debug(TAG, 'hasSource check ignored: sourceId is empty');
      return false;
    }

    const exists = this.entries.has(normalizedSourceId);
    logger.debug(TAG, `hasSource: sourceId=${normalizedSourceId}, exists=${exists}`);
    return exists;
  }

  listSourceIds(): string[] {
    const sourceIds = Array.from(this.entries.keys());
    logger.debug(TAG, `listSourceIds: count=${sourceIds.length}`);
    return sourceIds;
  }
}

export const ngfSourceRegistryFacade = new SourceRegistryFacade();
