[CmdletBinding()]
param(
    [string]$PgBin = "C:\Program Files\PostgreSQL\13\bin",
    [string]$HostName = "localhost",
    [int]$Port = 5433,
    [string]$Database = "ndbc",
    [string]$Username = "postgres",
    [string]$OutputDirectory = ".\database_export",
    [int]$MaximumChunkMegabyte = 45
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($MaximumChunkMegabyte -lt 5 -or $MaximumChunkMegabyte -gt 90) {
    throw "MaximumChunkMegabyte harus berada pada rentang 5 sampai 90 MB."
}

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$resolvedOutputDirectory = if ([System.IO.Path]::IsPathRooted($OutputDirectory)) {
    [System.IO.Path]::GetFullPath($OutputDirectory)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $scriptDirectory $OutputDirectory))
}

$pgDump = Join-Path $PgBin "pg_dump.exe"
$psql = Join-Path $PgBin "psql.exe"

foreach ($executable in @($pgDump, $psql)) {
    if (-not (Test-Path -LiteralPath $executable)) {
        throw "Executable PostgreSQL tidak ditemukan: $executable"
    }
}

if (Test-Path -LiteralPath $resolvedOutputDirectory) {
    Remove-Item -LiteralPath $resolvedOutputDirectory -Recurse -Force
}
New-Item -ItemType Directory -Path $resolvedOutputDirectory | Out-Null

$preDataFile = Join-Path $resolvedOutputDirectory "00_warehouse_pre.sql"
$smallDataFile = Join-Path $resolvedOutputDirectory "10_dimensions_and_small_facts.sql"
$tempObservationDump = Join-Path $resolvedOutputDirectory ".fact_observation.full.tmp.sql"
$sequenceFile = Join-Path $resolvedOutputDirectory "98_identity_sequences.sql"
$postDataFile = Join-Path $resolvedOutputDirectory "99_warehouse_post.sql"
$manifestFile = Join-Path $resolvedOutputDirectory "export_manifest.txt"

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$Description
    )

    Write-Host $Description
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Description gagal dengan exit code $LASTEXITCODE."
    }
}

