// 聚合导出所有的能力门面与契约

// System Tasks (系统与常驻任务)
export * from './systemTasks/index';

// Core & Workflow
export * from './core/starter/StarterKernel';
export * from './core/contracts/IEventBus';

// Theme & Locale
export * from './uiTheme/contracts/IThemeManager';
export * from './uiTheme/facades/ThemeManagerFacade';
export * from './i18n/facades/I18nManagerFacade';

// Platform
export * from './platformOhos/UIContextManager';

// Device Awareness
export * from './deviceAwareness/facades/HoldingAwarenessFacade';

// -- 新增的 9 大能力模块 --

// Network
export * from './network/contracts/INetworkClient';
export * from './network/facades/NetworkManagerFacade';

// RDB Data
export * from './data/rdb/contracts/IRelationalStore';
export * from './data/rdb/facades/RdbManagerFacade';

// WebBridge
export * from './webBridge/contracts/IWebBridge';
export * from './webBridge/facades/WebManagerFacade';
export * from './webBridge/components/NGFWebView';

// Security
export * from './security/facades/UserAuthenticationFacade';
export * from './security/facades/KeyStoreManagerFacade';

// Hardware
export * from './hardware/facades/LocationManagerFacade';
export * from './hardware/facades/SensorManagerFacade';

// Media
export * from './media/facades/MediaPickerFacade';
export * from './media/components/NGFAVPlayer';

// Push
export * from './push/facades/PushManagerFacade';

// Interconnect
export * from './interconnect/facades/AppLinkingFacade';
