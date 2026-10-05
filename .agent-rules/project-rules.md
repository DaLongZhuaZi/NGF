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
1. NGF 消费镜像 `ghcr.io/dalongzhuazi/harmonyos-ci:api26`（command-line-tools 26.0.0.461，HarmonyOS 26.0.0 / API 26 Beta1）；镜像构建/维护统一在 [harmonyos-ci](https://github.com/DaLongZhuaZi/harmonyos-ci) 仓库，不要在本仓库重新引入 docker-image 构建。
2. 涉及 CI、云端构建、镜像、automation、自动发布、免 DevEco 构建时，先读 `.rules/skill-ci-build.md`（通用技能）+ `docs/CI_Guide.md`/`docs/CI_Guide.en.md`（本项目双语完整步骤）。
3. 消费方只需维护 `.github/workflows/build.yml`（构建+自动滚动 nightly Release）、`.github/workflows/sign-and-release.yml`（tag 签名发布，未配 Secrets 时自动跳过）、`.github/scripts/strip_signing.py`（剥离本机签名配置产出未签名 HAP）。
4. 签名材料（证书/密钥/口令）只走 repository secrets，绝不入库；`.gitignore` 已拦截证书类文件。
**来源**：用户明确要求将 HarmonyOS CI 云端构建纳入本项目 agent 规则库、并同步 NGF 项目。
**证据**：`.github/workflows/build.yml`、`.github/workflows/sign-and-release.yml`、`.github/scripts/strip_signing.py`、`docs/CI_Guide.md`；镜像 `ghcr.io/dalongzhuazi/harmonyos-ci:api26` 已云端验证构建通过。
**验证**：交付前回看本条；涉及 CI/构建/镜像时实际引用 `.rules/skill-ci-build.md` 与 `docs/CI_Guide.md`；证书类文件不进入工作区提交。
**更新时间**：2026-08-17

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
**更新时间**：2026-09-13

## Candidate Rules

当前没有待验证的候选规则。

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
