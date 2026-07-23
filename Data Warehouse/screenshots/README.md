# Screenshot Data Warehouse

Simpan screenshot aktual hasil eksekusi PostgreSQL dengan nama berikut. Jangan mengganti bukti runtime dengan gambar placeholder.

1. `01_tables_and_counts.png`  
   Menampilkan daftar tabel `ndbc_dw` dan jumlah baris dimension serta fact table.

2. `02_select_from_where.png`  
   Menampilkan query `SELECT ... FROM ... WHERE ...` dari `03_verify_and_analyze.sql` beserta hasilnya.

3. `03_daily_analytics.png`  
   Menampilkan hasil analisis ringkasan harian per stasiun.

4. `04_scrape_run_analytics.png`  
   Menampilkan hasil analisis kualitas batch scraping.

5. `05_data_quality.png`  
   Menampilkan tabel `HASIL VERIFIKASI FAIL-FAST` dengan seluruh status `PASS`, terutama set difference, duplicate grain, missing dimension, dan transformation mismatch.

6. `06_export_restore.png`  
   Menampilkan hasil `restore_warehouse.ps1`, perbandingan jumlah dengan manifest, dan assertion restore yang seluruhnya `PASS`.

Setelah semua screenshot dan export tersedia, jalankan `validate_submission.ps1` dari folder utama.
