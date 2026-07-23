\set ON_ERROR_STOP on
\pset pager off
\timing on

BEGIN ISOLATION LEVEL REPEATABLE READ;

DO $$
BEGIN
    IF to_regprocedure('ndbc_dw.refresh_warehouse()') IS NULL THEN
        RAISE EXCEPTION
            'Fungsi ndbc_dw.refresh_warehouse() belum tersedia. Jalankan 01 dan 02 terlebih dahulu.';
    END IF;
END
$$;

CREATE TEMP TABLE idempotency_result (
    run_number smallint NOT NULL,
    etl_batch_id bigint NOT NULL,
    source_station_count bigint NOT NULL,
    source_scrape_run_count bigint NOT NULL,
    source_observation_count bigint NOT NULL,
    inserted_station_count bigint NOT NULL,
    inserted_scrape_run_count bigint NOT NULL,
    inserted_observation_count bigint NOT NULL,
    total_station_count bigint NOT NULL,
    total_scrape_run_count bigint NOT NULL,
    total_observation_count bigint NOT NULL
) ON COMMIT PRESERVE ROWS;

INSERT INTO idempotency_result
SELECT 1, result.*
FROM ndbc_dw.refresh_warehouse() AS result;

INSERT INTO idempotency_result
SELECT 2, result.*
FROM ndbc_dw.refresh_warehouse() AS result;

\echo ''
\echo '================ HASIL UJI IDEMPOTENSI ==================='
SELECT *
FROM idempotency_result
ORDER BY run_number;

DO $$
DECLARE
    v_second_inserted_station bigint;
    v_second_inserted_scrape_run bigint;
    v_second_inserted_observation bigint;
    v_total_changed boolean;
BEGIN
    SELECT
        inserted_station_count,
        inserted_scrape_run_count,
        inserted_observation_count
    INTO STRICT
        v_second_inserted_station,
        v_second_inserted_scrape_run,
        v_second_inserted_observation
    FROM idempotency_result
    WHERE run_number = 2;

    SELECT EXISTS (
        SELECT 1
        FROM idempotency_result AS first_run
        JOIN idempotency_result AS second_run
            ON first_run.run_number = 1
           AND second_run.run_number = 2
        WHERE first_run.total_station_count IS DISTINCT FROM second_run.total_station_count
           OR first_run.total_scrape_run_count IS DISTINCT FROM second_run.total_scrape_run_count
           OR first_run.total_observation_count IS DISTINCT FROM second_run.total_observation_count
    ) INTO v_total_changed;

    IF v_second_inserted_station <> 0
        OR v_second_inserted_scrape_run <> 0
        OR v_second_inserted_observation <> 0 THEN
        RAISE EXCEPTION
            'Uji idempotensi gagal. Eksekusi kedua masih menambah station=%, scrape_run=%, observation=%',
            v_second_inserted_station,
            v_second_inserted_scrape_run,
            v_second_inserted_observation;
    END IF;

    IF v_total_changed THEN
        RAISE EXCEPTION
            'Uji idempotensi gagal. Total baris berubah antara eksekusi pertama dan kedua.';
    END IF;
END
$$;

COMMIT;

\echo ''
\echo 'Uji idempotensi PASS: eksekusi kedua tidak menambah grain baru.'
