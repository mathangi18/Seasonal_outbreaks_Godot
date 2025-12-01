# apply_programmatic_features.ps1
# Strict generator: reads programmatic_features.json, validates assets, writes tscn + .gd files, logs created files,
# writes missing assets to phase2_output\missing_assets.txt and aborts for that feature.
$ErrorActionPreference = "Stop"
$projectRoot = "D:\Repos\Seasonal_outbreaks_Godot"
$featuresFile = "D:\seasonal_outbreak_assets\programmatic_features.json"
$assetsFolder = Join-Path $projectRoot "project_assets\phase2"
$scenesFolder = Join-Path $projectRoot "phase2_output\scenes"
$scriptsFolder = Join-Path $projectRoot "scripts\programmatic"
$missingFile = Join-Path $projectRoot "phase2_output\missing_assets.txt"
$createdLog = Join-Path $projectRoot "phase2_output\created_files_log.txt"

foreach($d in @($scenesFolder, $scriptsFolder, (Split-Path $missingFile))) { if(-not (Test-Path $d)){ New-Item -Path $d -ItemType Directory | Out-Null } }
"" | Out-File -FilePath $missingFile -Encoding utf8
"" | Out-File -FilePath $createdLog -Encoding utf8

if(-not (Test-Path $featuresFile)){ Throw "Features file not found: $featuresFile" }

$featuresJson = Get-Content -Raw -Path $featuresFile | ConvertFrom-Json
if($featuresJson.PSObject.Properties.Name -contains "features"){ $features = $featuresJson.features } else { $features = $featuresJson }
if(-not $features){ Throw "No features found in $featuresFile" }

function SafeName($s){
    $n = $s -replace '[^A-Za-z0-9\-_\.]','_'
    return $n
}

$idx = 0
foreach($f in $features){
    if(-not $f.name){ Write-Warning "Feature missing 'name' - skipping"; continue }
    $idx++; $name = SafeName($f.name)
    $sceneName = ("scene_programmatic_{0:D2}_{1}.tscn" -f $idx, $name)
    $scriptName = ("programmatic_{0:D2}_{1}.gd" -f $idx, $name)
    $scriptPath = Join-Path $scriptsFolder $scriptName
    # write script stub (strict minimal)
    @"
extends Node2D
# Auto-generated programmatic feature: $name
func _ready():
    pass
"@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8
    Add-Content -Path $createdLog -Value ("SCRIPT|{0}" -f $scriptPath)

    # collect asset references for this feature (strict)
    $assetList = @()
    if($f.assets){ $assetList = $f.assets }
    elseif($f.asset){ $assetList = ,$f.asset }
    elseif($f.nodes -and ($f.nodes | ForEach-Object { $_.asset })){ $assetList = $f.nodes | ForEach-Object { $_.asset } }

    # validate & copy referenced assets into project_assets/phase2
    $exts = @()
    $id = 1
    $missingDetected = $false
    foreach($a in $assetList){
        if(-not $a){ continue }
        # Try to resolve absolute candidate in seasonal assets folder if given relative
        $source = $a
        if(-not (Test-Path $source)){
            $leaf = Split-Path $a -Leaf
            $candidate = Join-Path "D:\seasonal_outbreak_assets" $leaf
            if(Test-Path $candidate){ $source = $candidate }
        }
        if(-not (Test-Path $source)){
            Add-Content -Path $missingFile -Value ("MISSING_PROGRAMMATIC_ASSET`tFeature:`t{0}`tExpected:`t{1}" -f $name, $a)
            $missingDetected = $true
            Write-Output "MISSING_ASSET: $name -> $a ; logged to $missingFile"
            break
        } else {
            $leaf = Split-Path $source -Leaf
            $destName = "{0}_{1}" -f $name, $leaf
            $destRepo = Join-Path $assetsFolder $destName
            Copy-Item -LiteralPath $source -Destination $destRepo -Force
            $resPath = "res://project_assets/phase2/$destName"
            $exts += "[ext_resource path=`"$resPath`" type=`"Texture2D`" id=$id]"
            $id++
        }
    }

    if($missingDetected){ Write-Output "Feature aborted due to missing asset(s): $name"; continue }

    # write simple .tscn referencing ext_resources if present
    $tscnHeader = "[gd_scene load_steps=1 format=3]"
    $tscnBody = $tscnHeader + "`r`n"
    if($exts.Count -gt 0){ $tscnBody += ($exts -join "`r`n") + "`r`n" }
    $tscnBody += "[node name=`"$name`" type=`"Node2D`"]`r`n"
    $sprIndex = 1
    $resId = 1
    foreach($a in $assetList){
        if(-not $a){ continue }
        $sprName = "Sprite{0}" -f $sprIndex
        $tscnBody += "[node name=`"$sprName`" type=`"Sprite2D`" parent=`"$name`"]`r`n"
        $tscnBody += "texture = ExtResource( {0} )`r`n" -f $resId
        $sprIndex++; $resId++
    }
    $scenePath = Join-Path $scenesFolder $sceneName
    $tscnBody | Out-File -FilePath $scenePath -Encoding UTF8
    Add-Content -Path $createdLog -Value ("SCENE|{0}" -f $scenePath)
    Write-Output ("GEN: feature -> {0} (script:{1} scene:{2})" -f $name, $scriptPath, $scenePath)
}

Write-Output ""
Write-Output "DONE."
Write-Output ("Safety snapshot before restore: {0}" -f $safetySnapshot)
if (Test-Path $missingFile) {
  $m = (Get-Content -LiteralPath $missingFile -ErrorAction SilentlyContinue)
  if($m -and $m.Length -gt 0){ Write-Output ("Missing programmatic assets listed: {0}" -f ((Get-Content $missingFile).Count)); Write-Output ("Missing file path: {0}" -f $missingFile) } else { Write-Output "No missing programmatic assets." }
} else {
  Write-Output "No missing programmatic assets."
}
