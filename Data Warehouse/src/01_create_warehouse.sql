\set ON_ERROR_STOP on

BEGIN;

CREATE SCHEMA IF NOT EXISTS ndbc_dw;

COMMENT ON SCHEMA ndbc_dw IS
'Data warehouse meteorologi NDBC dengan constellation schema. Sumber data berasal dari schema operasional ndbc.';

CREATE TABLE IF NOT EXISTS ndbc_dw.dim_date (
    date_key integer NOT NULL,
    full_date date NOT NULL,
    day_of_month smallint NOT NULL,
    iso_day_of_week smallint NOT NULL,
    day_name varchar(12) NOT NULL,
    week_of_year smallint NOT NULL,
    month_number smallint NOT NULL,
    month_name varchar(12) NOT NULL,
    quarter_number smallint NOT NULL,
    year_number smallint NOT NULL,
    is_weekend boolean NOT NULL,
    CONSTRAINT pk_dim_date PRIMARY KEY (date_key),
    CONSTRAINT uq_dim_date_full_date UNIQUE (full_date),
    CONSTRAINT ck_dim_date_key_positive CHECK (date_key > 0),
    CONSTRAINT ck_dim_date_day CHECK (day_of_month BETWEEN 1 AND 31),
    CONSTRAINT ck_dim_date_iso_day CHECK (iso_day_of_week BETWEEN 1 AND 7),
    CONSTRAINT ck_dim_date_week CHECK (week_of_year BETWEEN 1 AND 53),
    CONSTRAINT ck_dim_date_month CHECK (month_number BETWEEN 1 AND 12),
    CONSTRAINT ck_dim_date_quarter CHECK (quarter_number BETWEEN 1 AND 4)
);

COMMENT ON TABLE ndbc_dw.dim_date IS
'Dimensi kalender. Satu baris merepresentasikan satu tanggal UTC.';

CREATE TABLE IF NOT EXISTS ndbc_dw.dim_time (
    time_key integer NOT NULL,
    full_time time without time zone NOT NULL,
    hour_number smallint NOT NULL,
    minute_number smallint NOT NULL,
    second_number smallint NOT NULL,
    minute_of_day smallint NOT NULL,
    time_bucket varchar(20) NOT NULL,
    CONSTRAINT pk_dim_time PRIMARY KEY (time_key),
    CONSTRAINT uq_dim_time_full_time UNIQUE (full_time),
    CONSTRAINT ck_dim_time_key_nonnegative CHECK (time_key >= 0),
    CONSTRAINT ck_dim_time_hour CHECK (hour_number BETWEEN 0 AND 23),
    CONSTRAINT ck_dim_time_minute CHECK (minute_number BETWEEN 0 AND 59),
    CONSTRAINT ck_dim_time_second CHECK (second_number BETWEEN 0 AND 59),
    CONSTRAINT ck_dim_time_minute_of_day CHECK (minute_of_day BETWEEN 0 AND 1439),
    CONSTRAINT ck_dim_time_bucket CHECK (
        time_bucket IN ('00:00-05:59', '06:00-11:59', '12:00-17:59', '18:00-23:59')
    )
);

COMMENT ON TABLE ndbc_dw.dim_time IS
'Dimensi waktu harian UTC dengan granularitas satu detik.';

CREATE TABLE IF NOT EXISTS ndbc_dw.dim_station (
    station_key bigint GENERATED ALWAYS AS IDENTITY,
    station_id varchar(10) NOT NULL,
    station_name varchar(160) NOT NULL,
    location text,
    device_type varchar(120) NOT NULL,
    payload varchar(120) NOT NULL,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    water_depth_meter double precision NOT NULL,
    station_status varchar(40) NOT NULL,
    provider_name varchar(120) NOT NULL,
    provider_base_url text NOT NULL,
    detail_url text NOT NULL,
    realtime_data_url text NOT NULL,
    source_created_at timestamptz NOT NULL,
    source_updated_at timestamptz NOT NULL,
    dw_created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dw_updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_dim_station PRIMARY KEY (station_key),
    CONSTRAINT uq_dim_station_station_id UNIQUE (station_id),
    CONSTRAINT ck_dim_station_id_not_blank CHECK (length(btrim(station_id)) > 0),
    CONSTRAINT ck_dim_station_latitude CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT ck_dim_station_longitude CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT ck_dim_station_water_depth CHECK (water_depth_meter >= 0)
);

COMMENT ON TABLE ndbc_dw.dim_station IS
'Dimensi stasiun terdenormalisasi. Atribut provider disimpan bersama metadata stasiun agar query analitik tidak membutuhkan snowflake join tambahan.';

