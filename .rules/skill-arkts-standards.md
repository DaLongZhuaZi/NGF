# 技能：ArkTS 语法标准

**适用场景**：编写或修改 `.ets` 文件；涉及 ArkTS 语法规则、限制、TypeScript 到 ArkTS 差异、语法合规审查、ArkTS 语法问题。

**自动触发条件（满足任意一条即应主动阅读本文件）**：
- 编写或修改任意 `.ets` 文件。
- 需要做 ArkTS 语法合规审查、TypeScript 到 ArkTS 差异迁移、ArkTS 受限语法修复。
- 编译报错涉及 `any`、`unknown`、解构、动态属性访问、模板字符串、结构类型、类型断言等 ArkTS 限制。

---

## 1. 核心写作检查清单

编写或修改 `.ets` 文件前，必须遵守以下规则：

- 将代码视为 **ArkTS**，而非通用 TypeScript
- **禁止** 使用 `any` 或 `unknown`（除非用户明确允许）
- 类型转换统一使用 `as` 语法（与 `AGENTS.md` §6.2 一致）；禁止用 `as` 做任意/越权的断言绕过类型系统（如绕过 private、跨无关类型的强制断言）
- **禁止** 依赖结构类型；使用命名 class/interface 和显式 `implements`
- **禁止** 使用动态属性访问如 `obj[key]`；使用已知名称的直接属性访问
- 对象字面量必须通过类型化变量、类型化参数或 class/interface 构造提供显式类型上下文
- **禁止** 使用内联对象字面量类型；定义命名 interface 或 class
- **禁止** 使用模板字面量如 `` `${value}` ``；使用字符串拼接和显式转换
- **禁止** 将命名空间作为运行时值；导入或引用具体的导出值/类型
- **避免** 受限 TypeScript 模式：解构声明、解构参数、函数表达式、嵌套局部函数声明、类表达式、`delete`、`in`、`for...in`、`typeof` 类型查询

## 2. 声明规则

| 规则 | 说明 |
|------|------|
| 禁止 `var` | 使用 `let` 或 `const` |
| 禁止解构声明 | 不支持 `const { a, b } = obj` |
| 禁止解构参数 | 不支持 `function foo({ x }: T)` |
| 禁止 `any`/`unknown` | ArkTS 强类型要求 |
| 用 `as` 做显式类型转换 | 与 `AGENTS.md` §6.2 一致，避免 any/unknown 透传；禁止越权断言 |
| 禁止确定赋值断言 `!` | Sendable 类中不允许 |

## 3. 函数和类规则

| 规则 | 说明 |
|------|------|
| 禁止嵌套局部函数声明 | 使用顶层声明、类方法或箭头函数 |
| 禁止函数表达式 | 使用箭头函数 `=>` |
| 禁止生成器函数和 `yield` | ArkTS 不支持 |
| 禁止类表达式 | 使用命名 class 声明 |
| 禁止独立函数中的 `this` | 将 context 作为参数传递 |

## 4. 对象和属性访问规则

| 规则 | 说明 |
|------|------|
| 禁止自由形式结构类型 | 对象字面量必须有显式类型上下文 |
| 禁止内联对象字面量类型 | 定义命名 interface |
| 禁止动态属性访问 | 不支持 `obj[dynamicKey]` |
| 避免 `Record<string, T>` | 定义命名类型 |
| 优先标识符属性名 | 使用直接点访问 |

## 5. 字符串语法规则

- 模板字面量 **不支持** ArkTS 创作
- 重写插值为字符串拼接 + 显式转换：

```typescript
// TypeScript 风格（禁止）
const label: string = `Count: ${count}`

// ArkTS 风格（正确）
const label: string = "Count: " + count.toString()
```

## 6. 受限运算符和语句

| 受限语法 | 替代方案 |
|----------|---------|
| `delete obj.x` | 构造不含该属性的值 |
| `in` / `for...in` | 使用 `Map` 或其他已知结构 |
| `typeof` 作为类型查询 | 使用显式类型 |
| `catch (err: Error)` | `catch (err)` 无类型注解 |
| 解构赋值 | 显式局部绑定 |

## 7. TypeScript 到 ArkTS 关键差异

| TypeScript 模式 | ArkTS 替代 |
|----------------|-----------|
| `{ x: number; y: number }` 内联类型 | 定义 `interface PointLike { x: number; y: number }` |
| 函数表达式 `function() {}` | 箭头函数 `() => {}` |
| 类表达式 `const C = class {}` | 命名 class 声明 |
| 结构类型推断 | 显式 `implements` 关系 |
| `Record<string, T>` | 命名 interface/class |
| `` `${value}` `` | `"Value: " + value.toString()` |
| 命名空间作为运行时值 | 导入具体导出符号 |
| `var` | `let` 或 `const` |
| `value as T` 越权/任意断言 | 合法的类型转换仍然用 `as`；禁止的是用 `as` 绕过类型系统（如私有成员、无关类型强转） |
| `catch (err: Error)` | `catch (err)` |

## 8. Sendable 限制

- Sendable 类必须使用显式字段类型
- Sendable 字段类型本身必须是 sendable 的
- Sendable 类型不得从对象字面量或数组字面量直接初始化
- Sendable 类和函数有更严格的捕获和继承规则

## 9. 主题别名映射

在判断用户问题属于哪个主题时，参考以下映射：

| 主题关键词 | 对应规则领域 |
|-----------|-------------|
| var/let/const/变量声明 | 声明规则 |
| 解构/解构赋值/解构参数 | 声明规则 |
| 箭头函数/函数表达式/局部函数 | 函数规则 |
| class/构造函数 | 类规则 |
| interface/结构类型 | 接口规则 |
| delete/typeof/in/catch | 运算符规则 |
| 对象字面量/动态属性/Record | 对象规则 |
| 模板字符串/字符串插值 | 字符串规则 |
| namespace/命名空间 | 命名空间规则 |
| sendable/@sendable/并发类型 | Sendable 规则 |
| typescript/migration/差异/迁移 | TS-ArkTS 差异 |

## 10. 官方参考

- 官方文档索引（总入口/API 参考/工具下载）：见 [official-doc-links.md](official-doc-links.md)
- ArkTS 语言基础与介绍：https://developer.huawei.com/consumer/cn/doc/doccenter-getting-started/introduction-to-arkts
- ArkTS 编码风格指南：https://developer.huawei.com/consumer/cn/doc/doccenter-getting-started/arkts-coding-style-guide
- ArkTS 迁移背景（TS/JS → ArkTS 差异与迁移）：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-migration-background

> 注意：本文件中「`as` 类型转换合法、禁止越权断言」的结论与 `AGENTS.md` §6.2 一致；如官方文档有新表述，以官方最新版为准。