function Invoke-ScalarQuery {
    param(
        [Parameter(Mandatory = $true)][string]$Sql,
        [Parameter(Mandatory = $true)][string]$Description
    )

    $output = & $psql `
        -X `
        -v ON_ERROR_STOP=1 `
        -A `
        -t `
        -U $Username `
        -h $HostName `
        -p $Port `
        -d $Database `
        -c $Sql

    if ($LASTEXITCODE -ne 0) {
        throw "$Description gagal dengan exit code $LASTEXITCODE."
    }

    $value = ($output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Last 1).Trim()
    return [int64]$value
}

$connectionArguments = @(
    "--host=$HostName",
    "--port=$Port",
    "--username=$Username",
    "--dbname=$Database"
)

Invoke-CheckedCommand `
    -Executable $psql `
    -Arguments @(
        "-X", "-v", "ON_ERROR_STOP=1",
        "-h", $HostName,
        "-p", $Port,
        "-U", $Username,
        "-d", $Database,
        "-c", "SELECT COUNT(*) AS fact_observation_count FROM ndbc_dw.fact_observation;"
    ) `
    -Description "Memeriksa schema ndbc_dw..."

$dimDateCount = Invoke-ScalarQuery -Sql "SELECT COUNT(*) FROM ndbc_dw.dim_date;" -Description "Menghitung dim_date"
$dimTimeCount = Invoke-ScalarQuery -Sql "SELECT COUNT(*) FROM ndbc_dw.dim_time;" -Description "Menghitung dim_time"
$dimStationCount = Invoke-ScalarQuery -Sql "SELECT COUNT(*) FROM ndbc_dw.dim_station;" -Description "Menghitung dim_station"
$dimScrapeRunCount = Invoke-ScalarQuery -Sql "SELECT COUNT(*) FROM ndbc_dw.dim_scrape_run;" -Description "Menghitung dim_scrape_run"
$factScrapeRunCount = Invoke-ScalarQuery -Sql "SELECT COUNT(*) FROM ndbc_dw.fact_scrape_run;" -Description "Menghitung fact_scrape_run"
$factObservationCount = Invoke-ScalarQuery -Sql "SELECT COUNT(*) FROM ndbc_dw.fact_observation;" -Description "Menghitung fact_observation"
$etlBatchCount = Invoke-ScalarQuery -Sql "SELECT COUNT(*) FROM ndbc_dw.etl_batch;" -Description "Menghitung etl_batch"

Invoke-CheckedCommand `
    -Executable $pgDump `
    -Arguments ($connectionArguments + @(
        "--no-owner",
        "--no-privileges",
        "--schema=ndbc_dw",
        "--section=pre-data",
        "--file=$preDataFile"
    )) `
    -Description "Mengekspor pre-data warehouse..."

Invoke-CheckedCommand `
    -Executable $pgDump `
    -Arguments ($connectionArguments + @(
        "--no-owner",
        "--no-privileges",
        "--data-only",
        "--schema=ndbc_dw",
        "--exclude-table=ndbc_dw.fact_observation",
        "--file=$smallDataFile"
    )) `
    -Description "Mengekspor dimension, fact scrape run, dan audit ETL..."

Invoke-CheckedCommand `
    -Executable $pgDump `
    -Arguments ($connectionArguments + @(
        "--no-owner",
        "--no-privileges",
        "--data-only",
        "--table=ndbc_dw.fact_observation",
        "--file=$tempObservationDump"
    )) `
    -Description "Mengekspor fact observation sementara..."

$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
$maximumChunkBytes = [int64]$MaximumChunkMegabyte * 1MB
$reader = New-Object System.IO.StreamReader($tempObservationDump, $utf8WithoutBom, $true)
$copyHeader = $null
$insideCopy = $false
$chunkNumber = 0
$currentRowCount = 0L
$currentByteCount = 0L
$totalRowCount = 0L
$writer = $null
$chunkSummaries = New-Object System.Collections.Generic.List[object]

function Open-ObservationChunk {
    param([string]$Header)

    $script:chunkNumber++
    $script:currentRowCount = 0L
    $script:currentByteCount = 0L

    $chunkName = "20_fact_observation_{0:D3}.sql" -f $script:chunkNumber
    $chunkPath = Join-Path $resolvedOutputDirectory $chunkName
    $script:writer = New-Object System.IO.StreamWriter($chunkPath, $false, $utf8WithoutBom)

    $preamble = @(
        "SET statement_timeout = 0;",
        "SET lock_timeout = 0;",
        "SET client_encoding = 'UTF8';",
        "SET standard_conforming_strings = on;",
        $Header
    )

    foreach ($line in $preamble) {
        $script:writer.WriteLine($line)
        $script:currentByteCount += [System.Text.Encoding]::UTF8.GetByteCount($line) + 1
    }

    return $chunkPath
}

function Close-ObservationChunk {
    param([string]$ChunkPath)

    if ($null -eq $script:writer) {
        return
    }

    $script:writer.WriteLine("\.")
    $script:writer.Flush()
    $script:writer.Dispose()
    $script:writer = $null

    $fileInfo = Get-Item -LiteralPath $ChunkPath
    $chunkSummaries.Add([PSCustomObject]@{
        FileName = $fileInfo.Name
        RowCount = $script:currentRowCount
        SizeByte = $fileInfo.Length
    })
}

$currentChunkPath = $null

try {
    while (($line = $reader.ReadLine()) -ne $null) {
        if (-not $insideCopy) {
            if ($line -match '^COPY\s+ndbc_dw\.fact_observation\s+\(') {
                $copyHeader = $line
                $insideCopy = $true
                $currentChunkPath = Open-ObservationChunk -Header $copyHeader
            }
            continue
        }

        if ($line -eq "\.") {
            break
        }

        $lineByteCount = [System.Text.Encoding]::UTF8.GetByteCount($line) + 1
        if (
            $currentRowCount -gt 0 `
            -and ($currentByteCount + $lineByteCount + 3) -gt $maximumChunkBytes
        ) {
            Close-ObservationChunk -ChunkPath $currentChunkPath
            $currentChunkPath = Open-ObservationChunk -Header $copyHeader
        }

        $writer.WriteLine($line)
        $currentRowCount++
        $totalRowCount++
        $currentByteCount += $lineByteCount
    }

    if (-not $insideCopy -or $null -eq $copyHeader) {
        throw "Bagian COPY fact_observation tidak ditemukan pada hasil pg_dump."
    }

    Close-ObservationChunk -ChunkPath $currentChunkPath
}
finally {
    if ($null -ne $writer) {
        $writer.Dispose()
    }
    $reader.Dispose()
    Remove-Item -LiteralPath $tempObservationDump -Force -ErrorAction SilentlyContinue
}

if ($totalRowCount -ne $factObservationCount) {
    throw "Jumlah baris fact_observation dalam dump ($totalRowCount) tidak sama dengan database ($factObservationCount)."
}

$sequenceSql = @'
SELECT pg_catalog.setval(
    pg_get_serial_sequence('ndbc_dw.dim_station', 'station_key')::regclass,
    COALESCE((SELECT MAX(station_key) FROM ndbc_dw.dim_station), 1),
    EXISTS (SELECT 1 FROM ndbc_dw.dim_station)
);

