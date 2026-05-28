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
export * from './webBridge/index';

// Security
export * from './security/index';

// Hardware
export * from './hardware/index';

// Media
export * from './media/index';
export * from './media/components/NGFAVPlayer';

// Push
export * from './push/index';

// Interconnect
export * from './interconnect/index';
