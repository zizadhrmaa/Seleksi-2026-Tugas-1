# PostgreSQL Database Export

Folder `database_export` dihasilkan oleh `export_database.ps1`. Export dipecah menjadi beberapa file SQL agar setiap file tetap di bawah batas ukuran file GitHub.

Urutan file restore:

1. `00_database_pre.sql`
2. `10_observation_001.sql`, dilanjutkan nomor berikutnya
3. `99_database_post.sql`

File tetap merupakan hasil `pg_dump`. Pemecahan hanya dilakukan pada blok `COPY ndbc.observation`, sehingga seluruh schema, data, constraint, index, function, dan trigger tetap dapat dipulihkan.

## Membuat export

Jalankan dari folder `Data Storing/export`:

```powershell
$env:PGPASSWORD = "PASSWORD_POSTGRES"

.\export_database.ps1 `
  -PgBin "C:\Program Files\PostgreSQL\13\bin" `
  -HostName localhost `
  -Port 5433 `
  -Database ndbc `
  -Username postgres `
  -OutputDirectory ".\database_export"
```

## Menguji restore

Gunakan database terpisah agar database utama tidak terganggu:

```powershell
.\restore_database.ps1 `
  -PgBin "C:\Program Files\PostgreSQL\13\bin" `
  -HostName localhost `
  -Port 5433 `
  -Database ndbc_restore_test `
  -Username postgres `
  -InputDirectory ".\database_export" `
  -RecreateDatabase
```

Verifikasi hasil restore:

```powershell
& "C:\Program Files\PostgreSQL\13\bin\psql.exe" `
  -U postgres `
  -h localhost `
  -p 5433 `
  -d ndbc_restore_test `
  -c "SELECT (SELECT COUNT(*) FROM ndbc.station) AS total_stations, (SELECT COUNT(*) FROM ndbc.observation) AS total_observations;"
```

Target hasilnya adalah 90 stasiun dan 571167 observasi.

## Status snapshot export

File pada `database_export` merepresentasikan baseline setelah batch awal:

```text
station     = 90
observation = 571167
```

Automated scheduling dijalankan setelah export dibuat, sehingga database operasional dapat memiliki jumlah observasi yang lebih besar. Export baseline tetap valid karena sudah diuji restore. Jika snapshot diperbarui, jalankan kembali restore test dan verifikasi jumlah data sebelum mengganti bukti pada README.

`99_database_post.sql` juga memuat composite foreign key:

```text
observation(first_seen_run_id, station_id)
    -> station_extraction(scrape_run_id, station_id)
```

Constraint tersebut memastikan bahwa batch pertama sebuah observasi benar-benar tercatat mengekstrak stasiun terkait.
