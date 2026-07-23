param(
    [string]$PgBin = "C:\Program Files\PostgreSQL\13\bin",
    [string]$HostName = "localhost",
    [int]$Port = 5433,
    [string]$Database = "ndbc_restore_test",
    [string]$Username = "postgres",
    [string]$InputDirectory = ".\database_export",
    [switch]$RecreateDatabase
)

$ErrorActionPreference = "Stop"

if ($Database -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
    throw "Nama database tidak valid: $Database"
}

$psql = Join-Path $PgBin "psql.exe"

if (-not (Test-Path $psql -PathType Leaf)) {
    throw "psql.exe tidak ditemukan di: $psql"
}

if ([System.IO.Path]::IsPathRooted($InputDirectory)) {
    $inputDirectoryPath = [System.IO.Path]::GetFullPath($InputDirectory)
}
else {
    $inputDirectoryPath = [System.IO.Path]::GetFullPath(
        (Join-Path (Get-Location).Path $InputDirectory)
    )
}

if (-not (Test-Path $inputDirectoryPath -PathType Container)) {
    throw "Folder export tidak ditemukan: $inputDirectoryPath"
}

$sqlFiles = @(
    Get-ChildItem $inputDirectoryPath -File -Filter "*.sql" |
        Where-Object {
            $_.Name -match '^(00_database_pre|10_observation_\d{3}|99_database_post)\.sql$'
        } |
        Sort-Object Name
)

if ($sqlFiles.Count -lt 3) {
    throw "File export tidak lengkap pada folder: $inputDirectoryPath"
}

if ($sqlFiles[0].Name -ne "00_database_pre.sql") {
    throw "File pertama harus 00_database_pre.sql."
}

if ($sqlFiles[-1].Name -ne "99_database_post.sql") {
    throw "File terakhir harus 99_database_post.sql."
}

if ($RecreateDatabase) {
    & $psql `
        --host=$HostName `
        --port=$Port `
        --username=$Username `
        --dbname=postgres `
        --set=ON_ERROR_STOP=1 `
        --command="SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$Database' AND pid <> pg_backend_pid();"

    if ($LASTEXITCODE -ne 0) {
        throw "Gagal menghentikan koneksi ke database $Database."
    }

    & $psql `
        --host=$HostName `
        --port=$Port `
        --username=$Username `
        --dbname=postgres `
        --set=ON_ERROR_STOP=1 `
        --command="DROP DATABASE IF EXISTS $Database;"

    if ($LASTEXITCODE -ne 0) {
        throw "Gagal menghapus database $Database."
    }

    & $psql `
        --host=$HostName `
        --port=$Port `
        --username=$Username `
        --dbname=postgres `
        --set=ON_ERROR_STOP=1 `
        --command="CREATE DATABASE $Database;"

    if ($LASTEXITCODE -ne 0) {
        throw "Gagal membuat database $Database."
    }
}

$combinedRestorePath = Join-Path $inputDirectoryPath ".restore_combined.tmp.sql"
$newLineBytes = [System.Text.Encoding]::UTF8.GetBytes([Environment]::NewLine)

try {
    Write-Host "Menggabungkan $($sqlFiles.Count) file SQL sementara untuk satu sesi psql..."

    $targetStream = [System.IO.FileStream]::new(
        $combinedRestorePath,
        [System.IO.FileMode]::Create,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::None
    )

    try {
        foreach ($sqlFile in $sqlFiles) {
            Write-Host "Menyiapkan $($sqlFile.Name)..."

            $sourceStream = [System.IO.FileStream]::new(
                $sqlFile.FullName,
                [System.IO.FileMode]::Open,
                [System.IO.FileAccess]::Read,
                [System.IO.FileShare]::Read
            )

            try {
                $sourceStream.CopyTo($targetStream, 1MB)
            }
            finally {
                $sourceStream.Dispose()
            }

            $targetStream.Write($newLineBytes, 0, $newLineBytes.Length)
        }
    }
    finally {
        $targetStream.Dispose()
    }

    Write-Host "Memulihkan database dalam satu sesi psql..."

    & $psql `
        --host=$HostName `
        --port=$Port `
        --username=$Username `
        --dbname=$Database `
        --set=ON_ERROR_STOP=1 `
        --file=$combinedRestorePath

    if ($LASTEXITCODE -ne 0) {
        throw "Restore database gagal dengan exit code $LASTEXITCODE."
    }

    Write-Host "Restore selesai ke database: $Database"
}
finally {
    if (Test-Path $combinedRestorePath -PathType Leaf) {
        Remove-Item $combinedRestorePath -Force
    }
}
