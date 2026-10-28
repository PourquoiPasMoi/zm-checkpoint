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
while($true){
 Start-Sleep -Milliseconds 500
 if(($null -eq $worker -or $worker.HasExited) -and ($pendingInstall -or $pendingCheck)){
  $install=$pendingInstall
  $pendingInstall=$false
  $pendingCheck=$false
  try{
   if($install){ & $statusScript -State installing }else{ & $statusScript -State checking }
   $args=@('-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File',('"'+$updater+'"'))
   if($install){$args+='-InstallLatest'}
   $worker=Start-Process -FilePath 'powershell.exe' -ArgumentList $args -WindowStyle Hidden -PassThru
  }catch{
   & $statusScript -State error -ErrorMessage $_.Exception.Message
  }
 }
 if(-not(Test-Path $log)){continue}
 $file=Get-Item $log
 if($file.Length -lt $position){$position=0}
 if($file.Length -eq $position){continue}
 $stream=[IO.File]::Open($log,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
 try{
  $stream.Seek($position,[IO.SeekOrigin]::Begin)|Out-Null
  $reader=[IO.StreamReader]::new($stream)
  $chunk=$reader.ReadToEnd()
  $position=$stream.Position
  $reader.Dispose()
 }finally{ $stream.Dispose() }
 if($chunk.ToLowerInvariant().Contains($marker)){
  $pendingCheck=$true
  if(-not $pendingInstall){ & $statusScript -State checking }
 }
 if($chunk.ToLowerInvariant().Contains($installMarker)){
  $pendingInstall=$true
  $pendingCheck=$false
  & $statusScript -State installing
 }
}
