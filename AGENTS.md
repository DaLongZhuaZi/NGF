# AGENTS

本文件是本仓库统一的代理工作规范，已整合以下规则来源：

- `.trae/rules/project_rules.md`
- `.windsurf/rules/projectrules.md`
- `.kiro/steering/projectrules.md`
- `.cursor/rules/projectrules.mdc`

目标是让 Codex、OpenCode、Claude Code 等支持 `AGENTS.md` 的代理都能读取同一份规则，并且始终从 **NGF 框架工程** 的视角理解仓库，而不是把它误判成某个单一业务 App。

## 1. 适用范围与优先级

- 用户明确指令优先于本文件。
- 本文件优先于分散在 `.trae`、`.windsurf`、`.kiro`、`.cursor` 中的同类规则文件。
- 当前仓库已确认存在根目录 `AGENTS.md`；如后续子目录新增同名文件，则按更深层 `AGENTS.md` 优先。
- 每次进行文件读取、写入、修改时，必须显式使用 UTF-8 编码；禁止依赖系统默认编码。支持编码选项的写回操作统一使用 UTF-8（建议无 BOM）。
- 涉及 HarmonyOS Next 导入、引用、编译、运行、API 能力、废弃接口迁移时，必须优先参考最新官方文档与官方最佳实践。
- 需要解决报错或解释报错时，必须先查官方文档和相关声明定义，再结合源文件分析原因，最后给出修复方案。
- 修复方案必须保持原功能等价，避免引入新的问题。
- 对侵入性较强或高风险的修改，优先先做同目录 `*.bak` 备份再执行改动。
- 修复问题时默认不自动执行编译、打包、hvigor 构建或预览器运行；修改完成后也不需要因为“收尾”而手动再执行一次自动编译。只有在用户明确要求，或当前任务本身就是编译、构建、运行问题排查时，才进行相关操作。
- 修复完成后，必须再次检查是否符合 ArkTS 规则、当前仓库实际结构与本文件规范。
- 每次修复后都应回顾本次问题是否值得沉淀为长期规则；只有真正可复用的规则才能补充到本文件，不要为一次性问题临时加规则。
- 忽略本仓库中的 `--allowArbitraryExtensions` 相关问题，除非用户明确要求处理。

## 2. 项目定位

- 这是一个 HarmonyOS Next 项目，主要使用 ArkTS 开发。
- 当前仓库的主定位是 **NGF 核心运行框架 / 框架验证工程**，而不是某个具体业务的单一 App。
- 所有页面、示例、导航入口、演示数据与交互，默认都应服务于“验证框架能力、展示官方组件接入方式、沉淀可复用模式”，而不是拼装某一个垂直产品。
- 修改代码时，应优先考虑“可复用、低耦合、可扩展、可替换”的框架设计，避免写死单一业务名称、业务流程、业务规则、产品文案或专属于某个 App 的交互假设。
- 仓库内如果出现某些业务化页面、历史命名或迁移遗留模块，应优先将其视为示例、验证页或兼容遗留，而不是把整个仓库理解成该业务本身。
- 历史业务化描述只可视为背景，不应再作为新增开发的默认前提。
- 优先使用官方最新 API，尽量不引入新的第三方依赖。

### 2.1 框架优先原则

- 当“框架抽象”与“某个旧业务特例”发生冲突时，默认优先保留框架抽象与通用能力，除非用户明确要求兼容该业务特例。
- 新增能力时，优先沉淀为通用模块、通用服务、通用页面模式、通用日志、通用导航接入方式或通用平台桥接能力。
- 新增页面如属于演示、测试或验证页，应明确体现其框架验证属性，例如围绕核心能力、官方组件、路由壳层、日志链路、平台能力接入等展开。
- 共享规则文件中不再沉淀任何面向单一业务的专属适配规则或产品流程规则；只有在用户明确要求处理某个历史模块时，才允许在当次任务范围内局部考虑。

## 3. 当前仓库事实基线

以下内容基于当前仓库实测结果整理；如后续文件内容发生变化，应始终以 **实际文件** 为准，而不是死记本节文字。

