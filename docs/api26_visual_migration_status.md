# API26 视效迁移状态

## 本批范围

- 来源报告：`docs/20260614123648_apiChange.csv`
- 处理类别：`UX视觉布局变更`
- 重点变更：
  - Dialog、Toast、AlphabetIndexer 和文本选择菜单默认开启沉浸式系统材质
  - 内置文本组件样式优化
  - 表单类组件触摸热区最小高度变更

## 已落实

- `ngfVisualEffectsFacade` 增加系统材质策略：跟随系统、强制沉浸、关闭材质。
- `ngfVisualEffectsFacade` 增加主链路视效 helper：普通面板、显著面板、浮动控件三类 API26 系统材质入口。
- 新增 `NGFMaterialSurfaceTokens`，统一主视觉卡、普通面板、交互控件和 Sheet 的背景效果、阴影与圆角建议值。
- `NGFMaterialSurfaceTokens` 增加 material-aware fallback：系统材质启用时返回透明背景、透明边框、无自定义背景模糊与阴影；关闭材质时回退旧面板样式。
- Overlay、Toast、Dialog、SegmentButton、设置页 Sheet 接入统一系统材质策略。
- Sheet 默认使用 API26 `ULTRA_THICK` 系统材质，并在启用系统材质时强制透明背景与 `BlurStyle.NONE`，避免实色背景和双重模糊遮挡玻璃透底。
- HDS Tabs 当前 wrapper 未暴露 ArkUI `FloatingTabBarStyle.systemMaterial` 字段，已通过 HDS `systemMaterialEffect` 跟随 NGF 生效材质档位。
- 直接页面 Toast 调用迁移到 `ngfOverlayManagerFacade`，避免绕过框架策略。
- 新增 `NGFControlStyleTokens`，热点页面的小按钮显式使用 `ControlSize.SMALL/NORMAL` 与共享高度。
- `NGFSettingsPage` 增加 API26 系统材质策略展示与切换入口。
- 主链路页面已接入材质策略：`MainMenuPage` 五个 Tab 可见主卡、HDS 综合展示页、HDS 官方展示入口页、系统资源预览页、设置页。
- 主链路大卡已按“底层渐变 underlay + 上层透明 systemMaterial 节点”拆分，避免在同一节点叠加实色渐变、背景模糊、阴影和系统材质。
- 一跳演示页已按低侵入方式接入：任务管理、数据存储、安全性能、工作流、设备显示、同步管理、错误恢复、能力验证入口与能力子页。

## 验证重点

- Toast、Dialog、Sheet 在三种系统材质策略下是否符合预期。
- HDS Tabs 和 SegmentButton 的材质是否能跟随策略变化。
- 32/36/40vp 紧凑按钮在 API26 下是否仍保持可点、文本不溢出。
- `CommonMethod<T>` Stage-only 约束仍作为全量 API26 构建扫描项，不在本批做无关重构。
- API26 命令行构建需设置 `$env:DEVECO_SDK_HOME='G:\DevEco Studio 26\DevEco Studio\sdk'`，不能指向 `sdk\default`。
