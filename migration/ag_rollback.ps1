# AG Rollback Script
# Deletes created files during this session

$files = @(
    "D:\Repos\Seasonal_outbreaks_Godot\migration\ag_run_log.txt",
    "D:\Repos\Seasonal_outbreaks_Godot\migration\ag_wipe_log.txt",
    "D:\Repos\Seasonal_outbreaks_Godot\migration\scene_validation.json",
    "D:\Repos\Seasonal_outbreaks_Godot\migration\ag_plan.json",
    "D:\Repos\Seasonal_outbreaks_Godot\migration\ag_plan_human.md",
    "D:\Repos\Seasonal_outbreaks_Godot\migration\ag_summary.txt",
    "D:\Repos\Seasonal_outbreaks_Godot\migration\block_05_processor.ps1",
    "D:\Repos\Seasonal_outbreaks_Godot\scenes\CameraWrapper.tscn",
    "D:\Repos\Seasonal_outbreaks_Godot\scripts\visual_camera.gd"
)

$unboundDir = "D:\Repos\Seasonal_outbreaks_Godot\scenes\unbound"

foreach ($f in $files) {
    if (Test-Path $f) {
        Remove-Item -Force $f
        Write-Output "Deleted: $f"
    }
}

if (Test-Path $unboundDir) {
    Remove-Item -Recurse -Force $unboundDir
    Write-Output "Deleted: $unboundDir"
}

Write-Output "Rollback Complete."
