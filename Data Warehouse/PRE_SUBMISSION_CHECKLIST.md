# Pre-Submission Checklist

Gunakan daftar ini setelah seluruh script dijalankan pada PostgreSQL lokal.

## Desain dan dokumentasi

- [ ] `design/erd.png` dapat dibaca dan sesuai dengan `erd.dot`.
- [ ] `design/relational_diagram.png` memuat seluruh kolom, PK, FK, unique key, dan sama dengan DDL.
- [ ] Tidak ada relasi `etl_batch` ke fact karena DDL memang tidak memiliki foreign key tersebut.
- [ ] Grain setiap fact dijelaskan secara eksplisit.
- [ ] Kebutuhan analitik dipetakan ke fact, dimension, dan measure.
- [ ] Asumsi SCD Type 1 dan konsekuensinya dijelaskan.

## Runtime PostgreSQL

- [ ] `run_warehouse.ps1 -TestIdempotency` selesai dengan exit code `0`.
- [ ] Seluruh metrik pada `HASIL VERIFIKASI FAIL-FAST` berstatus `PASS`.
- [ ] `source_observation_rows_missing_in_warehouse = 0`.
- [ ] `unexpected_warehouse_observation_rows = 0`.
- [ ] `observation_transformation_mismatch_rows = 0`.
- [ ] `scrape_run_transformation_mismatch_rows = 0`.
- [ ] Eksekusi kedua pengujian idempotensi menambah nol baris.

## Export dan restore

- [ ] Folder `export/database_export` berisi file `.sql` aktual, bukan hanya `.gitkeep`.
- [ ] `export_manifest.txt` tersedia.
- [ ] `restore_warehouse.ps1 -RecreateDatabase` selesai tanpa error.
- [ ] `restore_verification.txt` menunjukkan seluruh assertion `PASS`.
- [ ] Jumlah setiap tabel hasil restore sama dengan manifest.

## Screenshot

- [ ] `01_tables_and_counts.png`.
- [ ] `02_select_from_where.png`.
- [ ] `03_daily_analytics.png`.
- [ ] `04_scrape_run_analytics.png`.
- [ ] `05_data_quality.png`.
- [ ] `06_export_restore.png`.

## Pemeriksaan akhir

- [ ] Jalankan `validate_submission.ps1` dan pastikan hasil akhirnya `SUBMISSION READY`.
- [ ] Tidak ada password, token, file log, atau file runtime sensitif di repository.
