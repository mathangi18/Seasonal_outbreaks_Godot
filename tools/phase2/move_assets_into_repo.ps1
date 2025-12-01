param(
  [string]$Repo = "D:\Repos\Seasonal_outbreaks_Godot",
  [string]$ScenesRel = "phase2_output\scenes",
  [string]$RepoAssetsRel = "project_assets\phase2",
  [string]$LogRel = "phase2_output\logs"
)

$scenesDir = Join-Path $Repo $ScenesRel
$repoAssetsDir = Join-Path $Repo $RepoAssetsRel
$logDir = Join-Path $Repo $LogRel
New-Item -ItemType Directory -Force -Path $repoAssetsDir, $logDir | Out-Null

$time = (Get-Date).ToString("yyyyMMdd_HHmmss")
$log = Join-Path $logDir ("move_assets_into_repo_run_$time.log")
function L { param($s) ("$(Get-Date -Format o)`t$s") | Out-File -FilePath $log -Append -Encoding UTF8; Write-Output $s }

if (-not (Test-Path $scenesDir)) { L "ERROR: scenes dir missing: $scenesDir"; exit 1 }
$tscns = Get-ChildItem -Path $scenesDir -Filter '*.tscn' -File -ErrorAction Stop
if ($tscns.Count -eq 0) { L "ERROR: no .tscn files found in $scenesDir"; exit 2 }

# collect ext_resource paths (first capturing group)
$refs = @()
foreach ($f in $tscns) {
  $txt = Get-Content -Raw -LiteralPath $f.FullName
  $matches = [regex]::Matches($txt, '^\[ext_resource\s+path\s*=\s*"(.*?)"', [System.Text.RegularExpressions.RegexOptions]::Multiline)
  foreach ($m in $matches) { $refs += [PSCustomObject]@{ Scene = $f.FullName; Path = $m.Groups[1].Value } }
}
if ($refs.Count -eq 0) { L "ERROR: no ext_resource refs found"; exit 3 }

# resolve refs to source files
$resolved = @{}
$missing = @()
foreach ($r in $refs) {
  $p = $r.Path
  $src = $null
  if ($p -match '^file:///') {
    $trim = $p -replace '^file:///', ''
    $win = $trim -replace '/','\'
    if (Test-Path $win) { $src = $win }
  } elseif ($p -match '^res://') {
    # already repo-local -> convert to repo path
    $rel = $p -replace '^res://',''
    $cand = Join-Path $Repo $rel
    if (Test-Path $cand) { $src = $cand }
  } else {
    $candidate = Join-Path $scenesDir $p
    if (Test-Path $candidate) { $src = $candidate } else {
      $candidate2 = Join-Path 'D:\seasonal_outbreak_assets' $p
      if (Test-Path $candidate2) { $src = $candidate2 }
    }
  }
  if ($src) { $resolved[$p] = $src } else { $missing += [PSCustomObject]@{ Scene = $r.Scene; Ref = $p } }
}

if ($missing.Count -gt 0) {
  L "ABORT: unresolved asset references (no copies performed):"
  foreach ($m in $missing) { L " - Scene: $($m.Scene)  -> missing ref: $($m.Ref)" }
  exit 4
}

# copy unique source files into repoAssetsDir (deterministic naming)
$copyMap = @{}  # src fullpath -> dest filename
foreach ($kv in $resolved.GetEnumerator()) {
  $src = $kv.Value
  if ($copyMap.ContainsKey($src)) { continue }
  $base = [IO.Path]::GetFileName($src)
  $dest = Join-Path $repoAssetsDir $base
  $n = 1
  while ((Test-Path $dest) -and -not ((Get-Item $dest).FullName -eq (Get-Item $src).FullName)) {
    $nameOnly = [IO.Path]::GetFileNameWithoutExtension($base)
    $ext = [IO.Path]::GetExtension($base)
    $dest = Join-Path $repoAssetsDir ("$nameOnly`_$n$ext")
    $n++
  }
  Copy-Item -LiteralPath $src -Destination $dest -Force
  (Get-Item $dest).Attributes = 'Normal'
  $copyMap[$src] = (Split-Path $dest -Leaf)
  L "COPIED: $src -> $dest"
}

# update scenes to use res://project_assets/phase2/<destfile>
foreach ($f in $tscns) {
  $content = Get-Content -Raw -LiteralPath $f.FullName
  $changed = $false
  $new = [regex]::Replace($content, '^\[ext_resource\s+path\s*=\s*"(.*?)"', {
    param($m)
    $old = $m.Groups[1].Value
    $srcResolved = $resolved[$old]
    $destFile = $copyMap[$srcResolved]
    $newPath = "res://project_assets/phase2/$destFile"
    $changed = $true
    return "[ext_resource path=""$newPath"""
  }, [System.Text.RegularExpressions.RegexOptions]::Multiline)
  if ($changed) {
    $tmp = $f.FullName + '.tmp'
    $new | Set-Content -LiteralPath $tmp -Encoding UTF8
    if (Test-Path $f.FullName) { Remove-Item -LiteralPath $f.FullName -Force }
    Move-Item -Path $tmp -Destination $f.FullName -Force
    (Get-Item $f.FullName).Attributes = 'Normal'
    L "UPDATED: $($f.FullName) -> now uses res://project_assets/phase2/..."
  } else {
    L "NOCHANGE: $($f.FullName)"
  }
}

L "SUCCESS: assets copied into $repoAssetsDir and $($tscns.Count) scenes updated. Log: $log"
