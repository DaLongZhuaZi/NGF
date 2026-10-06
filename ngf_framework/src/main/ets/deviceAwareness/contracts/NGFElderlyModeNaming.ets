/**
 * NGF 适老模式命名契约（附件2 §3.1）
 *
 * 规范原文（工信厅信管函〔2021〕67号 附件2 §3.1，已逐字核验）：
 *
 * > 应将「长辈版」作为标准功能名……同时设置「亲情版」「关爱版」「关怀版」等别名作为搜索关键字。
 *
 * 因此这里有**两条独立要求**，不要混为一谈：
 *
 * 1. **显示名**必须用标准功能名「长辈版」—— 通过 i18n 资源下发
 *    （`ngf_elderly_mode_standard_name`，zh_CN 下即「长辈版」）。
 * 2. **搜索关键字**必须能命中标准名与全部别名 —— 这是**字符串匹配**要求，
 *    与界面语言无关，所以匹配用的是规范里的**中文原词**，而不是本地化后的显示名。
 *
 * ## 为什么不把两者合成一个
 *
 * 如果把匹配建立在"当前语言的显示名"上，那么把系统语言切成英文后，
 * 用户搜「长辈版」就再也搜不到了 —— 而规范要求的是**这些词本身**能作为搜索关键字。
 * 显示走 i18n、匹配走规范原词，是两件必须分开的事。
 */

/** 附件2 §3.1 规定的标准功能名（规范中文原词，用于搜索匹配） */
export const NGF_ELDERLY_MODE_STANDARD_NAME_ZH: string = '长辈版';

/** 附件2 §3.1 允许的别名（规范中文原词，用于搜索匹配） */
export const NGF_ELDERLY_MODE_ALIASES_ZH: Array<string> = ['亲情版', '关爱版', '关怀版'];

/** 全部可匹配关键字：标准名在前，别名在后 */
export const NGF_ELDERLY_MODE_ALL_KEYWORDS_ZH: Array<string> =
  [NGF_ELDERLY_MODE_STANDARD_NAME_ZH].concat(NGF_ELDERLY_MODE_ALIASES_ZH);

/**
 * 标准功能名的显示资源（走 i18n）。
 * 在 zh_CN 下取值即规范要求的「长辈版」；其它语言下为对应译名。
 */
export function getElderlyModeDisplayName(): ResourceStr {
  return $r('app.string.ngf_elderly_mode_standard_name');
}

/**
 * 别名的显示资源（走 i18n），顺序与 `NGF_ELDERLY_MODE_ALIASES_ZH` 一致。
 * 用于在界面上把别名作为可点击的搜索建议展示出来。
 */
export function getElderlyModeAliasDisplayNames(): Array<ResourceStr> {
  const names: Array<ResourceStr> = [
    $r('app.string.ngf_elderly_mode_alias_family'),
    $r('app.string.ngf_elderly_mode_alias_care'),
    $r('app.string.ngf_elderly_mode_alias_solicitude')
  ];
  return names;
}

/** 关键字是否**恰好**是标准名或某个别名（去首尾空白后比较） */
export function matchesElderlyModeKeyword(keyword: string): boolean {
  const trimmed: string = keyword.trim();
  if (trimmed.length === 0) {
    return false;
  }
  return NGF_ELDERLY_MODE_ALL_KEYWORDS_ZH.includes(trimmed);
}

/**
 * 搜索框输入是否应命中适老模式。
 *
 * 用"关键字包含输入"做前缀/子串匹配，因为用户在搜索框里是**逐字输入**的
 * （输入「长」「长辈」「长辈版」都应逐步命中）。空串不算命中。
 */
export function isElderlyModeSearchHit(query: string): boolean {
  const trimmed: string = query.trim();
  if (trimmed.length === 0) {
    return false;
  }
  for (let i = 0; i < NGF_ELDERLY_MODE_ALL_KEYWORDS_ZH.length; i++) {
    if (NGF_ELDERLY_MODE_ALL_KEYWORDS_ZH[i].includes(trimmed)) {
      return true;
    }
  }
  return false;
}

/** 从一组关键字里筛出指向适老模式的那些（保序） */
export function filterElderlyModeKeywords(keywords: Array<string>): Array<string> {
  const matched: Array<string> = [];
  for (let i = 0; i < keywords.length; i++) {
    if (matchesElderlyModeKeyword(keywords[i])) {
      matched.push(keywords[i]);
    }
  }
  return matched;
}
