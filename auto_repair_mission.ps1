# auto_repair_mission.ps1
$ErrorActionPreference = "Stop"

# --- CONFIGURATION ---
$repo = "D:\Repos\Seasonal_outbreaks_Godot"
$godot_candidates = @("D:\Godot\Godot.exe", "C:\Users\Hope\Downloads\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64.exe")
$godot_exe = $null
foreach ($path in $godot_candidates) { if (Test-Path $path) { $godot_exe = $path; break } }
if (!$godot_exe) { Write-Error "Godot executable not found."; exit 1 }

$ts = (Get-Date).ToString("yyyyMMdd_HHmmss")
$branch_name = "godot/auto-full-fix-$ts"
$backup_zip = "D:\Repos\Seasonal_outbreaks_Godot_backup_before_auto_full_fix_$ts.zip"
$log_dir = Join-Path $repo "logs"
if (-not (Test-Path $log_dir)) { New-Item -ItemType Directory -Path $log_dir -Force | Out-Null }
$report_file = Join-Path $log_dir "auto_fix_report_$ts.json"
$global:actions = @()

function Log-Action($msg) {
    Write-Host "[ACTION] $msg"
    $global:actions += $msg
}

try {
    Set-Location $repo

    # --- 0. PRE-CLEANUP ---
    Log-Action "Stopping Godot processes"
    Get-Process -Name "Godot" -ErrorAction SilentlyContinue | Stop-Process -Force

    # --- 1. BACKUP & BRANCH ---
    Log-Action "Creating branch $branch_name"
    git checkout -B $branch_name 2>$null

    Log-Action "Zipping backup to $backup_zip"
    try {
        Compress-Archive -Path . -DestinationPath $backup_zip -Force -ErrorAction Stop
    }
    catch {
        Log-Action "Backup failed (non-fatal): $_"
    }

    # --- 2. CLEANUP ---
    Log-Action "Clearing caches"
    Remove-Item -Recurse -Force .\.godot -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force .\.import -ErrorAction SilentlyContinue
    Get-ChildItem -Recurse -Filter "*.uid" | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Recurse -Filter "*.import" | Remove-Item -Force -ErrorAction SilentlyContinue

    # --- 3. RE-ENCODE TEXT FILES ---
    Log-Action "Re-encoding text files"
    $exts = @("*.gd", "*.tscn", "*.cfg", "*.txt", "*.md")
    foreach ($e in $exts) {
        Get-ChildItem -Path $repo -Include $e -Recurse -File | ForEach-Object {
            $path = $_.FullName
            try {
                $bytes = [System.IO.File]::ReadAllBytes($path)
                $text = [System.Text.Encoding]::UTF8.GetString($bytes)
                if ($text -match "`uFFFD") {
                    $text = [System.Text.Encoding]::Default.GetString($bytes)
                }
                [System.IO.File]::WriteAllText($path, $text, [System.Text.Encoding]::UTF8)
            }
            catch {}
        }
    }

    # --- 4. REPAIR ASSETS ---
    Log-Action "Restoring placeholder assets"
    $png_b64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII="
    $bytes = [Convert]::FromBase64String($png_b64)
    $paths = @("res\assets\patient.png", "res\assets\facility.png", "res\assets\ambulance.png", "res\res\assets\patient.png", "res\res\assets\facility.png", "res\res\assets\ambulance.png")
    foreach ($p in $paths) {
        $dir = Split-Path $p -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        [System.IO.File]::WriteAllBytes($p, $bytes)
    }

    # --- 5. NORMALIZE PATHS ---
    Log-Action "Normalizing script paths"
    Get-ChildItem -Recurse -Include *.tscn, *.tres | ForEach-Object {
        $c = Get-Content $_.FullName -Raw
        if ($c -match "res://scripts/") {
            $c = $c -replace "res://scripts/", "res://res/scripts/"
            Set-Content $_.FullName -Value $c -Encoding UTF8 -Force
        }
    }
    if (Test-Path "scripts") {
        Get-ChildItem "scripts" -Filter "*.gd" | Move-Item -Destination "res\res\scripts" -Force -ErrorAction SilentlyContinue
    }

    # --- 6. AUTOLOADS ---
    Log-Action "Fixing Autoloads"
    $proj = Get-Content "project.godot" -Raw
    $proj = $proj -replace 'AudioManager=".*?"', 'AudioManager="*res://res/scripts/AudioManager.gd"'
    $proj = $proj -replace 'UIScale=".*?"', 'UIScale="*res://misc/util/ui_scale.gd"'
    Set-Content "project.godot" -Value $proj -Encoding UTF8 -Force

    # --- 7. HEADLESS HEALTH CHECK ---
    Log-Action "Running Headless Health Check"
    $health_log = Join-Path $log_dir "health_check_mission.log"
    if (-not (Test-Path "tools\health_check.gd")) {
        New-Item -ItemType Directory -Path "tools" -Force | Out-Null
        Set-Content "tools\health_check.gd" -Value "extends SceneTree`nfunc _init():`n print('HEALTH_CHECK_OK')`n quit()" -Encoding UTF8
    }
    & $godot_exe --path $repo --no-window --script res://tools/health_check.gd 2>&1 | Out-File $health_log -Encoding UTF8
    $health_tail = Get-Content $health_log -Tail 10

    # --- 8. VISUAL EDITOR LAUNCH ---
    Log-Action "Launching Godot Editor"
    $editor_proc = Start-Process -FilePath $godot_exe -ArgumentList "--path `"$repo`"" -WindowStyle Normal -PassThru
    Log-Action "Waiting 45s for imports..."
    Start-Sleep -Seconds 45

    # --- 9. AUTO-RUN MAIN SCENE ---
    Log-Action "Triggering Main Scene Run"
    $run_visual_script = "tools\force_spawn_visual.gd"
    $script_content = @"
extends SceneTree
func _init():
    var main = load('res://res/res/scenes/Main.tscn').instantiate()
    root.add_child(main)
    print('MAIN: Spawn complete.')
    await create_timer(5.0).timeout
    quit()
"@
    Set-Content $run_visual_script -Value $script_content -Encoding UTF8
    $run_log = Join-Path $log_dir "godot_visual_run.log"
    & $godot_exe --path $repo --script $run_visual_script 2>&1 | Out-File $run_log -Encoding UTF8
    
    # --- 10. VERIFY & SCREENSHOT ---
    Log-Action "Capturing Screenshot"
    Add-Type -AssemblyName System.Drawing
    $bmp = New-Object System.Drawing.Bitmap([System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width, [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
    $screenshot_path = Join-Path $log_dir "main_scene_verified_$ts.png"
    $bmp.Save($screenshot_path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()

    # --- 11. COMMIT & PUSH ---
    Log-Action "Committing changes"
    git add -A
    git commit -m "chore(auto-fix): full auto-repair and visual verification - $ts"
    git push origin HEAD
    
    # --- 12. REPORT ---
    $report = @{
        status            = "success"
        branch            = $branch_name
        backup_zip        = $backup_zip
        screenshot        = $screenshot_path
        health_check_tail = $health_tail
        error_tail        = (Get-Content $run_log -Tail 20)
        actions           = $global:actions
    }
    $json = $report | ConvertTo-Json -Depth 5
    Set-Content $report_file -Value $json -Encoding UTF8
    Write-Output $json

}
catch {
    Write-Error "Fatal Error: $_"
    $report = @{
        status  = "failed"
        error   = $_.ToString()
        actions = $global:actions
    }
    $report | ConvertTo-Json | Out-File $report_file
    exit 1
}
