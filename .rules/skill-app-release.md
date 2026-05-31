# 技能：框架业务化与 AGC 上架发布指南 (App Release)

**适用场景**：当需要将纯净的 NGF 框架工程转变为你自己的真实业务 App，修改包名、图标、版本号，配置真实的签名证书（调试/发布），以及最终打包推送到 AppGallery Connect (AGC) 上架或内测时。绝对禁止使用针对 Android 的打包流程。

**触发条件（满足任意一条即应主动阅读本文件）**：
- 收到“修改应用名”、“替换 App 图标”、“更换包名(bundleName)”等业务化指令。
- 收到“如何生成签名证书”、“如何获取 p12/p7b 文件”、“帮我打包正式版”等上架相关指令。
- 试图执行构建应用级别的包（如 `.app` 或 `.hap`）以准备对外发布时。

---

## 阶段一：本地定制化 (Local Customization)

在正式签名之前，必须先将本框架完全剥离“NGF”印记，定制为你自己的 App。

### 1. 修改唯一包名 (Bundle Name)
这是你在应用市场的唯一标识，必须与 AGC 后台创建应用时的包名**完全一致**。
- **修改位置 1**：`AppScope/app.json5` 中的 `bundleName` 字段。
  ```json5
  // AppScope/app.json5
  {
    "app": {
      "bundleName": "com.yourcompany.yourapp", // 必须全局唯一
      // ...
    }
  }
  ```
- **同步要求**：修改后请全局搜索旧包名 `com.dlzz.ngf`，确保没有任何历史硬编码残留。

### 2. 修改应用名称与多语言
- **应用内部资源**：`AppScope/resources/base/element/string.json` 中的 `app_name`。
- **中文覆盖**：`AppScope/resources/zh_CN/element/string.json` 中的 `app_name`。
桌面最终显示的名称由这里决定。

### 3. 替换应用图标 (App Icon)
- **修改位置**：将你的新图标替换到 `AppScope/resources/base/media/app_icon.png`。
- **规范**：必须是 114x114 到 512x512 之间的正方形 PNG，系统会自动进行圆角裁剪，四周请不要自带透明圆角。

### 4. 版本号管理
每次提交 AGC 新版本时，必须自增 `versionCode`。
- **修改位置**：`AppScope/app.json5`
  ```json5
  "versionCode": 1000000,    // 用于商店的版本对比，必须递增
  "versionName": "1.0.0"     // 面向用户的展示版本号
  ```

---

## 阶段二：真实的 AGC 上架与签名流程 (AGC Process)

HarmonyOS Next 的应用签名体系非常严格，禁止使用未经授权的测试签名上架。

### 第 1 步：AGC 创建项目与应用
1. 登录 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)。
2. 在“我的项目”中创建新项目，然后在该项目下“添加应用”。
3. **平台选择**：HarmonyOS。
4. **包名输入**：填入你在阶段一中设定的 `bundleName`（例如 `com.yourcompany.yourapp`）。

### 第 2 步：生成密钥库 (.p12) 与证书请求 (.csr)
你需要使用 DevEco Studio 本地生成加密凭据，不要让第三方代为生成。
1. 在 DevEco Studio 顶部菜单栏选择 `Build > Generate Key and CSR`。
2. 创建一个新的 Key Store（会生成一个 `.p12` 文件），牢记密码。
3. 填写 Alias、Password 以及你的企业/个人信息。
4. 点击 Finish，IDE 会在指定目录下同时生成一个 `.csr`（Certificate Signing Request）文件。

### 第 3 步：在 AGC 申请证书 (.cer) 与 Profile (.p7b)
这是鸿蒙独有的授权机制。
1. **申请证书 (Certificate)**：
   - 进入 AGC -> "用户与访问" -> "证书管理" -> "新增证书"。
   - 证书类型选择 **“发布” (Release)**（如果是真机联调则选“调试”）。
   - 上传你刚才生成的 `.csr` 文件。
   - AGC 审核通过后，下载生成的 `.cer` 证书文件。
2. **生成 Profile (Profile)**：
   - 进入 AGC -> "我的项目" -> 选择你的项目 -> "HAP Provision Profile" -> "添加"。
   - 选择你刚刚创建的**发布证书**，并绑定你的**应用**。
   - 下载生成的 `.p7b` 配置文件。

### 第 4 步：在 DevEco Studio 配置正式签名
将 `.p12`、`.cer`、`.p7b` 三个文件放到安全目录（切勿提交到开源 Git，可以放在外层目录或忽略）。
1. 打开 `File > Project Structure > Project > Signing Configs`。
2. 取消勾选 `Automatically generate signature`。
3. 新增一个名为 `release` 的配置，依次填入：
   - `Store file`: 你的 `.p12` 文件路径
   - `Store password`: 你的密钥库密码
   - `Key alias`: 你的密钥别名
   - `Key password`: 密钥别名密码
   - `Sign alg`: 通常为 `SHA256withECDSA`
   - `Profile file`: 从 AGC 下载的 `.p7b`
   - `Certpath file`: 从 AGC 下载的 `.cer`
4. 确认 `build-profile.json5` 中的 `products` 节点，`default` product 的 `signingConfig` 指向了 `"release"`。

### 第 5 步：构建用于上架的最终包 (App/Hap)
确保在 PowerShell 中显式设置 SDK 路径并执行构建，**且必须带上 `--release` 标志**：
```powershell
$env:DEVECO_SDK_HOME='F:\DevEco Studio\sdk'; & 'F:\DevEco Studio\tools\hvigor\bin\hvigorw.bat' assembleApp --release --no-daemon
```
> **注意**：上架使用的是 `assembleApp` 产物（生成 `.app` 包），而局域网测试分发单模块可以使用 `assembleHap`（生成 `.hap`）。

### 第 6 步：AGC 邀请测试或正式上架
1. 回到 AGC 的“我的应用” -> "分发" -> "版本信息"。
2. 点击“软件包管理”，上传刚刚构建出的 `.app` 包。
3. **如需开放测试 (Open Testing)**：在后台找到“开放测试”菜单，创建测试列表，通过邀请码分发给用户。
4. **如需正式上架**：填写完善的应用介绍、隐私政策网址、应用分级（年龄），选择截图，点击“提交审核”。审核期通常为 1-3 个工作日。

---

## 3. Agent 执行本规则的底线要求

作为 AI 助手，在响应用户的发布需求时：
- **绝对禁止**使用任何与 Android APK 相关的签名工具（如 `apksigner`、`keytool`）来处理 HarmonyOS Next 产物。
- **绝对禁止**在没有任何 `.p7b` 授权配置的情况下，强行劝导用户执行 release 打包并承诺可以直接安装。
- 当用户询问上架步骤时，必须严格按照本文件中**六个步骤**的顺序进行解释，并明确指出必须要去“AppGallery Connect”操作。
