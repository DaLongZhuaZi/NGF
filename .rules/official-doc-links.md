# NGF 官方文档与资源链接索引

本文件集中维护 HarmonyOS / OpenHarmony 官方文档与资源下载入口，供所有 .rules/skill-*.md 技能文件引用，避免每个技能重复维护易漂移的 URL。

> 使用约定：
> - 优先用无版本后缀的 URL（华为会自动 302 到当前最新版本），避免旧 -V13/-V14 链接失效。
> - 涉及具体 API 描述/签名时，先打开对应 harmonyos-references 参考页确认，再结合源码与声明定义分析（见 AGENTS.md §5.1）。
> - 下载地址（带 HW-CC-Expire 时效签名）会过期，只作「如何获取」的指引，不当作长期固定 URL 固化到共享规则。

---

## 1. 官方文档总入口

| 资源 | URL |
|------|-----|
| HarmonyOS 应用开发文档总入口 | https://developer.huawei.com/consumer/cn/doc/ |
| ArkTS 介绍与语言基础 | https://developer.huawei.com/consumer/cn/doc/doccenter-getting-started/introduction-to-arkts |
| ArkTS 编码风格指南 | https://developer.huawei.com/consumer/cn/doc/doccenter-getting-started/arkts-coding-style-guide |
| ArkTS 迁移背景（TS/JS → ArkTS） | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-migration-background |
| ArkTS 装饰器总览（状态管理） | https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/arkts-decorator-overview |
| ArkUI 声明式 UI 开发总览 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-development-overview |
| HDS 设计系统 / UI 设计入门 | https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/ui-design-introduction |

## 2. 核心系统 API 参考（harmonyos-references）

| 主题 | 官方参考 URL |
|------|-------------|
| ArkUI 组件通用属性与方法 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-component-common |
| 导航 Navigation / NavDestination | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-navigation-navigation |
| 窗口管理 @ohos.window | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-window |
| 通知 @ohos.notificationManager | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-notificationmanager |
| 国际化 @ohos.i18n | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-i18n |
| 设备信息 @ohos.deviceInfo | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-device-info |
| 首选项 @ohos.data.preferences | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-data-preferences |
| 多模感知 @ohos.multimodalAwareness | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-multimodalawareness |

> 注：上表精确文档 ID 需以 developer.huawei.com/consumer/cn/doc/ 站内搜索为准；此处给出官方主题路径，现场核对时在总入口搜索模块名（如 @ohos.window、@ohos.notificationManager）。

## 3. 测试与 UI 自动化

| 资源 | URL |
|------|-----|
| 单元测试指南（hypium） | https://developer.huawei.com/consumer/cn/doc/doccenter-testing/unittest-guidelines |
| UI 测试（uitest）API 参考 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-uitest |
| OpenHarmony uitest 用例 | https://gitee.com/openharmony/docs |

## 4. 构建 / 打包 / 发布

| 资源 | URL |
|------|-----|
| hvigor 构建工具 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hvigor |
| HAP 打包与应用签名 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-signing |
| 命令行人工具（hdc / aa / bm / hilog） | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hdc |
| AppGallery Connect（AGC 上架） | https://developer.huawei.com/consumer/cn/service/josp/agc/index.html |

## 5. 工具包下载入口（统一走官方下载中心）

> **所有官方工具包/SDK/IDE 的下载，统一从华为官方下载中心入口进入：https://developer.huawei.com/consumer/cn/download/**
> 在下载中心按需搜索或筛选对应内容，不要固化带 `HW-CC-Expire` 时效签名的直链。

| 工具包 | 下载方式（从下载中心进入） |
|--------|---------|
| DevEco Studio / SDK | 下载中心 → 「DevEco Studio」标签页 |
| devecotesting-hypium（测试框架） | 下载中心搜索「hypium」或「测试」；详见 skill-automation-test.md §2 |
| commandline-tools（CI 工具链） | 下载中心搜索「commandline-tools」；社区已构建镜像 ghcr.io/dalongzhuazi/harmonyos-ci（tags: api23/api24/api26/api26b2），详见 skill-ci-build.md |

---

## 6. OpenHarmony 开源侧

| 资源 | URL |
|------|-----|
| OpenHarmony 文档仓库 | https://gitee.com/openharmony/docs |
| OpenHarmony 开发者文档 | https://docs.openharmony.cn/ |