- 仓库根目录关键配置文件包括：
  - `build-profile.json5`
  - `oh-package.json5`
  - `hvigorfile.ts`
  - `hvigor/hvigor-config.json5`
  - `AppScope/app.json5`
  - `entry/oh-package.json5`
  - `entry/src/main/module.json5`
  - `entry/src/main/resources/base/profile/main_pages.json`
- 当前 `build-profile.json5` 的产品配置为：
  - `targetSdkVersion: 6.0.1(21)`
  - `compatibleSdkVersion: 6.0.1(21)`
- 当前根目录 `oh-package.json5` 的 `modelVersion` 为 `6.1.0`。
- 当前 `AppScope/app.json5` 的 `bundleName` 为 `com.dlzz.ngf`。
- 当前 `entry/src/main/module.json5` 的主能力为 `EntryAbility`，页面入口通过 `$profile:main_pages` 声明。
- 当前 `entry/src/main/resources/base/profile/main_pages.json` 中注册的入口页面为 `pages/ngf/MainMenuPage`。
- 当前页面目录以 `entry/src/main/ets/pages/` 为主，其中 `entry/src/main/ets/pages/ngf/` 承担 NGF 演示与展示页职责。
- 当前框架主目录为 `entry/src/main/ets/Framework/NGF/`，已确认存在以下一级目录：
  - `core`
  - `platformOhos`
  - `data`
  - `contentWorkflow`
  - `contentSource`
  - `uiShell`
  - `utils`
- 当前日志实现文件为 `entry/src/main/ets/Framework/NGF/utils/Logger.ets`。
- 当前 `local.properties` 未记录 SDK 路径，因此 **不能** 把它作为判断 SDK 绑定状态的唯一依据。

### 3.1 本机 SDK 与 IDE 路径基线

- 当前机器已确认存在的 HarmonyOS SDK 主目录为 `F:\HarmonyOS\SDK`。
- 当前机器已确认存在的 HarmonyOS SDK 版本目录包括：
  - `F:\HarmonyOS\SDK\23`
  - `F:\HarmonyOS\SDK\20`
  - `F:\HarmonyOS\SDK\18`
- 当前机器 **未确认存在** `F:\HarmonyOS\SDK\21`；因此不能仅因项目 `targetSdkVersion` 为 `6.0.1(21)` 就推断本机一定有独立的 `21` 目录。
- 当前机器已确认存在的 DevEco Studio 安装目录为 `F:\DevEco Studio`。
- 当前机器已确认存在的 DevEco Studio SDK 根目录为 `F:\DevEco Studio\sdk`。
- 当前机器已确认存在的 DevEco Studio 默认 OpenHarmony SDK 目录为 `F:\DevEco Studio\sdk\default\openharmony`。
- 当前机器已确认存在的 DevEco Studio 默认 HMS SDK 目录为 `F:\DevEco Studio\sdk\default\hms`。
- 涉及 SDK 路径、toolchains、previewer、hvigor、构建环境或 IDE 绑定目录排查时，优先先核对以上路径，不要凭空假设其他安装位置。
- 如果任务涉及“为什么能编译 / 为什么不能编译 / SDK 是否匹配”等问题，必须同时对照 `build-profile.json5`、本机路径、DevEco Studio 默认 SDK 目录以及用户实际报错，不能只看单一文件下结论。

## 4. 框架目录与修改原则

- 修改代码前，先判断目标文件属于哪一层，再沿用该层既有模式，不要强行套用单一架构。
- 当前 `entry/src/main/ets/Framework/NGF/` 目录的职责可按以下方式理解：
  - `core`：核心契约、生命周期、日志抽象、事件抽象、服务容器、启动内核。
  - `platformOhos`：HarmonyOS 平台桥接、上下文桥接、窗口策略、平台控制能力。
  - `data`：缓存、设置、存储、迁移与数据门面。
  - `contentWorkflow`：通用工作流、动作执行、重试、限流等流程编排能力。
  - `contentSource`：通用内容源注册、加载、仓储与接入门面，按“通用适配层”理解，不要写成单一来源特例层。
  - `uiShell`：导航壳层、页面策略宿主与 UI 外壳能力。
  - `utils`：日志、时间、日志收集等基础工具。
