# Perancangan Data Warehouse NDBC

## Tujuan dan ruang lingkup

Data warehouse dibangun dari schema operasional `ndbc` untuk mendukung dua kelompok analisis:

1. analisis historis observasi meteorologi per stasiun dan waktu;
2. evaluasi mutu serta produktivitas proses scraping.

Warehouse ditempatkan pada schema PostgreSQL `ndbc_dw`. Pemisahan ini bersifat logis. Schema operasional dan warehouse tetap memakai database serta resource PostgreSQL yang sama, sehingga bukan pemisahan workload secara fisik.

## Kebutuhan analitik

| Pertanyaan analitik | Fact | Dimension | Measure atau indikator |
|---|---|---|---|
| Bagaimana tren kecepatan angin setiap stasiun per hari? | `fact_observation` | `dim_station`, `dim_date` | `AVG` dan `MAX` wind speed |
| Stasiun mana yang mencatat wind gust tertinggi dalam tujuh hari terakhir? | `fact_observation` | `dim_station`, `dim_date` | `MAX(wind_gust_meter_per_second)` |
| Bagaimana kelengkapan pengukuran per stasiun dan hari? | `fact_observation` | `dim_station`, `dim_date` | `SUM(measurement_count)` dan flag pengukuran |
| Batch scraping mana yang memiliki success rate terendah? | `fact_scrape_run` | `dim_scrape_run`, `dim_date`, `dim_time` | successful, processed, failed count |
| Apakah durasi scraping meningkat ketika kandidat bertambah? | `fact_scrape_run` | `dim_scrape_run`, `dim_date` | duration dan candidate count |

Pemilihan fact, dimension, dan measure diturunkan dari kebutuhan tersebut, bukan sekadar menyalin struktur operasional.

## Jenis skema

Rancangan menggunakan **fact constellation** atau **galaxy schema** karena terdapat dua proses bisnis dengan grain berbeda yang berbagi dimension table:

- `fact_observation` untuk kejadian pengukuran meteorologi;
- `fact_scrape_run` untuk kejadian pelaksanaan scraping.

Dimension yang digunakan:

- `dim_date`, konteks kalender UTC;
- `dim_time`, konteks waktu harian UTC;
- `dim_station`, konteks stasiun dan provider yang didenormalisasi;
- `dim_scrape_run`, konteks batch ekstraksi.

`etl_batch` merupakan tabel audit proses refresh warehouse. Tabel ini tidak berelasi melalui foreign key dengan fact table dan tidak digambarkan sebagai bagian constellation.

## Grain

### `fact_observation`

> Satu baris merepresentasikan satu observasi meteorologi dari satu stasiun pada satu timestamp UTC.

Candidate key bisnis atau natural grain:

```text
(station_key, observed_at_utc)
```

Primary key fisik menggunakan surrogate key `observation_fact_key`. Unique constraint pada natural grain mencegah penggandaan kejadian.

### `fact_scrape_run`

> Satu baris merepresentasikan satu batch scraping NDBC.

Candidate key bisnis pada fact adalah `scrape_run_key`, sedangkan primary key fisik menggunakan `scrape_run_fact_key`.

## Measure dan sifat agregasi

### Measure `fact_observation`

- `wind_direction_degree` dan `mean_wave_direction_degree` bersifat non-additive dan sirkular.
- Kecepatan angin, wind gust, tinggi gelombang, periode gelombang, dan suhu tidak dijumlahkan untuk memperoleh nilai fisik gabungan. Measure tersebut dianalisis dengan `AVG`, `MIN`, `MAX`, distribusi, atau fungsi statistik lain yang tepat.
- `measurement_count` adalah **derived additive count** pada grain observasi. Nilai ini menghitung jumlah dari delapan kolom pengukuran yang tidak null. Penjumlahannya antar-observasi bermakna sebagai jumlah measurement cells yang tersedia, bukan jumlah observasi.
- Flag `has_wind_measurement`, `has_wave_measurement`, dan `has_temperature_measurement` merupakan indikator turunan untuk analisis kelengkapan.

### Measure `fact_scrape_run`

Measure berupa durasi dan berbagai count proses: target, kandidat, kandidat diproses, stasiun berhasil, kandidat bukan buoy, tanpa data, percobaan gagal, observasi sumber, dan duplikasi preprocessing. Count dapat dijumlahkan lintas batch selama interpretasinya tetap pada total aktivitas proses.

## Pemetaan sumber ke warehouse

| Schema operasional | Data warehouse | Transformasi |
|---|---|---|
| `ndbc.station` + `ndbc.data_provider` | `ndbc_dw.dim_station` | Join, lookup natural key, dan denormalisasi provider |
| `ndbc.scrape_run` | `ndbc_dw.dim_scrape_run` | Surrogate key dan atribut konteks batch |
| Timestamp pada observation dan scrape run | `dim_date` | UTC date key `YYYYMMDD` dan atribut kalender |
| Timestamp pada observation dan scrape run | `dim_time` | UTC time key `HHMMSS`, dibulatkan ke detik |
| `ndbc.observation` | `fact_observation` | Lookup surrogate key, derived key, count, flags, dan lineage |
| `ndbc.scrape_run` | `fact_scrape_run` | Lookup key, date/time role-playing dimension, dan derived duration |

