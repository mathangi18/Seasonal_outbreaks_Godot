<#
 FULL AUTOMATED SWEDISH ROAD SIGN IMAGE PIPELINE
 ------------------------------------------------
 This script will:

 1. Create working folders:
       C:\temp\driving_csv\
       C:\temp\driving_csv\images_raw\
       C:\temp\driving_csv\images\
 2. Download the Atakua Swedish Road Signs PDF
 3. Extract images using pdfimages (from Poppler)
 4. Convert all extracted files into .jpg using ImageMagick
 5. Rename images into clean standardized filenames:
       sign_priority_road.jpg
       sign_give_way.jpg
       sign_stop.jpg
       sign_speed_30.jpg
       ...
 6. OUTPUT: ready-to-use images for flashcard/CSV generator

 REQUIREMENTS:
   - Poppler installed (provides pdfimages)
   - ImageMagick installed (provides magick)
#>

Set-StrictMode -Version Latest
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ========= CONFIG =========
$baseDir     = "C:\temp\driving_csv"
$rawDir      = Join-Path $baseDir "images_raw"
$outDir      = Join-Path $baseDir "images"
$pdfName     = "swedish_road_signs_atakua.pdf"
$pdfUrl      = "https://atakua.org/w/images/swedish_road_signs_signals_road_markings_and_marking_by_policemen.pdf"
$pdfPath     = Join-Path $baseDir $pdfName
$logPath     = Join-Path $baseDir "signs_pipeline_log.txt"

# ========= CREATE FOLDERS =========
New-Item -ItemType Directory -Force -Path $baseDir | Out-Null
New-Item -ItemType Directory -Force -Path $rawDir | Out-Null
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Remove-Item -Path $logPath -ErrorAction SilentlyContinue

function Log($msg) {
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg"
    $line | Tee-Object -FilePath $logPath -Append
    Write-Host $line
}

Log "========== ROAD SIGN PIPELINE START =========="

# ========= CHECK DEPENDENCIES =========
function Require-Tool($toolName) {
    $exists = Get-Command $toolName -ErrorAction SilentlyContinue
    if (-not $exists) {
        Log "ERROR: '$toolName' not found in PATH. Install it or add to PATH."
        Log "STOPPED."
        exit 1
    } else {
        Log "OK: Found $toolName"
    }
}

Require-Tool "pdfimages"
Require-Tool "magick"

# ========= DOWNLOAD PDF =========
if (Test-Path $pdfPath) {
    Log "PDF already exists: $pdfPath"
} else {
    Log "Downloading PDF..."
    Invoke-WebRequest -Uri $pdfUrl -OutFile $pdfPath -UseBasicParsing -Headers @{ "User-Agent"="PowerShell Script" }
    Log "Downloaded PDF → $pdfPath"
}

# ========= EXTRACT IMAGES =========
Log "Extracting images with pdfimages..."
$pdfimagesOut = Join-Path $rawDir "atakua_extract"
& pdfimages -all $pdfPath $pdfimagesOut
Log "Extracted images to $rawDir"

# ========= CONVERT IMAGES INTO JPG =========
$rawFiles = Get-ChildItem -Path $rawDir -File

if ($rawFiles.Count -eq 0) {
    Log "ERROR: No images extracted. PDF may have contained vector images only."
    exit 1
}

foreach ($f in $rawFiles) {
    $newName = ($f.BaseName + ".jpg")
    $newPath = Join-Path $outDir $newName

    # If file is already jpg/png, convert anyway for consistency
    Log "Converting $($f.Name) → $newName"
    & magick convert $f.FullName -background white -flatten -resize 1500x1500 $newPath
}

Log "Conversion complete. Standardized JPGs saved to $outDir"

# ========= AUTO-RENAME USING SMART SIGN MAPPING =========

$mappings = @(
    @{pattern='priority[_\- ]*road';        name='sign_priority_road'}
    @{pattern='end[_\- ]*priority';         name='sign_end_priority_road'}
    @{pattern='\bgive[_\- ]*way\b';         name='sign_give_way'}
    @{pattern='\bstop\b';                   name='sign_stop'}
    @{pattern='priority[_\- ]*to[_\- ]*the'; name='sign_priority_to_right'}
    @{pattern='roundabout';                 name='sign_roundabout'}
    @{pattern='no[_\- ]*entry';             name='sign_no_entry'}
    @{pattern='speed[_\- ]*(\d{2,3})';      name='sign_speed'}
    @{pattern='end[_\- ]*speed';            name='sign_end_speed_limit'}
    @{pattern='no[_\- ]*overtaking';        name='sign_no_overtaking'}
    @{pattern='end[_\- ]*no[_\- ]*overtaking'; name='sign_end_no_overtaking'}
    @{pattern='pedestrian|crossing';        name='sign_pedestrian_crossing'}
    @{pattern='cycle|bicycle';              name='sign_cyclist_crossing'}
    @{pattern='school';                     name='sign_school_zone'}
    @{pattern='bus[_\- ]*lane';             name='sign_bus_lane'}
    @{pattern='narrow';                     name='sign_road_narrowing'}
    @{pattern='roadwork|work|construction'; name='sign_roadworks'}
    @{pattern='slippery';                   name='sign_slippery_road'}
    @{pattern='animal';                     name='sign_animals_crossing'}
    @{pattern='revers';                     name='sign_reversible_lane'}
    @{pattern='tunnel';                     name='sign_tunnel'}
    @{pattern='no[_\- ]*parking';           name='sign_parking_prohibited'}
    @{pattern='no[_\- ]*stopping';          name='sign_stopping_prohibited'}
    @{pattern='disabled|handicap|wheel';    name='sign_disabled_parking'}
    @{pattern='motorway|end[_\- ]*motorway'; name='sign_motorway'}
)

Log "Renaming JPGs for clean naming..."

$finalFiles = Get-ChildItem -Path $outDir -Filter *.jpg

foreach ($f in $finalFiles) {
    $lower = $f.Name.ToLower()
    $renamed = $false

    foreach ($m in $mappings) {
        if ($lower -match $m.pattern) {
            $base = $m.name

            # Special case: speed limit extraction (speed_30, speed_50...)
            if ($base -eq 'sign_speed') {
                if ($lower -match '(\d{2,3})') {
                    $spd = $matches[1]
                    $base = "sign_speed_$spd"
                } else {
                    $base = "sign_speed_unknown"
                }
            }

            $newName = "$base.jpg"
            $newPath = Join-Path $outDir $newName

            $i=1
            while (Test-Path $newPath) {
                $newPath = Join-Path $outDir ("{0}_{1}.jpg" -f $base, $i)
                $i++
            }

            Rename-Item -Path $f.FullName -NewName (Split-Path $newPath -Leaf)
            Log "Renamed → $(Split-Path $newPath -Leaf)"
            $renamed = $true
            break
        }
    }

    if (-not $renamed) {
        $fallback = "wiki_" + ($f.BaseName -replace '[^0-9A-Za-z\-_]','_') + ".jpg"
        Rename-Item -Path $f.FullName -NewName $fallback
        Log "Fallback rename → $fallback"
    }
}

Log "========== ALL DONE =========="
Log "Final images ready in: $outDir"
Write-Host "Your Swedish road sign image pack is READY 🎉"
