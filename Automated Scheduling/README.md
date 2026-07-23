# Automated Scheduling ETL NDBC

Folder ini menjalankan pipeline scraping dan data storing secara berkala melalui Windows Task Scheduler.

Alur yang dijalankan:

1. Mengambil daftar stasiun dan observasi terbaru dari NDBC.
2. Membuat batch baru dengan `scrape_run_id` yang berbeda.
3. Memvalidasi JSON hasil scraping.
4. Memuat batch ke PostgreSQL.
5. Mencatat timestamp batch dan metrik jumlah data.
6. Memastikan tidak ada redundansi berdasarkan key observasi.

Scheduled task secara default berjalan setiap hari pukul 02.00 waktu lokal. Opsi `StartWhenAvailable` diaktifkan sehingga task dapat dijalankan ketika komputer kembali tersedia.

## Struktur folder

```text
Automated Scheduling/
├── config/
│   └── pipeline.settings.example.json
├── history/
│   ├── pipeline_runs.csv
│   └── latest_two_batches.csv
├── screenshots/
├── scripts/
│   ├── configure_pipeline.ps1
│   ├── register_scheduled_task.ps1
│   ├── run_pipeline.ps1
│   └── unregister_scheduled_task.ps1
├── sql/
│   └── verify_scheduling.sql
├── .gitignore
└── README.md
```

Folder `runs` dan `logs` dibuat saat runtime dan tidak dikumpulkan ke Git.

## Pencegahan redundansi dan koreksi historis

Identitas observasi ditentukan oleh:

```sql
PRIMARY KEY (station_id, observed_at_utc)
```

Kebijakan loader:

- Key baru dimasukkan sebagai tuple baru.
- Key lama dengan nilai yang sama tidak diubah.
- Key lama dengan nilai meteorologi atau metadata sumber yang berubah diperbarui.
- `first_seen_run_id` tetap menunjuk batch pertama.
- Tidak ada tuple kedua untuk key yang sama.

Dengan demikian, sistem bersifat idempotent sekaligus menerima koreksi historis dari sumber.

Pada laporan scheduling:

- `inserted_observation_count` adalah jumlah key yang pertama kali muncul pada batch tersebut.
- `overlapping_observation_count` adalah jumlah key sumber yang sudah ada sebelumnya. Nilai ini dapat mencakup tuple yang tetap sama maupun tuple yang dikoreksi oleh sumber.
- `database_duplicate_count` harus selalu `0`.

## 1. Membuat konfigurasi lokal

Buka PowerShell dari folder `Automated Scheduling`:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\configure_pipeline.ps1
```

Script membuat file lokal:

```text
config/pipeline.settings.local.json
config/postgres.password.dpapi
```

Kedua file diabaikan Git. Password disimpan menggunakan Windows DPAPI dan hanya dapat dibuka oleh user Windows pada komputer yang sama.

## 2. Menjalankan pipeline manual

```powershell
.\scripts\run_pipeline.ps1
```

Setelah berhasil, terminal menampilkan:

```text
Scrape run ID
Observasi sumber
Observasi baru
Observasi overlap
Duplikasi di database
Total observasi database
```

Riwayat disimpan pada:

```text
history/pipeline_runs.csv
history/latest_two_batches.csv
```

Timestamp disimpan dalam ISO 8601 UTC, misalnya:

```text
2026-07-23T10:31:55.961Z
```

Path runtime pada CSV disimpan relatif terhadap folder `Automated Scheduling` agar tidak bergantung pada drive atau username lokal.

## 3. Mendaftarkan scheduled task

```powershell
.\scripts\register_scheduled_task.ps1
```

Task yang dibuat:

```text
Nama   : NDBC Automated ETL
Jadwal : setiap hari pukul 02.00 waktu lokal
```

Periksa status:

```powershell
Get-ScheduledTask -TaskName "NDBC Automated ETL" |
    Select-Object TaskName, State
```

Jalankan untuk pengujian:

```powershell
Start-ScheduledTask -TaskName "NDBC Automated ETL"
```

Periksa hasil terakhir:

```powershell
Get-ScheduledTaskInfo -TaskName "NDBC Automated ETL" |
    Select-Object LastRunTime, LastTaskResult, NextRunTime
```

`LastTaskResult = 0` berarti task selesai tanpa error.

## 4. Verifikasi dua batch dan redundansi

```powershell
$pgBin = "C:\Program Files\PostgreSQL\13\bin"
$repo = "D:\ZIZAKAYA\Asisten Basis Data\Seleksi-2026-Tugas-1"

& "$pgBin\psql.exe" `
  -U postgres `
  -h localhost `
  -p 5433 `
  -d ndbc `
  -f "$repo\Automated Scheduling\sql\verify_scheduling.sql"
```

Query tersebut menampilkan:

1. Dua batch terbaru dengan timestamp yang berbeda.
2. Jumlah data sumber, data baru, dan overlap.
3. Jumlah tuple unik.
4. `duplicate_row_count = 0`.

## 5. File screenshot

Simpan bukti pada:

```text
Automated Scheduling/screenshots/
├── 01_scheduled_task_ready.png
├── 02_two_batch_timestamps.png
├── 03_no_duplicate_observations.png
├── 04_pipeline_history.png
└── 05_scheduled_task_result.png
```

## 6. Menghapus scheduled task

```powershell
.\scripts\unregister_scheduled_task.ps1
```

## Catatan runtime

Scraper menghasilkan file observasi per stasiun dan dapat menghasilkan `observations.json` gabungan. Setelah loading berhasil, file gabungan dihapus untuk menghemat ruang. Batch lama pada folder runtime dibersihkan sesuai `keepBatchDirectories` pada konfigurasi lokal.
