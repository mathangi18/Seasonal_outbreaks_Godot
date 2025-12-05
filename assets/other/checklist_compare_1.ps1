param(
  [Parameter(Mandatory=$true)][string]$Repo,
  [string]$ChecklistOut = "$env:TEMP\checklist_report.csv"
)

$checklist = @(
  "project.godot",
  "scenes\Main.tscn",
  "scenes\Simulation.tscn",
  "scenes\Patient.tscn",
  "scenes\Facility.tscn",
  "scenes\HUD.tscn",
  "scenes\manifest.tscn",
  "scripts\Main.gd",
  "scripts\SimulationEngine.gd",
  "scripts\Patient.gd",
  "scripts\Facility.gd",
  "scripts\HUD.gd",
  "scripts\logger.gd",
  "scripts\AudioManager.gd",
  "scripts\CameraController.gd",
  "misc\run_headless.gd",
  "misc\util\ui_scale.gd"
)

$placeholderTokens = @(
  '^\s*pass\s*$',
  'AUTO_PLACEHOLDER_DETECTED',
  'TODO\b',
  'FIXME\b'
)

$results = @()

function Test-RepoFile([string]$rel) {
  $full = Join-Path -Path $Repo -ChildPath $rel
  return @{
    Relative = $rel
    FullPath = $full
    Exists = (Test-Path $full)
  }
}

foreach ($item in $checklist) {
  $r = Test-RepoFile $item
  $r.PlaceholderHits = @()
  if ($r.Exists -and $item -like '*.gd') {
    try {
      $content = Get-Content -LiteralPath $r.FullPath -Raw -ErrorAction Stop
      foreach ($tok in $placeholderTokens) {
        if ($content -match $tok) {
          $r.PlaceholderHits += $tok
        }
      }
    } catch {
      $r.Error = $_.Exception.Message
    }
  }
  $results += (New-Object PSObject -Property $r)
}

$gdFiles = Get-ChildItem -Path $Repo -Recurse -Filter '*.gd' -ErrorAction SilentlyContinue
foreach ($f in $gdFiles) {
  $raw = $null
  try { $raw = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop } catch { $raw = $null }
  if ($null -ne $raw) {
    $hits = @()
    foreach ($tok in $placeholderTokens) {
      if ($raw -match $tok) { $hits += $tok }
    }
    if ($hits.Count -gt 0) {
      $results += [PSCustomObject]@{
        Relative = ($f.FullName -replace [regex]::Escape($Repo+"\"),"")
        FullPath = $f.FullName
        Exists = $true
        PlaceholderHits = $hits -join ';'
        Error = $null
      }
    }
  }
}

# Safe, explicit Sort-Object using property objects to avoid parser ambiguity
$results | Select-Object Relative,FullPath,Exists,PlaceholderHits,Error |
  Sort-Object -Property (@{Expression={$_.Exists};Descending=$true}, @{Expression={$_.Relative};Descending=$false}) |
  Export-Csv -Path $ChecklistOut -NoTypeInformation -Force

Write-Output "WROTE: $ChecklistOut"
Write-Output ("MISSING: " + ($results | Where-Object { -not $_.Exists } | Measure-Object).Count)
Write-Output ("PLACEHOLDER_HITS: " + ($results | Where-Object { $_.PlaceholderHits -and $_.PlaceholderHits -ne '' } | Measure-Object).Count)
