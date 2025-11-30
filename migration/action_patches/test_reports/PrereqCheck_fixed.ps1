# PrereqCheck_fixed.ps1 — robust prereq checker (writes prereq_check.json)
Import-Module -Name Microsoft.PowerShell.Utility -ErrorAction SilentlyContinue
$repo = "D:\Repos\Seasonal_outbreaks_Godot"
$reportDir = Join-Path $repo "migration\action_patches\test_reports"
if(-not (Test-Path $reportDir)){ New-Item -ItemType Directory -Force -Path $reportDir | Out-Null }
$outPath = Join-Path $reportDir "prereq_check.json"
$now = [DateTime]::UtcNow.ToString("o")

function RunCmd($cmd){
  try { $o = & cmd /c $cmd 2>&1; $code = $LASTEXITCODE } catch { $o = $_.Exception.Message; $code = 1 }
  return @{ stdout = ($o -join "`n"); stderr = ""; code = $code}
}

# Simple checks
$checks = @{}

# git
$checks.git = RunCmd("git --version")

# PowerShell version
try { $checks.powershell = @{ ok=$true; stdout = (pwsh --version 2>&1 | Out-String).Trim(); code=0 } } catch { $checks.powershell = @{ ok=$false; stdout=""; code=1 } }

# ffmpeg
$checks.ffmpeg = RunCmd("ffmpeg -version")

# ImageMagick
$checks.imagemagick = RunCmd("magick -version")

# node & npm
$checks.node = RunCmd("node -v")
$checks.npm = RunCmd("npm -v")

# Playwright package check (optional)
$playOk = $false
$playNote = ""
try {
  $pkgJson = Join-Path $repo "package.json"
  if(Test-Path (Join-Path $repo "node_modules\@playwright\test")){ $playOk = $true; $playNote="installed" }
  elseif(Test-Path $pkgJson -and (Get-Content $pkgJson -Raw) -match '"@playwright/test"'){ $playOk=$false; $playNote="declared in package.json" }
  else { $playOk = $false; $playNote = "missing" }
} catch { $playOk = $false; $playNote = "error" }
$checks.playwright_package = @{ ok = $playOk; note = $playNote }

# AG CLI
$checks.ag_cli = RunCmd("ag --version")

# FS write test
$testFile = Join-Path $reportDir ".prereq_test_write"
try { Set-Content -Path $testFile -Value "test" -Force; Remove-Item $testFile -Force; $checks.fs_write = @{ ok = $true; test_file = $testFile } } catch { $checks.fs_write = @{ ok = $false; test_file = $testFile; stderr = $_.Exception.Message } }

# Git remote
try {
  Push-Location $repo
  $remote = RunCmd("git remote get-url origin")
  $hasRemote = ($remote.code -eq 0 -and $remote.stdout.Trim() -ne "")
  $reachable = $false
  if($hasRemote){ $lr = RunCmd("git ls-remote --exit-code origin HEAD"); $reachable = ($lr.code -eq 0) }
  Pop-Location
  $checks.git_remote = @{ present = $hasRemote; reachable = $reachable; stdout = $remote.stdout }
} catch { $checks.git_remote = @{ present = $false; reachable = $false } }

# Robust Godot detection
function TestGodot($path){
  try { $out = & $path --version 2>&1; $code = $LASTEXITCODE } catch { $out = $_.Exception.Message; $code = 1 }
  return @{ ok = ($out -ne "" -or $code -eq 0); stdout = ($out -join "`n"); code = $code }
}

$godotPaths = @()
if($env:GODOT_EXE -and $env:GODOT_EXE -ne ""){ $godotPaths += $env:GODOT_EXE }
$defaultCandidates = @("D:\Godot\Godot_v4.5.1-stable_win64_console.exe","D:\Godot\Godot.exe","C:\Program Files\Godot\Godot.exe","godot")
foreach($c in $defaultCandidates){ $godotPaths += $c }
# wildcard scan for D:\Godot\Godot*.exe
try { $wild = Get-ChildItem -Path "D:\Godot" -Filter "Godot*.exe" -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName } ; $godotPaths += $wild } catch {}
$godotPaths = $godotPaths | Where-Object { $_ } | Select-Object -Unique

$chosen = $null; $gout=""; $gcode = 1
foreach($p in $godotPaths){
  $t = TestGodot $p
  if($t.ok -or $t.code -eq 0){
    $chosen = $p; $gout = $t.stdout; $gcode = $t.code; break
  }
}
if($chosen){
  $checks.godot = @{ ok = $true; chosen = $chosen; stdout = $gout; code = $gcode; path_checked = $godotPaths }
} else {
  $checks.godot = @{ ok = $false; chosen = $null; stdout = ""; code = 1; path_checked = $godotPaths }
}

# Determine prereq_ok
$required = @("git","godot","powershell","ffmpeg","imagemagick","fs_write")
$allGood = $true
foreach($r in $required){
  if($r -eq "godot"){
    if(-not $checks.godot.ok){ $allGood = $false }
  } elseif($r -eq "powershell"){
    if(-not $checks.powershell.ok){ $allGood = $false }
  } else {
    if(-not ($checks.$r.code -eq 0 -or $checks.$r.ok -eq $true)){ $allGood = $false }
  }
}

# notes
$notes = @()
if(-not $checks.godot.ok){ $notes += "Godot not found. Set GODOT_EXE or add D:\Godot to PATH." }
if(-not $checks.playwright_package.ok){ $notes += "Playwright package missing (optional): npm i --no-audit --no-fund @playwright/test" }
if($checks.ag_cli.code -ne 0){ $notes += "AG CLI not found (optional)." }

# build result
$result = @{
  timestamp = $now
  prereq_ok = $allGood
  checks = $checks
  notes = $notes
}

# write JSON
$result | ConvertTo-Json -Depth 6 | Set-Content -Path $outPath -Encoding UTF8

# print summary line
if($allGood){ Write-Host "PREREQ CHECK: OK - see $outPath" } else { Write-Host "PREREQ CHECK: FAIL - see $outPath" ; exit 1 }
