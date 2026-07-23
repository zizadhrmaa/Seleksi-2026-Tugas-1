-- Bonus Query Optimization
-- Database: PostgreSQL 13
-- Schema: ndbc
--
-- File ini berisi tiga pengujian optimasi query. Setiap bagian memuat:
-- 1. Query sebelum optimasi beserta EXPLAIN ANALYZE.
-- 2. Pembuatan index atau perbaikan bentuk query.
-- 3. Query setelah optimasi beserta EXPLAIN ANALYZE.
-- 4. Pemeriksaan bahwa output sebelum dan sesudah optimasi tetap sama.
--
-- Jalankan file ini menggunakan psql agar perintah \echo dan \timing dapat diproses.

\set ON_ERROR_STOP on
\pset pager off
\timing on

SET search_path TO ndbc, public;
SET TIME ZONE 'Asia/Jakarta';

-- Statistik tabel diperbarui agar query planner menggunakan informasi terbaru.
ANALYZE ndbc.observation;

-- Index bonus dihapus lebih dahulu agar hasil baseline dapat direproduksi
-- ketika file ini dijalankan ulang.
DROP INDEX IF EXISTS ndbc.idx_observation_time_station_cover;
DROP INDEX IF EXISTS ndbc.idx_observation_high_wind;
DROP INDEX IF EXISTS ndbc.idx_observation_latest_per_station;


-- ============================================================================
-- QUERY OPTIMASI 1
-- Mengambil observasi pada satu tanggal kalender.
--
-- Masalah query awal:
-- observed_at_utc dikonversi menjadi date pada setiap baris. Operasi tersebut
-- membuat kondisi tidak sargable sehingga PostgreSQL tidak dapat melakukan
-- pencarian langsung berdasarkan nilai timestamp pada B-tree index.
--
-- Optimasi:
-- Kondisi diubah menjadi rentang timestamp [awal hari, awal hari berikutnya)
-- dan ditambahkan covering index berdasarkan observed_at_utc dan station_id.
-- ============================================================================

\echo ''
\echo '================ QUERY 1: SEBELUM OPTIMASI ================'

EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, SUMMARY ON, TIMING OFF)
SELECT
    station_id,
    observed_at_utc,
    wind_speed_meter_per_second,
    wave_height_meter,
    sea_surface_temperature_celsius
FROM ndbc.observation
WHERE observed_at_utc::date = DATE '2026-07-20'
ORDER BY observed_at_utc, station_id;

CREATE INDEX idx_observation_time_station_cover
ON ndbc.observation (observed_at_utc, station_id)
INCLUDE (
    wind_speed_meter_per_second,
    wave_height_meter,
    sea_surface_temperature_celsius
);

ANALYZE ndbc.observation;

\echo ''
\echo '================ QUERY 1: SETELAH OPTIMASI ================'

EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, SUMMARY ON, TIMING OFF)
SELECT
    station_id,
    observed_at_utc,
    wind_speed_meter_per_second,
    wave_height_meter,
    sea_surface_temperature_celsius
FROM ndbc.observation
WHERE observed_at_utc >= TIMESTAMPTZ '2026-07-20 00:00:00+07'
  AND observed_at_utc <  TIMESTAMPTZ '2026-07-21 00:00:00+07'
ORDER BY observed_at_utc, station_id;

\echo ''
\echo '================ QUERY 1: VALIDASI OUTPUT =================='