- 如果目标修改只影响某一层，则优先在该层内完成闭环，不要把局部问题扩散到无关模块。
- 同名或近名文件较多时，必须先确认正确路径和职责范围再修改，避免误改展示层与框架层、页面层与门面层。
- 处理现有页面时，应优先保持目标目录现有组织方式；例如演示页继续保持“展示 / 验证”定位，不要无意间改造成业务首页。
- 当现有模块已经采用 facade、contract、starter、page shell 等模式时，应优先复用，不要旁路新增一套平行实现。

## 5. LLM 自动环境核查规范

本节用于让代理在开始任何中等及以上复杂任务前，先自动确认“当前环境是什么、当前流程该怎么走”，避免在错误前提上修改仓库。

### 5.1 启动任务前必须自动执行的核查

- 先确认当前工作目录是否仍为仓库根目录 `F:\DevEcoStudioProject\NGF`，并确认目标文件确实属于本仓库。
- 先读取根目录 `AGENTS.md`；如任务进入更深子目录，继续搜索该目录链上是否存在新的 `AGENTS.md`。
- 先读取以下配置文件，再开始推断环境：
  - `build-profile.json5`
  - `oh-package.json5`
  - `entry/oh-package.json5`
  - `AppScope/app.json5`
  - `entry/src/main/module.json5`
  - `entry/src/main/resources/base/profile/main_pages.json`
  - `hvigor/hvigor-config.json5`
- 先确认目标文件位于哪一层：`pages`、`entryability`、`Framework/NGF/core`、`platformOhos`、`data`、`contentWorkflow`、`contentSource`、`uiShell` 或 `utils`。
- 如果任务与 API、导入、编译、运行、弃用接口、窗口行为有关，必须先查官方文档，再结合源文件与声明定义分析。
- 如果任务与构建环境有关，必须先核对本机 SDK 目录和 DevEco Studio 默认 SDK 目录是否存在，且不能依赖空白的 `local.properties` 做推断。
- 如果任务不要求构建、运行、预览或排查构建失败，则默认只做静态分析与代码修改，不自动执行 hvigor 构建。
- 对于普通代码修改、文档修改、规则文件修改或静态重构任务，完成修改后默认直接进入静态复核与交付，不需要额外手动触发自动编译。

### 5.2 推荐的自动核查命令

以下命令仅作为推荐模板；执行时仍应显式使用 UTF-8：

- `Get-ChildItem -Name`
- `rg --files -g "**/AGENTS.md"`
- `Get-Content -Encoding utf8 AGENTS.md`
- `Get-Content -Encoding utf8 build-profile.json5`
- `Get-Content -Encoding utf8 oh-package.json5`
- `Get-Content -Encoding utf8 entry/oh-package.json5`
- `Get-Content -Encoding utf8 AppScope/app.json5`
- `Get-Content -Encoding utf8 entry/src/main/module.json5`
- `Get-Content -Encoding utf8 entry/src/main/resources/base/profile/main_pages.json`
- `Get-ChildItem -Path entry/src/main/ets/Framework/NGF -Directory`
- `Test-Path "F:\HarmonyOS\SDK"`
- `Test-Path "F:\DevEco Studio\sdk\default\openharmony"`

### 5.3 启动任务时应向自己确认的环境摘要

代理在正式修改前，应先形成一份简短环境摘要，至少包含：

- 当前任务作用的模块或文件范围。
- 当前仓库实际 `targetSdkVersion` / `compatibleSdkVersion`。
- 当前主入口页面或相关页面注册位置。
- 当前目标修改属于哪一层架构。
- 是否需要先查官方文档。
- 是否需要先做 `*.bak` 备份。
- 是否真的需要执行构建、运行、预览命令。

如果以上任一项不清楚，应继续读配置和源码，不要直接下手修改。

### 5.4 标准开发流程

- 第一步：理解用户目标，判断这是框架层、页面层、平台层还是构建层问题。
- 第二步：读取相关配置、目标文件和相邻契约或门面，确认当前模式。
- 第三步：如果涉及官方 API、导入、弃用或报错原因，先查官方文档和声明定义。
- 第四步：在尽量小的改动范围内实现修复或增强，优先修根因，不做表面补丁。
- 第五步：完成后做静态自检，确认类型、安全区、导航、资源、日志、导出关系与本文件规则一致。
- 第六步：仅在用户明确要求，或任务本身就是构建、运行、测试排查时，才执行 hvigor、预览器、安装或运行相关命令。
- 第七步：向用户交付时明确说明改了哪些文件、是否做过验证、未执行构建的原因以及仍需用户确认的部分；不要把“修改完成后手动再编译一次”当作默认流程。

