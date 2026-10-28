param([switch]$InstallLatest)
$ErrorActionPreference='Stop'
$statusScript=Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'Update-ZMCheckpoint-Status.ps1'
try {
 $script=Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'Update-ZMCheckpoint.ps1'
 $rows=@(& $script -CheckOnly -IncludeNotes)
 $notesRow=$rows | Where-Object { $_ -like 'NOTES64|*' } | Select-Object -First 1
 $notes=''
 if ($notesRow) { $notes=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($notesRow.Substring(8))) }
 $result=($rows | Select-Object -Last 1) -split '\|'
 if ($result[0] -eq 'UP_TO_DATE') {
  & $statusScript -State up_to_date -Version $result[1] -Notes $notes
  return
 }
 if ($result[0] -ne 'UPDATE_AVAILABLE') { throw "Unexpected update result: $($rows -join ' ')" }
 if (-not $InstallLatest) {
  & $statusScript -State update_available -Version $result[2] -Notes $notes
  return
 }
 & $statusScript -State installing -Version $result[2] -Notes $notes
 $done=@(& $script)
 $entry=($done | Select-Object -Last 1) -split '\|'
 if ($entry[0] -ne 'INSTALLED') { throw "Unexpected install result: $($done -join ' ')" }
 & $statusScript -State installed -Version $entry[2] -Notes $notes
} catch {
 & $statusScript -State error
}