WITH before_result AS (
    SELECT
        station_id,
        observed_at_utc,
        wind_speed_meter_per_second,
        wave_height_meter,
        sea_surface_temperature_celsius
    FROM ndbc.observation
    WHERE observed_at_utc::date = DATE '2026-07-20'
),
after_result AS (
    SELECT
        station_id,
        observed_at_utc,
        wind_speed_meter_per_second,
        wave_height_meter,
        sea_surface_temperature_celsius
    FROM ndbc.observation
    WHERE observed_at_utc >= TIMESTAMPTZ '2026-07-20 00:00:00+07'
      AND observed_at_utc <  TIMESTAMPTZ '2026-07-21 00:00:00+07'
)
SELECT
    (SELECT COUNT(*) FROM before_result) AS before_row_count,
    (SELECT COUNT(*) FROM after_result) AS after_row_count,
    NOT EXISTS (
        SELECT 1
        FROM (
            (SELECT * FROM before_result EXCEPT ALL SELECT * FROM after_result)
            UNION ALL
            (SELECT * FROM after_result EXCEPT ALL SELECT * FROM before_result)
        ) AS difference
    ) AS output_same;


-- ============================================================================
-- QUERY OPTIMASI 2
-- Mengambil kejadian angin kencang dengan kecepatan minimal 15 m/s.
--
-- Masalah query awal:
-- COALESCE diterapkan pada kolom wind_speed_meter_per_second. Walaupun hasilnya
-- benar, fungsi pada kolom membuat pencarian tidak dapat memakai B-tree index
-- secara langsung.
--
-- Optimasi:
-- Constraint database menjamin nilai kecepatan angin tidak negatif. Karena itu,
-- COALESCE(NULL, -1) >= 15 ekuivalen dengan wind_speed >= 15. Query diubah
-- menjadi predicate langsung dan dibuat index yang mengikuti filter serta urutan
-- hasil query.
-- ============================================================================

\echo ''
\echo '================ QUERY 2: SEBELUM OPTIMASI ================'

EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, SUMMARY ON, TIMING OFF)
SELECT
    station_id,
    observed_at_utc,
    wind_speed_meter_per_second,
    wind_gust_meter_per_second
FROM ndbc.observation
WHERE COALESCE(wind_speed_meter_per_second, -1) >= 15
ORDER BY
    wind_speed_meter_per_second DESC,
    observed_at_utc DESC,
    station_id;

CREATE INDEX idx_observation_high_wind
ON ndbc.observation (
    wind_speed_meter_per_second DESC,
    observed_at_utc DESC,
    station_id
)
INCLUDE (wind_gust_meter_per_second)
WHERE wind_speed_meter_per_second IS NOT NULL;

ANALYZE ndbc.observation;

\echo ''
\echo '================ QUERY 2: SETELAH OPTIMASI ================'

EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, SUMMARY ON, TIMING OFF)
SELECT
    station_id,
    observed_at_utc,
    wind_speed_meter_per_second,
    wind_gust_meter_per_second
FROM ndbc.observation
WHERE wind_speed_meter_per_second >= 15
ORDER BY
    wind_speed_meter_per_second DESC,
    observed_at_utc DESC,
    station_id;

\echo ''
\echo '================ QUERY 2: VALIDASI OUTPUT ================='

WITH before_result AS (
    SELECT
        station_id,
        observed_at_utc,
        wind_speed_meter_per_second,
        wind_gust_meter_per_second
    FROM ndbc.observation
    WHERE COALESCE(wind_speed_meter_per_second, -1) >= 15
),
after_result AS (
    SELECT
        station_id,
        observed_at_utc,
        wind_speed_meter_per_second,
        wind_gust_meter_per_second
    FROM ndbc.observation
    WHERE wind_speed_meter_per_second >= 15
)
SELECT
    (SELECT COUNT(*) FROM before_result) AS before_row_count,
    (SELECT COUNT(*) FROM after_result) AS after_row_count,
    NOT EXISTS (
        SELECT 1
        FROM (
            (SELECT * FROM before_result EXCEPT ALL SELECT * FROM after_result)
            UNION ALL
            (SELECT * FROM after_result EXCEPT ALL SELECT * FROM before_result)
        ) AS difference
    ) AS output_same;


