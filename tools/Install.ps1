param(
    [string]$PlutoniumRoot = (Join-Path $env:LOCALAPPDATA 'Plutonium\storage\t6'),
    [switch]$InstallCompanionMods
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$buildScript = Join-Path $PSScriptRoot 'Build.ps1'
$packageRoot = Join-Path $projectRoot 'dist\zm_checkpoint'
$modsRoot = [System.IO.Path]::GetFullPath((Join-Path $PlutoniumRoot 'mods'))
$installRoot = [System.IO.Path]::GetFullPath((Join-Path $modsRoot 'zm_checkpoint'))

if (-not $installRoot.StartsWith($modsRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Install target must stay inside $modsRoot"
}

& $buildScript
New-Item -ItemType Directory -Force -Path $installRoot | Out-Null
Copy-Item -Path (Join-Path $packageRoot '*') -Destination $installRoot -Recurse -Force

$rawRoot = [System.IO.Path]::GetFullPath((Join-Path $PlutoniumRoot 'raw'))
$stockMaps = @('zm_transit', 'zm_nuked', 'zm_highrise', 'zm_prison', 'zm_buried', 'zm_tomb')
$sharedScriptRoots = @()

foreach ($mapName in $stockMaps) {
    $sharedScriptRoot = [System.IO.Path]::GetFullPath((Join-Path $PlutoniumRoot (Join-Path 'raw\scripts\zm' $mapName)))
    if (-not $sharedScriptRoot.StartsWith($rawRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Shared script target must stay inside $rawRoot"
    }

    New-Item -ItemType Directory -Force -Path $sharedScriptRoot | Out-Null
    Copy-Item -LiteralPath (Join-Path $packageRoot (Join-Path (Join-Path 'scripts\zm' $mapName) 'zm_checkpoint.gsc')) -Destination (Join-Path $sharedScriptRoot 'zm_checkpoint.gsc') -Force
    $sharedScriptRoots += $sharedScriptRoot
}

$companionMods = @()
if ($InstallCompanionMods) {
Get-ChildItem -LiteralPath $modsRoot -Directory | Where-Object { $_.FullName -ne $installRoot } | ForEach-Object {
    $targetRoot = [System.IO.Path]::GetFullPath($_.FullName)
    if (-not $targetRoot.StartsWith($modsRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Companion target must stay inside $modsRoot"
    }

    foreach ($mapName in $stockMaps) {
        $scriptRoot = Join-Path $targetRoot (Join-Path 'scripts\zm' $mapName)
        New-Item -ItemType Directory -Force -Path $scriptRoot | Out-Null
        Copy-Item -LiteralPath (Join-Path $packageRoot (Join-Path (Join-Path 'scripts\zm' $mapName) 'zm_checkpoint.gsc')) -Destination (Join-Path $scriptRoot 'zm_checkpoint.gsc') -Force
    }
    Copy-Item -LiteralPath (Join-Path $packageRoot 'zz_zm_checkpoint.iwd') -Destination (Join-Path $targetRoot 'zz_zm_checkpoint.iwd') -Force
    $companionMods += $_.Name
}
}

Write-Host "Installed standalone ZM Checkpoint at $installRoot"
Write-Host ('Installed shared scripts for: ' + ($stockMaps -join ', '))
if ($companionMods.Count -gt 0) {
    Write-Host ('Added the Checkpoint companion UI to: ' + ($companionMods -join ', '))
}
Write-Host 'Reload the selected mod once. SAVE & EXIT will then appear on supported stock Zombies maps.'

