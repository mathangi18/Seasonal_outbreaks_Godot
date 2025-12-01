<#
Guarded generator:
- Requires a real FEATURES_GODOT_FULL.txt (checked via ensure_real_features.ps1)
- Requires tools\phase2\assets_to_features_map.json to map features -> asset paths
- Aborts (no writes) if any feature lacks a mapped, existing asset
- Produces final scenes under phase2_output\scenes and copies assets deterministically
#>
param(
  [string]$Repo = "D:\Repos\Seasonal_outbreaks_Godot",
  [string]$FeaturesRel = "tools\references\FEATURES_GODOT_FULL.txt",
  [string]$MapRel = "tools\phase2\assets_to_features_map.json",
  [string]$OutRel = "phase2_output\scenes"
)

$featuresPath = Join-Path $Repo $FeaturesRel
$mapPath = Join-Path $Repo $MapRel
$outScenes = Join-Path $Repo $OutRel
$outAssets = Join-Path $outScenes "assets"
New-Item -ItemType Directory -Force -Path $outScenes, $outAssets | Out-Null

# 0) run placeholder check
$checker = Join-Path $Repo "tools\phase2\ensure_real_features.ps1"
& powershell -NoProfile -ExecutionPolicy Bypass -File $checker -Repo $Repo -FeaturesRel $FeaturesRel
if ($LASTEXITCODE -ne 0) { Write-Error "Refusing to run: FEATURES file failed placeholder checks."; exit 4 }

if (-not (Test-Path $mapPath)) { Write-Error "Assets map not found: $mapPath"; exit 5 }
$mapJson = Get-Content $mapPath -Raw | ConvertFrom-Json

$features = Get-Content $featuresPath | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not($_ -match "^\s*#") }

# Build mapping: for each feature, find first existing asset (expand under D:\seasonal_outbreak_assets if needed)
$missing = @()
$resolved = @{}
foreach ($f in $features) {
  $found = $null
  if ($mapJson.PSObject.Properties.Name -contains $f) {
    $cands = $mapJson.$f
    foreach ($c in $cands) {
      $abs = $c
      if (-not (Test-Path $abs)) {
        $try = Join-Path "D:\seasonal_outbreak_assets" $c
        if (Test-Path $try) { $abs = $try }
      }
      if (Test-Path $abs) { $found = $abs; break }
    }
  }
  if (-not $found) { $missing += $f } else { $resolved[$f] = $found }
}

if ($missing.Count -gt 0) {
  Write-Error "Aborting: the following features have NO mapped existing asset paths:`n$($missing -join "`n")"
  exit 6
}

# All features have mapped assets -> generate scenes
$time = (Get-Date).ToString("yyyyMMdd_HHmmss")
$i=1
foreach ($f in $features) {
  $safeFeature = ($f -replace "[^A-Za-z0-9\-_]","_") -replace "_+","_"
  $safeFeature = $safeFeature.Trim("_")
  if ([string]::IsNullOrWhiteSpace($safeFeature)) { $safeFeature = "feature_unknown" }
  $sceneName = "scene_$('{0:D3}' -f $i)_$safeFeature"
  $sceneFile = Join-Path $outScenes ($sceneName + ".tscn")

  $assetSrc = $resolved[$f]
  $ext = [IO.Path]::GetExtension($assetSrc)
  $assetDest = Join-Path $outAssets ($sceneName + $ext)

  Copy-Item -Path $assetSrc -Destination $assetDest -Force
  (Get-Item $assetDest).Attributes = "Normal"

  $rel = "assets/" + ($sceneName + $ext)
  $tscn = @"
[gd_scene load_steps=2 format=3]
[ext_resource path=""$rel"" type=""Texture"" id=1]
[node name=""Root"" type=""Node2D""]
node_name = ""$sceneName""
# Feature: $f
# Generated: $time
[node name=""Sprite"" type=""Sprite"" parent=""Root""]
texture = ExtResource( 1 )
"@
  $tmp = $sceneFile + ".tmp"
  $tscn | Set-Content -LiteralPath $tmp -Encoding UTF8
  if (Test-Path $sceneFile) { Remove-Item -LiteralPath $sceneFile -Force }
  Move-Item -Path $tmp -Destination $sceneFile -Force
  (Get-Item $sceneFile).Attributes = "Normal"

  Write-Output "WROTE: $sceneFile  -> asset: $rel"
  $i++
}

Write-Output "SUCCESS: Generated $($i-1) scenes under $outScenes"
exit 0
