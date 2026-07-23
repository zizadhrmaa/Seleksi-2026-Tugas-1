\pset pager off
\timing off
SET search_path TO ndbc, public;

\echo ''
\echo '================ DUA BATCH TERBARU ================='
-- Menampilkan dua batch terbaru beserta waktu scraping dan waktu ekstraksi.
-- Perbedaan timestamp membuktikan bahwa pipeline dijalankan pada waktu berbeda.
WITH latest_runs AS (
    SELECT
        sr.scrape_run_id,
        sr.started_at,
        sr.finished_at,
        sr.total_observation_count,
        sr.loaded_at,
        ROW_NUMBER() OVER (
            ORDER BY sr.started_at DESC
        ) AS batch_order
    FROM ndbc.scrape_run AS sr
    ORDER BY sr.started_at DESC
    LIMIT 2
), extraction_summary AS (
    SELECT
        se.scrape_run_id,
        COUNT(*) AS extracted_station_count,
        MIN(se.extracted_at) AS first_extracted_at,
        MAX(se.extracted_at) AS last_extracted_at
    FROM ndbc.station_extraction AS se
    WHERE se.scrape_run_id IN (
        SELECT scrape_run_id
        FROM latest_runs
    )
    GROUP BY se.scrape_run_id
), inserted_summary AS (
    SELECT
        o.first_seen_run_id AS scrape_run_id,
        COUNT(*) AS inserted_observation_count
    FROM ndbc.observation AS o
    WHERE o.first_seen_run_id IN (
        SELECT scrape_run_id
        FROM latest_runs
    )
    GROUP BY o.first_seen_run_id
)
SELECT
    lr.batch_order,
    lr.scrape_run_id,
    lr.started_at AS scrape_started_at,
    lr.finished_at AS scrape_finished_at,
    es.first_extracted_at,
    es.last_extracted_at,
    es.extracted_station_count,
    lr.total_observation_count AS source_observation_count,
    COALESCE(ins.inserted_observation_count, 0) AS inserted_observation_count,
    lr.total_observation_count
        - COALESCE(ins.inserted_observation_count, 0)
        AS overlapping_observation_count,
    lr.total_observation_count =
        COALESCE(ins.inserted_observation_count, 0)
        + (
            lr.total_observation_count
            - COALESCE(ins.inserted_observation_count, 0)
        ) AS source_count_consistent,
    lr.loaded_at
FROM latest_runs AS lr
LEFT JOIN extraction_summary AS es
    ON es.scrape_run_id = lr.scrape_run_id
LEFT JOIN inserted_summary AS ins
    ON ins.scrape_run_id = lr.scrape_run_id
ORDER BY lr.started_at;

\echo ''
\echo '================ CEK REDUNDANSI OBSERVASI ============'
-- Primary key observation adalah (station_id, observed_at_utc).
-- Nilai duplicate_row_count harus 0.
SELECT
    COUNT(*) AS total_row_count,
    COUNT(DISTINCT (station_id, observed_at_utc)) AS unique_row_count,
    COUNT(*) - COUNT(DISTINCT (station_id, observed_at_utc))
        AS duplicate_row_count
FROM ndbc.observation;

\echo ''
\echo '================ RIWAYAT JUMLAH DATA ================='
-- Menunjukkan bahwa batch baru tetap tercatat walaupun sebagian besar key
-- real-time sudah ada dari batch sebelumnya. Key overlap tidak dibuat menjadi
-- tuple baru; nilai lama dapat diperbarui apabila sumber mengoreksinya.
SELECT
    sr.scrape_run_id,
    sr.started_at,
    sr.finished_at,
    sr.successful_station_count,
    sr.total_observation_count AS source_observation_count,
    COUNT(o.observed_at_utc) AS newly_inserted_observation_count
FROM ndbc.scrape_run AS sr
LEFT JOIN ndbc.observation AS o
    ON o.first_seen_run_id = sr.scrape_run_id
GROUP BY
    sr.scrape_run_id,
    sr.started_at,
    sr.finished_at,
    sr.successful_station_count,
    sr.total_observation_count
ORDER BY sr.started_at DESC
LIMIT 10;