### 5.5 修改后的自动复核要点

- 是否仍保持 NGF 框架视角，而不是把共享规则或共享模块改成某个单一 App 的特化实现。
- 是否沿用了目标目录既有模式，而不是在旁边再造一套重复架构。
- 是否补齐了必要的页面注册、导出、依赖声明或资源引用。
- 是否避免了 `any`、`unknown`、未类型化对象字面量、危险空值访问和动态索引访问。
- 是否正确使用 UTF-8、日志系统、资源路径与现有导航方式。
- 是否在需要时说明“未执行构建 / 未执行运行”的原因。

## 6. ArkTS 硬性语言与类型规则

### 6.1 类型安全

- 禁止使用 `any`、`unknown`，包括但不限于函数参数、返回值、变量声明、接口属性、泛型约束和双重断言中间态。
- 必须为数据结构提供明确的类、接口或类型别名。
- 所有对象字面量都应对应明确声明的类型，不要依赖未类型化对象字面量。
- 配置文件和资源文件必须定义明确类型接口，并通过类型断言确保类型安全。
- 使用 `error` 时必须确保其类型可控，必要时显式收敛为 `Error` 或其他明确错误类型。
- 重点关注 `null`、可选值和未初始化状态，避免危险访问。

### 6.2 类型断言与泛型

- 类型转换统一使用 `as` 语法。
- ArkTS 调用泛型函数时，必须显式标注泛型参数，不要依赖编译器自动推断。
- `typeof` 只能用于表达式上下文，不能用于类型上下文。

### 6.3 禁止的语言模式

- 禁止把构造函数直接作为函数参数或类型签名使用；优先采用类继承体系、接口或抽象工厂模式。
- 禁止依赖结构类型系统，应尽量按名义化、显式契约思路设计。
- 禁止动态解构变量声明；应使用显式属性访问。
- 禁止函数参数解构声明；应改用显式对象参数和属性提取。
- 禁止使用 `in` 操作符和 `hasOwnProperty`；应使用 `Object.keys(...).includes(...)` 并结合显式类型断言。
- 禁止通过 `Function.apply` 和 `Function.call` 动态修改 `this`。
- 禁止在独立函数中使用 `this`。
- 禁止使用 `globalThis`。
- 禁止使用 `ESObject`。
- 禁止使用索引签名定义对象类型。
- 禁止依赖字符串索引签名进行动态访问。
- 禁止使用对象扩展运算符 `...` 合并普通对象；对象属性应显式赋值。
- 禁止使用 definite assignment assertion。

### 6.4 属性访问与数组规则

- 应进行显式空值检查，避免对可能为 `null` 的对象进行属性访问或调用。
- 避免 `object['key']`、`object[fieldName]` 形式的动态索引访问；优先使用点语法和显式 helper。
- 如果必须处理动态字段，优先先枚举 `Object.keys()`，再通过显式类型断言访问。
- `Object.entries()` 的返回值类型必须显式声明为 `[string, T][]` 等明确形式。
- 避免使用无法推断元素类型的数组字面量。
- 初始化 `Map` 时，优先先声明泛型类型，再通过 `set()` 逐项添加，而不是直接在构造函数中放入复杂数组字面量。
- 扩展运算符只能用于数组或从数组派生的类，不能用于普通对象。

### 6.5 异常与构造一致性

- `throw` 应优先抛出 `Error` 或其他明确类型错误对象。
- 类定义中的构造参数必须与所有实例化调用在类型、数量、顺序上完全一致。
- 内部类访问外部类属性时，必须通过构造参数传递或显式属性声明完成，不得访问不存在的属性。

## 7. 通用实现规范

### 7.1 日志与问题分析

- 日志系统统一优先使用 `entry/src/main/ets/Framework/NGF/utils/Logger.ets`。
- 优先使用以下日志方法：
  - `logger.debug`
  - `logger.info`
  - `logger.warn`
  - `logger.error`
  - `logger.lifecycle`
  - `logger.startup`
  - `logger.stateChange`
  - `logger.performance`
