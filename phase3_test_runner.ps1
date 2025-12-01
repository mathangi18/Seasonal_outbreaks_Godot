<#
Phase-3 Master Test Runner
- Single-run script to:
  1) make a single timestamped snapshot (only one kept)
  2) run Godot in-headless AutoTests (best-effort command)
  3) run Playwright HTML5 runtime tests (if present)
  4) run asset validation (ffmpeg / ImageMagick) checks
  5) gather logs, screenshots, exit codes into LogsDir
- Edit $ProjectRoot if you prefer the other project.godot path.
#>

# --- CONFIG ---
$ProjectRoot = "D:\SO_FAST_BACKUP_20251125_182824"   # chosen default; change if you want the archived support folder
$GodotExe = "D:\Godot\Godot.exe"                    # per your model context - adjust if different
$LogsDir = "D:\seasonal_outbreaks_logs\TestPhase"
$RollbackDir = "D:\seasonal_outbreaks_logs\rollback"
$Timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$SnapshotPath = Join-Path $RollbackDir "snapshot_$Timestamp"
$SingleBackupMarker = Join-Path $RollbackDir "current_snapshot.txt"
$RunReport = Join-Path $LogsDir "run_report_$Timestamp.txt"

# Make dirs
New-Item -Path $LogsDir -ItemType Directory -Force | Out-Null
New-Item -Path $RollbackDir -ItemType Directory -Force | Out-Null

# --- Single timestamped snapshot (keep exactly one) ---
Write-Output "=== PHASE-3: Creating single timestamped snapshot ===" | Tee-Object -FilePath $RunReport -Append
# Remove previous snapshot(s)
Get-ChildItem -Path $RollbackDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'snapshot_*' } | ForEach-Object {
    Write-Output "Removing old snapshot: $($_.FullName)" | Tee-Object -FilePath $RunReport -Append
    Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
}
# Create new snapshot (safe copy)
Write-Output "Copying $ProjectRoot -> $SnapshotPath (this may take time)" | Tee-Object -FilePath $RunReport -Append
Try {
    Copy-Item -Path $ProjectRoot -Destination $SnapshotPath -Recurse -Force -ErrorAction Stop
    Set-Content -Path $SingleBackupMarker -Value $SnapshotPath
    Write-Output "Snapshot created: $SnapshotPath" | Tee-Object -FilePath $RunReport -Append
} Catch {
    Write-Output "ERROR: Snapshot failed: $($_.Exception.Message)" | Tee-Object -FilePath $RunReport -Append
    exit 10
}

# --- 1) Godot In-Engine Tests (headless) ---
Write-Output "`n=== RUNNING GODOT AUTOTESTS ===" | Tee-Object -FilePath $RunReport -Append
$GodotLog = Join-Path $LogsDir "godot_test_$Timestamp.log"
# Best-effort command: many projects expose an Autotest entrypoint (adjust --script path if needed).
# If your project uses a different test entrypoint, edit $GodotTestArgs accordingly.
$GodotTestArgs = "--path `"$ProjectRoot`" --no-window --quit --script `"$ProjectRoot\tests\autotest_runner.gd`""
Write-Output "Godot command: `"$GodotExe`" $GodotTestArgs" | Tee-Object -FilePath $RunReport -Append
# Run Godot if exe exists
If (Test-Path $GodotExe) {
    & $GodotExe $GodotTestArgs *> $GodotLog
    $GodotExit = $LASTEXITCODE
    Write-Output "Godot exit code: $GodotExit" | Tee-Object -FilePath $RunReport -Append
} Else {
    Write-Output "Godot executable not found at $GodotExe — skipping Godot tests." | Tee-Object -FilePath $RunReport -Append
    $GodotExit = -1
}

# --- 2) Playwright HTML5 runtime tests (optional) ---
Write-Output "`n=== RUNNING PLAYWRIGHT (if present) ===" | Tee-Object -FilePath $RunReport -Append
$PlaywrightRunner = Join-Path $ProjectRoot "tools\run_playwright_tests.ps1"
$PWLog = Join-Path $LogsDir "playwright_$Timestamp.log"

