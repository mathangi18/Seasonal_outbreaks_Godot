<#
setup-godot-cli.ps1
Single-script setup:
- Add permanent 'godot' alias to PowerShell hosts (pwsh and Windows PowerShell)
- Add Godot folder to User PATH (if not present)
- Set ExecutionPolicy CurrentUser = RemoteSigned
- Reload profiles (where possible)
- Test godot --version (and fallback to direct exe)
#>

param(
    [string]$GodotExe = 'D:\Godot\Godot_v4.5.1-stable_win64.exe\godot_console.exe',
    [switch]$AddToPath = $true,
    [int]$TestTicks = 200
)

function Add-AliasToProfile {
    param(
        [string]$ProfilePath,
        [string]$AliasLine
    )
    if (-not $ProfilePath) { return }

    $profileDir = Split-Path -Parent $ProfilePath
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        Write-Host "Created profile directory: $profileDir"
    }
    if (-not (Test-Path $ProfilePath)) {
        New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
        Write-Host "Created profile file: $ProfilePath"
    }

    $content = ""
    try { $content = Get-Content -Path $ProfilePath -Raw -ErrorAction Stop } catch { $content = "" }

    if ($content -notmatch [regex]::Escape($AliasLine)) {
        Add-Content -Path $ProfilePath -Value "`n# Godot CLI alias`n$AliasLine`n"
        Write-Host "Alias added to profile: $ProfilePath"
    } else {
        Write-Host "Alias already present in profile: $ProfilePath"
    }
}

function Ensure-UserPathContains {
    param([string]$Dir)
    if (-not (Test-Path $Dir)) {
        Write-Warning "Directory does not exist: $Dir"
        return $false
    }

    $curPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $paths = $curPath -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    if ($paths -contains $Dir) {
        Write-Host "User PATH already contains: $Dir"
        return $true
    }

    $newPath = ($paths + $Dir) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Host "Added to User PATH: $Dir"
    return $true
}

# --- start script
Write-Host "=== setup-godot-cli.ps1 START ==="
Write-Host "Using Godot exe path: $GodotExe"
if (-not (Test-Path $GodotExe)) {
    Write-Warning "Warning: Godot exe not found at the provided path. Edit the script parameter -GodotExe to the correct path and re-run."
}

# Build alias line
$aliasLine = "Set-Alias godot `"$GodotExe`""

# 1) Add alias to current host profile ($PROFILE) — this handles pwsh (PowerShell 7) if run in pwsh
try {
    $currentProfile = $PROFILE
    Add-AliasToProfile -ProfilePath $currentProfile -AliasLine $aliasLine
} catch {
    Write-Warning "Could not add alias to current host profile: $($_.Exception.Message)"
}

# 2) Add alias to CurrentUserAllHosts profile (creates cross-host alias)
try {
    $cuAll = $PROFILE.CurrentUserAllHosts
    Add-AliasToProfile -ProfilePath $cuAll -AliasLine $aliasLine
} catch {
    Write-Warning "Could not add alias to CurrentUserAllHosts profile: $($_.Exception.Message)"
}

# 3) Add alias to Windows PowerShell profile (Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1)
try {
    $documents = [Environment]::GetFolderPath('MyDocuments')
    if ($documents) {
        $winPSDir = Join-Path $documents 'WindowsPowerShell'
        $winPSProfile = Join-Path $winPSDir 'Microsoft.PowerShell_profile.ps1'
        Add-AliasToProfile -ProfilePath $winPSProfile -AliasLine $aliasLine
    }
} catch {
    Write-Warning "Could not add alias to Windows PowerShell profile: $($_.Exception.Message)"
}

# 4) Set ExecutionPolicy for CurrentUser (RemoteSigned) — safe and per-user
try {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction Stop
    Write-Host "Set ExecutionPolicy for CurrentUser to RemoteSigned."
} catch {
    Write-Warning "Could not set ExecutionPolicy automatically: $($_.Exception.Message). You may need to run as admin or set manually."
}

# 5) Optionally add Godot folder to User PATH
if ($AddToPath -and (Test-Path $GodotExe)) {
    $godotDir = Split-Path -Parent $GodotExe
    Ensure-UserPathContains -Dir $godotDir | Out-Null
    Write-Host "Note: PATH change takes effect in new shells. To use in this session, you can call the exe directly as fallback."
}

# 6) Reload profiles where possible
# Attempt to dot-source the current host profile and the per-user profile
try {
    if (Test-Path $PROFILE) { . $PROFILE; Write-Host "Reloaded profile: $PROFILE" }
    if ($cuAll -and (Test-Path $cuAll)) { . $cuAll; Write-Host "Reloaded profile: $cuAll" }
    if ($winPSProfile -and (Test-Path $winPSProfile)) { . $winPSProfile; Write-Host "Reloaded Windows PowerShell profile: $winPSProfile" }
} catch {
    Write-Warning "Could not reload some profile(s) automatically: $($_.Exception.Message)"
}

# 7) Test the alias now
Write-Host "`nTesting godot alias..."
$ok = $false
try {
    & godot --version 2>$null | Out-Null
    Write-Host "Command 'godot --version' ran successfully in this shell."
    & godot --version
    $ok = $true
} catch {
    Write-Warning "Alias test failed in this session. Trying direct exe path..."
    try {
        & $GodotExe --version
        Write-Host "Direct exe test succeeded:"
        & $GodotExe --version
        $ok = $true
    } catch {
        Write-Error "Direct exe test also failed. Please verify the path: $GodotExe"
    }
}

# 8) Final notes and AG instructions
Write-Host "`n=== DONE ==="
if ($ok) {
    Write-Host "Godot CLI appears functional. If your AG runs locally, it can now use 'godot' command."
    Write-Host "To request AG re-run headless validation, send the following instruction to AG (exact):"
    Write-Host ""
    Write-Host "AG: Godot CLI is installed and available as 'godot'. Please re-run:"
    Write-Host "  godot --version"
    Write-Host "  godot --headless --path . --script misc/validate_project.gd"
    Write-Host "  godot --headless --path . --script misc/run_headless.gd --ticks=200"
    Write-Host ""
} else {
    Write-Warning "Godot CLI not verified. Fix the exe path or run the direct exe with full path as a fallback."
}

# 9) Provide local authoritative spec path for AG if needed
$specLocalPath = 'file:///mnt/data/FEATURES_GODOT_FULL.txt.txt'
Write-Host "`nAuthoritative Godot spec file path (local URL): $specLocalPath"

Write-Host "=== setup-godot-cli.ps1 END ==="
