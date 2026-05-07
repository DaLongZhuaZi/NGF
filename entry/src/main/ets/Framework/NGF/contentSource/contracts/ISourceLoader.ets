/**
 * 源码加载器接口
 * @note API 23 适配：新增 initialize 方法支持依赖注入，解耦对 GlobalContext 的直接依赖
 */
export interface ISourceLoader {
  /**
   * 初始化源码加载器
   * @param filesDir 文件目录路径
   * @note API 23 适配：通过依赖注入传入路径，替代直接依赖 GlobalContext
   */
  initialize(filesDir: string): void;

  exists(pkg: string): boolean;
  loadSourceJson(pkg: string): string;
  loadIconPath(pkg: string): string;
}
