# 技能：HarmonyOS CI 云端构建（免 DevEco Studio）

**适用场景**：GitHub Actions 云端构建 HarmonyOS 应用（产出 `.hap`），全程无需安装 DevEco Studio；以及镜像维护、新项目接入、构建排障。

**自动触发条件（满足任意一条即应主动阅读本文件）**：
- 用户提到 CI / 云端构建 / GitHub Actions / 流水线 / HAP 产物 / 免 DevEco 构建 / 自动发布 Release
- 涉及 `.github/workflows/`、`docker/`、`harmonyos-ci`、`ghcr.io` 镜像、`strip_signing` 脚本
- 需要把某个项目接入自动构建、新增 API 版本镜像、排查 CI 构建报错
- 提到 harmonyos-ci 仓库、harmonyos-ci:apiXX 镜像 tag

---

## 1. 背景：镜像体系（一个 package，多 tag）

所有 HarmonyOS 构建镜像统一收敛在**一个 package**：`ghcr.io/dalongzhuazi/harmonyos-ci`（public、匿名可拉）。构建/维护归 **[harmonyos-ci](https://github.com/DaLongZhuaZi/harmonyos-ci) 仓库**，各项目只消费不拥有。

| Tag | command-line-tools | 适用 SDK | 消费者 |
|---|---|---|---|
| `api23` | 6.1.0.818 | HarmonyOS 6.1.0（API 23） | Coder |
| `api24` | 6.1.1.300 | HarmonyOS 6.1.1（API 24） | — |
| `api26` | 26.0.0.461 | HarmonyOS 26.0.0（API 26 Beta1） | NGF、ASFWorkshop |
| `api26b2` | 26.0.0.621 | HarmonyOS 26.0.0（API 26 Beta2） | — |

关键契约：镜像 tag 必须与工程 `build-profile.json5` 的 `compatibleSdkVersion` 匹配，否则 hvigor 报版本不匹配。

---

## 2. 三个 workflow（消费方模板）

消费方项目（如 NGF）在 `.github/workflows/` 下：

| Workflow | 触发 | 作用 |
|---|---|---|
| `build.yml` | push main/master、PR、手动 | 构建未签名 debug HAP → 上传 artifact → push 时自动发布滚动 `nightly` Release |
| `sign-and-release.yml` | push `v*` tag、手动 | 构建 → hap-sign-tool 签名 → 发布版本化 Release |
| （镜像构建在 harmonyos-ci 仓库，消费方不再维护 docker-image.yml） |

> 完整双语指南：`docs/CI_Guide.md` / `docs/CI_Guide.en.md`（消费方仓库内）。

---

## 3. 标准接入步骤（把某个项目接入 CI）

1. 确认项目 `build-profile.json5` 的 `compatibleSdkVersion`，确定要用的镜像 tag（API 23→api23、API 26→api26 等）。
2. 复制三个文件到该项目：
   - `.github/workflows/build.yml`（把镜像 tag 改成对应版本）
   - `.github/workflows/sign-and-release.yml`（同上）
   - `.github/scripts/strip_signing.py`
3. 若项目有 git 子模块（`.gitmodules` 存在），checkout 必须加 `submodules: recursive`。
4. 提交推送 → Actions 自动构建 → 在 Releases/Artifact 下载 `.hap`。

要点：CI 会先运行 `strip_signing.py` 剥离 `build-profile.json5` 的本机签名配置，产出**未签名** HAP；`ohpm install --all` 再 `hvigorw assembleHap ... --no-daemon`。

---

## 4. 新增 API 版本镜像（在 harmonyos-ci 仓库）

1. 取得与目标 API 匹配的 Linux (x86-64) command-line-tools 直链：从官方下载中心 https://developer.huawei.com/consumer/cn/download/ 搜索「commandline-tools」获取（需登录+签名），或使用社区镜像分片（见 official-doc-links.md §5）。
2. 在 harmonyos-ci 仓库运行 **Build CI image**（workflow_dispatch）：填 `clt_zip_url`、`clt_version`、`image_tag`。
3. 构建成功后会自动推送镜像 + 发布一条正式 Release（非 prerelease）作为构建公告。

跨仓库写已存在的 ghcr package 必须用 user 级 PAT（`secrets.GHCR_PAT`，scope 含 `write:packages`），repo 级 GITHUB_TOKEN 会被 deny。

---

## 5. 签名与自动发布

- **滚动 nightly Release**：push main/master 自动更新（未签名 HAP，默认开启）。
- **版本化 Release + 签名**：push `v*` tag 触发 `sign-and-release.yml`，需 Secrets：`SIGNING_CERT`/`SIGNING_PROFILE`/`SIGNING_KEY`（base64）、`SIGNING_KEY_ALIAS`、`KEYSTORE_PASSWORD`/`KEY_PASSWORD`。未配齐则跳过签名不报红。

---

## 6. 关键命令

```bash
# 消费方 CI 内实际执行的构建命令
ohpm install --all
hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon --stacktrace
# 产物路径(多模块用 find 兜底)
#   <module>/build/default/outputs/default/entry-default-unsigned.hap
# 本地无 DevEco 复现云端环境
docker run --rm -v "$PWD":/workspace ghcr.io/dalongzhuazi/harmonyos-ci:api26 \
  bash -lc 'ohpm install --all && hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon'
```

---

## 7. 关键文件路径速查

| 文件 | 说明 |
|------|------|
| `.github/workflows/build.yml` | 构建 + artifact + 自动滚动 Release |
| `.github/workflows/sign-and-release.yml` | tag 签名发布 |
| `.github/scripts/strip_signing.py` | 剥离本机签名配置（产出未签名 HAP） |
| `docs/CI_Guide.md` / `docs/CI_Guide.en.md` | 完整双语 CI 指南 |
| harmonyos-ci 仓库 `docker/harmonyos-ci.Dockerfile` | 镜像定义（zip/tar.gz + 分片 + sha256） |

---

## 8. 常见坑（均已验证）

- **libGL.so.1 缺失**：裸容器缺 OpenGL；镜像已内置 `libgl1/libegl1/...`，自建镜像需补装。
- **shopt: not found**：runner 默认 `sh`(dash) 无 shopt；workflow 需 `defaults.run.shell: bash`。
- **write_package denied**：跨仓库写已存在 ghcr package 要用 PAT 而非 GITHUB_TOKEN。
- **子模块悬空**：`.gitmodules` 指向的 commit 未推送到远端会 `not our ref`；先推送子模块。
- **hvigor 版本不匹配**：镜像 tag 与 `compatibleSdkVersion` 不符；换对应 API 的镜像 tag。

## 8. 官方参考

- 官方文档索引（构建/打包/发布/命令行人工具）：见 [official-doc-links.md](official-doc-links.md) §4
- hvigor 构建工具：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hvigor
- 应用签名/HAP 打包：见 official-doc-links.md §4（`ide-signing`）
- 命令行人工具（hap-sign-tool/hdc/aa/bm/hilog）：见 official-doc-links.md §4
- harmonyos-ci 镜像仓库：https://github.com/DaLongZhuaZi/harmonyos-ci（tags: api23/api24/api26/api26b2）