## Functional dependency dan candidate key

Functional dependency utama yang relevan:

```text
dim_date:
  date_key -> seluruh atribut dim_date
  full_date -> seluruh atribut dim_date

dim_time:
  time_key -> seluruh atribut dim_time
  full_time -> seluruh atribut dim_time

dim_station:
  station_key -> seluruh atribut dim_station
  station_id -> seluruh atribut dim_station

dim_scrape_run:
  scrape_run_key -> seluruh atribut dim_scrape_run
  scrape_run_id -> seluruh atribut dim_scrape_run

fact_observation:
  observation_fact_key -> seluruh atribut fact_observation
  (station_key, observed_at_utc) -> seluruh atribut fact_observation

fact_scrape_run:
  scrape_run_fact_key -> seluruh atribut fact_scrape_run
  scrape_run_key -> seluruh atribut fact_scrape_run
```

Primary key dan unique constraint pada DDL merepresentasikan candidate key tersebut. Tidak ada atribut multivalued atau composite yang disimpan langsung. Timestamp operasional telah diuraikan menjadi foreign key tanggal dan waktu, sementara timestamp asli dipertahankan pada fact untuk lineage dan grain.

## Normalisasi dan denormalisasi dimensional

Pada model operasional, provider merupakan entity terpisah. Pada warehouse, atribut provider disimpan di `dim_station`. Secara teori relasional, denormalisasi ini menghasilkan dependency transitif dari `station_id` ke atribut provider melalui provider asal. Keputusan tersebut disengaja untuk mencapai bentuk star yang mudah dianalisis dan mengurangi snowflake join.

Denormalisasi tidak diterapkan pada fact. Setiap fact menyimpan foreign key dimension dan measure sesuai grain. Atribut deskriptif stasiun tidak diduplikasi pada setiap observasi.

## Translasi model ke relational schema

- Setiap dimension menjadi relation dengan surrogate primary key dan alternate natural key.
- Hubungan dimension ke fact dengan cardinality `1:N` diterjemahkan menjadi foreign key pada sisi fact sebagai sisi `N`.
- `dim_date` dan `dim_time` berperan sebagai role-playing dimensions pada `fact_scrape_run`: started date/time dan finished date/time.
- Tidak ada hubungan `M:N` yang memerlukan relation penghubung tambahan.
- Tidak ada weak entity, specialization, generalization, aggregation, atau multivalued attribute karena tidak diperlukan oleh domain.
- `etl_batch` berdiri sendiri sebagai audit relation dan tidak dipaksakan menjadi dimension.

## Incremental loading dan pencegahan redundansi

`ndbc_dw.refresh_warehouse()` menggunakan upsert berbasis key:

- `dim_station`: `station_id`;
- `dim_scrape_run`: `scrape_run_id`;
- `fact_scrape_run`: `scrape_run_key`;
- `fact_observation`: `(station_key, observed_at_utc)`.

`DO UPDATE ... WHERE row IS DISTINCT FROM row` mencegah rewrite apabila seluruh nilai sumber tidak berubah. `dw_loaded_at` hanya berubah ketika atribut fact memang berubah.

Tabel audit `etl_batch` mencatat jumlah sumber, jumlah grain baru, dan total setelah refresh. Pengujian idempotensi menjalankan refresh dua kali dalam transaksi `REPEATABLE READ`; refresh kedua wajib menambah nol baris.

## Strategi verifikasi

Verifikasi memakai tiga tingkat pembuktian:

1. **count equality**, untuk membandingkan jumlah source dan warehouse;
2. **set difference dua arah**, untuk memastikan setiap natural key sumber ada pada warehouse dan tidak ada grain tambahan;
3. **attribute transformation comparison**, untuk memastikan measure, date/time key, flag, dan lineage sama dengan aturan transformasi.

Semua hasil dimasukkan ke tabel sementara. Bila satu nilai tidak sama dengan target, script mengeluarkan `RAISE EXCEPTION`, sehingga pipeline berhenti dan tidak dapat memberikan pesan sukses palsu.

## Slowly Changing Dimension

`dim_station` dan `dim_scrape_run` menggunakan pendekatan Type 1. Perubahan atribut memperbarui baris dimension yang sama. Konsekuensinya, analisis observasi historis menggunakan metadata stasiun terbaru, bukan metadata yang berlaku ketika observasi terjadi.

Type 1 dipilih karena lingkup tugas berfokus pada observasi cuaca dan tidak menyediakan histori perubahan metadata stasiun. Apabila perpindahan lokasi buoy harus dianalisis secara historis, desain perlu dikembangkan menjadi SCD Type 2 dengan effective date, expiry date, dan current flag.

## Asumsi dan batasan

1. Seluruh key tanggal dan waktu dibentuk dalam UTC.
2. Schema operasional `ndbc` telah melalui validasi dan deduplikasi.
3. Setiap station mempunyai provider valid.
4. Setiap observation mempunyai `first_seen_run_id` yang terdapat pada `scrape_run`.
5. `measurement_count` berada pada rentang 1 sampai 8 karena baris tanpa satu pun measure tidak disimpan oleh tahap operasional.
6. Hasil runtime, export, dan screenshot harus dibuat pada komputer yang memiliki database sumber.
