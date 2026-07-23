[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$PgBin = "C:\Program Files\PostgreSQL\13\bin",
    [string]$PostgresDataDirectory = "D:\PostgreSQL\ndbc-data",
    [string]$PostgresLogPath = "D:\PostgreSQL\ndbc-server.log",
    [string]$HostName = "localhost",
    [ValidateRange(1, 65535)]
    [int]$Port = 5433,
    [string]$Database = "ndbc",
    [string]$Username = "postgres",
    [ValidateRange(1, 1000)]
    [int]$TargetStationCount = 90,
    [ValidateRange(0, 60)]
    [double]$RequestDelaySeconds = 1.0,
    [ValidatePattern('^([01]\d|2[0-3]):[0-5]\d$')]
    [string]$DailyAt = "02:00",
    [ValidateRange(1, 30)]
    [int]$KeepBatchDirectories = 2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$automationRoot = Split-Path -Parent $PSScriptRoot
$configDirectory = Join-Path $automationRoot "config"
$configPath = Join-Path $configDirectory "pipeline.settings.local.json"
$passwordPath = Join-Path $configDirectory "postgres.password.dpapi"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = [System.IO.Path]::GetFullPath(
        (Join-Path $automationRoot "..")
    )
}
else {
    $RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
}

$requiredPaths = @(
    (Join-Path $RepoRoot "Data Scraping\src\NdbcScraper.csproj"),
    (Join-Path $RepoRoot "Data Storing\src\NdbcDataLoader.csproj"),
    (Join-Path $RepoRoot "Data Storing\export\schema.sql"),
    (Join-Path $PgBin "psql.exe"),
    (Join-Path $PgBin "pg_isready.exe"),
    (Join-Path $PgBin "pg_ctl.exe")
)

foreach ($requiredPath in $requiredPaths) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Path wajib tidak ditemukan: $requiredPath"
    }
}

New-Item -ItemType Directory -Path $configDirectory -Force | Out-Null

$securePassword = Read-Host "Masukkan password PostgreSQL untuk user $Username" -AsSecureString
if ($securePassword.Length -eq 0) {
    throw "Password PostgreSQL tidak boleh kosong."
}

$settings = [ordered]@{
    repoRoot = $RepoRoot
    pgBin = [System.IO.Path]::GetFullPath($PgBin)
    postgresDataDirectory = [System.IO.Path]::GetFullPath($PostgresDataDirectory)
    postgresLogPath = [System.IO.Path]::GetFullPath($PostgresLogPath)
    hostName = $HostName
    port = $Port
    database = $Database
    username = $Username
    targetStationCount = $TargetStationCount
    requestDelaySeconds = $RequestDelaySeconds
    dailyAt = $DailyAt
    keepBatchDirectories = $KeepBatchDirectories
}

$settings |
    ConvertTo-Json -Depth 4 |
    Set-Content -LiteralPath $configPath -Encoding UTF8

$securePassword |
    ConvertFrom-SecureString |
    Set-Content -LiteralPath $passwordPath -Encoding UTF8

$plainPassword = [System.Net.NetworkCredential]::new(
    "",
    $securePassword
).Password

try {
    $env:PGPASSWORD = $plainPassword
    $psql = Join-Path $PgBin "psql.exe"
    $pgIsReady = Join-Path $PgBin "pg_isready.exe"
    $pgCtl = Join-Path $PgBin "pg_ctl.exe"

    & $pgIsReady -h $HostName -p $Port *> $null

    if ($LASTEXITCODE -ne 0) {
        if (-not (Test-Path -LiteralPath $PostgresDataDirectory)) {
            throw "PostgreSQL tidak aktif dan data directory tidak ditemukan: $PostgresDataDirectory"
        }

        $logDirectory = Split-Path -Parent $PostgresLogPath
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null

        Write-Host "Menyalakan PostgreSQL pada port $Port..."
        & $pgCtl -D $PostgresDataDirectory -l $PostgresLogPath -o "-p $Port" start

        if ($LASTEXITCODE -ne 0) {
            throw "PostgreSQL gagal dijalankan. Periksa log: $PostgresLogPath"
        }

        Start-Sleep -Seconds 3
    }

    & $psql `
        -X `
        -v ON_ERROR_STOP=1 `
        -U $Username `
        -h $HostName `
        -p $Port `
        -d $Database `
        -tAc "SELECT current_database();"

    if ($LASTEXITCODE -ne 0) {
        throw "Koneksi PostgreSQL gagal. Periksa server, port, database, username, dan password."
    }
}
finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    $plainPassword = $null
}

Write-Host ""
Write-Host "Konfigurasi automated scheduling berhasil dibuat."
Write-Host "Settings : $configPath"
Write-Host "Password : $passwordPath"
Write-Host ""
Write-Host "Kedua file tersebut bersifat lokal dan sudah diabaikan oleh .gitignore."
