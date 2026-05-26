# NGF 规则库 (.rules/)

本目录是 NGF 框架的**技能规则库**，面向所有 AI 编程助手（Agent/LLM）和 Vibe Coding 场景。

每份规则文件描述一种可复用的开发技能，包含：背景知识、使用前置条件、标准实现模式、关键代码片段和注意事项。

规则文件**不会自动触发**，需要开发者/LLM 在合适的任务开始前主动阅读并运用。

---

## 规则文件列表

| 文件 | 技能 | 适用场景 |
|------|------|---------|
| [skill-hds-page-design.md](skill-hds-page-design.md) | HDS 页面设计技能 | 新建 NavDestination 页面、沉浸式顶栏布局、光效/材质配置 |
| [skill-manager-apis.md](skill-manager-apis.md) | 框架管理器 API 技能 | 使用主题、语言、视效、握持感知等管理能力 |
| [skill-system-tasks.md](skill-system-tasks.md) | 任务管理与系统通知技能 | 提交后台长时任务、监听任务进度、发送系统通知、事件意图派发 |
| [skill-arkts-types.md](skill-arkts-types.md) | ArkTS 类型安全技能 | 涉及 Map、Array、ForEach 及回调函数的强类型声明 |
| [skill-llm-onboarding.md](skill-llm-onboarding.md) | LLM 项目初始化技能 | Agent 新会话开启、定位环境 SDK 路径、构造编译命令 |
| [skill-rules-update.md](skill-rules-update.md) | 规则滚动更新技能 | 开发者手动触发，将项目最新实践沉淀回本规则库 |

---

## 使用指引

1. **新建页面前**：阅读 `skill-hds-page-design.md`，确认沉浸式顶栏模式和安全区处理方式。
2. **使用管理器能力前**：阅读 `skill-manager-apis.md`，按标准模式订阅/读取/取消订阅。
3. **发现新规律后**：由开发者手动提起，阅读 `skill-rules-update.md` 执行规则沉淀。

> 主规范文件为根目录 `AGENTS.md`，本规则库是对 `AGENTS.md` 的具体技能补充，两者互为参考，`AGENTS.md` 优先级更高。
