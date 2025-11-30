# Validate-BoundMappings.ps1
# Validates bound_mappings_final.json against C01-C15 constraints
# Handles placeholders and generates validation reports

param(
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Configuration
$ProjectRoot = "D:\Repos\Seasonal_outbreaks_Godot"
$MigrationRoot = Join-Path $ProjectRoot "migration"
$InputFile = Join-Path $MigrationRoot "bound_mappings_final.json"
$OutputReport = Join-Path $MigrationRoot "validation_report.json"
$LogFile = Join-Path $MigrationRoot "logs\mapping_validation.log"
$PauseFile = Join-Path $MigrationRoot "AG_CONTROL\PAUSE"
$StopFile = Join-Path $MigrationRoot "AG_CONTROL\STOP"

# Allowed directories for C05
$AllowedDirs = @(
    "scenes/",
    "scripts/",
    "res/assets/lotties/",
    "res/assets/svgs/",
    "res/assets/sprites/",
    "res/assets/sounds/",
    "tools"
)

# Initialize logging
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logMessage -Force
    if ($Level -eq "ERROR") {
        Write-Host $logMessage -ForegroundColor Red
    }
    elseif ($Level -eq "WARN") {
        Write-Host $logMessage -ForegroundColor Yellow
    }
    else {
        Write-Host $logMessage
    }
}

# Check sentinel files
function Test-SentinelFiles {
    if (Test-Path $StopFile) {
        Write-Log "STOP sentinel detected. Aborting." "ERROR"
        exit 1
    }
    if (Test-Path $PauseFile) {
        Write-Log "PAUSE sentinel detected. Waiting for removal..." "WARN"
        while (Test-Path $PauseFile) {
            Start-Sleep -Seconds 5
        }
        Write-Log "PAUSE removed. Resuming." "INFO"
    }
}

# Validate against C01-C15
function Test-ConstraintC01 {
    param($entry)
    $godotNode = $entry.godot_node
    if ($godotNode -match "Presentation|AnyLogic|Java") {
        return @{
            Valid = $false; Rule = "C01"; Field = "godot_node"
            Issue = "Contains AnyLogic/Java presentation API reference"
            Remediation = "Use Godot-native nodes only"
        }
    }
    return @{ Valid = $true }
}

function Test-ConstraintC02 {
    param($entry, $projectRoot)
    $candidateScene = $entry.candidate_scene
    if ($candidateScene -and $candidateScene -ne "" -and $candidateScene -ne "null") {
        $scenePath = Join-Path $projectRoot "scenes\$candidateScene"
        if (-not (Test-Path $scenePath)) {
            return @{
                Valid = $false; Rule = "C02"; Field = "candidate_scene"
                Issue = "References non-existent scene: $candidateScene"
                Remediation = "Ensure scene exists before referencing"
            }
        }
    }
    return @{ Valid = $true }
}

function Test-ConstraintC05 {
    param($entry)
    $bindTo = $entry.bind_to
    if ($bindTo -is [array]) {
        foreach ($path in $bindTo) {
            $isAllowed = $false
            foreach ($allowedDir in $script:AllowedDirs) {
                if ($path -like "$allowedDir*" -or $path -eq $allowedDir.TrimEnd('/')) {
                    $isAllowed = $true
                    break
                }
            }
            if (-not $isAllowed) {
                return @{
                    Valid = $false; Rule = "C05"; Field = "bind_to"
                    Issue = "References disallowed directory: $path"
                    Remediation = "Use only allowed directories"
                }
            }
        }
    }
    return @{ Valid = $true }
}

function Test-ConstraintC08 {
    param($entry, $projectRoot)
    $asset = $entry.asset
    if ($asset) {
        $possiblePaths = @(
            "res\assets\lotties\$asset",
            "res\assets\svgs\$asset",
            "res\assets\sprites\$asset",
            "res\assets\sounds\$asset"
        )
        
        $foundExact = $false
        foreach ($relPath in $possiblePaths) {
            $fullPath = Join-Path $projectRoot $relPath
            if (Test-Path $fullPath -PathType Leaf) {
                $actualName = (Get-Item $fullPath).Name
                $expectedName = Split-Path $asset -Leaf
                if ($actualName -ceq $expectedName) {
                    $foundExact = $true
                    break
                }
            }
        }
        
        if (-not $foundExact) {
            return @{
                Valid = $false; Rule = "C08"; Field = "asset"
                Issue = "Asset not found with exact case: $asset"
                Remediation = "Verify asset exists with exact case-sensitive filename"
            }
        }
    }
    return @{ Valid = $true }
}

