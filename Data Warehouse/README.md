# Data Warehouse Meteorologi NDBC

Data warehouse dibangun dari schema operasional PostgreSQL `ndbc` dan disimpan pada schema logis terpisah `ndbc_dw` dalam database yang sama. Pemisahan ini memisahkan struktur operasional dan analitik secara logis, tetapi tidak menciptakan isolasi workload secara fisik karena keduanya masih menggunakan instance PostgreSQL yang sama.

## Struktur folder

```text
Data Warehouse/
├── design/
│   ├── erd.dot
│   ├── erd.png
│   ├── relational_diagram.dot
│   ├── relational_diagram.png
│   └── data_warehouse_design.md
├── src/
│   ├── 01_create_warehouse.sql
│   ├── 02_load_warehouse.sql
│   ├── 03_verify_and_analyze.sql
│   ├── 04_test_idempotency.sql
│   ├── run_warehouse.ps1
│   └── README.md
├── export/
│   ├── database_export/
│   ├── export_warehouse.ps1
│   ├── restore_warehouse.ps1
│   ├── verify_restored_warehouse.sql
│   └── README.md
├── screenshots/
│   └── README.md
├── validate_submission.ps1
└── PRE_SUBMISSION_CHECKLIST.md
```

## Arsitektur dimensional

Rancangan menggunakan **fact constellation** karena terdapat dua fact table dengan grain berbeda:

- `fact_observation`: satu stasiun pada satu timestamp UTC;
- `fact_scrape_run`: satu batch scraping.

Dimension table yang digunakan adalah `dim_date`, `dim_time`, `dim_station`, dan `dim_scrape_run`. Tabel `etl_batch` merupakan tabel audit proses dan tidak memiliki foreign key ke fact table.

## Menjalankan pipeline warehouse

```powershell
cd ".\Data Warehouse\src"

.\run_warehouse.ps1 `
  -PgBin "C:\Program Files\PostgreSQL\13\bin" `
  -HostName localhost `
  -Port 5433 `
  -Database ndbc `
  -Username postgres `
  -TestIdempotency
```

Pipeline hanya menampilkan pesan berhasil apabila pembuatan schema, load, seluruh assertion kualitas, dan pengujian idempotensi selesai dengan exit code `0`.

## Verifikasi yang diwajibkan

`03_verify_and_analyze.sql` membuktikan kesesuaian data menggunakan:

- equality jumlah source dan warehouse;
- set difference dua arah berbasis natural key;
- pemeriksaan seluruh hasil transformasi;
- pemeriksaan grain dan foreign key;
- konsistensi date key dan time key;
- assertion fail-fast.

Jumlah yang sama tidak dianggap sebagai bukti yang cukup apabila isi key atau atribut berbeda.

## Export dan restore

Jalankan script pada folder `export` setelah pipeline lolos. Export dibagi menjadi beberapa file SQL agar ukuran `fact_observation` tetap aman untuk repository. Restore otomatis memeriksa integritas dan membandingkan jumlah tabel dengan `export_manifest.txt`.

## Validasi berkas submission

Setelah export aktual dan screenshot dibuat, jalankan:

```powershell
.\validate_submission.ps1
```

Script ini sengaja gagal apabila file `.sql` export atau enam screenshot wajib belum tersedia. Dengan demikian, folder placeholder tidak akan keliru dianggap sebagai bukti submission.

## Batas verifikasi paket ini

Kode dan diagram pada paket ini dapat diperiksa secara statis. Hasil export aktual, hasil query PostgreSQL, serta screenshot tidak dapat dibuat tanpa database `ndbc` pada komputer pemilik proyek. Semua bukti runtime harus dihasilkan setelah script dijalankan pada lingkungan lokal.
