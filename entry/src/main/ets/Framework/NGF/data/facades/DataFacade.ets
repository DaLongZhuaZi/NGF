import { logger } from '../../utils/Logger';
import { relationalStore } from '@kit.ArkData';
import { securityToolkit } from '../../utils/SecurityToolkit';
import { SettingsManager } from '../SettingsManager';
import { IDataFacade, NGFDataQueryResult, NGFPaginationParams, NGFPaginatedResult } from '../contracts/IDataFacade';
import { ngfSettingsStoreFacade } from './SettingsStoreFacade';

const TAG = 'NGFDataFacade';
const SETTINGS_ENTITY_NAME = 'settings';

class NGFDataEntityEnvelope {
  id: string;
  payloadJson: string;

  constructor(id: string, payloadJson: string) {
    this.id = id;
    this.payloadJson = payloadJson;
  }
}

class NGFDataEntityCollection {
  items: Array<NGFDataEntityEnvelope> = [];
}

class NGFDataQueryEnvelope {
  id: string;

  constructor(id: string) {
    this.id = id;
  }
}

class NGFSettingsQueryEnvelope {
  key: string;
  valueType: string;
  defaultString: string;
  defaultNumber: number;
  defaultBoolean: boolean;

  constructor(key: string, valueType: string, defaultString: string, defaultNumber: number, defaultBoolean: boolean) {
    this.key = key;
    this.valueType = valueType;
    this.defaultString = defaultString;
    this.defaultNumber = defaultNumber;
    this.defaultBoolean = defaultBoolean;
  }
}

class NGFSettingsWriteEnvelope {
  key: string;
  valueType: string;
  stringValue: string;
  numberValue: number;
  booleanValue: boolean;

  constructor(key: string, valueType: string, stringValue: string, numberValue: number, booleanValue: boolean) {
    this.key = key;
    this.valueType = valueType;
    this.stringValue = stringValue;
    this.numberValue = numberValue;
    this.booleanValue = booleanValue;
  }
}

class NGFSettingsResponseEnvelope {
  key: string;
  valueType: string;
  stringValue: string;
  numberValue: number;
  booleanValue: boolean;

  constructor(key: string, valueType: string, stringValue: string, numberValue: number, booleanValue: boolean) {
    this.key = key;
    this.valueType = valueType;
    this.stringValue = stringValue;
    this.numberValue = numberValue;
    this.booleanValue = booleanValue;
  }
}

export class DataFacade implements IDataFacade {
  private readonly settingsManager: SettingsManager = SettingsManager.getInstance();
  private readonly entityStores: Map<string, Map<string, string>> = new Map<string, Map<string, string>>();
  private rdbStore: relationalStore.RdbStore | undefined = undefined;
  private rdbAvailable: boolean = false;

  async query(entityName: string, queryJson: string): Promise<NGFDataQueryResult> {
    const normalizedEntity = this.normalizeEntityName(entityName);
    logger.debug(TAG, `查询数据: entity=${normalizedEntity}`);
    if (this.isSettingsEntity(normalizedEntity)) {
      const settingsQuery = this.parseSettingsQueryEnvelope(queryJson);
      if (settingsQuery.key.length <= 0) {
        logger.warn(TAG, '查询设置忽略: key为空');
        return new NGFDataQueryResult(false, '');
      }

      const settingsResponse = this.querySettings(settingsQuery);
      logger.info(TAG, `查询设置成功: key=${settingsQuery.key}, type=${settingsQuery.valueType}`);
      return new NGFDataQueryResult(true, JSON.stringify(settingsResponse));
    }

    const queryEnvelope = this.parseQueryEnvelope(queryJson);
    const entityStore = this.ensureEntityStore(normalizedEntity);
    if (queryEnvelope.id.length > 0) {
      const payloadJson = entityStore.get(queryEnvelope.id);
      if (!payloadJson) {
        logger.debug(TAG, `查询实体未命中: entity=${normalizedEntity}, id=${queryEnvelope.id}`);
        return new NGFDataQueryResult(false, '');
      }
      const response = new NGFDataEntityEnvelope(queryEnvelope.id, payloadJson);
      logger.info(TAG, `查询实体成功: entity=${normalizedEntity}, id=${queryEnvelope.id}`);
      return new NGFDataQueryResult(true, JSON.stringify(response));
    }

    logger.info(TAG, `查询实体集合: entity=${normalizedEntity}, 数量=${entityStore.size}`);
    return new NGFDataQueryResult(true, this.serializeEntityCollection(entityStore));
  }

