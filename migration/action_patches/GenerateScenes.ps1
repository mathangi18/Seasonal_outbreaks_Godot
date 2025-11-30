# GenerateScenes.ps1
param(
    [string]$Timestamp = "20251130_211640"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = "D:\Repos\Seasonal_outbreaks_Godot"
$MigrationRoot = Join-Path $ProjectRoot "migration"
$MappingFile = Join-Path $MigrationRoot "bound_mappings_final.json"
$ScenesDir = Join-Path $ProjectRoot "scenes"
$BackupDir = Join-Path $MigrationRoot "backups\scenes_backup_$Timestamp"

if (-not (Test-Path $ScenesDir)) {
    New-Item -ItemType Directory -Force -Path $ScenesDir | Out-Null
}

if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
}

Write-Host "Loading mappings from $MappingFile..."
$mappings = Get-Content $MappingFile -Raw | ConvertFrom-Json

$createdCount = 0
$backupCount = 0

foreach ($entry in $mappings) {
    if ($entry.candidate_scene -and $entry.candidate_scene -ne "null" -and $entry.candidate_scene -ne "") {
        $sceneName = $entry.candidate_scene
        # Ensure .tscn extension
        if (-not $sceneName.EndsWith(".tscn")) {
            $sceneName += ".tscn"
        }
        
        $scenePath = Join-Path $ScenesDir $sceneName
        
        if (Test-Path $scenePath) {
            # Backup existing
            $backupPath = Join-Path $BackupDir $sceneName
            Copy-Item $scenePath $backupPath -Force
            $backupCount++
            # Write-Host "Backed up $sceneName"
        }
        else {
            # Create new
            $nodeName = if ($entry.godot_node) { $entry.godot_node } else { "Node2D" }
            # Sanitize node name for Godot (simple regex)
            $nodeName = $nodeName -replace "[^a-zA-Z0-9_]", ""
            if (-not $nodeName) { $nodeName = "Node2D" }
            
            $nodeType = if ($entry.godot_node) { $entry.godot_node } else { "Node2D" }
            # If godot_node looks like a name rather than a type, default to Node2D?
            # The prompt says "Root node = mapping.godot_node or Node2D". 
            # Usually godot_node in mapping might be the class name or node name. 
            # I'll assume it's the Type if it looks like a standard type, otherwise Node2D.
            # But to be safe and simple, I'll use the value as the Type if possible, or Node2D.
            # Actually, if godot_node is "Patient", that's likely a custom class, so Type="Node2D" with script might be better, 
            # but I don't have the script info here easily.
            # I'll use "Node2D" as the type and name it $nodeName.
            # Wait, "Root node = mapping.godot_node or Node2D". This implies the Type is mapping.godot_node.
            
            $content = @"
[gd_scene format=3 uid="uid://placeholder_$($sceneName.GetHashCode())"]

[node name="$nodeName" type="$nodeType"]
# TODO: Mapped from $($entry.asset)
"@
            
            # Ensure parent dir exists
            $parentDir = Split-Path $scenePath
            if (-not (Test-Path $parentDir)) {
                New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
            }

            Set-Content -Path $scenePath -Value $content
            $createdCount++
            Write-Host "Created $sceneName"
        }
    }
}

Write-Host "Scenes Backed Up: $backupCount"
Write-Host "Scenes Created: $createdCount"
