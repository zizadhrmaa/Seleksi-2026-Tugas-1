[CmdletBinding()]
param(
    [string]$TaskName = "NDBC Automated ETL",
    [string]$ConfigPath = (Join-Path (Split-Path -Parent $PSScriptRoot) "config\pipeline.settings.local.json")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Konfigurasi lokal belum tersedia. Jalankan configure_pipeline.ps1 terlebih dahulu."
}

$settings = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$runScript = Join-Path $PSScriptRoot "run_pipeline.ps1"

if (-not (Test-Path -LiteralPath $runScript)) {
    throw "Script pipeline tidak ditemukan: $runScript"
}

$scheduledTime = [DateTime]::ParseExact(
    [string]$settings.dailyAt,
    "HH:mm",
    [System.Globalization.CultureInfo]::InvariantCulture
)

$actionArguments = @(
    "-NoProfile",
    "-ExecutionPolicy Bypass",
    "-File `"$runScript`"",
    "-ConfigPath `"$ConfigPath`""
) -join " "

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument $actionArguments `
    -WorkingDirectory $PSScriptRoot

$trigger = New-ScheduledTaskTrigger `
    -Daily `
    -At $scheduledTime

$taskSettings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Hours 4)

$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$principal = New-ScheduledTaskPrincipal `
    -UserId $currentUser `
    -LogonType Interactive `
    -RunLevel Limited

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $taskSettings `
    -Principal $principal `
    -Description "Scrape data buoy NDBC dan memuat pembaruan ke PostgreSQL tanpa duplikasi." `
    -Force | Out-Null

Write-Host "Scheduled task berhasil dibuat."
Write-Host "Nama task : $TaskName"
Write-Host "Jadwal    : setiap hari pukul $($settings.dailyAt) waktu lokal"
Write-Host "User      : $currentUser"
Write-Host ""
Write-Host "Jalankan sekarang untuk pengujian:"
Write-Host "Start-ScheduledTask -TaskName `"$TaskName`""
