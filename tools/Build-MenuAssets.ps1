param(
    [string]$LinkerPath = (Join-Path $PSScriptRoot '..\.tools\oat-v0.34.0\Linker.exe'),
    [string]$UiZonePath = 'E:\SteamLibrary\steamapps\common\Call of Duty Black Ops II\zone\all\ui_zm.ff'
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$assetRoot = Join-Path $projectRoot 'assets\menu'
$linker = (Resolve-Path -LiteralPath $LinkerPath).Path
$uiZone = (Resolve-Path -LiteralPath $UiZonePath).Path

& $linker -b $assetRoot -l $uiZone mod
if ($LASTEXITCODE -ne 0) { throw "Menu asset linker failed with exit code $LASTEXITCODE" }

$compiled = Join-Path $assetRoot 'zone_out\mod\mod.ff'
if (-not (Test-Path -LiteralPath $compiled)) { throw 'Menu asset linker did not produce mod.ff' }
Copy-Item -LiteralPath $compiled -Destination (Join-Path $assetRoot 'mod.ff') -Force
Write-Host "Built menu assets at $assetRoot\mod.ff"
