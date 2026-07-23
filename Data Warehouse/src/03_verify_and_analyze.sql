\set ON_ERROR_STOP on
\pset pager off
\timing on

SET search_path TO ndbc_dw, public;

DO $$
BEGIN
    IF to_regclass('ndbc.station') IS NULL
        OR to_regclass('ndbc.scrape_run') IS NULL
        OR to_regclass('ndbc.observation') IS NULL
        OR to_regclass('ndbc.data_provider') IS NULL THEN
        RAISE EXCEPTION
            'Verifikasi gagal: schema sumber ndbc belum lengkap.';
    END IF;

    IF to_regclass('ndbc_dw.fact_observation') IS NULL
        OR to_regclass('ndbc_dw.fact_scrape_run') IS NULL THEN
        RAISE EXCEPTION
            'Verifikasi gagal: schema ndbc_dw belum dibuat atau belum lengkap.';
    END IF;
END
$$;

DROP TABLE IF EXISTS pg_temp.warehouse_verification;
CREATE TEMP TABLE warehouse_verification (
    metric_name text PRIMARY KEY,
    actual_value bigint NOT NULL,
    expected_value bigint NOT NULL
) ON COMMIT PRESERVE ROWS;

-- Pemeriksaan bahwa sumber berisi data yang memang dapat dianalisis.
INSERT INTO warehouse_verification VALUES
(
    'source_station_is_not_empty',
    (SELECT CASE WHEN COUNT(*) > 0 THEN 0 ELSE 1 END FROM ndbc.station),
    0
),
(
    'source_scrape_run_is_not_empty',
    (SELECT CASE WHEN COUNT(*) > 0 THEN 0 ELSE 1 END FROM ndbc.scrape_run),
    0
),
(
    'source_observation_is_not_empty',
    (SELECT CASE WHEN COUNT(*) > 0 THEN 0 ELSE 1 END FROM ndbc.observation),
    0
),
(
    'successful_etl_batch_exists',
    (
        SELECT CASE
            WHEN EXISTS (
                SELECT 1
                FROM ndbc_dw.etl_batch
                WHERE status = 'SUCCESS'
                  AND finished_at IS NOT NULL
            ) THEN 0 ELSE 1
        END
    ),
    0
);

-- Pemeriksaan jumlah pada level tabel.
INSERT INTO warehouse_verification VALUES
(
    'dim_station_rows_equal_source',
    (SELECT COUNT(*) FROM ndbc_dw.dim_station),
    (SELECT COUNT(*) FROM ndbc.station)
),
(
    'dim_scrape_run_rows_equal_source',
    (SELECT COUNT(*) FROM ndbc_dw.dim_scrape_run),
    (SELECT COUNT(*) FROM ndbc.scrape_run)
),
(
    'fact_scrape_run_rows_equal_source',
    (SELECT COUNT(*) FROM ndbc_dw.fact_scrape_run),
    (SELECT COUNT(*) FROM ndbc.scrape_run)
),
(
    'fact_observation_rows_equal_source',
    (SELECT COUNT(*) FROM ndbc_dw.fact_observation),
    (SELECT COUNT(*) FROM ndbc.observation)
);