  async save(entityName: string, dataJson: string): Promise<boolean> {
    const normalizedEntity = this.normalizeEntityName(entityName);
    if (this.isSettingsEntity(normalizedEntity)) {
      const settingsWrite = this.parseSettingsWriteEnvelope(dataJson);
      if (settingsWrite.key.length <= 0) {
        logger.warn(TAG, '保存设置忽略: key为空');
        return false;
      }
      this.writeSettings(settingsWrite);
      logger.info(TAG, `保存设置成功: key=${settingsWrite.key}, type=${settingsWrite.valueType}`);
      return true;
    }

    const envelope = this.parseEntityEnvelope(dataJson);
    const id = envelope.id.length > 0 ? envelope.id : this.generateEntityId(normalizedEntity);
    const payloadJson = envelope.payloadJson.length > 0 ? envelope.payloadJson : dataJson;
    const entityStore = this.ensureEntityStore(normalizedEntity);
    entityStore.set(id, payloadJson);
    this.persistToRdb(normalizedEntity, id, payloadJson);
    logger.info(TAG, `保存实体成功: entity=${normalizedEntity}, id=${id}`);
    return true;
  }

  async saveEncrypted(entityName: string, dataJson: string, secretKeyBase64: string, ivBase64: string): Promise<boolean> {
    const normalizedEntity = this.normalizeEntityName(entityName);
    const encryptResult = await securityToolkit.aesEncrypt(dataJson, secretKeyBase64, ivBase64);
    if (!encryptResult.success) {
      logger.error(TAG, `加密保存失败: entity=${normalizedEntity}`);
      return false;
    }
    return this.save(normalizedEntity, encryptResult.data);
  }

  async queryDecrypted(entityName: string, queryJson: string, secretKeyBase64: string, ivBase64: string): Promise<NGFDataQueryResult> {
    const queryResult = await this.query(entityName, queryJson);
    if (!queryResult.success) {
      return queryResult;
    }
    
    const queryEnvelope = this.parseQueryEnvelope(queryJson);
    if (queryEnvelope.id.length > 0) {
      const envelope = this.parseEntityEnvelope(queryResult.dataJson);
      const decryptResult = await securityToolkit.aesDecrypt(envelope.payloadJson, secretKeyBase64, ivBase64);
      if (!decryptResult.success) {
        logger.error(TAG, `解密查询失败: id=${envelope.id}`);
        return new NGFDataQueryResult(false, '');
      }
      const decryptedEnvelope = new NGFDataEntityEnvelope(envelope.id, decryptResult.data);
      return new NGFDataQueryResult(true, JSON.stringify(decryptedEnvelope));
    } else {
      try {
        const collection = JSON.parse(queryResult.dataJson) as Partial<NGFDataEntityCollection>;
        const items = collection.items ? collection.items : [];
        const decryptedCollection = new NGFDataEntityCollection();
        for (let i = 0; i < items.length; i++) {
          const item = items[i];
          const decryptResult = await securityToolkit.aesDecrypt(item.payloadJson, secretKeyBase64, ivBase64);
          if (decryptResult.success) {
            decryptedCollection.items.push(new NGFDataEntityEnvelope(item.id, decryptResult.data));
          } else {
            logger.warn(TAG, `解密集合项失败: id=${item.id}`);
          }
        }
        return new NGFDataQueryResult(true, JSON.stringify(decryptedCollection));
      } catch (error) {
        logger.error(TAG, `解析集合数据失败: ${error}`);
        return new NGFDataQueryResult(false, '');
      }
    }
  }

  async remove(entityName: string, id: string): Promise<boolean> {
    const normalizedEntity = this.normalizeEntityName(entityName);
    const normalizedId = id.trim();
    if (normalizedId.length <= 0) {
      logger.warn(TAG, `删除忽略: entity=${normalizedEntity}, id为空`);
      return false;
    }

    if (this.isSettingsEntity(normalizedEntity)) {
      try {
        await this.settingsManager.deleteSetting(normalizedId);
        logger.info(TAG, `删除设置成功: key=${normalizedId}`);
        return true;
      } catch {
        logger.warn(TAG, `删除设置失败: key=${normalizedId}`);
        return false;
      }
    }

    const entityStore = this.entityStores.get(normalizedEntity);
    if (!entityStore) {
      logger.debug(TAG, `删除实体跳过: entity=${normalizedEntity} 未找到`);
      return false;
    }
    const removed = entityStore.delete(normalizedId);
    if (removed) {
      this.removeFromRdb(normalizedEntity, normalizedId);
    }
    logger.info(TAG, `删除实体: entity=${normalizedEntity}, id=${normalizedId}, 成功=${removed}`);
    return removed;
  }

