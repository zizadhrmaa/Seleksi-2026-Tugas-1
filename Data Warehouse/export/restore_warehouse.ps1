[CmdletBinding()]
param(
    [string]$PgBin = "C:\Program Files\PostgreSQL\13\bin",
    [string]$HostName = "localhost",
    [int]$Port = 5433,
    [string]$Database = "ndbc_dw_restore_test",
    [string]$Username = "postgres",
    [string]$InputDirectory = ".\database_export",
    [switch]$RecreateDatabase
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$resolvedInputDirectory = if ([System.IO.Path]::IsPathRooted($InputDirectory)) {
    [System.IO.Path]::GetFullPath($InputDirectory)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $scriptDirectory $InputDirectory))
}

$psql = Join-Path $PgBin "psql.exe"
if (-not (Test-Path -LiteralPath $psql)) {
    throw "psql.exe tidak ditemukan pada: $psql"
}

if (-not (Test-Path -LiteralPath $resolvedInputDirectory)) {
    throw "Folder input tidak ditemukan: $resolvedInputDirectory"
}

$sqlFiles = @(Get-ChildItem -LiteralPath $resolvedInputDirectory -File -Filter "*.sql" | Sort-Object Name)
if ($sqlFiles.Count -lt 4) {
    throw "File export tidak lengkap. Minimal dibutuhkan pre-data, data, sequence, dan post-data."
}

$manifestPath = Join-Path $resolvedInputDirectory "export_manifest.txt"
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Manifest export tidak ditemukan: $manifestPath"
}

$verificationSql = Join-Path $scriptDirectory "verify_restored_warehouse.sql"
if (-not (Test-Path -LiteralPath $verificationSql -PathType Leaf)) {
    throw "Script verifikasi restore tidak ditemukan: $verificationSql"
}

function Invoke-PsqlCommand {
    param(
        [Parameter(Mandatory = $true)][string]$TargetDatabase,
        [Parameter(Mandatory = $true)][string]$Sql,
        [Parameter(Mandatory = $true)][string]$Description
    )

    & $psql -X -v ON_ERROR_STOP=1 -U $Username -h $HostName -p $Port -d $TargetDatabase -c $Sql
    if ($LASTEXITCODE -ne 0) {
        throw "$Description gagal dengan exit code $LASTEXITCODE."
    }
}

function Invoke-ScalarQuery {
    param([Parameter(Mandatory = $true)][string]$Sql)

    $output = & $psql -X -v ON_ERROR_STOP=1 -A -t -U $Username -h $HostName -p $Port -d $Database -c $Sql
    if ($LASTEXITCODE -ne 0) {
        throw "Query perbandingan hasil restore gagal dengan exit code $LASTEXITCODE."
    }

    return [int64](($output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Last 1).Trim())
}

if ($RecreateDatabase) {
    $safeLiteralDatabase = $Database.Replace("'", "''")
    Invoke-PsqlCommand `
        -TargetDatabase "postgres" `
        -Sql "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$safeLiteralDatabase' AND pid <> pg_backend_pid();" `
        -Description "Menghentikan koneksi database target"

    $safeIdentifierDatabase = $Database.Replace('"', '""')
    Invoke-PsqlCommand `
        -TargetDatabase "postgres" `
        -Sql "DROP DATABASE IF EXISTS `"$safeIdentifierDatabase`";" `
        -Description "Menghapus database target"

    Invoke-PsqlCommand `
        -TargetDatabase "postgres" `
        -Sql "CREATE DATABASE `"$safeIdentifierDatabase`";" `
        -Description "Membuat database target"
}

$tempCombinedFile = Join-Path $resolvedInputDirectory ".warehouse_restore_combined.tmp.sql"
$outputStream = [System.IO.File]::Open(
    $tempCombinedFile,
    [System.IO.FileMode]::Create,
    [System.IO.FileAccess]::Write,
    [System.IO.FileShare]::None
)

