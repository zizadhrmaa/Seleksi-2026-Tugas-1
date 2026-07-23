\set ON_ERROR_STOP on
\pset pager off
\timing on

BEGIN;

CREATE OR REPLACE FUNCTION ndbc_dw.refresh_warehouse()
RETURNS TABLE (
    etl_batch_id bigint,
    source_station_count bigint,
    source_scrape_run_count bigint,
    source_observation_count bigint,
    inserted_station_count bigint,
    inserted_scrape_run_count bigint,
    inserted_observation_count bigint,
    total_station_count bigint,
    total_scrape_run_count bigint,
    total_observation_count bigint
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_etl_batch_id bigint;
    v_source_station_count bigint;
    v_source_scrape_run_count bigint;
    v_source_observation_count bigint;
    v_before_station_count bigint;
    v_before_scrape_run_count bigint;
    v_before_observation_count bigint;
    v_after_station_count bigint;
    v_after_scrape_run_count bigint;
    v_after_observation_count bigint;
BEGIN
    IF to_regclass('ndbc.station') IS NULL
        OR to_regclass('ndbc.scrape_run') IS NULL
        OR to_regclass('ndbc.observation') IS NULL
        OR to_regclass('ndbc.data_provider') IS NULL THEN
        RAISE EXCEPTION
            'Schema sumber ndbc belum lengkap. Jalankan proses Data Storing sebelum memuat Data Warehouse.';
    END IF;

    SELECT COUNT(*) INTO v_source_station_count FROM ndbc.station;
    SELECT COUNT(*) INTO v_source_scrape_run_count FROM ndbc.scrape_run;
    SELECT COUNT(*) INTO v_source_observation_count FROM ndbc.observation;

    SELECT COUNT(*) INTO v_before_station_count FROM ndbc_dw.dim_station;
    SELECT COUNT(*) INTO v_before_scrape_run_count FROM ndbc_dw.dim_scrape_run;
    SELECT COUNT(*) INTO v_before_observation_count FROM ndbc_dw.fact_observation;

    INSERT INTO ndbc_dw.etl_batch AS eb (
        status,
        source_station_count,
        source_scrape_run_count,
        source_observation_count
    )
    VALUES (
        'RUNNING',
        v_source_station_count,
        v_source_scrape_run_count,
        v_source_observation_count
    )
    RETURNING eb.etl_batch_id INTO v_etl_batch_id;

    -- Memuat dimensi tanggal dari seluruh timestamp observasi dan batch scraping.
    WITH source_dates AS (
        SELECT (o.observed_at_utc AT TIME ZONE 'UTC')::date AS full_date
        FROM ndbc.observation AS o
        UNION
        SELECT (r.started_at AT TIME ZONE 'UTC')::date
        FROM ndbc.scrape_run AS r
        UNION
        SELECT (r.finished_at AT TIME ZONE 'UTC')::date
        FROM ndbc.scrape_run AS r
    )
    INSERT INTO ndbc_dw.dim_date (
        date_key,
        full_date,
        day_of_month,
        iso_day_of_week,
        day_name,
        week_of_year,
        month_number,
        month_name,
        quarter_number,
        year_number,
        is_weekend
    )
    SELECT
        (
            EXTRACT(YEAR FROM sd.full_date)::integer * 10000
            + EXTRACT(MONTH FROM sd.full_date)::integer * 100
            + EXTRACT(DAY FROM sd.full_date)::integer
        ) AS date_key,
        sd.full_date,
        EXTRACT(DAY FROM sd.full_date)::smallint,
        EXTRACT(ISODOW FROM sd.full_date)::smallint,
        btrim(to_char(sd.full_date, 'Day')),
        EXTRACT(WEEK FROM sd.full_date)::smallint,
        EXTRACT(MONTH FROM sd.full_date)::smallint,
        btrim(to_char(sd.full_date, 'Month')),
        EXTRACT(QUARTER FROM sd.full_date)::smallint,
        EXTRACT(YEAR FROM sd.full_date)::smallint,
        EXTRACT(ISODOW FROM sd.full_date)::integer IN (6, 7)
    FROM source_dates AS sd
    WHERE sd.full_date IS NOT NULL
    ON CONFLICT (date_key) DO NOTHING;

    -- Memuat dimensi waktu UTC. Timestamp dibulatkan ke detik agar time_key stabil.
    WITH source_times AS (
        SELECT date_trunc('second', o.observed_at_utc AT TIME ZONE 'UTC')::time AS full_time
        FROM ndbc.observation AS o
        UNION
        SELECT date_trunc('second', r.started_at AT TIME ZONE 'UTC')::time
        FROM ndbc.scrape_run AS r
        UNION
        SELECT date_trunc('second', r.finished_at AT TIME ZONE 'UTC')::time
        FROM ndbc.scrape_run AS r
    )
    INSERT INTO ndbc_dw.dim_time (
        time_key,
        full_time,
        hour_number,
        minute_number,
        second_number,
        minute_of_day,
        time_bucket
    )
    SELECT
        (
            EXTRACT(HOUR FROM st.full_time)::integer * 10000
            + EXTRACT(MINUTE FROM st.full_time)::integer * 100
            + FLOOR(EXTRACT(SECOND FROM st.full_time))::integer
        ) AS time_key,
        st.full_time,
        EXTRACT(HOUR FROM st.full_time)::smallint,
        EXTRACT(MINUTE FROM st.full_time)::smallint,
        FLOOR(EXTRACT(SECOND FROM st.full_time))::smallint,
        (
            EXTRACT(HOUR FROM st.full_time)::integer * 60
            + EXTRACT(MINUTE FROM st.full_time)::integer
        )::smallint,
        CASE
            WHEN EXTRACT(HOUR FROM st.full_time) < 6 THEN '00:00-05:59'
            WHEN EXTRACT(HOUR FROM st.full_time) < 12 THEN '06:00-11:59'
            WHEN EXTRACT(HOUR FROM st.full_time) < 18 THEN '12:00-17:59'
            ELSE '18:00-23:59'
        END
    FROM source_times AS st
    WHERE st.full_time IS NOT NULL
    ON CONFLICT (time_key) DO NOTHING;

    -- Type 1 upsert untuk metadata stasiun dan provider yang telah didenormalisasi.
    INSERT INTO ndbc_dw.dim_station (
        station_id,
        station_name,
        location,
        device_type,
        payload,
        latitude,
        longitude,
        water_depth_meter,
        station_status,
        provider_name,
        provider_base_url,
        detail_url,
        realtime_data_url,
        source_created_at,
        source_updated_at
    )
    SELECT
        s.station_id,
        s.station_name,
        s.location,
        s.device_type,
        s.payload,
        s.latitude,
        s.longitude,
        s.water_depth_meter,
        s.status,
        p.provider_name,
        p.base_url,
        s.detail_url,
        s.realtime_data_url,
        s.created_at,
        s.updated_at
    FROM ndbc.station AS s
    JOIN ndbc.data_provider AS p
        ON p.provider_id = s.provider_id
    ON CONFLICT (station_id) DO UPDATE SET
        station_name = EXCLUDED.station_name,
        location = EXCLUDED.location,
        device_type = EXCLUDED.device_type,
        payload = EXCLUDED.payload,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        water_depth_meter = EXCLUDED.water_depth_meter,
        station_status = EXCLUDED.station_status,
        provider_name = EXCLUDED.provider_name,
        provider_base_url = EXCLUDED.provider_base_url,
        detail_url = EXCLUDED.detail_url,
        realtime_data_url = EXCLUDED.realtime_data_url,
        source_created_at = EXCLUDED.source_created_at,
        source_updated_at = EXCLUDED.source_updated_at
    WHERE (
        ndbc_dw.dim_station.station_name,
        ndbc_dw.dim_station.location,
        ndbc_dw.dim_station.device_type,
        ndbc_dw.dim_station.payload,
        ndbc_dw.dim_station.latitude,
        ndbc_dw.dim_station.longitude,
        ndbc_dw.dim_station.water_depth_meter,
        ndbc_dw.dim_station.station_status,
        ndbc_dw.dim_station.provider_name,
        ndbc_dw.dim_station.provider_base_url,
        ndbc_dw.dim_station.detail_url,
        ndbc_dw.dim_station.realtime_data_url,
        ndbc_dw.dim_station.source_created_at,
        ndbc_dw.dim_station.source_updated_at
    ) IS DISTINCT FROM (
        EXCLUDED.station_name,
        EXCLUDED.location,
        EXCLUDED.device_type,
        EXCLUDED.payload,
        EXCLUDED.latitude,
        EXCLUDED.longitude,
        EXCLUDED.water_depth_meter,
        EXCLUDED.station_status,
        EXCLUDED.provider_name,
        EXCLUDED.provider_base_url,
        EXCLUDED.detail_url,
        EXCLUDED.realtime_data_url,
        EXCLUDED.source_created_at,
        EXCLUDED.source_updated_at
    );

    -- Upsert konteks batch scraping berdasarkan natural key scrape_run_id.
    INSERT INTO ndbc_dw.dim_scrape_run (
        scrape_run_id,
        started_at,
        finished_at,
        target_met,
        station_list_source_url,
        source_output_directory,
        source_loaded_at
    )
    SELECT
        r.scrape_run_id,
        r.started_at,
        r.finished_at,
        r.target_met,
        r.station_list_source_url,
        r.source_output_directory,
        r.loaded_at
    FROM ndbc.scrape_run AS r
    ON CONFLICT (scrape_run_id) DO UPDATE SET
        started_at = EXCLUDED.started_at,
        finished_at = EXCLUDED.finished_at,
        target_met = EXCLUDED.target_met,
        station_list_source_url = EXCLUDED.station_list_source_url,
        source_output_directory = EXCLUDED.source_output_directory,
        source_loaded_at = EXCLUDED.source_loaded_at
    WHERE (
        ndbc_dw.dim_scrape_run.started_at,
        ndbc_dw.dim_scrape_run.finished_at,
        ndbc_dw.dim_scrape_run.target_met,
        ndbc_dw.dim_scrape_run.station_list_source_url,
        ndbc_dw.dim_scrape_run.source_output_directory,
        ndbc_dw.dim_scrape_run.source_loaded_at
    ) IS DISTINCT FROM (
        EXCLUDED.started_at,
        EXCLUDED.finished_at,
        EXCLUDED.target_met,
        EXCLUDED.station_list_source_url,
        EXCLUDED.source_output_directory,
        EXCLUDED.source_loaded_at
    );

    -- Memuat fact pada grain satu baris per batch scraping.
    INSERT INTO ndbc_dw.fact_scrape_run (
        scrape_run_key,
        started_date_key,
        started_time_key,
        finished_date_key,
        finished_time_key,
        duration_second,
        target_station_count,
        source_candidate_count,
        processed_candidate_count,
        successful_station_count,
        skipped_non_buoy_count,
        skipped_no_data_count,
        failed_attempt_count,
        source_observation_count,
        duplicate_observation_count,
        dw_loaded_at
    )
    SELECT
        dr.scrape_run_key,
        (
            EXTRACT(YEAR FROM r.started_at AT TIME ZONE 'UTC')::integer * 10000
            + EXTRACT(MONTH FROM r.started_at AT TIME ZONE 'UTC')::integer * 100
            + EXTRACT(DAY FROM r.started_at AT TIME ZONE 'UTC')::integer
        ),
        (
            EXTRACT(HOUR FROM r.started_at AT TIME ZONE 'UTC')::integer * 10000
            + EXTRACT(MINUTE FROM r.started_at AT TIME ZONE 'UTC')::integer * 100
            + FLOOR(EXTRACT(SECOND FROM r.started_at AT TIME ZONE 'UTC'))::integer
        ),
        (
            EXTRACT(YEAR FROM r.finished_at AT TIME ZONE 'UTC')::integer * 10000
            + EXTRACT(MONTH FROM r.finished_at AT TIME ZONE 'UTC')::integer * 100
            + EXTRACT(DAY FROM r.finished_at AT TIME ZONE 'UTC')::integer
        ),
        (
            EXTRACT(HOUR FROM r.finished_at AT TIME ZONE 'UTC')::integer * 10000
            + EXTRACT(MINUTE FROM r.finished_at AT TIME ZONE 'UTC')::integer * 100
            + FLOOR(EXTRACT(SECOND FROM r.finished_at AT TIME ZONE 'UTC'))::integer
        ),
        EXTRACT(EPOCH FROM (r.finished_at - r.started_at))::numeric(18,3),
        r.target_station_count,
        r.source_candidate_count,
        r.processed_candidate_count,
        r.successful_station_count,
        r.skipped_non_buoy_count,
        r.skipped_no_data_count,
        r.failed_attempt_count,
        r.total_observation_count,
        r.duplicate_observation_count,
        CURRENT_TIMESTAMP
    FROM ndbc.scrape_run AS r
    JOIN ndbc_dw.dim_scrape_run AS dr
        ON dr.scrape_run_id = r.scrape_run_id
    ON CONFLICT (scrape_run_key) DO UPDATE SET
        started_date_key = EXCLUDED.started_date_key,
        started_time_key = EXCLUDED.started_time_key,
        finished_date_key = EXCLUDED.finished_date_key,
        finished_time_key = EXCLUDED.finished_time_key,
        duration_second = EXCLUDED.duration_second,
        target_station_count = EXCLUDED.target_station_count,
        source_candidate_count = EXCLUDED.source_candidate_count,
        processed_candidate_count = EXCLUDED.processed_candidate_count,
        successful_station_count = EXCLUDED.successful_station_count,
        skipped_non_buoy_count = EXCLUDED.skipped_non_buoy_count,
        skipped_no_data_count = EXCLUDED.skipped_no_data_count,
        failed_attempt_count = EXCLUDED.failed_attempt_count,
        source_observation_count = EXCLUDED.source_observation_count,
        duplicate_observation_count = EXCLUDED.duplicate_observation_count,
        dw_loaded_at = CURRENT_TIMESTAMP
    WHERE (
        ndbc_dw.fact_scrape_run.started_date_key,
        ndbc_dw.fact_scrape_run.started_time_key,
        ndbc_dw.fact_scrape_run.finished_date_key,
        ndbc_dw.fact_scrape_run.finished_time_key,
        ndbc_dw.fact_scrape_run.duration_second,
        ndbc_dw.fact_scrape_run.target_station_count,
        ndbc_dw.fact_scrape_run.source_candidate_count,
        ndbc_dw.fact_scrape_run.processed_candidate_count,
        ndbc_dw.fact_scrape_run.successful_station_count,
        ndbc_dw.fact_scrape_run.skipped_non_buoy_count,
        ndbc_dw.fact_scrape_run.skipped_no_data_count,
        ndbc_dw.fact_scrape_run.failed_attempt_count,
        ndbc_dw.fact_scrape_run.source_observation_count,
        ndbc_dw.fact_scrape_run.duplicate_observation_count
    ) IS DISTINCT FROM (
        EXCLUDED.started_date_key,
        EXCLUDED.started_time_key,
        EXCLUDED.finished_date_key,
        EXCLUDED.finished_time_key,
        EXCLUDED.duration_second,
        EXCLUDED.target_station_count,
        EXCLUDED.source_candidate_count,
        EXCLUDED.processed_candidate_count,
        EXCLUDED.successful_station_count,
        EXCLUDED.skipped_non_buoy_count,
        EXCLUDED.skipped_no_data_count,
        EXCLUDED.failed_attempt_count,
        EXCLUDED.source_observation_count,
        EXCLUDED.duplicate_observation_count
    );

    -- Memuat fact utama pada grain satu stasiun dan satu timestamp UTC.
    -- ON CONFLICT menjaga proses incremental tetap idempotent.
    INSERT INTO ndbc_dw.fact_observation (
        station_key,
        date_key,
        time_key,
        first_seen_scrape_run_key,
        observed_at_utc,
        wind_direction_degree,
        wind_speed_meter_per_second,
        wind_gust_meter_per_second,
        wave_height_meter,
        dominant_wave_period_second,
        average_wave_period_second,
        mean_wave_direction_degree,
        sea_surface_temperature_celsius,
        measurement_count,
        has_wind_measurement,
        has_wave_measurement,
        has_temperature_measurement,
        source_row_number,
        source_url,
        source_extracted_at,
        source_loaded_at,
        dw_loaded_at
    )
    SELECT
        ds.station_key,
        (
            EXTRACT(YEAR FROM o.observed_at_utc AT TIME ZONE 'UTC')::integer * 10000
            + EXTRACT(MONTH FROM o.observed_at_utc AT TIME ZONE 'UTC')::integer * 100
            + EXTRACT(DAY FROM o.observed_at_utc AT TIME ZONE 'UTC')::integer
        ),
        (
            EXTRACT(HOUR FROM o.observed_at_utc AT TIME ZONE 'UTC')::integer * 10000
            + EXTRACT(MINUTE FROM o.observed_at_utc AT TIME ZONE 'UTC')::integer * 100
            + FLOOR(EXTRACT(SECOND FROM o.observed_at_utc AT TIME ZONE 'UTC'))::integer
        ),
        dr.scrape_run_key,
        o.observed_at_utc,
        o.wind_direction_degree,
        o.wind_speed_meter_per_second,
        o.wind_gust_meter_per_second,
        o.wave_height_meter,
        o.dominant_wave_period_second,
        o.average_wave_period_second,
        o.mean_wave_direction_degree,
        o.sea_surface_temperature_celsius,
        num_nonnulls(
            o.wind_direction_degree,
            o.wind_speed_meter_per_second,
            o.wind_gust_meter_per_second,
            o.wave_height_meter,
            o.dominant_wave_period_second,
            o.average_wave_period_second,
            o.mean_wave_direction_degree,
            o.sea_surface_temperature_celsius
        )::smallint,
        (
            o.wind_direction_degree IS NOT NULL
            OR o.wind_speed_meter_per_second IS NOT NULL
            OR o.wind_gust_meter_per_second IS NOT NULL
        ),
        (
            o.wave_height_meter IS NOT NULL
            OR o.dominant_wave_period_second IS NOT NULL
            OR o.average_wave_period_second IS NOT NULL
            OR o.mean_wave_direction_degree IS NOT NULL
        ),
        o.sea_surface_temperature_celsius IS NOT NULL,
        o.source_row_number,
        o.source_url,
        o.extracted_at,
        o.loaded_at,
        CURRENT_TIMESTAMP
    FROM ndbc.observation AS o
    JOIN ndbc_dw.dim_station AS ds
        ON ds.station_id = o.station_id
    JOIN ndbc_dw.dim_scrape_run AS dr
        ON dr.scrape_run_id = o.first_seen_run_id
    ON CONFLICT (station_key, observed_at_utc) DO UPDATE SET
        date_key = EXCLUDED.date_key,
        time_key = EXCLUDED.time_key,
        first_seen_scrape_run_key = EXCLUDED.first_seen_scrape_run_key,
        wind_direction_degree = EXCLUDED.wind_direction_degree,
        wind_speed_meter_per_second = EXCLUDED.wind_speed_meter_per_second,
        wind_gust_meter_per_second = EXCLUDED.wind_gust_meter_per_second,
        wave_height_meter = EXCLUDED.wave_height_meter,
        dominant_wave_period_second = EXCLUDED.dominant_wave_period_second,
        average_wave_period_second = EXCLUDED.average_wave_period_second,
        mean_wave_direction_degree = EXCLUDED.mean_wave_direction_degree,
        sea_surface_temperature_celsius = EXCLUDED.sea_surface_temperature_celsius,
        measurement_count = EXCLUDED.measurement_count,
        has_wind_measurement = EXCLUDED.has_wind_measurement,
        has_wave_measurement = EXCLUDED.has_wave_measurement,
        has_temperature_measurement = EXCLUDED.has_temperature_measurement,
        source_row_number = EXCLUDED.source_row_number,
        source_url = EXCLUDED.source_url,
        source_extracted_at = EXCLUDED.source_extracted_at,
        source_loaded_at = EXCLUDED.source_loaded_at,
        dw_loaded_at = CURRENT_TIMESTAMP
    WHERE (
        ndbc_dw.fact_observation.date_key,
        ndbc_dw.fact_observation.time_key,
        ndbc_dw.fact_observation.first_seen_scrape_run_key,
        ndbc_dw.fact_observation.wind_direction_degree,
        ndbc_dw.fact_observation.wind_speed_meter_per_second,
        ndbc_dw.fact_observation.wind_gust_meter_per_second,
        ndbc_dw.fact_observation.wave_height_meter,
        ndbc_dw.fact_observation.dominant_wave_period_second,
        ndbc_dw.fact_observation.average_wave_period_second,
        ndbc_dw.fact_observation.mean_wave_direction_degree,
        ndbc_dw.fact_observation.sea_surface_temperature_celsius,
        ndbc_dw.fact_observation.measurement_count,
        ndbc_dw.fact_observation.has_wind_measurement,
        ndbc_dw.fact_observation.has_wave_measurement,
        ndbc_dw.fact_observation.has_temperature_measurement,
        ndbc_dw.fact_observation.source_row_number,
        ndbc_dw.fact_observation.source_url,
        ndbc_dw.fact_observation.source_extracted_at,
        ndbc_dw.fact_observation.source_loaded_at
    ) IS DISTINCT FROM (
        EXCLUDED.date_key,
        EXCLUDED.time_key,
        EXCLUDED.first_seen_scrape_run_key,
        EXCLUDED.wind_direction_degree,
        EXCLUDED.wind_speed_meter_per_second,
        EXCLUDED.wind_gust_meter_per_second,
        EXCLUDED.wave_height_meter,
        EXCLUDED.dominant_wave_period_second,
        EXCLUDED.average_wave_period_second,
        EXCLUDED.mean_wave_direction_degree,
        EXCLUDED.sea_surface_temperature_celsius,
        EXCLUDED.measurement_count,
        EXCLUDED.has_wind_measurement,
        EXCLUDED.has_wave_measurement,
        EXCLUDED.has_temperature_measurement,
        EXCLUDED.source_row_number,
        EXCLUDED.source_url,
        EXCLUDED.source_extracted_at,
        EXCLUDED.source_loaded_at
    );

    -- Memperbarui statistik planner setelah load berukuran besar.
    ANALYZE ndbc_dw.dim_date;
    ANALYZE ndbc_dw.dim_time;
    ANALYZE ndbc_dw.dim_station;
    ANALYZE ndbc_dw.dim_scrape_run;
    ANALYZE ndbc_dw.fact_scrape_run;
    ANALYZE ndbc_dw.fact_observation;

    SELECT COUNT(*) INTO v_after_station_count FROM ndbc_dw.dim_station;
    SELECT COUNT(*) INTO v_after_scrape_run_count FROM ndbc_dw.dim_scrape_run;
    SELECT COUNT(*) INTO v_after_observation_count FROM ndbc_dw.fact_observation;

    -- Menutup audit batch hanya setelah seluruh dimension dan fact berhasil dimuat.
    UPDATE ndbc_dw.etl_batch
    SET
        finished_at = CURRENT_TIMESTAMP,
        status = 'SUCCESS',
        inserted_station_count = v_after_station_count - v_before_station_count,
        inserted_scrape_run_count = v_after_scrape_run_count - v_before_scrape_run_count,
        inserted_observation_count = v_after_observation_count - v_before_observation_count,
        total_station_count = v_after_station_count,
        total_scrape_run_count = v_after_scrape_run_count,
        total_observation_count = v_after_observation_count
    WHERE ndbc_dw.etl_batch.etl_batch_id = v_etl_batch_id;

    RETURN QUERY
    SELECT
        v_etl_batch_id,
        v_source_station_count,
        v_source_scrape_run_count,
        v_source_observation_count,
        v_after_station_count - v_before_station_count,
        v_after_scrape_run_count - v_before_scrape_run_count,
        v_after_observation_count - v_before_observation_count,
        v_after_station_count,
        v_after_scrape_run_count,
        v_after_observation_count;
END;
$$;

SELECT * FROM ndbc_dw.refresh_warehouse();

COMMIT;

\echo ''
\echo '================ JUMLAH DATA WAREHOUSE ================'
SELECT
    (SELECT COUNT(*) FROM ndbc_dw.dim_date) AS dim_date_count,
    (SELECT COUNT(*) FROM ndbc_dw.dim_time) AS dim_time_count,
    (SELECT COUNT(*) FROM ndbc_dw.dim_station) AS dim_station_count,
    (SELECT COUNT(*) FROM ndbc_dw.dim_scrape_run) AS dim_scrape_run_count,
    (SELECT COUNT(*) FROM ndbc_dw.fact_scrape_run) AS fact_scrape_run_count,
    (SELECT COUNT(*) FROM ndbc_dw.fact_observation) AS fact_observation_count;

\echo ''
\echo '================ ETL BATCH TERBARU ====================='
SELECT
    etl_batch_id,
    started_at,
    finished_at,
    status,
    source_station_count,
    source_scrape_run_count,
    source_observation_count,
    inserted_station_count,
    inserted_scrape_run_count,
    inserted_observation_count,
    total_station_count,
    total_scrape_run_count,
    total_observation_count
FROM ndbc_dw.etl_batch
ORDER BY etl_batch_id DESC
LIMIT 2;
