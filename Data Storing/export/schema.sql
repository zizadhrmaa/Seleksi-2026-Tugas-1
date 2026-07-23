BEGIN;

CREATE SCHEMA IF NOT EXISTS ndbc;

CREATE TABLE IF NOT EXISTS ndbc.data_provider (
    provider_id smallint GENERATED ALWAYS AS IDENTITY,
    provider_name varchar(120) NOT NULL,
    base_url text NOT NULL,
    CONSTRAINT pk_data_provider PRIMARY KEY (provider_id),
    CONSTRAINT uq_data_provider_name UNIQUE (provider_name),
    CONSTRAINT uq_data_provider_base_url UNIQUE (base_url),
    CONSTRAINT ck_data_provider_name_not_blank
        CHECK (length(btrim(provider_name)) > 0),
    CONSTRAINT ck_data_provider_base_url_https
        CHECK (base_url LIKE 'https://%')
);

CREATE TABLE IF NOT EXISTS ndbc.scrape_run (
    scrape_run_id varchar(64) NOT NULL,
    started_at timestamptz NOT NULL,
    finished_at timestamptz NOT NULL,
    target_station_count integer NOT NULL,
    target_met boolean NOT NULL,
    source_candidate_count integer NOT NULL,
    processed_candidate_count integer NOT NULL,
    successful_station_count integer NOT NULL,
    skipped_non_buoy_count integer NOT NULL,
    skipped_no_data_count integer NOT NULL,
    failed_attempt_count integer NOT NULL,
    total_observation_count integer NOT NULL,
    duplicate_observation_count integer NOT NULL,
    station_list_source_url text NOT NULL,
    source_output_directory text,
    loaded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_scrape_run PRIMARY KEY (scrape_run_id),
    CONSTRAINT ck_scrape_run_id_not_blank
        CHECK (length(btrim(scrape_run_id)) > 0),
    CONSTRAINT ck_scrape_run_time_order
        CHECK (finished_at >= started_at),
    CONSTRAINT ck_scrape_run_target_positive
        CHECK (target_station_count > 0),
    CONSTRAINT ck_scrape_run_counts_nonnegative
        CHECK (
            source_candidate_count >= 0
            AND processed_candidate_count >= 0
            AND successful_station_count >= 0
            AND skipped_non_buoy_count >= 0
            AND skipped_no_data_count >= 0
            AND failed_attempt_count >= 0
            AND total_observation_count >= 0
            AND duplicate_observation_count >= 0
        ),
    CONSTRAINT ck_scrape_run_processed_not_exceed_source
        CHECK (processed_candidate_count <= source_candidate_count),
    CONSTRAINT ck_scrape_run_processed_breakdown
        CHECK (
            processed_candidate_count = successful_station_count
                + skipped_non_buoy_count
                + skipped_no_data_count
        ),
    CONSTRAINT ck_scrape_run_target_met_consistent
        CHECK (target_met = (successful_station_count >= target_station_count)),
    CONSTRAINT ck_scrape_run_source_url_https
        CHECK (station_list_source_url LIKE 'https://%')
);

