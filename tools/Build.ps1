param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\dist\zm_checkpoint')
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputRoot = [System.IO.Path]::GetFullPath($OutputDirectory)
$distRoot = [System.IO.Path]::GetFullPath((Join-Path $projectRoot 'dist'))

if (-not $outputRoot.StartsWith($distRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Output must stay inside $distRoot"
}

New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null
$stockMaps = @('zm_transit', 'zm_nuked', 'zm_highrise', 'zm_prison', 'zm_buried', 'zm_tomb')
$sourceScript = Join-Path $projectRoot 'src\scripts\zm\zm_nuked\zm_checkpoint.gsc'
$sourceText = [System.IO.File]::ReadAllText($sourceScript)
$sourceText += [Environment]::NewLine + [System.IO.File]::ReadAllText((Join-Path $projectRoot 'src\scripts\zm\zm_checkpoint_coop.gsc'))
$sourceText += [Environment]::NewLine + [System.IO.File]::ReadAllText((Join-Path $projectRoot 'src\scripts\zm\zm_checkpoint_slots.gsc'))
$mapOnlySections = [ordered]@{
    'NUKETOWN' = 'zm_nuked'
    'TRANSIT'  = 'zm_transit'
    'BURIED'   = 'zm_buried'
}

foreach ($mapName in $stockMaps) {
    $mapScriptRoot = Join-Path $outputRoot (Join-Path 'scripts\zm' $mapName)
    New-Item -ItemType Directory -Force -Path $mapScriptRoot | Out-Null
    $destination = Join-Path $mapScriptRoot 'zm_checkpoint.gsc'

    $mapScript = $sourceText

    foreach ($sectionName in $mapOnlySections.Keys) {
        if ($mapName -eq $mapOnlySections[$sectionName]) {
            continue
        }

        $sectionPattern = "(?ms)^[ \t]*// ZMCP_${sectionName}_ONLY_BEGIN[ \t]*\r?\n.*?^[ \t]*// ZMCP_${sectionName}_ONLY_END[ \t]*\r?\n?"
        $mapScript = [System.Text.RegularExpressions.Regex]::Replace($mapScript, $sectionPattern, '')
    }

    if ($mapName -ne 'zm_nuked' -and $mapScript -match 'zm_nuked_perks') {
        throw "$mapName checkpoint build still contains a Nuketown-only external reference."
    }

    if ($mapName -ne 'zm_transit' -and $mapScript -match 'town_bunker_door') {
        throw "$mapName checkpoint build still contains a TranZit-only entity reference."
    }

    if ($mapName -ne 'zm_buried' -and $mapScript -match 'hole_breakthrough|sloth_barricade|maze_fountain_trigger|_zm_ai_sloth|zmcp_(write|restore)_buried_sloth|zm_buried_sq::') {
        throw "$mapName checkpoint build still contains a Buried-only entity reference."
    }

    [System.IO.File]::WriteAllText($destination, $mapScript, [System.Text.UTF8Encoding]::new($false))
}

Copy-Item -LiteralPath (Join-Path $projectRoot 'mod.json') -Destination (Join-Path $outputRoot 'mod.json') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'cfg\zm_checkpoint.cfg') -Destination (Join-Path $outputRoot 'zm_checkpoint.cfg') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'THIRD_PARTY_NOTICES.md') -Destination (Join-Path $outputRoot 'THIRD_PARTY_NOTICES.md') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'COOP_TEST_PLAN.md') -Destination (Join-Path $outputRoot 'COOP_TEST_PLAN.md') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'LICENSE-NOTICE.md') -Destination (Join-Path $outputRoot 'LICENSE-NOTICE.md') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'README.md') -Destination (Join-Path $outputRoot 'README.md') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'tools\Update-ZMCheckpoint.ps1') -Destination (Join-Path $outputRoot 'Update-ZMCheckpoint.ps1') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'tools\Update-ZMCheckpoint-Window.ps1') -Destination (Join-Path $outputRoot 'Update-ZMCheckpoint-Window.ps1') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'tools\Watch-ZMCheckpointUpdates.ps1') -Destination (Join-Path $outputRoot 'Watch-ZMCheckpointUpdates.ps1') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'tools\Launch-UpdateBridge.vbs') -Destination (Join-Path $outputRoot 'Launch-UpdateBridge.vbs') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'tools\Update-ZMCheckpoint-Status.ps1') -Destination (Join-Path $outputRoot 'Update-ZMCheckpoint-Status.ps1') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets\menu\mod.ff') -Destination (Join-Path $outputRoot 'mod.ff') -Force

$uiStage = Join-Path $distRoot '.zm_checkpoint_iwd'
$zipPath = Join-Path $distRoot 'zz_zm_checkpoint.zip'
$iwdPath = Join-Path $outputRoot 'zz_zm_checkpoint.iwd'

if (Test-Path -LiteralPath $uiStage) {
    Remove-Item -LiteralPath $uiStage -Recurse -Force
}

if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

if (Test-Path -LiteralPath $iwdPath) {
    Remove-Item -LiteralPath $iwdPath -Force
}

New-Item -ItemType Directory -Force -Path $uiStage | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'src\ui\ui') -Destination (Join-Path $uiStage 'ui') -Recurse -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'src\ui\ui_mp') -Destination (Join-Path $uiStage 'ui_mp') -Recurse -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'src\ui\ui\t6\menus\mainlobby.lua') -Destination (Join-Path $uiStage 'ui\t6\mainlobby.lua') -Force
Compress-Archive -Path (Join-Path $uiStage '*') -DestinationPath $zipPath -CompressionLevel Optimal
Copy-Item -LiteralPath $zipPath -Destination $iwdPath -Force
Remove-Item -LiteralPath $zipPath -Force
Remove-Item -LiteralPath $uiStage -Recurse -Force

Write-Host "Built ZM Checkpoint at $outputRoot"