  async queryPaginated(storeName: string, filters: Map<string, string>, pagination: NGFPaginationParams): Promise<NGFPaginatedResult<string>> {
    const normalizedStore = this.normalizeEntityName(storeName);
    const entityStore = this.ensureEntityStore(normalizedStore);
    const allEntries: Array<string> = [];
    entityStore.forEach((payloadJson: string) => {
      allEntries.push(payloadJson);
    });

    let filteredEntries: Array<string> = allEntries;
    if (filters.size > 0) {
      filteredEntries = [];
      const filterKeys: Array<string> = [];
      filters.forEach((_value: string, key: string) => {
        filterKeys.push(key);
      });
      for (let i = 0; i < allEntries.length; i++) {
        const entry = allEntries[i];
        let matchesAll = true;
        for (let j = 0; j < filterKeys.length; j++) {
          const filterKey = filterKeys[j];
          const filterValue = filters.get(filterKey) as string;
          if (entry.indexOf(filterKey) < 0 || entry.indexOf(filterValue) < 0) {
            matchesAll = false;
            break;
          }
        }
        if (matchesAll) {
          filteredEntries.push(entry);
        }
      }
    }

    const total = filteredEntries.length;
    const safeOffset = Math.max(0, Math.min(pagination.offset, total));
    const safeLimit = Math.max(0, pagination.limit);
    const end = Math.min(safeOffset + safeLimit, total);
    const items: Array<string> = [];
    for (let i = safeOffset; i < end; i++) {
      items.push(filteredEntries[i]);
    }
    const hasMore = end < total;

    logger.info(TAG, `分页查询: store=${normalizedStore}, total=${total}, offset=${pagination.offset}, limit=${pagination.limit}, returned=${items.length}, hasMore=${hasMore}`);
    return new NGFPaginatedResult<string>(items, total, hasMore);
  }

  async queryStream(storeName: string, filters: Map<string, string>, batchSize: number, onBatch: (items: Array<string>) => void): Promise<void> {
    const normalizedStore = this.normalizeEntityName(storeName);
    logger.info(TAG, `流式查询开始: store=${normalizedStore}`);
    
    let offset = 0;
    while (true) {
      const pagination = new NGFPaginationParams(offset, batchSize);
      const result = await this.queryPaginated(normalizedStore, filters, pagination);
      
      if (result.items.length > 0) {
        try {
          onBatch(result.items);
        } catch (error) {
          logger.error(TAG, `流式查询批次回调异常: ${error}`);
          break;
        }
      }
      
      if (!result.hasMore) {
        break;
      }
      offset += batchSize;
    }
    logger.info(TAG, `流式查询结束: store=${normalizedStore}`);
  }

  private querySettings(query: NGFSettingsQueryEnvelope): NGFSettingsResponseEnvelope {
    const valueType = query.valueType.toLowerCase();
    if (valueType === 'number') {
      const numberValue = ngfSettingsStoreFacade.getNumber(query.key, query.defaultNumber);
      return new NGFSettingsResponseEnvelope(query.key, 'number', `${numberValue}`, numberValue, false);
    }

    if (valueType === 'boolean') {
      const booleanValue = ngfSettingsStoreFacade.getBoolean(query.key, query.defaultBoolean);
      return new NGFSettingsResponseEnvelope(
        query.key,
        'boolean',
        booleanValue ? 'true' : 'false',
        booleanValue ? 1 : 0,
        booleanValue
      );
    }

    const stringValue = ngfSettingsStoreFacade.getString(query.key, query.defaultString);
    return new NGFSettingsResponseEnvelope(query.key, 'string', stringValue, 0, false);
  }

  private writeSettings(writeEnvelope: NGFSettingsWriteEnvelope): void {
    const valueType = writeEnvelope.valueType.toLowerCase();
    if (valueType === 'number') {
      ngfSettingsStoreFacade.setNumber(writeEnvelope.key, writeEnvelope.numberValue);
      return;
    }

    if (valueType === 'boolean') {
      ngfSettingsStoreFacade.setBoolean(writeEnvelope.key, writeEnvelope.booleanValue);
      return;
    }

    ngfSettingsStoreFacade.setString(writeEnvelope.key, writeEnvelope.stringValue);
  }

