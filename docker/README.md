# harmonyos-ci (HarmonyOS CI 镜像 / CI images)

本镜像用于在 GitHub Actions 上**无需 DevEco Studio** 即可构建 HarmonyOS 工程，产出 `.hap` 产物。
These images build HarmonyOS apps **without DevEco Studio** inside GitHub Actions, producing `.hap` artifacts.

**Package 地址 / Package URL**：https://github.com/DaLongZhuaZi/NGF/pkgs/container/harmonyos-ci

## 可用 tag / Available tags

| Tag | command-line-tools | 适用 SDK / For SDK | 消费者 / Consumers |
|---|---|---|---|
| `api26` | 26.0.0.461 | HarmonyOS 26.0.0（API 26） | NGF、ASFWorkshop |
| `api23` | 6.1.0.818 | HarmonyOS 6.1.0（API 23） | Coder |

两个 tag 均 `public`，任何仓库可匿名拉取（复用）。
Both tags are `public` and pullable anonymously (reusable across repos).

> 该 package 归 **NGF 仓库** 所有（由 NGF 的 `.github/workflows/docker-image.yml` 构建推送）；
> 其它项目（ASFWorkshop / Coder）作为**消费者**拉取对应 tag，因此它们的仓库页面不会出现此 package——这是「一个镜像、多仓复用」的正确形态。
> This package belongs to the **NGF repo** (built/pushed by NGF's `docker-image.yml`);
> other projects (ASFWorkshop / Coder) just pull the tag they need as consumers.

## 内含 / Contents

| 组件 / Component | 说明 / Description |
|---|---|
| command-line-tools | 随 tag 锁定、可复现 / pinned per tag |
| hvigor / hvigorw | 构建编排（等价 Android 的 gradle）/ build orchestration (= Android gradle) |
| ohpm | 依赖管理（等价 Android 的 maven）/ package manager (= Android maven) |
| HarmonyOS SDK | 与 tag 匹配的 API 版本 / matching API per tag |
| hap-sign-tool.jar | JDK 17 运行时签名工具 / signing tool (requires JDK 17) |
| libGL/EGL/GLES + X11/GBM | SDK 资源编译器 restool 所需的 headless 图形运行库 / headless GL libs required by restool |

## 用途 / Usage

本镜像由各仓库的 `.github/workflows/build.yml` 与 `.github/workflows/sign-and-release.yml` 自动使用，无需手动操作。
Each repo's `.github/workflows/build.yml` / `sign-and-release.yml` consumes it automatically — no manual step required.

本地手动构建（免 DevEco Studio）/ Local manual build:
```bash
# API 26 工程
docker run --rm -v "$PWD":/workspace ghcr.io/dalongzhuazi/harmonyos-ci:api26 bash -lc 'ohpm install --all && hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon'
# API 23 工程
docker run --rm -v "$PWD":/workspace ghcr.io/dalongzhuazi/harmonyos-ci:api23 bash -lc 'ohpm install --all && hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon'
```

## 为新 API 版本新增 tag / Adding a tag for a new API version

1. 取得对应版本的 Linux (x86-64) command-line-tools 直链（社区镜像分片、空格分隔，也可附 `.sha256` 校验）：
   - API 26：`jerry-271828/harmonyos-commandline-tools` 的 `v26.0.0.461`（zip 分片）
   - API 23：`ErBWs/ohos-sdk` 的 `6.1.0.818`（tar.gz.aa / .ab 分片 + .sha256）
2. 运行 NGF 仓库的 **Build CI image** workflow（workflow_dispatch），`clt_zip_url` 填对应直链、`image_tag` 填新 tag（如 `api24`）。

> GitHub 包页面当前渲染的是本仓库根目录 `README.md`；镜像描述来自 OCI label（见本目录 Dockerfile）。
> 完整中文/英文步骤见 [docs/CI_Guide.md](../docs/CI_Guide.md) / [docs/CI_Guide.en.md](../docs/CI_Guide.en.md)。