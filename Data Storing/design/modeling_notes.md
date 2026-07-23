# Catatan Perancangan Model Data NDBC

Dokumen ini menjelaskan asumsi, translasi, constraint, normalisasi, dan perbedaan antara model konseptual, model relasional logis, serta implementasi fisik PostgreSQL.

## 1. Ruang lingkup model

Model menyimpan empat objek utama dari proses ETL NDBC:

1. Penyedia data.
2. Stasiun buoy.
3. Pelaksanaan scraping.
4. Observasi meteorologi per stasiun dan timestamp.

Tabel `station_extraction` dibentuk dari relationship M:N antara `scrape_run` dan `station`.

## 2. Model konseptual ERD

ERD pada `erd.png` menggunakan notasi yang dipilih untuk proyek ini. Entitas, relationship, weak entity, identifying relationship, atribut relationship, dan arah kardinalitas ditampilkan sesuai kebutuhan model konseptual.

### Entitas

- `DATA_PROVIDER` merupakan strong entity dengan key `provider_id`.
- `SCRAPE_RUN` merupakan strong entity dengan key `scrape_run_id`.
- `STATION` merupakan strong entity dengan key `station_id`.
- `OBSERVATION` merupakan weak entity milik `STATION`.

Partial key `OBSERVATION` adalah `observed_at_utc`. Identitas lengkap observasi diperoleh dari key owner dan partial key:

```text
(station_id, observed_at_utc)
```

### Relationship

- `OPERATES`: satu provider dapat mengoperasikan banyak stasiun, sedangkan setiap stasiun memiliki tepat satu provider.
- `EXTRACTS`: satu scrape run dapat mengekstrak banyak stasiun dan satu stasiun dapat diekstrak pada banyak scrape run. Relationship memiliki atribut `extracted_at`.
- `RECORDS`: identifying relationship antara `STATION` dan weak entity `OBSERVATION`.
- `FIRST_SEEN_IN`: setiap observasi memiliki tepat satu scrape run ketika key observasi tersebut pertama kali dimasukkan ke database.

## 3. Asumsi

1. Setiap stasiun dioperasikan oleh tepat satu provider.
2. Metadata pada `station` merepresentasikan metadata terbaru yang diketahui.
3. Riwayat stasiun yang ikut dalam suatu batch disimpan pada `station_extraction`.
4. Satu observasi diidentifikasi oleh pasangan `station_id` dan `observed_at_utc`.
5. Nilai `MM` dari sumber diubah menjadi `NULL`.
6. Setiap observasi wajib memiliki minimal satu nilai meteorologi yang tidak `NULL`.
7. `first_seen_run_id` tidak berubah setelah observasi pertama kali dimasukkan.
8. Jika NDBC mengoreksi nilai lama pada key observasi yang sama, nilai meteorologi dan metadata sumber diperbarui tanpa mengubah `first_seen_run_id`.
9. `quality_flags` tidak dimuat ke PostgreSQL karena seluruh flag pada dataset yang divalidasi kosong. Loader menolak data dengan `quality_flags` non-kosong agar informasi tidak hilang diam-diam.

## 4. Translasi ERD menjadi model relasional

### Strong entity

Setiap strong entity diterjemahkan menjadi satu relation:

```text
data_provider(provider_id, provider_name, base_url)
scrape_run(scrape_run_id, ...)
station(station_id, ...)
```

### Relationship 1:N `OPERATES`

Key `data_provider` ditempatkan pada sisi N sebagai foreign key:

```text
station.provider_id -> data_provider.provider_id
```

### Relationship M:N `EXTRACTS`

Relationship diterjemahkan menjadi relation asosiasi:

```text
station_extraction(
    scrape_run_id,
    station_id,
    extracted_at
)
```

Primary key:

```text
(scrape_run_id, station_id)
```

### Weak entity `OBSERVATION`

Key owner `station_id` digabung dengan partial key `observed_at_utc`:

```text
PRIMARY KEY (station_id, observed_at_utc)
```

### Relationship `FIRST_SEEN_IN`

Key `scrape_run` ditempatkan pada `observation`:

```text
observation.first_seen_run_id -> scrape_run.scrape_run_id
```

Selain foreign key tersebut, implementasi fisik memakai composite foreign key:

```text
observation(first_seen_run_id, station_id)
    -> station_extraction(scrape_run_id, station_id)
```

Constraint ini memastikan bahwa batch yang disebut sebagai batch pertama suatu observasi benar-benar mencatat ekstraksi stasiun terkait.

## 5. Model logis dan implementasi fisik

`relational_diagram.png` menampilkan model relasional logis hasil translasi ERD. Kolom audit fisik tidak harus muncul pada ERD konseptual karena kolom tersebut bukan bagian dari kebutuhan domain utama.

Implementasi PostgreSQL menambahkan kolom berikut:

- `station.created_at`
- `station.updated_at`
- `scrape_run.loaded_at`
- `observation.loaded_at`

