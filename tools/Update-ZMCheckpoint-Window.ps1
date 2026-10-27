param([switch]$InstallLatest)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework
$statusScript=Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'Update-ZMCheckpoint-Status.ps1'
try {
 $script=Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'Update-ZMCheckpoint.ps1'
 $rows=@(& $script -CheckOnly)
 $result=($rows | Select-Object -Last 1) -split '\|'
 if ($result[0] -eq 'UP_TO_DATE') {
  & $statusScript -State up_to_date -Version $result[1]
  return
 }
 if ($result[0] -ne 'UPDATE_AVAILABLE') { throw "Unexpected update result: $($rows -join ' ')" }
 & $statusScript -State update_available -Version $result[2]
 if (-not $InstallLatest) {
  $answer=[System.Windows.MessageBox]::Show("Version $($result[2]) is available. Download and install it now?",'ZM Checkpoint Update','YesNo','Question')
  if ($answer -ne 'Yes') { return }
 }
 $done=@(& $script)
 $entry=($done | Select-Object -Last 1) -split '\|'
 if ($entry[0] -ne 'INSTALLED') { throw "Unexpected install result: $($done -join ' ')" }
 & $statusScript -State installed -Version $entry[2]
 [System.Windows.MessageBox]::Show("ZM Checkpoint $($entry[2]) is installed. Unload and reload the mod from Plutonium's Mods menu when ready.",'ZM Checkpoint Update','OK','Information') | Out-Null
} catch {
 & $statusScript -State error
}
