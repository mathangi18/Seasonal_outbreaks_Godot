<#
run_full_ci.ps1
Comprehensive non-interactive test runner for Seasonal_outbreaks_Godot TEST PHASE.
Usage:
  powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run_full_ci.ps1 -Repo "D:\Repos\Seasonal_outbreaks_Godot" -GodotExe "D:\Godot\Godot_v4.5.1-stable_win64_console.exe" -AutoApplyPatches
#>

param(
  [string]$Repo = "D:\Repos\Seasonal_outbreaks_Godot",
  [string]$GodotExe = "D:\Godot\Godot_v4.5.1-stable_win64_console.exe",
  [switch]$AutoApplyPatches,
  [switch]$SkipPlaywright,
  [string]$ReportsFolder = ""
)

function Write-Stage { param($s) Write-Host "`n==== $s ====" -ForegroundColor Cyan }
function FailExit($msg){ Write-Host $msg -ForegroundColor Red; exit 1 }

# Prepare paths
if(-not (Test-Path $Repo)){ FailExit "Repo path not found: $Repo" }
$toolDir = Join-Path $Repo "tools"
if(-not (Test-Path $toolDir)){ New-Item -ItemType Directory -Force -Path $toolDir | Out-Null }

if([string]::IsNullOrWhiteSpace($ReportsFolder)){
  $ReportsFolder = Join-Path $Repo "migration\action_patches\test_reports"
}
New-Item -ItemType Directory -Force -Path $ReportsFolder | Out-Null

$stamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$runFolder = Join-Path $ReportsFolder "ci_run_$stamp"
New-Item -ItemType Directory -Force -Path $runFolder | Out-Null

# Create fallback scene load tester if missing (Godot 4 style)
$sceneTester = Join-Path $toolDir "scene_load_tester.gd"
if(-not (Test-Path $sceneTester)){
  Write-Host "Writing fallback scene_load_tester.gd (Godot 4 style)"
  @"
extends Node
@tool
func _ready() -> void:
    var out = []
    var dir = DirAccess.open("res://")
    var scenes = []
    _collect_scenes(dir, "res://", scenes)
    for s in scenes:
        var result = {"scene": s, "loaded": false, "error": null, "load_ms": null}
        var t0 = OS.get_ticks_msec()
        var r = ResourceLoader.load(s)
        result["load_ms"] = OS.get_ticks_msec() - t0
        if r == null:
            result["error"] = "ResourceLoader returned null"
            out.append(result)
            continue
        var ok_instance = false
        var inst = null
        try:
            inst = r.instantiate()
            add_child(inst)
            get_tree().process_frame()
            get_tree().idle_frame()
            ok_instance = true
            inst.queue_free()
        except err:
            result["error"] = str(err)
        result["loaded"] = ok_instance
        out.append(result)
    var json = JSON.new()
    print(json.stringify(out))
    get_tree().quit(0)

func _collect_scenes(dir:DirAccess, base:String, out_arr:Array) -> void:
    dir.list_dir_begin()
    var fname = dir.get_next()
    while fname != "":
        if dir.current_is_dir():
            if fname != "." and fname != "..":
                var sub = DirAccess.open(base + fname + "/")
                _collect_scenes(sub, base + fname + "/", out_arr)
        else:
            if fname.ends_with(".tscn") or fname.ends_with(".scn"):
                out_arr.append(base + fname)
        fname = dir.get_next()
    dir.list_dir_end()
"@ | Set-Content -Path $sceneTester -Encoding UTF8
}

# Snapshot branch + minor safety commit
Write-Stage "GIT SNAPSHOT"
Push-Location $Repo
try {
  $curBranch = (git rev-parse --abbrev-ref HEAD) 2>$null
  if(-not $curBranch){ Write-Host "Not a git repo or git not available"; Pop-Location; FailExit "git required" }
  $snapshotBranch = "ci/snapshot_$stamp"
  git checkout -B $snapshotBranch 2>$null
  git add -A
  git commit -m "AG: pre-ci snapshot $stamp" --allow-empty 2>$null
  Write-Host "Created snapshot branch: $snapshotBranch"
} catch {
  Write-Host "Git snapshot failed: $_"
}
Pop-Location

# Run Validate-BoundMappings.ps1 if present
Write-Stage "RUN Validate-BoundMappings.ps1"
$validateScript = Join-Path $Repo "migration\Validate-BoundMappings.ps1"
if(Test-Path $validateScript){
  $vmOut = Join-Path $runFolder "ValidateBoundMappings.raw.txt"
  try {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $validateScript -TestMode *>&1 | Tee-Object -FilePath $vmOut
  } catch {
    Write-Host "Validate script ran with non-zero exit or error; check $vmOut"
  }
} else {
  Write-Host "No Validate-BoundMappings.ps1 found; skipping."
}

# Run Godot scene load tester
Write-Stage "GODOT SCENE LOAD TEST (pre-patch)"
$godotJsonPre = Join-Path $runFolder "godot_scene_load_pre_patch.json"
$godotErrPre = Join-Path $runFolder "godot_scene_load_pre_patch.err"
if(Test-Path $GodotExe){
  Push-Location $Repo
  & "$GodotExe" --headless --script $sceneTester 1> $godotJsonPre 2> $godotErrPre
  Pop-Location
  Write-Host "Godot test completed. JSON: $godotJsonPre"
} else {
  Write-Host "Godot executable not found at $GodotExe; skipping Godot scene test."
}

