# NGF 无障碍与适老化持续目标接管提示词

下面的内容可以直接交给另一个 Agent。它描述了当前 NGF 工作区的真实状态、已完成证据、未完成任务和执行规则。

```text
你正在接管 F:\DevEcoStudioProject\NGF 的持续目标：

持续推进 NGF 无障碍与适老化底层能力，按研究计划完成 HarmonyOS/ArkTS API 26 证据探针、国家标准与行业规范原文核验，更新设计与验收文档，再分阶段实现 NGF 契约、平台适配、UI/UX helper、适老化策略和测试验证；每阶段维护可追踪进度，不把未经验证的 API 或标准数值当作结论。

一、开始前必须读取

1. 根规则：`F:\DevEcoStudioProject\NGF\AGENTS.md`
2. 规则索引：`F:\DevEcoStudioProject\NGF\.rules\README.md`
3. 项目规则：`F:\DevEcoStudioProject\NGF\.agent-rules\README.md`、`project-rules.md`
4. 本地环境事实：`.local-rules/README.md`、`.local-rules/base-local-rules.md`
5. 无障碍研究计划：`docs/NGF_ACCESSIBILITY_ELDERLY_RESEARCH_PLAN.md`
6. 无障碍设计文档：`docs/NGF_ACCESSIBILITY_ELDERLY_DESIGN.md`
7. 当前任务检查点：`.agent-state/ngf-accessibility-elderly-research.local.md`
8. DevEco 同步诊断：`.local-rules/deveco-sync.local.md`
9. 相关技能：`skill-llm-onboarding.md`、`skill-local-rules.md`、`skill-arkts-standards.md`、`skill-arkts-types.md`、`skill-arkui-knowledge.md`、`skill-manager-apis.md`、`skill-automation-test.md`、`skill-i18n.md`、`skill-ui-symbols.md`、`skill-project-rule-governance.md`。

二、当前已验证事实

1. 工程根包名来自 `AppScope/app.json5`：`com.dlzz.ngf`。
2. API/兼容版本是 `26.0.0`，根配置在 `build-profile.json5`。
3. 工程模块是 `entry` 和 `ngf_framework`，入口页在 `entry/src/main/resources/base/profile/main_pages.json`。
4. DevEco 26 SDK 可用：
   - SDK 根目录：`G:\DevEco Studio 26\DevEco Studio\sdk\default\openharmony`
   - API 声明：`ets/kits/@kit.AccessibilityKit.d.ts`、`ets/kits/@kit.ArkUI.d.ts`
   - 通用声明：`ets/build-tools/ets-loader/declarations/common.d.ts`
   - Hvigor：`G:\DevEco Studio 26\DevEco Studio\tools\hvigor\bin\hvigorw.bat`
5. DevEco 26 Hvigor 已验证：
   - `tasks --no-daemon --stacktrace` 成功。
   - `init --no-daemon --stacktrace` 成功。
   - `-s --no-daemon --stacktrace` 成功，并生成 `.hvigor/outputs/sync/output.json` 和 `taskInfo.json`。
6. `output.json` 已明确包含：
   - `BUNDLE_NAME=com.dlzz.ngf`
   - `entry` / `ngf_framework`
   - `default` target
   - `applyToProducts=default`
7. 使用 DevEco 26 Hvigor 执行 `assembleApp --no-daemon --stacktrace` 时，已经通过：
   - ArkTS 编译
   - 资源处理
   - HAP 打包
   - 生成 `entry/build/default/outputs/default/entry-default-unsigned.hap`
8. 之前阻塞编译的两个缺失文件已补齐：
   - `ngf_framework/obfuscation-rules.txt`
   - `ngf_framework/consumer-rules.txt`
9. 当前签名 profile 在后续 DevEco 证书流程中已出现/更新，但签名材料属于本机私有状态，绝不提交、复制到公开仓库或写入提示词/日志。

三、DevEco 同步问题的真实根因

不要再把问题归因于“AppScope 没有包名”或“build-profile 缺失”。

用户提供的 `G:\Huawei\DevEcoStudio26.0\log\idea.log` 中，NGF 同步失败时出现：

- `TargetManager: getCurrentTarget is null`
- `product#getTargetNameSetByModulePath is null, moduleName: entry`
- `HvigorDependencyInfo: The root node of hvigor lock yaml is null`
- `AppAnalyzer syncFailed: sync ohos project error`

