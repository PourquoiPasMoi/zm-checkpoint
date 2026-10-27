param(
 [ValidateSet('checking','up_to_date','update_available','installed','error')][string]$State,
 [string]$Version = '',
 [string]$PlutoniumRoot = (Join-Path $env:LOCALAPPDATA 'Plutonium\storage\t6')
)
$ErrorActionPreference='Stop'
if ($Version -and $Version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+(?:-alpha)?$') { throw 'Invalid update version' }
$main=Join-Path $PlutoniumRoot 'main'
New-Item -ItemType Directory -Path $main -Force | Out-Null
$content="set zmcp_update_state $State`r`nset zmcp_update_version $Version`r`n"
foreach ($folder in @($main, (Join-Path $PlutoniumRoot 'mods\zm_checkpoint'))) {
 New-Item -ItemType Directory -Path $folder -Force | Out-Null
 $path=Join-Path $folder 'zmcp_update_status.cfg'
 $temp=Join-Path $folder ('zmcp_update_status_'+[guid]::NewGuid().ToString('N')+'.tmp')
 [IO.File]::WriteAllText($temp,$content,[Text.Encoding]::ASCII)
 Move-Item -LiteralPath $temp -Destination $path -Force
}
