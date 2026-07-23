# Revision Notes

Perbaikan utama pada paket ini:

1. `03_verify_and_analyze.sql` diubah menjadi verifikasi fail-fast. Script membandingkan jumlah, natural key, set difference dua arah, hasil transformasi, dimension mapping, dan date/time key. Ketidaksesuaian menghasilkan `RAISE EXCEPTION`.
2. `04_test_idempotency.sql` ditambahkan. Refresh dijalankan dua kali pada snapshot sumber yang sama menggunakan `REPEATABLE READ`; eksekusi kedua wajib menambah nol baris.
3. Upsert `fact_scrape_run` hanya memperbarui baris apabila atribut sumber benar-benar berubah.
4. Constraint audit `etl_batch` diperketat untuk menjaga konsistensi status, timestamp, dan count.
5. ERD dan relational diagram dibuat ulang dari source Graphviz. Relational diagram memuat seluruh kolom, tipe data, PK, AK, dan FK yang sesuai dengan DDL.
6. Dokumentasi desain ditambah dengan kebutuhan analitik, grain, functional dependency, candidate key, translasi relasional, sifat measure, denormalisasi dimensional, SCD Type 1, dan batasan desain.
7. Export manifest sekarang memuat jumlah seluruh tabel. Restore membandingkan seluruh jumlah dengan manifest dan menjalankan assertion integritas pascarestore.
8. `validate_submission.ps1` ditambahkan untuk menolak submission yang belum mempunyai export SQL aktual atau enam screenshot wajib.
9. Folder lama `screenshot/` dihapus. Hanya `screenshots/` yang digunakan.

## Batas paket revisi

Paket ini tidak menyertakan export database aktual atau screenshot hasil PostgreSQL karena database sumber berada pada lingkungan lokal pemilik proyek. Kedua jenis bukti tersebut harus dibuat dengan script yang tersedia sebelum submission.
