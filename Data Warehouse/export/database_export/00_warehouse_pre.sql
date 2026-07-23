--
-- PostgreSQL database dump
--

\restrict zzzaF8gIfn0WT3drWA5QRkFOsNj30yS0aNyIqoMFN1wtg6B3p0kpYzE961dwk19

-- Dumped from database version 13.23
-- Dumped by pg_dump version 13.23

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'WIN1252';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: ndbc_dw; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA ndbc_dw;


--
-- Name: SCHEMA ndbc_dw; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA ndbc_dw IS 'Data warehouse meteorologi NDBC dengan constellation schema. Sumber data berasal dari schema operasional ndbc.';


--
-- Name: refresh_warehouse(); Type: FUNCTION; Schema: ndbc_dw; Owner: -
--

CREATE FUNCTION ndbc_dw.refresh_warehouse() RETURNS TABLE(etl_batch_id bigint, source_station_count bigint, source_scrape_run_count bigint, source_observation_count bigint, inserted_station_count bigint, inserted_scrape_run_count bigint, inserted_observation_count bigint, total_station_count bigint, total_scrape_run_count bigint, total_observation_count bigint)
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


--
-- Name: set_dw_updated_at(); Type: FUNCTION; Schema: ndbc_dw; Owner: -
--

CREATE FUNCTION ndbc_dw.set_dw_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.dw_updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: dim_date; Type: TABLE; Schema: ndbc_dw; Owner: -
--

CREATE TABLE ndbc_dw.dim_date (
    date_key integer NOT NULL,
    full_date date NOT NULL,
    day_of_month smallint NOT NULL,
    iso_day_of_week smallint NOT NULL,
    day_name character varying(12) NOT NULL,
    week_of_year smallint NOT NULL,
    month_number smallint NOT NULL,
    month_name character varying(12) NOT NULL,
    quarter_number smallint NOT NULL,
    year_number smallint NOT NULL,
    is_weekend boolean NOT NULL,
    CONSTRAINT ck_dim_date_day CHECK (((day_of_month >= 1) AND (day_of_month <= 31))),
    CONSTRAINT ck_dim_date_iso_day CHECK (((iso_day_of_week >= 1) AND (iso_day_of_week <= 7))),
    CONSTRAINT ck_dim_date_key_positive CHECK ((date_key > 0)),
    CONSTRAINT ck_dim_date_month CHECK (((month_number >= 1) AND (month_number <= 12))),
    CONSTRAINT ck_dim_date_quarter CHECK (((quarter_number >= 1) AND (quarter_number <= 4))),
    CONSTRAINT ck_dim_date_week CHECK (((week_of_year >= 1) AND (week_of_year <= 53)))
);


--
-- Name: TABLE dim_date; Type: COMMENT; Schema: ndbc_dw; Owner: -
--

COMMENT ON TABLE ndbc_dw.dim_date IS 'Dimensi kalender. Satu baris merepresentasikan satu tanggal UTC.';


--
-- Name: dim_scrape_run; Type: TABLE; Schema: ndbc_dw; Owner: -
--

CREATE TABLE ndbc_dw.dim_scrape_run (
    scrape_run_key bigint NOT NULL,
    scrape_run_id character varying(64) NOT NULL,
    started_at timestamp with time zone NOT NULL,
    finished_at timestamp with time zone NOT NULL,
    target_met boolean NOT NULL,
    station_list_source_url text NOT NULL,
    source_output_directory text,
    source_loaded_at timestamp with time zone NOT NULL,
    dw_created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    dw_updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_dim_scrape_run_id_not_blank CHECK ((length(btrim((scrape_run_id)::text)) > 0)),
    CONSTRAINT ck_dim_scrape_run_time_order CHECK ((finished_at >= started_at))
);


--
-- Name: TABLE dim_scrape_run; Type: COMMENT; Schema: ndbc_dw; Owner: -
--

