# 技能：HarmonyOS 自动化测试与回归测试（hypium）

**适用场景**：为 NGF / HarmonyOS 项目编写、运行、维护单元测试、集成测试与回归测试；接入 hypium 测试框架；从零搭建测试环境。

**自动触发条件（满足任意一条即应主动阅读本文件）**：
- 用户提到 自动化测试 / 单元测试 / 集成测试 / 回归测试 / 测试用例 / hypium / 断言 / 测试覆盖率
- 涉及 `entry/src/test/`、`entry/src/ohosTest/`、`*.test.ets`、`List.test.ets`、测试 runner
- 需要搭建测试环境、从下载测试工具包开始、运行 hvigor 测试任务、排查测试失败
- 涉及 `@ohos/hypium`、`@ohos/hamock` 依赖、`describe`/`it`/`expect` 断言 API
- 用户提到 模拟点击 / 自动点击 / UI 自动化 / 截图断言 / 图片识别 / OCR / 控件树 dump / 手势注入 / `uitest` / `snapshot_display` / 端到端 UI 回归

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

在 IDE 外独立搭建/补齐测试环境时，从华为官方下载中心下载对应 API 版本的 **devecotesting-hypium** 工具包：

- 官方下载中心入口：https://developer.huawei.com/consumer/cn/download/
- 在下载中心搜索/筛选「**hypium**」或「测试工具」，按当前工程 API 版本（NGF 为 API 26）选择对应包：
  - devecotesting-hypium-26.0.0.400 → HarmonyOS 26.0.0（API 26）
  - devecotesting-hypium-6.1.0.210 → HarmonyOS 6.1.x（API 23/24）

> ⚠️ 官网下载中心的直链常带 `HW-CC-Expire` 时效签名（约 2 小时），过期后需回到下载中心重新获取；不要固化直链，**统一从下载中心入口进入下载**。
>
> 📚 官方文档入口：单元测试指南（hypium）https://developer.huawei.com/consumer/cn/doc/doccenter-testing/unittest-guidelines ；UI 测试（uitest）API 参考 https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-uitest ；统一见 [official-doc-links.md](official-doc-links.md) §3。

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

## 7A. 综合性设备 UI 自动化测试（模拟点击 / 控件树 / 截图 / 图片识别 / 日志闭环）

> 适用：不做纯逻辑单测，而是要在真机/模拟器上验证「点击 → 页面/生命周期变化 → 日志产生」的端到端链路；以及需要图片识别(OCR/视觉断言)、控件定位、手势注入、日志抓取的综合性回归测试。以下命令均为 **2026-08-18 在真机（MLR-AL10 / MatePad Mini / API 26 / 1600×2560 物理分辨率）实测验证**。

### 7A.1 工具探测（先确认设备端能力）

设备端 UI 自动化工具不在 hdc 顶层命令里，而是通过 `hdc shell` 调用的 /system/bin 工具。先探测：

```powershell
$HDC = '<hdc 绝对路径>'; $T = '<target>'
& $HDC -t $T shell which uitest          # /bin/uitest（核心：点击/截图/dump 控件树）
& $HDC -t $T shell which aa hidumper
& $HDC -t $T shell ls /system/bin | Select-String 'uitest|snapshot|uinput|hidumper|wukong'
```

实测可用工具链：`uitest`（点击/截图/布局 dump）、`snapshot_display`（截图）、`uinput`（输入注入）、`hidumper`（资源 dump）、`wukong`（随机压测）。

### 7A.2 uitest 子命令速查（实测语法）

```powershell
# 模拟点击/手势（坐标用物理像素，屏幕全分辨率，如 1600×2560）
& $HDC -t $T shell uitest uiInput click <x> <y>                 # 单击
& $HDC -t $T shell uitest uiInput doubleClick <x> <y>           # 双击
& $HDC -t $T shell uitest uiInput longClick <x> <y>             # 长按
& $HDC -t $T shell uitest uiInput swipe <fx> <fy> <tx> <ty> [velocity]   # 滑动/滚动
& $HDC -t $T shell uitest uiInput drag <fx> <fy> <tx> <ty> [velocity]    # 拖拽
& $HDC -t $T shell uitest uiInput fling <fx> <fy> <tx> <ty> [velocity] [stepLength]  # 甩动
& $HDC -t $T shell uitest uiInput dircFling <0..3>               # 定向甩动(0左1右2上3下)
& $HDC -t $T shell uitest uiInput keyEvent Back                  # 按键: Back/Home/Power
& $HDC -t $T shell uitest uiInput keyEvent <keyID_0> <keyID_1> [keyID_2]   # 组合键
& $HDC -t $T shell uitest uiInput inputText <x> <y> <text>       # 在坐标点输入文本
& $HDC -t $T shell uitest uiInput text <text>                    # 在已聚焦位置输入文本

# 截图 / 控件树 dump
& $HDC -t $T shell uitest screenCap -p <savePath>                # 截图到设备路径
& $HDC -t $T shell uitest dumpLayout -p <savePath>               # dump 控件树(含 bounds/text/clickable)
# dumpLayout 常用选项: -i(不合并窗口) -b <bundleName>(限定目标窗口) -a(含字体属性)
```

