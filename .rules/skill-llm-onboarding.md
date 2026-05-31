# 技能：LLM 项目初始化与环境基线探针

**适用场景**：AI 代理（Agent/LLM）在开启一个新会话时，为了快速熟悉当前工程结构、自动核查本地 SDK 路径、定位构建工具以及推导正确的编译命令而执行的标准探针流程。

**触发条件（满足任意一条即应主动阅读本文件）**：
- Agent 开启新会话，首次接触本项目（Onboarding / 初始化阶段）
- 遇到 `SDK path not found`、`hvigorw not found` 等环境异常
- 遇到 `targetSdkVersion` 或 `compatibleSdkVersion` 与本地不匹配的编译错误
- 需要执行任何形式的自动编译或预览但尚未构建正确的命令环境时

---

## 1. 背景

HarmonyOS Next 项目依赖特定的 DevEco Studio 与 SDK 路径，不同机器的安装环境往往不一致，且 `local.properties` 有时可能未记录 SDK 路径。如果 LLM 在缺乏本机环境认知的情况下盲目猜测路径或执行标准 npm/yarn 命令，将导致项目彻底破坏或陷入报错死循环。
本技能要求 LLM 执行一套标准的**动态探针流程**，在修改代码或执行构建前，先自我确认环境基线。

## 2. 探针执行流程（LLM 必须运行的预检指令）

### 2.1 检查项目配置基线
请主动读取以下关键文件（务必使用 UTF-8 编码读取）：
- `build-profile.json5`：提取 `targetSdkVersion` 与 `compatibleSdkVersion`。
- `ngf_framework/oh-package.json5`：这是框架主模块配置，获取核心依赖和 `modelVersion`。
- `entry/oh-package.json5`：这是应用层模块配置。
- `AppScope/app.json5`：获取 `bundleName`。

### 2.2 扫描本地 SDK 与 IDE 路径
请运行 PowerShell 脚本来动态嗅探本地可能存在的 SDK 与构建工具路径，严禁凭空编造：

```powershell
# 嗅探可能的 SDK 根目录
Test-Path "F:\HarmonyOS\SDK"
Test-Path "D:\HarmonyOS\SDK"
Test-Path "C:\Users\*\AppData\Local\Huawei\Sdk"

# 嗅探可能的 DevEco Studio 与默认工具链
Test-Path "F:\DevEco Studio\sdk\default\openharmony"
Test-Path "D:\DevEco Studio\sdk\default\openharmony"
Test-Path "C:\Program Files\Huawei\DevEco Studio\sdk"
```
> **当前实测基线参考**：截至最新探测，本机的 SDK 目录为 `F:\HarmonyOS\SDK\23`，DevEco Studio 工具链位于 `F:\DevEco Studio\sdk`。如果探测结果与此不符，以你的最新探测结果为准。

### 2.3 构建正确的环境变量与编译命令

一旦探针确认了有效的 IDE SDK 目录和 Hvigor 路径，在后续任何执行构建的 `run_command` 中，**必须采用显式声明环境变量配合绝对路径的方式**调用 `hvigorw.bat`：

**正确的 PowerShell 组合执行模式**：
```powershell
$env:DEVECO_SDK_HOME='F:\DevEco Studio\sdk'; & 'F:\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleHap --no-daemon --stacktrace
```
- `DEVECO_SDK_HOME` 指向包含 `default/openharmony` 的那层 sdk 目录。
- 必须使用 `&` 调用带空格的路径。
- 必须包含 `--no-daemon` 防止 Agent 进程挂起或锁死。
- 执行该命令的工作目录（Cwd）必须为当前仓库的根目录。

## 3. 常见环境问题与修复策略

### 3.1 Ninja 缓存冲突
**报错**：`generator : Ninja does not match the generator used previously...`
**对策**：清理指定模块内的 `.cxx` 和 `CMakeCache.txt` 缓存，然后重新执行构建。严禁使用 `rm -rf` 无差别清空整个 `entry` 目录。
**命令**：
```powershell
& 'F:\DevEco Studio\tools\hvigor\bin\hvigorw.bat' clean --no-daemon
```

### 3.2 找不到对应版本的 SDK
**报错**：`The compatibleSdkVersion X is not found.`
**对策**：根据你在 2.2 节嗅探到的本机实际 SDK 版本（例如 `F:\HarmonyOS\SDK\23` 则版本为 `23`），去修改 `build-profile.json5` 的相关字段，使项目版本对齐本机实际版本，然后再编译。

### 3.3 工具链路径在后续步骤中丢失
**对策**：Agent 的每次 `run_command` 会话可能并不继承上一次的环境变量。**在同一轮对话中，如果需要多次构建，每一次执行 `hvigorw.bat` 都必须带上前置的 `$env:DEVECO_SDK_HOME=...` 声明。**
