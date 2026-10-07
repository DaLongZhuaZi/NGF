# NGF 项目专属规则登记册

本登记册只记录无法自然归入根 `AGENTS.md`、`.rules/` 或 `.local-rules/` 的当前工作区规则。所有 `active` 条目都必须在任务执行中遵守；`candidate` 条目仅用于后续验证，不能约束实现。

## Active Rules

### PR-001 项目专属规则的自动治理与执行

**状态**：active
**范围**：当前 NGF 工作区，以及后续在本仓库内创建或长期维护的 NGF 应用模块。
**指令**：当用户表达持续适用的非敏感偏好，或任务产生有充分证据支持的项目/App 稳定模式、Harness 改进时，Agent 必须按 `.rules/skill-project-rule-governance.md` 提炼并写入正确层级；执行源码任务前必须读取并遵守所有 `active` 项目规则和不冲突的本地偏好。一次性判断保持为 `candidate` 或任务状态，除非用户提出相反要求。
**来源**：用户关于“使用 NGF 创建新 App 时，Agent 应精心收集、提炼并遵守项目专属规则、Harness 和个人偏好”的明确长期指令。
**证据**：根 `AGENTS.md` 的 `1.3`、`5.4`、`5.6.3` 与 `.rules/skill-project-rule-governance.md` 已建立相应读取、提炼、冲突处理和验证流程。
**验证**：每次中等及以上任务在评估、实现、复核和交付前检查有效规则；交付时说明本次新增、修订、保留为候选或未沉淀的结论。
**更新时间**：2026-08-13

### PR-002 NGF 项目的 CI 云端构建约定

