[CmdletBinding()]
param(
    [string]$TaskName = "NDBC Automated ETL"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($null -eq $task) {
    Write-Host "Scheduled task tidak ditemukan: $TaskName"
    return
}

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
Write-Host "Scheduled task berhasil dihapus: $TaskName"
