# repair_files.ps1
$ErrorActionPreference = "Stop"
$repo = "D:\Repos\Seasonal_outbreaks_Godot"
Set-Location $repo

# 1. CLEANUP
Write-Host "Clearing caches..."
Remove-Item -Recurse -Force .\.godot -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\.import -ErrorAction SilentlyContinue
Get-ChildItem -Recurse -Filter "*.uid" | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem -Recurse -Filter "*.import" | Remove-Item -Force -ErrorAction SilentlyContinue

# 2. RE-ENCODE
Write-Host "Re-encoding text files..."
$exts = @("*.gd", "*.tscn", "*.cfg", "*.txt", "*.md")
foreach ($e in $exts) {
    Get-ChildItem -Path $repo -Include $e -Recurse -File | ForEach-Object {
        $path = $_.FullName
        try {
            $bytes = [System.IO.File]::ReadAllBytes($path)
            $text = [System.Text.Encoding]::UTF8.GetString($bytes)
            if ($text -match "`uFFFD") { $text = [System.Text.Encoding]::Default.GetString($bytes) }
            [System.IO.File]::WriteAllText($path, $text, [System.Text.Encoding]::UTF8)
        }
        catch {}
    }
}

# 3. ASSETS
Write-Host "Restoring assets..."
$png_b64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII="
$bytes = [Convert]::FromBase64String($png_b64)
$paths = @("res\assets\patient.png", "res\assets\facility.png", "res\assets\ambulance.png", "res\res\assets\patient.png", "res\res\assets\facility.png", "res\res\assets\ambulance.png")
foreach ($p in $paths) {
    $dir = Split-Path $p -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllBytes($p, $bytes)
}

# 4. PATHS
Write-Host "Normalizing paths..."
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

# 5. AUTOLOADS
Write-Host "Fixing Autoloads..."
$proj = Get-Content "project.godot" -Raw
$proj = $proj -replace 'AudioManager=".*?"', 'AudioManager="*res://res/scripts/AudioManager.gd"'
$proj = $proj -replace 'UIScale=".*?"', 'UIScale="*res://misc/util/ui_scale.gd"'
Set-Content "project.godot" -Value $proj -Encoding UTF8 -Force

Write-Host "File repair complete."
