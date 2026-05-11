/**
 * 管道步骤执行结果
 */
export class NGFPipelineStepResult {
  readonly success: boolean;
  readonly output: string;
  readonly stepName: string;

  constructor(success: boolean, output: string, stepName: string) {
    this.success = success;
    this.output = output;
    this.stepName = stepName;
  }
}

/**
 * 管道执行结果
 */
export class NGFPipelineResult {
  readonly success: boolean;
  readonly output: string;
  readonly stepResults: Array<NGFPipelineStepResult>;

  constructor(success: boolean, output: string, stepResults: Array<NGFPipelineStepResult>) {
    this.success = success;
    this.output = output;
    this.stepResults = stepResults;
  }
}

/**
 * 管道步骤定义
 */
export class NGFPipelineStepDefinition {
  readonly stepName: string;
  readonly stepType: string;
  readonly config: string;

  constructor(stepName: string, stepType: string, config: string) {
    this.stepName = stepName;
    this.stepType = stepType;
    this.config = config;
  }
}

/**
 * 管道定义
 */
export class NGFPipelineDefinition {
  readonly pipelineName: string;
  readonly steps: Array<NGFPipelineStepDefinition>;

  constructor(pipelineName: string, steps: Array<NGFPipelineStepDefinition>) {
    this.pipelineName = pipelineName;
    this.steps = steps;
  }
}

/**
 * 内容管道接口
 * fetch → parse → transform → cache
 */
export interface IContentPipeline {
  registerPipeline(definition: NGFPipelineDefinition): void;
  execute(pipelineName: string, sourceId: string, input: string): Promise<NGFPipelineResult>;
  hasPipeline(pipelineName: string): boolean;
}
