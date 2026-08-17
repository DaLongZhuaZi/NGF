# CI 免 DevEco Studio 构建指南

> 本仓库通过 GitHub Actions 实现「push 即云端出包」，全程**无需安装 DevEco Studio**。
> 本文件与 [CI_Guide.en.md](CI_Guide.en.md) 内容对应（中英双语）。

## 1. 概览

三个 workflow（位于 `.github/workflows/`）：

| Workflow | 触发 | 作用 |
|---|---|---|
| `docker-image.yml` | 手动（workflow_dispatch） | 一次性构建 API 26 CI 镜像并推送 ghcr.io |
| `build.yml` | push `main`/`master`、PR、手动 | 构建未签名 debug HAP → 上传 artifact → **push 时自动发布滚动 `nightly` Release** |
| `sign-and-release.yml` | push `v*` tag、手动 | 构建 → hap-sign-tool 签名 → 发布版本化 Release |

触发矩阵：

| 操作 | 结果 |
|---|---|
| push 到 `main`/`master`（文件有修改） | 自动构建 + 自动发布/更新 `nightly` 滚动 Release |
| 打开/更新 PR | 仅构建（不发布 Release） |
| 推送 `v*` tag | 构建 + 签名（若配了密钥）+ 发布版本化 Release |

## 2. 前置条件

- GitHub 仓库（公开仓库的 release 资产可直接下载）。
- 首次需要一次性构建 CI 镜像（见 §3），之后全自动。

## 3. 首次搭建（一次性，约 15 分钟）

### 3.1 取得 command-line-tools Linux zip 直链

需要与工程 API 26 匹配的 Linux (x86-64) command-line-tools zip，两种来源任选：

1. **社区镜像（推荐，链接稳定公开）**：[jerry-271828/harmonyos-commandline-tools](https://github.com/jerry-271828/harmonyos-commandline-tools) 的 `v26.0.0.461` release，zip 被切成两个分片（`clt.zip.part00` / `clt.zip.part01`），把两个分片 URL 以空格分隔填入即可，Dockerfile 会自动 cat 拼接。
2. **华为官方**：[「获取命令行工具」](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-commandline-get) 下载（链接带时效签名，先下载到本地再上传到 GitHub Release 附件 / 对象存储等可直链处）。

### 3.2 配置并构建镜像

1. 在仓库 Settings → Secrets and variables → Actions 添加 secret `CLT_ZIP_URL`（值为 zip 直链，多个 URL 空格分隔）。
2. 手动运行一次 **Build CI image** workflow，产出 `ghcr.io/<owner>/harmonyos-ci:api26`。
3. 后续 `build.yml` / `sign-and-release.yml` 默认引用该锁定 tag，构建环境可复现。

> 也可在 workflow_dispatch 的 `clt_zip_url` 输入框直接填 URL（不必存 secret）。

## 4. 免 DevEco Studio 的三种构建方式

### 方式 A：云端自动（默认，零操作）
push 到 `main` 后，Actions 自动在 ghcr 镜像内执行：
```bash
ohpm install --all
hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon --stacktrace
```
产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`，随 artifact 与 `nightly` Release 分发。

### 方式 B：本地 Docker（不装 DevEco，复现云端环境）
```bash
docker run --rm -v "$PWD":/workspace ghcr.io/dalongzhuazi/harmonyos-ci:api26 \\
  bash -lc 'ohpm install --all && hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon'
```

### 方式 C：本机 DevEco 命令行（已装 DevEco 时）
用 IDE 自带 hvigor（见 `.local-rules/build-commands.local.md`）：
```powershell
$env:DEVECO_SDK_HOME='G:\\DevEco Studio 26\\DevEco Studio\\sdk'; & 'G:\\DevEco Studio 26\\DevEco Studio\\tools\\hvigor\\bin\\hvigorw.bat' assembleHap --no-daemon --stacktrace
```
（该路径为本机事实，不同机器请以实际 DevEco 安装目录为准。）

## 5. 签名与自动 Release

### 滚动 nightly Release（无需签名，已默认开启）
每次 push `main`/`master`，`build.yml` 的 `release` job 用 `gh release` 移动 `nightly` tag 并更新同名额预发布（prerelease），附带未签名 HAP 与双语说明。

### 版本化 Release + 签名（可选，需配置密钥）
push `v*` tag 触发 `sign-and-release.yml`。所需 Secrets（证书/密钥文件 base64 编码，绝不入库；`.gitignore` 已拦截证书类文件）：

| Secret | 内容 |
|---|---|
| `SIGNING_CERT` | `.cer` 公钥证书，base64（`base64 -w 0` 生成单行） |
| `SIGNING_PROFILE` | `.p7b` 签名 profile，base64 |
| `SIGNING_KEY` | `.p12` 密钥库文件，base64 |
| `SIGNING_KEY_ALIAS` | 密钥别名（明文） |
| `KEYSTORE_PASSWORD` / `KEY_PASSWORD` | 密钥库 / 密钥口令（明文） |
| `CLT_ZIP_URL` | （仅 docker-image.yml 用）zip 直链 |

> 未配置签名 Secrets 时，tag 构建会跳过签名并输出指引，不会报红失败。

## 6. 验证

1. push 后打开 Actions 页，确认 `Assemble HAP` 与 `Auto-publish rolling Release` 均为绿色。
2. 在 Releases 页或 Action artifact 下载 `entry-default-unsigned.hap`（`gh run download <id> -n hap-unsigned`），用 DevEco Studio 重新签名后安装。
3. 确认 hap 非空且为合法 ZIP 容器（文件头 `50 4B 03 04` = `PK`）。

## 7. 排障

| 现象 | 原因与解决 |
|---|---|
| `libGL.so.1: cannot open shared object file` | 裸容器缺 OpenGL 系统库；镜像已内置 `libgl1/libegl1/...` |
| `shopt: not found` | runner 默认 sh(dash) 无 shopt；workflow 已用 `defaults.run.shell: bash` |
| `hvigor 版本不匹配 / unsupported model version` | command-line-tools 与工程 `modelVersion 26.0.0` 不匹配；改用 26.0.0.x 的 zip 重建镜像 |
| 镜像不存在导致构建失败 | 首次需先跑 Build CI image，再让 push 触发构建 |
| `entry-default-unsigned.hap` 无法直接安装 | 未签名 HAP 需先签名（DevEco Studio 或 hap-sign-tool） |

## 8. 文件索引

- `.github/workflows/build.yml` — 构建 + artifact + 自动滚动 Release
- `.github/workflows/sign-and-release.yml` — tag 签名发布
- `.github/workflows/docker-image.yml` — 构建推送 CI 镜像
- `.github/scripts/strip_signing.py` — 剥离本机签名配置（产出未签名 HAP）
- `docker/harmonyos-ci.Dockerfile` / `docker/README.md` — CI 镜像定义与说明