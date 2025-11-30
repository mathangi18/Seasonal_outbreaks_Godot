# PrereqCheck.ps1
# Runs all prerequisite checks for Seasonal_outbreaks_Godot TEST PHASE automation

$ErrorActionPreference = "Continue"
$ProjectRoot = "D:\Repos\Seasonal_outbreaks_Godot"
$OutputFile = Join-Path $ProjectRoot "migration\action_patches\test_reports\prereq_check.json"

# Initialize results
$results = @{
    timestamp = (Get-Date -Format "o")
    prereq_ok = $true
    checks    = @{
        git                = @{}
        godot              = @{}
        powershell         = @{}
        ffmpeg             = @{}
        imagemagick        = @{}
        node               = @{}
        npm                = @{}
        playwright_package = @{}
        ag_cli             = @{}
        fs_write           = @{}
        git_remote         = @{}
    }
    notes     = @()
}

# Helper function to run command and capture output
function Invoke-CheckCommand {
    param(
        [string]$Command,
        [string[]]$Arguments = @()
    )
    
    try {
        $output = & $Command $Arguments 2>&1
        $exitCode = $LASTEXITCODE
        return @{
            stdout = ($output | Where-Object { $_ -is [string] }) -join "`n"
            stderr = ""
            code   = if ($null -eq $exitCode) { 0 } else { $exitCode }
        }
    }
    catch {
        return @{
            stdout = ""
            stderr = $_.Exception.Message
            code   = 1
        }
    }
}

# 1. Git check
Write-Host "Checking Git..."
$gitResult = Invoke-CheckCommand "git" @("--version")
$results.checks.git = @{
    ok     = ($gitResult.code -eq 0 -and $gitResult.stdout -match "git version")
    cmd    = "git --version"
    stdout = $gitResult.stdout
    stderr = $gitResult.stderr
    code   = $gitResult.code
}
if (-not $results.checks.git.ok) {
    $results.prereq_ok = $false
    $results.notes += "Install Git: winget install --id Git.Git -e --source winget"
}

# 2. Godot check
Write-Host "Checking Godot..."
$godotPaths = @()
$godotFound = $null
$godotVersion = ""

# Check environment variable
if ($env:GODOT_EXE) {
    $godotPaths += $env:GODOT_EXE
}

# Check default paths
$godotPaths += "C:\Program Files\Godot\Godot.exe"

# Check for versioned Godot executables
$godotDir = "C:\Program Files\Godot"
if (Test-Path $godotDir) {
    $versionedExes = Get-ChildItem -Path $godotDir -Filter "Godot_v*.exe" -ErrorAction SilentlyContinue
    foreach ($exe in $versionedExes) {
        $godotPaths += $exe.FullName
    }
}

# Try godot in PATH
$godotPaths += "godot"

foreach ($path in $godotPaths) {
    try {
        $testResult = Invoke-CheckCommand $path @("--version")
        if ($testResult.code -eq 0 -and ($testResult.stdout -match "Godot Engine v" -or $testResult.stdout -match "Godot")) {
            $godotFound = $path
            $godotVersion = $testResult.stdout
            break
        }
    }
    catch {
        continue
    }
}

$results.checks.godot = @{
    ok           = ($null -ne $godotFound)
    path_checked = $godotPaths
    chosen       = $godotFound
    stdout       = $godotVersion
    stderr       = ""
    code         = if ($godotFound) { 0 } else { 1 }
    version      = $godotVersion
}

if (-not $results.checks.godot.ok) {
    $results.prereq_ok = $false
    $results.notes += "Install Godot: Download from https://godotengine.org/ or use winget/choco. Set GODOT_EXE environment variable if custom path."
}

# 3. PowerShell check
Write-Host "Checking PowerShell..."
$pwshResult = Invoke-CheckCommand "pwsh" @("--version")
if ($pwshResult.code -ne 0) {
    $pwshResult = Invoke-CheckCommand "powershell.exe" @("-Command", "`$PSVersionTable.PSVersion")
}

$results.checks.powershell = @{
    ok     = ($pwshResult.code -eq 0)
    stdout = $pwshResult.stdout
    stderr = $pwshResult.stderr
    code   = $pwshResult.code
}

if (-not $results.checks.powershell.ok) {
    $results.prereq_ok = $false
    $results.notes += "Install PowerShell Core (pwsh) or use built-in Windows PowerShell."
}

# 4. ffmpeg check
Write-Host "Checking ffmpeg..."
$ffmpegResult = Invoke-CheckCommand "ffmpeg" @("-version")
$results.checks.ffmpeg = @{
    ok     = ($ffmpegResult.code -eq 0 -and $ffmpegResult.stdout -match "ffmpeg version")
    stdout = $ffmpegResult.stdout
    stderr = $ffmpegResult.stderr
    code   = $ffmpegResult.code
}

if (-not $results.checks.ffmpeg.ok) {
    $results.prereq_ok = $false
    $results.notes += "Install ffmpeg: winget install -e --id Gyan.FFmpeg"
}

# 5. ImageMagick check
Write-Host "Checking ImageMagick..."
$magickResult = Invoke-CheckCommand "magick" @("-version")
$results.checks.imagemagick = @{
    ok     = ($magickResult.code -eq 0 -and $magickResult.stdout -match "ImageMagick")
    stdout = $magickResult.stdout
    stderr = $magickResult.stderr
    code   = $magickResult.code
}

