[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$errors = New-Object System.Collections.Generic.List[string]

$requiredFiles = @(
    "design\erd.dot",
    "design\erd.png",
    "design\relational_diagram.dot",
    "design\relational_diagram.png",
    "design\data_warehouse_design.md",
    "src\01_create_warehouse.sql",
    "src\02_load_warehouse.sql",
    "src\03_verify_and_analyze.sql",
    "src\04_test_idempotency.sql",
    "src\run_warehouse.ps1",
    "export\export_warehouse.ps1",
    "export\restore_warehouse.ps1",
    "export\verify_restored_warehouse.sql"
)

foreach ($relativePath in $requiredFiles) {
    $fullPath = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        $errors.Add("File wajib tidak ditemukan: $relativePath")
    }
}

$exportDirectory = Join-Path $root "export\database_export"
$sqlExports = @()
if (Test-Path -LiteralPath $exportDirectory -PathType Container) {
    $sqlExports = @(Get-ChildItem -LiteralPath $exportDirectory -File -Filter "*.sql")
}
if ($sqlExports.Count -lt 4) {
    $errors.Add("Export aktual belum lengkap. Diperlukan minimal empat file .sql pada export\database_export.")
}
foreach ($sqlExport in $sqlExports) {
    if ($sqlExport.Length -eq 0) {
        $errors.Add("File export kosong: export\database_export\$($sqlExport.Name)")
    }
}

$manifest = Join-Path $exportDirectory "export_manifest.txt"
if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
    $errors.Add("export_manifest.txt belum tersedia.")
}

$requiredScreenshots = @(
    "01_tables_and_counts.png",
    "02_select_from_where.png",
    "03_daily_analytics.png",
    "04_scrape_run_analytics.png",
    "05_data_quality.png",
    "06_export_restore.png"
)

foreach ($fileName in $requiredScreenshots) {
    $path = Join-Path (Join-Path $root "screenshots") $fileName
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $errors.Add("Screenshot wajib belum tersedia: screenshots\$fileName")
    } elseif ((Get-Item -LiteralPath $path).Length -lt 10KB) {
        $errors.Add("Screenshot terlalu kecil atau kemungkinan placeholder: screenshots\$fileName")
    }
}

if (Test-Path -LiteralPath (Join-Path $root "screenshot") -PathType Container) {
    $errors.Add("Folder lama 'screenshot' masih ada. Gunakan hanya folder 'screenshots'.")
}

if ($errors.Count -gt 0) {
    Write-Host "SUBMISSION NOT READY" -ForegroundColor Red
    foreach ($item in $errors) {
        Write-Host "- $item" -ForegroundColor Red
    }
    exit 1
}

Write-Host "SUBMISSION READY" -ForegroundColor Green
Write-Host "Seluruh file desain, source, export, manifest, dan screenshot wajib tersedia."
