# Block 05 Processor
$manifestPath = "D:\Repos\Seasonal_outbreaks_Godot\migration\asset_mappings.json"
$catalogPath = "D:\Repos\Seasonal_outbreaks_Godot\asset_catalog.json"
$validationPath = "D:\Repos\Seasonal_outbreaks_Godot\migration\scene_validation.json"
$errorsPath = "D:\Repos\Seasonal_outbreaks_Godot\migration\ag_errors.json"
$unboundDir = "D:\Repos\Seasonal_outbreaks_Godot\scenes\unbound"

# 1. Load Manifest
if (-not (Test-Path $manifestPath)) {
    Write-Error "Manifest missing!"
    exit 1
}
$manifest = Get-Content $manifestPath | ConvertFrom-Json

# 2. Verify Assets & Create Placeholders
if (-not (Test-Path $unboundDir)) {
    New-Item -ItemType Directory -Force -Path $unboundDir | Out-Null
}

$missingAssets = @()
foreach ($item in $manifest) {
    $path = $item.new_path
    if (-not (Test-Path -LiteralPath $path)) {
        $missingAssets += $path
    } else {
        # Create placeholder scene
        $name = [System.IO.Path]::GetFileNameWithoutExtension($path)
        $ext = [System.IO.Path]::GetExtension($path)
        $scenePath = Join-Path $unboundDir "$name.tscn"
        
        # Simple template based on type
        $content = ""
        $relPath = $path.Replace("D:\Repos\Seasonal_outbreaks_Godot\", "res://").Replace("\", "/")
        
        if ($ext -match "\.png|\.jpg|\.svg") {
            $content = "[gd_scene load_steps=2 format=3]`n`n[ext_resource type=`"Texture2D`" path=`"$relPath`" id=`"1_tex`"]`n`n[node name=`"$name`" type=`"Sprite2D`"]`ntexture = ExtResource(`"1_tex`")"
        } elseif ($ext -match "\.ogg|\.wav") {
            $content = "[gd_scene load_steps=2 format=3]`n`n[ext_resource type=`"AudioStream`" path=`"$relPath`" id=`"1_aud`"]`n`n[node name=`"$name`" type=`"AudioStreamPlayer`"]`nstream = ExtResource(`"1_aud`")"
        } else {
            # Generic Node
            $content = "[gd_scene format=3]`n`n[node name=`"$name`" type=`"Node`"]"
        }
        
        if (-not (Test-Path $scenePath)) {
            Set-Content -Path $scenePath -Value $content -Encoding UTF8
        }
    }
}

if ($missingAssets.Count -gt 0) {
    $errorJson = @{
        error = "Missing Assets"
        missing_paths = $missingAssets
        remediation = "Restore missing assets to their paths."
    } | ConvertTo-Json
    Set-Content -Path $errorsPath -Value $errorJson
    Write-Output "ABORT_MISSING_ASSETS"
    exit 1
}

# 3. Headless Validation (Text Parse Fallback)
$scenes = Get-ChildItem -Path "D:\Repos\Seasonal_outbreaks_Godot\scenes" -Recurse -Filter "*.tscn"
$validationResults = @()

foreach ($scene in $scenes) {
    $content = Get-Content $scene.FullName
    $missingRes = @()
    $status = "ok"
    
    # Regex to find ext_resource path="..."
    $matches = [regex]::Matches($content, 'path="res://([^"]+)"')
    foreach ($m in $matches) {
        $rel = $m.Groups[1].Value
        $abs = Join-Path "D:\Repos\Seasonal_outbreaks_Godot" $rel
        if (-not (Test-Path $abs)) {
            $missingRes += "res://$rel"
            $status = "error"
        }
    }
    
    $validationResults += @{
        scene = $scene.Name
        load_status = $status
        missing_resources = $missingRes
        node_issues = @()
    }
}

$validationResults | ConvertTo-Json -Depth 4 | Set-Content -Path $validationPath
Write-Output "VALIDATION_COMPLETE"