If (Test-Path $PlaywrightRunner) {
    Write-Output "Found Playwright runner: $PlaywrightRunner" | Tee-Object -FilePath $RunReport -Append
    & powershell -ExecutionPolicy Bypass -File $PlaywrightRunner *> $PWLog
    $PWExit = $LASTEXITCODE
    Write-Output "Playwright exit code: $PWExit" | Tee-Object -FilePath $RunReport -Append
} Else {
    Write-Output "No Playwright runner at $PlaywrightRunner — skipping. You can add one at tools/run_playwright_tests.ps1" | Tee-Object -FilePath $RunReport -Append
    $PWExit = -1
}

# --- 3) Asset validation (ffmpeg / ImageMagick checks, best-effort) ---
Write-Output "`n=== ASSET VALIDATION: IMAGES / GIF / APNG / VIDEO ===" | Tee-Object -FilePath $RunReport -Append
$AssetReport = Join-Path $LogsDir "asset_report_$Timestamp.txt"
Get-ChildItem -Path (Join-Path $ProjectRoot "assets") -Recurse -Include *.png,*.jpg,*.jpeg,*.gif,*.apng,*.mp4,*.webm -ErrorAction SilentlyContinue | ForEach-Object {
    $f = $_.FullName
    # check file readability
    Try {
        $size = $_.Length
        Add-Content -Path $AssetReport -Value "OK: $f ($size bytes)"
    } Catch {
        Add-Content -Path $AssetReport -Value "ERROR: cannot read $f - $($_.Exception.Message)"
    }
}
Write-Output "Asset scan written to $AssetReport" | Tee-Object -FilePath $RunReport -Append

# Optional: ffmpeg / magick checks - only if tools exist
If (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
    Add-Content -Path $AssetReport -Value "`nFFMPEG checks:"
    Get-ChildItem -Path (Join-Path $ProjectRoot "assets") -Recurse -Include *.mp4,*.webm -ErrorAction SilentlyContinue | ForEach-Object {
        $f = $_.FullName
        & ffmpeg -v error -i $f -f null - 2>> $AssetReport
        If ($LASTEXITCODE -eq 0) { Add-Content $AssetReport "FFMPEG OK: $f" } Else { Add-Content $AssetReport "FFMPEG ERR: $f" }
    }
} Else {
    Add-Content -Path $AssetReport -Value "`nffmpeg not found — skipping video validation."
}

If (Get-Command magick -ErrorAction SilentlyContinue) {
    Add-Content -Path $AssetReport -Value "`nImageMagick checks:"
    Get-ChildItem -Path (Join-Path $ProjectRoot "assets") -Recurse -Include *.png,*.gif,*.apng -ErrorAction SilentlyContinue | ForEach-Object {
        $f = $_.FullName
        & magick identify -format "%w x %h %m\n" $f >> $AssetReport 2>&1
        If ($LASTEXITCODE -eq 0) { Add-Content $AssetReport "IMAGICK OK: $f" } Else { Add-Content $AssetReport "IMAGICK ERR: $f" }
    }
} Else {
    Add-Content -Path $AssetReport -Value "`nImageMagick not found — skipping image validation."
}

# --- Finalize report and exit code aggregation ---
Write-Output "`n=== SUMMARY ===" | Tee-Object -FilePath $RunReport -Append
Write-Output "ProjectRoot: $ProjectRoot" | Tee-Object -FilePath $RunReport -Append
Write-Output "Snapshot: $SnapshotPath" | Tee-Object -FilePath $RunReport -Append
Write-Output "Godot exit: $GodotExit" | Tee-Object -FilePath $RunReport -Append
Write-Output "Playwright exit: $PWExit" | Tee-Object -FilePath $RunReport -Append
Write-Output "Asset report: $AssetReport" | Tee-Object -FilePath $RunReport -Append

# Exit with non-zero if any real tests failed (leave -1/skipped states alone)
If ($GodotExit -gt 0 -or $PWExit -gt 0) {
    Write-Output "One or more tests failed. See $RunReport" | Tee-Object -FilePath $RunReport -Append
    exit 20
} Else {
    Write-Output "All run steps completed (some may be skipped). See $RunReport" | Tee-Object -FilePath $RunReport -Append
    exit 0
}