-- Pemeriksaan key set dan atribut dimension.
INSERT INTO warehouse_verification VALUES
(
    'source_station_rows_missing_in_dimension',
    (
        SELECT COUNT(*)
        FROM ndbc.station AS s
        LEFT JOIN ndbc_dw.dim_station AS ds
            ON ds.station_id = s.station_id
        WHERE ds.station_key IS NULL
    ),
    0
),
(
    'unexpected_station_dimension_rows',
    (
        SELECT COUNT(*)
        FROM ndbc_dw.dim_station AS ds
        LEFT JOIN ndbc.station AS s
            ON s.station_id = ds.station_id
        WHERE s.station_id IS NULL
    ),
    0
),
(
    'station_dimension_mismatch_rows',
    (
        SELECT COUNT(*)
        FROM ndbc.station AS s
        JOIN ndbc.data_provider AS p
            ON p.provider_id = s.provider_id
        JOIN ndbc_dw.dim_station AS ds
            ON ds.station_id = s.station_id
        WHERE ds.station_name IS DISTINCT FROM s.station_name
           OR ds.location IS DISTINCT FROM s.location
           OR ds.device_type IS DISTINCT FROM s.device_type
           OR ds.payload IS DISTINCT FROM s.payload
           OR ds.latitude IS DISTINCT FROM s.latitude
           OR ds.longitude IS DISTINCT FROM s.longitude
           OR ds.water_depth_meter IS DISTINCT FROM s.water_depth_meter
           OR ds.station_status IS DISTINCT FROM s.status
           OR ds.provider_name IS DISTINCT FROM p.provider_name
           OR ds.provider_base_url IS DISTINCT FROM p.base_url
           OR ds.detail_url IS DISTINCT FROM s.detail_url
           OR ds.realtime_data_url IS DISTINCT FROM s.realtime_data_url
           OR ds.source_created_at IS DISTINCT FROM s.created_at
           OR ds.source_updated_at IS DISTINCT FROM s.updated_at
    ),
    0
),
(
    'source_scrape_run_rows_missing_in_dimension',
    (
        SELECT COUNT(*)
        FROM ndbc.scrape_run AS r
        LEFT JOIN ndbc_dw.dim_scrape_run AS dr
            ON dr.scrape_run_id = r.scrape_run_id
        WHERE dr.scrape_run_key IS NULL
    ),
    0
),
(
    'unexpected_scrape_run_dimension_rows',
    (
        SELECT COUNT(*)
        FROM ndbc_dw.dim_scrape_run AS dr
        LEFT JOIN ndbc.scrape_run AS r
            ON r.scrape_run_id = dr.scrape_run_id
        WHERE r.scrape_run_id IS NULL
    ),
    0
),
(
    'scrape_run_dimension_mismatch_rows',
    (
        SELECT COUNT(*)
        FROM ndbc.scrape_run AS r
        JOIN ndbc_dw.dim_scrape_run AS dr
            ON dr.scrape_run_id = r.scrape_run_id
        WHERE dr.started_at IS DISTINCT FROM r.started_at
           OR dr.finished_at IS DISTINCT FROM r.finished_at
           OR dr.target_met IS DISTINCT FROM r.target_met
           OR dr.station_list_source_url IS DISTINCT FROM r.station_list_source_url
           OR dr.source_output_directory IS DISTINCT FROM r.source_output_directory
           OR dr.source_loaded_at IS DISTINCT FROM r.loaded_at
    ),
    0
),
(
    'dim_date_attribute_mismatch_rows',
    (
        SELECT COUNT(*)
        FROM ndbc_dw.dim_date AS d
        WHERE d.date_key IS DISTINCT FROM (
                  EXTRACT(YEAR FROM d.full_date)::integer * 10000
                + EXTRACT(MONTH FROM d.full_date)::integer * 100
                + EXTRACT(DAY FROM d.full_date)::integer
              )
           OR d.day_of_month IS DISTINCT FROM EXTRACT(DAY FROM d.full_date)::smallint
           OR d.iso_day_of_week IS DISTINCT FROM EXTRACT(ISODOW FROM d.full_date)::smallint
           OR d.day_name IS DISTINCT FROM btrim(to_char(d.full_date, 'Day'))
           OR d.week_of_year IS DISTINCT FROM EXTRACT(WEEK FROM d.full_date)::smallint
           OR d.month_number IS DISTINCT FROM EXTRACT(MONTH FROM d.full_date)::smallint
           OR d.month_name IS DISTINCT FROM btrim(to_char(d.full_date, 'Month'))
           OR d.quarter_number IS DISTINCT FROM EXTRACT(QUARTER FROM d.full_date)::smallint
           OR d.year_number IS DISTINCT FROM EXTRACT(YEAR FROM d.full_date)::smallint
           OR d.is_weekend IS DISTINCT FROM
                (EXTRACT(ISODOW FROM d.full_date)::integer IN (6, 7))
    ),
    0
),
(
    'dim_time_attribute_mismatch_rows',
    (
        SELECT COUNT(*)
        FROM ndbc_dw.dim_time AS t
        WHERE t.time_key IS DISTINCT FROM (
                  EXTRACT(HOUR FROM t.full_time)::integer * 10000
                + EXTRACT(MINUTE FROM t.full_time)::integer * 100
                + FLOOR(EXTRACT(SECOND FROM t.full_time))::integer
              )
           OR t.hour_number IS DISTINCT FROM EXTRACT(HOUR FROM t.full_time)::smallint
           OR t.minute_number IS DISTINCT FROM EXTRACT(MINUTE FROM t.full_time)::smallint
           OR t.second_number IS DISTINCT FROM FLOOR(EXTRACT(SECOND FROM t.full_time))::smallint
           OR t.minute_of_day IS DISTINCT FROM (
                  EXTRACT(HOUR FROM t.full_time)::integer * 60
                + EXTRACT(MINUTE FROM t.full_time)::integer
              )::smallint
           OR t.time_bucket IS DISTINCT FROM CASE
                WHEN EXTRACT(HOUR FROM t.full_time) < 6 THEN '00:00-05:59'
                WHEN EXTRACT(HOUR FROM t.full_time) < 12 THEN '06:00-11:59'
                WHEN EXTRACT(HOUR FROM t.full_time) < 18 THEN '12:00-17:59'
                ELSE '18:00-23:59'
              END
    ),
    0
);

