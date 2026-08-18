# 技能：HarmonyOS 自动化测试与回归测试（hypium）

**适用场景**：为 NGF / HarmonyOS 项目编写、运行、维护单元测试、集成测试与回归测试；接入 hypium 测试框架；从零搭建测试环境。

**自动触发条件（满足任意一条即应主动阅读本文件）**：
- 用户提到 自动化测试 / 单元测试 / 集成测试 / 回归测试 / 测试用例 / hypium / 断言 / 测试覆盖率
- 涉及 `entry/src/test/`、`entry/src/ohosTest/`、`*.test.ets`、`List.test.ets`、测试 runner
- 需要搭建测试环境、从下载测试工具包开始、运行 hvigor 测试任务、排查测试失败
- 涉及 `@ohos/hypium`、`@ohos/hamock` 依赖、`describe`/`it`/`expect` 断言 API

---

## 1. 背景：hypium 测试框架与两种测试类型

HarmonyOS 官方测试框架为 **hypium**（`@ohos/hypium`），配套 mock 库 `@ohos/hamock`。断言 API 走 `describe / beforeAll / beforeEach / afterEach / afterAll / it / expect`。

测试分两类：

| 类型 | 目录 | 是否需要设备 | 用途 |
|---|---|---|---|
| LocalUnit 本地单元测试 | `entry/src/test/` | 否 | 纯逻辑、算法、门面/协调器单元测试与回归测试 |
| 设备集成测试 | `entry/src/ohosTest/` | 是（真机/模拟器） | 依赖 Ability/系统能力的集成测试，含 `module.json5` + `OpenHarmonyTestRunner` |

> 已验证案例：`F:\DevEcoStudioProject\Coder`（30+ LocalUnit 单测 + Ability 集成测试）、`F:\DevEcoStudioProject\manxia`（LocalUnit + Legado 一致性/回归测试）。

---

## 2. 第一步：下载 hypium 测试工具包（引导从这里开始）

在 IDE 外独立搭建/补齐测试环境时，先从华为官网下载对应 API 版本的 **devecotesting-hypium** 工具包：

| 版本 | 适用 SDK | 下载链接（带时效签名，约 2 小时有效） |
|---|---|---|
| devecotesting-hypium-26.0.0.400 | HarmonyOS 26.0.0（API 26） | https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_package_901_9/bd/v3/6i-nCtxySTSUtzkxzKPgXQ/devecotesting-hypium-26.0.0.400.zip?HW-CC-KV=V1&HW-CC-Date=20260818T031304Z&HW-CC-Expire=7200&HW-CC-Sign=659A677A44869127C210100413AC9A24E40C49DAD44D62EA74CC87E7581D7E93 |
| devecotesting-hypium-6.1.0.210 | HarmonyOS 6.1.x（API 23/24） | https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_package_901_9/86/v3/3Fag_cVcSWKxJfpt5ge7ZA/devecotesting-hypium-6.1.0.210.zip?HW-CC-KV=V1&HW-CC-Date=20260818T031337Z&HW-CC-Expire=7200&HW-CC-Sign=CFA933ECEE92D4D31D2F96B8271298226D7E39C7322B848FD24C61F4E3BB5B49 |

> ⚠️ 官方直链带 `HW-CC-Expire` 时效签名，过期后需重新登录官网/下载页获取；不要把已过期的链接固化当作长期可下载地址。

---

## 3. 依赖配置

在根 `oh-package.json5` 声明测试依赖（NGF 已就绪）：

```json5
// oh-package.json5
{
  "devDependencies": {
    "@ohos/hypium": "1.0.25",
    "@ohos/hamock": "1.0.0"
  }
}
```

然后 `ohpm install --all` 拉取。

---

## 4. 标准目录结构与入口

```
entry/src/test/          # LocalUnit 单元测试(无设备)
  ├── List.test.ets      # 聚合入口: export default function testsuite()
  ├── LocalUnit.test.ets # 具体单测
  └── Xxx.test.ets       # 各模块单测/回归测试
entry/src/ohosTest/      # 设备集成测试(需真机/模拟器)
  ├── module.json5       # testRunner: OpenHarmonyTestRunner
  └── ets/test/Ability.test.ets
```

---

## 5. 标准模式：LocalUnit 单元测试

单个测试文件（`LocalUnit.test.ets` 实测写法）：

```typescript
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';

export default function localUnitTest() {
  describe('localUnitTest', () => {
    beforeAll(() => { /* 所有用例前执行一次 */ });
    beforeEach(() => { /* 每个用例前 */ });
    afterEach(() => { /* 每个用例后 */ });
    afterAll(() => { /* 所有用例后 */ });
    it('assertContain', 0, () => {
      let a = 'abc';
      let b = 'b';
      expect(a).assertContain(b);
      expect(a).assertEqual(a);
    });
  });
}
```

聚合入口（`List.test.ets`）：

```typescript
import localUnitTest from './LocalUnit.test';
import someModuleTest from './SomeModule.test';

export default function testsuite() {
  localUnitTest();
  someModuleTest();
}
```

---

## 6. 标准模式：回归/一致性测试（引用主代码）

回归测试直接 import 主代码路径（`../main/ets/...`）验证既有行为不变。manxia 的 `LegadoCompatibilityConformance.test.ets` 是典型范例（大量 import 主代码做兼容性/一致性断言）。

要点：
- 回归测试围绕「已稳定契约」写断言，改动后重跑确保不破坏既有行为。
- 纯逻辑门面/协调器/解析器用 LocalUnit；依赖 Ability/系统 API 的用 ohosTest。

---

## 7. 运行测试

- **IDE**：右键 `entry/src/test` 或 `entry/src/ohosTest` → Run / 对应 Test 配置。
- **命令行（LocalUnit）**：`hvigorw test`（以 hvigor 实际任务为准；NGF 为 API 26，本机 DevEco 里用 IDE 运行最稳）。

> NGF 当前仓库已有 `@ohos/hypium`/`@ohos/hamock` 依赖，但尚无测试用例目录；新增测试时按本文件 §4/§5 建立 `entry/src/test/` 与聚合入口。

---

## 8. 关键文件路径速查

| 文件 | 说明 |
|------|------|
| `oh-package.json5` | 声明 `@ohos/hypium`、`@ohos/hamock` |
| `entry/src/test/List.test.ets` | LocalUnit 聚合入口 |
| `entry/src/test/*.test.ets` | 单元测试/回归测试 |
| `entry/src/ohosTest/module.json5` | 设备测试模块配置（testRunner） |
| `entry/src/ohosTest/ets/test/Ability.test.ets` | 设备集成测试 |
