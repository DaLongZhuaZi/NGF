/**
 * 字符串工具类
 * @module utils/StringUtils
 * @description NGF 框架常用字符串处理工具
 */

export class StringUtils {
  /**
   * 判断字符串是否为 null、undefined 或空字符串
   */
  static isNullOrEmpty(value: string | null | undefined): boolean {
    if (value === null || value === undefined) {
      return true;
    }
    return value.length === 0;
  }

  /**
   * 判断字符串是否为 null、undefined、空字符串或仅含空白字符
   */
  static isNullOrWhitespace(value: string | null | undefined): boolean {
    if (value === null || value === undefined) {
      return true;
    }
    return value.trim().length === 0;
  }

  /**
   * 截断字符串到指定最大长度，超出部分以 suffix 替代
   * @param value 原始字符串
   * @param maxLength 最大长度（含 suffix）
   * @param suffix 省略后缀，默认 '...'
   */
  static truncate(value: string, maxLength: number, suffix: string = '...'): string {
    if (maxLength < 0) {
      return '';
    }
    if (value.length <= maxLength) {
      return value;
    }
    if (maxLength <= suffix.length) {
      return suffix.substring(0, maxLength);
    }
    return value.substring(0, maxLength - suffix.length) + suffix;
  }

  /**
   * 首字母大写，其余保持不变
   */
  static capitalize(value: string): string {
    if (value.length === 0) {
      return value;
    }
    return value.charAt(0).toUpperCase() + value.substring(1);
  }

  /**
   * camelCase 转 snake_case
   */
  static camelToSnake(value: string): string {
    if (value.length === 0) {
      return value;
    }
    let result = '';
    for (let i = 0; i < value.length; i++) {
      const ch = value.charAt(i);
      const upperCode = ch.charCodeAt(0);
      if (upperCode >= 65 && upperCode <= 90) {
        if (i > 0) {
          result += '_';
        }
        result += ch.toLowerCase();
      } else {
        result += ch;
      }
    }
    return result;
  }

  /**
   * snake_case 转 camelCase
   */
  static snakeToCamel(value: string): string {
    if (value.length === 0) {
      return value;
    }
    let result = '';
    let capitalizeNext = false;
    for (let i = 0; i < value.length; i++) {
      const ch = value.charAt(i);
      if (ch === '_') {
        capitalizeNext = true;
      } else if (capitalizeNext) {
        result += ch.toUpperCase();
        capitalizeNext = false;
      } else {
        result += ch;
      }
    }
    return result;
  }

  /**
   * 忽略大小写判断 haystack 是否包含 needle
   */
  static containsIgnoreCase(haystack: string, needle: string): boolean {
    if (needle.length === 0) {
      return true;
    }
    if (haystack.length === 0) {
      return false;
    }
    return haystack.toLowerCase().indexOf(needle.toLowerCase()) >= 0;
  }

  /**
   * 移除字符串开头的指定前缀；若不匹配则原样返回
   */
  static removePrefix(value: string, prefix: string): string {
    if (prefix.length === 0) {
      return value;
    }
    if (value.length >= prefix.length && value.substring(0, prefix.length) === prefix) {
      return value.substring(prefix.length);
    }
    return value;
  }

  /**
   * 移除字符串末尾的指定后缀；若不匹配则原样返回
   */
  static removeSuffix(value: string, suffix: string): string {
    if (suffix.length === 0) {
      return value;
    }
    if (value.length >= suffix.length && value.substring(value.length - suffix.length) === suffix) {
      return value.substring(0, value.length - suffix.length);
    }
    return value;
  }
}