-- ============================================================================
-- QUERY OPTIMASI 3
-- Mengambil satu observasi terbaru dari setiap stasiun.
--
-- Masalah query awal:
-- ROW_NUMBER menghitung peringkat untuk seluruh baris dalam setiap kelompok
-- stasiun sebelum menyisakan baris dengan rn = 1. Proses ini menambah kerja
-- WindowAgg dan pengurutan terhadap ratusan ribu observasi.
--
-- Optimasi:
-- DISTINCT ON dapat berhenti pada satu baris pertama untuk setiap station_id
-- sesuai urutan index. Index menggunakan urutan campuran station_id ASC dan
-- observed_at_utc DESC serta menyertakan kolom hasil agar pembacaan tabel utama
-- dapat dikurangi.
-- ============================================================================

\echo ''
\echo '================ QUERY 3: SEBELUM OPTIMASI ================'

EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, SUMMARY ON, TIMING OFF)
WITH ranked_observation AS (
    SELECT
        station_id,
        observed_at_utc,
        wind_speed_meter_per_second,
        wave_height_meter,
        sea_surface_temperature_celsius,
        ROW_NUMBER() OVER (
            PARTITION BY station_id
            ORDER BY observed_at_utc DESC
        ) AS row_number
    FROM ndbc.observation
)
SELECT
    station_id,
    observed_at_utc,
    wind_speed_meter_per_second,
    wave_height_meter,
    sea_surface_temperature_celsius
FROM ranked_observation
WHERE row_number = 1
ORDER BY station_id;

CREATE INDEX idx_observation_latest_per_station
ON ndbc.observation (station_id ASC, observed_at_utc DESC)
INCLUDE (
    wind_speed_meter_per_second,
    wave_height_meter,
    sea_surface_temperature_celsius
);

ANALYZE ndbc.observation;

\echo ''
\echo '================ QUERY 3: SETELAH OPTIMASI ================'

EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, SUMMARY ON, TIMING OFF)
SELECT DISTINCT ON (station_id)
    station_id,
    observed_at_utc,
    wind_speed_meter_per_second,
    wave_height_meter,
    sea_surface_temperature_celsius
FROM ndbc.observation
ORDER BY station_id, observed_at_utc DESC;

\echo ''
\echo '================ QUERY 3: VALIDASI OUTPUT ================='

WITH before_result AS (
    SELECT
        station_id,
        observed_at_utc,
        wind_speed_meter_per_second,
        wave_height_meter,
        sea_surface_temperature_celsius
    FROM (
        SELECT
            station_id,
            observed_at_utc,
            wind_speed_meter_per_second,
            wave_height_meter,
            sea_surface_temperature_celsius,
            ROW_NUMBER() OVER (
                PARTITION BY station_id
                ORDER BY observed_at_utc DESC
            ) AS row_number
        FROM ndbc.observation
    ) AS ranked_observation
    WHERE row_number = 1
),
after_result AS (
    SELECT DISTINCT ON (station_id)
        station_id,
        observed_at_utc,
        wind_speed_meter_per_second,
        wave_height_meter,
        sea_surface_temperature_celsius
    FROM ndbc.observation
    ORDER BY station_id, observed_at_utc DESC
)
SELECT
    (SELECT COUNT(*) FROM before_result) AS before_row_count,
    (SELECT COUNT(*) FROM after_result) AS after_row_count,
    NOT EXISTS (
        SELECT 1
        FROM (
            (SELECT * FROM before_result EXCEPT ALL SELECT * FROM after_result)
            UNION ALL
            (SELECT * FROM after_result EXCEPT ALL SELECT * FROM before_result)
        ) AS difference
    ) AS output_same;


-- Ringkasan index yang ditambahkan oleh bonus query optimization.
\echo ''
\echo '================ INDEX HASIL OPTIMASI ====================='

SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'ndbc'
  AND indexname IN (
      'idx_observation_time_station_cover',
      'idx_observation_high_wind',
      'idx_observation_latest_per_station'
  )
ORDER BY indexname;
