param([switch]$InstallLatest, [string]$RequestId = '')
$ErrorActionPreference='Stop'
$statusScript=Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'Update-ZMCheckpoint-Status.ps1'
# An older bridge process may remain running after the mod updates. It starts
# this newer worker without -RequestId; recover the ID from the console marker.
if (-not $RequestId) {
 $log=Join-Path $env:LOCALAPPDATA 'Plutonium\storage\t6\main\console_zm.log'
 if (Test-Path -LiteralPath $log) {
  $kind=if($InstallLatest){'install'}else{'request'}
  $tail=Get-Content -LiteralPath $log -Tail 1000 -ErrorAction SilentlyContinue
  $requestMatches=[regex]::Matches(($tail -join "`n"), "zmcp_update_${kind}_20261028_([0-9]{9,16})")
  if ($requestMatches.Count) { $RequestId=$requestMatches[$requestMatches.Count-1].Groups[1].Value }
 }
}
$mutex=[System.Threading.Mutex]::new($false, 'Local\ZMCheckpointUpdater')
$hasLock=$false
try {
 $hasLock=$mutex.WaitOne([TimeSpan]::FromSeconds(120))
 if (-not $hasLock) { throw 'Another update check is still running. Please retry.' }
 $script=Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'Update-ZMCheckpoint.ps1'
 if ($InstallLatest) {
  & $statusScript -State installing -RequestId $RequestId
  $done=@(& $script -IncludeNotes -StatusScript $statusScript -RequestId $RequestId)
  $notesRow=$done | Where-Object { $_ -like 'NOTES64|*' } | Select-Object -First 1
  $notes=''
  if ($notesRow) { $notes=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($notesRow.Substring(8))) }
  $entry=($done | Select-Object -Last 1) -split '\|'
  if ($entry[0] -eq 'INSTALLED') { $version=$entry[2] }
  elseif ($entry[0] -eq 'UP_TO_DATE') { $version=$entry[1] }
  else { throw "Unexpected install result: $($done -join ' ')" }
  & $statusScript -State installed -Version $version -Notes $notes -RequestId $RequestId
  return
 }
 $rows=@(& $script -CheckOnly -IncludeNotes)
 $notesRow=$rows | Where-Object { $_ -like 'NOTES64|*' } | Select-Object -First 1
 $notes=''
 if ($notesRow) { $notes=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($notesRow.Substring(8))) }
 $result=($rows | Select-Object -Last 1) -split '\|'
 if ($result[0] -eq 'UP_TO_DATE') {
  $state = if ($InstallLatest) { 'installed' } else { 'up_to_date' }
  & $statusScript -State $state -Version $result[1] -Notes $notes -RequestId $RequestId
  return
 }
 if ($result[0] -ne 'UPDATE_AVAILABLE') { throw "Unexpected update result: $($rows -join ' ')" }
 & $statusScript -State update_available -Version $result[2] -Notes $notes -RequestId $RequestId
} catch {
 & $statusScript -State error -ErrorMessage $_.Exception.Message -RequestId $RequestId
} finally {
 if ($hasLock) { $mutex.ReleaseMutex() }
 $mutex.Dispose()
}
