SELECT pg_catalog.setval(
    pg_get_serial_sequence('ndbc_dw.dim_station', 'station_key')::regclass,
    COALESCE((SELECT MAX(station_key) FROM ndbc_dw.dim_station), 1),
    EXISTS (SELECT 1 FROM ndbc_dw.dim_station)
);

SELECT pg_catalog.setval(
    pg_get_serial_sequence('ndbc_dw.dim_scrape_run', 'scrape_run_key')::regclass,
    COALESCE((SELECT MAX(scrape_run_key) FROM ndbc_dw.dim_scrape_run), 1),
    EXISTS (SELECT 1 FROM ndbc_dw.dim_scrape_run)
);

SELECT pg_catalog.setval(
    pg_get_serial_sequence('ndbc_dw.fact_scrape_run', 'scrape_run_fact_key')::regclass,
    COALESCE((SELECT MAX(scrape_run_fact_key) FROM ndbc_dw.fact_scrape_run), 1),
    EXISTS (SELECT 1 FROM ndbc_dw.fact_scrape_run)
);

SELECT pg_catalog.setval(
    pg_get_serial_sequence('ndbc_dw.fact_observation', 'observation_fact_key')::regclass,
    COALESCE((SELECT MAX(observation_fact_key) FROM ndbc_dw.fact_observation), 1),
    EXISTS (SELECT 1 FROM ndbc_dw.fact_observation)
);

SELECT pg_catalog.setval(
    pg_get_serial_sequence('ndbc_dw.etl_batch', 'etl_batch_id')::regclass,
    COALESCE((SELECT MAX(etl_batch_id) FROM ndbc_dw.etl_batch), 1),
    EXISTS (SELECT 1 FROM ndbc_dw.etl_batch)
);