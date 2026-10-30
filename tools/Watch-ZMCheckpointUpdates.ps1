param([string]$PlutoniumRoot = (Join-Path $env:LOCALAPPDATA 'Plutonium\storage\t6'))
$ErrorActionPreference='Stop'
$log=Join-Path $PlutoniumRoot 'main\console_zm.log'
$updater=Join-Path $PSScriptRoot 'Update-ZMCheckpoint-Window.ps1'
$statusScript=Join-Path $PSScriptRoot 'Update-ZMCheckpoint-Status.ps1'
$marker='zmcp_update_request_20261028'
$installMarker='zmcp_update_install_20261028'
$position=if(Test-Path $log){(Get-Item $log).Length}else{0}
$worker=$null
$pendingCheck=$false
$pendingInstall=$false
$pendingCheckId=''
$pendingInstallId=''
$markerCarry=''
$lastCheckMarkerId=''
$lastInstallMarkerId=''
while($true){
 Start-Sleep -Milliseconds 500
 if(($null -eq $worker -or $worker.HasExited) -and ($pendingInstall -or $pendingCheck)){
  $install=$pendingInstall
  $requestId=if($install){$pendingInstallId}else{$pendingCheckId}
  $pendingInstall=$false
  $pendingCheck=$false
  try{
   if($install){ & $statusScript -State installing -RequestId $requestId }else{ & $statusScript -State checking -RequestId $requestId }
   $args=@('-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File',('"'+$updater+'"'))
   if($install){$args+='-InstallLatest'}
   if($requestId){$args+=@('-RequestId',$requestId)}
   $worker=Start-Process -FilePath 'powershell.exe' -ArgumentList $args -WindowStyle Hidden -PassThru
  }catch{
   & $statusScript -State error -ErrorMessage $_.Exception.Message -RequestId $requestId
  }
 }
 if(-not(Test-Path $log)){continue}
 $file=Get-Item $log
 if($file.Length -lt $position){$position=0; $markerCarry=''}
 if($file.Length -eq $position){continue}
 $stream=[IO.File]::Open($log,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
 try{
  $stream.Seek($position,[IO.SeekOrigin]::Begin)|Out-Null
  $reader=[IO.StreamReader]::new($stream)
  $chunk=$reader.ReadToEnd()
  $position=$stream.Position
  $reader.Dispose()
 }finally{ $stream.Dispose() }
 # A console write can split a request marker across two reads. Keep a small
 # overlap and deduplicate complete IDs before scheduling work.
 $scan=$markerCarry+$chunk
 $markerCarry=if($scan.Length -gt 64){$scan.Substring($scan.Length-64)}else{$scan}
 $checkMatches=[regex]::Matches($scan,"${marker}_([0-9]{9,16})(?=[^0-9])")
 if($checkMatches.Count){
  $foundId=$checkMatches[$checkMatches.Count-1].Groups[1].Value
  if($foundId -ne $lastCheckMarkerId){
   $lastCheckMarkerId=$foundId
   $pendingCheckId=$foundId
   $pendingCheck=$true
   if(-not $pendingInstall){ & $statusScript -State checking -RequestId $pendingCheckId }
  }
 }
 $installMatches=[regex]::Matches($scan,"${installMarker}_([0-9]{9,16})(?=[^0-9])")
 if($installMatches.Count){
  $foundId=$installMatches[$installMatches.Count-1].Groups[1].Value
  if($foundId -ne $lastInstallMarkerId){
   $lastInstallMarkerId=$foundId
   $pendingInstallId=$foundId
   $pendingInstall=$true
   $pendingCheck=$false
   & $statusScript -State installing -RequestId $pendingInstallId
  }
 }
}
