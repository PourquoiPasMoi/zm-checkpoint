param(
 [ValidateSet('checking','up_to_date','update_available','installing','downloading','unpacking','copying','installed','error')][string]$State,
 [string]$Version = '',
 [string]$Notes = '',
 [string]$ErrorMessage = '',
 [string]$RequestId = '',
 [string]$PlutoniumRoot = (Join-Path $env:LOCALAPPDATA 'Plutonium\storage\t6')
)
$ErrorActionPreference='Stop'
if ($Version -and $Version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+(?:-alpha)?$') { throw 'Invalid update version' }
if ($RequestId -and $RequestId -notmatch '^[0-9]{9,16}$') { throw 'Invalid update request ID' }
$main=Join-Path $PlutoniumRoot 'main'
New-Item -ItemType Directory -Path $main -Force | Out-Null
# Release bodies and exception messages are untrusted: keep dvars to short
# plain ASCII without quotes, semicolons, control characters or URLs.
function Clean-GameText([string]$Value) {
 $Value = $Value -replace 'https?://\S+', ' '
 $Value = $Value -replace '[^A-Za-z0-9 .,!?():/''-]', ' '
 return ($Value -replace '\s+', ' ').Trim()
}
$entries = [System.Collections.Generic.List[string]]::new()
foreach ($rawLine in ($Notes -split '\r?\n')) {
 $rawLine = $rawLine.Trim() -replace '^#{1,6}\s*', '' -replace '^[-*+]\s+', ''
 if (-not $rawLine) { continue }
 # Existing release descriptions are often one paragraph. Separate sentences.
 foreach ($sentence in ($rawLine -split '(?<=[.!?])\s+(?=[A-Z])')) {
  $clean = Clean-GameText $sentence
  if ($clean) { $entries.Add($clean) }
 }
}
if ($entries.Count -eq 0 -and $State -notin @('checking','error')) {
 $entries.Add('Release notes are loading. Press R to refresh.')
}
$lines = [System.Collections.Generic.List[string]]::new()
foreach ($entry in $entries) {
 $entryLines = [System.Collections.Generic.List[string]]::new()
 $current = '-'
 foreach ($word in ($entry -split ' ')) {
  if (-not $word) { continue }
  if ($word.Length -gt 34) { $word = $word.Substring(0,34) }
  $candidate = "$current $word"
  if ($candidate.Length -gt 36) {
   $entryLines.Add($current)
   $current = "  $word"
  } else { $current = $candidate }
 }
 if ($current.Trim()) { $entryLines.Add($current) }
 $used = $lines.Count % 8
 if ($used -gt 0) {
  if ($entryLines.Count -le 8 -and $entryLines.Count + 1 -gt 8 - $used) {
   while (($lines.Count % 8) -ne 0) { $lines.Add('') }
  } else { $lines.Add('') }
 }
 foreach ($wrapped in $entryLines) { $lines.Add($wrapped) }
}
if ($lines.Count -gt 64) {
 $lines = [System.Collections.Generic.List[string]]::new($lines.GetRange(0,64))
 $lines[63] = '  More on GitHub release page...'
}
$errorText = Clean-GameText $ErrorMessage
if ($errorText.Length -gt 60) { $errorText = $errorText.Substring(0,57) + '...' }
$content="set zmcp_update_state $State`r`nset zmcp_update_version $Version`r`nset zmcp_update_request_id $RequestId`r`n"
$content += "set zmcp_update_error `"$errorText`"`r`n"
$content += "set zmcp_update_note_count $($lines.Count)`r`n"
for ($i = 0; $i -lt 64; $i++) {
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
