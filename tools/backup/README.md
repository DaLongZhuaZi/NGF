# NGF 备份工具

NGF 使用三条职责不同的仓库线：

- **GitHub `origin`**：公开主源，只保存可公开发布的代码、文档和同步工具。
- **Gitea `backup`**：私有完整备份，保存工作区快照、被 .gitignore 排除的配置/证书，以及 Git 历史 bundle。
- **GitCode `gitcode`**：公开镜像（`https://gitcode.com/dlzz/NGF.git`）。

> ⚠️ **本脚本只处理 Gitea 私有备份，不推送 GitCode。**
> GitCode 是**公开镜像**，需要手动 `git push gitcode main` ——
> 它没有任何自动化同步机制，不推就会静默落后。详见
> [仓库同步指南](../../docs/Repository_Sync_Guide.md)。

私有备份仓库必须位于 NGF 工作区之外，且不能配置为 GitHub 的第二个 push URL。

## 创建完整备份

在 NGF 根目录执行：

    .\tools\backup\Invoke-NgfPrivateBackup.ps1 -BackupRepo F:\DevEcoStudioProject\NGF-private-backup

脚本默认只生成并提交本地私有备份，不推送到 Gitea。确认备份内容后再显式推送：

    .\tools\backup\Invoke-NgfPrivateBackup.ps1 -BackupRepo F:\DevEcoStudioProject\NGF-private-backup -Push

备份仓库应配置名为 backup 或 origin 的 Gitea remote。脚本会优先使用 backup，其次使用 origin。完整快照推送到 backup/full 分支，不覆盖 Gitea 的 main 基线。外置普通配置通过 AdditionalPath 显式加入；证书应先使用 Invoke-NgfDevEcoCertificateBackup.ps1 写入独立私有仓库，再用 CertificateBackupRepo 只记录链接。

## 独立证书备份

```powershell
.\tools\backup\Invoke-NgfDevEcoCertificateBackup.ps1 `
  -SourcePath $env:USERPROFILE\.ohos\config `
  -CertificateRepo F:\DevEcoStudioProject\NGF-devtools-certificates `
  -Push
```

证书仓库必须是独立的 Gitea 私有仓库。NGF 完整备份只保存证书仓库的 remote、commit 和路径链接，不复制证书内容。

## 恢复完整备份

先恢复到隔离目录：

    .\tools\backup\Restore-NgfPrivateBackup.ps1 -BackupRepo F:\DevEcoStudioProject\NGF-private-backup -Destination F:\DevEcoStudioProject\NGF.restore-check

确认无误后，才对正式工作区使用 -Force。恢复脚本不会把私有备份内容推送到 GitHub。

## 安全边界

- 不要在公开仓库提交 local.properties、证书、密钥或真实签名口令。
- Gitea 私有权限不是唯一保护；证书和密钥建议在进入 Gitea 前使用 age、SOPS 或等价方式加密。
- 公开仓库中如果曾经出现过签名材料，应先轮换材料，再建立新的私有备份。
- 备份仓库的 current/ 目录使用 git add -f 纳入，从而不会被源目录自己的 .gitignore 漏掉。
- 默认模式包含所有 HAP/HAR 配置文件和证书，但排除各模块的 build、.cxx、.hvigor 目录；需要保留编译产物时使用 -IncludeGenerated。
- backup-manifest.json 会记录被排除的生成目录、证书存在性和 HAP/HAR 编译产物存在性。
