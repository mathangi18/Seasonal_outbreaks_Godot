# AutoFix_C08_C11.ps1
param(
    [string]$Timestamp = "20251130_211640"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = "D:\Repos\Seasonal_outbreaks_Godot"
$MigrationRoot = Join-Path $ProjectRoot "migration"
$MappingFile = Join-Path $MigrationRoot "bound_mappings_final.json"
$BackupFile = "$MappingFile.bak.$Timestamp"
$PatchFile = Join-Path $MigrationRoot "action_patches\applied_patch_$Timestamp.json"

Write-Host "Loading mappings from $MappingFile..."
$mappings = Get-Content $MappingFile -Raw | ConvertFrom-Json

$changes = @()
$fixedCountC08 = 0
$fixedCountC11 = 0

$assetDirs = @(
    "res\assets\lotties",
    "res\assets\svgs",
    "res\assets\sprites",
    "res\assets\sounds"
)

foreach ($entry in $mappings) {
    $originalEntry = $entry | ConvertTo-Json -Depth 10 -Compress
    $modified = $false
    $changeLog = @{
        asset   = $entry.asset
        changes = @()
    }

    # C08 Fix: Case Sensitivity
    if ($entry.asset -and $entry.asset -ne "NOT_FOUND") {
        $assetName = $entry.asset
        $found = $false
        foreach ($dir in $assetDirs) {
            $fullDir = Join-Path $ProjectRoot $dir
            $possiblePath = Join-Path $fullDir $assetName
            
            # Check if file exists (case-insensitive)
            if (Test-Path $possiblePath) {
                # Get actual casing
                $actualItem = Get-Item $possiblePath
                $actualName = $actualItem.Name
                
                if ($actualName -cne $assetName) {
                    $entry.asset = $actualName
                    $modified = $true
                    $fixedCountC08++
                    $changeLog.changes += "C08: Renamed '$assetName' to '$actualName'"
                }
                $found = $true
                break
            }
        }
    }

    # C11 Fix: res:// prefix in notes
    if ($entry.notes -match "\.(json|png|svg|ogg|apng|gif)" -and $entry.notes -notmatch "^res://") {
        # Simple heuristic: if it looks like a path, prefix it.
        # Avoid prefixing if it's just a filename description without path context, but user said "Add res:// prefixes in notes fields where asset-like paths appear."
        # I'll assume if it has an extension, it's a path.
        
        # Check if it's already an absolute path or relative path
        if ($entry.notes -notmatch "^(http|https)://") {
            $entry.notes = "res://" + $entry.notes.TrimStart("/").TrimStart("\")
            $modified = $true
            $fixedCountC11++
            $changeLog.changes += "C11: Added res:// prefix to notes"
        }
    }

    if ($modified) {
        $changes += $changeLog
    }
}

Write-Host "Fixed C08: $fixedCountC08"
Write-Host "Fixed C11: $fixedCountC11"

if ($changes.Count -gt 0) {
    Write-Host "Backing up mapping file to $BackupFile..."
    Copy-Item $MappingFile $BackupFile -Force

    Write-Host "Saving updated mappings..."
    $mappings | ConvertTo-Json -Depth 10 | Set-Content $MappingFile -Force

    Write-Host "Saving patch manifest to $PatchFile..."
    $changes | ConvertTo-Json -Depth 10 | Set-Content $PatchFile -Force
}
else {
    Write-Host "No changes needed."
    $changes | ConvertTo-Json -Depth 10 | Set-Content $PatchFile -Force
}
