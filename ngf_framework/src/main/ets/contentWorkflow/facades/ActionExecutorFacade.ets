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

class NGFExtractActionEnvelope {
  path: string;

  constructor(path: string) {
    this.path = path;
  }
}

class NGFTransformActionEnvelope {
  map: Map<string, string>;

  constructor(map: Map<string, string>) {
    this.map = map;
  }
}

class NGFNavigateActionEnvelope {
  route: string;
  params: Map<string, string>;

  constructor(route: string, params: Map<string, string>) {
    this.route = route;
    this.params = params;
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

    if (normalizedType === 'extract') {
      return this.executeExtractAction(actionJson, contextJson);
    }

    if (normalizedType === 'transform') {
      return this.executeTransformAction(actionJson, contextJson);
    }

    if (normalizedType === 'navigate') {
      return this.executeNavigateAction(actionJson, contextJson);
    }

    if (normalizedType === 'script') {
      return this.executeScriptAction(actionJson, contextJson);
    }

    if (normalizedType === 'api') {
      return await this.executeApiAction(actionJson, contextJson);
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

  private executeExtractAction(actionJson: string, contextJson: string): NGFActionResult {
    const envelope = this.parseExtractAction(actionJson);
    if (envelope.path.length <= 0) {
      logger.warn(TAG, 'extract 动作缺少 path');
      return new NGFActionResult(false, '{"error":"missing path"}');
    }
    try {
      if (contextJson.trim().length <= 0) {
        logger.warn(TAG, 'extract 上下文为空');
        return new NGFActionResult(false, '{"error":"empty context"}');
      }
      const context: object = JSON.parse(contextJson) as object;
      const result: string = this.resolveJsonPath(context, envelope.path);
      const outputJson: string = `{"actionType":"extract","executedAt":${Date.now()},"extractedPath":"${envelope.path}","extractedValue":"${result}"}`;
      logger.info(TAG, `extract 完成: path=${envelope.path}`);
      return new NGFActionResult(true, outputJson);
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `extract 失败: path=${envelope.path}, error=${message}`);
      return new NGFActionResult(false, `{"error":"${message}"}`);
    }
  }

  private executeTransformAction(actionJson: string, contextJson: string): NGFActionResult {
    const envelope = this.parseTransformAction(actionJson);
    if (envelope.map.size <= 0) {
      logger.warn(TAG, 'transform 动作缺少 map');
      return new NGFActionResult(false, '{"error":"missing map"}');
    }
    try {
      if (contextJson.trim().length <= 0) {
        logger.warn(TAG, 'transform 上下文为空');
        return new NGFActionResult(false, '{"error":"empty context"}');
      }
      const context: object = JSON.parse(contextJson) as object;
      const contextRecord = context as Record<string, string>;
      const transformed: Map<string, string> = new Map<string, string>();
      const keys: Array<string> = Object.keys(contextRecord);
      for (let i = 0; i < keys.length; i++) {
        const key: string = keys[i];
        const newKey: string | undefined = envelope.map.get(key);
        if (newKey !== undefined) {
          transformed.set(newKey, contextRecord[key]);
        } else {
          transformed.set(key, contextRecord[key]);
        }
      }
      const transformedJson: string = this.mapToJson(transformed);
      const outputJson: string = `{"actionType":"transform","executedAt":${Date.now()},"transformedData":${transformedJson}}`;
      logger.info(TAG, `transform 完成: mapped ${envelope.map.size} fields`);
      return new NGFActionResult(true, outputJson);
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `transform 失败: error=${message}`);
      return new NGFActionResult(false, `{"error":"${message}"}`);
    }
  }

  private executeNavigateAction(actionJson: string, contextJson: string): NGFActionResult {
    const envelope = this.parseNavigateAction(actionJson);
    if (envelope.route.length <= 0) {
      logger.warn(TAG, 'navigate 动作缺少 route');
      return new NGFActionResult(false, '{"error":"missing route"}');
    }
    const paramsJson: string = this.mapToJson(envelope.params);
    const outputJson: string = `{"actionType":"navigate","executedAt":${Date.now()},"navigationIntent":{"route":"${envelope.route}","params":${paramsJson}}}`;
    logger.info(TAG, `navigate 意图已生成: route=${envelope.route}`);
    return new NGFActionResult(true, outputJson);
  }

