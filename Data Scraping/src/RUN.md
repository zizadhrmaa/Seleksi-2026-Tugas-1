# Menjalankan NDBC Scraper

Kebutuhan:

- .NET SDK 10
- Koneksi internet

Jalankan dari dalam folder `src`:

```bash
dotnet restore
dotnet run -- --limit 100
```

Secara default program mencari 100 stasiun yang teridentifikasi sebagai buoy dari bagian `National Data Buoy Center Stations`, lalu menulis hasil ke folder `data` yang berada sejajar dengan folder `src`.

Output utama:

- `data/stations.json`
- `data/observations.json`
- `data/observations_manifest.json`
- `data/observations/{station_id}.json`
- `data/skipped_stations.json`
- `data/errors.json`
- `data/scraping_report.json`
- `data/checkpoints/progress.json`

`observations.json` tetap dibuat sebagai file gabungan lokal. File tersebut diabaikan oleh Git karena ukurannya dapat melewati batas GitHub. Data yang dikumpulkan ke repository menggunakan file per stasiun pada folder `data/observations` dan dilengkapi `observations_manifest.json`.

Jika proses dihentikan sebelum selesai, lanjutkan dengan:

```bash
dotnet run -- --resume
```

Opsi yang tersedia:

```bash
dotnet run -- --limit 100 --delay-seconds 1
dotnet run -- --limit 5 --output ../data-test
dotnet run -- --resume
```

Menjalankan program tanpa `--resume` akan memulai run baru dan mengganti file hasil scraping yang dibuat oleh run sebelumnya.