> 实测：`uiInput click` 成功返回 `No Error`；坐标必须是**物理像素**（`dumpLayout` 里 `bounds` 用的就是物理坐标，两者同坐标系，直接复用）。

### 7A.3 完整闭环：控件树定位 → 截图 → 点击 → 日志验证

标准四步（每一步都可独立使用或组合）：

```powershell
# 1) dump 控件树，拿到可点击节点坐标
& $HDC -t $T shell uitest dumpLayout -p /data/local/tmp/layout.json
& $HDC -t $T file recv /data/local/tmp/layout.json .\layout.json

# 2) 解析 bounds 找目标（PowerShell 递归提取 text/clickable 节点及 bounds）
$root = (Get-Content -Raw -Encoding utf8 .\layout.json) | ConvertFrom-Json
# 遍历 node.attributes，聚焦 text / clickable=true / type=Button 的节点，取 bounds=[x1,y1][x2,y2] 中心点 ((x1+x2)/2, (y1+y2)/2)

# 3) 截图做视觉断言（视觉识别可用 describe_image 工具）
& $HDC -t $T shell uitest screenCap -p /data/local/tmp/screen.png
& $HDC -t $T file recv /data/local/tmp/screen.png .\screen.png

# 4) 点击 + 抓日志验证动作生效
& $HDC -t $T shell hilog -r                                  # 清日志基线（可选）
& $HDC -t $T shell uitest uiInput click <cx> <cy>
Start-Sleep -Seconds 2
& $HDC -t $T shell hilog -T wwssadad    # 抓 NGF 应用日志(见 skill-device-hdc-debug §6.5)
```

### 7A.4 实测验证结论（NGF 真机）

- **Tab 切换**：点击底部标签栏物理坐标（例如「设备」tab 中心约 (926,2427)）→ 日志实时出现 `[NGFDeviceAwarenessPage] 设备感知页面出现，刷新设备与握持状态`，截图确认底部「设备」tab 变蓝色选中。
- **进入二级页**：点击首页卡片（「官方 HDS Navigation 示例页」中心约 (800,1708)）→ 日志 `打开HDS演示: route=ngf.hds.official.navigation` + `NGFHdsNavigationOfficialShowcasePage 官方展示已显示`。
- **返回**：`keyEvent Back` → 日志 `应用页面策略: page=pages/ngf/MainMenuPage`，回到主页面。
- **图片识别**：`uitest screenCap` 截图拉到本地后，用视觉模型 describe_image 分析，能准确读出页面标题、卡片文案、选中态（蓝色高亮）与页面归属（主页面 vs 设备页 vs 二级示例页）。
- **日志过滤**：NGF 应用日志固定用 `hilog -T wwssadad`（domain 0x1F00 / tag wwssadad，见 skill-device-hdc-debug §6.5）；动作是否生效以 Logger 输出的生命周期/页面事件为准，而不是凭截图主观判断。

### 7A.5 坐标单位与适配注意

- `uitest uiInput` 的坐标与 `dumpLayout` 的 `bounds` 都是**物理像素**，直接复用，不要乘/除 density。
- 设备分辨率不同（如 1600×2560），坐标会漂移；跨设备回归前先重新 `dumpLayout` 校准坐标，不要硬编码旧坐标。
- 底部 Tab / 固定栏 / 卡片等锚点坐标要「先 dump 后用」，避免系统栏、安全区、标题栏高度差异导致点空。
- `force-stop` 后立即点击可能无效（进程未就绪），点击前先 `aa start` 并 `Start-Sleep` 等待页面加载完成。

---

## 8. 关键文件路径速查

| 文件 | 说明 |
|------|------|
| `oh-package.json5` | 声明 `@ohos/hypium`、`@ohos/hamock` |
| `entry/src/test/List.test.ets` | LocalUnit 聚合入口 |
| `entry/src/test/*.test.ets` | 单元测试/回归测试 |
| `entry/src/ohosTest/module.json5` | 设备测试模块配置（testRunner） |
| `entry/src/ohosTest/ets/test/Ability.test.ets` | 设备集成测试 |
| 设备端 `/system/bin/uitest` | UI 自动化：点击/手势/截图/控件树 dump |
| 设备端 `/system/bin/snapshot_display` | 截图（`-f <file>` 输出到设备） |
| 设备端 `/system/bin/uinput` | 底层输入注入 |
| 设备端 `/system/bin/wukong` | 随机 UI 压测 |
