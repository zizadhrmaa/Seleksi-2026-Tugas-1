param(
    [string]$PgBin = "C:\Program Files\PostgreSQL\13\bin",
    [string]$HostName = "localhost",
    [int]$Port = 5433,
    [string]$Database = "ndbc",
    [string]$Username = "postgres",
    [string]$OutputDirectory = ".\database_export",
    [ValidateRange(10, 90)]
    [int]$MaxObservationFileSizeMB = 45
)

$ErrorActionPreference = "Stop"

$pgDump = Join-Path $PgBin "pg_dump.exe"

if (-not (Test-Path $pgDump -PathType Leaf)) {
    throw "pg_dump.exe tidak ditemukan di: $pgDump"
}

if ([System.IO.Path]::IsPathRooted($OutputDirectory)) {
    $outputDirectoryPath = [System.IO.Path]::GetFullPath($OutputDirectory)
}
else {
    $outputDirectoryPath = [System.IO.Path]::GetFullPath(
        (Join-Path (Get-Location).Path $OutputDirectory)
    )
}
New-Item -ItemType Directory -Path $outputDirectoryPath -Force | Out-Null

Get-ChildItem $outputDirectoryPath -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -match '^(00_database_pre|10_observation_\d{3}|99_database_post)\.sql$' -or
        $_.Name -eq 'export_manifest.txt' -or
        $_.Name -eq '.ndbc_database_full.tmp.sql'
    } |
    Remove-Item -Force

$tempDumpPath = Join-Path $outputDirectoryPath ".ndbc_database_full.tmp.sql"
$preDumpPath = Join-Path $outputDirectoryPath "00_database_pre.sql"
$postDumpPath = Join-Path $outputDirectoryPath "99_database_post.sql"
$manifestPath = Join-Path $outputDirectoryPath "export_manifest.txt"

Write-Host "Membuat dump PostgreSQL sementara..."

& $pgDump `
    --host=$HostName `
    --port=$Port `
    --username=$Username `
    --format=plain `
    --no-owner `
    --no-privileges `
    --file=$tempDumpPath `
    $Database

if ($LASTEXITCODE -ne 0) {
    throw "pg_dump gagal dengan exit code $LASTEXITCODE."
}

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$newLine = [Environment]::NewLine
$maxChunkBytes = $MaxObservationFileSizeMB * 1MB
$githubSafeLimitBytes = 49MB

function Write-SessionHeader {
    param([System.IO.StreamWriter]$Writer)

    $lines = @(
        "-- Generated PostgreSQL export chunk",
        "SET client_encoding = 'UTF8';",
        "SET standard_conforming_strings = on;",
        "SET check_function_bodies = false;",
        "SET xmloption = content;",
        "SET client_min_messages = warning;",
        "SET row_security = off;",
        ""
    )

    foreach ($headerLine in $lines) {
        $Writer.WriteLine($headerLine)
    }

    return ($utf8NoBom.GetByteCount(($lines -join $newLine) + $newLine))
}

$reader = $null
$preWriter = $null
$postWriter = $null
$chunkWriter = $null
$chunkPaths = [System.Collections.Generic.List[string]]::new()
$state = "pre"
$copyHeader = $null
$chunkIndex = 0
$chunkBytes = 0L
$chunkRowCount = 0L
$observationCopyFound = $false
$exportSucceeded = $false

function Open-ObservationChunk {
    $script:chunkIndex++
    $chunkName = "10_observation_{0:D3}.sql" -f $script:chunkIndex
    $chunkPath = Join-Path $outputDirectoryPath $chunkName
    [void]$script:chunkPaths.Add($chunkPath)
    $script:chunkWriter = [System.IO.StreamWriter]::new($chunkPath, $false, $utf8NoBom)
    $script:chunkBytes = Write-SessionHeader -Writer $script:chunkWriter
    $script:chunkWriter.WriteLine($script:copyHeader)
    $script:chunkBytes += $utf8NoBom.GetByteCount($script:copyHeader + $newLine)
    $script:chunkRowCount = 0L
}

function Close-ObservationChunk {
    if ($null -eq $script:chunkWriter) {
        return
    }

    $script:chunkWriter.WriteLine("\.")
    $script:chunkWriter.Dispose()
    $script:chunkWriter = $null
}

