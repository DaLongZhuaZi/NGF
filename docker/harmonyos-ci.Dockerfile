# NGF HarmonyOS CI image (API 26)
#
# 用途: 在 GitHub Actions 上云端构建 HarmonyOS(API 26)工程, 等价于本机的
#   DevEco Studio 26 工具链 (hvigor / ohpm / SDK / hap-sign-tool)。
#
# 构建方式(二选一):
#   A. 远程 zip(推荐, 配合 .github/workflows/docker-image.yml):
#      docker build --build-arg CLT_ZIP_URL=<下载直链> -t ghcr.io/<owner>/harmonyos-ci:api26 .
#   B. 本地 zip: 把华为官方 command-line-tools-linux-x64-*.zip 放到本目录,
#      注释掉 ARG CLT_ZIP_URL 与 curl 逻辑, 改用下方注释里的 COPY/RUN 块。
#
# zip 来源: 华为开发者官网 "获取命令行工具" 页面
#   https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-commandline-get
# 选择与工程 build-profile.json5 的 targetSdkVersion/compatibleSdkVersion 匹配的
# Linux (x86-64) 版本(本工程为 API 26 / DevEco Studio 26 时代的 command-line-tools)。
# 注意: 官方下载链接带时效签名, 不要把具体 URL 固化进仓库。

FROM ubuntu:24.04

# command-line-tools linux x64 zip 的下载直链(必须通过 --build-arg 传入)
ARG CLT_ZIP_URL

# 基础依赖: JDK 17 供 hap-sign-tool 签名; git 供 actions/checkout; python3 供仓库内 CI 脚本
RUN apt-get update && apt-get install -y --no-install-recommends \
      openjdk-17-jdk-headless unzip curl git ca-certificates python3 \
    && rm -rf /var/lib/apt/lists/*

# 下载并解压 command-line-tools。
# CLT_ZIP_URL 支持以空格分隔的多个 URL: GitHub Release 单资产上限 2GB, 大 zip
# 常被切成 clt.zip.part00/part01...(cat 拼接即可还原), 单 URL 同样适用。
# 可用来源示例(社区镜像, 26.0.0.461 linux-x64):
#   https://github.com/jerry-271828/harmonyos-commandline-tools/releases/download/v26.0.0.461/clt.zip.part00
#   https://github.com/jerry-271828/harmonyos-commandline-tools/releases/download/v26.0.0.461/clt.zip.part01
RUN set -eux; \
    test -n "$CLT_ZIP_URL"; \
    mkdir -p /tmp/clt; cd /tmp/clt; \
    i=0; for u in $CLT_ZIP_URL; do \
      curl -fL --retry 3 --retry-delay 5 -o "clt.part$i" "$u"; i=$((i+1)); \
    done; \
    cat clt.part* > clt.zip; \
    unzip -q clt.zip -d /opt/; \
    if [ ! -x /opt/command-line-tools/bin/hvigorw ]; then \
      d=$(dirname "$(dirname "$(find /opt -maxdepth 3 -type f -path '*/bin/hvigorw' | head -n1)")"); \
      mv "$d" /opt/command-line-tools; \
    fi; \
    test -x /opt/command-line-tools/bin/hvigorw; \
    test -d /opt/command-line-tools/sdk; \
    rm -rf /tmp/clt

# ---- 本地 zip 方案(B)时改用以下两行, 并注释掉上面的 ARG/RUN ----
# COPY command-line-tools-linux-x64-*.zip /tmp/
# RUN unzip -q /tmp/command-line-tools-linux-x64-*.zip -d /opt/ && rm -f /tmp/*.zip

# DEVECO_SDK_HOME 必须指向包含 default/ 的 sdk 根目录(而不是 sdk/default)
ENV DEVECO_SDK_HOME=/opt/command-line-tools/sdk
ENV PATH=/opt/command-line-tools/bin:/opt/command-line-tools/tool/node/bin:/opt/command-line-tools/tool/hvigor/bin:/opt/command-line-tools/tool/ohpm/bin:$PATH

# @ohos 域包走华为 npm 镜像(hvigor / ohpm 解析 @ohos/* 依赖依赖这条配置)
RUN echo "@ohos:registry=https://repo.harmonyos.com/npm/" >> /root/.npmrc

# 预热: hvigor 首次运行会自检并初始化 ~/.hvigor, 预热避免每次 CI 冷启动
RUN hvigorw --version

# 签名工具固定路径(需 JDK 17):
#   /opt/command-line-tools/sdk/default/openharmony/toolchains/lib/hap-sign-tool.jar

WORKDIR /workspace
CMD ["/bin/bash"]
