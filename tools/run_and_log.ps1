param (
    [string]$GodotExe = "godot",
    [string]$ProjectPath = ".",
    [string]$Mode = "scene",
    [string]$LogFile = "logs/godot_log.txt"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path "logs")) { mkdir logs | Out-Null }

Write-Host "Starting Godot Wrapper..."
Write-Host "Exe: $GodotExe"
Write-Host "Project: $ProjectPath"
Write-Host "Mode: $Mode"

$args = @("--headless", "--path", $ProjectPath)

if ($Mode -eq "scene") {
    $args += ("--script", "misc/validate_project.gd")
} elseif ($Mode -eq "mainloop") {
    $args += ("--script", "misc/validator_mainloop.gd")
} else {
    Write-Error "Unknown mode: $Mode"
    exit 1
}

Write-Host "Running: $GodotExe $args"
try {
    & $GodotExe $args *> $LogFile
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Godot exited with code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
    Write-Host "Success."
} catch {
    Write-Error "Failed to run Godot: $_"
    exit 1
}
