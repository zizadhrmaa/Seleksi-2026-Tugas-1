[CmdletBinding()]
param(
    [string]$PgBin = "C:\Program Files\PostgreSQL\13\bin",
    [string]$HostName = "localhost",
    [int]$Port = 5433,
    [string]$Database = "ndbc",
    [string]$Username = "postgres",
    [switch]$TestIdempotency
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$psql = Join-Path $PgBin "psql.exe"

if (-not (Test-Path -LiteralPath $psql)) {
    throw "psql.exe tidak ditemukan pada: $psql"
}

$sqlFiles = @(
    (Join-Path $scriptDirectory "01_create_warehouse.sql"),
    (Join-Path $scriptDirectory "02_load_warehouse.sql"),
    (Join-Path $scriptDirectory "03_verify_and_analyze.sql")
)

if ($TestIdempotency) {
    $sqlFiles += (Join-Path $scriptDirectory "04_test_idempotency.sql")
}

foreach ($sqlFile in $sqlFiles) {
    if (-not (Test-Path -LiteralPath $sqlFile)) {
        throw "File SQL tidak ditemukan: $sqlFile"
    }
}

function Invoke-PsqlFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    Write-Host ""
    Write-Host "Menjalankan $(Split-Path -Leaf $Path)..."

    & $psql `
        -X `
        -v ON_ERROR_STOP=1 `
        -U $Username `
        -h $HostName `
        -p $Port `
        -d $Database `
        -f $Path

    if ($LASTEXITCODE -ne 0) {
        throw "Eksekusi gagal pada $(Split-Path -Leaf $Path) dengan exit code $LASTEXITCODE."
    }
}

Write-Host "Memeriksa koneksi PostgreSQL..."
& $psql `
    -X `
    -v ON_ERROR_STOP=1 `
    -U $Username `
    -h $HostName `
    -p $Port `
    -d $Database `
    -c "SELECT current_database(), current_user, version();"

if ($LASTEXITCODE -ne 0) {
    throw "Koneksi PostgreSQL gagal dengan exit code $LASTEXITCODE."
}

foreach ($sqlFile in $sqlFiles) {
    Invoke-PsqlFile -Path $sqlFile
}

Write-Host ""
Write-Host "Data warehouse berhasil dibuat, dimuat, dan lolos seluruh assertion wajib."
if (-not $TestIdempotency) {
    Write-Host "Tambahkan -TestIdempotency untuk menjalankan pengujian eksekusi ulang otomatis."
}
