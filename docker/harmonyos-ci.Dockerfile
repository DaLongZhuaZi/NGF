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

# 基础依赖: JDK 17 供 hap-sign-tool 签名; git/python3 供 actions/checkout 与仓库内 CI 脚本;
# libGL/EGL/GLES + X11/GBM 等 headless 图形运行库为 SDK 资源编译器(restool/
# image_transcoder)必需, 缺失会报 'libGL.so.1: cannot open shared object file'(裸容器 CI 常见坑)。
# 分两组安装便于失败定位; 显式确保 universe 组件; 关闭 pty 使 apt 输出可被 Actions 日志捕获。
RUN sed -i 's|Components: main.*|Components: main universe restricted multiverse|' /etc/apt/sources.list.d/*.sources 2>/dev/null || true \
    && apt-get update -o Dpkg::Use-Pty=0 \
    && apt-get install -y --no-install-recommends -o Dpkg::Use-Pty=0 \
         openjdk-17-jdk-headless unzip curl git ca-certificates python3 \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update -o Dpkg::Use-Pty=0 \
    && apt-get install -y --no-install-recommends -o Dpkg::Use-Pty=0 \
         libgl1 libegl1 libgles2 libglx0 libglib2.0-0 \
         libx11-6 libxext6 libxrender1 libxrandr2 libxfixes3 libxi6 libxcursor1 \
         libxcomposite1 libxdamage1 libxtst6 libxkbcommon0 \
         libgbm1 libdrm2 fontconfig fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

# 下载、拼接、校验并解压 command-line-tools, 自动判型 zip / tar.gz。
# CLT_ZIP_URL: 以空格分隔的分片直链, 按顺序 cat 拼接还原完整归档:
#   - zip 分片:    ...clt.zip.part00 / .part01 (API 26 社区镜像)
#   - tar.gz 分片: ...ohos-sdk-linux-amd64.tar.gz.aa / .ab (API 23 社区镜像)
#   可在末尾附加一个 *.sha256 的直链做完整性校验。
# 解压后统一归一化到 /opt/command-line-tools(bin/ tool/ sdk/ 结构)。
RUN set -eux; \
    test -n "$CLT_ZIP_URL"; \
    mkdir -p /tmp/clt; cd /tmp/clt; \
    i=0; for u in $CLT_ZIP_URL; do \
      case "$u" in *.sha256) curl -fL --retry 3 --retry-delay 5 -o sha256.txt "$u";; \
      *) curl -fL --retry 3 --retry-delay 5 -o "part.$i" "$u"; i=$((i+1));; \
      esac; \
    done; \
    for u in $CLT_ZIP_URL; do FIRURL="$u"; break; done; \
    ARCHIVE=clt.zip; \
    case "$FIRURL" in *.tar*) ARCHIVE=clt.tar.gz;; esac; \
    : > "$ARCHIVE"; \
    for f in part.*; do cat "$f" >> "$ARCHIVE"; done; \
    if [ -f sha256.txt ]; then \
      EXPECT=$(awk '{print $1}' sha256.txt); \
      ACTUAL=$(sha256sum "$ARCHIVE" | awk '{print $1}'); \
      test "$EXPECT" = "$ACTUAL"; \
    fi; \
    mkdir -p out; \
    case "$ARCHIVE" in *.tar.gz) tar -xzf "$ARCHIVE" -C out;; *) unzip -q "$ARCHIVE" -d out;; esac; \
    CLTDIR=$(find out -maxdepth 2 -type d -name command-line-tools | head -n1); \
    test -n "$CLTDIR"; \
    mv "$CLTDIR" /opt/command-line-tools; \
    ls -la /opt/command-line-tools/bin/; \
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

# OCI 元数据: 这些 label 会显示在 GitHub Package 页面(ghcr.io)的描述区。
# OCI labels: these populate the GitHub Package (ghcr.io) page description.
LABEL org.opencontainers.image.title="harmonyos-ci (HarmonyOS NEXT API 26 构建镜像 / CI build image)" \
      org.opencontainers.image.description="无 DevEco Studio 的 HarmonyOS NEXT (API 26) 云端构建镜像: command-line-tools 26.0.0.461 + hvigor + ohpm + SDK + hap-sign-tool。 / Build HarmonyOS NEXT (API 26) HAPs in CI without DevEco Studio: command-line-tools 26.0.0.461 + hvigor + ohpm + SDK + hap-sign-tool." \
      org.opencontainers.image.version="26.0.0.461" \
      org.opencontainers.image.source="https://github.com/DaLongZhuaZi/NGF" \
      org.opencontainers.image.documentation="https://github.com/DaLongZhuaZi/NGF/blob/main/docker/README.md" \
      org.opencontainers.image.licenses="MIT"

WORKDIR /workspace
CMD ["/bin/bash"]