COMMENT ON TABLE ndbc_dw.dim_scrape_run IS 'Dimensi batch scraping. Menyediakan konteks proses ekstraksi untuk fact observation dan fact scrape run.';


--
-- Name: dim_scrape_run_scrape_run_key_seq; Type: SEQUENCE; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ndbc_dw.dim_scrape_run ALTER COLUMN scrape_run_key ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ndbc_dw.dim_scrape_run_scrape_run_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: dim_station; Type: TABLE; Schema: ndbc_dw; Owner: -
--

CREATE TABLE ndbc_dw.dim_station (
    station_key bigint NOT NULL,
    station_id character varying(10) NOT NULL,
    station_name character varying(160) NOT NULL,
    location text,
    device_type character varying(120) NOT NULL,
    payload character varying(120) NOT NULL,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    water_depth_meter double precision NOT NULL,
    station_status character varying(40) NOT NULL,
    provider_name character varying(120) NOT NULL,
    provider_base_url text NOT NULL,
    detail_url text NOT NULL,
    realtime_data_url text NOT NULL,
    source_created_at timestamp with time zone NOT NULL,
    source_updated_at timestamp with time zone NOT NULL,
    dw_created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    dw_updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_dim_station_id_not_blank CHECK ((length(btrim((station_id)::text)) > 0)),
    CONSTRAINT ck_dim_station_latitude CHECK (((latitude >= ('-90'::integer)::double precision) AND (latitude <= (90)::double precision))),
    CONSTRAINT ck_dim_station_longitude CHECK (((longitude >= ('-180'::integer)::double precision) AND (longitude <= (180)::double precision))),
    CONSTRAINT ck_dim_station_water_depth CHECK ((water_depth_meter >= (0)::double precision))
);


--
-- Name: TABLE dim_station; Type: COMMENT; Schema: ndbc_dw; Owner: -
--

COMMENT ON TABLE ndbc_dw.dim_station IS 'Dimensi stasiun terdenormalisasi. Atribut provider disimpan bersama metadata stasiun agar query analitik tidak membutuhkan snowflake join tambahan.';


--
-- Name: dim_station_station_key_seq; Type: SEQUENCE; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ndbc_dw.dim_station ALTER COLUMN station_key ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ndbc_dw.dim_station_station_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: dim_time; Type: TABLE; Schema: ndbc_dw; Owner: -
--

CREATE TABLE ndbc_dw.dim_time (
    time_key integer NOT NULL,
    full_time time without time zone NOT NULL,
    hour_number smallint NOT NULL,
    minute_number smallint NOT NULL,
    second_number smallint NOT NULL,
    minute_of_day smallint NOT NULL,
    time_bucket character varying(20) NOT NULL,
    CONSTRAINT ck_dim_time_bucket CHECK (((time_bucket)::text = ANY ((ARRAY['00:00-05:59'::character varying, '06:00-11:59'::character varying, '12:00-17:59'::character varying, '18:00-23:59'::character varying])::text[]))),
    CONSTRAINT ck_dim_time_hour CHECK (((hour_number >= 0) AND (hour_number <= 23))),
    CONSTRAINT ck_dim_time_key_nonnegative CHECK ((time_key >= 0)),
    CONSTRAINT ck_dim_time_minute CHECK (((minute_number >= 0) AND (minute_number <= 59))),
    CONSTRAINT ck_dim_time_minute_of_day CHECK (((minute_of_day >= 0) AND (minute_of_day <= 1439))),
    CONSTRAINT ck_dim_time_second CHECK (((second_number >= 0) AND (second_number <= 59)))
);


--
-- Name: TABLE dim_time; Type: COMMENT; Schema: ndbc_dw; Owner: -
--

COMMENT ON TABLE ndbc_dw.dim_time IS 'Dimensi waktu harian UTC dengan granularitas satu detik.';


--
-- Name: etl_batch; Type: TABLE; Schema: ndbc_dw; Owner: -
--