-- Pemeriksaan natural grain pada sumber dan warehouse.
INSERT INTO warehouse_verification VALUES
(
    'source_duplicate_observation_grain_rows',
    (
        SELECT COUNT(*) - COUNT(DISTINCT (station_id, observed_at_utc))
        FROM ndbc.observation
    ),
    0
),
(
    'warehouse_duplicate_observation_grain_rows',
    (
        SELECT COUNT(*) - COUNT(DISTINCT (station_key, observed_at_utc))
        FROM ndbc_dw.fact_observation
    ),
    0
),
(
    'warehouse_duplicate_scrape_run_grain_rows',
    (
        SELECT COUNT(*) - COUNT(DISTINCT scrape_run_key)
        FROM ndbc_dw.fact_scrape_run
    ),
    0
);

-- Set difference: jumlah yang sama saja tidak cukup untuk membuktikan isi yang sama.
INSERT INTO warehouse_verification VALUES
(
    'source_observation_rows_missing_in_warehouse',
    (
        SELECT COUNT(*)
        FROM ndbc.observation AS o
        LEFT JOIN ndbc_dw.dim_station AS ds
            ON ds.station_id = o.station_id
        LEFT JOIN ndbc_dw.fact_observation AS f
            ON f.station_key = ds.station_key
           AND f.observed_at_utc = o.observed_at_utc
        WHERE ds.station_key IS NULL
           OR f.observation_fact_key IS NULL
    ),
    0
),
(
    'unexpected_warehouse_observation_rows',
    (
        SELECT COUNT(*)
        FROM ndbc_dw.fact_observation AS f
        JOIN ndbc_dw.dim_station AS ds
            ON ds.station_key = f.station_key
        LEFT JOIN ndbc.observation AS o
            ON o.station_id = ds.station_id
           AND o.observed_at_utc = f.observed_at_utc
        WHERE o.station_id IS NULL
    ),
    0
),
(
    'source_scrape_run_rows_missing_in_warehouse',
    (
        SELECT COUNT(*)
        FROM ndbc.scrape_run AS r
        LEFT JOIN ndbc_dw.dim_scrape_run AS dr
            ON dr.scrape_run_id = r.scrape_run_id
        LEFT JOIN ndbc_dw.fact_scrape_run AS f
            ON f.scrape_run_key = dr.scrape_run_key
        WHERE dr.scrape_run_key IS NULL
           OR f.scrape_run_fact_key IS NULL
    ),
    0
),
(
    'unexpected_warehouse_scrape_run_rows',
    (
        SELECT COUNT(*)
        FROM ndbc_dw.fact_scrape_run AS f
        JOIN ndbc_dw.dim_scrape_run AS dr
            ON dr.scrape_run_key = f.scrape_run_key
        LEFT JOIN ndbc.scrape_run AS r
            ON r.scrape_run_id = dr.scrape_run_id
        WHERE r.scrape_run_id IS NULL
    ),
    0
);

