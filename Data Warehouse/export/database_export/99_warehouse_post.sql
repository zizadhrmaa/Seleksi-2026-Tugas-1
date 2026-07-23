--
-- PostgreSQL database dump
--

\restrict f9IemIHD9dHJAdcgPRD4g30ZebePzAsSLWvvk9MDEorhr4OkQ8WUcRyDrzDcLds

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

SET default_tablespace = '';

--
-- Name: dim_date pk_dim_date; Type: CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.dim_date
    ADD CONSTRAINT pk_dim_date PRIMARY KEY (date_key);


--
-- Name: dim_scrape_run pk_dim_scrape_run; Type: CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.dim_scrape_run
    ADD CONSTRAINT pk_dim_scrape_run PRIMARY KEY (scrape_run_key);


--
-- Name: dim_station pk_dim_station; Type: CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.dim_station
    ADD CONSTRAINT pk_dim_station PRIMARY KEY (station_key);


--
-- Name: dim_time pk_dim_time; Type: CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.dim_time
    ADD CONSTRAINT pk_dim_time PRIMARY KEY (time_key);


--
-- Name: etl_batch pk_etl_batch; Type: CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.etl_batch
    ADD CONSTRAINT pk_etl_batch PRIMARY KEY (etl_batch_id);


--
-- Name: fact_observation pk_fact_observation; Type: CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.fact_observation
    ADD CONSTRAINT pk_fact_observation PRIMARY KEY (observation_fact_key);


--
-- Name: fact_scrape_run pk_fact_scrape_run; Type: CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.fact_scrape_run
    ADD CONSTRAINT pk_fact_scrape_run PRIMARY KEY (scrape_run_fact_key);


--
-- Name: dim_date uq_dim_date_full_date; Type: CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.dim_date
    ADD CONSTRAINT uq_dim_date_full_date UNIQUE (full_date);


--
-- Name: dim_scrape_run uq_dim_scrape_run_id; Type: CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.dim_scrape_run
    ADD CONSTRAINT uq_dim_scrape_run_id UNIQUE (scrape_run_id);


--
-- Name: dim_station uq_dim_station_station_id; Type: CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.dim_station
    ADD CONSTRAINT uq_dim_station_station_id UNIQUE (station_id);


--
-- Name: dim_time uq_dim_time_full_time; Type: CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.dim_time
    ADD CONSTRAINT uq_dim_time_full_time UNIQUE (full_time);


--
-- Name: fact_observation uq_fact_observation_grain; Type: CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.fact_observation
    ADD CONSTRAINT uq_fact_observation_grain UNIQUE (station_key, observed_at_utc);


--
-- Name: fact_scrape_run uq_fact_scrape_run_run; Type: CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.fact_scrape_run
    ADD CONSTRAINT uq_fact_scrape_run_run UNIQUE (scrape_run_key);


--
-- Name: idx_fact_observation_date_station; Type: INDEX; Schema: ndbc_dw; Owner: -
--

CREATE INDEX idx_fact_observation_date_station ON ndbc_dw.fact_observation USING btree (date_key, station_key);


--
-- Name: idx_fact_observation_run; Type: INDEX; Schema: ndbc_dw; Owner: -
--

CREATE INDEX idx_fact_observation_run ON ndbc_dw.fact_observation USING btree (first_seen_scrape_run_key);


--
-- Name: idx_fact_observation_station_date; Type: INDEX; Schema: ndbc_dw; Owner: -
--

CREATE INDEX idx_fact_observation_station_date ON ndbc_dw.fact_observation USING btree (station_key, date_key);


--
-- Name: idx_fact_scrape_run_started_date; Type: INDEX; Schema: ndbc_dw; Owner: -
--

CREATE INDEX idx_fact_scrape_run_started_date ON ndbc_dw.fact_scrape_run USING btree (started_date_key);


--
-- Name: dim_scrape_run trg_dim_scrape_run_set_dw_updated_at; Type: TRIGGER; Schema: ndbc_dw; Owner: -
--

CREATE TRIGGER trg_dim_scrape_run_set_dw_updated_at BEFORE UPDATE ON ndbc_dw.dim_scrape_run FOR EACH ROW EXECUTE FUNCTION ndbc_dw.set_dw_updated_at();


--
-- Name: dim_station trg_dim_station_set_dw_updated_at; Type: TRIGGER; Schema: ndbc_dw; Owner: -
--

CREATE TRIGGER trg_dim_station_set_dw_updated_at BEFORE UPDATE ON ndbc_dw.dim_station FOR EACH ROW EXECUTE FUNCTION ndbc_dw.set_dw_updated_at();


--
-- Name: fact_observation fk_fact_observation_date; Type: FK CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.fact_observation
    ADD CONSTRAINT fk_fact_observation_date FOREIGN KEY (date_key) REFERENCES ndbc_dw.dim_date(date_key) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fact_observation fk_fact_observation_run; Type: FK CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.fact_observation
    ADD CONSTRAINT fk_fact_observation_run FOREIGN KEY (first_seen_scrape_run_key) REFERENCES ndbc_dw.dim_scrape_run(scrape_run_key) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fact_observation fk_fact_observation_station; Type: FK CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.fact_observation
    ADD CONSTRAINT fk_fact_observation_station FOREIGN KEY (station_key) REFERENCES ndbc_dw.dim_station(station_key) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fact_observation fk_fact_observation_time; Type: FK CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.fact_observation
    ADD CONSTRAINT fk_fact_observation_time FOREIGN KEY (time_key) REFERENCES ndbc_dw.dim_time(time_key) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fact_scrape_run fk_fact_scrape_run_finished_date; Type: FK CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.fact_scrape_run
    ADD CONSTRAINT fk_fact_scrape_run_finished_date FOREIGN KEY (finished_date_key) REFERENCES ndbc_dw.dim_date(date_key) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fact_scrape_run fk_fact_scrape_run_finished_time; Type: FK CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.fact_scrape_run
    ADD CONSTRAINT fk_fact_scrape_run_finished_time FOREIGN KEY (finished_time_key) REFERENCES ndbc_dw.dim_time(time_key) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fact_scrape_run fk_fact_scrape_run_run; Type: FK CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.fact_scrape_run
    ADD CONSTRAINT fk_fact_scrape_run_run FOREIGN KEY (scrape_run_key) REFERENCES ndbc_dw.dim_scrape_run(scrape_run_key) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fact_scrape_run fk_fact_scrape_run_started_date; Type: FK CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.fact_scrape_run
    ADD CONSTRAINT fk_fact_scrape_run_started_date FOREIGN KEY (started_date_key) REFERENCES ndbc_dw.dim_date(date_key) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: fact_scrape_run fk_fact_scrape_run_started_time; Type: FK CONSTRAINT; Schema: ndbc_dw; Owner: -
--

ALTER TABLE ONLY ndbc_dw.fact_scrape_run
    ADD CONSTRAINT fk_fact_scrape_run_started_time FOREIGN KEY (started_time_key) REFERENCES ndbc_dw.dim_time(time_key) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

\unrestrict f9IemIHD9dHJAdcgPRD4g30ZebePzAsSLWvvk9MDEorhr4OkQ8WUcRyDrzDcLds