try {
    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    $headerBytes = $utf8WithoutBom.GetBytes("\set ON_ERROR_STOP on`n")
    $outputStream.Write($headerBytes, 0, $headerBytes.Length)

    foreach ($sqlFile in $sqlFiles) {
        Write-Host "Menyiapkan $($sqlFile.Name)..."
        $inputStream = [System.IO.File]::OpenRead($sqlFile.FullName)
        try {
            $inputStream.CopyTo($outputStream)
            $separatorBytes = $utf8WithoutBom.GetBytes("`n")
            $outputStream.Write($separatorBytes, 0, $separatorBytes.Length)
        }
        finally {
            $inputStream.Dispose()
        }
    }
}
finally {
    $outputStream.Dispose()
}

try {
    Write-Host "Memulihkan data warehouse dalam satu sesi psql..."
    & $psql -X -v ON_ERROR_STOP=1 -U $Username -h $HostName -p $Port -d $Database -f $tempCombinedFile
    if ($LASTEXITCODE -ne 0) {
        throw "Restore data warehouse gagal dengan exit code $LASTEXITCODE."
    }
}
finally {
    Remove-Item -LiteralPath $tempCombinedFile -Force -ErrorAction SilentlyContinue
}

$manifest = @{}
Get-Content -LiteralPath $manifestPath | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        $manifest[$matches[1]] = $matches[2]
    }
}

$comparisons = @(
    @{ Name = "DimDateRows"; Sql = "SELECT COUNT(*) FROM ndbc_dw.dim_date;" },
    @{ Name = "DimTimeRows"; Sql = "SELECT COUNT(*) FROM ndbc_dw.dim_time;" },
    @{ Name = "DimStationRows"; Sql = "SELECT COUNT(*) FROM ndbc_dw.dim_station;" },
    @{ Name = "DimScrapeRunRows"; Sql = "SELECT COUNT(*) FROM ndbc_dw.dim_scrape_run;" },
    @{ Name = "FactScrapeRunRows"; Sql = "SELECT COUNT(*) FROM ndbc_dw.fact_scrape_run;" },
    @{ Name = "FactObservationRows"; Sql = "SELECT COUNT(*) FROM ndbc_dw.fact_observation;" },
    @{ Name = "EtlBatchRows"; Sql = "SELECT COUNT(*) FROM ndbc_dw.etl_batch;" }
)

foreach ($comparison in $comparisons) {
    if (-not $manifest.ContainsKey($comparison.Name)) {
        throw "Manifest tidak mempunyai nilai $($comparison.Name). Buat ulang export dengan script terbaru."
    }

    $expected = [int64]$manifest[$comparison.Name]
    $actual = Invoke-ScalarQuery -Sql $comparison.Sql
    if ($actual -ne $expected) {
        throw "Jumlah $($comparison.Name) hasil restore tidak sama. actual=$actual expected=$expected"
    }

    Write-Host "$($comparison.Name): PASS ($actual)"
}

$verificationOutput = Join-Path $resolvedInputDirectory "restore_verification.txt"

$previousErrorActionPreference = $ErrorActionPreference
$psqlExitCode = $null

try {
    $ErrorActionPreference = "Continue"

    & $psql `
        -X `
        -v ON_ERROR_STOP=1 `
        -U $Username `
        -h $HostName `
        -p $Port `
        -d $Database `
        -f $verificationSql 2>&1 |
        Tee-Object -FilePath $verificationOutput

    $psqlExitCode = $LASTEXITCODE
}
finally {
    $ErrorActionPreference = $previousErrorActionPreference
}

if ($psqlExitCode -ne 0) {
    throw "Verifikasi integritas hasil restore gagal dengan exit code $psqlExitCode."
}

Write-Host ""
Write-Host "Restore dan verifikasi selesai ke database: $Database"
Write-Host "Bukti teks: $verificationOutput"
