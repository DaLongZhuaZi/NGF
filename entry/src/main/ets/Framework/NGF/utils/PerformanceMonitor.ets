import { hilog, hidebug } from '@kit.PerformanceAnalysisKit';
import { logger } from './Logger';

const TAG: string = 'NGFPerformanceMonitor';

/**
 * 性能打点记录
 */
export class NGFPerformanceMark {
  readonly name: string;
  readonly timestamp: number;

  constructor(name: string, timestamp: number) {
    this.name = name;
    this.timestamp = timestamp;
  }
}

/**
 * 性能度量结果
 */
export class NGFPerformanceMeasure {
  readonly name: string;
  readonly startMark: string;
  readonly endMark: string;
  readonly durationMs: number;

  constructor(name: string, startMark: string, endMark: string, durationMs: number) {
    this.name = name;
    this.startMark = startMark;
    this.endMark = endMark;
    this.durationMs = durationMs;
  }
}

/**
 * 内存快照
 */
export class NGFMemorySnapshot {
  readonly timestamp: number;
  readonly usedPssKb: number;

  constructor(timestamp: number, usedPssKb: number) {
    this.timestamp = timestamp;
    this.usedPssKb = usedPssKb;
  }
}

/**
 * 性能监控工具
 */
class PerformanceMonitor {
  private static instance: PerformanceMonitor | null = null;
  private readonly marks: Map<string, NGFPerformanceMark> = new Map<string, NGFPerformanceMark>();
  private readonly measures: Array<NGFPerformanceMeasure> = [];
  private readonly memorySnapshots: Array<NGFMemorySnapshot> = [];

  private constructor() {
    // 私有构造函数，确保单例模式
  }

  static getInstance(): PerformanceMonitor {
    if (!PerformanceMonitor.instance) {
      PerformanceMonitor.instance = new PerformanceMonitor();
    }
    return PerformanceMonitor.instance;
  }

  /**
   * 记录性能打点
   */
  mark(name: string): void {
    const normalizedName = name.trim();
    if (normalizedName.length <= 0) {
      return;
    }
    const now = Date.now();
    this.marks.set(normalizedName, new NGFPerformanceMark(normalizedName, now));
    logger.debug(TAG, `打点: ${normalizedName}, 时间=${now}`);
  }

  /**
   * 测量两个打点之间的时间差
   */
  measure(name: string, startMark: string, endMark: string): NGFPerformanceMeasure | null {
    const start = this.marks.get(startMark);
    const end = this.marks.get(endMark);
    if (start === undefined || end === undefined) {
      logger.warn(TAG, `测量失败: startMark=${startMark}, endMark=${endMark}`);
      return null;
    }
    const durationMs = end.timestamp - start.timestamp;
    const measure = new NGFPerformanceMeasure(name, startMark, endMark, durationMs);
    this.measures.push(measure);
    logger.info(TAG, `测量: ${name}, ${startMark} -> ${endMark}, 耗时=${durationMs}ms`);
    return measure;
  }

  /**
   * 获取打点时间戳
   */
  getMark(name: string): NGFPerformanceMark | null {
    const mark = this.marks.get(name.trim());
    return mark !== undefined ? mark : null;
  }

  /**
   * 获取所有度量结果
   */
  getMeasures(): Array<NGFPerformanceMeasure> {
    const copied: Array<NGFPerformanceMeasure> = [];
    for (let index = 0; index < this.measures.length; index++) {
      copied.push(this.measures[index]);
    }
    return copied;
  }

  /**
   * 记录内存快照
   */
  snapshotMemory(): NGFMemorySnapshot {
    const now = Date.now();
    let usedPssKb: number = 0;
    try {
      const memInfo = hidebug.getAppNativeMemInfo();
      usedPssKb = Number(memInfo.pss);
    } catch {
      usedPssKb = 0;
    }
    const snapshot = new NGFMemorySnapshot(now, usedPssKb);
    this.memorySnapshots.push(snapshot);
    logger.debug(TAG, `内存快照: PSS=${usedPssKb}KB`);
    return snapshot;
  }

  /**
   * 获取内存快照历史
   */
  getMemorySnapshots(): Array<NGFMemorySnapshot> {
    const copied: Array<NGFMemorySnapshot> = [];
    for (let index = 0; index < this.memorySnapshots.length; index++) {
      copied.push(this.memorySnapshots[index]);
    }
    return copied;
  }

  /**
   * 清除所有记录
   */
  clear(): void {
    this.marks.clear();
    this.measures.length = 0;
    this.memorySnapshots.length = 0;
    logger.info(TAG, '清除所有性能记录');
  }

  /**
   * 输出启动耗时报告到 hilog
   */
  reportToHilog(): void {
    for (let index = 0; index < this.measures.length; index++) {
      const m = this.measures[index];
      hilog.info(0x0000, TAG, `[Perf] ${m.name}: ${m.durationMs}ms (${m.startMark} -> ${m.endMark})`);
    }
    if (this.memorySnapshots.length > 0) {
      const last = this.memorySnapshots[this.memorySnapshots.length - 1];
      hilog.info(0x0000, TAG, `[Perf] Memory: ${last.usedPssKb}KB`);
    }
  }
}

export const performanceMonitor: PerformanceMonitor = PerformanceMonitor.getInstance();
