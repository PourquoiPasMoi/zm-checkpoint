param([string]$PlutoniumRoot = (Join-Path $env:LOCALAPPDATA 'Plutonium\storage\t6'), [switch]$CheckOnly, [switch]$IncludeNotes, [string]$StatusScript = '')
$ErrorActionPreference = 'Stop'
$repo = 'PourquoiPasMoi/zm-checkpoint'
$root = [IO.Path]::GetFullPath((Join-Path $PlutoniumRoot 'mods\zm_checkpoint'))
$metadata = Join-Path $root 'mod.json'
if (-not (Test-Path -LiteralPath $metadata)) { throw "ZM Checkpoint is not installed at $root" }
$current = (Get-Content -LiteralPath $metadata -Raw | ConvertFrom-Json).version
$releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases?per_page=10" -Headers @{ 'User-Agent'='ZMCheckpointUpdater'; 'Accept'='application/vnd.github+json' }
$release = $releases | Where-Object { -not $_.draft } | Select-Object -First 1
if (-not $release) { throw 'No published release found' }
$latest = $release.tag_name
if ($IncludeNotes) {
 $notesText = [string]$release.body
 if ($notesText.Length -gt 4096) { $notesText = $notesText.Substring(0, 4096) }
 Write-Output ('NOTES64|' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($notesText)))
}
$currentNumbers = [regex]::Match($current, '^([0-9]+)\.([0-9]+)\.([0-9]+)').Groups
$latestNumbers = [regex]::Match($latest, '^([0-9]+)\.([0-9]+)\.([0-9]+)').Groups
if (-not $currentNumbers[0].Success -or -not $latestNumbers[0].Success) { throw 'Invalid version format' }
$currentVersion = [version]::new([int]$currentNumbers[1].Value,[int]$currentNumbers[2].Value,[int]$currentNumbers[3].Value)
$latestVersion = [version]::new([int]$latestNumbers[1].Value,[int]$latestNumbers[2].Value,[int]$latestNumbers[3].Value)
if ($currentVersion -ge $latestVersion) { Write-Output "UP_TO_DATE|$current"; return }
if ($CheckOnly) { Write-Output "UPDATE_AVAILABLE|$current|$latest"; return }
$asset = $release.assets | Where-Object name -eq "zm_checkpoint-$latest.zip" | Select-Object -First 1
if (-not $asset) { throw "Release $latest has no matching package asset" }
if ($StatusScript) { & $StatusScript -State downloading -Version $latest -Notes $notesText }
$temp = Join-Path ([IO.Path]::GetTempPath()) "zm_checkpoint-$latest.zip"
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $temp -Headers @{ 'User-Agent'='ZMCheckpointUpdater' }
$downloadHash = (Get-FileHash -LiteralPath $temp -Algorithm SHA256).Hash.ToLowerInvariant()
if ($asset.digest -and $asset.digest -ne "sha256:$downloadHash") { throw 'Downloaded archive checksum did not match the release' }
if ($StatusScript) { & $StatusScript -State unpacking -Version $latest -Notes $notesText }
$expanded = Join-Path ([IO.Path]::GetTempPath()) "zm_checkpoint-update-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $expanded | Out-Null
Expand-Archive -LiteralPath $temp -DestinationPath $expanded -Force
$source = Join-Path $expanded 'zm_checkpoint'
if (-not (Test-Path (Join-Path $source 'mod.json'))) { $source = $expanded }
if (-not (Test-Path (Join-Path $source 'mod.json'))) { throw 'Downloaded package layout is invalid' }
if ((Get-Content (Join-Path $source 'mod.json') -Raw | ConvertFrom-Json).version -ne $latest) { throw 'Package version does not match release tag' }
if ($StatusScript) { & $StatusScript -State copying -Version $latest -Notes $notesText }
# Update only package-owned files. Preserve every scriptdata checkpoint.
foreach ($item in Get-ChildItem -LiteralPath $source -Recurse -File -Force) {
 $relative = $item.FullName.Substring($source.Length).TrimStart('\','/')
 if ($relative -match '(^|[\\/])scriptdata[\\/]' -or $item.Extension -eq '.sav') { continue }
 $target = Join-Path $root $relative
 New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
 Copy-Item -LiteralPath $item.FullName -Destination $target -Force
}
Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $expanded -Recurse -Force -ErrorAction SilentlyContinue
Write-Output "INSTALLED|$current|$latest"