-- Pemeriksaan mapping foreign key. FK database mencegah orphan baru, sedangkan
-- pemeriksaan ini menghasilkan bukti eksplisit untuk laporan dan screenshot.
INSERT INTO warehouse_verification VALUES
(
    'missing_station_dimension_rows',
    (
        SELECT COUNT(*)
        FROM ndbc_dw.fact_observation AS f
        LEFT JOIN ndbc_dw.dim_station AS s
            ON s.station_key = f.station_key
        WHERE s.station_key IS NULL
    ),
    0
),
(
    'missing_observation_date_dimension_rows',
    (
        SELECT COUNT(*)
        FROM ndbc_dw.fact_observation AS f
        LEFT JOIN ndbc_dw.dim_date AS d
            ON d.date_key = f.date_key
        WHERE d.date_key IS NULL
    ),
    0
),
(
    'missing_observation_time_dimension_rows',
    (
        SELECT COUNT(*)
        FROM ndbc_dw.fact_observation AS f
        LEFT JOIN ndbc_dw.dim_time AS t
            ON t.time_key = f.time_key
        WHERE t.time_key IS NULL
    ),
    0
),
(
    'missing_observation_scrape_run_dimension_rows',
    (
        SELECT COUNT(*)
        FROM ndbc_dw.fact_observation AS f
        LEFT JOIN ndbc_dw.dim_scrape_run AS r
            ON r.scrape_run_key = f.first_seen_scrape_run_key
        WHERE r.scrape_run_key IS NULL
    ),
    0
),
(
    'missing_fact_scrape_run_dimension_rows',
    (
        SELECT COUNT(*)
        FROM ndbc_dw.fact_scrape_run AS f
        LEFT JOIN ndbc_dw.dim_scrape_run AS r
            ON r.scrape_run_key = f.scrape_run_key
        WHERE r.scrape_run_key IS NULL
    ),
    0
);