CREATE TABLE IF NOT EXISTS ndbc.station (
    station_id varchar(10) NOT NULL,
    provider_id smallint NOT NULL,
    station_name varchar(160) NOT NULL,
    location text,
    device_type varchar(120) NOT NULL,
    payload varchar(120) NOT NULL,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    water_depth_meter double precision NOT NULL,
    status varchar(40) NOT NULL,
    detail_url text NOT NULL,
    realtime_data_url text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_station PRIMARY KEY (station_id),
    CONSTRAINT fk_station_provider
        FOREIGN KEY (provider_id)
        REFERENCES ndbc.data_provider (provider_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT uq_station_detail_url UNIQUE (detail_url),
    CONSTRAINT uq_station_realtime_data_url UNIQUE (realtime_data_url),
    CONSTRAINT ck_station_id_format
        CHECK (station_id ~ '^[A-Z0-9]+$'),
    CONSTRAINT ck_station_name_not_blank
        CHECK (length(btrim(station_name)) > 0),
    CONSTRAINT ck_station_device_type_not_blank
        CHECK (length(btrim(device_type)) > 0),
    CONSTRAINT ck_station_payload_not_blank
        CHECK (length(btrim(payload)) > 0),
    CONSTRAINT ck_station_latitude
        CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT ck_station_longitude
        CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT ck_station_water_depth
        CHECK (water_depth_meter >= 0),
    CONSTRAINT ck_station_status_not_blank
        CHECK (length(btrim(status)) > 0),
    CONSTRAINT ck_station_detail_url_https
        CHECK (detail_url LIKE 'https://%'),
    CONSTRAINT ck_station_realtime_url_https
        CHECK (realtime_data_url LIKE 'https://%')
);

CREATE TABLE IF NOT EXISTS ndbc.station_extraction (
    scrape_run_id varchar(64) NOT NULL,
    station_id varchar(10) NOT NULL,
    extracted_at timestamptz NOT NULL,
    CONSTRAINT pk_station_extraction
        PRIMARY KEY (scrape_run_id, station_id),
    CONSTRAINT fk_station_extraction_run
        FOREIGN KEY (scrape_run_id)
        REFERENCES ndbc.scrape_run (scrape_run_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_station_extraction_station
        FOREIGN KEY (station_id)
        REFERENCES ndbc.station (station_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS ndbc.observation (
    station_id varchar(10) NOT NULL,
    observed_at_utc timestamptz NOT NULL,
    first_seen_run_id varchar(64) NOT NULL,
    wind_direction_degree smallint,
    wind_speed_meter_per_second double precision,
    wind_gust_meter_per_second double precision,
    wave_height_meter double precision,
    dominant_wave_period_second double precision,
    average_wave_period_second double precision,
    mean_wave_direction_degree smallint,
    sea_surface_temperature_celsius double precision,
    source_row_number integer NOT NULL,
    source_url text NOT NULL,
    extracted_at timestamptz NOT NULL,
    loaded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_observation
        PRIMARY KEY (station_id, observed_at_utc),
    CONSTRAINT fk_observation_station
        FOREIGN KEY (station_id)
        REFERENCES ndbc.station (station_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_observation_first_seen_run
        FOREIGN KEY (first_seen_run_id)
        REFERENCES ndbc.scrape_run (scrape_run_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_observation_first_seen_extraction
        FOREIGN KEY (first_seen_run_id, station_id)
        REFERENCES ndbc.station_extraction (scrape_run_id, station_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_observation_wind_direction
        CHECK (wind_direction_degree IS NULL OR wind_direction_degree BETWEEN 0 AND 360),
    CONSTRAINT ck_observation_wind_speed
        CHECK (wind_speed_meter_per_second IS NULL OR wind_speed_meter_per_second >= 0),
    CONSTRAINT ck_observation_wind_gust
        CHECK (wind_gust_meter_per_second IS NULL OR wind_gust_meter_per_second >= 0),
    CONSTRAINT ck_observation_wave_height
        CHECK (wave_height_meter IS NULL OR wave_height_meter >= 0),
    CONSTRAINT ck_observation_dominant_period
        CHECK (dominant_wave_period_second IS NULL OR dominant_wave_period_second >= 0),
    CONSTRAINT ck_observation_average_period
        CHECK (average_wave_period_second IS NULL OR average_wave_period_second >= 0),
    CONSTRAINT ck_observation_mean_wave_direction
        CHECK (mean_wave_direction_degree IS NULL OR mean_wave_direction_degree BETWEEN 0 AND 360),
    CONSTRAINT ck_observation_sea_temperature
        CHECK (
            sea_surface_temperature_celsius IS NULL
            OR sea_surface_temperature_celsius BETWEEN -10 AND 60
        ),
    CONSTRAINT ck_observation_has_measurement
        CHECK (
            wind_direction_degree IS NOT NULL
            OR wind_speed_meter_per_second IS NOT NULL
            OR wind_gust_meter_per_second IS NOT NULL
            OR wave_height_meter IS NOT NULL
            OR dominant_wave_period_second IS NOT NULL
            OR average_wave_period_second IS NOT NULL
            OR mean_wave_direction_degree IS NOT NULL
            OR sea_surface_temperature_celsius IS NOT NULL
        ),
    CONSTRAINT ck_observation_source_row_positive
        CHECK (source_row_number > 0),
    CONSTRAINT ck_observation_source_url_https
        CHECK (source_url LIKE 'https://%'),
    CONSTRAINT ck_observation_time_not_after_extraction
        CHECK (observed_at_utc <= extracted_at)
);

-- CREATE TABLE IF NOT EXISTS tidak menambahkan constraint baru pada tabel lama.
-- Blok berikut membuat migrasi schema tetap idempotent ketika loader dijalankan
-- terhadap database yang sudah pernah dibuat oleh versi sebelumnya.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'ndbc.observation'::regclass
          AND conname = 'fk_observation_first_seen_extraction'
    ) THEN
        ALTER TABLE ndbc.observation
        ADD CONSTRAINT fk_observation_first_seen_extraction
            FOREIGN KEY (first_seen_run_id, station_id)
            REFERENCES ndbc.station_extraction (scrape_run_id, station_id)
            ON UPDATE CASCADE
            ON DELETE RESTRICT;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION ndbc.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_station_set_updated_at ON ndbc.station;

CREATE TRIGGER trg_station_set_updated_at
BEFORE UPDATE ON ndbc.station
FOR EACH ROW
EXECUTE FUNCTION ndbc.set_updated_at();

CREATE OR REPLACE FUNCTION ndbc.validate_station_extraction_time()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    run_started_at timestamptz;
    run_finished_at timestamptz;
BEGIN
    SELECT started_at, finished_at
    INTO run_started_at, run_finished_at
    FROM ndbc.scrape_run
    WHERE scrape_run_id = NEW.scrape_run_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Scrape run % tidak ditemukan.', NEW.scrape_run_id;
    END IF;

    IF NEW.extracted_at < run_started_at OR NEW.extracted_at > run_finished_at THEN
        RAISE EXCEPTION
            'Waktu ekstraksi % berada di luar rentang scrape run % (% sampai %).',
            NEW.extracted_at,
            NEW.scrape_run_id,
            run_started_at,
            run_finished_at;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_station_extraction_validate_time
ON ndbc.station_extraction;

CREATE TRIGGER trg_station_extraction_validate_time
BEFORE INSERT OR UPDATE ON ndbc.station_extraction
FOR EACH ROW
EXECUTE FUNCTION ndbc.validate_station_extraction_time();

CREATE OR REPLACE VIEW ndbc.station_observation_summary AS
SELECT
    s.station_id,
    s.station_name,
    COUNT(o.observed_at_utc) AS observation_count,
    MIN(o.observed_at_utc) AS first_observed_at_utc,
    MAX(o.observed_at_utc) AS last_observed_at_utc
FROM ndbc.station AS s
LEFT JOIN ndbc.observation AS o
    ON o.station_id = s.station_id
GROUP BY s.station_id, s.station_name;

COMMIT;
