# NGF GitHub / Gitea 双线同步指南

## 1. 仓库职责

| 仓库 | 可见性 | 职责 |
|---|---|---|
| GitHub origin | 公开 | 公开代码主线、文档、CI 和同步工具 |
| Gitea backup/full | 私有 | 完整工作区备份、私有配置、证书、密钥材料和恢复证据 |

两个仓库不是同一份内容的双 push 目标。GitHub 是公开发布线，Gitea 是私有灾备线。

## 2. 内容边界

公开 GitHub 线允许包含：

- ArkTS/C++ 源码；
- 公开文档、规则和 CI 配置；
- 不含秘密的配置模板；
- tools/backup/ 同步工具。

私有 Gitea 线可以额外包含：

- local.properties；
- DevEco/SDK 本机配置；
- .p12、.p7b、.cer、.key、.keystore 等证书和密钥；
- 未提交的工作区改动；
- 构建产物、测试证据和本机实验记录；
- git-history.bundle。

## 3. 同步方向

    GitHub main  ->  公开代码工作区
    完整本地工作区  ->  Gitea 私有备份
    Gitea 私有备份  ->  隔离恢复目录  ->  正式工作区

禁止把 Gitea 私有备份自动推回 GitHub。也不要用 Git 的多个 pushurl 实现双推，因为 .gitignore 排除的证书不会自动进入备份，而且误 push 时无法保证秘密不泄露。

## 4. 日常操作

### 4.1 更新公开代码

    git fetch origin
    git log --oneline --decorate -5 origin/main

需要切换到公开主线时，先确认本地私有改动已经备份，再执行：

    git reset --hard origin/main
    git clean -fdx

### 4.2 创建私有完整备份

    .\tools\backup\Invoke-NgfPrivateBackup.ps1 -BackupRepo F:\DevEcoStudioProject\NGF-private-backup

如需把工作区外的证书目录加入私有备份，显式传入 AdditionalPath，例如 `$env:USERPROFILE\.ohos\config`。

审查 current/ 后，再显式推送：

    .\tools\backup\Invoke-NgfPrivateBackup.ps1 -BackupRepo F:\DevEcoStudioProject\NGF-private-backup -Push

### 4.3 恢复私有备份

先恢复到隔离目录并人工检查：

    .\tools\backup\Restore-NgfPrivateBackup.ps1 -BackupRepo F:\DevEcoStudioProject\NGF-private-backup -Destination F:\DevEcoStudioProject\NGF.restore-check

确认配置和证书来源后，才对正式目录使用 -Force。

## 5. 备份仓库建议

Gitea 私有仓库建议启用：

- 私有可见性；
- backup/full 分支保护；
- 禁止普通账号强制推送；
- NAS 文件系统快照；
- 定期离线副本；
- Gitea 访问使用 SSH key 或专用 token，不把密码写入 URL。

证书和密钥建议二次加密后再提交 Gitea。加密密钥不得与 NAS 放在同一位置。

## 6. 恢复验收

恢复完成后检查：

- backup-manifest.json 中的源 commit 和快照时间；
- 关键配置文件存在；
- 证书文件数量和哈希符合预期；
- git-history.bundle 可以被 Git 识别；
- 默认模式下，HAP/HAR 配置文件和证书存在；需要编译产物时使用 -IncludeGenerated 并检查 manifest 中的 excludedGeneratedPaths 为空；
- 公开工作区仍然不包含私有备份内容；
- 未向 GitHub 推送任何私有文件。
