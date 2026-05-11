/**
 * 内容源健康状态
 */
export enum NGFSourceHealthStatus {
  HEALTHY = 'healthy',
  DEGRADED = 'degraded',
  UNHEALTHY = 'unhealthy',
  UNKNOWN = 'unknown'
}

/**
 * 内容源健康检查结果
 */
export class NGFSourceHealthResult {
  readonly sourceName: string;
  readonly status: NGFSourceHealthStatus;
  readonly latencyMs: number;
  readonly message: string;
  readonly checkedAt: number;

  constructor(
    sourceName: string,
    status: NGFSourceHealthStatus,
    latencyMs: number,
    message: string,
    checkedAt: number
  ) {
    this.sourceName = sourceName;
    this.status = status;
    this.latencyMs = latencyMs;
    this.message = message;
    this.checkedAt = checkedAt;
  }
}

/**
 * 内容源健康检查配置
 */
export class NGFSourceHealthConfig {
  readonly sourceName: string;
  readonly checkUrl: string;
  readonly timeoutMs: number;
  readonly degradedThresholdMs: number;
  readonly unhealthyThresholdMs: number;

  constructor(
    sourceName: string,
    checkUrl: string,
    timeoutMs: number = 5000,
    degradedThresholdMs: number = 2000,
    unhealthyThresholdMs: number = 5000
  ) {
    this.sourceName = sourceName;
    this.checkUrl = checkUrl;
    this.timeoutMs = timeoutMs;
    this.degradedThresholdMs = degradedThresholdMs;
    this.unhealthyThresholdMs = unhealthyThresholdMs;
  }
}

/**
 * 内容源健康检查器接口
 */
export interface ISourceHealthChecker {
  registerSource(config: NGFSourceHealthConfig): void;
  unregisterSource(sourceName: string): boolean;
  checkHealth(sourceName: string): Promise<NGFSourceHealthResult>;
  checkAll(): Promise<Array<NGFSourceHealthResult>>;
  getLastResult(sourceName: string): NGFSourceHealthResult | null;
  isAvailable(sourceName: string): boolean;
}
