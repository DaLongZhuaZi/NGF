/**
 * 存储提供者接口
 * @note API 23 适配：新增 initialize 方法支持依赖注入，解耦对 platformOhos 层的直接依赖
 */
export interface IStorageProvider {
  /**
   * 初始化存储提供者
   * @param filesDir 文件目录路径
   * @note API 23 适配：通过依赖注入传入路径，替代直接依赖 UIContextManager
   */
  initialize(filesDir: string): void;

  getCacheDir(): string;
  getFilesDir(): string;
  readText(path: string): string;
  writeText(path: string, content: string): boolean;
  exists(path: string): boolean;
}
