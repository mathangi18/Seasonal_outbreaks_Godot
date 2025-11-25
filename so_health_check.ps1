<#
  so_health_check.ps1
  Full repo health check for Seasonal_outbreaks_Godot
  Save to the machine and run from PowerShell.
#>

# ---------- CONFIG ----------
$repo = "D:\Repos\Seasonal_outbreaks_Godot"    # <-- adjust if needed
$ts   = (Get-Date -Format "yyyyMMdd_HHmmss")
$report = Join-Path $repo "so_health_report_$ts.txt"
$quickSnapshot = Join-Path (Split-Path $repo -Parent) ("SO_QUICK_SNAPSHOT_$ts")
$trashBackup    = "D:\SO_TRASH_BACKUP_$ts"
$DoCleanup = $false    # <-- set to $true only when you want the script to move/delete trash
$VerbosePreference = "SilentlyContinue"
# ----------------------------

function Log {
  param($line)
  $line | Tee-Object -FilePath $report -Append -Encoding utf8
}

# start report
"" > $report
Log "SO HEALTH CHECK REPORT - $ts"
Log "Repo: $repo"
Log "User: $env:USERNAME"
Log "PowerShell: $($PSVersionTable.PSVersion)"
Log "------------------------------------------`n"

# create a quick snapshot (non-blocking copy)
Log "Creating quick snapshot -> $quickSnapshot"
try {
  Copy-Item -Path $repo -Destination $quickSnapshot -Recurse -Force -ErrorAction Stop
  Log "SNAPSHOT_CREATED: $quickSnapshot"
} catch {
  Log "SNAPSHOT_FAILED: $_"
}

# Git status + diff (if repo)
if (Test-Path (Join-Path $repo ".git")) {
  Log "`n=== GIT STATUS (porcelain) ==="
  try { 
    & git -C $repo status --porcelain 2>&1 | ForEach-Object { Log "GIT: $_" }
  } catch { Log "GIT_STATUS_FAILED: $_" }

  Log "`n=== GIT DIFF (name-status against HEAD) ==="
  try {
    & git -C $repo diff --name-status HEAD 2>&1 | ForEach-Object { Log "GIT_DIFF: $_" }
  } catch { Log "GIT_DIFF_FAILED: $_" }
} else {
  Log "No git repo found at $repo"
}

