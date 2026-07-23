# Export Data Warehouse

Folder `database_export` harus diisi oleh hasil export aktual schema `ndbc_dw`. File `.gitkeep` bukan bukti export.

## Membuat export

Jalankan setelah load, assertion, dan pengujian idempotensi berhasil:

```powershell
cd ".\Data Warehouse\export"

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
Unblock-File ".\export_warehouse.ps1"

.\export_warehouse.ps1 `
  -PgBin "C:\Program Files\PostgreSQL\13\bin" `
  -HostName localhost `
  -Port 5433 `
  -Database ndbc `
  -Username postgres `
  -OutputDirectory ".\database_export" `
  -MaximumChunkMegabyte 45
```

Script melakukan hal berikut:

- mengekspor pre-data dan post-data schema;
- mengekspor dimension, fact kecil, dan audit ETL;
- membagi `fact_observation` menjadi beberapa file SQL;
- memastikan jumlah baris dump sama dengan jumlah database;
- membuat `export_manifest.txt` yang memuat jumlah seluruh tabel.

## Menguji restore

```powershell
.\restore_warehouse.ps1 `
  -PgBin "C:\Program Files\PostgreSQL\13\bin" `
  -HostName localhost `
  -Port 5433 `
  -Database ndbc_dw_restore_test `
  -Username postgres `
  -InputDirectory ".\database_export" `
  -RecreateDatabase
```

Restore dinyatakan berhasil hanya apabila:

1. seluruh file SQL dapat dipulihkan;
2. jumlah setiap tabel sama dengan manifest;
3. `verify_restored_warehouse.sql` melaporkan seluruh assertion `PASS`;
4. `restore_verification.txt` berhasil dibuat.
