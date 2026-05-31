/**
 * 错误处理工具模块
 * @module ErrorUtils
 * @description 提供统一的错误转换和处理工具函数
 * @note API 23 适配：从各 facade 中提取 errorToString 方法，消除代码重复
 */

/**
 * 将错误对象转换为字符串
 * @param error - 错误对象，可以是 Error、string、number、boolean 或 Object
 * @returns 错误信息的字符串表示
 * @note 统一处理各种类型的错误，避免代码重复
 */
export function errorToString(error: Error | string | number | boolean | Object): string {
  if (typeof error === 'string') {
    return error;
  }
  if (typeof error === 'number' || typeof error === 'boolean') {
    return String(error);
  }
  if (error instanceof Error) {
    return error.message;
  }
  return String(error);
}

/**
 * 错误类型枚举
 * @description 定义常见的错误分类，便于统一处理
 */
export enum NGFErrorCategory {
  /** 系统级错误 */
  SYSTEM = 'SYSTEM',
  /** 网络错误 */
  NETWORK = 'NETWORK',
  /** 存储错误 */
  STORAGE = 'STORAGE',
  /** 用户输入错误 */
  INPUT = 'INPUT',
  /** 业务逻辑错误 */
  BUSINESS = 'BUSINESS',
  /** 未知错误 */
  UNKNOWN = 'UNKNOWN'
}

/**
 * 标准化错误信息
 * @param error - 原始错误对象
 * @param category - 错误分类
 * @param context - 错误发生的上下文信息
 * @returns 标准化的错误信息字符串
 */
export function formatErrorMessage(
  error: Error | string | number | boolean | Object,
  category: NGFErrorCategory = NGFErrorCategory.UNKNOWN,
  context: string = ''
): string {
  const errorMessage = errorToString(error);
  const contextPrefix = context ? `[${context}] ` : '';
  return `${contextPrefix}[${category}] ${errorMessage}`;
}
