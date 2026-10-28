param([switch]$InstallLatest)
$ErrorActionPreference='Stop'
$statusScript=Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'Update-ZMCheckpoint-Status.ps1'
$mutex=[System.Threading.Mutex]::new($false, 'Local\ZMCheckpointUpdater')
$hasLock=$false
try {
 $hasLock=$mutex.WaitOne([TimeSpan]::FromSeconds(120))
 if (-not $hasLock) { throw 'Another update check is still running. Please retry.' }
 $script=Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'Update-ZMCheckpoint.ps1'
 $rows=@(& $script -CheckOnly -IncludeNotes)
 $notesRow=$rows | Where-Object { $_ -like 'NOTES64|*' } | Select-Object -First 1
 $notes=''
 if ($notesRow) { $notes=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($notesRow.Substring(8))) }
 $result=($rows | Select-Object -Last 1) -split '\|'
 if ($result[0] -eq 'UP_TO_DATE') {
  $state = if ($InstallLatest) { 'installed' } else { 'up_to_date' }
  & $statusScript -State $state -Version $result[1] -Notes $notes
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
 & $statusScript -State error -ErrorMessage $_.Exception.Message
} finally {
 if ($hasLock) { $mutex.ReleaseMutex() }
 $mutex.Dispose()
}
