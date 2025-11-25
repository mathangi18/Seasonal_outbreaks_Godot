# ===== CLEAN, CORRECTED, STABLE CLEANUP SCRIPT =====

param(
    [switch]$Execute
)

$RepoRoot    = 'D:\Repos\Seasonal_outbreaks_Godot'
$TrashRoot   = "D:\SO_TRASH_BACKUP_$((Get-Date).ToString('yyyyMMdd_HHmmss'))"
$SnapshotDir = "D:\SO_QUICK_SNAPSHOT_$((Get-Date).ToString('yyyyMMdd_HHmmss'))"
$ReportFile  = Join-Path $RepoRoot ("so_health_report_$((Get-Date).ToString('yyyyMMdd_HHmmss')).txt")

$Patterns = @(
    '*.ctex',
    '*.md5',
    'shader_cache',
    'godot_temp',
    'logs',
    'removed_backup_*',
    '.ag_work',
    '.openagent',
    '.open-agent',
    'Godot.exe.broken_*'
)

# SAFE DIR LIST — no arrays-with-commas
$ExplicitDirs = @(
    "$RepoRoot\.godot\imported",
    "$RepoRoot\.godot\shader_cache",
    "$RepoRoot\godot_temp",
    "$RepoRoot\logs",
    "$RepoRoot\.ag_work",
    "$RepoRoot\removed_backup_*",
    "$RepoRoot\Godot.exe.broken_*"
)

if (-not (Test-Path $RepoRoot)) {
    Write-Host "Error: Repo root missing!" -ForegroundColor Red
    exit 1
}

if ($Execute) {
    New-Item -ItemType Directory -Path $TrashRoot -Force | Out-Null
    Write-Host "EXECUTE MODE → trash folder: $TrashRoot"
} else {
    Write-Host "PREVIEW MODE → nothing will be moved."
    Write-Host "Planned trash folder: $TrashRoot"
}

function Move-Safe {
    param($src)
    $rel = $src.Substring($RepoRoot.Length).TrimStart('\','/')
    $dst = Join-Path $TrashRoot $rel

    if ($Execute) {
        $dstDir = Split-Path $dst -Parent
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
        Move-Item -LiteralPath $src -Destination $dst -Force -Verbose
    } else {
        Write-Host "WHATIF → $src  →  $dst"
    }
}

foreach ($p in $Patterns) {
    Write-Host "Scanning pattern: $p"
    $items = Get-ChildItem -Path $RepoRoot -Recurse -Force -Include $p -ErrorAction SilentlyContinue
    foreach ($it in $items) { Move-Safe $it.FullName }
}

foreach ($dir in $ExplicitDirs) {
    $match = Get-ChildItem -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
    foreach ($it in $match) { Move-Safe $it.FullName }
}

$report = @()
$report += "CLEANUP REPORT - $(Get-Date)"
$report += "Mode: $($Execute ? 'EXECUTE' : 'PREVIEW')"
$report += "Trash folder: $TrashRoot"
$report += ""
$report += "Remaining top-level items:"
Get-ChildItem -Path $RepoRoot -Force -Directory | ForEach-Object { $report += "  - $($_.Name)" }

$report | Set-Content -Path $ReportFile -Encoding UTF8
Write-Host "`nReport saved to: $ReportFile"
