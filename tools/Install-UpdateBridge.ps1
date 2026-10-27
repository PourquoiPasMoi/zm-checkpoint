param([string]$PlutoniumRoot = (Join-Path $env:LOCALAPPDATA 'Plutonium\storage\t6'))
$ErrorActionPreference='Stop'
$mod=Join-Path $PlutoniumRoot 'mods\zm_checkpoint'
$watcher=Join-Path $mod 'Watch-ZMCheckpointUpdates.ps1'
if(-not(Test-Path -LiteralPath $watcher)){throw "Updater watcher missing: $watcher"}
$launcher=Join-Path $mod 'Launch-UpdateBridge.vbs'
if(-not(Test-Path -LiteralPath $launcher)){throw "Updater launcher missing: $launcher"}
$name='ZM Checkpoint Update Bridge'
$action=New-ScheduledTaskAction -Execute 'wscript.exe' -Argument ('"'+$launcher+'"')
$trigger=New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings=New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Seconds 0) -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger -Settings $settings -Description 'Listens for the in-game ZM Checkpoint update request in the Plutonium console log.' -Force | Out-Null
Start-ScheduledTask -TaskName $name
Write-Output 'Update bridge installed for this Windows user.'
