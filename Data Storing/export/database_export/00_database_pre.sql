--
-- PostgreSQL database dump
--

\restrict L8ft73GpqjCi7qbo33KEI87exUtxhA0gHVX2CFTibGZoyESydRdISPW2fWYTyon

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
-- Name: ndbc; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA ndbc;


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: ndbc; Owner: -
--

CREATE FUNCTION ndbc.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: validate_station_extraction_time(); Type: FUNCTION; Schema: ndbc; Owner: -
--

CREATE FUNCTION ndbc.validate_station_extraction_time() RETURNS trigger
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


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: data_provider; Type: TABLE; Schema: ndbc; Owner: -
--

CREATE TABLE ndbc.data_provider (
    provider_id smallint NOT NULL,
    provider_name character varying(120) NOT NULL,
    base_url text NOT NULL,
    CONSTRAINT ck_data_provider_base_url_https CHECK ((base_url ~~ 'https://%'::text)),
    CONSTRAINT ck_data_provider_name_not_blank CHECK ((length(btrim((provider_name)::text)) > 0))
);


--
-- Name: data_provider_provider_id_seq; Type: SEQUENCE; Schema: ndbc; Owner: -
--

ALTER TABLE ndbc.data_provider ALTER COLUMN provider_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ndbc.data_provider_provider_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: observation; Type: TABLE; Schema: ndbc; Owner: -
--

CREATE TABLE ndbc.observation (
    station_id character varying(10) NOT NULL,
    observed_at_utc timestamp with time zone NOT NULL,
    first_seen_run_id character varying(64) NOT NULL,
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
    extracted_at timestamp with time zone NOT NULL,
    loaded_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_observation_average_period CHECK (((average_wave_period_second IS NULL) OR (average_wave_period_second >= (0)::double precision))),
    CONSTRAINT ck_observation_dominant_period CHECK (((dominant_wave_period_second IS NULL) OR (dominant_wave_period_second >= (0)::double precision))),
    CONSTRAINT ck_observation_has_measurement CHECK (((wind_direction_degree IS NOT NULL) OR (wind_speed_meter_per_second IS NOT NULL) OR (wind_gust_meter_per_second IS NOT NULL) OR (wave_height_meter IS NOT NULL) OR (dominant_wave_period_second IS NOT NULL) OR (average_wave_period_second IS NOT NULL) OR (mean_wave_direction_degree IS NOT NULL) OR (sea_surface_temperature_celsius IS NOT NULL))),
    CONSTRAINT ck_observation_mean_wave_direction CHECK (((mean_wave_direction_degree IS NULL) OR ((mean_wave_direction_degree >= 0) AND (mean_wave_direction_degree <= 360)))),
    CONSTRAINT ck_observation_sea_temperature CHECK (((sea_surface_temperature_celsius IS NULL) OR ((sea_surface_temperature_celsius >= ('-10'::integer)::double precision) AND (sea_surface_temperature_celsius <= (60)::double precision)))),
    CONSTRAINT ck_observation_source_row_positive CHECK ((source_row_number > 0)),
    CONSTRAINT ck_observation_source_url_https CHECK ((source_url ~~ 'https://%'::text)),
    CONSTRAINT ck_observation_time_not_after_extraction CHECK ((observed_at_utc <= extracted_at)),
    CONSTRAINT ck_observation_wave_height CHECK (((wave_height_meter IS NULL) OR (wave_height_meter >= (0)::double precision))),
    CONSTRAINT ck_observation_wind_direction CHECK (((wind_direction_degree IS NULL) OR ((wind_direction_degree >= 0) AND (wind_direction_degree <= 360)))),
    CONSTRAINT ck_observation_wind_gust CHECK (((wind_gust_meter_per_second IS NULL) OR (wind_gust_meter_per_second >= (0)::double precision))),
    CONSTRAINT ck_observation_wind_speed CHECK (((wind_speed_meter_per_second IS NULL) OR (wind_speed_meter_per_second >= (0)::double precision)))
);


--
-- Name: scrape_run; Type: TABLE; Schema: ndbc; Owner: -
--