- 日志分析时，先定位日志提到的代码，再结合源文件、官方文档和最佳实践解释原因，然后再给出方案。
- 处理导入模块问题时，先检查源文件是否正确导出以及导出名称是否正确；如果是 HarmonyOS 模块，再去官方文档确认模块名与导出名。

### 7.2 资源、配置与文件

- 颜色、字符串、媒体等资源优先复用现有资源定义与 `$r()` 资源引用，不要在共享层随意散落硬编码。
- JSON 配置文件应放在 `entry/src/main/resources/rawfile/` 下。
- `rawfile` 目录下的资源通过 `$rawfile('relative/path')` 使用。
- 资源、配置、原始数据应保持命名清晰、职责单一，避免把某个具体业务名或产品名写进共享资源层。
- 修改配置和资源前，先确认其实际消费者是谁，不要误把演示配置改成框架全局配置。

### 7.3 页面、导航与窗口

- 所有独立入口页面都必须通过当前实际路由配置管理；当前仓库以 `entry/src/main/resources/base/profile/main_pages.json` 为主入口声明。
- 新增页面或展示页时，应先确认是模块内局部路由，还是需要提升为主入口页面，不要随意污染根入口。
- 页面跳转时，优先沿用目标文件现有导航方式；不要在同一文件中混用多套导航模式。
- 如果目标文件已经使用 `this.getUIContext().getRouter()`，则在该文件内保持一致。
- 涉及沉浸式布局、安全区、系统栏、窗口策略时，应优先复用目标模块现有写法与 `platformOhos` 层能力，不要临时手写一套平行规则。
- `pages/ngf` 下的框架演示页以及后续新增展示页，默认应沿用 `MainMenuPage` 的沉浸式 HDS 顶栏模式：根层使用 `HdsNavigation` 或 `HdsNavDestination`，标题栏通过 `NGFHdsTitleBarOptionsFactory.build(...)` 配置，内容层通过 `NGFImmersiveTopChromeUnderlay` 提供顶部沉浸底板，并为主内容显式设置默认顶部避让。
- 对于带 `SubHeader`、`Tabs`、筛选条、操作条等多功能顶部区域的页面，这些控件应归属于标题栏下方的内容层，而不是再额外拼装一套自定义标题栏；如页面存在一个或多个实际滚动容器，必须把对应 `Scroller` 绑定到 HDS 导航容器，并按需配置 `ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])` 以保证顶部玻璃模糊与光感效果可见。
- 对于 `HdsNavDestination` 类页面，如目标是“标题栏本身正确避让系统状态栏、但页面内容底板继续延伸到状态栏区域”，优先采用“标题栏避让 + 内容层扩展”的分离模式：`titleBar` 显式传入 `avoidLayoutSafeArea = true`、`enableComponentSafeArea = false`，页面内容层或顶部底板通过 `expandSafeArea(...)` / 现有沉浸 helper 延伸到顶部安全区，而不要默认把整个 `HdsNavDestination` 根节点都设置为忽略顶部安全区。
- 新增或重构窗口管理能力时，统一优先接入 `entry/src/main/ets/Framework/NGF/platformOhos/` 的窗口管理器；`EntryAbility` 负责绑定/释放 `WindowStage`，页面层通过页面策略宿主或统一辅助层激活窗口策略，不再把 `entry/src/main/ets/Utils/WindowManager.ets`、`PageWindowCoordinator.ets` 作为新增实现入口。
- `List` 组件必须显式设置 `width` 和 `height`，避免布局告警。

### 7.4 UI、动画与组件

- 页面入场动画、属性动画和统一动画状态管理，优先复用目标模块已有实现。
- 所有动画相关状态变量必须使用 `@State` 管理，并在动画结束后及时清理状态。
- 复杂页面应将 UI 构建逻辑拆分成多个 `@Builder` 方法，提高可读性和维护性。
- `@Builder` 方法参数必须与调用处在类型、数量、顺序上完全匹配。
- 枚举类型必须使用完整枚举成员，不要用字符串字面量代替。
- 长列表渲染优先使用 `LazyForEach`。
- 自定义组件应遵循单一职责原则。
- 组件外部输入优先使用 `@Prop`，内部状态优先使用 `@State`。
- 组件接口应清晰区分必需参数和可选参数。

