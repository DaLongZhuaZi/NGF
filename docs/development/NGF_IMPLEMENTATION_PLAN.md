# NGF Implementation Plan

## 1. 当前定位

NGF 当前处于“框架骨架已建立、运行时兼容层待补完”的阶段。

已具备的基础能力：

- `core`：日志、事件、错误、生命周期、Starter 内核骨架
- `platformOhos`：平台窗口与上下文桥接 façade 骨架
- `data`：数据、设置、存储 façade 骨架
- `contentWorkflow`：通用工作流 façade 骨架
- `contentSource`：通用内容源 façade 骨架
- `uiShell`：导航壳层与页面策略宿主 façade 骨架

当前主要缺口：

- 缺少可持续演进的兼容基础设施文件
- 缺少统一的模块接线顺序与启动约定
- 缺少独立可复用的库化边界
- 缺少针对 NGF 契约与 façade 的测试覆盖
- 缺少面向框架接入者的文档与示例

## 2. 本轮补完目标

本轮先完成“继续演进所需的最低基础设施”，优先保证：

1. 旧 façade 的缺失依赖可被当前仓库接住
2. 入口能力与页面能够为 NGF 提供上下文
3. 文档中存在明确的实施路线图
4. 后续可以在不推翻现状的前提下继续补真实 DI、模块注册与库化能力

## 3. 分阶段实施

### Phase A：兼容基础设施补齐

目标：让现有 NGF façade 不再依赖缺失文件。

实施项：

- 增加 `GlobalContext.ets`
- 增加 `Framework/Managers/UIContextManager.ets`
- 增加 `Framework/Managers/SettingsManager.ets`
- 增加 `Framework/DependencyContainer.ets`
- 增加 `Framework/NGF/core/facades/ServiceContainerFacade.ets`
- 增加 `Utils/Logger.ets`
- 增加 `Utils/WindowManager.ets`
- 增加 `Utils/PageWindowPolicy.ets`
- 增加 `Utils/PageWindowRegistry.ets`
- 增加 `Utils/PageWindowCoordinator.ets`

验收结果：

- 现有 NGF 本地导入路径闭环
- 各层 façade 至少具备可运行的基础依赖

### Phase B：统一启动与上下文接线

目标：让 NGF 不再只依赖演示页手动触发。

实施项：

- 在 `EntryAbility` 中绑定能力上下文
- 在主入口页面绑定和释放 UIContext
- 抽出统一 bootstrap 顺序
- 逐步把模块集成 façade 纳入统一初始化过程

验收结果：

- Starter 不再只由演示逻辑承担全部初始化职责
- 平台层、壳层、数据层拥有稳定上下文来源

### Phase C：真实服务容器与模块注册

目标：把当前“记录实现名”的容器升级为真正的框架服务注册中心。

实施项：

- 定义模块描述与模块依赖模型
- 支持服务实例、工厂、生命周期
- 支持模块注册、排序、初始化、状态输出
- 将 Starter 与各集成 façade 纳入统一模块体系

验收结果：

- NGF 具备真正意义上的模块化启动能力
- 服务解析不再只返回字符串

### Phase D：框架文档与示例

目标：让外部接入者可以按文档理解和使用 NGF。

实施项：

- 输出架构图与目录职责说明
- 输出最小接入示例
- 输出模块扩展指南
- 输出 façade 到真实实现的迁移指南

验收结果：

- 外部开发者可以基于文档理解框架边界与扩展点

### Phase E：验证与质量保障

目标：建立真正面向框架的验证体系。

实施项：

- 为 `core` 契约与 Starter 增加单元测试
- 为 `data`、`uiShell`、`platformOhos` façade 增加回归测试
- 增加关键导入路径与模块接线检查
- 增加示例页联调清单

验收结果：

- 框架变更可被持续验证
- 核心能力不再只靠演示页手工观察

## 4. 下一批优先文件

建议下一轮优先落实：

1. 模块描述契约
2. 模块注册中心
3. 统一 bootstrap 编排器
4. Starter 与各 IntegrationFacade 的统一接线
5. NGF 专项测试文件

## 5. 说明

- 本计划以当前仓库结构为基础，不强行推翻既有目录。
- 兼容 façade 不是最终形态，但它们是过渡到真实框架化实现的必要步骤。
- 后续所有新增规则与实现都应继续保持 NGF 的“框架工程”视角。
