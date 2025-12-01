param(
  [string]$UrlsFile = "D:\Repos\Seasonal_outbreaks_Godot\dataset\urls.txt",
  [string]$FetcherScript = "D:\Repos\Seasonal_outbreaks_Godot\dataset\safe_fetcher.py",
  [string]$OutFolder = "D:\seasonal_outbreak_assets\raw_downloads",
  [string]$PythonExe = "python",
  [string]$ZipPath = "D:\seasonal_outbreak_assets\raw_downloads.zip"
)

Set-StrictMode -Version Latest

if (-not (Test-Path $FetcherScript)) { Write-Error "safe_fetcher.py missing"; exit 1 }
if (-not (Test-Path $UrlsFile)) { Write-Error "urls.txt missing"; exit 1 }

if (-not (Test-Path $OutFolder)) { New-Item -ItemType Directory -Path $OutFolder | Out-Null }

Write-Host "Running Python fetcher..."
$proc = Start-Process -FilePath $PythonExe `
    -ArgumentList "`"$FetcherScript`" `"$UrlsFile`" `"$OutFolder`"" `
    -NoNewWindow -PassThru -Wait `
    -RedirectStandardOutput "$OutFolder\stdout.txt" `
    -RedirectStandardError "$OutFolder\stderr.txt"

if ($proc.ExitCode -ne 0) {
    Write-Host "Fetcher finished with errors." -ForegroundColor Red
} else {
    Write-Host "Fetcher completed." -ForegroundColor Green
}

if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($OutFolder, $ZipPath)

Write-Host "Done. Zip ready at: $ZipPath" -ForegroundColor Cyan