CREATE TABLE ndbc_dw.etl_batch (
    etl_batch_id bigint NOT NULL,
    started_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    finished_at timestamp with time zone,
    status character varying(20) NOT NULL,
    source_station_count bigint NOT NULL,
    source_scrape_run_count bigint NOT NULL,
    source_observation_count bigint NOT NULL,
    inserted_station_count bigint,
    inserted_scrape_run_count bigint,
    inserted_observation_count bigint,
    total_station_count bigint,
    total_scrape_run_count bigint,
    total_observation_count bigint,
    CONSTRAINT ck_etl_batch_result_counts CHECK ((((inserted_station_count IS NULL) OR (inserted_station_count >= 0)) AND ((inserted_scrape_run_count IS NULL) OR (inserted_scrape_run_count >= 0)) AND ((inserted_observation_count IS NULL) OR (inserted_observation_count >= 0)) AND ((total_station_count IS NULL) OR (total_station_count >= 0)) AND ((total_scrape_run_count IS NULL) OR (total_scrape_run_count >= 0)) AND ((total_observation_count IS NULL) OR (total_observation_count >= 0)))),
    CONSTRAINT ck_etl_batch_source_counts CHECK (((source_station_count >= 0) AND (source_scrape_run_count >= 0) AND (source_observation_count >= 0))),
    CONSTRAINT ck_etl_batch_state_consistency CHECK (((((status)::text = 'RUNNING'::text) AND (finished_at IS NULL) AND (inserted_station_count IS NULL) AND (inserted_scrape_run_count IS NULL) AND (inserted_observation_count IS NULL) AND (total_station_count IS NULL) AND (total_scrape_run_count IS NULL) AND (total_observation_count IS NULL)) OR (((status)::text = 'SUCCESS'::text) AND (finished_at IS NOT NULL) AND (inserted_station_count IS NOT NULL) AND (inserted_scrape_run_count IS NOT NULL) AND (inserted_observation_count IS NOT NULL) AND (total_station_count IS NOT NULL) AND (total_scrape_run_count IS NOT NULL) AND (total_observation_count IS NOT NULL)))),
    CONSTRAINT ck_etl_batch_status CHECK (((status)::text = ANY ((ARRAY['RUNNING'::character varying, 'SUCCESS'::character varying])::text[]))),
    CONSTRAINT ck_etl_batch_time_order CHECK (((finished_at IS NULL) OR (finished_at >= started_at)))
);


--
-- Name: TABLE etl_batch; Type: COMMENT; Schema: ndbc_dw; Owner: -
--

COMMENT ON TABLE ndbc_dw.etl_batch IS 'Audit setiap refresh data warehouse. Selisih jumlah sebelum dan sesudah load digunakan sebagai bukti bahwa proses incremental bersifat idempotent.';


--
-- Name: etl_batch_etl_batch_id_seq; Type: SEQUENCE; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ndbc_dw.etl_batch ALTER COLUMN etl_batch_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ndbc_dw.etl_batch_etl_batch_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: fact_observation; Type: TABLE; Schema: ndbc_dw; Owner: -
--