  private normalizeEntityName(entityName: string): string {
    const normalized = entityName.trim().toLowerCase();
    if (normalized.length <= 0) {
      return 'default';
    }
    return normalized;
  }

  private isSettingsEntity(entityName: string): boolean {
    return entityName === SETTINGS_ENTITY_NAME;
  }

  private ensureEntityStore(entityName: string): Map<string, string> {
    const existingStore = this.entityStores.get(entityName);
    if (existingStore) {
      return existingStore;
    }

    const createdStore = new Map<string, string>();
    this.entityStores.set(entityName, createdStore);
    logger.debug(TAG, `创建实体存储: entity=${entityName}`);
    return createdStore;
  }

  private generateEntityId(entityName: string): string {
    return `${entityName}_${Date.now()}`;
  }

  private parseQueryEnvelope(queryJson: string): NGFDataQueryEnvelope {
    if (queryJson.trim().length <= 0) {
      return new NGFDataQueryEnvelope('');
    }

    try {
      const parsed = JSON.parse(queryJson) as Partial<NGFDataQueryEnvelope>;
      const id = parsed.id && typeof parsed.id === 'string' ? parsed.id : '';
      return new NGFDataQueryEnvelope(id);
    } catch {
      return new NGFDataQueryEnvelope('');
    }
  }

  private parseEntityEnvelope(dataJson: string): NGFDataEntityEnvelope {
    if (dataJson.trim().length <= 0) {
      return new NGFDataEntityEnvelope('', '');
    }

    try {
      const parsed = JSON.parse(dataJson) as Partial<NGFDataEntityEnvelope>;
      const id = parsed.id && typeof parsed.id === 'string' ? parsed.id : '';
      const payloadJson = parsed.payloadJson && typeof parsed.payloadJson === 'string'
        ? parsed.payloadJson
        : dataJson;
      return new NGFDataEntityEnvelope(id, payloadJson);
    } catch {
      return new NGFDataEntityEnvelope('', dataJson);
    }
  }

  private parseSettingsQueryEnvelope(queryJson: string): NGFSettingsQueryEnvelope {
    if (queryJson.trim().length <= 0) {
      return new NGFSettingsQueryEnvelope('', 'string', '', 0, false);
    }

    try {
      const parsed = JSON.parse(queryJson) as Partial<NGFSettingsQueryEnvelope>;
      const key = parsed.key && typeof parsed.key === 'string' ? parsed.key : '';
      const valueType = parsed.valueType && typeof parsed.valueType === 'string' ? parsed.valueType : 'string';
      const defaultString = parsed.defaultString && typeof parsed.defaultString === 'string'
        ? parsed.defaultString
        : '';
      const defaultNumber = parsed.defaultNumber && typeof parsed.defaultNumber === 'number'
        ? parsed.defaultNumber
        : 0;
      const defaultBoolean = parsed.defaultBoolean && typeof parsed.defaultBoolean === 'boolean'
        ? parsed.defaultBoolean
        : false;
      return new NGFSettingsQueryEnvelope(key, valueType, defaultString, defaultNumber, defaultBoolean);
    } catch {
      return new NGFSettingsQueryEnvelope('', 'string', '', 0, false);
    }
  }

  private parseSettingsWriteEnvelope(dataJson: string): NGFSettingsWriteEnvelope {
    if (dataJson.trim().length <= 0) {
      return new NGFSettingsWriteEnvelope('', 'string', '', 0, false);
    }

    try {
      const parsed = JSON.parse(dataJson) as Partial<NGFSettingsWriteEnvelope>;
      const key = parsed.key && typeof parsed.key === 'string' ? parsed.key : '';
      const valueType = parsed.valueType && typeof parsed.valueType === 'string' ? parsed.valueType : 'string';
      const stringValue = parsed.stringValue && typeof parsed.stringValue === 'string' ? parsed.stringValue : '';
      const numberValue = parsed.numberValue && typeof parsed.numberValue === 'number' ? parsed.numberValue : 0;
      const booleanValue = parsed.booleanValue && typeof parsed.booleanValue === 'boolean'
        ? parsed.booleanValue
        : false;
      return new NGFSettingsWriteEnvelope(key, valueType, stringValue, numberValue, booleanValue);
    } catch {
      return new NGFSettingsWriteEnvelope('', 'string', '', 0, false);
    }
  }