CREATE TABLE IF NOT EXISTS ndbc_dw.dim_scrape_run (
    scrape_run_key bigint GENERATED ALWAYS AS IDENTITY,
    scrape_run_id varchar(64) NOT NULL,
    started_at timestamptz NOT NULL,
    finished_at timestamptz NOT NULL,
    target_met boolean NOT NULL,
    station_list_source_url text NOT NULL,
    source_output_directory text,
    source_loaded_at timestamptz NOT NULL,
    dw_created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dw_updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_dim_scrape_run PRIMARY KEY (scrape_run_key),
    CONSTRAINT uq_dim_scrape_run_id UNIQUE (scrape_run_id),
    CONSTRAINT ck_dim_scrape_run_time_order CHECK (finished_at >= started_at),
    CONSTRAINT ck_dim_scrape_run_id_not_blank CHECK (length(btrim(scrape_run_id)) > 0)
);

COMMENT ON TABLE ndbc_dw.dim_scrape_run IS
'Dimensi batch scraping. Menyediakan konteks proses ekstraksi untuk fact observation dan fact scrape run.';

CREATE TABLE IF NOT EXISTS ndbc_dw.fact_scrape_run (
    scrape_run_fact_key bigint GENERATED ALWAYS AS IDENTITY,
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
    dw_loaded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_fact_scrape_run PRIMARY KEY (scrape_run_fact_key),
    CONSTRAINT uq_fact_scrape_run_run UNIQUE (scrape_run_key),
    CONSTRAINT fk_fact_scrape_run_run FOREIGN KEY (scrape_run_key)
        REFERENCES ndbc_dw.dim_scrape_run (scrape_run_key)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_fact_scrape_run_started_date FOREIGN KEY (started_date_key)
        REFERENCES ndbc_dw.dim_date (date_key)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_fact_scrape_run_started_time FOREIGN KEY (started_time_key)
        REFERENCES ndbc_dw.dim_time (time_key)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_fact_scrape_run_finished_date FOREIGN KEY (finished_date_key)
        REFERENCES ndbc_dw.dim_date (date_key)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_fact_scrape_run_finished_time FOREIGN KEY (finished_time_key)
        REFERENCES ndbc_dw.dim_time (time_key)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_fact_scrape_run_duration CHECK (duration_second >= 0),
    CONSTRAINT ck_fact_scrape_run_counts_nonnegative CHECK (
        target_station_count >= 0
        AND source_candidate_count >= 0
        AND processed_candidate_count >= 0
        AND successful_station_count >= 0
        AND skipped_non_buoy_count >= 0
        AND skipped_no_data_count >= 0
        AND failed_attempt_count >= 0
        AND source_observation_count >= 0
        AND duplicate_observation_count >= 0
    )
);

COMMENT ON TABLE ndbc_dw.fact_scrape_run IS
'Fact table pada grain satu baris per batch scraping. Berisi ukuran jumlah kandidat, stasiun, observasi, error, dan durasi proses.';

CREATE TABLE IF NOT EXISTS ndbc_dw.fact_observation (
    observation_fact_key bigint GENERATED ALWAYS AS IDENTITY,
    station_key bigint NOT NULL,
    date_key integer NOT NULL,
    time_key integer NOT NULL,
    first_seen_scrape_run_key bigint NOT NULL,
    observed_at_utc timestamptz NOT NULL,
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
    source_extracted_at timestamptz NOT NULL,
    source_loaded_at timestamptz NOT NULL,
    dw_loaded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_fact_observation PRIMARY KEY (observation_fact_key),
    CONSTRAINT uq_fact_observation_grain UNIQUE (station_key, observed_at_utc),
    CONSTRAINT fk_fact_observation_station FOREIGN KEY (station_key)
        REFERENCES ndbc_dw.dim_station (station_key)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_fact_observation_date FOREIGN KEY (date_key)
        REFERENCES ndbc_dw.dim_date (date_key)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_fact_observation_time FOREIGN KEY (time_key)
        REFERENCES ndbc_dw.dim_time (time_key)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_fact_observation_run FOREIGN KEY (first_seen_scrape_run_key)
        REFERENCES ndbc_dw.dim_scrape_run (scrape_run_key)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_fact_observation_wind_direction CHECK (
        wind_direction_degree IS NULL OR wind_direction_degree BETWEEN 0 AND 360
    ),
    CONSTRAINT ck_fact_observation_wind_speed CHECK (
        wind_speed_meter_per_second IS NULL OR wind_speed_meter_per_second >= 0
    ),
    CONSTRAINT ck_fact_observation_wind_gust CHECK (
        wind_gust_meter_per_second IS NULL OR wind_gust_meter_per_second >= 0
    ),
    CONSTRAINT ck_fact_observation_wave_height CHECK (
        wave_height_meter IS NULL OR wave_height_meter >= 0
    ),
    CONSTRAINT ck_fact_observation_dominant_period CHECK (
        dominant_wave_period_second IS NULL OR dominant_wave_period_second >= 0
    ),
    CONSTRAINT ck_fact_observation_average_period CHECK (
        average_wave_period_second IS NULL OR average_wave_period_second >= 0
    ),
    CONSTRAINT ck_fact_observation_wave_direction CHECK (
        mean_wave_direction_degree IS NULL OR mean_wave_direction_degree BETWEEN 0 AND 360
    ),
    CONSTRAINT ck_fact_observation_temperature CHECK (
        sea_surface_temperature_celsius IS NULL
        OR sea_surface_temperature_celsius BETWEEN -10 AND 60
    ),
    CONSTRAINT ck_fact_observation_measurement_count CHECK (measurement_count BETWEEN 1 AND 8),
    CONSTRAINT ck_fact_observation_source_row CHECK (source_row_number > 0),
    CONSTRAINT ck_fact_observation_source_time CHECK (observed_at_utc <= source_extracted_at)
);

