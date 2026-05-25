import { logger } from '../../utils/Logger';
import { IActionExecutor, NGFActionResult } from '../contracts/IActionExecutor';
import { ngfHttpClientFacade } from '../../contentSource/facades/HttpClientFacade';
import { NGFHttpRequestOptions, NGFHttpMethod } from '../../contentSource/contracts/IHttpClient';

const TAG: string = 'NGFActionExecutorFacade';

class NGFWaitActionEnvelope {
  waitMs: number;

  constructor(waitMs: number) {
    this.waitMs = waitMs;
  }
}

class NGFHttpActionEnvelope {
  url: string;
  method: string;

  constructor(url: string, method: string) {
    this.url = url;
    this.method = method;
  }
}

class NGFActionOutputEnvelope {
  actionType: string;
  actionJson: string;
  contextJson: string;
  executedAt: number;

  constructor(actionType: string, actionJson: string, contextJson: string, executedAt: number) {
    this.actionType = actionType;
    this.actionJson = actionJson;
    this.contextJson = contextJson;
    this.executedAt = executedAt;
  }
}

export class ActionExecutorFacade implements IActionExecutor {
  async executeAction(actionType: string, actionJson: string, contextJson: string): Promise<NGFActionResult> {
    const normalizedType = actionType.trim().toLowerCase();
    if (normalizedType.length <= 0) {
      logger.warn(TAG, 'executeAction 忽略：actionType 为空');
      return new NGFActionResult(false, '');
    }

    logger.info(TAG, `执行动作：type=${normalizedType}`);

    if (normalizedType === 'wait') {
      const waitAction = this.parseWaitAction(actionJson);
      if (waitAction.waitMs > 0) {
        logger.debug(TAG, `等待动作休眠：durationMs=${waitAction.waitMs}`);
        await this.sleep(waitAction.waitMs);
      }
      const waitOutput = new NGFActionOutputEnvelope('wait', actionJson, contextJson, Date.now());
      logger.info(TAG, `动作完成：type=${normalizedType}`);
      return new NGFActionResult(true, JSON.stringify(waitOutput));
    }

    if (normalizedType === 'fetch') {
      return await this.executeFetchAction(actionJson);
    }

    if (normalizedType === 'extract'
      || normalizedType === 'transform'
      || normalizedType === 'script'
      || normalizedType === 'navigate'
      || normalizedType === 'api') {
      const output = new NGFActionOutputEnvelope(normalizedType, actionJson, contextJson, Date.now());
      logger.info(TAG, `动作完成：type=${normalizedType}`);
      return new NGFActionResult(true, JSON.stringify(output));
    }

    logger.warn(TAG, `不支持的动作类型：${normalizedType}`);
    return new NGFActionResult(false, '');
  }

  private async executeFetchAction(actionJson: string): Promise<NGFActionResult> {
    const httpAction: NGFHttpActionEnvelope = this.parseHttpAction(actionJson);
    if (httpAction.url.length <= 0) {
      logger.warn(TAG, 'fetch 动作缺少 URL');
      return new NGFActionResult(false, '');
    }
    try {
      const options: NGFHttpRequestOptions = new NGFHttpRequestOptions(
        httpAction.method.length > 0 ? this.resolveHttpMethod(httpAction.method) : NGFHttpMethod.GET,
        httpAction.url,
        '',
        '',
        10000,
        30000
      );
      const response = await ngfHttpClientFacade.request(options);
      logger.info(TAG, `fetch 完成: url=${httpAction.url}, status=${response.statusCode}`);
      return new NGFActionResult(true, response.result);
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `fetch 失败: url=${httpAction.url}, error=${message}`);
      return new NGFActionResult(false, `fetch error: ${message}`);
    }
  }

  private parseHttpAction(actionJson: string): NGFHttpActionEnvelope {
    if (actionJson.trim().length <= 0) {
      return new NGFHttpActionEnvelope('', 'GET');
    }
    try {
      const parsed: object = JSON.parse(actionJson) as object;
      let url: string = '';
      let method: string = 'GET';
      const urlValue: string | undefined = (parsed as Record<string, string>)['url'];
      if (urlValue !== undefined && typeof urlValue === 'string') {
        url = urlValue;
      }
      const methodValue: string | undefined = (parsed as Record<string, string>)['method'];
      if (methodValue !== undefined && typeof methodValue === 'string') {
        method = methodValue;
      }
      return new NGFHttpActionEnvelope(url, method);
    } catch {
      logger.warn(TAG, 'parseHttpAction 失败：无效的 JSON 负载');
      return new NGFHttpActionEnvelope('', 'GET');
    }
  }

  private resolveHttpMethod(method: string): NGFHttpMethod {
    const normalized: string = method.trim().toUpperCase();
    if (normalized === 'POST') return NGFHttpMethod.POST;
    if (normalized === 'PUT') return NGFHttpMethod.PUT;
    if (normalized === 'DELETE') return NGFHttpMethod.DELETE;
    return NGFHttpMethod.GET;
  }

  private parseWaitAction(actionJson: string): NGFWaitActionEnvelope {
    if (actionJson.trim().length <= 0) {
      logger.debug(TAG, 'parseWaitAction 回退：actionJson 为空');
      return new NGFWaitActionEnvelope(0);
    }

    try {
      const parsed = JSON.parse(actionJson) as Partial<NGFWaitActionEnvelope>;
      const waitMs = parsed.waitMs && typeof parsed.waitMs === 'number' ? parsed.waitMs : 0;
      return new NGFWaitActionEnvelope(waitMs);
    } catch {
      logger.warn(TAG, 'parseWaitAction 失败：无效的 JSON 负载');
      return new NGFWaitActionEnvelope(0);
    }
  }

  private async sleep(durationMs: number): Promise<void> {
    await new Promise<void>((resolve: () => void) => {
      setTimeout((): void => {
        resolve();
      }, durationMs);
    });
  }
}

export const ngfActionExecutorFacade = new ActionExecutorFacade();