# Find large cache / trash candidates and report sizes
$trashPatterns = @(
  ".godot\imported",
  ".godot\shader_cache",
  "godot_temp",
  "logs",
  ".ag_work",
  ".openagent",
  ".open-agent",
  "removed_backup_*",
  "Godot.exe.broken_*"
)
Log "`n=== TRASH / CACHE CANDIDATES ==="
foreach($p in $trashPatterns) {
  $matches = Get-ChildItem -Path $repo -Recurse -Force -ErrorAction SilentlyContinue -Include $p | Select-Object -Unique FullName
  foreach($m in $matches) {
    try {
      $size = (Get-ChildItem -LiteralPath $m.FullName -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
      if (-not $size) { $size = 0 }
      $sizeMB = [math]::Round($size / 1MB, 2)
      Log "CANDIDATE: $($m.FullName)  SizeMB: $sizeMB"
    } catch {
      Log "CANDIDATE (error): $($m.FullName) -> $_"
    }
  }
}
Log "------------------------------------------`n"

# Parse .tscn files for texture references and check existence
Log "=== CHECKING .tscn texture references ==="
$tscnFiles = Get-ChildItem -Path $repo -Recurse -Include *.tscn -File -ErrorAction SilentlyContinue
$missing = @()
foreach($f in $tscnFiles) {
  $text = Get-Content -Raw -LiteralPath $f.FullName -ErrorAction SilentlyContinue
  # match lines like: texture = "res://assets/originals/ambulance.png"
  $regex = 'texture\s*=\s*"(res://[^"]+)"'
  [regex]::Matches($text, $regex) | ForEach-Object {
    $resPath = $_.Groups[1].Value
    # candidate physical paths to check (common variants)
    $rel = $resPath -replace '^res://','' -replace '/','\'
    $candidates = @(
      Join-Path $repo $rel,
      Join-Path $repo ("res\" + $rel),
      Join-Path $repo ("assets\" + (Split-Path $rel -Leaf)),
      Join-Path $repo ("assets\originals\" + (Split-Path $rel -Leaf)),
      Join-Path $repo ("res\assets\" + (Split-Path $rel -Leaf))
    ) | Get-Unique
    $found = $false
    foreach($c in $candidates) {
      if (Test-Path $c) { $found = $true; break }
    }
    if (-not $found) {
      $entry = @{ tscn = $f.FullName; texture = $resPath; checked = $candidates }
      $missing += $entry
      Log "MISSING_TEXTURE: $($f.FullName) -> $resPath"
      foreach($c in $candidates) { Log "    looked: $c" }
    }
  }
}
if ($missing.Count -eq 0) { Log "No missing texture references found (by the checks above)." }

# Find duplicate images (assets + res screenshots)
Log "`n=== DUPLICATE IMAGE CHECK (assets & logs screenshots) ==="
$imgCandidates = Get-ChildItem -Path $repo -Recurse -Include *.png,*.jpg,*.jpeg,*.svg -File -ErrorAction SilentlyContinue
# limit to reasonable set (assets, logs, res, scenes)
$imgCandidates = $imgCandidates | Where-Object { $_.FullName -match '\\assets\\' -or $_.FullName -match '\\logs\\' -or $_.FullName -match '\\res\\' -or $_.FullName -match 'main_scene' } 
$hashTable = @{}
foreach($img in $imgCandidates) {
  try {
    $h = (Get-FileHash -Algorithm MD5 -Path $img.FullName).Hash
    if (-not $hashTable.ContainsKey($h)) { $hashTable[$h] = @() }
    $hashTable[$h] += $img.FullName
  } catch { Log "HASH_FAIL: $($img.FullName) -> $_" }
}
$dups = $hashTable.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
if ($dups.Count -eq 0) { Log "No duplicate images detected in scanned areas." } else {
  foreach($d in $dups) {
    Log "DUPLICATES (hash $($d.Key)):"
    foreach($p in $d.Value) { Log "   $p" }
  }
}

# Show top untracked / new files (non-destructive)
Log "`n=== QUICK UNTRACKED / UNCOMMITTED FILES (git) ==="
try {
  & git -C $repo ls-files --others --exclude-standard 2>&1 | ForEach-Object { Log "UNTRACKED: $_" }
  & git -C $repo ls-files -m 2>&1 | ForEach-Object { Log "MODIFIED_TRACKED: $_" }
} catch {
  Log "GIT_LIST_FAILED: $_"
}

# Final summary of key locations still present
Log "`n=== KEY PATHS (exists?) ==="
$checkPaths = @(
  (Join-Path $repo ".godot\imported"),
  (Join-Path $repo ".godot\shader_cache"),
  (Join-Path $repo "godot_temp"),
  (Join-Path $repo "logs"),
  (Join-Path $repo ".ag_work"),
  (Join-Path $repo "Godot.exe.broken_*")
)
foreach($cp in $checkPaths) {
  $found = Get-ChildItem -Path $cp -Recurse -Force -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($found) { Log "PRESENT: $cp" } else { Log "MISSING: $cp" }
}

# CLEANUP SECTION (safe by default)
Log "`n=== CLEANUP ACTIONS (currently $DoCleanup) ==="
Log "Trash backup folder would be: $trashBackup"
if (-not (Test-Path $trashBackup)) { New-Item -ItemType Directory -Path $trashBackup -Force | Out-Null }

$movePatterns = @(
  "$repo\.godot\imported\*.ctex",
  "$repo\.godot\imported\*.md5",
  "$repo\.godot\shader_cache",
  "$repo\godot_temp",
  "$repo\logs",
  "$repo\removed_backup_*",
  "$repo\.ag_work",
  "$repo\Godot.exe.broken_*"
)

if ($DoCleanup) {
  foreach($mp in $movePatterns) {
    try {
      Get-ChildItem -Path $mp -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $dest = Join-Path $trashBackup (Split-Path $_.FullName -NoQualifier -Resolve)
        $destDir = Split-Path $dest -Parent
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Move-Item -LiteralPath $_.FullName -Destination $dest -Force -ErrorAction Stop
        Log "MOVED: $($_.FullName) -> $dest"
      }
    } catch {
      Log "MOVE_FAILED for pattern $mp -> $_"
    }
  }
  Log "CLEANUP DONE. Trash moved to $trashBackup"
} else {
  Log "CLEANUP is disabled. To enable set `\$DoCleanup = \$true` at top of script and re-run."
  Log "If you want to preview moves without executing, set `\$DoCleanup = 'whatif'` and implement the script accordingly."
}

Log "`nREPORT COMPLETE. Report path: $report"
Log "------------------------------------------"
# open report at end for convenience
Write-Host "REPORT GENERATED -> $report"
