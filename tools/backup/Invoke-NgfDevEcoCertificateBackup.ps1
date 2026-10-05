[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$SourcePath,
  [Parameter(Mandatory = $true)]
  [string]$CertificateRepo,
  [switch]$Push
)

$ErrorActionPreference = 'Stop'
$source = (Resolve-Path -LiteralPath $SourcePath).Path
$repoPath = [System.IO.Path]::GetFullPath($CertificateRepo)

if (-not (Test-Path -LiteralPath $source -PathType Container)) { throw "Certificate source directory is missing: $source" }
New-Item -ItemType Directory -Path $repoPath -Force | Out-Null
if (-not (Test-Path -LiteralPath (Join-Path $repoPath '.git'))) {
  & git -C $repoPath init
  if ($LASTEXITCODE -ne 0) { throw 'Failed to initialize the certificate backup repository.' }
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$current = Join-Path $repoPath 'current'
$destination = Join-Path $current (Split-Path -Leaf $source)
$manifestPath = Join-Path $repoPath 'certificate-manifest.json'

if (Test-Path -LiteralPath $current) { Remove-Item -LiteralPath $current -Recurse -Force }
$copyArgs = @($source, $destination, '/E', '/COPY:DAT', '/DCOPY:DAT', '/R:1', '/W:1', '/XJ', '/NFL', '/NDL', '/NP')
& robocopy @copyArgs
if ($LASTEXITCODE -gt 7) { throw "Certificate copy failed with robocopy code $LASTEXITCODE." }

$files = @(Get-ChildItem -LiteralPath $destination -Recurse -File -Force)
$hashes = @($files | ForEach-Object {
  $relative = $_.FullName.Substring($current.Length).TrimStart('\\')
  [ordered]@{
    path = $relative
    sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    length = $_.Length
  }
})
$manifest = [ordered]@{
  schemaVersion = 1
  createdAt = (Get-Date).ToUniversalTime().ToString('o')
  sourceName = (Split-Path -Leaf $source)
  fileCount = $files.Count
  files = $hashes
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding utf8

& git -C $repoPath add -A
& git -C $repoPath add -f -- current
& git -C $repoPath commit -m ('backup: DevEco certificates ' + $timestamp)
if ($LASTEXITCODE -ne 0) { throw 'Failed to commit the certificate backup.' }

$commit = (& git -C $repoPath rev-parse HEAD).Trim()
$remote = (& git -C $repoPath remote get-url backup 2>$null)
if ([string]::IsNullOrWhiteSpace($remote)) { $remote = (& git -C $repoPath remote get-url origin 2>$null) }
if ($Push) {
  if ([string]::IsNullOrWhiteSpace($remote)) { throw 'No Gitea remote named backup or origin is configured.' }
  if (-not [string]::IsNullOrWhiteSpace((& git -C $repoPath remote get-url backup 2>$null))) {
    & git -C $repoPath push backup HEAD:main
  } else {
    & git -C $repoPath push origin HEAD:main
  }
  if ($LASTEXITCODE -ne 0) { throw 'Failed to push the certificate backup to Gitea.' }
}

Write-Output ('Certificate repository: ' + $repoPath)
Write-Output ('Commit: ' + $commit)
Write-Output ('Remote: ' + $remote)
Write-Output ('Files: ' + $files.Count)
Write-Output ('Pushed: ' + [bool]$Push)