SELECT pg_catalog.setval(
    pg_get_serial_sequence('ndbc_dw.dim_scrape_run', 'scrape_run_key')::regclass,
    COALESCE((SELECT MAX(scrape_run_key) FROM ndbc_dw.dim_scrape_run), 1),
    EXISTS (SELECT 1 FROM ndbc_dw.dim_scrape_run)
);

SELECT pg_catalog.setval(
    pg_get_serial_sequence('ndbc_dw.fact_scrape_run', 'scrape_run_fact_key')::regclass,
    COALESCE((SELECT MAX(scrape_run_fact_key) FROM ndbc_dw.fact_scrape_run), 1),
    EXISTS (SELECT 1 FROM ndbc_dw.fact_scrape_run)
);

SELECT pg_catalog.setval(
    pg_get_serial_sequence('ndbc_dw.fact_observation', 'observation_fact_key')::regclass,
    COALESCE((SELECT MAX(observation_fact_key) FROM ndbc_dw.fact_observation), 1),
    EXISTS (SELECT 1 FROM ndbc_dw.fact_observation)
);

SELECT pg_catalog.setval(
    pg_get_serial_sequence('ndbc_dw.etl_batch', 'etl_batch_id')::regclass,
    COALESCE((SELECT MAX(etl_batch_id) FROM ndbc_dw.etl_batch), 1),
    EXISTS (SELECT 1 FROM ndbc_dw.etl_batch)
);
'@
[System.IO.File]::WriteAllText($sequenceFile, $sequenceSql, $utf8WithoutBom)

Invoke-CheckedCommand `
    -Executable $pgDump `
    -Arguments ($connectionArguments + @(
        "--no-owner",
        "--no-privileges",
        "--schema=ndbc_dw",
        "--section=post-data",
        "--file=$postDataFile"
    )) `
    -Description "Mengekspor post-data warehouse..."

$oversizedFiles = Get-ChildItem -LiteralPath $resolvedOutputDirectory -File -Filter "*.sql" |
    Where-Object { $_.Length -ge 95MB }

if ($oversizedFiles) {
    $names = ($oversizedFiles | ForEach-Object { "$($_.Name) ($([math]::Round($_.Length / 1MB, 2)) MB)" }) -join ", "
    throw "Terdapat file export yang terlalu besar untuk GitHub: $names"
}

$manifestLines = New-Object System.Collections.Generic.List[string]
$manifestLines.Add("NDBC DATA WAREHOUSE EXPORT")
$manifestLines.Add("GeneratedAtUtc=$([DateTime]::UtcNow.ToString('O'))")
$manifestLines.Add("Database=$Database")
$manifestLines.Add("Schema=ndbc_dw")
$manifestLines.Add("DimDateRows=$dimDateCount")
$manifestLines.Add("DimTimeRows=$dimTimeCount")
$manifestLines.Add("DimStationRows=$dimStationCount")
$manifestLines.Add("DimScrapeRunRows=$dimScrapeRunCount")
$manifestLines.Add("FactScrapeRunRows=$factScrapeRunCount")
$manifestLines.Add("FactObservationRows=$totalRowCount")
$manifestLines.Add("EtlBatchRows=$etlBatchCount")
$manifestLines.Add("MaximumChunkMegabyte=$MaximumChunkMegabyte")
$manifestLines.Add("")
$manifestLines.Add("FILES")

Get-ChildItem -LiteralPath $resolvedOutputDirectory -File -Filter "*.sql" |
    Sort-Object Name |
    ForEach-Object {
        $manifestLines.Add("$($_.Name)|$($_.Length)")
    }

$manifestLines.Add("")
$manifestLines.Add("FACT_OBSERVATION_CHUNKS")
foreach ($summary in $chunkSummaries) {
    $manifestLines.Add("$($summary.FileName)|rows=$($summary.RowCount)|bytes=$($summary.SizeByte)")
}

[System.IO.File]::WriteAllLines($manifestFile, $manifestLines, $utf8WithoutBom)

Write-Host ""
Write-Host "Export data warehouse selesai."
Write-Host "Output               : $resolvedOutputDirectory"
Write-Host "Fact observation rows: $totalRowCount"
Write-Host "Jumlah chunk fact    : $($chunkSummaries.Count)"

Get-ChildItem -LiteralPath $resolvedOutputDirectory -File |
    Sort-Object Name |
    Select-Object Name, @{Name = "SizeMB"; Expression = { [math]::Round($_.Length / 1MB, 2) }} |
    Format-Table -AutoSize