try {
    Write-Host "Memecah dump menjadi beberapa file SQL..."

    $reader = [System.IO.StreamReader]::new($tempDumpPath, $utf8NoBom, $true)
    $preWriter = [System.IO.StreamWriter]::new($preDumpPath, $false, $utf8NoBom)

    while (($line = $reader.ReadLine()) -ne $null) {
        if ($state -eq "pre") {
            if ($line -match '^COPY\s+ndbc\.observation\s*\(') {
                $observationCopyFound = $true
                $copyHeader = $line
                $preWriter.Dispose()
                $preWriter = $null
                $state = "observation"
                Open-ObservationChunk
                continue
            }

            $preWriter.WriteLine($line)
            continue
        }

        if ($state -eq "observation") {
            if ($line -eq "\.") {
                Close-ObservationChunk
                $state = "post"
                $postWriter = [System.IO.StreamWriter]::new($postDumpPath, $false, $utf8NoBom)
                [void](Write-SessionHeader -Writer $postWriter)
                continue
            }

            $lineBytes = $utf8NoBom.GetByteCount($line + $newLine)
            $closingBytes = $utf8NoBom.GetByteCount("\." + $newLine)

            if (
                $chunkRowCount -gt 0 -and
                ($chunkBytes + $lineBytes + $closingBytes) -gt $maxChunkBytes
            ) {
                Close-ObservationChunk
                Open-ObservationChunk
            }

            $chunkWriter.WriteLine($line)
            $chunkBytes += $lineBytes
            $chunkRowCount++
            continue
        }

        $postWriter.WriteLine($line)
    }

    if (-not $observationCopyFound) {
        throw "Blok COPY untuk tabel ndbc.observation tidak ditemukan pada hasil pg_dump."
    }

    if ($state -eq "observation") {
        throw "Blok COPY ndbc.observation tidak memiliki penutup \\."
    }

    $reader.Dispose()
    $reader = $null

    if ($null -ne $postWriter) {
        $postWriter.Dispose()
        $postWriter = $null
    }

    $generatedFiles = @($preDumpPath) + $chunkPaths.ToArray() + @($postDumpPath)

    foreach ($filePath in $generatedFiles) {
        $file = Get-Item $filePath
        if ($file.Length -ge $githubSafeLimitBytes) {
            throw "File $($file.Name) berukuran $([math]::Round($file.Length / 1MB, 2)) MB. Ukurannya melebihi batas aman 49 MB yang digunakan script ini."
        }
    }

    $manifestLines = [System.Collections.Generic.List[string]]::new()
    $manifestLines.Add("NDBC PostgreSQL Export")
    $manifestLines.Add("Generated at: $([DateTimeOffset]::Now.ToString('o'))")
    $manifestLines.Add("Database: $Database")
    $manifestLines.Add("Host: ${HostName}:$Port")
    $manifestLines.Add("Restore files in this exact order:")

    foreach ($filePath in $generatedFiles) {
        $file = Get-Item $filePath
        $manifestLines.Add("$($file.Name) | $([math]::Round($file.Length / 1MB, 2)) MB")
    }

    [System.IO.File]::WriteAllLines($manifestPath, $manifestLines, $utf8NoBom)
    Remove-Item $tempDumpPath -Force
    $exportSucceeded = $true

    Write-Host ""
    Write-Host "Export berhasil dibuat di: $outputDirectoryPath"
    Write-Host "File SQL: $($generatedFiles.Count)"

    Get-Item $generatedFiles |
        Select-Object Name, @{
            Name = "SizeMB"
            Expression = { [math]::Round($_.Length / 1MB, 2) }
        } |
        Format-Table -AutoSize
}
finally {
    if ($null -ne $reader) {
        $reader.Dispose()
    }

    if ($null -ne $preWriter) {
        $preWriter.Dispose()
    }

    if ($null -ne $postWriter) {
        $postWriter.Dispose()
    }

    if ($null -ne $chunkWriter) {
        $chunkWriter.Dispose()
    }

    if (-not $exportSucceeded -and (Test-Path $tempDumpPath)) {
        Write-Warning "Dump sementara dipertahankan untuk pemeriksaan: $tempDumpPath"
    }
}