  private serializeEntityCollection(store: Map<string, string>): string {
    const collection = new NGFDataEntityCollection();
    store.forEach((payloadJson: string, id: string) => {
      collection.items.push(new NGFDataEntityEnvelope(id, payloadJson));
    });
    return JSON.stringify(collection);
  }

  /**
   * 初始化 RDB 持久化层。在 Ability 的 onCreate 中调用。
   * 若初始化失败则退化为纯内存模式。
   */
  async init(context: Context): Promise<void> {
    try {
      const STORE_NAME = 'ngf_data.db';
      const config: relationalStore.StoreConfig = {
        name: STORE_NAME,
        securityLevel: relationalStore.SecurityLevel.S1
      };
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      const createTableSql =
        'CREATE TABLE IF NOT EXISTS ngf_entities (' +
        'entity_name TEXT NOT NULL, ' +
        'entity_id TEXT NOT NULL, ' +
        'payload_json TEXT NOT NULL, ' +
        'PRIMARY KEY(entity_name, entity_id))';
      await this.rdbStore.executeSql(createTableSql);
      this.rdbAvailable = true;
      logger.info(TAG, 'RDB 初始化成功');
      await this.loadAllEntitiesFromRdb();
    } catch (err) {
      this.rdbAvailable = false;
      logger.warn(TAG, `RDB 初始化失败，退化为内存模式: ${err}`);
    }
  }

  /**
   * 持久化单条实体到 RDB
   */
  private persistToRdb(entityName: string, id: string, payloadJson: string): void {
    if (!this.rdbAvailable || !this.rdbStore) {
      return;
    }
    try {
      const bucket: relationalStore.ValuesBucket = {
        'entity_name': entityName,
        'entity_id': id,
        'payload_json': payloadJson
      };
      const predicates = new relationalStore.RdbPredicates('ngf_entities');
      predicates.equalTo('entity_name', entityName);
      predicates.equalTo('entity_id', id);
      const resultSet = this.rdbStore.querySync(predicates, ['entity_id']);
      if (resultSet.rowCount > 0) {
        this.rdbStore.updateSync(bucket, predicates);
      } else {
        this.rdbStore.insertSync('ngf_entities', bucket);
      }
      resultSet.close();
      logger.debug(TAG, `RDB 持久化: entity=${entityName}, id=${id}`);
    } catch (err) {
      logger.warn(TAG, `RDB 持久化失败: entity=${entityName}, id=${id}, err=${err}`);
    }
  }

  /**
   * 从 RDB 删除单条实体
   */
  private removeFromRdb(entityName: string, id: string): void {
    if (!this.rdbAvailable || !this.rdbStore) {
      return;
    }
    try {
      const predicates = new relationalStore.RdbPredicates('ngf_entities');
      predicates.equalTo('entity_name', entityName);
      predicates.equalTo('entity_id', id);
      this.rdbStore.deleteSync(predicates);
      logger.debug(TAG, `RDB 删除: entity=${entityName}, id=${id}`);
    } catch (err) {
      logger.warn(TAG, `RDB 删除失败: entity=${entityName}, id=${id}, err=${err}`);
    }
  }

  /**
   * 启动时将所有 RDB 数据加载到内存 Map
   */
  private async loadAllEntitiesFromRdb(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    try {
      const predicates = new relationalStore.RdbPredicates('ngf_entities');
      const resultSet = this.rdbStore.querySync(predicates, ['entity_name', 'entity_id', 'payload_json']);
      const count = resultSet.rowCount;
      let loadedCount = 0;
      for (let i = 0; i < count; i++) {
        resultSet.goToNextRow();
        const entityName = resultSet.getString(resultSet.getColumnIndex('entity_name'));
        const entityId = resultSet.getString(resultSet.getColumnIndex('entity_id'));
        const payloadJson = resultSet.getString(resultSet.getColumnIndex('payload_json'));
        const entityStore = this.ensureEntityStore(entityName);
        entityStore.set(entityId, payloadJson);
        loadedCount++;
      }
      resultSet.close();
      logger.info(TAG, `RDB 加载完成: ${loadedCount} 条实体`);
    } catch (err) {
      logger.warn(TAG, `RDB 加载失败: ${err}`);
    }
  }
}

export const ngfDataFacade = new DataFacade();