最终通过本机日志、DevEco 26 反编译代码和用户级 Hvigor 缓存确认：

- `RuntimeHandler.needExecPnpm` 会读取用户级缓存：
  `%USERPROFILE%\\.hvigor\\project_caches\\34c6657ee84fd5bd7d254d496cdfddac\\workspace\\package.json`
- 该缓存文件曾被写成 `{"name":"workspace","version":"1.0.0"}`，缺少 `dependencies`。
- DevEco 的 `get("dependencies").size()` 对该文件触发 NullPointerException。
- 后续的 TargetManager、HvigorDependencyInfo、AppAnalyzer 错误都是同步中断后的连带症状。
- 已删除该污染缓存并保留备份：`workspace.package.json.bak_sync_npe_20261005`。
- 其他被同一批脚本污染的缓存已备份到：`C:\Users\13359\.hvigor\_poison_backup_20261005\`。
- 修复后用等价逻辑复算 `needExecPnpm=false`，并用 Hvigor `-s` 验证同步产物重新生成。

不要恢复或创建一个没有 `dependencies` 字段的用户级 workspace/package.json。正常状态下该文件可以不存在；不要用项目根 `package.json` 替代它。

四、当前 NGF 无障碍实现状态

原有能力：

- `AccessibilityFacade` 已使用 `@kit.AccessibilityKit` 的 `isOpenAccessibilitySync()`。
- 旧代码曾把 `isOpenTouchGuideSync()` 误当成屏幕朗读状态。
- 已有 `ngf.device.accessibility` 服务注册。

已落地的第一版 P3 契约：

- `IAccessibilityManager` 增加：
  - `NGFAccessibilityState`
  - `NGFAccessibilityStateSnapshot`
  - `NGFAccessibilityStateListener`
  - `isTouchGuideEnabled()`
  - `isAnimationReduceEnabled()`
  - `getStateSnapshot()`
  - `addStateListener()` / `removeStateListener()`
- `AccessibilityFacade` 已使用 API 26 的：
  - `isOpenAccessibilitySync()`
  - `isOpenTouchGuideSync()`
  - `isScreenReaderOpenSync()`
  - `isAnimationReduceEnabledSync()`
  - `on('accessibilityStateChange', ...)`
  - `on('touchGuideStateChange', ...)`
  - `on('screenReaderStateChange', ...)`
  - `onAnimationReduceStateChange(...)`
- 状态变化后会刷新快照并通知 NGF listener。
- `deviceAwareness/index.ets` 已导出相关契约和 `ngfAccessibilityFacade`。
- 这些源码已通过 API 26 ArkTS 编译阶段，但尚未做真机读屏、焦点、动效和 UI 语义验收。

五、研究文档和标准状态

已完成：

- 研究计划和设计文档已经建立。
- GB/T 37668-2019 已通过全国标准信息公共服务平台核验为现行推荐性国家标准：
  - 发布日期：2019-08-30
  - 实施日期：2020-03-01
  - 修订计划：`20252537-T-469`
- WCAG 2.2 作为国际工程参考，已记录 4.5:1、3:1、焦点顺序、目标尺寸、动效等参考维度。
- 工信部适老化/无障碍专项行动的正式标题、文号、条款仍未稳定从官方原文核验，不能把搜索摘要当标准条款。
- NGF 工程基线必须与国家标准条款分开记录，不能把 16vp、48vp、4.5:1 等工程基线伪装成中国标准原文。

六、必须保持的设计边界

1. NGF 是通用框架，不要把设计写成某个具体业务 App 的流程。
2. 平台层、语义契约层、适配策略层、UI helper 层分离。
3. 页面不得直接散落调用 `@kit.AccessibilityKit`。
4. 读屏状态、触摸探索状态、系统总无障碍状态必须区分。
5. `accessibility.on(...)` 必须有对应的 `off(...)` 或受控生命周期；不得注册匿名回调后无法取消。
6. UI 文案必须走 i18n；不要在 helper 中硬编码中文提示。
7. 图标使用系统 Symbol，不使用新 Emoji 作为无障碍状态指示。
8. 不把编译成功、自动点击成功或默认截图当作无障碍完成证明。
9. 任何 API 结论必须有 API 26 SDK 声明、官方文档或设备证据。
10. 任何标准数值必须标注来源、条款状态和是否只是 NGF 工程基线。
11. 不要提交 `.idea`、`.deveco`、`.hvigor`、`local.properties`、证书、profile、密钥、密码或用户级缓存。
12. 当前工作区是脏的；不要 reset、checkout、clean 或覆盖用户已有修改。

七、下一步执行顺序

P2：标准与政策核验

1. 从工信部官方站点核对适老化专项行动的正式通知标题、文号、发布日期和可引用条款。
2. 继续核验 GB/T 37668-2019 的公开可引用条款；无法获取全文时只记录标准身份，不写伪精确条款。
3. 更新 `docs/NGF_ACCESSIBILITY_ELDERLY_DESIGN.md` 的标准矩阵和证据等级。

P3：语义和策略契约

1. 设计并实现命名的 `NGFAccessibilitySemantics` 模型：id、role、label、description、value、state、actions、grouping、traversalOrder。
2. 设计 `NGFInclusiveDesignPolicy`：textScale、touchTarget、contrast、motion、density。
3. 只在 API 26 声明确认的范围内实现组件 helper；未确认的焦点/自定义动作接口先留契约和探针。
4. 保持旧 `IAccessibilityManager` 方法兼容，避免一次性破坏现有导入。

P4：UI helper 和验证

1. 建设可复用的 accessible Button/Form/List/Navigation/Dialog 模式。
2. 引入动态字号、触控目标、对比度、非颜色冗余、动效降级策略。
3. 用户可控的适老 profile 必须持久化、可恢复、可关闭。
4. 所有页面订阅必须在销毁生命周期取消。
5. 增加框架验证页和 Hypium/UI 自动化用例。

P5：真机验收

分别报告：源码/类型、运行时、语义树、读屏、视觉、触控、动效、生命周期和性能证据。

八、每轮工作必须做的检查

1. 开始前重新读取当前工作区 Git 状态，不要假设摘要仍然准确。
2. 修改前列出将要修改的文件和验证方式。
3. 修改后运行 `git diff --check`，检查 ArkTS 类型和导出关系。
4. 如果涉及构建，使用 DevEco 26 Hvigor：
   `$env:DEVECO_SDK_HOME='G:\\DevEco Studio 26\\DevEco Studio\\sdk'; & 'G:\\DevEco Studio 26\\DevEco Studio\\tools\\hvigor\\bin\\hvigorw.bat' assembleApp --no-daemon --stacktrace`
5. 如果只需同步项目模型，使用：
   `$env:DEVECO_SDK_HOME='G:\\DevEco Studio 26\\DevEco Studio\\sdk'; & 'G:\\DevEco Studio 26\\DevEco Studio\\tools\\hvigor\\bin\\hvigorw.bat' -s --no-daemon --stacktrace`
6. 不把签名失败误判成 ArkTS/API 失败；区分编译、打包、签名和设备运行证据。
7. 更新 `docs/NGF_ACCESSIBILITY_ELDERLY_RESEARCH_PLAN.md`、`docs/NGF_ACCESSIBILITY_ELDERLY_DESIGN.md` 和 `.agent-state/ngf-accessibility-elderly-research.local.md`。
8. 完成前报告：已完成、未完成、阻塞、验证命令、生成物和下一步。
```