CREATE TABLE ndbc.scrape_run (
    scrape_run_id character varying(64) NOT NULL,
    started_at timestamp with time zone NOT NULL,
    finished_at timestamp with time zone NOT NULL,
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
    loaded_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_scrape_run_counts_nonnegative CHECK (((source_candidate_count >= 0) AND (processed_candidate_count >= 0) AND (successful_station_count >= 0) AND (skipped_non_buoy_count >= 0) AND (skipped_no_data_count >= 0) AND (failed_attempt_count >= 0) AND (total_observation_count >= 0) AND (duplicate_observation_count >= 0))),
    CONSTRAINT ck_scrape_run_id_not_blank CHECK ((length(btrim((scrape_run_id)::text)) > 0)),
    CONSTRAINT ck_scrape_run_processed_breakdown CHECK ((processed_candidate_count = ((successful_station_count + skipped_non_buoy_count) + skipped_no_data_count))),
    CONSTRAINT ck_scrape_run_processed_not_exceed_source CHECK ((processed_candidate_count <= source_candidate_count)),
    CONSTRAINT ck_scrape_run_source_url_https CHECK ((station_list_source_url ~~ 'https://%'::text)),
    CONSTRAINT ck_scrape_run_target_met_consistent CHECK ((target_met = (successful_station_count >= target_station_count))),
    CONSTRAINT ck_scrape_run_target_positive CHECK ((target_station_count > 0)),
    CONSTRAINT ck_scrape_run_time_order CHECK ((finished_at >= started_at))
);


--
-- Name: station; Type: TABLE; Schema: ndbc; Owner: -
--

CREATE TABLE ndbc.station (
    station_id character varying(10) NOT NULL,
    provider_id smallint NOT NULL,
    station_name character varying(160) NOT NULL,
    location text,
    device_type character varying(120) NOT NULL,
    payload character varying(120) NOT NULL,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    water_depth_meter double precision NOT NULL,
    status character varying(40) NOT NULL,
    detail_url text NOT NULL,
    realtime_data_url text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_station_detail_url_https CHECK ((detail_url ~~ 'https://%'::text)),
    CONSTRAINT ck_station_device_type_not_blank CHECK ((length(btrim((device_type)::text)) > 0)),
    CONSTRAINT ck_station_id_format CHECK (((station_id)::text ~ '^[A-Z0-9]+$'::text)),
    CONSTRAINT ck_station_latitude CHECK (((latitude >= ('-90'::integer)::double precision) AND (latitude <= (90)::double precision))),
    CONSTRAINT ck_station_longitude CHECK (((longitude >= ('-180'::integer)::double precision) AND (longitude <= (180)::double precision))),
    CONSTRAINT ck_station_name_not_blank CHECK ((length(btrim((station_name)::text)) > 0)),
    CONSTRAINT ck_station_payload_not_blank CHECK ((length(btrim((payload)::text)) > 0)),
    CONSTRAINT ck_station_realtime_url_https CHECK ((realtime_data_url ~~ 'https://%'::text)),
    CONSTRAINT ck_station_status_not_blank CHECK ((length(btrim((status)::text)) > 0)),
    CONSTRAINT ck_station_water_depth CHECK ((water_depth_meter >= (0)::double precision))
);


--
-- Name: station_extraction; Type: TABLE; Schema: ndbc; Owner: -
--

CREATE TABLE ndbc.station_extraction (
    scrape_run_id character varying(64) NOT NULL,
    station_id character varying(10) NOT NULL,
    extracted_at timestamp with time zone NOT NULL
);


--
-- Name: station_observation_summary; Type: VIEW; Schema: ndbc; Owner: -
--

CREATE VIEW ndbc.station_observation_summary AS
 SELECT s.station_id,
    s.station_name,
    count(o.observed_at_utc) AS observation_count,
    min(o.observed_at_utc) AS first_observed_at_utc,
    max(o.observed_at_utc) AS last_observed_at_utc
   FROM (ndbc.station s
     LEFT JOIN ndbc.observation o ON (((o.station_id)::text = (s.station_id)::text)))
  GROUP BY s.station_id, s.station_name;


--
-- Data for Name: data_provider; Type: TABLE DATA; Schema: ndbc; Owner: -
--

COPY ndbc.data_provider (provider_id, provider_name, base_url) FROM stdin;
1	National Data Buoy Center	https://www.ndbc.noaa.gov
\.


--
-- Data for Name: observation; Type: TABLE DATA; Schema: ndbc; Owner: -
--

