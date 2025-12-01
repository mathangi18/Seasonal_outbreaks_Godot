param(
  [string]$Repo = "D:\Repos\Seasonal_outbreaks_Godot",
  [string]$FeaturesRel = "tools\references\FEATURES_GODOT_FULL.txt"
)
$featuresPath = Join-Path $Repo $FeaturesRel
if (-not (Test-Path $featuresPath)) { Write-Error "FEATURES file missing: $featuresPath"; exit 2 }
$lines = Get-Content $featuresPath | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not($_ -match "^\s*#") }
if ($lines.Count -eq 0) { Write-Error "FEATURES file empty or only comments."; exit 2 }

# Heuristics: if any of the first 10 non-comment lines contain obvious placeholder phrases, fail.
$placeholders = @('place the real', 'placeholder', 'This repo reference was created', 'assistant-cited', 'FEATURES_GODOT_FULL file')
$bad = @()
$checkLines = $lines | Select-Object -First 10
foreach ($l in $checkLines) {
  foreach ($p in $placeholders) {
    if ($l -match [regex]::Escape($p)) { $bad += $l; break }
  }
}
if ($bad.Count -gt 0) {
  Write-Error "FEATURES file looks like a placeholder. Detected lines:`n$($bad -join "`n")"; exit 3
}
Write-Output "FEATURES file passed basic placeholder checks. Lines: $($lines.Count)"
exit 0