Kolom audit tidak ditambahkan ke ERD konseptual. Kolom tersebut didokumentasikan pada dokumen ini, README, dan DDL fisik `schema.sql`.

Dengan pemisahan ini:

- ERD menjelaskan makna dan hubungan data.
- Diagram relasional menjelaskan relation, key, dan foreign key logis.
- `schema.sql` menjadi sumber kebenaran implementasi fisik PostgreSQL.

## 6. Functional dependency dan normalisasi

Functional dependency utama:

```text
provider_id -> provider_name, base_url
provider_name -> provider_id, base_url
base_url -> provider_id, provider_name

scrape_run_id -> seluruh atribut non-key scrape_run

station_id -> seluruh atribut non-key station
detail_url -> station_id dan atribut station lainnya
realtime_data_url -> station_id dan atribut station lainnya

(scrape_run_id, station_id) -> extracted_at

(station_id, observed_at_utc) -> seluruh atribut non-key observation
```

Relation utama dirancang untuk menghindari repeating group, partial dependency pada composite key, dan pemisahan objek yang tidak semestinya. Namun proyek ini tidak mengklaim bahwa seluruh schema berada dalam BCNF tanpa pengecualian.

Beberapa atribut audit dan ringkasan sengaja disimpan sebagai denormalisasi terkontrol:

- `scrape_run.target_met` dapat diturunkan dari jumlah stasiun berhasil dan target.
- Beberapa jumlah pada `scrape_run` saling berkaitan melalui constraint.
- `observation.extracted_at` dan `observation.loaded_at` disimpan untuk lineage dan audit operasional.

Konsistensi atribut tersebut dijaga melalui `CHECK`, foreign key, trigger, dan prosedur loading. Keputusan ini dipilih untuk keterlacakan ETL dan kemudahan audit, bukan karena seluruh atribut tersebut merupakan fakta independen.

## 7. Integrity constraints

Constraint yang diterapkan meliputi:

- Primary key dan composite primary key.
- Foreign key dan composite foreign key.
- Unique constraint pada candidate key yang digunakan.
- `NOT NULL` pada atribut wajib.
- `CHECK` untuk rentang koordinat, arah, suhu, nilai nonnegatif, urutan waktu, statistik scraping, dan keberadaan minimal satu measurement.
- Trigger untuk `station.updated_at`.
- Trigger untuk memastikan `station_extraction.extracted_at` berada dalam rentang scrape run.

Declarative constraints diprioritaskan. Trigger hanya digunakan pada aturan yang membutuhkan waktu sistem atau pembacaan row pada relation lain.

## 8. Kebijakan update dan redundansi

### Station

`station` menggunakan upsert. Update hanya dilakukan jika metadata benar-benar berubah menggunakan `IS DISTINCT FROM`. Dengan demikian, `updated_at` tidak berubah hanya karena batch baru memuat metadata yang sama.

### Observation

Primary key `(station_id, observed_at_utc)` mencegah tuple duplikat.

Kebijakan yang dipilih adalah **updatable historical data**:

- Key baru dimasukkan sebagai observasi baru.
- Key lama dengan nilai yang sama tidak diubah.
- Key lama hanya diperbarui jika salah satu dari delapan nilai meteorologi berubah.
- `first_seen_run_id` tetap menunjuk batch pertama.
- Jika nilai meteorologi benar-benar berubah, `source_row_number`, `source_url`, `extracted_at`, dan `loaded_at` diperbarui untuk merekam versi koreksi yang terakhir dimuat.
- Perubahan `source_row_number` saja tidak dianggap koreksi data karena nomor baris pada file real-time dapat bergeser ketika baris terbaru ditambahkan di bagian atas sumber.

Mekanisme ini mencegah redundansi sekaligus menerima koreksi historis dari sumber.

## 9. Keterbatasan `quality_flags`

Dataset yang divalidasi memiliki `quality_flags` kosong pada seluruh observasi. Karena itu, field tersebut sengaja tidak dibuat sebagai kolom atau relation PostgreSQL pada versi ini.

Untuk mencegah kehilangan informasi pada batch mendatang, loader memeriksa field tersebut dan menghentikan transaksi jika menemukan flag non-kosong. Pengembangan berikutnya dapat memakai relation:

```text
observation_quality_flag(
    station_id,
    observed_at_utc,
    flag_code
)
```

dengan foreign key ke `observation`.

## 10. Export baseline

Export SQL dalam `Data Storing/export/database_export` merepresentasikan baseline setelah batch awal dengan 90 stasiun dan 571.167 observasi. Automated scheduling selanjutnya dapat menambah atau memperbarui observasi pada database operasional.

Perbedaan jumlah antara export baseline dan database operasional bukan inkonsistensi. Export tersebut adalah snapshot yang telah diuji restore. Jika export diperbarui, proses restore dan verifikasi jumlah data harus dijalankan kembali.
