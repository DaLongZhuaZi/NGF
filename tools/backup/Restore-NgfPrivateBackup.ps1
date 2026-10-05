[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$BackupRepo,
  [Parameter(Mandatory = $true)]
  [string]$Destination,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$backupPath = (Resolve-Path -LiteralPath $BackupRepo).Path
$destinationPath = [System.IO.Path]::GetFullPath($Destination)
$current = Join-Path $backupPath 'current'
$bundle = Join-Path $backupPath 'git-history.bundle'
$manifest = Join-Path $backupPath 'backup-manifest.json'

if (-not (Test-Path -LiteralPath $current)) { throw "Backup snapshot is missing: $current" }
if (-not (Test-Path -LiteralPath $manifest)) { throw "Backup manifest is missing: $manifest" }
if (Test-Path -LiteralPath $destinationPath) {
  if (-not $Force) { throw 'Destination exists. Review the snapshot first, then pass -Force to overwrite it.' }
  if ((Resolve-Path -LiteralPath $destinationPath).Path -eq $backupPath) { throw 'Destination cannot be the backup repository.' }
}

New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
$exclude = @(Join-Path $destinationPath '.git')
$robocopyArgs = @($current, $destinationPath, '/MIR', '/COPY:DAT', '/DCOPY:DAT', '/R:1', '/W:1', '/XJ', '/NFL', '/NDL', '/NP', '/XD') + $exclude
& robocopy @robocopyArgs
if ($LASTEXITCODE -gt 7) { throw "Restore failed with robocopy code $LASTEXITCODE." }

if ((Test-Path -LiteralPath $bundle) -and -not (Test-Path -LiteralPath (Join-Path $destinationPath '.git'))) {
  $historyClone = Join-Path ([System.IO.Path]::GetTempPath()) ('ngf-history-restore-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
  & git clone $bundle $historyClone
  if ($LASTEXITCODE -ne 0) { throw 'Failed to restore Git history bundle.' }
  Move-Item -LiteralPath (Join-Path $historyClone '.git') -Destination (Join-Path $destinationPath '.git')
  Remove-Item -LiteralPath $historyClone -Recurse -Force
}

Write-Output ('Restored snapshot to: ' + $destinationPath)
Write-Output ('Manifest: ' + (Get-Content -LiteralPath $manifest -Raw))
