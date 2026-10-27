param([string]$PlutoniumRoot = (Join-Path $env:LOCALAPPDATA 'Plutonium\storage\t6'))
$ErrorActionPreference='Stop'
$log=Join-Path $PlutoniumRoot 'main\console_zm.log'
$updater=Join-Path $PSScriptRoot 'Update-ZMCheckpoint-Window.ps1'
$statusScript=Join-Path $PSScriptRoot 'Update-ZMCheckpoint-Status.ps1'
$marker='zmcp_update_request_20261028'
$position=if(Test-Path $log){(Get-Item $log).Length}else{0}
while($true){
 Start-Sleep -Milliseconds 500
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
  & $statusScript -State checking
  Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File',('"'+$updater+'"')) -WindowStyle Hidden
 }
}
