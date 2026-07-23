\set ON_ERROR_STOP on
\pset pager off

DO $$
BEGIN
    IF to_regclass('ndbc_dw.fact_observation') IS NULL
        OR to_regclass('ndbc_dw.fact_scrape_run') IS NULL THEN
        RAISE EXCEPTION 'Schema ndbc_dw hasil restore tidak lengkap.';
    END IF;
END
$$;

CREATE TEMP TABLE restore_verification (
    metric_name text PRIMARY KEY,
    actual_value bigint NOT NULL,
    expected_value bigint NOT NULL
) ON COMMIT PRESERVE ROWS;

INSERT INTO restore_verification VALUES
(
    'duplicate_observation_grain_rows',
    (
        SELECT COUNT(*) - COUNT(DISTINCT (station_key, observed_at_utc))
        FROM ndbc_dw.fact_observation
    ),
    0
),
(
    'duplicate_scrape_run_grain_rows',
    (
        SELECT COUNT(*) - COUNT(DISTINCT scrape_run_key)
        FROM ndbc_dw.fact_scrape_run
    ),
    0
),
(
    'orphan_observation_dimension_rows',
    (
        SELECT COUNT(*)
        FROM ndbc_dw.fact_observation AS f
        LEFT JOIN ndbc_dw.dim_station AS s ON s.station_key = f.station_key
        LEFT JOIN ndbc_dw.dim_date AS d ON d.date_key = f.date_key
        LEFT JOIN ndbc_dw.dim_time AS t ON t.time_key = f.time_key
        LEFT JOIN ndbc_dw.dim_scrape_run AS r ON r.scrape_run_key = f.first_seen_scrape_run_key
        WHERE s.station_key IS NULL
           OR d.date_key IS NULL
           OR t.time_key IS NULL
           OR r.scrape_run_key IS NULL
    ),
    0
),
(
    'orphan_scrape_run_dimension_rows',
    (
        SELECT COUNT(*)
        FROM ndbc_dw.fact_scrape_run AS f
        LEFT JOIN ndbc_dw.dim_scrape_run AS r ON r.scrape_run_key = f.scrape_run_key
        LEFT JOIN ndbc_dw.dim_date AS sd ON sd.date_key = f.started_date_key
        LEFT JOIN ndbc_dw.dim_time AS st ON st.time_key = f.started_time_key
        LEFT JOIN ndbc_dw.dim_date AS fd ON fd.date_key = f.finished_date_key
        LEFT JOIN ndbc_dw.dim_time AS ft ON ft.time_key = f.finished_time_key
        WHERE r.scrape_run_key IS NULL
           OR sd.date_key IS NULL
           OR st.time_key IS NULL
           OR fd.date_key IS NULL
           OR ft.time_key IS NULL
    ),
    0
),
(
    'observation_date_time_key_mismatch_rows',
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
);

SELECT
    metric_name,
    actual_value,
    expected_value,
    CASE WHEN actual_value = expected_value THEN 'PASS' ELSE 'FAIL' END AS status
FROM restore_verification
ORDER BY metric_name;

DO $$
DECLARE
    v_failure_summary text;
BEGIN
    SELECT string_agg(
        format('%s: actual=%s expected=%s', metric_name, actual_value, expected_value),
        E'\n' ORDER BY metric_name
    )
    INTO v_failure_summary
    FROM restore_verification
    WHERE actual_value <> expected_value;

    IF v_failure_summary IS NOT NULL THEN
        RAISE EXCEPTION E'Verifikasi restore gagal:\n%', v_failure_summary;
    END IF;
END
$$;

\echo ''
\echo '================ JUMLAH DATA HASIL RESTORE ==============='
SELECT
    (SELECT COUNT(*) FROM ndbc_dw.dim_date) AS dim_date_count,
    (SELECT COUNT(*) FROM ndbc_dw.dim_time) AS dim_time_count,
    (SELECT COUNT(*) FROM ndbc_dw.dim_station) AS dim_station_count,
    (SELECT COUNT(*) FROM ndbc_dw.dim_scrape_run) AS dim_scrape_run_count,
    (SELECT COUNT(*) FROM ndbc_dw.fact_scrape_run) AS fact_scrape_run_count,
    (SELECT COUNT(*) FROM ndbc_dw.fact_observation) AS fact_observation_count,
    (SELECT COUNT(*) FROM ndbc_dw.etl_batch) AS etl_batch_count;
