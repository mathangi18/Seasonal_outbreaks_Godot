<#
  run_pipeline.ps1
  Minimal orchestrator for:
  - Godot in-engine tests
  - Playwright HTML5 runtime tests
  - ffmpeg/imagemagick asset validation
  - PowerShell runbook (this orchestrator itself)
  - Auto-patch collector (git diff)
#>

param(
  [string]$RepoRoot = (Get-Location).Path,
  [string]$ArtifactsRoot = "C:\temp\seasonal_ci\artifacts",
  [string]$GodotExec = $env:GODOT_EXEC,          # e.g. "C:\Program Files\Godot\Godot.exe"
  [string]$PlaywrightCmd = $env:PLAYWRIGHT_CMD,  # e.g. "npm run test:playwright" or "npx playwright test"
  [string]$AssetDirs = "$RepoRoot\assets",
  [switch]$CreatePatch = $true
)

# Helpers
function FailIfLast { param($stage) if ($LASTEXITCODE -ne 0) { Write-Error "$stage FAILED (exit $LASTEXITCODE)"; exit $LASTEXITCODE } }

# make artifact dir
$ts = (Get-Date).ToString("yyyyMMdd_HHmmss")
$art = Join-Path $ArtifactsRoot $ts
New-Item -ItemType Directory -Force -Path $art | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $art "godot") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $art "playwright") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $art "assets") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $art "patches") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $art "logs") | Out-Null

Write-Output "Artifacts -> $art"

#####################
# 1) Godot in-engine tests
#####################
Write-Output "=== STAGE 1: Godot tests ==="
if (-not $GodotExec) { Write-Error "GODOT_EXEC not set. Set env or pass -GodotExec"; exit 2 }
$godotLog = Join-Path $art "godot\godot_run.log"
# NOTE: driver script path below should exist in your project (res://tests/run_all.gd). Adapt if different.
$godotArgs = "--path `"$RepoRoot`" --headless -s res://tests/run_all.gd --quit"
Write-Output "Running: $GodotExec $godotArgs" | Tee-Object -FilePath $godotLog -Append
& "$GodotExec" $godotArgs 2>&1 | Tee-Object -FilePath $godotLog
$LASTEXITCODE | Out-Null
FailIfLast "Godot tests"
# copy junit/xml if produced by your runner (common path)
Get-ChildItem -Path $RepoRoot -Filter "*junit*.xml" -Recurse -ErrorAction SilentlyContinue | ForEach-Object { Copy-Item $_.FullName -Destination (Join-Path $art "godot") -Force }

#####################
# 2) Playwright HTML5 runtime tests
#####################
Write-Output "=== STAGE 2: Playwright tests ==="
if (-not $PlaywrightCmd) { Write-Error "PLAYWRIGHT_CMD not set. Set env or pass -PlaywrightCmd"; exit 3 }
$pwLog = Join-Path $art "playwright\playwright_run.log"
Write-Output "Running Playwright: $PlaywrightCmd" | Tee-Object -FilePath $pwLog -Append
# run in repo root so test config is found
Push-Location $RepoRoot
# prefer using npm script so it resolves node modules; allow simple shell command too
if ($PlaywrightCmd -like "npx*") {
  # run direct
  iex $PlaywrightCmd 2>&1 | Tee-Object -FilePath $pwLog
} else {
  # run as process
  & cmd /c $PlaywrightCmd 2>&1 | Tee-Object -FilePath $pwLog
}
$LASTEXITCODE | Out-Null
Pop-Location
FailIfLast "Playwright tests"
# copy artifacts (screenshots/traces/playwright-report)
if (Test-Path "$RepoRoot\playwright-report") { Copy-Item -Recurse "$RepoRoot\playwright-report" (Join-Path $art "playwright\playwright-report") -Force }

#####################
# 3) Asset validation (ffmpeg + ImageMagick)
#####################
Write-Output "=== STAGE 3: Asset validation (ffmpeg/imagemagick) ==="
$assetsLog = Join-Path $art "assets\assets_validation.csv"
"file,ok,type,notes" | Out-File -FilePath $assetsLog -Encoding utf8
$ffprobe = "ffprobe"   # expect ffmpeg utilities in PATH
$identify = "identify" # imagemagick identify
Get-ChildItem -Path $AssetDirs -Recurse -File | ForEach-Object {
  $file = $_.FullName
  $ext = $_.Extension.ToLower()
  $ok = $false
  $notes = ""
  if ($ext -in ".mp4",".webm",".mov",".mkv") {
    # validate with ffprobe (detect decode errors)
    $cmd = "$ffprobe -v error -show_format -show_streams `"$file`""
    $output = & $ffprobe -v error -show_format -show_streams $file 2>&1
    if ($LASTEXITCODE -eq 0) { $ok = $true } else { $notes = ($output -join " | ") }
    $type = "video"
  } else {
    # image validation
    $out = & $identify -verbose $file 2>&1
    if ($LASTEXITCODE -eq 0) { $ok = $true } else { $notes = ($out -join " | ") }
    $type = "image"
  }
  "$file,$ok,$type,`"$notes`"" | Out-File -FilePath $assetsLog -Append -Encoding utf8
}

#####################
# 4) Runbook / extra validation (optional custom checks)
#####################
Write-Output "=== STAGE 4: Runbook checks ==="
$runbookLog = Join-Path $art "logs\runbook.log"
# Example checks: missing scenes, large textures > threshold, fps-config sanity
# (adapt below rules to your project)
$textureThresholdMB = 10
Get-ChildItem -Path "$RepoRoot" -Include *.import,*.cfg,*.tres,*.res -Recurse -ErrorAction SilentlyContinue |
 ForEach-Object {
   # simple placeholder checks
   if ($_.Length -gt ($textureThresholdMB * 1MB)) {
     "LARGE_FILE,$_ - size:$($_.Length)" | Out-File -FilePath $runbookLog -Append
   }
}
# (Add more domain checks here if needed)

#####################
# 5) Create patch (git diff) if CreatePatch
#####################
if ($CreatePatch) {
  Write-Output "=== STAGE 5: Create git patch(s) ==="
  Push-Location $RepoRoot
  # stash untracked? we want current working tree diffs
  $patchFile = Join-Path $art "patches\auto_fix_$(Get-Date -Format yyyyMMdd_HHmmss).diff"
  git --version > $null 2>&1
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "git not found - skipping patch creation"
  } else {
    # create diff of working tree vs HEAD
    git diff --no-prefix > $patchFile
    if ((Get-Item $patchFile).Length -eq 0) {
      Remove-Item $patchFile
      Write-Output "No diffs to save."
    } else {
      Write-Output "Patch written: $patchFile"
      # Optionally create branch and commit auto fixes (uncomment if desired)
      # git checkout -b auto-fixes/$(Get-Date -Format yyyyMMdd_HHmmss)
      # git add -A
      # git commit -m "Auto-fixes from CI run $ts"
    }
  }
  Pop-Location
}

Write-Output "=== PIPELINE COMPLETE ==="
Write-Output "Artifacts available at: $art"
