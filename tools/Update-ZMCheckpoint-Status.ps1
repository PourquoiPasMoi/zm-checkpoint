param(
 [ValidateSet('checking','up_to_date','update_available','installing','installed','error')][string]$State,
 [string]$Version = '',
 [string]$Notes = '',
 [string]$PlutoniumRoot = (Join-Path $env:LOCALAPPDATA 'Plutonium\storage\t6')
)
$ErrorActionPreference='Stop'
if ($Version -and $Version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+(?:-alpha)?$') { throw 'Invalid update version' }
$main=Join-Path $PlutoniumRoot 'main'
New-Item -ItemType Directory -Path $main -Force | Out-Null
$content="set zmcp_update_state $State`r`nset zmcp_update_version $Version`r`n"
# GitHub release notes are untrusted text. Keep only short, plain ASCII lines
# before writing them into a game console config.
$plain = $Notes -replace 'https?://\S+', ' ' -replace '[\r\n\t]+', ' '
$plain = $plain -replace '[^A-Za-z0-9 .,!?():/''-]', ' ' -replace '\s+', ' '
$plain = $plain.Trim()
if (-not $plain -and $State -notin @('checking','error')) { $plain = 'No release notes provided.' }
$lines = [System.Collections.Generic.List[string]]::new()
$line = ''
foreach ($word in ($plain -split ' ')) {
 if (-not $word) { continue }
 if ($word.Length -gt 36) { $word = $word.Substring(0, 36) }
 $candidate = if ($line) { "$line $word" } else { $word }
 if ($candidate.Length -gt 36) {
  $lines.Add($line)
  $line = $word
 } else { $line = $candidate }
}
if ($line) { $lines.Add($line) }
if ($lines.Count -gt 11) {
 $lines = [System.Collections.Generic.List[string]]::new($lines.GetRange(0, 11))
 $lines[10] = $lines[10].Substring(0, [Math]::Min(33, $lines[10].Length)).TrimEnd(' ','.') + '...'
}
for ($i = 0; $i -lt 11; $i++) {
 $value = if ($i -lt $lines.Count) { $lines[$i] } else { '' }
 $content += "set zmcp_update_note$($i+1) `"$value`"`r`n"
}
foreach ($folder in @($main, (Join-Path $PlutoniumRoot 'mods\zm_checkpoint'))) {
 New-Item -ItemType Directory -Path $folder -Force | Out-Null
 $path=Join-Path $folder 'zmcp_update_status.cfg'
 $temp=Join-Path $folder ('zmcp_update_status_'+[guid]::NewGuid().ToString('N')+'.tmp')
 [IO.File]::WriteAllText($temp,$content,[Text.Encoding]::ASCII)
 Move-Item -LiteralPath $temp -Destination $path -Force
}
