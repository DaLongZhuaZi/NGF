# harmonyos-ci (HarmonyOS NEXT API 26 CI 镜像 / CI image)

本镜像用于在 GitHub Actions 上**无需 DevEco Studio** 即可构建 NGF(HarmonyOS NEXT / API 26)工程，产出 `.hap` 产物。
This image builds NGF (HarmonyOS NEXT / API 26) **without DevEco Studio** inside GitHub Actions, producing `.hap` artifacts.

镜像 tag / Image tag: `ghcr.io/dalongzhuazi/harmonyos-ci:api26`（由本仓库 `.github/workflows/docker-image.yml` 一次性构建并推送）。
Image tag: `ghcr.io/dalongzhuazi/harmonyos-ci:api26` (built and pushed once by `.github/workflows/docker-image.yml`).

## 内含 / Contents

| 组件 / Component | 说明 / Description |
|---|---|
| command-line-tools | 26.0.0.461 (linux-x64)，随镜像锁定、可复现 / pinned for reproducibility |
| hvigor / hvigorw | 构建编排（等价 Android 的 gradle）/ build orchestration (= Android gradle) |
| ohpm | 依赖管理（等价 Android 的 maven）/ package manager (= Android maven) |
| HarmonyOS SDK | API 26（default/openharmony 与 default/hms）/ API 26 SDK |
| hap-sign-tool.jar | JDK 17 运行时签名工具 / signing tool (requires JDK 17) |
| libGL/EGL/GLES + X11/GBM | SDK 资源编译器 restool 所需的 headless 图形运行库 / headless GL libs required by restool |

## 用途 / Usage

本镜像由 `.github/workflows/build.yml` 与 `.github/workflows/sign-and-release.yml` 自动使用，无需手动操作。
This image is consumed automatically by `.github/workflows/build.yml` and `.github/workflows/sign-and-release.yml` — no manual step required.

本地手动构建（免 DevEco Studio）/ Local manual build:
```bash
docker run --rm -v "$PWD":/workspace ghcr.io/dalongzhuazi/harmonyos-ci:api26 \
  bash -lc 'ohpm install --all && hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon'
```

## 重建 / Rebuild

1. 取得 Linux (x86-64) command-line-tools zip 直链：社区镜像 [jerry-271828/harmonyos-commandline-tools](https://github.com/jerry-271828/harmonyos-commandline-tools) 的 `v26.0.0.461` 分片（多个 URL 以空格分隔），或华为官方「获取命令行工具」页下载后转存到可直链处。
2. 运行仓库的 **Build CI image** workflow（workflow_dispatch），或本地：
   ```bash
   docker build --build-arg CLT_ZIP_URL="<url0> <url1>" -t harmonyos-ci:api26 ./docker
   ```

> GitHub 包页面当前渲染的是本仓库根目录 `README.md`；镜像描述来自 OCI label（见本目录 Dockerfile）。
> 完整中文/英文步骤见 [docs/CI_Guide.md](../docs/CI_Guide.md) / [docs/CI_Guide.en.md](../docs/CI_Guide.en.md)。