-- Pemeriksaan transformasi observation, termasuk date/time key, derived measure,
-- flag kelompok pengukuran, dan lineage sumber.
INSERT INTO warehouse_verification VALUES
(
    'observation_transformation_mismatch_rows',
    (
        SELECT COUNT(*)
        FROM ndbc.observation AS o
        JOIN ndbc_dw.dim_station AS ds
            ON ds.station_id = o.station_id
        LEFT JOIN ndbc_dw.dim_scrape_run AS dr
            ON dr.scrape_run_id = o.first_seen_run_id
        JOIN ndbc_dw.fact_observation AS f
            ON f.station_key = ds.station_key
           AND f.observed_at_utc = o.observed_at_utc
        WHERE f.date_key IS DISTINCT FROM (
                  EXTRACT(YEAR FROM o.observed_at_utc AT TIME ZONE 'UTC')::integer * 10000
                + EXTRACT(MONTH FROM o.observed_at_utc AT TIME ZONE 'UTC')::integer * 100
                + EXTRACT(DAY FROM o.observed_at_utc AT TIME ZONE 'UTC')::integer
              )
           OR f.time_key IS DISTINCT FROM (
                  EXTRACT(HOUR FROM o.observed_at_utc AT TIME ZONE 'UTC')::integer * 10000
                + EXTRACT(MINUTE FROM o.observed_at_utc AT TIME ZONE 'UTC')::integer * 100
                + FLOOR(EXTRACT(SECOND FROM o.observed_at_utc AT TIME ZONE 'UTC'))::integer
              )
           OR f.first_seen_scrape_run_key IS DISTINCT FROM dr.scrape_run_key
           OR f.wind_direction_degree IS DISTINCT FROM o.wind_direction_degree
           OR f.wind_speed_meter_per_second IS DISTINCT FROM o.wind_speed_meter_per_second
           OR f.wind_gust_meter_per_second IS DISTINCT FROM o.wind_gust_meter_per_second
           OR f.wave_height_meter IS DISTINCT FROM o.wave_height_meter
           OR f.dominant_wave_period_second IS DISTINCT FROM o.dominant_wave_period_second
           OR f.average_wave_period_second IS DISTINCT FROM o.average_wave_period_second
           OR f.mean_wave_direction_degree IS DISTINCT FROM o.mean_wave_direction_degree
           OR f.sea_surface_temperature_celsius IS DISTINCT FROM o.sea_surface_temperature_celsius
           OR f.measurement_count IS DISTINCT FROM num_nonnulls(
                o.wind_direction_degree,
                o.wind_speed_meter_per_second,
                o.wind_gust_meter_per_second,
                o.wave_height_meter,
                o.dominant_wave_period_second,
                o.average_wave_period_second,
                o.mean_wave_direction_degree,
                o.sea_surface_temperature_celsius
              )::smallint
           OR f.has_wind_measurement IS DISTINCT FROM (
                o.wind_direction_degree IS NOT NULL
                OR o.wind_speed_meter_per_second IS NOT NULL
                OR o.wind_gust_meter_per_second IS NOT NULL
              )
           OR f.has_wave_measurement IS DISTINCT FROM (
                o.wave_height_meter IS NOT NULL
                OR o.dominant_wave_period_second IS NOT NULL
                OR o.average_wave_period_second IS NOT NULL
                OR o.mean_wave_direction_degree IS NOT NULL
              )
           OR f.has_temperature_measurement IS DISTINCT FROM
                (o.sea_surface_temperature_celsius IS NOT NULL)
           OR f.source_row_number IS DISTINCT FROM o.source_row_number
           OR f.source_url IS DISTINCT FROM o.source_url
           OR f.source_extracted_at IS DISTINCT FROM o.extracted_at
           OR f.source_loaded_at IS DISTINCT FROM o.loaded_at
    ),
    0
);

-- Pemeriksaan transformasi fact scrape run.
INSERT INTO warehouse_verification VALUES
(
    'scrape_run_transformation_mismatch_rows',
    (
        SELECT COUNT(*)
        FROM ndbc.scrape_run AS r
        JOIN ndbc_dw.dim_scrape_run AS dr
            ON dr.scrape_run_id = r.scrape_run_id
        JOIN ndbc_dw.fact_scrape_run AS f
            ON f.scrape_run_key = dr.scrape_run_key
        WHERE f.started_date_key IS DISTINCT FROM (
                  EXTRACT(YEAR FROM r.started_at AT TIME ZONE 'UTC')::integer * 10000
                + EXTRACT(MONTH FROM r.started_at AT TIME ZONE 'UTC')::integer * 100
                + EXTRACT(DAY FROM r.started_at AT TIME ZONE 'UTC')::integer
              )
           OR f.started_time_key IS DISTINCT FROM (
                  EXTRACT(HOUR FROM r.started_at AT TIME ZONE 'UTC')::integer * 10000
                + EXTRACT(MINUTE FROM r.started_at AT TIME ZONE 'UTC')::integer * 100
                + FLOOR(EXTRACT(SECOND FROM r.started_at AT TIME ZONE 'UTC'))::integer
              )
           OR f.finished_date_key IS DISTINCT FROM (
                  EXTRACT(YEAR FROM r.finished_at AT TIME ZONE 'UTC')::integer * 10000
                + EXTRACT(MONTH FROM r.finished_at AT TIME ZONE 'UTC')::integer * 100
                + EXTRACT(DAY FROM r.finished_at AT TIME ZONE 'UTC')::integer
              )
           OR f.finished_time_key IS DISTINCT FROM (
                  EXTRACT(HOUR FROM r.finished_at AT TIME ZONE 'UTC')::integer * 10000
                + EXTRACT(MINUTE FROM r.finished_at AT TIME ZONE 'UTC')::integer * 100
                + FLOOR(EXTRACT(SECOND FROM r.finished_at AT TIME ZONE 'UTC'))::integer
              )
           OR f.duration_second IS DISTINCT FROM
                EXTRACT(EPOCH FROM (r.finished_at - r.started_at))::numeric(18,3)
           OR f.target_station_count IS DISTINCT FROM r.target_station_count
           OR f.source_candidate_count IS DISTINCT FROM r.source_candidate_count
           OR f.processed_candidate_count IS DISTINCT FROM r.processed_candidate_count
           OR f.successful_station_count IS DISTINCT FROM r.successful_station_count
           OR f.skipped_non_buoy_count IS DISTINCT FROM r.skipped_non_buoy_count
           OR f.skipped_no_data_count IS DISTINCT FROM r.skipped_no_data_count
           OR f.failed_attempt_count IS DISTINCT FROM r.failed_attempt_count
           OR f.source_observation_count IS DISTINCT FROM r.total_observation_count
           OR f.duplicate_observation_count IS DISTINCT FROM r.duplicate_observation_count
    ),
    0
);

