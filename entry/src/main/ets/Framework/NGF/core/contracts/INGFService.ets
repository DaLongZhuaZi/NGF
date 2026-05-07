/**
 * NGF 服务标记接口
 * @interface INGFService
 * @description 所有 NGF 框架服务的基接口，用于服务注册和依赖注入
 * @note API 23 适配：引入标记接口消除 NGFServiceRegistration 中的 as object 断言
 *
 * @example
 * ```typescript
 * class MyService implements INGFService {
 *   readonly serviceId: string = 'my.service';
 *
 *   initialize(): void {
 *     // 服务初始化逻辑
 *   }
 * }
 * ```
 */
export interface INGFService {
  /**
   * 服务唯一标识符
   * @readonly
   */
  readonly serviceId: string;

  /**
   * 初始化服务
   * @note 在服务注册后由框架调用
   */
  initialize?(): void;

  /**
   * 销毁服务
   * @note 在应用退出或服务注销时调用
   */
  destroy?(): void;
}

/**
 * 服务元数据接口
 * @interface INGFServiceMetadata
 * @description 描述服务的元数据信息
 */
export interface INGFServiceMetadata {
  /** 服务标识符 */
  serviceId: string;
  /** 服务版本 */
  version?: string;
  /** 服务描述 */
  description?: string;
  /** 依赖的其他服务 */
  dependencies?: string[];
}

/**
 * 服务生命周期状态
 * @enum NGFServiceLifecycleState
 */
export enum NGFServiceLifecycleState {
  /** 已创建但未初始化 */
  CREATED = 'CREATED',
  /** 初始化中 */
  INITIALIZING = 'INITIALIZING',
  /** 已初始化并可用 */
  READY = 'READY',
  /** 运行中 */
  RUNNING = 'RUNNING',
  /** 销毁中 */
  DESTROYING = 'DESTROYING',
  /** 已销毁 */
  DESTROYED = 'DESTROYED',
  /** 错误状态 */
  ERROR = 'ERROR'
}

/**
 * 服务状态接口
 * @interface INGFServiceState
 */
export interface INGFServiceState {
  /** 当前生命周期状态 */
  lifecycleState: NGFServiceLifecycleState;
  /** 最后更新时间戳 */
  lastUpdatedAt: number;
  /** 错误信息（如果有） */
  errorMessage?: string;
}