COMMENT ON TABLE ndbc_dw.fact_observation IS
'Fact table utama pada grain satu observasi untuk satu stasiun pada satu timestamp UTC. Nilai arah bersifat non-additive; kecepatan, gelombang, periode, dan suhu dianalisis menggunakan AVG, MIN, atau MAX.';

CREATE TABLE IF NOT EXISTS ndbc_dw.etl_batch (
    etl_batch_id bigint GENERATED ALWAYS AS IDENTITY,
    started_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finished_at timestamptz,
    status varchar(20) NOT NULL,
    source_station_count bigint NOT NULL,
    source_scrape_run_count bigint NOT NULL,
    source_observation_count bigint NOT NULL,
    inserted_station_count bigint,
    inserted_scrape_run_count bigint,
    inserted_observation_count bigint,
    total_station_count bigint,
    total_scrape_run_count bigint,
    total_observation_count bigint,
    CONSTRAINT pk_etl_batch PRIMARY KEY (etl_batch_id),
    CONSTRAINT ck_etl_batch_status CHECK (status IN ('RUNNING', 'SUCCESS')),
    CONSTRAINT ck_etl_batch_time_order CHECK (
        finished_at IS NULL OR finished_at >= started_at
    ),
    CONSTRAINT ck_etl_batch_source_counts CHECK (
        source_station_count >= 0
        AND source_scrape_run_count >= 0
        AND source_observation_count >= 0
    ),
    CONSTRAINT ck_etl_batch_result_counts CHECK (
        (inserted_station_count IS NULL OR inserted_station_count >= 0)
        AND (inserted_scrape_run_count IS NULL OR inserted_scrape_run_count >= 0)
        AND (inserted_observation_count IS NULL OR inserted_observation_count >= 0)
        AND (total_station_count IS NULL OR total_station_count >= 0)
        AND (total_scrape_run_count IS NULL OR total_scrape_run_count >= 0)
        AND (total_observation_count IS NULL OR total_observation_count >= 0)
    ),
    CONSTRAINT ck_etl_batch_state_consistency CHECK (
        (
            status = 'RUNNING'
            AND finished_at IS NULL
            AND inserted_station_count IS NULL
            AND inserted_scrape_run_count IS NULL
            AND inserted_observation_count IS NULL
            AND total_station_count IS NULL
            AND total_scrape_run_count IS NULL
            AND total_observation_count IS NULL
        )
        OR
        (
            status = 'SUCCESS'
            AND finished_at IS NOT NULL
            AND inserted_station_count IS NOT NULL
            AND inserted_scrape_run_count IS NOT NULL
            AND inserted_observation_count IS NOT NULL
            AND total_station_count IS NOT NULL
            AND total_scrape_run_count IS NOT NULL
            AND total_observation_count IS NOT NULL
        )
    )
);

COMMENT ON TABLE ndbc_dw.etl_batch IS
'Audit setiap refresh data warehouse. Selisih jumlah sebelum dan sesudah load digunakan sebagai bukti bahwa proses incremental bersifat idempotent.';

-- Re-apply audit constraints so an existing schema from an older revision also
-- receives the stricter consistency rules.
ALTER TABLE ndbc_dw.etl_batch
    DROP CONSTRAINT IF EXISTS ck_etl_batch_result_counts,
    DROP CONSTRAINT IF EXISTS ck_etl_batch_state_consistency;