-- Pemeriksaan konsistensi key terhadap timestamp fact itu sendiri.
INSERT INTO warehouse_verification VALUES
(
    'fact_observation_date_time_key_mismatch_rows',
    (
        SELECT COUNT(*)
        FROM ndbc_dw.fact_observation AS f
        WHERE f.date_key IS DISTINCT FROM (
                  EXTRACT(YEAR FROM f.observed_at_utc AT TIME ZONE 'UTC')::integer * 10000
                + EXTRACT(MONTH FROM f.observed_at_utc AT TIME ZONE 'UTC')::integer * 100
                + EXTRACT(DAY FROM f.observed_at_utc AT TIME ZONE 'UTC')::integer
              )
           OR f.time_key IS DISTINCT FROM (
                  EXTRACT(HOUR FROM f.observed_at_utc AT TIME ZONE 'UTC')::integer * 10000
                + EXTRACT(MINUTE FROM f.observed_at_utc AT TIME ZONE 'UTC')::integer * 100
                + FLOOR(EXTRACT(SECOND FROM f.observed_at_utc AT TIME ZONE 'UTC'))::integer
              )
    ),
    0
),
(
    'unfinished_etl_batch_rows',
    (
        SELECT COUNT(*)
        FROM ndbc_dw.etl_batch
        WHERE status <> 'SUCCESS'
           OR finished_at IS NULL
    ),
    0
);

\echo ''
\echo '================ HASIL VERIFIKASI FAIL-FAST =============='
SELECT
    metric_name,
    actual_value,
    expected_value,
    CASE
        WHEN actual_value = expected_value THEN 'PASS'
        ELSE 'FAIL'
    END AS verification_status
FROM warehouse_verification
ORDER BY metric_name;

DO $$
DECLARE
    v_failure_summary text;
BEGIN
    SELECT string_agg(
        format('%s: actual=%s expected=%s', metric_name, actual_value, expected_value),
        E'\n'
        ORDER BY metric_name
    )
    INTO v_failure_summary
    FROM warehouse_verification
    WHERE actual_value <> expected_value;

    IF v_failure_summary IS NOT NULL THEN
        RAISE EXCEPTION E'Verifikasi data warehouse gagal:\n%', v_failure_summary;
    END IF;
END
$$;

\echo ''
\echo 'Semua assertion wajib PASS. Query analitik dijalankan setelah tahap ini.'

\echo ''
\echo '================ DAFTAR TABEL DATA WAREHOUSE ============='
SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'ndbc_dw'
ORDER BY table_type, table_name;

\echo ''
\echo '================ JUMLAH DIMENSION DAN FACT ================'
SELECT
    (SELECT COUNT(*) FROM ndbc_dw.dim_date) AS dim_date_count,
    (SELECT COUNT(*) FROM ndbc_dw.dim_time) AS dim_time_count,
    (SELECT COUNT(*) FROM ndbc_dw.dim_station) AS dim_station_count,
    (SELECT COUNT(*) FROM ndbc_dw.dim_scrape_run) AS dim_scrape_run_count,
    (SELECT COUNT(*) FROM ndbc_dw.fact_scrape_run) AS fact_scrape_run_count,
    (SELECT COUNT(*) FROM ndbc_dw.fact_observation) AS fact_observation_count;

