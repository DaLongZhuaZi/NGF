# ngf-platform-ohos

当前阶段:

1. 定义平台窗口、页面策略与上下文桥接契约。
2. 通过 `PlatformWindowManagerFacade` 统一管理 `WindowStage` / `Window` 生命周期、窗口监听与页面策略。

## 已接入的官方窗口接口

- `WindowStage.getMainWindowSync()`
- `WindowStage.on('windowStageEvent', ...)`
- `Window.setWindowLayoutFullScreen(...)`
- `Window.setSpecificSystemBarEnabled(...)`
- `Window.setWindowSystemBarProperties(...)`
- `Window.getWindowSystemBarProperties()`
- `Window.getWindowProperties()`
- `Window.getWindowAvoidArea(...)`
- `Window.getPreferredOrientation()`
- `Window.setPreferredOrientation(...)`
- `Window.getWindowStatus()`
- `Window.isFocused()`
- `Window.isImmersiveLayout()`
- `Window.on('windowSizeChange', ...)`
- `Window.on('avoidAreaChange', ...)`
- `Window.on('windowStatusChange', ...)`

## 统一监控输出

- `ngf_window_ready`
- `ngf_window_active_page`
- `ngf_window_display_mode`
- `ngf_window_status`
- `ngf_window_snapshot_updated_at`
- `ngf_window_snapshot_json`

## 页面接入约定

- `EntryAbility.onWindowStageCreate()` 绑定 `WindowStage`
- `EntryAbility.onWindowStageDestroy()` 清理窗口绑定
- 页面层统一通过 `uiShell/PagePolicyHostFacade` 或页面辅助层激活窗口策略
- 不再把 `entry/src/main/ets/Utils/WindowManager.ets` 作为新增窗口能力的主实现入口
