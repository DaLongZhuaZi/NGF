[CmdletBinding()]
param(
  [string]$Root = (Join-Path $PSScriptRoot '..\..'),
  [Parameter(Mandatory = $true)]
  [string]$BackupRepo,
  [switch]$Push,
  [switch]$IncludeGenerated,
  [string[]]$AdditionalPath = @(),
  [string]$CertificateBackupRepo
)

$ErrorActionPreference = 'Stop'
$rootPath = (Resolve-Path -LiteralPath $Root).Path
$backupPath = [System.IO.Path]::GetFullPath($BackupRepo)

if (-not (Test-Path -LiteralPath (Join-Path $rootPath '.git'))) { throw "Root is not a Git worktree: $rootPath" }
if ($backupPath.TrimEnd('\') -eq $rootPath.TrimEnd('\')) { throw 'BackupRepo must be different from Root.' }
if ($backupPath.StartsWith($rootPath.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase)) { throw 'BackupRepo must be outside the NGF worktree.' }

New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
if (-not (Test-Path -LiteralPath (Join-Path $backupPath '.git'))) {
  & git -C $backupPath init
  if ($LASTEXITCODE -ne 0) { throw 'Failed to initialize the private backup repository.' }
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$staging = Join-Path ([System.IO.Path]::GetTempPath()) ('ngf-private-backup-' + $timestamp)
$current = Join-Path $backupPath 'current'
$bundle = Join-Path $backupPath 'git-history.bundle'
$manifestPath = Join-Path $backupPath 'backup-manifest.json'
New-Item -ItemType Directory -Path $staging -Force | Out-Null

try {
  $sourceCommit = (& git -C $rootPath rev-parse HEAD).Trim()
  $statusLines = @(& git -C $rootPath status --porcelain)
  $workspace = Join-Path $staging 'current'
  $exclude = @((Join-Path $rootPath '.git'))
  $excludedGeneratedPaths = @()
  if (-not $IncludeGenerated) {
    $generatedDirectoryNames = @('build', '.cxx', '.hvigor')
    $moduleRoots = @($rootPath) + @(Get-ChildItem -LiteralPath $rootPath -Directory -Force | Select-Object -ExpandProperty FullName)
    foreach ($moduleRoot in $moduleRoots) {
      foreach ($generatedDirectoryName in $generatedDirectoryNames) {
        $generatedPath = Join-Path $moduleRoot $generatedDirectoryName
        if (Test-Path -LiteralPath $generatedPath) {
          $exclude += $generatedPath
          $excludedGeneratedPaths += $generatedPath.Substring($rootPath.Length).TrimStart('\\')
        }
      }
    }
  }

  $robocopyArgs = @($rootPath, $workspace, '/E', '/COPY:DAT', '/DCOPY:DAT', '/R:1', '/W:1', '/XJ', '/NFL', '/NDL', '/NP', '/XD') + $exclude
  & robocopy @robocopyArgs
  if ($LASTEXITCODE -gt 7) { throw "Workspace snapshot failed with robocopy code $LASTEXITCODE." }

  & git -C $rootPath bundle create (Join-Path $staging 'git-history.bundle') --all
  if ($LASTEXITCODE -ne 0) { throw 'Failed to create Git history bundle.' }

  $additionalPathNames = @()
  foreach ($additionalPathValue in $AdditionalPath) {
    $additionalItem = Get-Item -LiteralPath $additionalPathValue -Force -ErrorAction Stop
    $additionalPathName = $additionalItem.Name
    $additionalPathNames += $additionalPathName
    $additionalDestination = Join-Path (Join-Path $workspace 'private-config') $additionalPathName
    if ($additionalItem.PSIsContainer) {
      $additionalCopyArgs = @($additionalItem.FullName, $additionalDestination, '/E', '/COPY:DAT', '/DCOPY:DAT', '/R:1', '/W:1', '/XJ', '/NFL', '/NDL', '/NP')
      & robocopy @additionalCopyArgs
      if ($LASTEXITCODE -gt 7) { throw "Additional path copy failed for $additionalPathValue with robocopy code $LASTEXITCODE." }
    } else {
      New-Item -ItemType Directory -Path (Split-Path -Parent $additionalDestination) -Force | Out-Null
      Copy-Item -LiteralPath $additionalItem.FullName -Destination $additionalDestination -Force
    }
  }

  $certificateBackupLink = $null
  if (-not [string]::IsNullOrWhiteSpace($CertificateBackupRepo)) {
    $certificateRepoPath = (Resolve-Path -LiteralPath $CertificateBackupRepo).Path
    $certificateCommit = (& git -C $certificateRepoPath rev-parse HEAD).Trim()
    $certificateRemote = (& git -C $certificateRepoPath remote get-url backup 2>$null)
    if ([string]::IsNullOrWhiteSpace($certificateRemote)) { $certificateRemote = (& git -C $certificateRepoPath remote get-url origin 2>$null) }
    $certificateBackupLink = [ordered]@{
      remote = $certificateRemote
      branch = 'main'
      commit = $certificateCommit
      path = 'current/config'
    }
    $linkPath = Join-Path $workspace 'private-config/certificate-backup-link.json'
    New-Item -ItemType Directory -Path (Split-Path -Parent $linkPath) -Force | Out-Null
    $certificateBackupLink | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $linkPath -Encoding utf8
  }

  $files = @(Get-ChildItem -LiteralPath $workspace -Recurse -File -Force)
  $manifest = [ordered]@{
    schemaVersion = 1
    createdAt = (Get-Date).ToUniversalTime().ToString('o')
    sourceCommit = $sourceCommit
    worktreeDirty = ($statusLines.Count -gt 0)
    dirtyEntryCount = $statusLines.Count
    includeGenerated = [bool]$IncludeGenerated
    fileCount = $files.Count
    totalBytes = [int64](($files | Measure-Object -Property Length -Sum).Sum)
    containsIgnoredFiles = $true
    additionalPathNames = $additionalPathNames
    certificateBackup = $certificateBackupLink
    excludedGeneratedPaths = $excludedGeneratedPaths
    containsCertificates = (@($files | Where-Object { $_.Extension -in @('.p12','.cer','.csr','.crt','.der','.p7b','.pem','.pfx','.key','.keystore','.jks') }).Count -gt 0)
    containsCompiledArtifacts = (@($files | Where-Object { $_.Extension -in @('.hap','.har','.hsp','.so','.abc') }).Count -gt 0)
    historyBundle = 'git-history.bundle'
  }
  $manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $staging 'backup-manifest.json') -Encoding utf8

  if (Test-Path -LiteralPath $current) { Remove-Item -LiteralPath $current -Recurse -Force }
  Copy-Item -LiteralPath $workspace -Destination $current -Recurse -Force
  Copy-Item -LiteralPath (Join-Path $staging 'git-history.bundle') -Destination $bundle -Force
  Copy-Item -LiteralPath (Join-Path $staging 'backup-manifest.json') -Destination $manifestPath -Force

  & git -C $backupPath add -A
  & git -C $backupPath add -f -- current
  if ($LASTEXITCODE -ne 0) { throw 'Failed to stage the private backup snapshot.' }
  & git -C $backupPath commit -m ('backup: NGF full workspace ' + $timestamp)
  if ($LASTEXITCODE -ne 0) { throw 'Failed to commit the private backup snapshot.' }

  if ($Push) {
    $backupRemote = (& git -C $backupPath remote get-url backup 2>$null)
    $originRemote = (& git -C $backupPath remote get-url origin 2>$null)
    if (($LASTEXITCODE -ne 0) -and [string]::IsNullOrWhiteSpace($backupRemote) -and [string]::IsNullOrWhiteSpace($originRemote)) { throw 'No Gitea remote named backup or origin is configured.' }
    if (-not [string]::IsNullOrWhiteSpace($backupRemote)) {
      & git -C $backupPath push backup HEAD:backup/full
    } else {
      & git -C $backupPath push origin HEAD:backup/full
    }
    if ($LASTEXITCODE -ne 0) { throw 'Failed to push the private backup to Gitea.' }
  }

  Write-Output ('Backup repository: ' + $backupPath)
  Write-Output ('Source commit: ' + $sourceCommit)
  Write-Output ('Files: ' + $files.Count)
  Write-Output ('Dirty worktree: ' + ($statusLines.Count -gt 0))
  Write-Output ('Pushed: ' + [bool]$Push)
} finally {
  if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
}
