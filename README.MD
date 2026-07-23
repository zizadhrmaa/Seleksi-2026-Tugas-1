# ETL Data Meteorologi Buoy NDBC

Proyek Seleksi Tahap 2 Asisten Laboratorium Basis Data 2026

## Author

| Nama | NIM |
|---|---|
| Aziza Dharma Putri | 13524017 |

## Daftar Isi

1. [Ringkasan Proyek](#ringkasan-proyek)
2. [Alasan Pemilihan Topik](#alasan-pemilihan-topik)
3. [Cakupan Data](#cakupan-data)
4. [Hasil Akhir](#hasil-akhir)
5. [Arsitektur ETL](#arsitektur-etl)
6. [Struktur Repository](#struktur-repository)
7. [Teknologi dan Kebutuhan Sistem](#teknologi-dan-kebutuhan-sistem)
8. [Data Scraping](#data-scraping)
9. [Struktur JSON](#struktur-json)
10. [Data Modeling](#data-modeling)
11. [Translasi ERD ke Diagram Relasional](#translasi-erd-ke-diagram-relasional)
12. [Implementasi PostgreSQL dan Data Storing](#implementasi-postgresql-dan-data-storing)
13. [Export dan Restore Database](#export-dan-restore-database)
14. [Bonus Query Optimization](#bonus-query-optimization)
15. [Bonus Automated Scheduling](#bonus-automated-scheduling)
16. [Screenshot Bukti Implementasi](#screenshot-bukti-implementasi)
17. [Penggunaan AI](#penggunaan-ai)
18. [Catatan Keamanan dan Git](#catatan-keamanan-dan-git)
19. [Troubleshooting](#troubleshooting)
20. [Referensi](#referensi)

## Ringkasan Proyek

Proyek ini mengimplementasikan alur ETL untuk data meteorologi dari stasiun buoy milik National Data Buoy Center atau NDBC. Data diperoleh melalui web scraping tanpa menggunakan API, dibersihkan dan ditransformasikan menjadi JSON terstruktur, kemudian dimuat ke dalam PostgreSQL.

Data utama yang dikumpulkan terdiri dari:

- Metadata stasiun buoy.
- Riwayat pelaksanaan scraping.
- Riwayat keterlibatan stasiun pada setiap batch scraping.
- Observasi arah dan kecepatan angin.
- Observasi hembusan angin.
- Observasi tinggi dan periode gelombang.
- Observasi arah gelombang.
- Observasi suhu permukaan laut.

Database dirancang untuk mendukung penyimpanan data time-series dalam jumlah besar, pembaruan berkala, pelacakan asal data, pencegahan redundansi, dan query analitik yang efisien.

RDBMS yang digunakan adalah **PostgreSQL 13** dengan schema bernama `ndbc`. PostgreSQL dipilih karena mendukung constraint relasional yang lengkap, composite primary key, transaction, trigger, indexing, `COPY`, `ON CONFLICT`, dan fasilitas analisis query melalui `EXPLAIN ANALYZE`.

## Alasan Pemilihan Topik

Topik data meteorologi buoy dipilih karena memiliki karakteristik yang relevan untuk proyek basis data, yaitu:

1. Data diperbarui secara berkala sehingga sesuai untuk penerapan automated scheduling.
2. Setiap stasiun menghasilkan banyak observasi time-series sehingga dapat menguji desain primary key, indexing, dan performa query.
3. Data memiliki beberapa entitas yang jelas, seperti penyedia data, stasiun, batch scraping, dan observasi.
4. Sebagian nilai pengukuran dapat tidak tersedia sehingga diperlukan proses cleaning dan penanganan `NULL`.
5. Data memiliki informasi lokasi, waktu, angin, gelombang, dan suhu yang dapat digunakan untuk analisis lanjutan.
6. Dataset berukuran cukup besar untuk menunjukkan perbedaan nyata antara query sebelum dan setelah optimasi.

## Cakupan Data

Sumber daftar stasiun:

```text
https://www.ndbc.noaa.gov/to_station.shtml
```

Scraper mengambil kandidat dari bagian **National Data Buoy Center Stations**, kemudian memeriksa halaman detail setiap stasiun dan mengambil file standard meteorological real-time apabila stasiun teridentifikasi sebagai buoy dan data tersedia.

Pola halaman detail:

```text
https://www.ndbc.noaa.gov/station_page.php?station={station_id}
```

Pola sumber data meteorologi real-time:

```text
https://www.ndbc.noaa.gov/data/realtime2/{station_id}.txt
```

Kolom pengukuran utama yang diproses:

| Kode NDBC | Atribut JSON/Database | Keterangan | Satuan |
|---|---|---|---|
| `WDIR` | `wind_direction_degree` | Arah angin | derajat |
| `WSPD` | `wind_speed_meter_per_second` | Kecepatan angin | m/s |
| `GST` | `wind_gust_meter_per_second` | Kecepatan hembusan angin | m/s |
| `WVHT` | `wave_height_meter` | Tinggi gelombang signifikan | meter |
| `DPD` | `dominant_wave_period_second` | Periode gelombang dominan | detik |
| `APD` | `average_wave_period_second` | Periode gelombang rata-rata | detik |
| `MWD` | `mean_wave_direction_degree` | Arah gelombang rata-rata | derajat |
| `WTMP` | `sea_surface_temperature_celsius` | Suhu permukaan laut | °C |

Nilai `MM` pada sumber NDBC diperlakukan sebagai data yang tidak tersedia dan ditransformasikan menjadi `null` pada JSON serta `NULL` pada PostgreSQL.

## Hasil Akhir

### Batch utama

| Metrik | Nilai |
|---|---:|
| Stasiun berhasil | 90 |
| Observasi batch pertama | 571.167 |
| Duplikasi hasil preprocessing | 0 |
| RDBMS | PostgreSQL 13 |
| Schema | `ndbc` |

### Setelah automated scheduling

| Batch | Observasi sumber | Observasi baru | Observasi overlap | Total database | Duplikasi |
|---|---:|---:|---:|---:|---:|
| Pipeline manual pertama | 573.334 | 2.179 | 571.155 | 573.346 | 0 |
| Eksekusi melalui Task Scheduler | 573.463 | 129 | 573.334 | 573.475 | 0 |

Export database pada folder `Data Storing/export/database_export` merupakan **baseline snapshot** setelah batch utama, yaitu 90 stasiun dan 571.167 observasi. Export tersebut telah diuji dengan restore ke database baru dan menghasilkan jumlah data yang sama. Automated scheduling dijalankan setelah snapshot dibuat, sehingga jumlah pada database operasional dapat lebih besar daripada jumlah pada export baseline. Perbedaan tersebut disengaja dan didokumentasikan, bukan kehilangan atau inkonsistensi data.

## Arsitektur ETL

```text
NDBC station list web page
        |
        v
Pemeriksaan robots.txt dan daftar kandidat stasiun
        |
        v
Halaman detail stasiun + file meteorologi real-time
        |
        v
Parsing, cleaning, validation, transformation, deduplication
        |
        v
JSON per entitas dan JSON observasi per stasiun
        |
        v
Validasi data sumber oleh loader
        |
        v
PostgreSQL schema ndbc
        |
        v
Verification, export, query optimization, automated scheduling
```

## Struktur Repository

```text
Seleksi-2026-Tugas-1/
├── Data Scraping/
│   ├── data/
│   │   ├── checkpoints/
│   │   │   └── progress.json
│   │   ├── observations/
│   │   │   ├── 41001.json
│   │   │   ├── 41002.json
│   │   │   └── ...
│   │   ├── errors.json
│   │   ├── observations.json
│   │   ├── observations_manifest.json
│   │   ├── scraping_report.json
│   │   ├── skipped_stations.json
│   │   └── stations.json
│   └── src/
│       ├── Configuration/
│       ├── Http/
│       ├── Models/
│       ├── Parsing/
│       ├── Persistence/
│       ├── Scrapers/
│       ├── Services/
│       ├── Utilities/
│       ├── Validation/
│       ├── NdbcScraper.csproj
│       └── Program.cs
├── Data Storing/
│   ├── design/
│   │   ├── erd.png
│   │   ├── relational_diagram.png
│   │   └── modeling_notes.md
│   ├── export/
│   │   ├── database_export/
│   │   ├── export_database.ps1
│   │   ├── restore_database.ps1
│   │   ├── schema.sql
│   │   └── verification_queries.sql
│   ├── screenshots/
│   └── src/
│       ├── Configuration/
│       ├── Models/
│       ├── Persistence/
│       ├── Services/
│       ├── Utilities/
│       ├── NdbcDataLoader.csproj
│       └── Program.cs
├── Query Optimasi/
│   ├── screenshots/
│   └── query_optimization.sql
├── Automated Scheduling/
│   ├── config/
│   ├── history/
│   ├── screenshots/
│   ├── scripts/
│   ├── sql/
│   ├── .gitignore
│   └── README.md
├── .gitignore
└── README.md
```

`observations.json` adalah file gabungan lokal yang dapat berukuran sangat besar. Data observasi yang disimpan di repository dibagi menjadi file per stasiun pada folder `Data Scraping/data/observations` dan dideskripsikan oleh `observations_manifest.json`.

## Teknologi dan Kebutuhan Sistem

### Teknologi

| Komponen | Teknologi |
|---|---|
| Bahasa scraper | C# |
| Runtime | .NET 10 |
| HTML parser | HtmlAgilityPack 1.12.4 |
| Bahasa loader | C# |
| PostgreSQL driver | Npgsql 10.0.3 |
| RDBMS | PostgreSQL 13 |
| Automation | PowerShell dan Windows Task Scheduler |
| Format output | JSON dan SQL |

### Kebutuhan

- .NET SDK 10.
- PostgreSQL 13 atau versi kompatibel.
- PowerShell untuk script export, restore, dan scheduling.
- Koneksi internet untuk menjalankan scraper.
- Ruang penyimpanan yang cukup untuk JSON observasi dan database PostgreSQL.

Perintah pemeriksaan versi:

```powershell
dotnet --version
& "C:\Program Files\PostgreSQL\13\bin\psql.exe" --version
$PSVersionTable.PSVersion
```

## Data Scraping

### Etika scraping

Scraper melakukan beberapa langkah untuk mengurangi beban dan menjaga keterlacakan proses:

- Memeriksa kebijakan `robots.txt` sebelum scraping.
- Mengambil data dari halaman web dan file teks publik, bukan API.
- Memberikan jeda antar-request. Default jeda adalah satu detik.
- Melakukan request secara berurutan dan tidak melakukan flooding.
- Hanya mengambil kolom meteorologi yang diperlukan.
- Mencatat URL sumber dan timestamp ekstraksi pada output.
- Mencatat stasiun yang dilewati dan error secara terpisah.

### Menjalankan scraper

Buka terminal dari folder `Data Scraping/src`:

```powershell
cd "Data Scraping\src"
dotnet restore
dotnet build
dotnet run -- --limit 90 --delay-seconds 1 --output "..\data"
```

Opsi yang tersedia:

| Opsi | Fungsi | Default |
|---|---|---|
| `--limit <jumlah>` | Target jumlah stasiun buoy yang berhasil | 100 |
| `--delay-seconds <detik>` | Jeda minimum antar-request | 1.0 |
| `--output <folder>` | Folder output JSON | `../data` saat dijalankan dari `src` |
| `--resume` | Melanjutkan proses dari checkpoint | tidak aktif |

Contoh uji dengan data kecil:

```powershell
dotnet run -- --limit 5 --delay-seconds 1 --output "..\data-test"
```

Melanjutkan scraping yang terhenti:

```powershell
dotnet run -- --resume --limit 90 --output "..\data"
```

Menjalankan program tanpa `--resume` akan memulai batch baru dan mengganti output run sebelumnya pada folder tujuan.

### Tahap preprocessing

Scraper melakukan preprocessing berikut:

1. **Filtering kandidat**  
   Hanya kandidat pada kelompok NDBC yang teridentifikasi sebagai buoy dan mempunyai standard meteorological real-time data yang diproses sebagai stasiun berhasil.

2. **Parsing metadata**  
   Nama, lokasi, pemilik, tipe perangkat, payload, koordinat, kedalaman, status, dan URL sumber diambil dari halaman detail stasiun.

3. **Parsing waktu**  
   Komponen tahun, bulan, tanggal, jam, dan menit dikonversi menjadi timestamp UTC.

4. **Cleaning missing value**  
   Nilai `MM` dan nilai kosong dikonversi menjadi `null`.

5. **Transformation satuan dan tipe**  
   Kolom numerik dikonversi menjadi `int` atau `double` sesuai kebutuhan database.

6. **Validation**  
   Nilai arah, kecepatan, periode, tinggi gelombang, dan temperatur diperiksa sebelum disimpan.

7. **Row filtering**  
   Baris yang seluruh delapan nilai pengukurannya `null` tidak dimasukkan.

8. **Deduplication**  
   Observasi pada satu stasiun dideduplicasi berdasarkan timestamp `observed_at_utc`. Apabila terdapat lebih dari satu baris pada waktu yang sama, versi dengan pengukuran paling lengkap dipertahankan.

9. **Diagnostics**  
   Stasiun yang tidak sesuai kriteria, data yang tidak tersedia, dan error parsing dicatat pada file terpisah.

### Menggunakan hasil output scraper

Output dapat digunakan melalui dua cara:

1. Membaca JSON langsung untuk analisis atau pemrosesan lain.
2. Menjalankan loader pada `Data Storing/src` untuk memasukkan data ke PostgreSQL.

Loader menggunakan:

```text
stations.json
scraping_report.json
observations_manifest.json
observations/{station_id}.json
```

Loader sengaja tidak bergantung pada `observations.json` gabungan agar ratusan ribu baris dapat diproses per file stasiun tanpa memuat seluruh dataset ke memori sekaligus.

## Struktur JSON

Semua nama properti menggunakan `snake_case` agar konsisten dengan nama kolom PostgreSQL.

### `stations.json`

File berupa array objek metadata stasiun.

```json
[
  {
    "scrape_run_id": "ndbc-20260723-061419-0c3bbdce81",
    "station_id": "41001",
    "station_name": "EAST HATTERAS",
    "location": "150 NM East of Cape Hatteras",
    "owner": "National Data Buoy Center",
    "device_type": "3-meter foam buoy",
    "payload": "SCOOP payload",
    "latitude": 34.791,
    "longitude": -72.42,
    "water_depth_meter": 4450,
    "status": "ACTIVE",
    "detail_url": "https://www.ndbc.noaa.gov/station_page.php?station=41001",
    "realtime_data_url": "https://www.ndbc.noaa.gov/data/realtime2/41001.txt",
    "extracted_at": "2026-07-23T06:14:57.2974743+00:00"
  }
]
```

| Properti | Tipe | Keterangan |
|---|---|---|
| `scrape_run_id` | string | ID unik batch scraping |
| `station_id` | string | ID stasiun NDBC |
| `station_name` | string/null | Nama stasiun |
| `location` | string/null | Deskripsi lokasi |
| `owner` | string | Pemilik atau penyedia data |
| `device_type` | string/null | Jenis buoy/perangkat |
| `payload` | string/null | Jenis payload stasiun |
| `latitude` | number/null | Lintang |
| `longitude` | number/null | Bujur |
| `water_depth_meter` | number/null | Kedalaman air dalam meter |
| `status` | string | Status stasiun |
| `detail_url` | string | URL halaman detail |
| `realtime_data_url` | string | URL file meteorologi real-time |
| `extracted_at` | ISO-8601 timestamp | Waktu metadata diekstrak |

### `observations/{station_id}.json`

Setiap file berisi array observasi dari satu stasiun. Pemisahan per stasiun menghindari satu file JSON repository yang terlalu besar.

```json
[
  {
    "scrape_run_id": "ndbc-20260723-061419-0c3bbdce81",
    "station_id": "41001",
    "observed_at_utc": "2026-06-08T00:00:00+00:00",
    "wind_direction_degree": 230,
    "wind_speed_meter_per_second": 8,
    "wind_gust_meter_per_second": 10,
    "wave_height_meter": null,
    "dominant_wave_period_second": null,
    "average_wave_period_second": null,
    "mean_wave_direction_degree": null,
    "sea_surface_temperature_celsius": 23.5,
    "quality_flags": [],
    "source_row_number": 6450,
    "source_url": "https://www.ndbc.noaa.gov/data/realtime2/41001.txt",
    "extracted_at": "2026-07-23T06:14:57.2974743+00:00"
  }
]
```

| Properti | Tipe | Keterangan |
|---|---|---|
| `scrape_run_id` | string | Batch yang mengekstrak observasi |
| `station_id` | string | Stasiun pemilik observasi |
| `observed_at_utc` | ISO-8601 timestamp | Waktu observasi dalam UTC |
| `wind_direction_degree` | integer/null | Arah angin 0–360° |
| `wind_speed_meter_per_second` | number/null | Kecepatan angin |
| `wind_gust_meter_per_second` | number/null | Hembusan angin |
| `wave_height_meter` | number/null | Tinggi gelombang |
| `dominant_wave_period_second` | number/null | Periode dominan |
| `average_wave_period_second` | number/null | Periode rata-rata |
| `mean_wave_direction_degree` | integer/null | Arah gelombang rata-rata |
| `sea_surface_temperature_celsius` | number/null | Suhu permukaan laut |
| `quality_flags` | array string | Penanda kualitas hasil validasi scraper |
| `source_row_number` | integer | Nomor baris pada sumber |
| `source_url` | string | URL asal observasi |
| `extracted_at` | ISO-8601 timestamp | Waktu data diekstrak |

Pada dataset yang divalidasi, seluruh `quality_flags` bernilai array kosong. Field tersebut sengaja tidak dimuat ke PostgreSQL pada versi ini. Loader tetap membaca field tersebut dan membatalkan transaction apabila menemukan flag non-kosong agar informasi kualitas tidak hilang secara diam-diam. Perluasan berikutnya dapat memakai relation terpisah `observation_quality_flag`.

### `observations.json`

File ini adalah gabungan seluruh observasi dari semua stasiun. Struktur setiap elemennya sama dengan file per stasiun.

File gabungan berguna untuk inspeksi lokal, tetapi dapat melampaui batas ukuran file GitHub. Karena itu, repository menggunakan file per stasiun dan manifest sebagai sumber utama loader.

Pada automated pipeline, file gabungan dihapus setelah loading berhasil untuk menghemat ruang penyimpanan.

### `observations_manifest.json`

Manifest berisi ringkasan seluruh file observasi.

```json
{
  "scrape_run_id": "ndbc-20260723-061419-0c3bbdce81",
  "generated_at": "2026-07-23T06:24:10.3084876+00:00",
  "total_station_count": 90,
  "total_observation_count": 571167,
  "combined_file": "observations.json",
  "combined_file_git_ignored": true,
  "station_files": [
    {
      "station_id": "41001",
      "relative_path": "observations/41001.json",
      "observation_count": 6448,
      "first_observed_at_utc": "2026-06-08T00:00:00+00:00",
      "last_observed_at_utc": "2026-07-23T05:40:00+00:00",
      "file_size_bytes": 4177399
    }
  ]
}
```

| Properti | Keterangan |
|---|---|
| `scrape_run_id` | ID batch |
| `generated_at` | Waktu manifest dibuat |
| `total_station_count` | Jumlah file/stasiun observasi |
| `total_observation_count` | Total observasi seluruh file |
| `combined_file` | Nama file gabungan lokal |
| `combined_file_git_ignored` | Penanda bahwa file gabungan tidak perlu di-commit |
| `station_files` | Daftar file observasi per stasiun |

Setiap elemen `station_files` menyimpan ID stasiun, path relatif, jumlah observasi, rentang waktu observasi, dan ukuran file.

### `scraping_report.json`

File ini menyimpan metadata satu pelaksanaan scraper.

| Properti | Keterangan |
|---|---|
| `scrape_run_id` | ID unik batch |
| `started_at` | Waktu mulai scraping |
| `finished_at` | Waktu selesai scraping |
| `target_station_count` | Target stasiun berhasil |
| `target_met` | Apakah target terpenuhi |
| `source_candidate_count` | Jumlah kandidat pada daftar sumber |
| `processed_candidate_count` | Jumlah kandidat yang diperiksa |
| `successful_station_count` | Jumlah stasiun berhasil |
| `skipped_non_buoy_count` | Jumlah kandidat bukan buoy |
| `skipped_no_data_count` | Jumlah stasiun tanpa data meteorologi real-time |
| `failed_attempt_count` | Jumlah attempt yang gagal |
| `total_observation_count` | Total observasi hasil preprocessing |
| `duplicate_observation_count` | Duplikasi yang ditemukan saat preprocessing |
| `station_list_source_url` | URL daftar stasiun |
| `output_directory` | Folder output batch |

### `skipped_stations.json`

Berisi kandidat yang tidak dimasukkan, misalnya karena bukan buoy atau file meteorologi real-time tidak tersedia.

Properti penting:

- `scrape_run_id`
- `station_id`
- `reason_code`
- `message`
- `detail_url`
- `realtime_data_url`
- `http_status_code`
- `skipped_at`

### `errors.json`

Berisi error yang tidak dapat diselesaikan oleh retry atau proses parsing. File dapat berupa array kosong ketika tidak ada error.

Properti error meliputi:

- `scrape_run_id`
- `station_id`
- `scope`
- `error_code`
- `message`
- `source_url`
- `source_row_number`
- `raw_data`
- `http_status_code`
- `attempt_count`
- `occurred_at`

### `checkpoints/progress.json`

Checkpoint menyimpan progres batch agar proses dapat dilanjutkan dengan opsi `--resume`. File ini merupakan data runtime dan bukan bagian utama dari model relasional.

## Data Modeling

### ERD

![ERD NDBC](Data%20Storing/design/erd.png)

ERD terdiri dari empat entity utama dan empat relationship konseptual:

#### `DATA_PROVIDER`

Strong entity yang menyimpan penyedia data.

- Primary key: `provider_id`
- Candidate key: `provider_name`
- Candidate key: `base_url`

#### `SCRAPE_RUN`

Strong entity yang menyimpan satu eksekusi scraper, termasuk waktu, jumlah kandidat, jumlah stasiun berhasil, dan jumlah observasi sumber.

- Primary key: `scrape_run_id`

#### `STATION`

Strong entity yang menyimpan metadata terbaru setiap stasiun buoy.

- Primary key: `station_id`
- Candidate key: `detail_url`
- Candidate key: `realtime_data_url`

#### `OBSERVATION`

Weak entity yang keberadaannya bergantung pada `STATION`.

- Partial key: `observed_at_utc`
- Identitas lengkap: `(station_id, observed_at_utc)`

#### Relationship `OPERATES`

```text
DATA_PROVIDER 0..* <-> 1..1 STATION
```

Satu provider dapat mengoperasikan nol atau banyak stasiun. Setiap stasiun wajib memiliki tepat satu provider.

#### Relationship `EXTRACTS`

```text
SCRAPE_RUN 0..* <-> 0..* STATION
```

Satu batch dapat mengekstrak banyak stasiun dan satu stasiun dapat muncul pada banyak batch. Relationship memiliki descriptive attribute `extracted_at`.

#### Relationship `RECORDS`

```text
STATION 0..* <-> 1..1 OBSERVATION
```

Satu stasiun dapat memiliki nol atau banyak observasi. Setiap observasi wajib dimiliki tepat satu stasiun. Relationship ini merupakan identifying relationship untuk weak entity `OBSERVATION`.

#### Relationship `FIRST_SEEN_IN`

```text
SCRAPE_RUN 0..* <-> 1..1 OBSERVATION
```

Satu batch dapat menjadi batch pertama bagi banyak observasi. Setiap observasi menyimpan tepat satu batch ketika pertama kali masuk ke database.

### Arti notasi kardinalitas

| Notasi | Arti |
|---|---|
| `0..1` | Opsional, maksimal satu |
| `1..1` | Wajib tepat satu |
| `0..*` | Opsional, dapat banyak |
| `1..*` | Wajib minimal satu, dapat banyak |

Angka pertama menyatakan partisipasi minimum dan angka kedua menyatakan kardinalitas maksimum.

### Asumsi model

1. Setiap stasiun dioperasikan oleh tepat satu provider.
2. Satu provider dapat mengoperasikan nol atau lebih stasiun.
3. Satu proses scraping dapat mengekstrak nol atau lebih stasiun.
4. Satu stasiun dapat muncul dalam nol atau lebih proses scraping.
5. Waktu `extracted_at` pada `EXTRACTS` bergantung pada pasangan batch dan stasiun.
6. `OBSERVATION` adalah weak entity milik `STATION`.
7. Partial key observasi adalah `observed_at_utc`.
8. Setiap observasi pertama kali diperoleh melalui tepat satu `SCRAPE_RUN`.
9. Nilai pengukuran yang tidak tersedia disimpan sebagai `NULL`.
10. Setiap tuple observasi wajib memiliki minimal satu nilai pengukuran yang tidak `NULL`.
11. Metadata pada `STATION` menyimpan versi terbaru, sedangkan riwayat batch disimpan pada `STATION_EXTRACTION`.
12. Atribut audit `created_at`, `updated_at`, dan `loaded_at` ditambahkan pada implementasi fisik.

Dokumentasi model lebih detail tersedia pada:

```text
Data Storing/design/modeling_notes.md
```

### Diagram relasional

![Diagram Relasional NDBC](Data%20Storing/design/relational_diagram.png)

Relation yang diimplementasikan:

```text
data_provider(
    provider_id PK,
    provider_name UQ,
    base_url UQ
)

scrape_run(
    scrape_run_id PK,
    started_at,
    finished_at,
    target_station_count,
    target_met,
    source_candidate_count,
    processed_candidate_count,
    successful_station_count,
    skipped_non_buoy_count,
    skipped_no_data_count,
    failed_attempt_count,
    total_observation_count,
    duplicate_observation_count,
    station_list_source_url,
    source_output_directory,
    loaded_at
)

station(
    station_id PK,
    provider_id FK -> data_provider.provider_id,
    station_name,
    location,
    device_type,
    payload,
    latitude,
    longitude,
    water_depth_meter,
    status,
    detail_url UQ,
    realtime_data_url UQ,
    created_at,
    updated_at
)

station_extraction(
    scrape_run_id PK, FK -> scrape_run.scrape_run_id,
    station_id PK, FK -> station.station_id,
    extracted_at
)

observation(
    station_id PK, FK -> station.station_id,
    observed_at_utc PK,
    first_seen_run_id FK -> scrape_run.scrape_run_id,
    (first_seen_run_id, station_id) FK
        -> station_extraction(scrape_run_id, station_id),
    wind_direction_degree,
    wind_speed_meter_per_second,
    wind_gust_meter_per_second,
    wave_height_meter,
    dominant_wave_period_second,
    average_wave_period_second,
    mean_wave_direction_degree,
    sea_surface_temperature_celsius,
    source_row_number,
    source_url,
    extracted_at,
    loaded_at
)
```

## Translasi ERD ke Diagram Relasional

Translasi dilakukan menggunakan aturan berikut:

### 1. Strong entity menjadi relation

Setiap strong entity diterjemahkan menjadi satu relation dengan primary key yang sama:

- `DATA_PROVIDER` menjadi `data_provider`.
- `SCRAPE_RUN` menjadi `scrape_run`.
- `STATION` menjadi `station`.

### 2. Relationship 1:N `OPERATES`

`OPERATES` menghubungkan satu provider dengan banyak stasiun. Karena `STATION` berpartisipasi total, primary key `DATA_PROVIDER` dipindahkan ke sisi N sebagai foreign key:

```text
station.provider_id -> data_provider.provider_id
```

Relationship tidak memerlukan relation terpisah karena tidak memiliki descriptive attribute.

### 3. Relationship M:N `EXTRACTS`

Relationship M:N harus menjadi relation tersendiri:

```text
station_extraction(
    scrape_run_id,
    station_id,
    extracted_at
)
```

Primary key-nya adalah gabungan:

```text
(scrape_run_id, station_id)
```

`extracted_at` dipertahankan sebagai descriptive attribute relationship.

### 4. Weak entity `OBSERVATION`

Weak entity membawa primary key owner `STATION`. Partial key `observed_at_utc` digabungkan dengan `station_id` sehingga primary key relation menjadi:

```text
(station_id, observed_at_utc)
```

Composite primary key tersebut juga menjadi mekanisme utama pencegahan observasi duplikat.

### 5. Relationship 1:N `FIRST_SEEN_IN`

Primary key dari `SCRAPE_RUN` dipindahkan ke sisi N, yaitu `OBSERVATION`, sebagai:

```text
observation.first_seen_run_id -> scrape_run.scrape_run_id
```

Atribut ini menyimpan batch pertama yang berhasil memasukkan observasi ke database.

### 6. Atribut audit dan batas diagram

ERD digunakan sebagai model konseptual, sedangkan diagram relasional digunakan sebagai model logis hasil translasi. Kolom audit berikut merupakan keputusan implementasi fisik PostgreSQL:

- `station.created_at`
- `station.updated_at`
- `scrape_run.loaded_at`
- `observation.loaded_at`

Kolom audit tidak ditambahkan ke ERD karena bukan atribut domain utama. Kolom tersebut juga tidak harus ditampilkan pada diagram relasional logis selama perbedaannya didokumentasikan. `schema.sql` menjadi sumber kebenaran untuk seluruh kolom fisik. Penjelasan lengkap tersedia pada `Data Storing/design/modeling_notes.md`.

### 7. Normalisasi

Functional dependency utama:

```text
provider_id -> provider_name, base_url
provider_name -> provider_id, base_url
base_url -> provider_id, provider_name

scrape_run_id -> seluruh atribut non-key scrape_run

station_id -> seluruh atribut non-key station
detail_url -> seluruh atribut station
realtime_data_url -> seluruh atribut station

(scrape_run_id, station_id) -> extracted_at

(station_id, observed_at_utc) -> seluruh atribut non-key observation
```

Relation inti dirancang untuk menghindari repeating group, partial dependency, dan anomaly utama. Namun proyek ini tidak mengklaim bahwa seluruh schema berada dalam BCNF tanpa pengecualian.

Beberapa atribut ringkasan dan audit dipertahankan sebagai denormalisasi terkontrol. Contohnya, `scrape_run.target_met` dapat diturunkan dari `successful_station_count` dan `target_station_count`, sedangkan beberapa jumlah pada `scrape_run` saling berkaitan melalui constraint. Atribut tersebut dipertahankan untuk audit ETL dan kemudahan verifikasi. Konsistensinya dijaga dengan `CHECK`, foreign key, trigger, dan proses loading.

Translasi entity dan relationship utama bersifat lossless karena primary key dan foreign key mempertahankan identitas model asal. Penjelasan normalisasi dan asumsi tersedia pada `Data Storing/design/modeling_notes.md`.

## Implementasi PostgreSQL dan Data Storing

### Schema dan constraint

DDL tersedia pada:

```text
Data Storing/export/schema.sql
```

Constraint yang diimplementasikan meliputi:

- Primary key pada seluruh relation.
- Composite primary key pada `station_extraction`.
- Composite primary key pada `observation`.
- Foreign key untuk menjaga referential integrity.
- Composite foreign key `observation(first_seen_run_id, station_id)` ke `station_extraction(scrape_run_id, station_id)` agar batch pertama observasi benar-benar mengekstrak stasiun tersebut.
- Unique constraint pada nama provider dan URL.
- `NOT NULL` pada atribut wajib.
- `CHECK` untuk koordinat, arah, nilai nonnegatif, rentang suhu, urutan waktu, konsistensi statistik scraping, dan minimal satu pengukuran.
- Trigger untuk audit waktu update metadata stasiun.
- Trigger untuk memastikan waktu ekstraksi berada dalam rentang waktu batch.

Trigger yang digunakan:

1. `trg_station_set_updated_at`  
   Mengubah `station.updated_at` secara otomatis saat metadata stasiun diperbarui.

2. `trg_station_extraction_validate_time`  
   Memastikan `station_extraction.extracted_at` berada di antara `scrape_run.started_at` dan `scrape_run.finished_at`.

Database juga menyediakan view:

```text
ndbc.station_observation_summary
```

View tersebut menampilkan jumlah observasi serta waktu observasi pertama dan terakhir untuk setiap stasiun.

### Membuat database

Contoh environment proyek menggunakan PostgreSQL pada port `5433`:

```powershell
$pgBin = "C:\Program Files\PostgreSQL\13\bin"
& "$pgBin\createdb.exe" -U postgres -h localhost -p 5433 ndbc
```

Apabila database `ndbc` sudah ada, langkah ini dilewati.

### Build loader

```powershell
cd "Data Storing\src"
dotnet clean
Remove-Item .\bin, .\obj -Recurse -Force -ErrorAction SilentlyContinue
dotnet restore
dotnet build
```

### Menjalankan loader

Gunakan environment variable agar password tidak ditulis di source code:

```powershell
$env:NDBC_DB_CONNECTION = "Host=localhost;Port=5433;Database=ndbc;Username=postgres;Password=PASSWORD_POSTGRES"
dotnet run
```

Path default ketika perintah dijalankan dari `Data Storing/src`:

```text
Data source : ../../Data Scraping/data
Schema SQL  : ../export/schema.sql
```

Path dapat diberikan secara eksplisit:

```powershell
dotnet run -- `
  --data "../../Data Scraping/data" `
  --schema "../export/schema.sql" `
  --connection "Host=localhost;Port=5433;Database=ndbc;Username=postgres;Password=PASSWORD_POSTGRES"
```

### Mekanisme loading

1. Membaca `scraping_report.json`.
2. Membaca `stations.json`.
3. Membaca `observations_manifest.json`.
4. Memvalidasi bahwa jumlah dan referensi file konsisten.
5. Menjalankan `schema.sql`.
6. Membuka transaction PostgreSQL.
7. Memuat metadata batch dan stasiun.
8. Menggunakan binary `COPY` ke temporary import table untuk data besar.
9. Menggabungkan temporary data ke tabel utama.
10. Melakukan commit apabila seluruh proses berhasil.
11. Melakukan rollback apabila terjadi kegagalan sebelum commit.

Program bersifat idempotent dan memakai kebijakan **updatable historical data**:

- `station` di-upsert berdasarkan `station_id`, tetapi update hanya dilakukan jika metadata berubah. Hal ini mencegah `updated_at` berubah hanya karena batch baru membaca metadata yang sama.
- `station_extraction` di-upsert berdasarkan `(scrape_run_id, station_id)` dan hanya diperbarui jika `extracted_at` berubah.
- `observation` memakai `ON CONFLICT (station_id, observed_at_utc) DO UPDATE` dengan kondisi `IS DISTINCT FROM`.
- Observasi baru dimasukkan sebagai tuple baru.
- Observasi lama yang nilainya sama tidak diubah.
- Observasi lama hanya diperbarui jika salah satu dari delapan nilai meteorologi berubah. `first_seen_run_id` tetap mempertahankan batch pertama. Jika nilai meteorologi berubah, metadata sumber diperbarui bersama versi koreksi tersebut. Perubahan nomor baris sumber saja tidak dianggap koreksi karena baris file real-time dapat bergeser antarbatch.

Loader menampilkan jumlah observasi baru, observasi lama yang diperbarui, dan overlap yang tidak berubah. Primary key tetap menjamin bahwa satu key observasi hanya memiliki satu tuple.

### Verifikasi database

```powershell
$pgBin = "C:\Program Files\PostgreSQL\13\bin"
$repo = "D:\ZIZAKAYA\Asisten Basis Data\Seleksi-2026-Tugas-1"

& "$pgBin\psql.exe" `
  -U postgres `
  -h localhost `
  -p 5433 `
  -d ndbc `
  -f "$repo\Data Storing\export\verification_queries.sql"
```

Contoh query `SELECT FROM WHERE`:

```sql
SELECT
    s.station_id,
    s.station_name,
    o.observed_at_utc,
    o.wind_speed_meter_per_second,
    o.wave_height_meter,
    o.sea_surface_temperature_celsius
FROM ndbc.station AS s
JOIN ndbc.observation AS o
    ON o.station_id = s.station_id
WHERE o.wind_speed_meter_per_second IS NOT NULL
ORDER BY o.observed_at_utc DESC
LIMIT 20;
```

## Export dan Restore Database

Export dibuat dengan `pg_dump` dan dipecah agar setiap file berada di bawah batas ukuran GitHub.

Struktur export:

```text
Data Storing/export/database_export/
├── 00_database_pre.sql
├── 10_observation_001.sql
├── 10_observation_002.sql
├── 10_observation_003.sql
├── 99_database_post.sql
└── export_manifest.txt
```

- `00_database_pre.sql` berisi bagian awal dump, schema, function, dan tabel awal.
- `10_observation_*.sql` berisi data `COPY` untuk tabel observasi.
- `99_database_post.sql` berisi data tabel lain, sequence, constraint, index, trigger, dan bagian akhir dump.
- `export_manifest.txt` berisi urutan dan jumlah data pada setiap chunk.

### Membuat export

```powershell
cd "Data Storing\export"
$env:PGPASSWORD = "PASSWORD_POSTGRES"

.\export_database.ps1 `
  -PgBin "C:\Program Files\PostgreSQL\13\bin" `
  -HostName localhost `
  -Port 5433 `
  -Database ndbc `
  -Username postgres `
  -OutputDirectory ".\database_export"
```

### Restore ke database pengujian

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

Verifikasi restore:

```powershell
& "C:\Program Files\PostgreSQL\13\bin\psql.exe" `
  -U postgres `
  -h localhost `
  -p 5433 `
  -d ndbc_restore_test `
  -c "SELECT (SELECT COUNT(*) FROM ndbc.station) AS total_stations, (SELECT COUNT(*) FROM ndbc.observation) AS total_observations;"
```

Hasil restore yang telah diuji:

```text
total_stations     = 90
total_observations = 571167
```

Export tersebut adalah baseline snapshot sebelum automated scheduling. Database operasional kemudian menerima batch tambahan dan dapat memiliki jumlah observasi lebih besar. Jika export dibuat ulang dari kondisi terbaru, restore test dan pencatatan jumlah harus diulang.

## Bonus Query Optimization

Seluruh query optimasi tersedia dalam satu file:

```text
Query Optimasi/query_optimization.sql
```

File memuat:

- Query sebelum optimasi.
- `EXPLAIN ANALYZE` sebelum optimasi.
- Pembuatan index atau perubahan bentuk predicate.
- Query setelah optimasi.
- `EXPLAIN ANALYZE` setelah optimasi.
- Validasi bahwa output sebelum dan sesudah sama menggunakan `EXCEPT ALL`.

### Menjalankan query optimization

```powershell
$pgBin = "C:\Program Files\PostgreSQL\13\bin"
$repo = "D:\ZIZAKAYA\Asisten Basis Data\Seleksi-2026-Tugas-1"

& "$pgBin\psql.exe" `
  -U postgres `
  -h localhost `
  -p 5433 `
  -d ndbc `
  -f "$repo\Query Optimasi\query_optimization.sql"
```

### Query 1: observasi pada satu tanggal

Masalah awal:

```sql
WHERE observed_at_utc::date = DATE '2026-07-20'
```

Cast pada kolom menyebabkan predicate tidak sargable dan menghasilkan `Parallel Seq Scan`.

Optimasi:

```sql
WHERE observed_at_utc >= TIMESTAMPTZ '2026-07-20 00:00:00+07'
  AND observed_at_utc <  TIMESTAMPTZ '2026-07-21 00:00:00+07'
```

Index:

```sql
CREATE INDEX idx_observation_time_station_cover
ON ndbc.observation (observed_at_utc, station_id)
INCLUDE (
    wind_speed_meter_per_second,
    wave_height_meter,
    sea_surface_temperature_celsius
);
```

### Query 2: kejadian angin kencang

Masalah awal:

```sql
WHERE COALESCE(wind_speed_meter_per_second, -1) >= 15
```

Fungsi pada kolom menyebabkan pencarian tidak menggunakan B-tree index secara langsung.

Optimasi:

```sql
WHERE wind_speed_meter_per_second >= 15
```

Partial covering index:

```sql
CREATE INDEX idx_observation_high_wind
ON ndbc.observation (
    wind_speed_meter_per_second DESC,
    observed_at_utc DESC,
    station_id
)
INCLUDE (wind_gust_meter_per_second)
WHERE wind_speed_meter_per_second IS NOT NULL;
```

### Query 3: observasi terbaru setiap stasiun

Query awal menggunakan `ROW_NUMBER()` untuk seluruh 571.167 baris dan menghasilkan `WindowAgg`, external merge sort, dan temporary disk I/O.

Optimasi menggunakan PostgreSQL `DISTINCT ON`:

```sql
SELECT DISTINCT ON (station_id)
    station_id,
    observed_at_utc,
    wind_speed_meter_per_second,
    wave_height_meter,
    sea_surface_temperature_celsius
FROM ndbc.observation
ORDER BY station_id, observed_at_utc DESC;
```

Index:

```sql
CREATE INDEX idx_observation_latest_per_station
ON ndbc.observation (station_id ASC, observed_at_utc DESC)
INCLUDE (
    wind_speed_meter_per_second,
    wave_height_meter,
    sea_surface_temperature_celsius
);
```

### Hasil pengujian

| Query | Sebelum | Setelah | Percepatan | Validasi output |
|---|---:|---:|---:|---|
| Filter observasi per tanggal | 139,465 ms | 3,300 ms | sekitar 42,3× | 12.567 = 12.567, `output_same = t` |
| Angin kencang ≥ 15 m/s | 85,551 ms | 0,263 ms | sekitar 325,3× | 790 = 790, `output_same = t` |
| Observasi terbaru per stasiun | 1.468,070 ms | 139,651 ms | sekitar 10,5× | 90 = 90, `output_same = t` |

Perubahan execution plan:

| Query | Sebelum | Setelah |
|---|---|---|
| Query 1 | `Parallel Seq Scan` dan `Sort` | `Index Only Scan` |
| Query 2 | `Seq Scan` dan `Sort` | `Index Only Scan` |
| Query 3 | `WindowAgg`, external merge sort, temp disk | `Unique` dan `Index Only Scan` |

Angka waktu dapat berubah pada perangkat berbeda, tetapi output query harus tetap sama dan execution plan setelah optimasi harus menunjukkan pemanfaatan index yang sesuai.

## Bonus Automated Scheduling

Automated scheduling menjalankan keseluruhan pipeline:

```text
Scraping batch baru
-> validasi JSON
-> loading PostgreSQL
-> pencegahan duplikasi
-> verifikasi jumlah data
-> pencatatan history batch
```

Implementasi menggunakan PowerShell dan Windows Task Scheduler.

### Pencegahan redundansi

Redundansi dicegah pada dua lapisan:

1. Primary key database:

```sql
PRIMARY KEY (station_id, observed_at_utc)
```

2. Conditional upsert loader:

```sql
ON CONFLICT (station_id, observed_at_utc) DO UPDATE
...
WHERE ROW(existing_values) IS DISTINCT FROM ROW(source_values)
```

Observasi pada file real-time dapat tumpang tindih dengan batch sebelumnya. Key yang sudah ada tidak dibuat menjadi tuple baru. Jika delapan nilai meteorologinya sama, tuple tidak disentuh. Jika NDBC mengoreksi nilai meteorologi historis, tuple yang sama diperbarui dan `first_seen_run_id` tetap dipertahankan. Metadata sumber diperbarui hanya bersama koreksi meteorologi, bukan karena nomor baris file bergeser.

### Konfigurasi lokal

```powershell
cd "Automated Scheduling"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\configure_pipeline.ps1
```

Script membuat:

```text
config/pipeline.settings.local.json
config/postgres.password.dpapi
```

Password PostgreSQL disimpan menggunakan Windows DPAPI dan kedua file tersebut diabaikan oleh Git.

Contoh konfigurasi proyek:

```text
PostgreSQL bin        : C:\Program Files\PostgreSQL\13\bin
PostgreSQL data       : D:\PostgreSQL\ndbc-data
Host                  : localhost
Port                  : 5433
Database              : ndbc
Target stasiun        : 90
Request delay         : 1 detik
Jadwal                : setiap hari pukul 02:00
Batch runtime disimpan: 2 batch terbaru
```

### Menjalankan pipeline manual

```powershell
.\scripts\run_pipeline.ps1
```

### Mendaftarkan scheduled task

```powershell
.\scripts\register_scheduled_task.ps1
```

Task yang dibuat:

```text
Nama   : NDBC Automated ETL
Jadwal : setiap hari pukul 02:00 waktu lokal
```

Pemeriksaan task:

```powershell
Get-ScheduledTask -TaskName "NDBC Automated ETL" |
    Select-Object TaskName, State

Get-ScheduledTaskInfo -TaskName "NDBC Automated ETL" |
    Select-Object LastRunTime, LastTaskResult, NextRunTime
```

Menjalankan melalui Task Scheduler untuk pengujian:

```powershell
Start-ScheduledTask -TaskName "NDBC Automated ETL"
```

Hasil pengujian task:

```text
State          : Ready
LastTaskResult : 0
NextRunTime    : 24 Juli 2026 pukul 02:00 waktu lokal
```

`LastTaskResult = 0` menunjukkan task selesai tanpa error. Status `Ready` menunjukkan task tidak sedang berjalan dan menunggu jadwal berikutnya.

### Verifikasi dua batch

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

Bukti dua batch:

| Batch | Scrape run ID | Mulai scraping | Selesai scraping | Ekstraksi pertama | Ekstraksi terakhir | Observasi sumber | Observasi baru | Overlap |
|---|---|---|---|---|---|---:|---:|---:|
| 1 | `ndbc-20260723-061419-0c3bbdce81` | 23-07-2026 13:14:19 WIB | 23-07-2026 13:24:10 WIB | 23-07-2026 13:14:57 WIB | 23-07-2026 13:23:53 WIB | 571.167 | 571.167 | 0 |
| 2 | `ndbc-20260723-101648-3184b99631` | 23-07-2026 17:16:48 WIB | 23-07-2026 17:26:53 WIB | 23-07-2026 17:17:27 WIB | 23-07-2026 17:26:26 WIB | 573.334 | 2.179 | 571.155 |

Eksekusi berikutnya melalui Windows Task Scheduler menghasilkan 129 key observasi baru dan menaikkan total database menjadi 573.475 tanpa duplikasi.

Bukti tidak ada redundansi setelah eksekusi Task Scheduler:

```text
total_row_count     = 573475
unique_row_count    = 573475
duplicate_row_count = 0
```

Riwayat batch juga disimpan pada:

```text
Automated Scheduling/history/pipeline_runs.csv
Automated Scheduling/history/latest_two_batches.csv
```

Folder `runs` dan `logs` merupakan data runtime besar dan diabaikan oleh Git.

## Screenshot Bukti Implementasi

> Path screenshot di bawah menggunakan nama file standar proyek. Apabila nama file lokal berbeda, samakan nama file atau ubah path Markdown agar gambar tampil di GitHub.

### ERD dan diagram relasional

<p align="center">
  <img src="Data%20Storing/design/erd.png" alt="ERD NDBC" width="900" />
</p>

<p align="center">
  <img src="Data%20Storing/design/relational_diagram.png" alt="Diagram relasional NDBC" width="900" />
</p>

### Bukti tabel PostgreSQL

![Daftar tabel PostgreSQL](Data%20Storing/screenshots/01_tables.png)

### Bukti jumlah data

![Jumlah data pada tabel](Data%20Storing/screenshots/02_table_counts.png)

### Bukti query SELECT FROM WHERE

![Query SELECT FROM WHERE](Data%20Storing/screenshots/03_select_from_where.png)

### Bukti constraint

![Constraint PostgreSQL](Data%20Storing/screenshots/04_constraints.png)

### Bukti trigger

![Trigger PostgreSQL](Data%20Storing/screenshots/05_triggers.png)

### Bukti query optimization 1

![Query optimization 1](Query%20Optimasi/screenshots/01_query_1_optimization.png)

### Bukti query optimization 2

![Query optimization 2](Query%20Optimasi/screenshots/02_query_2_optimization.png)

### Bukti query optimization 3

![Query optimization 3](Query%20Optimasi/screenshots/03_query_3_optimization.png)

### Bukti index hasil optimasi

![Index hasil optimasi](Query%20Optimasi/screenshots/04_optimization_indexes.png)

### Bukti scheduled task

![Scheduled task NDBC ETL](Automated%20Scheduling/screenshots/01_scheduled_task_ready.png)

### Bukti perbedaan timestamp dua batch

![Dua batch dengan timestamp berbeda](Automated%20Scheduling/screenshots/02_two_batch_timestamps.png)

### Bukti tidak ada duplikasi

![Tidak ada observasi duplikat](Automated%20Scheduling/screenshots/03_no_duplicate_observations.png)

### Bukti riwayat pipeline

![Riwayat pipeline](Automated%20Scheduling/screenshots/04_pipeline_history.png)

### Bukti hasil Task Scheduler

![Hasil Task Scheduler](Automated%20Scheduling/screenshots/05_scheduled_task_result.png)

## Penggunaan AI

AI digunakan sebagai alat bantu selama pengerjaan proyek. Penggunaannya tidak menggantikan proses eksekusi, pemeriksaan data, pengujian database, dan pengambilan keputusan akhir oleh author.

### Bagian yang dibantu AI

AI membantu pada bagian berikut:

1. Memberikan masukan terhadap struktur project C# agar source scraper dan loader lebih terorganisasi.
2. Membantu meninjau parser metadata dan observasi NDBC.
3. Membantu meninjau strategi preprocessing missing value, validasi, dan deduplication.
4. Membantu meninjau rancangan ERD, kardinalitas, weak entity, partial key, dan descriptive attribute.
5. Membantu meninjau translasi ERD menjadi diagram relasional.
6. Membantu meninjau constraint PostgreSQL, termasuk primary key, foreign key, check constraint, dan trigger.
7. Membantu debugging loader PostgreSQL, binary `COPY`, transaction, dan proses export/restore.
8. Membantu menyusun dan meninjau tiga skenario query optimization.
9. Membantu menyusun dan meninjau script automated scheduling serta verifikasi anti-redundansi.
10. Membantu menyusun dokumentasi README agar seluruh langkah penggunaan dan hasil pengujian tercatat secara terstruktur.

### Bagian yang dikerjakan dan diverifikasi sendiri

Author melakukan sendiri bagian berikut:

1. Memilih topik data meteorologi buoy NDBC.
2. Menjalankan dan memantau proses scraping pada lingkungan lokal.
3. Memeriksa hasil JSON, jumlah stasiun, jumlah observasi, dan error log.
4. Menjalankan build dan runtime project C#.
5. Menyiapkan dan menjalankan PostgreSQL pada perangkat lokal.
6. Menjalankan loader dan memastikan data masuk ke database.
7. Memeriksa tabel, constraint, trigger, serta query `SELECT FROM WHERE`.
8. Menjalankan export dan menguji restore database ke database terpisah.
9. Menjalankan `EXPLAIN ANALYZE` sebelum dan setelah optimasi.
10. Memastikan output query sebelum dan sesudah optimasi sama.
11. Menjalankan pipeline kedua dan memeriksa bahwa jumlah duplikasi tetap nol.
12. Mendaftarkan serta menguji Windows Scheduled Task.
13. Mengambil dan menyimpan screenshot bukti implementasi.
14. Meninjau kembali hasil akhir sebelum di-commit dan dikumpulkan.

### Cara validasi hasil AI

Setiap saran atau kode hasil bantuan AI diperiksa melalui:

- `dotnet build` untuk memastikan project dapat dikompilasi.
- Eksekusi scraper terhadap website sumber.
- Validasi struktur dan jumlah data JSON.
- Eksekusi loader pada PostgreSQL.
- Query pemeriksaan jumlah baris dan referential integrity.
- Pemeriksaan daftar constraint dan trigger.
- Restore export ke database baru.
- `EXPLAIN ANALYZE` untuk mengukur performa query.
- Perbandingan output dengan `EXCEPT ALL`.
- Pengujian dua batch untuk membuktikan idempotensi.
- Pemeriksaan `LastTaskResult = 0` pada Windows Task Scheduler.

### Refleksi penggunaan AI

AI membantu mempercepat proses review, dokumentasi, dan identifikasi kemungkinan masalah teknis. Namun, hasil AI tidak selalu langsung sesuai dengan environment lokal. Beberapa bagian tetap memerlukan penyesuaian path Windows, port PostgreSQL, kapasitas penyimpanan, mekanisme restore `pg_dump`, dan eksekusi langsung untuk memastikan solusi benar-benar bekerja.

Penggunaan AI paling bermanfaat ketika diperlakukan sebagai alat diskusi dan code review, bukan sebagai sumber kebenaran tunggal. Pengujian langsung tetap diperlukan karena keberhasilan build belum menjamin scraping, loading, export, query optimization, dan scheduling berjalan sesuai kebutuhan.

## Catatan Keamanan dan Git

File berikut tidak boleh di-commit:

```text
**/bin/
**/obj/
Data Scraping/data/observations.json
Automated Scheduling/config/pipeline.settings.local.json
Automated Scheduling/config/postgres.password.dpapi
Automated Scheduling/runs/
Automated Scheduling/logs/
```

Hal lain yang perlu diperhatikan:

- Jangan menulis password PostgreSQL di source code atau README.
- Gunakan environment variable `NDBC_DB_CONNECTION` untuk loader manual.
- Gunakan DPAPI pada automated scheduling.
- Jangan mengunggah binary hasil build.
- Pastikan setiap file export `.sql` berada di bawah batas ukuran GitHub.
- Periksa repository dengan `git status` sebelum commit.

Contoh:

```powershell
git status
git ls-files | Select-String "bin/|obj/|password|observations.json"
```

## Troubleshooting

### PostgreSQL port 5433 tidak aktif

```powershell
$pgBin = "C:\Program Files\PostgreSQL\13\bin"
$pgData = "D:\PostgreSQL\ndbc-data"
$pgLog = "D:\PostgreSQL\ndbc-server.log"

& "$pgBin\pg_ctl.exe" -D $pgData -l $pgLog -o "-p 5433" start
& "$pgBin\pg_isready.exe" -h localhost -p 5433
```

Target:

```text
localhost:5433 - accepting connections
```

### Loader tidak menemukan connection string

```powershell
$env:NDBC_DB_CONNECTION = "Host=localhost;Port=5433;Database=ndbc;Username=postgres;Password=PASSWORD_POSTGRES"
```

Environment variable harus disetel ulang pada terminal PowerShell baru.

### PowerShell menolak menjalankan script

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
Unblock-File ".\nama_script.ps1"
```

Perubahan execution policy hanya berlaku untuk sesi PowerShell tersebut.

### Ruang penyimpanan PostgreSQL tidak cukup

Gejala:

```text
No space left on device
```

Solusi:

- Hapus file runtime yang tidak diperlukan.
- Hapus database pengujian setelah selesai.
- Gunakan PostgreSQL data directory pada drive yang mempunyai ruang cukup.
- Jangan menyimpan beberapa salinan `observations.json` besar.

### Scraper tidak mencapai target

Jumlah stasiun dengan data real-time dapat berubah. Kandidat dapat dilewati karena:

- Bukan buoy.
- File meteorologi real-time tidak tersedia.
- Metadata tidak memenuhi validasi.
- Website sedang tidak dapat diakses.

Periksa:

```text
skipped_stations.json
errors.json
scraping_report.json
```

### Query optimization dijalankan ulang

File `query_optimization.sql` menghapus index bonus terlebih dahulu agar baseline dapat direproduksi. Jangan menjalankan query lain yang bergantung pada index bonus pada saat script pengujian sedang berjalan.

### Scheduled Task berstatus `Ready`

`Ready` bukan error. Status ini berarti task sudah selesai atau belum waktunya berjalan dan sedang menunggu jadwal berikutnya. Keberhasilan run terakhir diperiksa melalui:

```powershell
Get-ScheduledTaskInfo -TaskName "NDBC Automated ETL" |
    Select-Object LastRunTime, LastTaskResult, NextRunTime
```

`LastTaskResult = 0` berarti eksekusi terakhir berhasil.

## Referensi

### Sumber data

1. National Data Buoy Center station list  
   https://www.ndbc.noaa.gov/to_station.shtml
2. National Data Buoy Center station page  
   https://www.ndbc.noaa.gov/station_page.php
3. National Data Buoy Center real-time data directory  
   https://www.ndbc.noaa.gov/data/realtime2/
4. National Data Buoy Center measurement descriptions  
   https://www.ndbc.noaa.gov/measdes.shtml
5. National Data Buoy Center robots.txt  
   https://www.ndbc.noaa.gov/robots.txt

### Library dan platform

1. .NET Documentation  
   https://learn.microsoft.com/dotnet/
2. Html Agility Pack  
   https://html-agility-pack.net/
3. HtmlAgilityPack NuGet package  
   https://www.nuget.org/packages/HtmlAgilityPack/
4. Npgsql documentation  
   https://www.npgsql.org/doc/
5. Npgsql NuGet package  
   https://www.nuget.org/packages/Npgsql/
6. PostgreSQL 13 Documentation  
   https://www.postgresql.org/docs/13/
7. PostgreSQL `COPY`  
   https://www.postgresql.org/docs/13/sql-copy.html
8. PostgreSQL `INSERT ... ON CONFLICT`  
   https://www.postgresql.org/docs/13/sql-insert.html
9. PostgreSQL `EXPLAIN`  
   https://www.postgresql.org/docs/13/sql-explain.html
10. PowerShell Documentation  
    https://learn.microsoft.com/powershell/
11. Windows Task Scheduler Documentation  
    https://learn.microsoft.com/windows/win32/taskschd/task-scheduler-start-page

### Materi perancangan basis data

- Materi IF2240 mengenai E-R Model.
- Materi IF2240 mengenai translasi E-R Diagram ke Relational Model.
- Materi IF2240 mengenai functional dependency dan normalisasi.
- Materi IF2240 mengenai relational database design dan optimasi.

---

Proyek ini dibuat oleh **Aziza Dharma Putri (13524017)** untuk Seleksi Tahap 2 Asisten Laboratorium Basis Data 2026.