CREATE TABLE ndbc_dw.fact_observation (
    observation_fact_key bigint NOT NULL,
    station_key bigint NOT NULL,
    date_key integer NOT NULL,
    time_key integer NOT NULL,
    first_seen_scrape_run_key bigint NOT NULL,
    observed_at_utc timestamp with time zone NOT NULL,
    wind_direction_degree smallint,
    wind_speed_meter_per_second double precision,
    wind_gust_meter_per_second double precision,
    wave_height_meter double precision,
    dominant_wave_period_second double precision,
    average_wave_period_second double precision,
    mean_wave_direction_degree smallint,
    sea_surface_temperature_celsius double precision,
    measurement_count smallint NOT NULL,
    has_wind_measurement boolean NOT NULL,
    has_wave_measurement boolean NOT NULL,
    has_temperature_measurement boolean NOT NULL,
    source_row_number integer NOT NULL,
    source_url text NOT NULL,
    source_extracted_at timestamp with time zone NOT NULL,
    source_loaded_at timestamp with time zone NOT NULL,
    dw_loaded_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_fact_observation_average_period CHECK (((average_wave_period_second IS NULL) OR (average_wave_period_second >= (0)::double precision))),
    CONSTRAINT ck_fact_observation_dominant_period CHECK (((dominant_wave_period_second IS NULL) OR (dominant_wave_period_second >= (0)::double precision))),
    CONSTRAINT ck_fact_observation_measurement_count CHECK (((measurement_count >= 1) AND (measurement_count <= 8))),
    CONSTRAINT ck_fact_observation_source_row CHECK ((source_row_number > 0)),
    CONSTRAINT ck_fact_observation_source_time CHECK ((observed_at_utc <= source_extracted_at)),
    CONSTRAINT ck_fact_observation_temperature CHECK (((sea_surface_temperature_celsius IS NULL) OR ((sea_surface_temperature_celsius >= ('-10'::integer)::double precision) AND (sea_surface_temperature_celsius <= (60)::double precision)))),
    CONSTRAINT ck_fact_observation_wave_direction CHECK (((mean_wave_direction_degree IS NULL) OR ((mean_wave_direction_degree >= 0) AND (mean_wave_direction_degree <= 360)))),
    CONSTRAINT ck_fact_observation_wave_height CHECK (((wave_height_meter IS NULL) OR (wave_height_meter >= (0)::double precision))),
    CONSTRAINT ck_fact_observation_wind_direction CHECK (((wind_direction_degree IS NULL) OR ((wind_direction_degree >= 0) AND (wind_direction_degree <= 360)))),
    CONSTRAINT ck_fact_observation_wind_gust CHECK (((wind_gust_meter_per_second IS NULL) OR (wind_gust_meter_per_second >= (0)::double precision))),
    CONSTRAINT ck_fact_observation_wind_speed CHECK (((wind_speed_meter_per_second IS NULL) OR (wind_speed_meter_per_second >= (0)::double precision)))
);


--
-- Name: TABLE fact_observation; Type: COMMENT; Schema: ndbc_dw; Owner: -
--

COMMENT ON TABLE ndbc_dw.fact_observation IS 'Fact table utama pada grain satu observasi untuk satu stasiun pada satu timestamp UTC. Nilai arah bersifat non-additive; kecepatan, gelombang, periode, dan suhu dianalisis menggunakan AVG, MIN, atau MAX.';


--
-- Name: fact_observation_observation_fact_key_seq; Type: SEQUENCE; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ndbc_dw.fact_observation ALTER COLUMN observation_fact_key ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ndbc_dw.fact_observation_observation_fact_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: fact_scrape_run; Type: TABLE; Schema: ndbc_dw; Owner: -
--

CREATE TABLE ndbc_dw.fact_scrape_run (
    scrape_run_fact_key bigint NOT NULL,
    scrape_run_key bigint NOT NULL,
    started_date_key integer NOT NULL,
    started_time_key integer NOT NULL,
    finished_date_key integer NOT NULL,
    finished_time_key integer NOT NULL,
    duration_second numeric(18,3) NOT NULL,
    target_station_count integer NOT NULL,
    source_candidate_count integer NOT NULL,
    processed_candidate_count integer NOT NULL,
    successful_station_count integer NOT NULL,
    skipped_non_buoy_count integer NOT NULL,
    skipped_no_data_count integer NOT NULL,
    failed_attempt_count integer NOT NULL,
    source_observation_count integer NOT NULL,
    duplicate_observation_count integer NOT NULL,
    dw_loaded_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_fact_scrape_run_counts_nonnegative CHECK (((target_station_count >= 0) AND (source_candidate_count >= 0) AND (processed_candidate_count >= 0) AND (successful_station_count >= 0) AND (skipped_non_buoy_count >= 0) AND (skipped_no_data_count >= 0) AND (failed_attempt_count >= 0) AND (source_observation_count >= 0) AND (duplicate_observation_count >= 0))),
    CONSTRAINT ck_fact_scrape_run_duration CHECK ((duration_second >= (0)::numeric))
);


