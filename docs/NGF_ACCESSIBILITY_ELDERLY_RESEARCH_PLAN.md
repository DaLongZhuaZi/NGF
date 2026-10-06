# NGF 无障碍与适老化底层能力研究计划

**任务状态**：计划中  
**创建日期**：2026-10-05  
**适用范围**：NGF 框架（`ngf_framework`）的无障碍、适老化 UI/UX、功能设计与优化  
**当前阶段**：P1 证据矩阵完成（API 26 SDK 声明逐行核对）；P2 中国官方规范数值核验完成；P3 第二批契约已落地并通过编译打包；P4/P5 未开始

## 目标

为 NGF 建立可复用的无障碍与适老化能力基线，先确认 ArkTS/ArkUI 与 HarmonyOS 系统 API 的可用能力，再基于可核验的国家标准、行业规范和官方设计建议形成分层设计、指标、验收方式与实施任务。研究结论必须区分“官方 API 已证实”“标准推荐值”“NGF 设计决策”和“待设备验证”。

## 工作边界

- 覆盖框架层契约、平台适配、UI/UX 组件模式、设置与状态管理、国际化、测试验收。
- 重点关注视觉、听觉、触控、运动/认知、读屏语义、动态字体、对比度、触控目标、动效减弱和老年模式。
- 不在本阶段直接修改业务页面或宣称通过国家认证；源码实现将在研究文档和验收矩阵评审后另行执行。
- 不把现有 `AccessibilityFacade` 的状态查询和文本拼接误认为完整能力。

## 阶段与验收

| 阶段 | 内容 | 产出 | 状态 |
|---|---|---|---|
| P0 | 规则、仓库现状、既有能力和入口盘点 | 本计划、现状清单 | 已完成（2026-10-05） |
| P1 | ArkTS/ArkUI/HarmonyOS 官方 API 检索与版本适配 | 官方 API 证据矩阵、能力缺口 | **已完成（SDK 声明逐行核对）**：18 项 ArkUI 属性 + 11 项平台信号 + 5 项适老模式 API + 3 项感官辅助能力，均标注 @since；编译与签名验证通过。设备运行时行为仍待 P5 |
| P2 | 国家标准、行业规范、官方设计指南检索 | 标准条款与推荐值矩阵 | **已完成**：工信厅信管函〔2021〕67号 附件2《移动互联网应用（APP）适老化通用设计规范》全文逐字核验（含 18/30 dp/pt、1.3 倍行距、4.5:1、44/48/60 dp/pt 触控、44 dp/pt 浮窗关闭键、"长辈版"命名等 13 条）；GB/T 37668-2019 身份与修订计划已核验、条款原文未取得（已标注不可引用） |
| P3 | NGF 分层架构与 UI/UX 功能设计 | 设计文档、接口草案、状态/配置模型 | **第一批+第二批契约已落地**（语义模型、策略模型、状态快照、适老模式、生命周期）；注册表/播报/焦点导航保留为待探针项 |
| P4 | 实施拆分与验证设计 | 任务清单、静态/设备/UI/性能验收门槛 | 待开始 |
| P5 | 评审与后续实现入口 | 评审记录、下一阶段变更边界 | 待开始 |

## 证据规则

1. HarmonyOS API 必须引用华为官方开发者文档或 SDK 声明，并记录 API 名称、模块、最低 API/版本、同步/异步语义和限制。
2. 标准数值必须记录标准编号、条款或公开发布来源、适用对象和是否为强制要求；无法核验条款原文时标记为“待核验”，不得伪造精确值。
3. UI/UX 推荐值与平台 API 能力分开记录；推荐值不能反向声称为系统硬性约束。
4. 每个设计决策必须映射到 API、标准、现有 NGF 层或明确的待验证项。
5. 进度更新只在完成对应证据或产出后勾选，并记录日期和验证方式。

## 当前已知事实

- `ngf_framework/src/main/ets/deviceAwareness/facades/AccessibilityFacade.ets` 已使用 `@kit.AccessibilityKit` 的 `isOpenAccessibilitySync()` 与 `isOpenTouchGuideSync()`。
- `IAccessibilityManager` 当前只包含状态查询、标签构建和提示文本构建。
- `NGFDeviceAwarenessIntegrationFacade` 已注册 `ngf.device.accessibility` 服务。
- 仓库目标/兼容 SDK 为 API 26；DevEco 26 SDK 声明和 NGF ArkTS 编译阶段已实测可用。
- ~~当前没有适老化模式、动态字体策略、语义树/可操作性封装、无障碍事件订阅、颜色对比度检查、动效减弱策略或专项验收矩阵的完整框架契约。~~
  **（2026-10-05 更新）该缺口已大部分闭合**：适老模式（系统 + 本应用）、动态字体
  （`fontSizeScale: followSystem` + `NGF_APP_FONT_SIZE_MAX_SCALE`）、语义树封装
  （`NGFAccessibilitySemantics` + `auditAccessibilitySemantics`）、无障碍事件订阅
  （`AccessibilityFacade` 六事件 + `NGFAccessibilityLifecycleBinding`）、
  颜色对比度检查（`NGFContrastChecker`）、动效减弱策略（`motionDurationScale` 三档）
  均已落地并有单测。
  **仍缺**：专项验收矩阵的**真机**部分（无设备，P5 阻塞）。

