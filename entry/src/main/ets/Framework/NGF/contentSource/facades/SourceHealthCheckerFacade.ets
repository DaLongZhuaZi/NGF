import { logger } from '../../utils/Logger';
import { ngfHttpClientFacade } from './HttpClientFacade';
import { NGFHttpMethod, NGFHttpRequestOptions, NGFHttpResponse } from '../contracts/IHttpClient';
import {
  ISourceHealthChecker,
  NGFSourceHealthConfig,
  NGFSourceHealthResult,
  NGFSourceHealthStatus
} from '../contracts/ISourceHealthChecker';

const TAG: string = 'NGFSourceHealthCheckerFacade';

export class SourceHealthCheckerFacade implements ISourceHealthChecker {
  private readonly configs: Map<string, NGFSourceHealthConfig> = new Map<string, NGFSourceHealthConfig>();
  private readonly lastResults: Map<string, NGFSourceHealthResult> = new Map<string, NGFSourceHealthResult>();

  registerSource(config: NGFSourceHealthConfig): void {
    this.configs.set(config.sourceName, config);
    logger.info(TAG, `注册健康检查: source=${config.sourceName}, url=${config.checkUrl}`);
  }

  unregisterSource(sourceName: string): boolean {
    const existed = this.configs.has(sourceName);
    this.configs.delete(sourceName);
    this.lastResults.delete(sourceName);
    logger.info(TAG, `注销健康检查: source=${sourceName}, existed=${existed}`);
    return existed;
  }

  async checkHealth(sourceName: string): Promise<NGFSourceHealthResult> {
    const config = this.configs.get(sourceName);
    if (config === undefined) {
      logger.warn(TAG, `健康检查配置未找到: source=${sourceName}`);
      return new NGFSourceHealthResult(sourceName, NGFSourceHealthStatus.UNKNOWN, 0, 'not registered', Date.now());
    }

    const startTime: number = Date.now();
    try {
      const options = new NGFHttpRequestOptions(NGFHttpMethod.GET, config.checkUrl, '', '', config.timeoutMs, config.timeoutMs);
      const response: NGFHttpResponse = await ngfHttpClientFacade.request(options);
      const latencyMs: number = Date.now() - startTime;

      let status: NGFSourceHealthStatus;
      let message: string;

      if (!response.isOk()) {
        status = NGFSourceHealthStatus.UNHEALTHY;
        message = `HTTP ${response.statusCode}`;
      } else if (latencyMs >= config.unhealthyThresholdMs) {
        status = NGFSourceHealthStatus.UNHEALTHY;
        message = `latency ${latencyMs}ms >= ${config.unhealthyThresholdMs}ms`;
      } else if (latencyMs >= config.degradedThresholdMs) {
        status = NGFSourceHealthStatus.DEGRADED;
        message = `latency ${latencyMs}ms >= ${config.degradedThresholdMs}ms`;
      } else {
        status = NGFSourceHealthStatus.HEALTHY;
        message = `ok, ${latencyMs}ms`;
      }

      const result = new NGFSourceHealthResult(sourceName, status, latencyMs, message, Date.now());
      this.lastResults.set(sourceName, result);
      logger.info(TAG, `健康检查完成: source=${sourceName}, status=${status}, latency=${latencyMs}ms`);
      return result;
    } catch (error) {
      const latencyMs: number = Date.now() - startTime;
      const errorMessage = error instanceof Error ? error.message : String(error);
      const result = new NGFSourceHealthResult(
        sourceName,
        NGFSourceHealthStatus.UNHEALTHY,
        latencyMs,
        `error: ${errorMessage}`,
        Date.now()
      );
      this.lastResults.set(sourceName, result);
      logger.warn(TAG, `健康检查异常: source=${sourceName}, error=${errorMessage}`);
      return result;
    }
  }

  async checkAll(): Promise<Array<NGFSourceHealthResult>> {
    const results: Array<NGFSourceHealthResult> = [];
    const names = this.configs.keys();
    for (const name of names) {
      const result = await this.checkHealth(name);
      results.push(result);
    }
    logger.info(TAG, `批量健康检查完成: count=${results.length}`);
    return results;
  }

  getLastResult(sourceName: string): NGFSourceHealthResult | null {
    const result = this.lastResults.get(sourceName);
    if (result === undefined) {
      return null;
    }
    return result;
  }

  isAvailable(sourceName: string): boolean {
    const result = this.lastResults.get(sourceName);
    if (result === undefined) {
      return true;
    }
    return result.status !== NGFSourceHealthStatus.UNHEALTHY;
  }
}

export const ngfSourceHealthCheckerFacade: SourceHealthCheckerFacade = new SourceHealthCheckerFacade();