### 7.5 `@Watch` 规范

- `@Watch` 只用于监听由状态装饰器管理的变量，如 `@State`、`@Prop`、`@Link`。
- `@Watch` 参数必须是字符串形式的方法名，例如 `@Watch('onCountChange')`。
- 被 `@Watch` 指向的回调方法必须是组件成员函数。
- 被 `@Watch` 指向的方法不能是 `private`。
- 推荐的回调函数签名是 `(changedPropertyName?: string) => void`。
- `@Watch` 在首次初始化时不会触发，只会在后续状态变化后同步触发。
- 不要在 `@Watch` 回调中直接或间接修改同一个被监听状态，避免死循环。
- `@Watch` 回调应尽量保持快速、同步、轻量。

### 7.6 HarmonyOS API 迁移与废弃约束

- `decode()` 已废弃，统一使用 `decodeToString()`。
- 全局 `animateTo()` 已废弃，应使用 `UIContext.animateTo(...)`。
- 在 `@Component` 中，应在 `aboutToAppear()` 中通过 `this.getUIContext()` 获取 `UIContext`，并做好空值检查。
- 触发动画时，优先在回调中修改 `@State` 变量，而不是直接操作组件实例。
- 如需等组件完成渲染后再执行动画，可使用 `setTimeout(..., 0)` 作为过渡。
- `getContext()` 已废弃，应使用 `this.getUIContext()?.getHostContext()`，并在需要时显式断言为 `common.UIAbilityContext`。
- 窗口显示、系统栏控制与页面策略应优先复用 `platformOhos` 层现有能力，而不是继续扩散旧式局部写法。

### 7.7 单例、全局状态与事件

- 不使用 `globalThis` 管理全局状态，优先使用单例模式。
- 单例类应提供私有构造函数、静态 `getInstance()` 方法，以及必要的生命周期管理方法。
- 跨模块通信优先复用目标模块现有事件机制；如果进入 NGF 分层，应优先依赖显式契约，例如 `entry/src/main/ets/Framework/NGF/core/contracts/IEventBus.ets` 的抽象思路，而不是引入新的隐式全局对象方案。
- 页面组件必须在合适的生命周期中订阅和取消订阅事件，避免泄漏和重复触发。
- 事件载荷必须保持类型安全，不要传递未类型化数据。

## 8. 历史遗留内容处理原则

- 历史业务模块、历史业务命名、历史页面文案、历史演示数据、历史适配层，只应视为遗留背景或迁移样本。
- 不要把某个历史模块的特殊逻辑升级成全局共享规则，除非用户明确要求。
- 不要再把仓库默认理解为任何单一产品工程。
- 如果历史文档、历史注释与当前仓库实际结构不一致，应优先相信当前代码和配置，并在本次改动范围内顺手修正文档漂移。

## 9. 提交修改前的简明检查清单

- 是否先核对了最新 HarmonyOS 官方文档与目标模块源码。
- 是否确认本次修改是在建设 NGF 框架能力，而不是无意中把仓库往某个单一 App 方向收窄。
- 是否完成了最小必要的环境核查，并确认当前实际 SDK、入口页、模块层级与工作目录。
- 是否避免了 `any`、`unknown`、未类型化对象字面量、危险空值访问和动态索引访问。
- 是否使用了 `entry/src/main/ets/Framework/NGF/utils/Logger.ets` 和项目既有日志风格。
- 是否沿用了目标文件已有的导航方式、窗口策略与架构模式。
- 是否确认了同名文件或近名文件的正确路径。
- 是否在需要时为高风险修改创建了 `*.bak` 备份。
- 是否避免在共享规则和共享模块中重新引入单一业务视角内容。
- 是否在完成修复后再次检查 ArkTS 兼容性与本文件规则。
- 如果未执行构建、运行、预览或测试，是否已明确说明原因；如果执行了，是否已明确说明命令与结果。
- 是否避免把“修改完成后手动触发自动编译”作为默认动作，除非用户明确要求这样做。
