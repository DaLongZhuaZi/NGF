/**
 * 内容缓存接口
 * 内存 LRU + 磁盘持久化的二级缓存
 */
export interface IContentCache {
  initialize(filesDir: string): void;
  put(key: string, value: string, ttlMs: number): void;
  get(key: string): string;
  has(key: string): boolean;
  remove(key: string): void;
  clear(): void;
  memorySize(): number;
}
