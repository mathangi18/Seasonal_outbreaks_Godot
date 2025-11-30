<#
prepare_for_ag.ps1
Purpose: Preflight + validation + prompt block generation for AG resume run.
Safe: idempotent. NON-DESTRUCTIVE by default.
Outputs:
 - migration/ag_prep.log
 - migration/validation_report.json
 - migration/validation_report.md
 - migration/ag_prompt_blocks/* (00..06)
 - migration/ag_prompt_full.txt
 - scripts/visual_camera.gd (only if missing or if --force)
 - scenes/CameraWrapper.tscn (only if missing or if --force)
#>

param(
  [switch]$ForceOverwrite  # Pass -ForceOverwrite to allow overwriting camera files
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- CONFIG (edit here if you move folders) ---
$RepoRoot = 'D:\Repos\Seasonal_outbreaks_Godot'
$RenderedRoot = 'D:\seasonal_outbreak_assets'
$MigrationDir = Join-Path $RepoRoot 'migration'
$PromptBlocksDir = Join-Path $MigrationDir 'ag_prompt_blocks'
$MainManifest = Join-Path $MigrationDir 'asset_mappings.json'
$VisualsManifest = Join-Path $MigrationDir 'asset_mappings_visuals_full.json'
$ValidationReportJson = Join-Path $MigrationDir 'validation_report.json'
$ValidationReportMd = Join-Path $MigrationDir 'validation_report.md'
$PrepLog = Join-Path $MigrationDir 'ag_prep.log'
$PromptFull = Join-Path $MigrationDir 'ag_prompt_full.txt'
$CameraScript = Join-Path $RepoRoot 'scripts\visual_camera.gd'
$CameraScene = Join-Path $RepoRoot 'scenes\CameraWrapper.tscn'
$FeaturesSrc1 = Join-Path $RenderedRoot 'FEATURES_MASTER.txt.txt'
$FeaturesSrc2 = Join-Path $RenderedRoot 'seasonal outbreak - Revised.docx'
$FeaturesDst1 = Join-Path $MigrationDir 'FEATURES_MASTER.txt.txt'
$FeaturesDst2 = Join-Path $MigrationDir 'seasonal outbreak - Revised.docx'

# --- Ensure migration folder exists ---
New-Item -Path $MigrationDir -ItemType Directory -Force | Out-Null
New-Item -Path $PromptBlocksDir -ItemType Directory -Force | Out-Null

# --- Logging helper ---
function Log {
  param($msg)
  $t = (Get-Date).ToString('u')
  $line = "$t`t$msg"
  Write-Output $line
  Add-Content -Path $PrepLog -Value $line
}

# Start
if (Test-Path $PrepLog) { Remove-Item $PrepLog -Force }
Log "AG preflight started."

# 1) Check features & concept files & copy to migration (idempotent)
$missingFiles = @()
foreach ($pair in @(@{src=$FeaturesSrc1;dst=$FeaturesDst1}, @{src=$FeaturesSrc2;dst=$FeaturesDst2})) {
  if (-not (Test-Path $pair.src)) {
    Log "MISSING: features file not found: $($pair.src)"
    $missingFiles += $pair.src
    continue
  }
  try {
    Copy-Item -Path $pair.src -Destination $pair.dst -Force
    Log "COPIED: $($pair.src) -> $($pair.dst)"
  } catch {
    Log "ERROR copying $($pair.src): $($_.Exception.Message)"
    $missingFiles += $pair.src
  }
}

# 2) Check manifests existence
$manifestMissing = @()
if (-not (Test-Path $MainManifest)) { Log "ERROR: main manifest missing: $MainManifest"; $manifestMissing += $MainManifest } else { Log "FOUND main manifest: $MainManifest" }
if (-not (Test-Path $VisualsManifest)) { Log "WARN: visuals manifest missing (expected optional): $VisualsManifest"; } else { Log "FOUND visuals manifest: $VisualsManifest" }

# 3) Read manifest(s) and validate per-entry
function Load-JsonFile($path) {
  try { return (Get-Content $path -Raw | ConvertFrom-Json) } catch { throw "Failed to parse JSON $path : $($_.Exception.Message)" }
}

$allEntries = @()
if (Test-Path $MainManifest) {
  try {
    $m = Load-JsonFile $MainManifest
    if ($m -is [System.Array]) { $allEntries += $m } else { $allEntries += ,$m }
    Log "Loaded main manifest entries: $($allEntries.Count)"
  } catch {
    Log "ERROR reading main manifest: $($_.Exception.Message)"
    throw $_
  }
}
if (Test-Path $VisualsManifest) {
  try {
    $v = Load-JsonFile $VisualsManifest
    if ($v -is [System.Array]) { $allEntries += $v } else { $allEntries += ,$v }
    Log "Loaded visuals manifest entries: $($v.Count)"
  } catch {
    Log "ERROR reading visuals manifest: $($_.Exception.Message)"
    throw $_
  }
}

# Normalize entries: expected fields role, original_path, new_path, sha256, converted
$validationResults = @()
foreach ($entry in $allEntries) {
  # attempt to read fields with common fallbacks
  $role = $null
  $orig = $null
  $newp = $null
  $sha = $null
  $conv = $false
  if ($entry.PSObject.Properties.Match('role')) { $role = $entry.role } 
  elseif ($entry.PSObject.Properties.Match('name')) { $role = $entry.name }
  if ($entry.PSObject.Properties.Match('original_path')) { $orig = $entry.original_path }
  elseif ($entry.PSObject.Properties.Match('src')) { $orig = $entry.src }
  if ($entry.PSObject.Properties.Match('new_path')) { $newp = $entry.new_path }
  elseif ($entry.PSObject.Properties.Match('dest')) { $newp = $entry.dest }
  if ($entry.PSObject.Properties.Match('sha256')) { $sha = $entry.sha256 }
  if ($entry.PSObject.Properties.Match('converted')) { $conv = [bool]$entry.converted }

  # ensure absolute/normalized path for new_path if it's Windows-style
  if ($newp) {
    # if looks like res path starting with res:// convert to repo path if necessary (do not auto-guess!)
    if ($newp -match '^res:\/\/') {
      # strip res:// and assume repo root is working dir
      $cand = $newp -replace '^res:\/\/',''
      $cand = Join-Path $RepoRoot $cand.TrimStart('/')
      $normPath = $cand
    } else {
      $normPath = $newp
    }
  } else {
    $normPath = $null
  }

  $res = [ordered]@{
    role = $role
    entry_origin = $orig
    new_path_declared = $newp
    new_path_resolved = $normPath
    expected_sha256 = $sha
    converted_flag = $conv
    exists = $false
    actual_sha256 = $null
    match = $false
    size_kb = $null
    notes = @()
  }

  if (-not $normPath) {
    $res.notes += "new_path missing or could not be normalized"
    $validationResults += $res
    continue
  }
  if (Test-Path $normPath) {
    $res.exists = $true
    $fi = Get-Item -LiteralPath $normPath
    $res.size_kb = [math]::Round($fi.Length/1KB,1)
    try {
      $h = Get-FileHash -Algorithm SHA256 -Path $normPath
      $res.actual_sha256 = $h.Hash
      if ($res.expected_sha256) {
        $res.match = ($res.expected_sha256 -eq $res.actual_sha256)
        if (-not $res.match) { $res.notes += "SHA mismatch" }
      } else {
        $res.notes += "expected sha missing in manifest"
      }
    } catch {
      $res.notes += "failed to compute hash: $($_.Exception.Message)"
    }
  } else {
    $res.exists = $false
    $res.notes += "file does not exist at new_path_resolved"
  }

  $validationResults += $res
  Log "Validated: $($res.role) exists=$($res.exists) match=$($res.match)"
}

# Write JSON + Markdown validation reports
$validationResults | ConvertTo-Json -Depth 6 | Out-File -FilePath $ValidationReportJson -Encoding utf8
# Markdown summary
$md = @()
$md += "# Manifest Validation Report"
$md += "Generated: $(Get-Date -Format u)"
$md += ""
$md += "| role | exists | size_kb | expected_sha256 | actual_sha256 | match | notes |"
$md += "|------|--------:|--------:|-----------------|---------------|:-----:|------|"
foreach ($r in $validationResults) {
  $md += "| $($r.role) | $($r.exists) | $($r.size_kb) | $($r.expected_sha256) | $($r.actual_sha256) | $($r.match) | $(([string]::Join('; ',$r.notes))) |"
}
$md | Out-File -FilePath $ValidationReportMd -Encoding utf8

Log "Wrote validation reports: $ValidationReportJson and $ValidationReportMd"

# 4) Prepare AG prompt block files (A -> G) - content mirrors the framework we discussed
$blocks = @{
"00_intent_and_scope.txt" = @"
<<INTENT>>
Resume AG pipeline headless on branch ag/implement-from-manifest; operate locally only; read manifests and rendered asset folders; generate scenes/scripts and camera wrapper; keep changes local; do not push.
"@
"01_inputs_and_manifest.txt" = @"
<<INPUTS>>
Files AG must read (in order):
- migration/asset_mappings.json
- migration/asset_mappings_visuals_full.json
- D:\seasonal_outbreak_assets\ (verify against manifest)
- migration\FEATURES_MASTER.txt.txt
- migration\seasonal outbreak - Revised.docx
"@
"02_constraints_and_C01-C15.txt" = @"
<<CONSTRAINTS>>
Enforce hard constraints C01-C15 (no new top-level dirs, no .import writes, exact case, res:// usage, etc.). Fail on any violation.
"@
"03_camera_and_visual_plan.txt" = @"
<<CAMERA_PLAN>>
Create scenes/CameraWrapper.tscn and scripts/visual_camera.gd:
- Camera2D smoothing_enabled=true, smoothing_speed=5.0, zoom=Vector2(0.85,0.85)
- Methods: set_target(), pulse_zoom(), shake()
- CanvasLayer for HUD. Optional Viewport for offscreen rasterization.
"@
"04_wipe_and_regen_policy.txt" = @"
<<WIPE_POLICY>>
Delete only AG-generated globs: scenes/generated_*, scripts/gen_*, migration/ag_temp_* if user issues GO. Do not delete res/assets/*.
Record deletions to migration/ag_wipe_log.txt.
"@
"05_headless_validation_and_logs.txt" = @"
<<HEADLESS_VALIDATION>>
Run Godot headless scene load for each produced scene and emit validation_report.json, ag_errors.json, ag_run_log.txt. Abort on first critical error.
"@
"06_plan_and_runbook.txt" = @"
<<RUNBOOK>>
Produce migration/ag_plan.json with step-by-step commands for dry-run, wipe (if GO), resume, and rollback git commands. All actions local only.
"@
}

foreach ($k in $blocks.Keys) {
  $path = Join-Path $PromptBlocksDir $k
  $blocks[$k] | Out-File -FilePath $path -Encoding utf8
  Log "Wrote prompt block: $path"
}

# 5) Compose ag_prompt_full.txt (concatenate in order)
Get-ChildItem -Path $PromptBlocksDir -Filter *.txt | Sort-Object Name | Get-Content | Out-File -FilePath $PromptFull -Encoding utf8
Log "Composed combined AG prompt: $PromptFull"

# 6) Write camera script & scene skeleton (non-destructive; only writes if missing or -ForceOverwrite)
$cameraScriptContent = @"
extends Camera2D

@export var damping: float = 5.0
@export var zoom_min: Vector2 = Vector2(0.7,0.7)
@export var zoom_max: Vector2 = Vector2(1.0,1.0)
@export var pulse_amount: float = 0.12
@export var shake_strength: float = 8.0

var _target: Node2D = null
var _shake_time = 0.0
var _shake_decay = 6.0
var _orig_offset = Vector2.ZERO

func _ready():
    smoothing_enabled = true
    smoothing_speed = damping
    _orig_offset = offset

func set_target(node_path: NodePath):
    var n = get_node_or_null(node_path)
    if n:
        _target = n
    else:
        push_warning("visual_camera.gd: target not found: %s" % str(node_path))

func _process(delta):
    if _target:
        global_position = global_position.linear_interpolate(_target.global_position + Vector2(0,-40), clamp(damping * delta, 0.0, 1.0))
    if _shake_time > 0.0:
        _shake_time -= delta * _shake_decay
        offset = _orig_offset + Vector2(randf_range(-1,1), randf_range(-1,1)) * _shake_time * shake_strength
    else:
        offset = _orig_offset

func pulse_zoom(time_sec: float = 0.25):
    var tween = get_tree().create_tween()
    tween.tween_property(self, "zoom", zoom * (1 - pulse_amount), time_sec).as_relative(false).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "zoom", zoom, time_sec).set_delay(time_sec)

func shake(duration: float = 0.6):
    _shake_time = duration
"@

$cameraSceneContent = @"
[gd_scene load_steps=2 format=2]

[node name='CameraWrapper' type='Node2D']

[node name='MainCamera' type='Camera2D' parent='CameraWrapper']
script = ExtResource( 1 )
current = true
zoom = Vector2( 0.85, 0.85 )

[ext_resource path='res://scripts/visual_camera.gd' type='Script' id=1]
"@

if ((-not (Test-Path $CameraScript)) -or $ForceOverwrite.IsPresent) {
  $cameraScriptContent | Out-File -FilePath $CameraScript -Encoding utf8
  Log "Wrote camera script: $CameraScript"
} else {
  Log "Camera script exists and not overwritten: $CameraScript"
}

if ((-not (Test-Path $CameraScene)) -or $ForceOverwrite.IsPresent) {
  $cameraSceneContent | Out-File -FilePath $CameraScene -Encoding utf8
  Log "Wrote camera scene skeleton: $CameraScene"
} else {
  Log "Camera scene exists and not overwritten: $CameraScene"
}

# 7) Quick repo sanity checks (manifests existence and assets counts)
$checks = [ordered]@{}
$checks['main_manifest_exists'] = Test-Path $MainManifest
$checks['visuals_manifest_exists'] = Test-Path $VisualsManifest
$checks['rendered_folder_exists'] = Test-Path $RenderedRoot
# count assets found under allowed folders in repo
$assetFiles = Get-ChildItem -Path (Join-Path $RepoRoot 'res\assets') -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match '\\res\\assets\\' }
$checks['repo_asset_files_count'] = $assetFiles.Count
$checks | ConvertTo-Json -Depth 2 | Out-File -FilePath (Join-Path $MigrationDir 'prep_checks.json') -Encoding utf8
Log "Wrote quick checks to migration\prep_checks.json"

# 8) Summary to console + exit code logic
$criticalMissing = @()
if ($missingFiles.Count -gt 0) { $criticalMissing += $missingFiles }
if ($manifestMissing.Count -gt 0) { $criticalMissing += $manifestMissing }

if ($criticalMissing.Count -gt 0) {
  Log "CRITICAL: missing items found. Check $PrepLog and $ValidationReportJson for details."
  Write-Output "`n=== PREP SUMMARY: FAIL ===`nSee $PrepLog and $ValidationReportJson"
  exit 2
} else {
  Log "PREP COMPLETE: no critical missing items. Validation report and prompt blocks created."
  Write-Output "`n=== PREP SUMMARY: OK ===`nValidation report: $ValidationReportJson`nCombined AG prompt: $PromptFull`nLogs: $PrepLog"
  exit 0
}
