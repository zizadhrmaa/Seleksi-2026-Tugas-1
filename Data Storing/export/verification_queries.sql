-- Seluruh query pada file ini bersifat read-only dan digunakan untuk
-- memverifikasi hasil loading, integrity, dan konsistensi antarbatch.

-- 1. Jumlah baris setiap tabel utama
SELECT 'data_provider' AS table_name, COUNT(*) AS row_count FROM ndbc.data_provider
UNION ALL
SELECT 'scrape_run', COUNT(*) FROM ndbc.scrape_run
UNION ALL
SELECT 'station', COUNT(*) FROM ndbc.station
UNION ALL
SELECT 'station_extraction', COUNT(*) FROM ndbc.station_extraction
UNION ALL
SELECT 'observation', COUNT(*) FROM ndbc.observation
ORDER BY table_name;

-- 2. Query SELECT FROM WHERE untuk screenshot wajib
SELECT
    station_id,
    observed_at_utc,
    wind_speed_meter_per_second,
    wave_height_meter,
    sea_surface_temperature_celsius
FROM ndbc.observation
WHERE station_id = '41001'
ORDER BY observed_at_utc DESC
LIMIT 20;

-- 3. Join metadata stasiun dengan observasi
SELECT
    s.station_id,
    s.station_name,
    o.observed_at_utc,
    o.wind_speed_meter_per_second,
    o.wave_height_meter,
    o.sea_surface_temperature_celsius
FROM ndbc.station AS s
INNER JOIN ndbc.observation AS o
    ON o.station_id = s.station_id
WHERE o.wave_height_meter IS NOT NULL
ORDER BY o.observed_at_utc DESC
LIMIT 20;

-- 4. Ringkasan observasi per stasiun
SELECT *
FROM ndbc.station_observation_summary
ORDER BY observation_count DESC, station_id
LIMIT 20;

-- 5. Verifikasi tidak ada duplikasi identitas observasi.
-- Query harus menghasilkan 0 baris.
SELECT
    station_id,
    observed_at_utc,
    COUNT(*) AS duplicate_count
FROM ndbc.observation
GROUP BY station_id, observed_at_utc
HAVING COUNT(*) > 1;

-- 6. Verifikasi tidak ada observasi tanpa pengukuran target.
-- Nilai empty_measurement_rows harus 0.
SELECT COUNT(*) AS empty_measurement_rows
FROM ndbc.observation
WHERE wind_direction_degree IS NULL
  AND wind_speed_meter_per_second IS NULL
  AND wind_gust_meter_per_second IS NULL
  AND wave_height_meter IS NULL
  AND dominant_wave_period_second IS NULL
  AND average_wave_period_second IS NULL
  AND mean_wave_direction_degree IS NULL
  AND sea_surface_temperature_celsius IS NULL;

-- 7. Verifikasi statistik setiap scrape run setelah automated scheduling.
-- source_observation_count = inserted_observation_count + overlapping_observation_count.
-- Observasi overlap adalah key yang sudah ada. Jika sumber mengoreksi nilainya,
-- loader dapat memperbarui tuple lama tanpa membuat tuple baru.
WITH inserted_summary AS (
    SELECT
        first_seen_run_id AS scrape_run_id,
        COUNT(*) AS inserted_observation_count
    FROM ndbc.observation
    GROUP BY first_seen_run_id
), extraction_summary AS (
    SELECT
        scrape_run_id,
        COUNT(*) AS stored_station_count
    FROM ndbc.station_extraction
    GROUP BY scrape_run_id
)
SELECT
    sr.scrape_run_id,
    sr.successful_station_count AS source_station_count,
    COALESCE(es.stored_station_count, 0) AS stored_station_count,
    sr.total_observation_count AS source_observation_count,
    COALESCE(ins.inserted_observation_count, 0) AS inserted_observation_count,
    sr.total_observation_count
        - COALESCE(ins.inserted_observation_count, 0)
        AS overlapping_observation_count,
    sr.total_observation_count =
        COALESCE(ins.inserted_observation_count, 0)
        + (
            sr.total_observation_count
            - COALESCE(ins.inserted_observation_count, 0)
        ) AS source_count_consistent
FROM ndbc.scrape_run AS sr
LEFT JOIN extraction_summary AS es
    ON es.scrape_run_id = sr.scrape_run_id
LEFT JOIN inserted_summary AS ins
    ON ins.scrape_run_id = sr.scrape_run_id
ORDER BY sr.started_at DESC
LIMIT 10;

-- 8. Verifikasi relationship FIRST_SEEN_IN terhadap EXTRACTS.
-- Composite foreign key juga menerapkan aturan ini pada database.
-- Nilai invalid_first_seen_reference harus 0.
SELECT COUNT(*) AS invalid_first_seen_reference
FROM ndbc.observation AS o
LEFT JOIN ndbc.station_extraction AS se
    ON se.scrape_run_id = o.first_seen_run_id
   AND se.station_id = o.station_id
WHERE se.scrape_run_id IS NULL;

-- 9. Verifikasi constraint composite foreign key telah terpasang.
SELECT
    con.conname AS constraint_name,
    pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint AS con
WHERE con.conrelid = 'ndbc.observation'::regclass
  AND con.conname = 'fk_observation_first_seen_extraction';