  private executeScriptAction(actionJson: string, contextJson: string): NGFActionResult {
    try {
      const params: Record<string, string> = this.parseActionParams(actionJson);
      const expression: string = params['expression'] !== undefined ? params['expression'] : '';
      const outputKey: string = params['outputKey'] !== undefined ? params['outputKey'] : 'scriptResult';

      if (expression.length <= 0) {
        logger.warn(TAG, 'script 动作缺少 expression');
        return new NGFActionResult(false, '{"error":"missing expression"}');
      }

      // Parse context into a Map for variable substitution
      const contextMap: Map<string, string> = new Map<string, string>();
      if (contextJson.trim().length > 0) {
        try {
          const contextObj: object = JSON.parse(contextJson) as object;
          const contextRecord: Record<string, string> = contextObj as Record<string, string>;
          const contextKeys: Array<string> = Object.keys(contextRecord);
          for (let i = 0; i < contextKeys.length; i++) {
            const key: string = contextKeys[i];
            contextMap.set(key, contextRecord[key]);
          }
        } catch (contextError) {
          logger.warn(TAG, 'script 动作解析上下文失败');
        }
      }

      // Variable substitution: replace ${key} patterns with context values
      let resolvedExpression: string = expression;
      const placeholderPattern: RegExp = /\$\{(\w+)\}/g;
      let match: RegExpExecArray | null = placeholderPattern.exec(expression);
      while (match !== null) {
        const varName: string = match[1];
        const varValue: string | undefined = contextMap.get(varName);
        if (varValue !== undefined) {
          const fullPlaceholder: string = match[0];
          // Replace all occurrences of this placeholder
          while (resolvedExpression.indexOf(fullPlaceholder) >= 0) {
            resolvedExpression = resolvedExpression.replace(fullPlaceholder, varValue);
          }
        }
        match = placeholderPattern.exec(expression);
      }

      logger.info(TAG, `script 完成: outputKey=${outputKey}, expressionLength=${resolvedExpression.length}`);
      const outputJson: string = `{"actionType":"script","executedAt":${Date.now()},"${outputKey}":${JSON.stringify(resolvedExpression)}}`;
      return new NGFActionResult(true, outputJson);
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `script 失败: error=${message}`);
      return new NGFActionResult(false, `{"error":"${message}"}`);
    }
  }

  private async executeApiAction(actionJson: string, contextJson: string): Promise<NGFActionResult> {
    try {
      const params: Record<string, string> = this.parseActionParams(actionJson);
      const url: string = params['url'] !== undefined ? params['url'] : '';
      const method: string = params['method'] !== undefined ? params['method'] : 'GET';
      const headers: string = params['headers'] !== undefined ? params['headers'] : '';
      let body: string = params['body'] !== undefined ? params['body'] : '';

      if (url.length <= 0) {
        logger.warn(TAG, 'api 动作缺少 url');
        return new NGFActionResult(false, '{"error":"missing url"}');
      }

      // If body contains ${key} placeholders, substitute from context
      if (body.length > 0 && contextJson.trim().length > 0) {
        try {
          const contextObj: object = JSON.parse(contextJson) as object;
          const contextRecord: Record<string, string> = contextObj as Record<string, string>;
          const placeholderPattern: RegExp = /\$\{(\w+)\}/g;
          let match: RegExpExecArray | null = placeholderPattern.exec(body);
          while (match !== null) {
            const varName: string = match[1];
            const varValue: string | undefined = contextRecord[varName];
            if (varValue !== undefined) {
              const fullPlaceholder: string = match[0];
              while (body.indexOf(fullPlaceholder) >= 0) {
                body = body.replace(fullPlaceholder, varValue);
              }
            }
            match = placeholderPattern.exec(body);
          }
        } catch (contextError) {
          logger.warn(TAG, 'api 动作解析上下文失败，使用原始 body');
        }
      }

      const httpMethod: NGFHttpMethod = this.resolveHttpMethod(method);
      const options: NGFHttpRequestOptions = new NGFHttpRequestOptions(
        httpMethod,
        url,
        headers,
        body,
        10000,
        30000
      );

      logger.info(TAG, `api 请求: method=${method}, url=${url}`);
      const response = await ngfHttpClientFacade.request(options);
      logger.info(TAG, `api 完成: url=${url}, status=${response.statusCode}`);

      const outputJson: string = `{"actionType":"api","executedAt":${Date.now()},"statusCode":${response.statusCode},"responseBody":${JSON.stringify(response.result)}}`;
      return new NGFActionResult(true, outputJson);
    } catch (error) {
      const message: string = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `api 失败: error=${message}`);
      return new NGFActionResult(false, `{"error":"${message}"}`);
    }
  }

  private parseActionParams(actionJson: string): Record<string, string> {
    const result: Record<string, string> = {};
    if (actionJson.trim().length <= 0) {
      return result;
    }
    try {
      const parsed: object = JSON.parse(actionJson) as object;
      const fullRecord: Record<string, Record<string, string>> = parsed as Record<string, Record<string, string>>;
      const params: Record<string, string> | undefined = fullRecord['params'];
      if (params !== undefined && typeof params === 'object') {
        const keys: Array<string> = Object.keys(params);
        for (let i = 0; i < keys.length; i++) {
          const key: string = keys[i];
          const value: string = params[key];
          result[key] = typeof value === 'string' ? value : String(value);
        }
      }
    } catch {
      logger.warn(TAG, 'parseActionParams 失败：无效的 JSON');
    }
    return result;
  }

  private resolveJsonPath(obj: object, path: string): string {
    const segments: Array<string> = path.split('.');
    let current: object = obj;
    for (let i = 0; i < segments.length; i++) {
      const segment: string = segments[i];
      const bracketMatch: RegExpMatchArray | null = segment.match(/^(\w+)\[(\d+)\]$/);
      if (bracketMatch !== null) {
        const propName: string = bracketMatch[1];
        const index: number = parseInt(bracketMatch[2]);
        const record = current as Record<string, object>;
        const arr: object = record[propName] as object;
        if (!Array.isArray(arr) || index >= arr.length) {
          return '';
        }
        const item: object = arr[index] as object;
        if (i === segments.length - 1) {
          return typeof item === 'string' ? item : JSON.stringify(item);
        }
        current = item;
      } else {
        const record = current as Record<string, string>;
        const keys: Array<string> = Object.keys(record);
        let found: boolean = false;
        for (let k = 0; k < keys.length; k++) {
          if (keys[k] === segment) {
            found = true;
            break;
          }
        }
        if (!found) {
          return '';
        }
        const value: string = record[segment];
        if (i === segments.length - 1) {
          return value;
        }
        try {
          current = JSON.parse(value) as object;
        } catch {
          return value;
        }
      }
    }
    return '';
  }

  private parseExtractAction(actionJson: string): NGFExtractActionEnvelope {
    if (actionJson.trim().length <= 0) {
      return new NGFExtractActionEnvelope('');
    }
    try {
      const parsed: object = JSON.parse(actionJson) as object;
      const record = parsed as Record<string, string>;
      const path: string | undefined = record['path'];
      if (path !== undefined && typeof path === 'string') {
        return new NGFExtractActionEnvelope(path);
      }
      return new NGFExtractActionEnvelope('');
    } catch {
      logger.warn(TAG, 'parseExtractAction 失败：无效的 JSON');
      return new NGFExtractActionEnvelope('');
    }
  }

  private parseTransformAction(actionJson: string): NGFTransformActionEnvelope {
    const emptyMap: Map<string, string> = new Map<string, string>();
    if (actionJson.trim().length <= 0) {
      return new NGFTransformActionEnvelope(emptyMap);
    }
    try {
      const parsed: object = JSON.parse(actionJson) as object;
      const record = parsed as Record<string, Record<string, string>>;
      const mapData: Record<string, string> | undefined = record['map'];
      if (mapData !== undefined && typeof mapData === 'object') {
        const result: Map<string, string> = new Map<string, string>();
        const keys: Array<string> = Object.keys(mapData);
        for (let i = 0; i < keys.length; i++) {
          result.set(keys[i], mapData[keys[i]]);
        }
        return new NGFTransformActionEnvelope(result);
      }
      return new NGFTransformActionEnvelope(emptyMap);
    } catch {
      logger.warn(TAG, 'parseTransformAction 失败：无效的 JSON');
      return new NGFTransformActionEnvelope(emptyMap);
    }
  }

  private parseNavigateAction(actionJson: string): NGFNavigateActionEnvelope {
    const emptyParams: Map<string, string> = new Map<string, string>();
    if (actionJson.trim().length <= 0) {
      return new NGFNavigateActionEnvelope('', emptyParams);
    }
    try {
      const route: string = this.extractStringField(actionJson, 'route');
      const paramsResult: Map<string, string> = new Map<string, string>();
      const paramsStart: number = actionJson.indexOf('"params"');
      if (paramsStart >= 0) {
        const colonIndex: number = actionJson.indexOf(':', paramsStart);
        if (colonIndex >= 0) {
          const braceIndex: number = actionJson.indexOf('{', colonIndex);
          if (braceIndex >= 0) {
            let depth: number = 1;
            let end: number = braceIndex + 1;
            while (end < actionJson.length && depth > 0) {
              if (actionJson.charAt(end) === '{') {
                depth++;
              } else if (actionJson.charAt(end) === '}') {
                depth--;
              }
              end++;
            }
            const paramsJsonStr: string = actionJson.substring(braceIndex, end);
            const paramsRecord: Record<string, string> = JSON.parse(paramsJsonStr) as Record<string, string>;
            const paramKeys: Array<string> = Object.keys(paramsRecord);
            for (let i = 0; i < paramKeys.length; i++) {
              paramsResult.set(paramKeys[i], paramsRecord[paramKeys[i]]);
            }
          }
        }
      }
      return new NGFNavigateActionEnvelope(route, paramsResult);
    } catch {
      logger.warn(TAG, 'parseNavigateAction 失败：无效的 JSON');
      return new NGFNavigateActionEnvelope('', emptyParams);
    }
  }

  private mapToJson(map: Map<string, string>): string {
    let result: string = '{';
    let first: boolean = true;
    map.forEach((value: string, key: string): void => {
      if (!first) {
        result += ',';
      }
      result += `"${key}":"${value}"`;
      first = false;
    });
    result += '}';
    return result;
  }

  private extractStringField(json: string, fieldName: string): string {
    const search: string = `"${fieldName}"`;
    const index: number = json.indexOf(search);
    if (index < 0) {
      return '';
    }
    const colonIndex: number = json.indexOf(':', index);
    if (colonIndex < 0) {
      return '';
    }
    const quoteStart: number = json.indexOf('"', colonIndex + 1);
    if (quoteStart < 0) {
      return '';
    }
    const quoteEnd: number = json.indexOf('"', quoteStart + 1);
    if (quoteEnd < 0) {
      return '';
    }
    return json.substring(quoteStart + 1, quoteEnd);
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
