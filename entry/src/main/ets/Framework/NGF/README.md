# NGF 目录骨架

本目录用于 NGF 框架的分层落地，当前处于“骨架搭建完成，兼容基础设施补完中”的阶段。

子目录说明:

1. `core`: 日志、事件、错误、生命周期、DI 等核心契约。
2. `platformOhos`: HarmonyOS 平台桥接与窗口治理契约。
3. `data`: 数据访问、设置、缓存、存储、迁移契约。
4. `contentWorkflow`: workflow 执行引擎契约。
5. `contentSource`: 通用内容源注册、仓储与加载契约。
6. `uiShell`: 导航壳层与页面策略宿主契约。

注意:

1. 当前仍以低风险兼容 façade + 新框架骨架并存的方式推进迁移。
2. 后续迁移与补完遵循 `docs/development/NGF_IMPLEMENTATION_PLAN.md`。
