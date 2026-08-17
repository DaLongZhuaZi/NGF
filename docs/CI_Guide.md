# CI 免 DevEco Studio 构建指南

> 本仓库通过 GitHub Actions 实现「push 即云端出包」，全程**无需安装 DevEco Studio**。
> 本文件与 [CI_Guide.en.md](CI_Guide.en.md) 内容对应（中英双语）。

## 1. 概览

三个 workflow（位于 `.github/workflows/`）：

| Workflow | 触发 | 作用 |
|---|---|---|
| `docker-image.yml` | 已迁至 [harmonyos-ci](https://github.com/DaLongZhuaZi/harmonyos-ci) 仓库 | 统一构建 API 23/26 CI 镜像（本仓库只消费） |
| `build.yml` | push `main`/`master`、PR、手动 | 构建未签名 debug HAP → 上传 artifact → **push 时自动发布滚动 `nightly` Release** |
| `sign-and-release.yml` | push `v*` tag、手动 | 构建 → hap-sign-tool 签名 → 发布版本化 Release |

触发矩阵：

| 操作 | 结果 |
|---|---|
| push 到 `main`/`master`（文件有修改） | 自动构建 + 自动发布/更新 `nightly` 滚动 Release |
| 打开/更新 PR | 仅构建（不发布 Release） |
| 推送 `v*` tag | 构建 + 签名（若配了密钥）+ 发布版本化 Release |

## 2. 前置条件

- 镜像 `ghcr.io/dalongzhuazi/harmonyos-ci:api26` 已就绪（public）。
- 镜像的构建/维护统一由 **[harmonyos-ci](https://github.com/DaLongZhuaZi/harmonyos-ci) 仓库**负责（Dockerfile + 构建 workflow + 多 API 版本 tag）；需要重建或新增 API 版本（如 api23、api24）时，按该仓库 README 操作即可，本仓库只消费镜像。

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
| `CLT_ZIP_URL` | （已随镜像构建迁至 harmonyos-ci 仓库） |

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
| 镜像不存在导致构建失败 | 镜像由 [harmonyos-ci](https://github.com/DaLongZhuaZi/harmonyos-ci) 仓库统一构建；先确认对应 tag 已存在 |
| `entry-default-unsigned.hap` 无法直接安装 | 未签名 HAP 需先签名（DevEco Studio 或 hap-sign-tool） |

## 8. 文件索引

- `.github/workflows/build.yml` — 构建 + artifact + 自动滚动 Release
- `.github/workflows/sign-and-release.yml` — tag 签名发布
- （镜像构建已迁至 [harmonyos-ci](https://github.com/DaLongZhuaZi/harmonyos-ci) 仓库）
- `.github/scripts/strip_signing.py` — 剥离本机签名配置（产出未签名 HAP）