**状态**：active
**范围**：NGF 仓库的 GitHub Actions 云端构建、镜像消费、自动发布；以及在本仓库内新建/维护应用模块时的构建交付。
**指令**：
1. NGF 消费镜像 `ghcr.io/dalongzhuazi/harmonyos-ci:api26r`（command-line-tools **26.0.0.821**，HarmonyOS 26.0.0 / API 26 **正式版**，与 DevEco Studio 26 Release 内置 SDK 一致）；镜像构建/维护统一在 [harmonyos-ci](https://github.com/DaLongZhuaZi/harmonyos-ci) 仓库，不要在本仓库重新引入 docker-image 构建。
   > ⚠️ **tag 必须与 `build-profile.json5` 的 `compatibleSdkVersion`（本工程 `26.0.0`）对齐。**
   > 曾用 `api26`（26.0.0.461 / Beta1），因代码使用 `HdsColorPicker`（Beta2 新增）而**编译失败**
   > （9×10505001 + 3 个 import 错误 + UI 语法错误），`Build HAP` 自 2026-08-29 起连续失败。
   > 详见 **PR-018**。
2. 涉及 CI、云端构建、镜像、automation、自动发布、免 DevEco 构建时，先读 `.rules/skill-ci-build.md`（通用技能）+ `docs/CI_Guide.md`/`docs/CI_Guide.en.md`（本项目双语完整步骤）。
3. 消费方只需维护 `.github/workflows/build.yml`（构建+自动滚动 nightly Release）、`.github/workflows/sign-and-release.yml`（tag 签名发布，未配 Secrets 时自动跳过）、`.github/scripts/strip_signing.py`（剥离本机签名配置产出未签名 HAP）。
4. 签名材料（证书/密钥/口令）只走 repository secrets，绝不入库；`.gitignore` 已拦截证书类文件。
**来源**：用户明确要求将 HarmonyOS CI 云端构建纳入本项目 agent 规则库、并同步 NGF 项目。
**证据**：`.github/workflows/build.yml`、`.github/workflows/sign-and-release.yml`、`.github/scripts/strip_signing.py`、`docs/CI_Guide.md`；镜像 `ghcr.io/dalongzhuazi/harmonyos-ci:api26r` 已云端验证构建通过（2026-10-06，run 37409696295）。
**验证**：交付前回看本条；涉及 CI/构建/镜像时实际引用 `.rules/skill-ci-build.md` 与 `docs/CI_Guide.md`；证书类文件不进入工作区提交。
**更新时间**：2026-10-06

### PR-003 NGF 自动化测试与回归测试 harness 约定

**状态**：active
**范围**：NGF 仓库的单元测试、集成测试与回归测试；新增测试用例、搭建测试环境、维护测试目录。
**指令**：
1. 测试框架统一用 `@ohos/hypium`（配套 `@ohos/hamock`），依赖已在根 `oh-package.json5` 的 devDependencies 就绪（1.0.25 / 1.0.0）。
2. 目录结构：本地单元测试放 `entry/src/test/`（`List.test.ets` 为聚合入口 `export default function testsuite()`）；设备集成测试放 `entry/src/ohosTest/`（含 `module.json5` + `OpenHarmonyTestRunner`）。
3. 涉及测试时先读 `.rules/skill-automation-test.md`；参考已落地案例 `F:\DevEcoStudioProject\Coder` 与 `F:\DevEcoStudioProject\manxia` 的 `entry/src/test` / `entry/src/ohosTest`。
4. 在 IDE 外搭建/补齐测试环境时，从下载 devecotesting-hypium 工具包开始（API 26 用 26.0.0.400、API 23/24 用 6.1.0.210），注意官方直链带时效签名（约 2 小时）。
5. 回归测试围绕「已稳定契约」写断言，引用主代码路径 `../main/ets/...`，改动后重跑确保不破坏既有行为。
**来源**：用户要求参考 Coder/manxia 的 hypium 实际案例，在 NGF 建立自动化测试、回归测试流程与 harness。
**证据**：`@ohos/hypium`/`@ohos/hamock` 已在 oh-package.json5；Coder（30+ LocalUnit + Ability.test）、manxia（LocalUnit + Legado 一致性/回归测试）已验证。
**验证**：交付前回看本条；新增测试按 §4/§5 结构落地；测试用例 import `@ohos/hypium` 且入口正确聚合。
**更新时间**：2026-08-18

### PR-004 API26 组件级沉浸光感与 HdsColorPicker 接入约定

**状态**：active
**范围**：NGF 仓库 HDS 展示页（`pages/ngf/HdsNavigationOfficialShowcasePage.ets`）及后续新建/改造 HDS 页面时，涉及 API26 组件级沉浸光感、`HdsColorPicker`、`ImmersiveMaterial`、`hdsEffect` 点光/按压阴影的接入。
**指令**：
1. 能力分层互斥：使用 `.systemMaterial(ImmersiveMaterial{interactive:true, lightEffect})` 接管按压反馈后，不要再叠加 `.visualEffect(hdsEffect 链)`，两者会重复渲染按压反馈，导致性能下降且视觉异常。
2. `HdsColorPicker` 选中颜色必须存到 `@State` 变量，再由该变量驱动 `VisualEffect` 重建；颜色注入通过修改 `NGFHdsPointLightPresetSpec.color` 后调用 `basePreset.buildVisualEffect()` 走工厂方法，不要在页面层直接 `new hdsEffect.HdsEffectBuilder()`。
3. `ngfVisualEffectsFacade.buildImmersiveMaterialForTabs()` 返回 `uiMaterial.ImmersiveMaterial | undefined`，调用方需做空值兼容（返回 `undefined` 表示设备/策略不支持）。
4. 三档 `MaterialLevel`（GENTLE/SMOOTH/EXQUISITE）的视觉差异由 `SystemMaterialParams.materialLevel` 驱动，系统材质引擎按设备算力自动适配模糊/高光/阴影，不需要手写 `linearGradient` + `shadow` + `border` 模拟材质层次。
5. `NGFHdsPointLightPresetSpec` 已纳入 `ngf_framework` 的 `uiShell/index.ets` barrel 导出，页面层可 `import { NGFHdsPointLightPresetSpec } from 'ngf_framework'`。
**来源**：用户要求针对新增的 API26 优化内容完成文档与技能修改。
**证据**：`entry/src/main/ets/pages/ngf/HdsNavigationOfficialShowcasePage.ets` 的 `buildColorPickerSection`/`buildCustomPointLightVisualEffect`/`buildMaterialPanelContent`；`ngf_framework/src/main/ets/uiShell/index.ets` 新增 `NGFHdsPointLightPresetSpec` 导出；`hvigorw assembleHap` → BUILD SUCCESSFUL。
**验证**：交付前回看本条；HDS 页面涉及 API26 光感/材质/颜色选择器时，实际引用 `.rules/skill-hds-page-design.md` §8 与 `.rules/skill-arkui-knowledge.md` §10。
**更新时间**：2026-08-28

### PR-005 GitHub 公开源与 Gitea 私有完整备份双线约定

**状态**：active
**范围**：NGF 主仓库的公开发布、私有完整备份、工作区恢复与远端配置。
**指令**：GitHub `origin` 只承载可公开发布的代码和工具；Gitea `backup` 承载包含被忽略配置、证书和 Git 历史 bundle 的私有完整备份。不得把两个源配置为同一工作区的多个 push 目标，也不得将私有备份内容自动推送到 GitHub。完整备份和恢复统一使用 `tools/backup/` 脚本，并先恢复到隔离目录校验。
**来源**：用户明确要求在同时存在公开 GitHub 源和私有 Gitea/NAS 源时建立双线同步。
**证据**：`docs/Repository_Sync_Guide.md`、`tools/backup/Invoke-NgfPrivateBackup.ps1`、`tools/backup/Restore-NgfPrivateBackup.ps1`、根 `.gitignore` 的证书排除规则，以及冻结工作区中已存在的 `nas-backup` remote。
**验证**：交付前检查公开工作区不包含私有备份目录和证书；备份脚本使用 `git add -f current` 纳入被忽略文件；恢复脚本默认拒绝覆盖已存在目录。
**更新时间**：2026-10-06

**修订（2026-10-06）：补入第三条公开镜像 GitCode**

实际存在**三个**远程，此前只记录了前两个，导致 GitCode 长期收不到提交：

| 远程名 | 平台 | 地址 | 定位 |
|---|---|---|---|
| `origin` | GitHub | `https://github.com/DaLongZhuaZi/NGF.git` | 公开主源 |
| `backup` | Gitea（NAS） | `http://192.168.5.146:3333/DLZZ/NGF.git` | 私有完整备份（含被忽略文件、证书、bundle） |
| **`gitcode`** | **GitCode** | **`https://gitcode.com/dlzz/NGF.git`** | **公开镜像** |

**关键事实**：
1. GitCode 仓库**已迁移为小写路径** `dlzz`（大写 `DLZZ` 会收到
   「This repository moved. Please use the new location」提示，推送仍会成功，但应使用新地址）。
2. **没有任何自动化会把提交推到 GitCode** —— 它既不在 `tools/backup/` 脚本里，
   也不在 CI 里。**每次交付后必须手动 `git push gitcode main`**，否则会静默落后。
3. 诊断方法：`git ls-remote gitcode refs/heads/main` 与 `git rev-parse HEAD` 比对。

**验证**：交付后对三个远程各跑一次 `git ls-remote <remote> refs/heads/main`，
三者都等于本地 `HEAD` 才算同步完成。

### PR-006 普通组件一律不使用系统材质，改用普通玻璃模糊材质

**状态**：active
**范围**：NGF 框架与全部页面中**除 HDS 底栏以外**的所有组件表面（卡片、面板、控件、按钮、标题栏等）。
**来源**：2026-10-06 用户明确指令 ——「由于系统材质的 API 调整，导致除了 hds 底栏以外的很多普通组件的系统材质都是不生效的，反而导致对比度下降，所以需要你把普通组件的系统材质全部取消掉，正确使用普通的玻璃模糊材质」。

**指令**：
1. **不得**在普通组件上调用 `.systemMaterial(...)`（已全仓库移除 **232** 处，涉及 24 个文件）。
2. **不得**让 `NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface()` 返回 true —— 该函数现**恒返回 false**。
   原因：它一旦为 true，全部 `buildMaterialAware*` 助手会把背景 / 边框 / 模糊 / 阴影**置空**
   （返回 `Color.Transparent` 或 `undefined`），组件变成全透明，文字直接压在沉浸式渐变上。
3. 普通组件一律使用**普通玻璃模糊材质**：`backgroundColor(panel_background)` +
   `backgroundEffect(NGFMaterialBackgroundEffectOptions(...))` + 描边 + 阴影。
   这正是迁移提交 `9a27358` **之前**的写法，由 `buildMaterialAware*` 在 useSysMat=false 时还原。
4. **HDS 底栏例外**：它走 `barFloatingStyle({ systemMaterialEffect: ... })`，是另一套 API，**保留**系统材质。

**证据**：
- 迁移前写法（`git show 9a27358^:entry/src/main/ets/pages/ngf/MainMenuPage.ets`）：
  `backgroundColor(panel_background)` + `backgroundEffect(...)` + `border` + `shadow`。
- 设备端像素实测（模拟器 `127.0.0.1:5555`，densityPixels=2.75）：
  修复前深色正文对比度仅 **1.49 ~ 2.28 : 1**；修复后按声明色值对白底实测
  `text_primary` **15.62** / `text_secondary` **6.53** / `text_tertiary` **4.76**，全部 ≥ 附件2 §1.3 的 4.5:1。

### PR-007 表面/材质决策必须只有一处实现，禁止页面自建副本

**状态**：active
**范围**：NGF 框架与全部页面中任何「用不用某种材质/表面」的判断。
**来源**：2026-10-06 用户指出「设备和设置页大量的内容还没有正确适老化设计」，排查后发现根因不是适老化本身。

**指令**：页面**不得**自行复制材质判断逻辑，必须委托
`NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface()`。

**为什么（这次的真实故障链）**：
1. 令牌层改成「普通组件不再使用系统材质」（**PR-006**）；
2. 但 `NGFDeviceAwarenessPage` / `NGFSettingsPage` / `SystemResourcePreviewPage`
   **各自复制了一份同名逻辑**，仍返回「用系统材质」→ 面板背景被判为透明；
3. 系统材质又不生效 → 面板、模糊、描边全部消失；
4. 深色文字直接压在沉浸式渐变上 —— **设备页与设置页几乎不可读**。

**修复**：三处统一改为 `return NGFMaterialSurfaceTokens.shouldUseSystemMaterialSurface();`，
决策收敛到一处。**实测**：面板恢复白底，三档文字对比度 **15.62 / 6.53 / 4.76**（§1.3 要求 ≥4.5）。

**通用教训**：**当同一个决策被复制到多处时，改一处不会生效，而且不会有任何报错。**
新增此类开关时，先确认是否已有单一来源；有则委托，没有则先建单一来源。

### PR-008 使用关怀模式（长辈模式）独立开关的应用必须声明 senior_mode metadata

**状态**：active
**范围**：NGF 应用模块（`entry` 及后续独立 App）的 `module.json5`。
**来源**：2026-10-06 用户要求核对关怀模式同步，核对后发现声明缺失。

**指令**：
- 应用**有**自己的长辈版/关怀模式开关，且调用了
  `accessibility.setSeniorModeStateForSelf` / `getSeniorModeStateForSelf`
  → **必须**在 `module.json5` 的 **module 级** `metadata` 中声明：
  `{ "name": "senior_mode", "value": "independent_control" }`
- 应用只是**跟随系统**（无独立开关，只用 `isSeniorModeEnabled`）
  → **不应**声明该 metadata。

**为什么**：声明后应用才会出现在
**「设置 > 关怀和无障碍 > 关怀模式 > 应用管理」**；不声明则用户无法从系统侧管理本应用，
只能进应用内翻开关 —— 这正是"每个 App 都要单独找设置"的老问题。

**验证方式**：
1. 打包产物解压后 `module.json` 应含该 metadata；
2. 设备上 `hdc shell bm dump -n <bundleName>` 应能读到；
3. 开关往返时 hilog 应出现
   `SetSeniorModeStateForApp enabled, state: 0/1` 与
   `seniorModeStateForApp from db: {"<bundle>_0":true/false}`。

**相关 API（SDK `@ohos.accessibility.d.ts`，ForSelf 系列均为 @since 26.0.0）**：
`isSeniorModeEnabled` / `on|offSeniorModeStateChange` /
`getSeniorModeStateForSelf` / `setSeniorModeStateForSelf` /
`on|offSeniorModeStateChangeForSelf`。

### PR-009 适老指标必须在**目标设备**上实测，不能只看模拟器

**状态**：active
**范围**：NGF 全部页面的适老验收。
**来源**：2026-10-06 真机实测发现两个模拟器上不存在的缺口。

**指令**：
1. 适老指标（§1.1 字号 / §1.2 行距 / §2.1 点击区）必须在**真机**上复测；
   模拟器结论**不能**替代真机结论。
2. `densityPixels` **按设备分别推算**：找一个代码里写死尺寸的元素
   （如 `constraintSize` 60 vp 的 Toggle），用 `实测 px ÷ 已知 vp` 反推。
   - 模拟器 `127.0.0.1:5555` → **2.75**
   - MatePad Mini `192.168.0.36:35573` → **2.393**
3. 测量时**排除被视口裁切的节点**（`bounds` 贴屏幕边缘），否则会把
   「被裁切的卡片」误判为「字号过小」。

**实测证据**（MatePad Mini）：五个标签页文字最小 **23.4 vp**（= 18×1.3），
点击区最小 **60×60 / 129×64 vp** —— 全部达标。

**真机独有的两个缺口**（模拟器上未出现）：
- 浮动标签栏默认宽度下每项仅 **53 vp** → 适老档 `.barWidth('100%')` → **129 vp**
- `NGFSettingsPage` 自身 Toggle 未约束 **36×20 vp** → 加 `constraintSize` → **60×60 vp**

### PR-010 禁止对 HDS 浮动底栏设置 `barWidth` —— 会导致胶囊与图标错位

**状态**：active
**范围**：`MainMenuPage` 及后续任何使用 `HdsTabs` + `barFloatingStyle` 的页面。

**指令**：**不要**调用 `.barWidth(...)` 去调整浮动底栏宽度。宽度交给 HDS 浮动样式自行计算。

**为什么（2026-10-06 真机实测的真实故障）**：
为满足附件2 §2.1「适老版主要组件点击区 ≥60×60」，我给底栏加了
`.barWidth(this.isElderlyUi ? '100%' : '40%')`。结果**两种模式都出现底栏漂移**：

| 模式 | 现象 |
|---|---|
| 关怀模式（`'100%'`） | 图标落在 x=185/490/795/1100/1410，而背景胶囊从 x≈520 起 —— **前两个图标完全在胶囊外** |
| 普通模式（`'40%'`） | 同样错位 |

且百分比语义与预期相反：`'100%'` 反而比 `'40%'` **更窄**。

**移除 `barWidth` 后两种模式均恢复正常**：关怀模式下 5 个图标中心
x=548/674/800/926/1052，**左右距各 548px，完全居中**，图标全部落在胶囊内。

**⚠️ 已知未解决的取舍（不要用 barWidth 去"修"）**：
移除后标签项实测 **53×64 vp**，宽度仍差 §2.1 的 60vp 约 7vp。
这是 **HDS 浮动底栏按内容自适应宽度**带来的固有约束 ——
5 项 × 53vp ≈ 287vp 已经是该样式下的自然宽度。
**强行拉宽会破坏胶囊与图标的对齐，比差 7vp 严重得多。**
如需彻底满足，应改为「适老档不使用浮动样式」，但那会改变视觉风格，
**需用户决策后再动**。

**排查方法**：出现底栏错位时，先确认页面里没有 `.barWidth(`。

### PR-011 适老判定必须同时考虑「关怀模式」与「系统字体缩放」两个独立信号

**状态**：active
**范围**：NGF 适老呈现层的信号来源设计。

**指令**：判断是否进入适老档时，**不能只看关怀模式**。
HarmonyOS 有两套**互不替代**的适老信号：

| 信号 | 来源 | 提供什么 |
|---|---|---|
| **关怀模式** | `accessibility.isSeniorModeEnabled()` | 应用自建的适老呈现层 |
| **系统字体缩放** | `Configuration.fontSizeScale`（**@since 12**） | 系统自动的长按放大弹窗 |

**前置配置**（两个都要）：
- 关怀模式 → `module.json5` 声明 `senior_mode: independent_control`（PR-008）
- 字体缩放 → `app.json5` 的 `configuration` 指向 profile，
  其中 `fontSizeScale: "followSystem"`（**缺省是 `nonFollowSystem`**）
  + `fontSizeMaxScale` ≥ **1.875**（§1.1 要求 30dp ÷ 16vp）

**相关运行时 API**（SDK 已确认）：
`Configuration.fontSizeScale`（@since 12）、
`ApplicationContext.setFontSizeScale()`（@since 13）、
`ApplicationContext.onSystemConfigurationUpdated()`（@since 24）。

**当前状态**：`configuration` **已配**；但 `onSystemConfigurationUpdated` **未订阅** ——
用户只调大系统字体时，文字会跟随放大，而**基于 vp 的点击区 / 段距不会跟着变**。
修复涉及行为变更，**待用户决策**。

### PR-012 官方适老化长按放大弹窗只对 `BottomTabBarStyle` 生效

**状态**：active
**范围**：使用 `Tabs` 的页面。

**指令**：若要拿到官方的**适老化长按放大弹窗**，底部页签必须使用
`BottomTabBarStyle`；用 `@Builder` 自定义 `tabBar` 的页面**拿不到**。

**为什么重要**：这正是底栏标签项点击区不足 §2.1（60vp）时的**官方解法**。
本项目第二十三批曾用 `.barWidth()` 强行拉宽，结果造成底栏胶囊与图标错位
（见 **PR-010**）—— **方向错了**。

**长按放大弹窗的触发条件**：系统字体 **> 1 倍**（即 `fontSizeScale > 1`）。
系统字体 > 2 倍时，弹窗内容放大倍数**固定为 2 倍**。

**支持长按触发的组件白名单**：
`SideBarContainer`、底部页签 `tabBar`、`Navigation`、`NavDestination`、`Tabs`。

### PR-013 适老状态必须显示「生效状态 + 来源」，不能只显示应用内开关

**状态**：active
**范围**：任何提供「长辈版 / 关怀模式」开关的页面。

**指令**：开关旁的状态文字必须反映**实际生效**的状态与**来源**，至少三态可区分：

| 情况 | 显示 |
|---|---|
| 应用内开关开 | 已开启 |
| **仅系统关怀模式开** | **已生效 · 由系统关怀模式开启** |
| 都没开 | 已关闭 |

**为什么**：系统关怀模式开启时，应用内开关可能是关的，但界面**已经是适老档**。
只显示应用内开关会出现**「显示已关闭、界面却是大字」的自相矛盾**，
用户无法判断是哪个信号在起作用 —— 2026-10-06 用户就是因为这个报告「开了系统关怀模式但没放大效果」，
实际应用**本来就是适老档**。

**实现**：`MainMenuPage.describeElderlyEffectiveState()`。

### PR-014 门面在构造函数里注册的监听，必须在上下文就绪后惰性补订阅

**状态**：active
**范围**：所有在构造函数中调用平台 API 注册监听的 NGF 门面。

**指令**：构造函数里注册失败（典型：`UIAbilityContext` 尚未就绪）时，
**必须**在后续的读取路径上**惰性重试**，不能只注册一次。

**为什么**：2026-10-06 实测 `AccessibilityFacade` 在构造期注册
`systemConfigurationUpdated` 失败：

```text
⚠️ 无障碍事件注册失败: systemConfigurationUpdated,
   message=NGF: UIAbilityContext 尚未就绪，字体缩放订阅延后
```

**没有重试** → 字体缩放在**整个进程生命周期内永远是 1**，
「只调大系统字体的用户」永远拿不到适老布局。

**正确模式**：仿照 `ensureUserPolicyRestored`，
增加 `ensureSystemListeners()` 在 `getPolicy()` 等读取路径上补订阅
（此时页面已在渲染，上下文必然就绪；`tryRegister` 本身幂等）。

### PR-015 应用内关怀模式开关必须让位于系统信号，不得与系统设置争抢

**状态**：active
**范围**：任何提供「长辈版 / 关怀模式」开关的页面。

**指令**：**系统信号优先，应用内开关让位。**
系统关怀模式是用户对**整个设备**的选择，应用不应与之争抢。

必须同时做到三点：

1. **`systemSeniorMode` 与 `appSeniorMode` 分开存**，不能只留一个布尔。
2. **系统接管时禁用应用内开关**：
   `.enabled(this.seniorModeResolved && !this.systemSeniorMode)`
3. **系统接管时切换处理函数直接返回**，不做无意义写入。
4. **状态文字在系统接管时一律显示「由系统控制」**，无论应用内开关如何
   （即使恰好也是开的，真正的控制方仍是系统，开关已锁定）。

**为什么**：2026-10-06 审计发现三处冲突 —— 系统开启时把开关拨到关会被系统同步回来，
表现为**「拨到关又立刻弹回开」**，用户会以为开关坏了；
且写入本身是与系统的**无意义争抢**。
官方原文：「重新开启系统关怀模式时，原先被关闭的App会同步恢复开启。」

**实现**：`MainMenuPage` 的 `systemSeniorMode` 状态 +
`describeElderlyEffectiveState()` + `handleToggleSeniorMode()` 早退。

### PR-016 `@Builder` 渲染动态文本时必须传**对象**参数，禁止传基本类型位置参数

**状态**：active
**范围**：所有 ArkUI `@Builder` 方法；尤其是任何渲染**会变化**的文本（设置项当前值、
实时设备/运行状态、计数器、选中项名称）的地方。

**指令**：
1. `@Builder` 渲染动态文本时，参数必须是**对象**（按引用传递）：
   ```ts
   export interface NGFXxxParams { label: ResourceStr; value: ResourceStr; }
   @Builder private buildXxx(params: NGFXxxParams): void { Text(params.value) }
   this.buildXxx({ label: ..., value: this.currentTheme })   // ← 对象字面量
   ```
2. **禁止**用位置参数传基本类型再直接渲染：
   ```ts
   @Builder private buildXxx(label: ResourceStr, value: ResourceStr): void { Text(value) }  // ✗
   ```
3. ArkTS 要求对象字面量有明确类型 → 必须声明 `interface`。

**为什么**：ArkUI 的 `@Builder` **只有按引用传递参数时才建立状态依赖**。
按值传递时，内部渲染的文本**停在首次构建的结果**，之后状态变化不再刷新。

**证据（2026-10-06 真机实测，MatePad Mini / API 26）**：
设置页点「深色」后，按钮的 `accessibilitySelected` 已变成 `true`（**功能是通的**），
但「当前主题」这一行**仍然显示「跟随系统」** —— **显示与功能脱节**。
把签名从 `(label, value)` 改成 `(params: {label, value})` 后立即恢复：
点「深色」→ 该行变成「深色」✓、`selected` 同步变 ✓。

**受影响范围**（本仓库同批修好的，共 **5 个 builder、40 处调用点**）：
| builder | 调用点 | 传的动态值 |
|---|---|---|
| `NGFSettingsPage.buildSettingRow` | 18 | 主题 / 语言 / 材质 / 系统状态 |
| `AboutSheetContent.buildInfoRow` | 10 | 异步读取的设备型号、系统版本、包名 |
| `MainMenuPage.buildPerfInfoRow` | 5 | 实时进程 / 内存 / 温度 / 运行时间 |
| `MainMenuPage.buildHeaderGlassChip` | 5 | 实时生命周期 / 模块计数 / 窗口状态 / 事件计数 |
| `AboutSheetContent.buildLinkRow` | 2 | 链接名 / URL |

**同批修复的第二类问题：信息组的无障碍分组（PR-017）** ——
「标签 + 数值」不分组时读屏读成两个孤立节点。见下一条。

**排查方法**：搜 `@Builder` 带参数且内部有 `Text(<参数>)` 的；再判断该参数是否来自
**会变化的 `@State`/`@StorageProp`**。若来自 `ForEach` 的数据项，则不构成此问题。
（2026-10-06 全仓扫描结果：**0 处剩余**）

**排查方法**：搜 `@Builder` 带参数且内部有 `Text(<参数>)` 的；再判断该参数是否来自
**会变化的 `@State`/`@StorageProp`**。若来自 `ForEach` 的数据项，则不构成此问题。

**与本文件的关系**：这是根 `AGENTS.md` §7.4
「动态文本不要通过通用 `@Builder` 方法的字符串参数层层传递后再渲染」的**具体可执行判据**。

### PR-017 「标签 + 数值」必须做无障碍分组，否则读屏读到两个孤立节点

**状态**：active
**范围**：任何渲染「名词 + 数值」的 `@Builder` 或容器 —— 设置项、设备/运行信息、
统计指标、链接名+URL、卡片标题+描述。

**指令**：在这类容器的属性链末尾加 `.accessibilityGroup(true)`：

```ts
@Builder private buildInfoRow(params: NGFInfoRowParams): void {
  Row() { Text(params.label) ; Text(params.value) }
  .width('100%')
  .accessibilityGroup(true)     // ← 读屏拼成「推荐停靠 右侧」一次播报
}
```

**⚠️ 例外：容器内有 `Button`/`Toggle` 等可交互子组件时，禁止分组** ——
分组会把整个子树当**一个**节点处理，子组件不再可单独聚焦，交互就废了。
（本仓库 `MainMenuPage.buildFeatureActionButton` / `buildSmallActionButton` 属此例外。）
判据：容器内**没有** `Button(`/`Toggle(` 等交互组件，只有 `Text` → 可分组。

**为什么**：官方《支持无障碍》原文 ——
「启用分组后，该组件及其所有子组件将作为一个整体处理，无障碍服务**不再单独处理各子组件**」，
且会把子组件的文本**拼接**起来。不分组时读屏只会念一个孤立的「右侧」，
用户完全不知道它是「推荐停靠」的值 —— 这正是「信息数值和信息名词没联系起来」。

**证据（2026-10-06 真机，MatePad Mini / API 26）**：
设备页「握持感知」区共 10 组「标签 + 数值」（推荐停靠 / 握持侧 / 数据来源 / 置信度 /
传感器可用 / 精确握姿支持 / 操作手增强 / DETECT_GESTURE / ACTIVITY_MOTION / 握持刷新时间），
修复前在无障碍树里是 **20 个互不相关的 Text 节点**。

**本仓库已分组的 12 处**：`buildSettingRow`、`buildInfoRow`、`buildLinkRow`、
`buildPerfInfoRow`、`buildHeaderGlassChip`、`buildMetricPill`、`buildCapabilityCard`、
`buildResultStat`、`buildStrategyRule`、`buildMaterialApiMetric`、`buildMaterialApiLine`、
`buildSearchResultsPanel` 空态。

> ⚠️ **验证手段的限制**：`dumpLayout` dump 的是**渲染树**，分组作用于**无障碍树** ——
> 分组后 dump 里**仍然**能看到子 Text 节点，**无法用它验证分组是否生效**。
> 分组效果只能靠**读屏服务实测**确认。

### PR-018 CI 镜像 tag 必须与 `compatibleSdkVersion` 对齐，且禁止在 job 级 `if:` 里使用 `secrets`

**状态**：active
**范围**：`.github/workflows/` 下的全部工作流。

**指令**：
1. **镜像 tag 与 SDK 版本对齐** —— 本工程 `compatibleSdkVersion` 为 `26.0.0`，
   必须使用 `ghcr.io/dalongzhuazi/harmonyos-ci:api26r`。
   对照表（来源：harmonyos-ci `docs/CI_Guide.md`）：

   | tag | command-line-tools | 适用 |
   |---|---|---|
   | `api26r` | **26.0.0.821** | **API 26 正式版 —— 与 DevEco Studio 26 Release 内置 SDK 一致** |
   | `api26b2` | 26.0.0.621 | API 26 Beta2 |
   | `api26` | 26.0.0.461 | API 26 Beta1（**旧**） |
   | `api24` / `api23` | 6.1.1.300 / 6.1.0.818 | API 24 / 23 |

2. **禁止在 job 级 `if:` 里使用 `secrets` 上下文** ——
   GitHub Actions 只在 `env:` / `with:` / `run:` 中提供 `secrets`。
   正确做法：加一个独立的 **guard job**，在 `env:` 里读 secrets（合法），
   在 `run:` 里判断并写 `$GITHUB_OUTPUT`，下游用 `needs.<guard>.outputs.<flag>` 判断。

**为什么（两次真实故障，2026-10-06 定位并修复）**：

- **故障 1**：`build.yml` / `sign-and-release.yml` 用 `:api26`（Beta1，26.0.0.461），
  而代码用了 `HdsColorPicker`（**Beta2 新增**）→ 编译报
  **9×10505001 + 3 个 import 错误 + UI 语法错误**，`Build HAP` 自 **2026-08-29** 起连续失败。
  改成 `:api26r` 后 **CI 立刻变绿**（2m49s，3 个 job 全成功）。
- **故障 2**：`sign-and-release.yml` 的 job 级 `if: secrets.SIGNING_CERT != '' && …`
  → **工作流校验失败**，每次 push 产生一条 **0 秒失败**记录，
  名字是**文件路径** `.github/workflows/sign-and-release.yml`（而非 workflow 名）——
  **看到这种形态就知道是校验错误，不是运行失败**。

**排查方法**：
- 镜像/编译问题：`gh run view <id> --log-failed`，看 `COMPILE RESULT` 与 import 行号；
- 校验问题：`gh run list` 里出现**以文件路径为名字的 0 秒失败** → 用
  `python -c "import yaml;yaml.safe_load(open(f))"` 校验语法，并重点查 `if:` 里是否用了
  `secrets` / `env` 等**在该位置不可用的上下文**。

## Candidate Rules

### PR-C001 ArkTS 回调接口必须使用「可选函数类型属性」而非「可选方法」

**状态**：candidate
**范围**：NGF 框架内所有对外暴露回调的接口与类型（监听器、观察者、策略订阅等）。
**指令**：在 `.ets` 中声明可选回调时，必须写成
`onXxx?: (payload: T) => void;`（可选函数类型属性），
**不要**写成 `onXxx?(payload: T): void;`（可选方法）。实现方也必须用类字段（箭头函数属性）赋值，不要用成员方法。
**来源**：2026-10-05 在 `entry/src/test/AccessibilityContract.test.ets` 的 `testLifecycleBindingIsIdempotentAndDelivers` 上实测到的静默失效。
**证据**：
- 症状：`NGFAccessibilityLifecycleBinding` 订阅成功、facade 也确认发出了通知，但观察者回调始终收不到，断言 `received.length >= 1` 为 false；**没有任何编译错误或运行时异常**（通知路径外层的 try/catch 把异常吞掉了）。
- 对照实验：同一用例中直接向 `ngfAccessibilityFacade.addPolicyListener()` 注册箭头函数可以收到通知（`testFacadeNotifiesPolicyListenerDirectly` 通过），证明 facade 侧无问题。
- 把接口从可选方法改为可选函数类型属性、实现方改为类字段箭头函数后，同一用例立即通过。
**验证**：`hvigorw test --no-daemon`；修复前后该用例分别为 Failure / Success。
**备注**：这是 ArkTS 语言层行为，并非 NGF 工作区特有；其最终归属应是共享 `.rules/`（如 `skill-arkts-types.md`），需由开发者明确触发 `skill-rules-update.md` 流程后再迁移。迁移前保留为候选条目。
**更新时间**：2026-10-05

### PR-C002 ArkUI 声明式语法与组件复用的四条实测约束

**状态**：candidate
**范围**：NGF 框架内所有 `@Component` struct 与可复用属性集。
**指令**：
1. **可复用的属性集必须用 `AttributeModifier` 实现，不能写成"返回组件的普通函数"。**
   ArkUI 的 `build()` 只接受组件调用与属性链；把 `applyXxx(Button(...), ...)` 这类调用当组件根节点会报
   `does not meet UI component syntax`。正确写法：
   ```typescript
   class MyModifier implements AttributeModifier<CommonAttribute> {
     readonly applyNormalAttribute: (instance: CommonAttribute) => void =
       (instance: CommonAttribute): void => { instance.accessibilityText(...); };
   }
   // build() 中：Button('x').attributeModifier(new MyModifier())
   ```
   （API 26 声明：`attributeModifier(modifier: AttributeModifier<T>): T` @since 12，
   注释明确 "You need a custom class to implement the AttributeModifier API"。）
2. **struct 属性名不能叫 `enabled` 或 `position`**：二者与 ArkUI `CustomComponent` 成员冲突，
   编译报 `Property 'X' in type 'Y' is not assignable to the same property in base type 'CustomComponent'`。
   改用 `isEnabled` / `closePosition` 等名称。
3. **`SymbolGlyph.fontColor` 只接受数组**：签名是 `fontColor(value: Array<ResourceColor>)`，
   传单个 `Resource` 会报 `No overload matches this call`。写法：`.fontColor([$r('app.color.x')])`。
4. **未被任何文件引用的 `.ets` 不会进入编译图**：新增文件后如果没被 barrel/页面 import，
   编译不会报它的错，容易得到"改完就能过"的**假阳性**。验证新组件时必须先接入导出或调用点。
**来源**：2026-10-05 在实现 `NGFAccessibleButton` / `NGFAccessibleListItem` / `NGFAccessibleDialogCloseButton` 时逐条实测。
**证据**：四条均有编译器原始报错与修复后 `BUILD SUCCESSFUL` 对照；其中第 4 条由"先通过、接入导出后立即失败"的前后矛盾暴露。
**验证**：`hvigorw assembleHap --no-daemon`；修复前 `COMPILE RESULT:FAIL {ERROR:10}`，修复后 `BUILD SUCCESSFUL`。
**备注**：同 PR-C001，属 ArkTS/ArkUI 通用行为，最终应迁入共享 `.rules/`（`skill-arkui-knowledge.md` / `skill-arkts-types.md`），需开发者触发后再迁移。
**更新时间**：2026-10-05

### PR-C003 读取 ArkUI `.d.ts` 的 `@since` 必须取「堆叠块中的最小版本」

**状态**：candidate
**范围**：任何"核对 API 引入版本 / 判断某 API 在目标 SDK 是否可用"的任务。
**指令**：对目标声明向上遍历**连续堆叠的全部 JSDoc 块**，取其中**最小**的 `@since` 作为引入版本。
不要只取最近的一个 —— ArkUI 的 `.d.ts` 常把旧块叠在新块之上，最近那个是**文档修订版本**。
**来源**：2026-10-05 对 NGF 无障碍证据矩阵做复核时发现原矩阵有 6 处 `@since` 错误。
**证据**：
- `common.d.ts` 中 `accessibilityGroup(value: boolean)` 上方叠了 `@since 11`（L21928）与 `@since 12`（L21945）两个块，
  两个块都不是引入版本；真正的引入版本是 **10**。
- 只取最近块会得到 12；取最小会得到 10。同理 `accessibilityText(string)`、`accessibilityDescription(string)`、
  `accessibilityLevel` 原记 12 实为 **10**；`accessibilityStateDescription` 原记 26 实为 **23**；
  `accessibilityFocusDrawLevel` 原记 26 实为 **19**。
- 附带发现：同一方法在 `@since` 值上可能出现 `26.0.0` 这类三段版本号，做数值比较前必须先规范化，否则比较会失败。
**验证**：复核脚本输出与逐块人工阅读 `common.d.ts` L21924–21972 一致；纠正后文档 §3.1 与脚本输出逐项对齐。
**备注**：属 ArkUI 文档结构通用规律，最终应迁入共享 `.rules/`（`skill-arkui-knowledge.md`），需开发者触发后再迁移。
**更新时间**：2026-10-05

### PR-C004 ArkUI `$r()` 不能与字符串直接拼接（会渲染成 `[object Object]`）

**状态**：candidate
**范围**：所有用 `$r('app.string.*')` 参与文本拼接的 UI 代码。
**指令**：`$r()` 返回的是 **`Resource` 对象**，不是字符串。
把它放进 `+` 拼接会调用 `toString()`，页面上直接渲染成 **`[object Object]`**。
必须先用 `resolveResourceString(context, $r(...))` 解析成字符串再拼接。

```typescript
// ✗ 错：渲染成 "[object Object]：disabled"
Text($r('app.string.a11y_label_accessibility') + '：' + value)

// ✓ 对
Text(resolveResourceString(ctx, $r('app.string.a11y_label_accessibility')) + '：' + value)
```

**来源**：2026-10-06 在模拟器（`127.0.0.1:5555`）上打开 NGF 无障碍验证页时**实测发现**。
**证据**：
- 页面所有拼接标签渲染为 `[object Object]：<值>`，截图与 `uitest dumpLayout` 双向确认；
- 值本身正确（`enabled` / `none` / `system` / `16` / `44` / `20.8`），说明只是拼接坏了；
- **编译完全通过**，57 条单测也全过 —— 只有真机/模拟器运行才能发现。
- 修复后 dump 显示 `系统无障碍总开关：enabled`、`正文行高：20.8` 等，全部正常。
**验证**：`hvigorw assembleApp` + 模拟器安装运行；`uitest dumpLayout` 文本节点逐条核对。
**范围核验**：用正则 `\$r\([^)]*\)\s*\+` 全仓库扫描（已用"能匹配修复前、不匹配修复后"做过模式自检），
**除本页外 0 命中** —— 该问题此前只存在于 `NGFAccessibilityShowcasePage`，现已全部修复（20 处）。
**备注**：属 ArkTS/ArkUI 通用陷阱，最终应迁入共享 `.rules/`（`skill-arkui-knowledge.md` / `skill-i18n.md`），需开发者触发后再迁移。
**更新时间**：2026-10-06

### PR-C005 HDS 标题栏文字是硬编码白色，底色必须深色或透明

**状态**：candidate
**范围**：所有调用 `NGFHdsTitleBarOptionsFactory.build(mainTitle, subTitle, backgroundColor, ...)` 的页面。
**指令**：第 3 个参数 `backgroundColor` **不能传浅色**。
工厂内部把标题文字固定为 `$r('app.color.text_white')`（见 `HdsNavigationSupport.ets`），
浅色底会导致白字不可读。传**深色**（其他 20 个页面的做法，如 `#111827` / `#1A0F08`）
或 **`Color.Transparent`**（让页面自己的沉浸底板透上来）。

**来源**：2026-10-06 在模拟器上实测发现。
**证据**：
- 全仓库 22 处调用中，**20 处传深色**，只有 `MainMenuPage` 与 `NGFAccessibilityShowcasePage` 传了浅色
  `background_primary`（`#F3F7FB`）。
- 系统材质正常时该参数被材质覆盖，**这条回退路径从未被执行**；材质失效后回退到浅色，
  截图确认「白字压浅灰蓝渐变」不可读。
- 两处均已改为 `Color.Transparent`，模拟器复验通过（标题恢复为白字压深色沉浸底）。

**备注**：属 ArkUI/HDS 通用陷阱，最终应迁入共享 `.rules/skill-hds-page-design.md`，需开发者触发后再迁移。

## Open Decisions

当前没有需要在实现前决定的项目级事项。

## 条目格式

### PR-001 规则名称

**状态**：active / candidate / deprecated
**范围**：模块、页面、功能或交付场景
**指令**：满足什么条件时必须做什么，以及不适用的边界。
**来源**：用户长期指令 / 配置 / 已验证源码 / 官方文档。
**证据**：精确文件、命令输出或重复验证模式。
**验证**：交付时如何检查遵守情况。
**更新时间**：YYYY-MM-DD