ALTER TABLE ndbc_dw.etl_batch
    ADD CONSTRAINT ck_etl_batch_result_counts CHECK (
        (inserted_station_count IS NULL OR inserted_station_count >= 0)
        AND (inserted_scrape_run_count IS NULL OR inserted_scrape_run_count >= 0)
        AND (inserted_observation_count IS NULL OR inserted_observation_count >= 0)
        AND (total_station_count IS NULL OR total_station_count >= 0)
        AND (total_scrape_run_count IS NULL OR total_scrape_run_count >= 0)
        AND (total_observation_count IS NULL OR total_observation_count >= 0)
    ),
    ADD CONSTRAINT ck_etl_batch_state_consistency CHECK (
        (
            status = 'RUNNING'
            AND finished_at IS NULL
            AND inserted_station_count IS NULL
            AND inserted_scrape_run_count IS NULL
            AND inserted_observation_count IS NULL
            AND total_station_count IS NULL
            AND total_scrape_run_count IS NULL
            AND total_observation_count IS NULL
        )
        OR
        (
            status = 'SUCCESS'
            AND finished_at IS NOT NULL
            AND inserted_station_count IS NOT NULL
            AND inserted_scrape_run_count IS NOT NULL
            AND inserted_observation_count IS NOT NULL
            AND total_station_count IS NOT NULL
            AND total_scrape_run_count IS NOT NULL
            AND total_observation_count IS NOT NULL
        )
    );

CREATE INDEX IF NOT EXISTS idx_fact_observation_date_station
    ON ndbc_dw.fact_observation (date_key, station_key);

CREATE INDEX IF NOT EXISTS idx_fact_observation_station_date
    ON ndbc_dw.fact_observation (station_key, date_key);

CREATE INDEX IF NOT EXISTS idx_fact_observation_run
    ON ndbc_dw.fact_observation (first_seen_scrape_run_key);

CREATE INDEX IF NOT EXISTS idx_fact_scrape_run_started_date
    ON ndbc_dw.fact_scrape_run (started_date_key);

CREATE OR REPLACE FUNCTION ndbc_dw.set_dw_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.dw_updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_dim_station_set_dw_updated_at ON ndbc_dw.dim_station;
CREATE TRIGGER trg_dim_station_set_dw_updated_at
BEFORE UPDATE ON ndbc_dw.dim_station
FOR EACH ROW
EXECUTE FUNCTION ndbc_dw.set_dw_updated_at();

DROP TRIGGER IF EXISTS trg_dim_scrape_run_set_dw_updated_at ON ndbc_dw.dim_scrape_run;
CREATE TRIGGER trg_dim_scrape_run_set_dw_updated_at
BEFORE UPDATE ON ndbc_dw.dim_scrape_run
FOR EACH ROW
EXECUTE FUNCTION ndbc_dw.set_dw_updated_at();

CREATE OR REPLACE VIEW ndbc_dw.v_daily_station_weather AS
SELECT
    d.full_date,
    s.station_id,
    s.station_name,
    s.location,
    s.latitude,
    s.longitude,
    COUNT(*) AS observation_count,
    COUNT(f.wind_speed_meter_per_second) AS wind_speed_observation_count,
    AVG(f.wind_speed_meter_per_second) AS average_wind_speed_meter_per_second,
    MAX(f.wind_speed_meter_per_second) AS maximum_wind_speed_meter_per_second,
    MAX(f.wind_gust_meter_per_second) AS maximum_wind_gust_meter_per_second,
    AVG(f.wave_height_meter) AS average_wave_height_meter,
    MAX(f.wave_height_meter) AS maximum_wave_height_meter,
    AVG(f.sea_surface_temperature_celsius) AS average_sea_surface_temperature_celsius
FROM ndbc_dw.fact_observation AS f
JOIN ndbc_dw.dim_date AS d
    ON d.date_key = f.date_key
JOIN ndbc_dw.dim_station AS s
    ON s.station_key = f.station_key
GROUP BY
    d.full_date,
    s.station_id,
    s.station_name,
    s.location,
    s.latitude,
    s.longitude;

COMMENT ON VIEW ndbc_dw.v_daily_station_weather IS
'Ringkasan harian per stasiun untuk analisis tren angin, gelombang, dan suhu.';

CREATE OR REPLACE VIEW ndbc_dw.v_scrape_run_quality AS
SELECT
    r.scrape_run_id,
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
        WHEN f.processed_candidate_count = 0 THEN 0::numeric
        ELSE ROUND(
            100.0 * f.successful_station_count / f.processed_candidate_count,
            2
        )
    END AS station_success_rate_percent
FROM ndbc_dw.fact_scrape_run AS f
JOIN ndbc_dw.dim_scrape_run AS r
    ON r.scrape_run_key = f.scrape_run_key;

COMMENT ON VIEW ndbc_dw.v_scrape_run_quality IS
'Ringkasan kualitas dan produktivitas setiap batch scraping.';

COMMIT;