if (-not $results.checks.imagemagick.ok) {
    $results.prereq_ok = $false
    $results.notes += "Install ImageMagick: https://imagemagick.org and add magick to PATH."
}

# 6. Node check
Write-Host "Checking Node.js..."
$nodeResult = Invoke-CheckCommand "node" @("-v")
$results.checks.node = @{
    ok     = ($nodeResult.code -eq 0)
    stdout = $nodeResult.stdout
    stderr = $nodeResult.stderr
    code   = $nodeResult.code
}

if (-not $results.checks.node.ok) {
    $results.notes += "Install Node.js (optional): winget install OpenJS.NodeJS.LTS"
}

# 7. npm check
Write-Host "Checking npm..."
$npmResult = Invoke-CheckCommand "npm" @("-v")
$results.checks.npm = @{
    ok     = ($npmResult.code -eq 0)
    stdout = $npmResult.stdout
    stderr = $npmResult.stderr
    code   = $npmResult.code
}

if (-not $results.checks.npm.ok) {
    $results.notes += "Install npm (optional): comes with Node.js"
}

# 8. Playwright package check
Write-Host "Checking Playwright packages..."
$playwrightOk = $false
$playwrightNote = "missing"
$playwrightStdout = ""

if ($results.checks.node.ok -and $results.checks.npm.ok) {
    $nodeModulesPath = Join-Path $ProjectRoot "node_modules\@playwright\test"
    $packageJsonPath = Join-Path $ProjectRoot "package.json"
    
    if (Test-Path $nodeModulesPath) {
        $playwrightOk = $true
        $playwrightNote = "installed"
        $playwrightStdout = "Found @playwright/test in node_modules"
    }
    elseif (Test-Path $packageJsonPath) {
        $packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
        if ($packageJson.dependencies.'@playwright/test' -or $packageJson.devDependencies.'@playwright/test') {
            # Try to install
            Write-Host "Attempting to install Playwright..."
            $installResult = Invoke-CheckCommand "npm" @("i", "--no-audit", "--no-fund", "@playwright/test")
            if ($installResult.code -eq 0) {
                $playwrightOk = $true
                $playwrightNote = "installed"
                $playwrightStdout = $installResult.stdout
            }
            else {
                $playwrightNote = "install_failed"
                $playwrightStdout = $installResult.stdout + "`n" + $installResult.stderr
            }
        }
    }
}

$results.checks.playwright_package = @{
    ok     = $playwrightOk
    note   = $playwrightNote
    stdout = $playwrightStdout
}

if (-not $playwrightOk) {
    $results.notes += "Install Playwright (optional): npm i --no-audit --no-fund @playwright/test"
}

# 9. AG CLI check
Write-Host "Checking AG CLI..."
$agResult = Invoke-CheckCommand "ag" @("--version")
$results.checks.ag_cli = @{
    ok     = ($agResult.code -eq 0)
    stdout = $agResult.stdout
}

if (-not $results.checks.ag_cli.ok) {
    $results.notes += "AG CLI not found (optional)"
}

# 10. Filesystem write check
Write-Host "Checking filesystem write permissions..."
$testFile = Join-Path $ProjectRoot "migration\action_patches\.prereq_test_write"
$fsWriteOk = $false
$fsWriteStderr = ""

try {
    "test" | Out-File -FilePath $testFile -Force
    if (Test-Path $testFile) {
        Remove-Item $testFile -Force
        $fsWriteOk = $true
    }
}
catch {
    $fsWriteStderr = $_.Exception.Message
}

$results.checks.fs_write = @{
    ok        = $fsWriteOk
    test_file = "migration\action_patches\.prereq_test_write"
    stderr    = $fsWriteStderr
}

if (-not $fsWriteOk) {
    $results.prereq_ok = $false
    $results.notes += "Ensure write access to repo path or adjust directory ACLs."
}

# 11. Git remote check
Write-Host "Checking git remote..."
$remotePresent = $false
$remoteReachable = $false
$remoteStdout = ""

try {
    $remoteUrl = & git remote get-url origin 2>&1
    if ($LASTEXITCODE -eq 0) {
        $remotePresent = $true
        $remoteStdout = $remoteUrl
        
        # Try ls-remote
        $lsRemoteResult = & git ls-remote --exit-code origin HEAD 2>&1
        if ($LASTEXITCODE -eq 0) {
            $remoteReachable = $true
        }
    }
}
catch {
    # No remote configured
}

$results.checks.git_remote = @{
    present   = $remotePresent
    reachable = $remoteReachable
    stdout    = $remoteStdout
}

if ($remotePresent -and -not $remoteReachable) {
    $results.notes += "Git remote present but not reachable (optional for local testing)"
}

# Write results
Write-Host "Writing results to $OutputFile..."
$results | ConvertTo-Json -Depth 10 | Set-Content $OutputFile -Force

# Output summary
Write-Host "`n=== PREREQUISITE CHECK RESULTS ===" -ForegroundColor Cyan
Write-Host "Output file: $OutputFile" -ForegroundColor White
if ($results.prereq_ok) {
    Write-Host "PREREQ CHECK: OK" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "PREREQ CHECK: FAIL - see $OutputFile" -ForegroundColor Red
    Write-Host "`nRemediation hints:" -ForegroundColor Yellow
    foreach ($note in $results.notes) {
        Write-Host "  - $note" -ForegroundColor Yellow
    }
    exit 1
}
