# Source Data Warehouse

Folder ini berisi script pembuatan, incremental load, verifikasi fail-fast, dan pengujian idempotensi warehouse NDBC pada PostgreSQL.

## Urutan file

1. `01_create_warehouse.sql` membuat schema `ndbc_dw`, dimension table, fact table, constraint, index, trigger, dan view analitik.
2. `02_load_warehouse.sql` membuat fungsi `ndbc_dw.refresh_warehouse()` dan memuat data dari schema operasional `ndbc` secara incremental.
3. `03_verify_and_analyze.sql` melakukan perbandingan berbasis jumlah dan key, memeriksa transformasi, lalu menghentikan proses dengan `RAISE EXCEPTION` apabila ada ketidaksesuaian.
4. `04_test_idempotency.sql` menjalankan refresh dua kali dalam snapshot sumber yang sama dan mewajibkan eksekusi kedua menambah nol baris.
5. `run_warehouse.ps1` menjalankan script secara berurutan dengan `ON_ERROR_STOP`.

## Menjalankan load dan verifikasi

```powershell
cd ".\Data Warehouse\src"

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
Unblock-File ".\run_warehouse.ps1"

.\run_warehouse.ps1 `
  -PgBin "C:\Program Files\PostgreSQL\13\bin" `
  -HostName localhost `
  -Port 5433 `
  -Database ndbc `
  -Username postgres
```

## Menjalankan pengujian idempotensi

```powershell
.\run_warehouse.ps1 `
  -PgBin "C:\Program Files\PostgreSQL\13\bin" `
  -HostName localhost `
  -Port 5433 `
  -Database ndbc `
  -Username postgres `
  -TestIdempotency
```

Pengujian menggunakan transaksi `REPEATABLE READ`, sehingga kedua refresh membaca snapshot sumber yang sama. Eksekusi kedua wajib menghasilkan:

```text
inserted_station_count = 0
inserted_scrape_run_count = 0
inserted_observation_count = 0
```

## Makna fail-fast

Query verifikasi tidak hanya menampilkan angka. Semua metrik wajib dimasukkan ke tabel sementara dan dibandingkan dengan nilai target. Bila satu metrik gagal, `03_verify_and_analyze.sql` mengeluarkan exception dan `run_warehouse.ps1` berhenti dengan exit code nonzero.

Metrik wajib meliputi:

- jumlah source dan warehouse;
- source row yang hilang;
- warehouse row yang tidak mempunyai pasangan pada source;
- duplikasi natural grain;
- missing dimension;
- mismatch transformasi observation dan scrape run;
- konsistensi date key dan time key;
- batch ETL yang belum selesai.