## 下一步

1. ~~进入 P4：按已核验的附件2 数值实现 UI helper（触控目标 44/48/60 dp/pt 分上下文、行距 1.3 倍、对比度 4.5:1/3:1、浮窗关闭键 44 dp/pt 且位置受限）~~
   **（2026-10-05 完成）**：已落地为 `NGFInclusiveDesignTokens` + `NGFContrastChecker` + 四个可复用组件
   （`NGFAccessibleButton` / `NGFAccessibleListItem` / `NGFAccessibleDialogCloseButton` / `NGFAccessibleFormField`）。
2. ~~完成 §5.1.2 三项探针决策（语义注册表、播报、焦点导航）后进入 UI helper 实现。~~
   **（2026-10-05 部分完成）**：语义注册表改为 `NGFAccessibilitySemantics` + 审计；
   焦点导航探明 API 26 的 `accessibilityNextFocusId(nextId, nextFocusParams)`；
   播报（announcer）仍未见公开入口，保持未决。
3. ~~建立框架验证页与 Hypium 用例，把 `auditAccessibilitySemantics()` 的问题码纳入回归断言。~~
   **（2026-10-05 完成）**：验证页 `NGFAccessibilityShowcasePage` 已接路由与主菜单；
   无障碍契约单测 **48/48 全通过**，问题码已纳入断言。
4. **仍未完成**：① "长辈版"标准命名与别名（亲情版/关爱版/关怀版）的 i18n 资源；
   ② 在真机/模拟器上完成 P5 验收矩阵（**阻塞于无设备**）；
   ③ 显示密度（DPI）读取接口探针。

## P2 已核验的中国官方规范数值（2026-10-05）

来源：**工信厅信管函〔2021〕67号 附件2《移动互联网应用（APP）适老化通用设计规范》**，2026-10-05 从 miit.gov.cn 原文页面逐字抓取核验。

- 主要功能/界面**最大字体不小于 30 dp/pt**；适老版界面及单独适老版 APP 主要文字**不小于 18 dp/pt**（§1.1）
- 段落内行距**至少 1.3 倍**，段距**至少比行距大 1.3 倍**（§1.2）
- 对比度**至少 4.5:1**，字号大于 18 dp/pt 时**至少 3:1**（§1.3）
- 触控焦点：适老版界面**不小于 60×60 dp/pt**；其他页面**不小于 44×44 dp/pt**；单独适老版 APP 首页**不小于 48×48 dp/pt**（§2.1）
- 浮窗关闭按钮**不小于 44×44 dp/pt**，且只可在左上、右上、中央底部（§2.4）
- 避免需 3 个或以上手指的复杂手势（§2.2）；操作完毕前界面不变化（§2.3）
- **"长辈版"是标准功能名**，需支持搜索直达，并配置"亲情版/关爱版/关怀版"别名（§3.1）
- 不得禁止或限制终端厂商已适配好的辅助设备（如读屏软件）（§4.1）

不可引用：GB/T 37668-2019 条款数值（全文公开但本轮未逐字获取）、GB/T 37668 修订版标准号（计划 20252537-T-469 仍"正在批准"）、工信部信管〔2020〕200号附件《行动方案》与工信部信管〔2023〕251号《工作方案》正文。

引用陷阱：67 号文原文引用的 YD/T1822-2008 已废止（其 2012 版亦废止，现行替代为 GB/Z 41284-2022）。

## 本轮新增的关键事实（2026-10-05）

- **API 26 提供应用粒度适老模式**：`getSeniorModeStateForSelf()` / `setSeniorModeStateForSelf()` / `on|offSeniorModeStateChangeForSelf`（`@since 26.0.0`）。NGF 不应自造一套并行开关。
- **官方强制监听配对**：所有 `accessibility.on*` 都要求命名函数回调 + 生命周期内 `off`，否则可能内存泄漏甚至崩溃。
- **ArkUI 26 的可执行无障碍动作只有点击**：`AccessibilityAction` 仅 `UNDEFINED_ACTION` / `ACCESSIBILITY_CLICK`，其余动作只能作为语义描述。
- **没有 accessibilityEnabled / accessibilityExpanded 属性**：enabled 由组件自身状态表达，expanded 只能经 `accessibilityStateDescription` 文本表达。
- **感官辅助能力可复用**：闪光提醒、单声道音频、字幕管理（`@since 23` / `@since 8`）应作为系统信号接入"听觉"维度。