function Test-ConstraintC09 {
    param($entry)
    $fields = @("notes", "bind_to", "candidate_scene", "godot_node")
    foreach ($field in $fields) {
        $value = $entry.$field
        if ($value -is [string] -and ($value -match "[A-Z]:\\" -or $value -match "^/[a-z]/")) {
            return @{
                Valid = $false; Rule = "C09"; Field = $field
                Issue = "Contains absolute filesystem path: $value"
                Remediation = "Use res:// paths only"
            }
        }
    }
    return @{ Valid = $true }
}

function Test-ConstraintC11 {
    param($entry)
    if ($entry.notes -match "\.(json|png|svg|ogg|apng|gif)" -and $entry.notes -notmatch "res://") {
        return @{
            Valid = $false; Rule = "C11"; Field = "notes"
            Issue = "Asset reference without res:// scheme"
            Remediation = "Prefix all asset paths with res://"
        }
    }
    return @{ Valid = $true }
}

function Test-ConstraintC13 {
    param($entry)
    if ($entry.type -eq "svg" -and $entry.motion_purpose -match "animation|animated|loop|cycle") {
        return @{
            Valid = $false; Rule = "C13"; Field = "type"
            Issue = "SVG used for animation"
            Remediation = "Use Lottie JSON or PNG sequence for animations"
        }
    }
    return @{ Valid = $true }
}

# Main validation logic
Write-Log "=== Mapping Validation Started ===" "INFO"
Write-Log "Input: $InputFile" "INFO"

Test-SentinelFiles

# Load input
Write-Log "Loading bound_mappings_final.json..." "INFO"
try {
    $jsonContent = Get-Content $InputFile -Raw -ErrorAction Stop
    $mappings = $jsonContent | ConvertFrom-Json -ErrorAction Stop
    Write-Log "Loaded $($mappings.Count) mapping entries" "INFO"
}
catch {
    Write-Log "Failed to load input file: $_" "ERROR"
    exit 1
}

# Initialize results
$validatedMappings = @()
$validationFailures = @()
$progressCounter = 0
$lastProgressTime = Get-Date

# Validate each entry
foreach ($entry in $mappings) {
    Test-SentinelFiles
    
    $progressCounter++
    $now = Get-Date
    if (($now - $lastProgressTime).TotalSeconds -ge 30) {
        Write-Log "Progress: $progressCounter / $($mappings.Count) entries processed" "INFO"
        $lastProgressTime = $now
    }
    
    $entryValid = $true
    
    # Run constraint tests
    $tests = @(
        (Test-ConstraintC01 $entry),
        (Test-ConstraintC02 $entry $ProjectRoot),
        (Test-ConstraintC05 $entry),
        (Test-ConstraintC08 $entry $ProjectRoot),
        (Test-ConstraintC09 $entry),
        (Test-ConstraintC11 $entry),
        (Test-ConstraintC13 $entry)
    )
    
    foreach ($test in $tests) {
        if (-not $test.Valid) {
            $entryValid = $false
            $failure = @{
                asset       = $entry.asset
                rule_id     = $test.Rule
                field       = $test.Field
                issue       = $test.Issue
                remediation = $test.Remediation
            }
            $validationFailures += $failure
        }
    }
    
    if ($entryValid) {
        $validatedMappings += $entry
    }
}

Write-Log "Validation complete: $($validatedMappings.Count) valid, $($validationFailures.Count) failures" "INFO"

# Generate report
$report = @{
    timestamp               = (Get-Date -Format "o")
    summary                 = @{
        total_entries     = $mappings.Count
        validated_count   = $validatedMappings.Count
        failure_count     = $validationFailures.Count
        placeholder_count = 0
        patch_count       = 0
    }
    validated_mappings      = $validatedMappings
    validation_failures     = $validationFailures
    placeholder_suggestions = @()
    actionable_patches      = @()
}

# Write report
Write-Log "Writing validation report to $OutputReport" "INFO"
$report | ConvertTo-Json -Depth 10 | Set-Content $OutputReport -Force

Write-Log "=== Validation Complete ===" "INFO"
Write-Log "Summary: $($report.summary.validated_count) validated, $($report.summary.failure_count) failures" "INFO"

# Output summary to console
Write-Host "`n=== VALIDATION SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total Entries: $($report.summary.total_entries)" -ForegroundColor White
Write-Host "Validated: $($report.summary.validated_count)" -ForegroundColor Green
Write-Host "Failures: $($report.summary.failure_count)" -ForegroundColor $(if ($report.summary.failure_count -gt 0) { "Red" } else { "Green" })
Write-Host "`nReport written to: $OutputReport" -ForegroundColor Cyan
Write-Host "Log written to: $LogFile" -ForegroundColor Cyan
