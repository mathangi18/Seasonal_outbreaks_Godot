param(
    [string]$GodotExe = "D:\Godot\Godot_v4.5.1-stable_win64.exe\Godot.exe",
    [string]$ProjectPath = ".",
    [ValidateSet("scene","mainloop")] [string]$Mode = "scene",
    [int]$TailLines = 200
)

$resolved = (Resolve-Path $ProjectPath).Path
$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$logDir = Join-Path $resolved "logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$logFile = Join-Path $logDir ("godot_log_$timestamp.txt")
$historyFile = Join-Path $resolved "docs\validation_history.md"

# decide how to invoke Godot
$scenePath = "res://misc/validator.tscn"
$scriptPath = "--script misc/validate_project.gd"
$mainloopScript = "--script misc/validator_mainloop.gd"

if ($Mode -eq "scene" -and (Test-Path (Join-Path $resolved "misc\validator.tscn"))) {
    $arg = "-s " + $scenePath
    Write-Host "Using scene validator: $scenePath"
} elseif ($Mode -eq "mainloop") {
    $arg = $mainloopScript
    Write-Host "Using mainloop validator script: misc/validator_mainloop.gd"
} else {
    $arg = $scriptPath
    Write-Host "Using fallback script validator: misc/validate_project.gd"
}

Write-Host "Running: $GodotExe --headless --path $resolved $arg"
# run Godot synchronously and redirect combined output
& $GodotExe --headless --path $resolved $arg *> $logFile

if (-not (Test-Path $logFile)) {
    Write-Host "Log file missing: $logFile"
    exit 1
}

$logText = Get-Content $logFile -Raw
if ($logText -match "ERROR" -or $logText -match "Parse Error" -or $logText -match "Failed to load script") {
    $excerpt = (Get-Content $logFile -Tail $TailLines) -join "`n"
    $append = @"
---
**Failure detected:** $timestamp

Log excerpt (last $TailLines lines):
$excerpt

bash
Copy code

Screenshot evidence (if available): /mnt/data/7819575e-1adb-4e55-8f5c-7d6170e91dc9.png

"@
    Add-Content -Path $historyFile -Value $append
    Write-Host "Errors found and appended to $historyFile"
} else {
    Write-Host "No obvious errors found. Log saved to $logFile"
}
