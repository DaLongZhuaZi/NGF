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