# Asset validation
Write-Stage "ASSET VALIDATION (images/videos/lotties)"
$assetsRoot = "D:\seasonal_outbreak_assets"
$imgLog = Join-Path $runFolder "imagemagick_errors.log"
$badImages = Join-Path $runFolder "bad_images.txt"
$ffErr = Join-Path $runFolder "ffmpeg_errors.log"
$badLotties = Join-Path $runFolder "bad_lotties.txt"

if(Test-Path $assetsRoot){
  Get-ChildItem -Path $assetsRoot -Include *.png,*.jpg,*.jpeg -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    try {
      magick identify -format "%f %m %w x %h %z bits\n" "$($_.FullName)" 2>> $imgLog
      if($LASTEXITCODE -ne 0){ Add-Content $badImages $_.FullName }
    } catch { Add-Content $badImages $_.FullName }
  }
  Get-ChildItem -Path $assetsRoot -Include *.mp4,*.webm -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    try { ffmpeg -v error -i "$($_.FullName)" -f null - 2>> $ffErr } catch { Add-Content $ffErr "$($_.FullName) - ffmpeg failed" }
  }
  Get-ChildItem -Path (Join-Path $assetsRoot "lotties") -Include *.json -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    try { $txt = Get-Content $_.FullName -Raw; $null = ConvertFrom-Json $txt } catch { Add-Content $badLotties $_.FullName }
  }
  Write-Host "Asset validation complete."
} else {
  Write-Host "Assets root not found ($assetsRoot). Skipping asset validation."
}

# Log analysis helper creation
Write-Stage "LOG ANALYSIS"
$analysisOut = Join-Path $runFolder "quick_log_analysis.txt"
"" | Out-File $analysisOut
$patterns = @("Unresolved identifier","Class .* not found","Presentation","ShapeImage","Null instance","Attempt to call function '.*' in base 'null'","error:","Exception")
Get-ChildItem -Path $runFolder -Include *.log,*.err,*.txt,*.json -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
  $c = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
  foreach($p in $patterns){ if($c -match $p){ Add-Content $analysisOut "[$p] in $($_.FullName)`n----`n$($Matches[0])`n`n" } }
}
Write-Host "Quick analysis saved to $analysisOut"

# Prepare AG prompt for automated fixes
Write-Stage "WRITE AG PROMPT"
$agPromptFile = Join-Path $runFolder "ag_prompt.json"
$agPrompt = @{
  task="Fix Presentation/ShapeImage and runtime-only incompatibilities";
  repo=$Repo;
  branch=$snapshotBranch;
  pattern_targets=@("Presentation","ShapeImage","PresentationAPI","enterprise");
  patch_location = Join-Path $Repo "migration\action_patches";
  test_cmd = "`"$GodotExe`" --headless --script tools/scene_load_tester.gd";
  commit_message_prefix = "AG: PLE fix"
}
$agPrompt | ConvertTo-Json -Depth 6 | Set-Content -Path $agPromptFile -Encoding UTF8
Write-Host "AG prompt written: $agPromptFile"

# Auto apply patches if requested
Write-Stage "APPLY DIFFS (if any) - AutoApplyPatches: $AutoApplyPatches"
$diffsFolder = Join-Path $Repo "migration\action_patches"
$applied = @(); $failed = @()
if($AutoApplyPatches){
  $diffs = Get-ChildItem -Path $diffsFolder -Filter *.diff -File -ErrorAction SilentlyContinue
  if($diffs.Count -eq 0){ Write-Host "No diffs found in $diffsFolder" } else {
    Push-Location $Repo
    foreach($d in $diffs){
      try {
        git apply --index $d.FullName
        git add -A
        git commit -m "PLE: apply patch $($d.Name)" 2>$null
        $applied += $d.Name
      } catch {
        $failed += $d.Name
        Copy-Item $d.FullName (Join-Path $runFolder "failed_$($d.Name)") -Force
      }
    }
    Pop-Location
  }
} else {
  Write-Host "AutoApplyPatches not enabled. Skipping patch application."
}

# Re-run Godot tester after patches
Write-Stage "GODOT SCENE LOAD TEST (post-patch)"
$godotJsonPost = Join-Path $runFolder "godot_scene_load_post_patch.json"
$godotErrPost = Join-Path $runFolder "godot_scene_load_post_patch.err"
if(Test-Path $GodotExe){
  Push-Location $Repo
  & "$GodotExe" --headless --script $sceneTester 1> $godotJsonPost 2> $godotErrPost
  Pop-Location
  Write-Host "Post-patch Godot test done. JSON: $godotJsonPost"
}

# Final summary & archive
Write-Stage "ARCHIVE & SUMMARY"
$artifactZip = Join-Path $ReportsFolder "ci_results_$stamp.zip"
if(Test-Path $artifactZip){ Remove-Item $artifactZip -Force }
Compress-Archive -Path $runFolder\* -DestinationPath $artifactZip -Force

# Final action summary JSON
$summary = @{
  timestamp = $stamp
  godot_exe = $GodotExe
  repo = $Repo
  report_folder = $runFolder
  artifact = $artifactZip
  applied_diffs = $applied
  failed_diffs = $failed
}
$summary | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $runFolder "ag_action_summary.json") -Encoding UTF8

Write-Host "==== ARCHIVE & SUMMARY ====`nAll reports archived to: $artifactZip"
exit 0
