[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path (Split-Path -Parent $PSScriptRoot) "config\pipeline.settings.local.json")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-PlainTextPassword {
    param(
        [Parameter(Mandatory)]
        [string]$PasswordFile
    )

    if (-not (Test-Path -LiteralPath $PasswordFile)) {
        throw "File password tidak ditemukan: $PasswordFile"
    }

    $encryptedPassword = (Get-Content -LiteralPath $PasswordFile -Raw).Trim()
    $securePassword = $encryptedPassword | ConvertTo-SecureString

    return [System.Net.NetworkCredential]::new(
        "",
        $securePassword
    ).Password
}

function Start-PostgresIfNeeded {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Settings
    )

    $pgIsReady = Join-Path $Settings.pgBin "pg_isready.exe"
    $pgCtl = Join-Path $Settings.pgBin "pg_ctl.exe"

    & $pgIsReady `
        -h $Settings.hostName `
        -p $Settings.port *> $null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "PostgreSQL sudah aktif pada port $($Settings.port)."
        return
    }

    if (-not (Test-Path -LiteralPath $Settings.postgresDataDirectory)) {
        throw "PostgreSQL tidak aktif dan data directory tidak ditemukan: $($Settings.postgresDataDirectory)"
    }

    $logDirectory = Split-Path -Parent $Settings.postgresLogPath
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null

    Write-Host "Menyalakan PostgreSQL pada port $($Settings.port)..."

    & $pgCtl `
        -D $Settings.postgresDataDirectory `
        -l $Settings.postgresLogPath `
        -o "-p $($Settings.port)" `
        start

    if ($LASTEXITCODE -ne 0) {
        throw "PostgreSQL gagal dijalankan. Periksa log: $($Settings.postgresLogPath)"
    }

    for ($attempt = 1; $attempt -le 15; $attempt++) {
        Start-Sleep -Seconds 2

        & $pgIsReady `
            -h $Settings.hostName `
            -p $Settings.port *> $null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "PostgreSQL siap menerima koneksi."
            return
        }
    }

    throw "PostgreSQL belum siap setelah 30 detik. Periksa log: $($Settings.postgresLogPath)"
}

function ConvertTo-ConnectionStringValue {
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    return '"' + $Value.Replace('"', '""') + '"'
}

function Invoke-PsqlScalar {
    param(
        [Parameter(Mandatory)]
        [string]$Psql,
        [Parameter(Mandatory)]
        [pscustomobject]$Settings,
        [Parameter(Mandatory)]
        [string]$Sql
    )

    $result = & $Psql `
        -X `
        -q `
        -v ON_ERROR_STOP=1 `
        -U $Settings.username `
        -h $Settings.hostName `
        -p $Settings.port `
        -d $Settings.database `
        -tAc $Sql

    if ($LASTEXITCODE -ne 0) {
        throw "Query PostgreSQL gagal dijalankan."
    }

    return ($result | Out-String).Trim()
}

function Remove-OldBatchDirectories {
    param(
        [Parameter(Mandatory)]
        [string]$RunsDirectory,
        [Parameter(Mandatory)]
        [int]$KeepCount
    )

    $directories = Get-ChildItem -LiteralPath $RunsDirectory -Directory |
        Sort-Object LastWriteTimeUtc -Descending

    $directories |
        Select-Object -Skip $KeepCount |
        ForEach-Object {
            Write-Host "Menghapus batch lama: $($_.FullName)"
            Remove-Item -LiteralPath $_.FullName -Recurse -Force
        }
}

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Konfigurasi lokal belum tersedia. Jalankan configure_pipeline.ps1 terlebih dahulu."
}

$automationRoot = Split-Path -Parent $PSScriptRoot
$passwordPath = Join-Path $automationRoot "config\postgres.password.dpapi"
$settings = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$plainPassword = Get-PlainTextPassword -PasswordFile $passwordPath

$requiredProperties = @(
    "repoRoot",
    "pgBin",
    "postgresDataDirectory",
    "postgresLogPath",
    "hostName",
    "port",
    "database",
    "username",
    "targetStationCount",
    "requestDelaySeconds",
    "keepBatchDirectories"
)

foreach ($propertyName in $requiredProperties) {
    if ($null -eq $settings.PSObject.Properties[$propertyName]) {
        throw "Konfigurasi tidak memiliki property: $propertyName"
    }
}

$runsDirectory = Join-Path $automationRoot "runs"
$logsDirectory = Join-Path $automationRoot "logs"
$historyDirectory = Join-Path $automationRoot "history"

New-Item -ItemType Directory -Path $runsDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $logsDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $historyDirectory -Force | Out-Null

$schedulerStartedAt = [DateTimeOffset]::UtcNow
$schedulerRunId = "pipeline-{0}" -f $schedulerStartedAt.ToString("yyyyMMdd-HHmmss")
$batchDirectory = Join-Path $runsDirectory $schedulerRunId
$logPath = Join-Path $logsDirectory "$schedulerRunId.log"
$historyPath = Join-Path $historyDirectory "pipeline_runs.csv"
$latestTwoPath = Join-Path $historyDirectory "latest_two_batches.csv"

