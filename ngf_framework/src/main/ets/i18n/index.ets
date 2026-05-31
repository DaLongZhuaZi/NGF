export { II18nManager, NGFDateStyle, NGFNumberStyle } from './contracts/II18nManager';
export {
  ITranslationResource,
  NGFTranslationLoadResult,
  NGFMissingKeyReport
} from './contracts/ITranslationResource';
export {
  IRelativeTimeFormatter,
  NGFRelativeTimeUnit,
  NGFRelativeTimeResult
} from './contracts/IRelativeTimeFormatter';
export { ngfI18nManagerFacade } from './facades/I18nManagerFacade';
export { ngfTranslationResourceFacade } from './facades/TranslationResourceFacade';
export { RelativeTimeFormatterFacade, ngfRelativeTimeFormatterFacade } from './facades/RelativeTimeFormatterFacade';
export { NGFI18nIntegrationFacade, ngfI18nIntegrationFacade } from './facades/NGFI18nIntegrationFacade';
export { resolveResourceString } from './utils/ResourceStringResolver';
