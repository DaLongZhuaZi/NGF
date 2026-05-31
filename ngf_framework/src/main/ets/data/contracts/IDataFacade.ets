export class NGFDataQueryResult {
  success: boolean;
  dataJson: string;

  constructor(success: boolean, dataJson: string) {
    this.success = success;
    this.dataJson = dataJson;
  }
}

export class NGFPaginationParams {
  offset: number;
  limit: number;

  constructor(offset: number, limit: number) {
    this.offset = offset;
    this.limit = limit;
  }
}

export class NGFPaginatedResult<T> {
  items: Array<T>;
  total: number;
  hasMore: boolean;

  constructor(items: Array<T>, total: number, hasMore: boolean) {
    this.items = items;
    this.total = total;
    this.hasMore = hasMore;
  }
}

export interface IDataTransformer<T> {
  transform(entity: T): T;
}

export interface IDataFacade {
  query(entityName: string, queryJson: string): Promise<NGFDataQueryResult>;
  save(entityName: string, dataJson: string): Promise<boolean>;
  saveEncrypted(entityName: string, dataJson: string, secretKeyBase64: string, ivBase64: string): Promise<boolean>;
  queryDecrypted(entityName: string, queryJson: string, secretKeyBase64: string, ivBase64: string): Promise<NGFDataQueryResult>;
  
  // Data Masking / Transformation via explicit typed contract
  saveWithTransformer<T>(entityName: string, entity: T, transformer: IDataTransformer<T>): Promise<boolean>;
  queryWithTransformer<T>(entityName: string, queryJson: string, transformer: IDataTransformer<T>): Promise<NGFDataQueryResult>;

  remove(entityName: string, id: string): Promise<boolean>;
  
  queryPaginated(storeName: string, filters: Map<string, string>, pagination: NGFPaginationParams): Promise<NGFPaginatedResult<string>>;
  queryStream(storeName: string, filters: Map<string, string>, batchSize: number, onBatch: (items: Array<string>) => void): Promise<void>;
  
  // True RDB physical pagination
  queryRdbPaginated(storeName: string, filters: Map<string, string>, pagination: NGFPaginationParams): Promise<NGFPaginatedResult<string>>;
}