\echo ''
\echo '================ SELECT FROM WHERE ========================'
SELECT
    d.full_date,
    t.full_time,
    s.station_id,
    s.station_name,
    f.wind_speed_meter_per_second,
    f.wind_gust_meter_per_second,
    f.wave_height_meter,
    f.sea_surface_temperature_celsius
FROM ndbc_dw.fact_observation AS f
JOIN ndbc_dw.dim_date AS d
    ON d.date_key = f.date_key
JOIN ndbc_dw.dim_time AS t
    ON t.time_key = f.time_key
JOIN ndbc_dw.dim_station AS s
    ON s.station_key = f.station_key
WHERE
    d.full_date = (SELECT MAX(full_date) FROM ndbc_dw.dim_date)
    AND f.wind_speed_meter_per_second IS NOT NULL
ORDER BY
    f.wind_speed_meter_per_second DESC,
    s.station_id,
    t.full_time
LIMIT 20;

\echo ''
\echo '================ ANALISIS 1: RINGKASAN HARIAN ============='
SELECT
    full_date,
    station_id,
    station_name,
    observation_count,
    ROUND(average_wind_speed_meter_per_second::numeric, 2) AS avg_wind_speed_mps,
    ROUND(maximum_wind_gust_meter_per_second::numeric, 2) AS max_wind_gust_mps,
    ROUND(average_wave_height_meter::numeric, 2) AS avg_wave_height_m,
    ROUND(average_sea_surface_temperature_celsius::numeric, 2) AS avg_sea_temperature_c
FROM ndbc_dw.v_daily_station_weather
WHERE full_date >= (SELECT MAX(full_date) - 2 FROM ndbc_dw.dim_date)
ORDER BY
    full_date DESC,
    maximum_wind_gust_meter_per_second DESC NULLS LAST
LIMIT 20;

\echo ''
\echo '================ ANALISIS 2: STASIUN ANGIN TERKUAT ======='
SELECT
    s.station_id,
    s.station_name,
    COUNT(*) AS observation_count,
    ROUND(AVG(f.wind_speed_meter_per_second)::numeric, 2) AS avg_wind_speed_mps,
    ROUND(MAX(f.wind_speed_meter_per_second)::numeric, 2) AS max_wind_speed_mps,
    ROUND(MAX(f.wind_gust_meter_per_second)::numeric, 2) AS max_wind_gust_mps
FROM ndbc_dw.fact_observation AS f
JOIN ndbc_dw.dim_station AS s
    ON s.station_key = f.station_key
JOIN ndbc_dw.dim_date AS d
    ON d.date_key = f.date_key
WHERE
    d.full_date >= (SELECT MAX(full_date) - 6 FROM ndbc_dw.dim_date)
    AND f.wind_speed_meter_per_second IS NOT NULL
GROUP BY s.station_id, s.station_name
HAVING COUNT(f.wind_speed_meter_per_second) >= 10
ORDER BY avg_wind_speed_mps DESC
LIMIT 10;

\echo ''
\echo '================ ANALISIS 3: KUALITAS BATCH SCRAPING ====='
SELECT
    scrape_run_id,
    started_at,
    finished_at,
    ROUND(duration_second, 2) AS duration_second,
    successful_station_count,
    source_observation_count,
    failed_attempt_count,
    duplicate_observation_count,
    station_success_rate_percent
FROM ndbc_dw.v_scrape_run_quality
ORDER BY started_at DESC;

\echo ''
\echo '================ RIWAYAT REFRESH WAREHOUSE ================'
SELECT
    etl_batch_id,
    started_at,
    finished_at,
    status,
    source_observation_count,
    inserted_observation_count,
    total_observation_count
FROM ndbc_dw.etl_batch
ORDER BY etl_batch_id DESC;
