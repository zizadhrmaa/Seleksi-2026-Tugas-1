# NDBC PostgreSQL Loader

Program ini membaca `stations.json`, `scraping_report.json`, `observations_manifest.json`, dan seluruh file JSON pada folder `observations`, lalu menyimpannya ke PostgreSQL.

Loader tidak membaca `observations.json` gabungan. File per stasiun digunakan agar ratusan ribu observasi dapat diproses tanpa memuat seluruh dataset ke memori.

## Persiapan database

Buat database PostgreSQL kosong, misalnya `ndbc`.

```powershell
createdb -h localhost -p 5432 -U postgres ndbc
```

Jika database sudah dibuat melalui pgAdmin, langkah tersebut dapat dilewati.

## Build

Jalankan dari folder `Data Storing/src`:

```powershell
dotnet clean
Remove-Item .\bin, .\obj -Recurse -Force -ErrorAction SilentlyContinue
dotnet restore
dotnet build
```

Project menggunakan daftar file `Compile` yang eksplisit. File hasil build atau file C# lain di luar folder source tidak akan ikut dikompilasi.

## Menjalankan loader

```powershell
$env:NDBC_DB_CONNECTION="Host=localhost;Port=5432;Database=ndbc;Username=postgres;Password=PASSWORD"
dotnet run
```

Default path:

```text
Data source : ../../Data Scraping/data
Schema SQL  : ../export/schema.sql
```

Path dapat diganti:

```powershell
dotnet run -- `
  --data "../../Data Scraping/data" `
  --schema "../export/schema.sql" `
  --connection "Host=localhost;Port=5432;Database=ndbc;Username=postgres;Password=PASSWORD"
```

Program bersifat idempotent dan memakai kebijakan **updatable historical data**.

- Metadata stasiun di-upsert berdasarkan `station_id`, tetapi update hanya dilakukan jika nilainya benar-benar berubah. Karena itu, `station.updated_at` tidak berubah pada batch yang hanya memuat metadata sama.
- Observasi baru dimasukkan berdasarkan primary key `(station_id, observed_at_utc)`.
- Observasi dengan key yang sama dan nilai yang sama tidak diubah.
- Observasi dengan key yang sama hanya diperbarui jika salah satu dari delapan nilai meteorologi berubah.
- `first_seen_run_id` tetap mempertahankan batch pertama. Jika nilai meteorologi berubah, metadata sumber (`source_row_number`, `source_url`, dan `extracted_at`) diperbarui bersama koreksi tersebut. Perubahan nomor baris sumber saja tidak memicu update karena nomor baris file real-time dapat bergeser pada batch berikutnya.
- Composite foreign key `(first_seen_run_id, station_id)` memastikan batch pertama benar-benar mengekstrak stasiun tersebut.

Field JSON `quality_flags` sengaja tidak dimuat karena seluruh flag pada dataset tervalidasi kosong. Loader akan menghentikan transaksi jika menemukan `quality_flags` non-kosong agar informasi tidak hilang secara diam-diam.

## Bukti dan export

Setelah loader selesai:

1. Jalankan query pada `../export/verification_queries.sql` melalui pgAdmin atau `psql`.
2. Ambil screenshot hasil query yang menggunakan `SELECT`, `FROM`, dan `WHERE`.
3. Simpan screenshot pada folder `Data Storing/screenshots`.
4. Jalankan `../export/export_database.ps1` untuk menghasilkan export asli PostgreSQL.

`schema.sql` adalah DDL implementasi. File export final untuk pengumpulan harus berasal dari `pg_dump`, misalnya `ndbc_database.sql`.

## Export untuk repository GitHub

Dump satu file dapat melebihi batas ukuran GitHub. Gunakan script berikut dari folder `Data Storing/export`:

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

Script menghasilkan beberapa file `.sql` yang harus dipulihkan berdasarkan urutan nama file. Cara restore dan verifikasinya tersedia pada `../export/README.md`.
