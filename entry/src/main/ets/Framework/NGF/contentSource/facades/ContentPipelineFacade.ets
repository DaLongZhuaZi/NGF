import { logger } from '../../utils/Logger';
import {
  IContentPipeline,
  NGFPipelineDefinition,
  NGFPipelineResult,
  NGFPipelineStepDefinition,
  NGFPipelineStepResult
} from '../contracts/IContentPipeline';
import { ngfHttpClientFacade } from './HttpClientFacade';
import { ngfContentCacheFacade } from './ContentCacheFacade';
import { NGFHttpMethod, NGFHttpRequestOptions, NGFHttpResponse } from '../contracts/IHttpClient';

const TAG: string = 'NGFContentPipelineFacade';

export class ContentPipelineFacade implements IContentPipeline {
  private readonly pipelines: Map<string, NGFPipelineDefinition> = new Map<string, NGFPipelineDefinition>();

  registerPipeline(definition: NGFPipelineDefinition): void {
    const name = definition.pipelineName.trim();
    if (name.length <= 0) {
      logger.warn(TAG, '注册管道忽略: pipelineName 为空');
      return;
    }
    this.pipelines.set(name, definition);
    logger.info(TAG, `注册管道: name=${name}, steps=${definition.steps.length}`);
  }

  hasPipeline(pipelineName: string): boolean {
    return this.pipelines.has(pipelineName.trim());
  }

  async execute(pipelineName: string, sourceId: string, input: string): Promise<NGFPipelineResult> {
    const name = pipelineName.trim();
    const definition = this.pipelines.get(name);
    if (definition === undefined) {
      logger.warn(TAG, `管道未注册: name=${name}`);
      return new NGFPipelineResult(false, '', []);
    }

    const stepResults: Array<NGFPipelineStepResult> = [];
    let currentInput: string = input;

    for (let index = 0; index < definition.steps.length; index++) {
      const step = definition.steps[index];
      logger.debug(TAG, `执行步骤: pipeline=${name}, step=${step.stepName}, type=${step.stepType}`);
      const stepResult = await this.executeStep(step, sourceId, currentInput);
      stepResults.push(stepResult);
      if (!stepResult.success) {
        logger.warn(TAG, `步骤失败: step=${step.stepName}, pipeline=${name}`);
        return new NGFPipelineResult(false, currentInput, stepResults);
      }
      currentInput = stepResult.output;
    }

    logger.info(TAG, `管道执行完成: pipeline=${name}, steps=${stepResults.length}`);
    return new NGFPipelineResult(true, currentInput, stepResults);
  }

  private async executeStep(step: NGFPipelineStepDefinition, sourceId: string, input: string): Promise<NGFPipelineStepResult> {
    try {
      if (step.stepType === 'fetch') {
        return await this.executeFetch(step, input);
      }
      if (step.stepType === 'parse') {
        return this.executeParse(step, input);
      }
      if (step.stepType === 'transform') {
        return this.executeTransform(step, input);
      }
      if (step.stepType === 'cache') {
        return this.executeCache(step, sourceId, input);
      }
      logger.warn(TAG, `未知步骤类型: ${step.stepType}`);
      return new NGFPipelineStepResult(false, input, step.stepName);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error(TAG, `步骤异常: step=${step.stepName}, error=${message}`);
      return new NGFPipelineStepResult(false, input, step.stepName);
    }
  }

  private async executeFetch(step: NGFPipelineStepDefinition, input: string): Promise<NGFPipelineStepResult> {
    const url = input.trim();
    if (url.length <= 0) {
      return new NGFPipelineStepResult(false, '', step.stepName);
    }
    const options = new NGFHttpRequestOptions(NGFHttpMethod.GET, url);
    const response: NGFHttpResponse = await ngfHttpClientFacade.request(options);
    if (!response.isOk()) {
      logger.warn(TAG, `fetch 失败: url=${url}, status=${response.statusCode}`);
      return new NGFPipelineStepResult(false, '', step.stepName);
    }
    return new NGFPipelineStepResult(true, response.result, step.stepName);
  }

  private executeParse(step: NGFPipelineStepDefinition, input: string): NGFPipelineStepResult {
    if (input.length <= 0) {
      return new NGFPipelineStepResult(false, '', step.stepName);
    }
    try {
      const parsed: Object = JSON.parse(input);
      const serialized: string = JSON.stringify(parsed);
      logger.debug(TAG, `parse 成功: step=${step.stepName}, outputLength=${serialized.length}`);
      return new NGFPipelineStepResult(true, serialized, step.stepName);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn(TAG, `parse 失败: step=${step.stepName}, error=${message}`);
      return new NGFPipelineStepResult(false, input, step.stepName, message);
    }
  }

  private executeTransform(step: NGFPipelineStepDefinition, input: string): NGFPipelineStepResult {
    if (input.length <= 0) {
      return new NGFPipelineStepResult(false, '', step.stepName);
    }
    const config = step.config.trim();
    if (config.length <= 0) {
      return new NGFPipelineStepResult(true, input, step.stepName);
    }
    try {
      const mapping = JSON.parse(config) as object;
      const entries = Object.entries(mapping) as [string, string][];
      if (entries.length <= 0) {
        return new NGFPipelineStepResult(true, input, step.stepName);
      }
      let output: string = input;
      for (let index = 0; index < entries.length; index++) {
        const entry = entries[index];
        const placeholder = `{{${entry[0]}}}`;
        output = output.replace(placeholder, entry[1]);
      }
      return new NGFPipelineStepResult(true, output, step.stepName);
    } catch {
      return new NGFPipelineStepResult(true, input, step.stepName);
    }
  }

  private executeCache(step: NGFPipelineStepDefinition, sourceId: string, input: string): NGFPipelineStepResult {
    if (input.length <= 0) {
      return new NGFPipelineStepResult(false, '', step.stepName);
    }
    const ttlMs = this.parseTtlMs(step.config);
    const cacheKey = `pipeline:${sourceId}:${step.stepName}`;
    ngfContentCacheFacade.put(cacheKey, input, ttlMs);
    logger.debug(TAG, `缓存步骤结果: key=${cacheKey}, ttlMs=${ttlMs}`);
    return new NGFPipelineStepResult(true, input, step.stepName);
  }

  private parseTtlMs(config: string): number {
    const trimmed = config.trim();
    if (trimmed.length <= 0) {
      return 300000;
    }
    try {
      const parsed = JSON.parse(trimmed) as object;
      const entries = Object.entries(parsed) as [string, number][];
      for (let index = 0; index < entries.length; index++) {
        if (entries[index][0] === 'ttlMs') {
          return entries[index][1];
        }
      }
    } catch {
      // ignore
    }
    return 300000;
  }
}

export const ngfContentPipelineFacade: ContentPipelineFacade = new ContentPipelineFacade();