--
-- Name: TABLE fact_scrape_run; Type: COMMENT; Schema: ndbc_dw; Owner: -
--

COMMENT ON TABLE ndbc_dw.fact_scrape_run IS 'Fact table pada grain satu baris per batch scraping. Berisi ukuran jumlah kandidat, stasiun, observasi, error, dan durasi proses.';


--
-- Name: fact_scrape_run_scrape_run_fact_key_seq; Type: SEQUENCE; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ndbc_dw.fact_scrape_run ALTER COLUMN scrape_run_fact_key ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ndbc_dw.fact_scrape_run_scrape_run_fact_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: v_daily_station_weather; Type: VIEW; Schema: ndbc_dw; Owner: -
--

CREATE VIEW ndbc_dw.v_daily_station_weather AS
 SELECT d.full_date,
    s.station_id,
    s.station_name,
    s.location,
    s.latitude,
    s.longitude,
    count(*) AS observation_count,
    count(f.wind_speed_meter_per_second) AS wind_speed_observation_count,
    avg(f.wind_speed_meter_per_second) AS average_wind_speed_meter_per_second,
    max(f.wind_speed_meter_per_second) AS maximum_wind_speed_meter_per_second,
    max(f.wind_gust_meter_per_second) AS maximum_wind_gust_meter_per_second,
    avg(f.wave_height_meter) AS average_wave_height_meter,
    max(f.wave_height_meter) AS maximum_wave_height_meter,
    avg(f.sea_surface_temperature_celsius) AS average_sea_surface_temperature_celsius
   FROM ((ndbc_dw.fact_observation f
     JOIN ndbc_dw.dim_date d ON ((d.date_key = f.date_key)))
     JOIN ndbc_dw.dim_station s ON ((s.station_key = f.station_key)))
  GROUP BY d.full_date, s.station_id, s.station_name, s.location, s.latitude, s.longitude;


--
-- Name: VIEW v_daily_station_weather; Type: COMMENT; Schema: ndbc_dw; Owner: -
--

COMMENT ON VIEW ndbc_dw.v_daily_station_weather IS 'Ringkasan harian per stasiun untuk analisis tren angin, gelombang, dan suhu.';


--
-- Name: v_scrape_run_quality; Type: VIEW; Schema: ndbc_dw; Owner: -
--

CREATE VIEW ndbc_dw.v_scrape_run_quality AS
 SELECT r.scrape_run_id,
    r.started_at,
    r.finished_at,
    f.duration_second,
    f.source_candidate_count,
    f.processed_candidate_count,
    f.successful_station_count,
    f.skipped_non_buoy_count,
    f.skipped_no_data_count,
    f.failed_attempt_count,
    f.source_observation_count,
    f.duplicate_observation_count,
        CASE
            WHEN (f.processed_candidate_count = 0) THEN (0)::numeric
            ELSE round(((100.0 * (f.successful_station_count)::numeric) / (f.processed_candidate_count)::numeric), 2)
        END AS station_success_rate_percent
   FROM (ndbc_dw.fact_scrape_run f
     JOIN ndbc_dw.dim_scrape_run r ON ((r.scrape_run_key = f.scrape_run_key)));


--
-- Name: VIEW v_scrape_run_quality; Type: COMMENT; Schema: ndbc_dw; Owner: -
--

COMMENT ON VIEW ndbc_dw.v_scrape_run_quality IS 'Ringkasan kualitas dan produktivitas setiap batch scraping.';


--
-- PostgreSQL database dump complete
--

\unrestrict zzzaF8gIfn0WT3drWA5QRkFOsNj30yS0aNyIqoMFN1wtg6B3p0kpYzE961dwk19