$mutex = [System.Threading.Mutex]::new($false, "Local\NdbcEtPipelineScheduler")
$mutexAcquired = $false
$transcriptStarted = $false

try {
    try {
        $mutexAcquired = $mutex.WaitOne(0)
    }
    catch [System.Threading.AbandonedMutexException] {
        $mutexAcquired = $true
    }

    if (-not $mutexAcquired) {
        throw "Pipeline lain masih berjalan. Eksekusi baru dibatalkan agar tidak terjadi proses tumpang tindih."
    }

    Start-Transcript -LiteralPath $logPath -Force | Out-Null
    $transcriptStarted = $true

    Write-Host "Run scheduler : $schedulerRunId"
    Write-Host "Mulai UTC     : $($schedulerStartedAt.ToString('O'))"
    Write-Host "Output batch  : $batchDirectory"
    Write-Host ""

    Start-PostgresIfNeeded -Settings $settings

    $psql = Join-Path $settings.pgBin "psql.exe"
    $scraperProject = Join-Path $settings.repoRoot "Data Scraping\src\NdbcScraper.csproj"
    $loaderProject = Join-Path $settings.repoRoot "Data Storing\src\NdbcDataLoader.csproj"
    $schemaPath = Join-Path $settings.repoRoot "Data Storing\export\schema.sql"

    foreach ($requiredPath in @($psql, $scraperProject, $loaderProject, $schemaPath)) {
        if (-not (Test-Path -LiteralPath $requiredPath)) {
            throw "File wajib tidak ditemukan: $requiredPath"
        }
    }

    $env:PGPASSWORD = $plainPassword

    Write-Host ""
    Write-Host "Menjalankan scraping batch baru..."

    & dotnet run `
        --project $scraperProject `
        -- `
        --limit $settings.targetStationCount `
        --delay-seconds $settings.requestDelaySeconds `
        --output $batchDirectory

    if ($LASTEXITCODE -ne 0) {
        throw "Scraper selesai dengan exit code $LASTEXITCODE."
    }

    $reportPath = Join-Path $batchDirectory "scraping_report.json"
    if (-not (Test-Path -LiteralPath $reportPath)) {
        throw "Scraping report tidak ditemukan: $reportPath"
    }

    $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    if (-not [bool]$report.target_met) {
        throw "Target scraping tidak tercapai. Batch tidak diteruskan ke PostgreSQL."
    }

    $connectionString = @(
        "Host=$(ConvertTo-ConnectionStringValue ([string]$settings.hostName))",
        "Port=$($settings.port)",
        "Database=$(ConvertTo-ConnectionStringValue ([string]$settings.database))",
        "Username=$(ConvertTo-ConnectionStringValue ([string]$settings.username))",
        "Password=$(ConvertTo-ConnectionStringValue $plainPassword)"
    ) -join ";"

    $env:NDBC_DB_CONNECTION = $connectionString

    Write-Host ""
    Write-Host "Memuat batch ke PostgreSQL..."

    & dotnet run `
        --project $loaderProject `
        -- `
        --data $batchDirectory `
        --schema $schemaPath

    if ($LASTEXITCODE -ne 0) {
        throw "Data loader selesai dengan exit code $LASTEXITCODE."
    }

    $scrapeRunId = [string]$report.scrape_run_id
    $escapedRunId = $scrapeRunId.Replace("'", "''")

    $metricsSql = @"
WITH selected_run AS (
    SELECT
        sr.scrape_run_id,
        sr.started_at,
        sr.finished_at,
        sr.total_observation_count,
        MIN(se.extracted_at) AS first_extracted_at,
        MAX(se.extracted_at) AS last_extracted_at
    FROM ndbc.scrape_run AS sr
    LEFT JOIN ndbc.station_extraction AS se
        ON se.scrape_run_id = sr.scrape_run_id
    WHERE sr.scrape_run_id = '$escapedRunId'
    GROUP BY
        sr.scrape_run_id,
        sr.started_at,
        sr.finished_at,
        sr.total_observation_count
)
SELECT concat_ws('|',
    scrape_run_id,
    to_char(started_at AT TIME ZONE 'UTC', 'YYYY-MM-DD')
        || 'T'
        || to_char(started_at AT TIME ZONE 'UTC', 'HH24:MI:SS.MS')
        || 'Z',
    to_char(finished_at AT TIME ZONE 'UTC', 'YYYY-MM-DD')
        || 'T'
        || to_char(finished_at AT TIME ZONE 'UTC', 'HH24:MI:SS.MS')
        || 'Z',
    to_char(first_extracted_at AT TIME ZONE 'UTC', 'YYYY-MM-DD')
        || 'T'
        || to_char(first_extracted_at AT TIME ZONE 'UTC', 'HH24:MI:SS.MS')
        || 'Z',
    to_char(last_extracted_at AT TIME ZONE 'UTC', 'YYYY-MM-DD')
        || 'T'
        || to_char(last_extracted_at AT TIME ZONE 'UTC', 'HH24:MI:SS.MS')
        || 'Z',
    total_observation_count,
    (SELECT COUNT(*) FROM ndbc.observation WHERE first_seen_run_id = selected_run.scrape_run_id),
    total_observation_count - (SELECT COUNT(*) FROM ndbc.observation WHERE first_seen_run_id = selected_run.scrape_run_id),
    (SELECT COUNT(*) FROM ndbc.observation)
)
FROM selected_run;
"@

    $metricsLine = Invoke-PsqlScalar `
        -Psql $psql `
        -Settings $settings `
        -Sql $metricsSql

    if ([string]::IsNullOrWhiteSpace($metricsLine)) {
        throw "Metrik batch tidak ditemukan di PostgreSQL."
    }

    $metricParts = $metricsLine.Split('|')
    if ($metricParts.Count -ne 9) {
        throw "Format metrik batch tidak sesuai. Nilai: $metricsLine"
    }

    $duplicateSql = @"
SELECT COUNT(*) - COUNT(DISTINCT (station_id, observed_at_utc))
FROM ndbc.observation;
"@

    $databaseDuplicateCount = [long](Invoke-PsqlScalar `
        -Psql $psql `
        -Settings $settings `
        -Sql $duplicateSql)

    if ($databaseDuplicateCount -ne 0) {
        throw "Redundansi ditemukan pada tabel observation: $databaseDuplicateCount baris."
    }

    $schedulerFinishedAt = [DateTimeOffset]::UtcNow

    $historyRecord = [pscustomobject][ordered]@{
        scheduler_run_id = $schedulerRunId
        scheduler_started_at_utc = $schedulerStartedAt.ToString("O")
        scheduler_finished_at_utc = $schedulerFinishedAt.ToString("O")
        scrape_run_id = $metricParts[0]
        scrape_started_at_utc = $metricParts[1]
        scrape_finished_at_utc = $metricParts[2]
        first_extracted_at_utc = $metricParts[3]
        last_extracted_at_utc = $metricParts[4]
        source_observation_count = [long]$metricParts[5]
        inserted_observation_count = [long]$metricParts[6]
        overlapping_observation_count = [long]$metricParts[7]
        database_total_observation_count = [long]$metricParts[8]
        database_duplicate_count = $databaseDuplicateCount
        data_directory = "runs/$schedulerRunId"
        log_file = "logs/$schedulerRunId.log"
    }

    if (Test-Path -LiteralPath $historyPath) {
        $historyRecord |
            Export-Csv -LiteralPath $historyPath -NoTypeInformation -Append -Encoding UTF8
    }
    else {
        $historyRecord |
            Export-Csv -LiteralPath $historyPath -NoTypeInformation -Encoding UTF8
    }

    Import-Csv -LiteralPath $historyPath |
        Select-Object -Last 2 |
        Export-Csv -LiteralPath $latestTwoPath -NoTypeInformation -Encoding UTF8

    $combinedObservationFile = Join-Path $batchDirectory "observations.json"
    if (Test-Path -LiteralPath $combinedObservationFile) {
        Remove-Item -LiteralPath $combinedObservationFile -Force
        Write-Host "File gabungan observations.json dihapus setelah loading untuk menghemat ruang."
    }

    $checkpointDirectory = Join-Path $batchDirectory "checkpoints"
    if (Test-Path -LiteralPath $checkpointDirectory) {
        Remove-Item -LiteralPath $checkpointDirectory -Recurse -Force
    }

    Remove-OldBatchDirectories `
        -RunsDirectory $runsDirectory `
        -KeepCount ([int]$settings.keepBatchDirectories)

    Write-Host ""
    Write-Host "Automated pipeline berhasil."
    Write-Host "Scrape run ID            : $($historyRecord.scrape_run_id)"
    Write-Host "Observasi sumber         : $($historyRecord.source_observation_count)"
    Write-Host "Observasi baru           : $($historyRecord.inserted_observation_count)"
    Write-Host "Observasi overlap        : $($historyRecord.overlapping_observation_count)"
    Write-Host "Duplikasi di database    : $($historyRecord.database_duplicate_count)"
    Write-Host "Total observasi database : $($historyRecord.database_total_observation_count)"
    Write-Host "Riwayat batch            : $historyPath"
}
catch {
    Write-Error $_
    exit 1
}
finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    Remove-Item Env:NDBC_DB_CONNECTION -ErrorAction SilentlyContinue
    $plainPassword = $null

    if ($transcriptStarted) {
        Stop-Transcript | Out-Null
    }

    if ($mutexAcquired) {
        $mutex.ReleaseMutex()
    }

    $mutex.Dispose()
}
