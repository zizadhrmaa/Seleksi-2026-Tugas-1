using NdbcDataLoader.Models;
using NdbcDataLoader.Utilities;
using Npgsql;
using NpgsqlTypes;

namespace NdbcDataLoader.Persistence;

internal sealed class PostgresDataLoader
{
    private const string NdbcBaseUrl = "https://www.ndbc.noaa.gov";

    private readonly JsonDataReader _jsonDataReader;

    public PostgresDataLoader(JsonDataReader jsonDataReader)
    {
        _jsonDataReader = jsonDataReader;
    }

    public async Task<LoadSummary> LoadAsync(
        NpgsqlDataSource dataSource,
        ScrapeRunReport report,
        ObservationManifest manifest,
        IReadOnlyList<StationData> stations,
        string dataDirectory,
        CancellationToken cancellationToken)
    {
        await using NpgsqlConnection connection = await dataSource.OpenConnectionAsync(
            cancellationToken);

        await using NpgsqlTransaction transaction = await connection.BeginTransactionAsync(
            cancellationToken);

        bool transactionCommitted = false;

        try
        {
            await UpsertScrapeRunAsync(
                connection,
                transaction,
                report,
                cancellationToken);

            await CreateStationImportTableAsync(
                connection,
                transaction,
                cancellationToken);

            CopyStations(connection, stations);

            await MergeStationsAsync(
                connection,
                transaction,
                cancellationToken);

            await CreateObservationImportTableAsync(
                connection,
                transaction,
                cancellationToken);

            int sourceObservationCount = await CopyObservationsAsync(
                connection,
                report,
                manifest,
                dataDirectory,
                cancellationToken);

            Console.WriteLine("Menggabungkan observasi ke tabel utama...");

            (int insertedObservationCount, int updatedObservationCount) =
                await ReadObservationMergePlanAsync(
                    connection,
                    transaction,
                    cancellationToken);

            int affectedObservationCount = await MergeObservationsAsync(
                connection,
                transaction,
                cancellationToken);

            int expectedAffectedCount = checked(
                insertedObservationCount + updatedObservationCount);

            if (affectedObservationCount != expectedAffectedCount)
            {
                throw new InvalidOperationException(
                    "Jumlah baris hasil merge observasi tidak sesuai rencana. " +
                    $"Diperkirakan: {expectedAffectedCount:N0}, " +
                    $"terpengaruh: {affectedObservationCount:N0}.");
            }

            int unchangedObservationCount = checked(
                sourceObservationCount
                - insertedObservationCount
                - updatedObservationCount);

            Console.WriteLine("Menyimpan transaksi database...");
            await transaction.CommitAsync(cancellationToken);
            transactionCommitted = true;

            await AnalyzeAsync(connection, cancellationToken);

            (long stationCount, long observationCount) = await ReadDatabaseCountsAsync(
                connection,
                cancellationToken);

            return new LoadSummary(
                report.ScrapeRunId,
                stations.Count,
                sourceObservationCount,
                insertedObservationCount,
                updatedObservationCount,
                unchangedObservationCount,
                stationCount,
                observationCount);
        }
        catch (Exception originalException)
        {
            if (!transactionCommitted)
            {
                try
                {
                    await transaction.RollbackAsync(CancellationToken.None);
                }
                catch (Exception rollbackException)
                {
                    throw new AggregateException(
                        "Proses loading gagal dan rollback transaksi juga gagal.",
                        originalException,
                        rollbackException);
                }
            }

            throw;
        }
    }

    private static async Task UpsertScrapeRunAsync(
        NpgsqlConnection connection,
        NpgsqlTransaction transaction,
        ScrapeRunReport report,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO ndbc.scrape_run (
                scrape_run_id,
                started_at,
                finished_at,
                target_station_count,
                target_met,
                source_candidate_count,
                processed_candidate_count,
                successful_station_count,
                skipped_non_buoy_count,
                skipped_no_data_count,
                failed_attempt_count,
                total_observation_count,
                duplicate_observation_count,
                station_list_source_url,
                source_output_directory
            )
            VALUES (
                @scrape_run_id,
                @started_at,
                @finished_at,
                @target_station_count,
                @target_met,
                @source_candidate_count,
                @processed_candidate_count,
                @successful_station_count,
                @skipped_non_buoy_count,
                @skipped_no_data_count,
                @failed_attempt_count,
                @total_observation_count,
                @duplicate_observation_count,
                @station_list_source_url,
                @source_output_directory
            )
            ON CONFLICT (scrape_run_id) DO UPDATE SET
                started_at = EXCLUDED.started_at,
                finished_at = EXCLUDED.finished_at,
                target_station_count = EXCLUDED.target_station_count,
                target_met = EXCLUDED.target_met,
                source_candidate_count = EXCLUDED.source_candidate_count,
                processed_candidate_count = EXCLUDED.processed_candidate_count,
                successful_station_count = EXCLUDED.successful_station_count,
                skipped_non_buoy_count = EXCLUDED.skipped_non_buoy_count,
                skipped_no_data_count = EXCLUDED.skipped_no_data_count,
                failed_attempt_count = EXCLUDED.failed_attempt_count,
                total_observation_count = EXCLUDED.total_observation_count,
                duplicate_observation_count = EXCLUDED.duplicate_observation_count,
                station_list_source_url = EXCLUDED.station_list_source_url,
                source_output_directory = EXCLUDED.source_output_directory;
            """;

        await using NpgsqlCommand command = new(sql, connection, transaction);
        command.Parameters.AddWithValue("scrape_run_id", report.ScrapeRunId);
        command.Parameters.AddWithValue("started_at", report.StartedAt);
        command.Parameters.AddWithValue("finished_at", report.FinishedAt);
        command.Parameters.AddWithValue("target_station_count", report.TargetStationCount);
        command.Parameters.AddWithValue("target_met", report.TargetMet);
        command.Parameters.AddWithValue("source_candidate_count", report.SourceCandidateCount);
        command.Parameters.AddWithValue("processed_candidate_count", report.ProcessedCandidateCount);
        command.Parameters.AddWithValue("successful_station_count", report.SuccessfulStationCount);
        command.Parameters.AddWithValue("skipped_non_buoy_count", report.SkippedNonBuoyCount);
        command.Parameters.AddWithValue("skipped_no_data_count", report.SkippedNoDataCount);
        command.Parameters.AddWithValue("failed_attempt_count", report.FailedAttemptCount);
        command.Parameters.AddWithValue("total_observation_count", report.TotalObservationCount);
        command.Parameters.AddWithValue("duplicate_observation_count", report.DuplicateObservationCount);
        command.Parameters.AddWithValue("station_list_source_url", report.StationListSourceUrl);
        command.Parameters.Add(
            "source_output_directory",
            NpgsqlDbType.Text).Value = report.OutputDirectory is null
                ? DBNull.Value
                : report.OutputDirectory;

        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task CreateStationImportTableAsync(
        NpgsqlConnection connection,
        NpgsqlTransaction transaction,
        CancellationToken cancellationToken)
    {
        const string sql = """
            CREATE TEMP TABLE station_import (
                scrape_run_id varchar(64) NOT NULL,
                station_id varchar(10) NOT NULL,
                station_name varchar(160) NOT NULL,
                location text,
                owner_name varchar(120) NOT NULL,
                provider_base_url text NOT NULL,
                device_type varchar(120) NOT NULL,
                payload varchar(120) NOT NULL,
                latitude double precision NOT NULL,
                longitude double precision NOT NULL,
                water_depth_meter double precision NOT NULL,
                status varchar(40) NOT NULL,
                detail_url text NOT NULL,
                realtime_data_url text NOT NULL,
                extracted_at timestamptz NOT NULL
            ) ON COMMIT DROP;
            """;

        await using NpgsqlCommand command = new(sql, connection, transaction);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static void CopyStations(
        NpgsqlConnection connection,
        IReadOnlyList<StationData> stations)
    {
        const string copySql = """
            COPY station_import (
                scrape_run_id,
                station_id,
                station_name,
                location,
                owner_name,
                provider_base_url,
                device_type,
                payload,
                latitude,
                longitude,
                water_depth_meter,
                status,
                detail_url,
                realtime_data_url,
                extracted_at
            ) FROM STDIN (FORMAT BINARY)
            """;

        using NpgsqlBinaryImporter importer = connection.BeginBinaryImport(copySql);
        importer.Timeout = Timeout.InfiniteTimeSpan;

        foreach (StationData station in stations)
        {
            importer.StartRow();
            importer.Write(station.ScrapeRunId, NpgsqlDbType.Varchar);
            importer.Write(station.StationId, NpgsqlDbType.Varchar);
            importer.Write(station.StationName, NpgsqlDbType.Varchar);
            WriteNullable(importer, station.Location, NpgsqlDbType.Text);
            importer.Write(station.Owner, NpgsqlDbType.Varchar);
            importer.Write(NdbcBaseUrl, NpgsqlDbType.Text);
            importer.Write(station.DeviceType, NpgsqlDbType.Varchar);
            importer.Write(station.Payload, NpgsqlDbType.Varchar);
            importer.Write(station.Latitude, NpgsqlDbType.Double);
            importer.Write(station.Longitude, NpgsqlDbType.Double);
            importer.Write(station.WaterDepthMeter, NpgsqlDbType.Double);
            importer.Write(station.Status, NpgsqlDbType.Varchar);
            importer.Write(station.DetailUrl, NpgsqlDbType.Text);
            importer.Write(station.RealtimeDataUrl, NpgsqlDbType.Text);
            importer.Write(station.ExtractedAt, NpgsqlDbType.TimestampTz);
        }

        importer.Complete();
    }

    private static async Task MergeStationsAsync(
        NpgsqlConnection connection,
        NpgsqlTransaction transaction,
        CancellationToken cancellationToken)
    {
        const string providerSql = """
            INSERT INTO ndbc.data_provider (provider_name, base_url)
            SELECT DISTINCT owner_name, provider_base_url
            FROM station_import
            ON CONFLICT (provider_name) DO UPDATE SET
                base_url = EXCLUDED.base_url
            WHERE data_provider.base_url IS DISTINCT FROM EXCLUDED.base_url;
            """;

        await using (NpgsqlCommand providerCommand = new(providerSql, connection, transaction))
        {
            await providerCommand.ExecuteNonQueryAsync(cancellationToken);
        }

        const string stationSql = """
            INSERT INTO ndbc.station (
                station_id,
                provider_id,
                station_name,
                location,
                device_type,
                payload,
                latitude,
                longitude,
                water_depth_meter,
                status,
                detail_url,
                realtime_data_url
            )
            SELECT
                source.station_id,
                provider.provider_id,
                source.station_name,
                source.location,
                source.device_type,
                source.payload,
                source.latitude,
                source.longitude,
                source.water_depth_meter,
                source.status,
                source.detail_url,
                source.realtime_data_url
            FROM station_import AS source
            INNER JOIN ndbc.data_provider AS provider
                ON provider.provider_name = source.owner_name
            ON CONFLICT (station_id) DO UPDATE SET
                provider_id = EXCLUDED.provider_id,
                station_name = EXCLUDED.station_name,
                location = EXCLUDED.location,
                device_type = EXCLUDED.device_type,
                payload = EXCLUDED.payload,
                latitude = EXCLUDED.latitude,
                longitude = EXCLUDED.longitude,
                water_depth_meter = EXCLUDED.water_depth_meter,
                status = EXCLUDED.status,
                detail_url = EXCLUDED.detail_url,
                realtime_data_url = EXCLUDED.realtime_data_url
            WHERE ROW(
                station.provider_id,
                station.station_name,
                station.location,
                station.device_type,
                station.payload,
                station.latitude,
                station.longitude,
                station.water_depth_meter,
                station.status,
                station.detail_url,
                station.realtime_data_url
            ) IS DISTINCT FROM ROW(
                EXCLUDED.provider_id,
                EXCLUDED.station_name,
                EXCLUDED.location,
                EXCLUDED.device_type,
                EXCLUDED.payload,
                EXCLUDED.latitude,
                EXCLUDED.longitude,
                EXCLUDED.water_depth_meter,
                EXCLUDED.status,
                EXCLUDED.detail_url,
                EXCLUDED.realtime_data_url
            );
            """;

        await using (NpgsqlCommand stationCommand = new(stationSql, connection, transaction))
        {
            await stationCommand.ExecuteNonQueryAsync(cancellationToken);
        }

        const string extractionSql = """
            INSERT INTO ndbc.station_extraction (
                scrape_run_id,
                station_id,
                extracted_at
            )
            SELECT
                scrape_run_id,
                station_id,
                extracted_at
            FROM station_import
            ON CONFLICT (scrape_run_id, station_id) DO UPDATE SET
                extracted_at = EXCLUDED.extracted_at
            WHERE station_extraction.extracted_at
                IS DISTINCT FROM EXCLUDED.extracted_at;
            """;

        await using NpgsqlCommand extractionCommand = new(
            extractionSql,
            connection,
            transaction);

        await extractionCommand.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task CreateObservationImportTableAsync(
        NpgsqlConnection connection,
        NpgsqlTransaction transaction,
        CancellationToken cancellationToken)
    {
        const string sql = """
            CREATE TEMP TABLE observation_import (
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
                extracted_at timestamptz NOT NULL
            ) ON COMMIT DROP;
            """;

        await using NpgsqlCommand command = new(sql, connection, transaction);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private async Task<int> CopyObservationsAsync(
        NpgsqlConnection connection,
        ScrapeRunReport report,
        ObservationManifest manifest,
        string dataDirectory,
        CancellationToken cancellationToken)
    {
        const string copySql = """
            COPY observation_import (
                station_id,
                observed_at_utc,
                first_seen_run_id,
                wind_direction_degree,
                wind_speed_meter_per_second,
                wind_gust_meter_per_second,
                wave_height_meter,
                dominant_wave_period_second,
                average_wave_period_second,
                mean_wave_direction_degree,
                sea_surface_temperature_celsius,
                source_row_number,
                source_url,
                extracted_at
            ) FROM STDIN (FORMAT BINARY)
            """;

        using NpgsqlBinaryImporter importer = connection.BeginBinaryImport(copySql);
        importer.Timeout = Timeout.InfiniteTimeSpan;
        int totalCount = 0;

        for (int fileIndex = 0; fileIndex < manifest.StationFiles.Count; fileIndex++)
        {
            StationObservationFile stationFile = manifest.StationFiles[fileIndex];
            string observationPath = Path.GetFullPath(
                Path.Combine(dataDirectory, stationFile.RelativePath));

            int fileCount = 0;

            await foreach (ObservationData observation in _jsonDataReader.StreamArrayAsync<ObservationData>(
                observationPath,
                cancellationToken))
            {
                if (!string.Equals(
                        observation.StationId,
                        stationFile.StationId,
                        StringComparison.OrdinalIgnoreCase))
                {
                    throw new InvalidDataException(
                        $"Station ID dalam {stationFile.RelativePath} tidak konsisten.");
                }

                if (!string.Equals(
                        observation.ScrapeRunId,
                        report.ScrapeRunId,
                        StringComparison.Ordinal))
                {
                    throw new InvalidDataException(
                        $"scrape_run_id dalam {stationFile.RelativePath} tidak sesuai report.");
                }

                if (observation.QualityFlags.Count > 0)
                {
                    throw new InvalidDataException(
                        $"quality_flags non-kosong ditemukan pada {stationFile.RelativePath}, " +
                        $"waktu {observation.ObservedAtUtc:O}. " +
                        "Schema saat ini sengaja tidak menyimpan quality_flags karena " +
                        "dataset tervalidasi tidak mengandung flag. Perluasan schema " +
                        "diperlukan sebelum data ber-flag dapat dimuat tanpa kehilangan informasi.");
                }

                if (!HasMeasurement(observation))
                {
                    throw new InvalidDataException(
                        $"Observasi tanpa pengukuran ditemukan pada {stationFile.RelativePath}, " +
                        $"waktu {observation.ObservedAtUtc:O}.");
                }

                importer.StartRow();
                importer.Write(observation.StationId, NpgsqlDbType.Varchar);
                importer.Write(observation.ObservedAtUtc, NpgsqlDbType.TimestampTz);
                importer.Write(observation.ScrapeRunId, NpgsqlDbType.Varchar);
                WriteNullable(importer, observation.WindDirectionDegree, NpgsqlDbType.Smallint);
                WriteNullable(importer, observation.WindSpeedMeterPerSecond, NpgsqlDbType.Double);
                WriteNullable(importer, observation.WindGustMeterPerSecond, NpgsqlDbType.Double);
                WriteNullable(importer, observation.WaveHeightMeter, NpgsqlDbType.Double);
                WriteNullable(importer, observation.DominantWavePeriodSecond, NpgsqlDbType.Double);
                WriteNullable(importer, observation.AverageWavePeriodSecond, NpgsqlDbType.Double);
                WriteNullable(importer, observation.MeanWaveDirectionDegree, NpgsqlDbType.Smallint);
                WriteNullable(importer, observation.SeaSurfaceTemperatureCelsius, NpgsqlDbType.Double);
                importer.Write(observation.SourceRowNumber, NpgsqlDbType.Integer);
                importer.Write(observation.SourceUrl, NpgsqlDbType.Text);
                importer.Write(observation.ExtractedAt, NpgsqlDbType.TimestampTz);

                fileCount++;
                totalCount++;

                if (totalCount % 10_000 == 0)
                {
                    cancellationToken.ThrowIfCancellationRequested();
                }
            }

            if (fileCount != stationFile.ObservationCount)
            {
                throw new InvalidDataException(
                    $"Jumlah observasi {stationFile.StationId} tidak sesuai manifest. " +
                    $"Manifest: {stationFile.ObservationCount}, terbaca: {fileCount}.");
            }

            Console.WriteLine(
                $"[{fileIndex + 1}/{manifest.StationFiles.Count}] " +
                $"{stationFile.StationId}: {fileCount:N0} observasi disiapkan.");
        }

        if (totalCount != manifest.TotalObservationCount)
        {
            throw new InvalidDataException(
                $"Total observasi tidak sesuai manifest. " +
                $"Manifest: {manifest.TotalObservationCount}, terbaca: {totalCount}.");
        }

        importer.Complete();
        return totalCount;
    }

    private static async Task<(int InsertedCount, int UpdatedCount)>
        ReadObservationMergePlanAsync(
            NpgsqlConnection connection,
            NpgsqlTransaction transaction,
            CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                COUNT(*) FILTER (
                    WHERE target.station_id IS NULL
                )::integer AS inserted_count,
                COUNT(*) FILTER (
                    WHERE target.station_id IS NOT NULL
                      AND ROW(
                          target.wind_direction_degree,
                          target.wind_speed_meter_per_second,
                          target.wind_gust_meter_per_second,
                          target.wave_height_meter,
                          target.dominant_wave_period_second,
                          target.average_wave_period_second,
                          target.mean_wave_direction_degree,
                          target.sea_surface_temperature_celsius
                      ) IS DISTINCT FROM ROW(
                          source.wind_direction_degree,
                          source.wind_speed_meter_per_second,
                          source.wind_gust_meter_per_second,
                          source.wave_height_meter,
                          source.dominant_wave_period_second,
                          source.average_wave_period_second,
                          source.mean_wave_direction_degree,
                          source.sea_surface_temperature_celsius
                      )
                )::integer AS updated_count
            FROM observation_import AS source
            LEFT JOIN ndbc.observation AS target
                ON target.station_id = source.station_id
               AND target.observed_at_utc = source.observed_at_utc;
            """;

        await using NpgsqlCommand command = new(sql, connection, transaction)
        {
            CommandTimeout = 0
        };

        await using NpgsqlDataReader reader = await command.ExecuteReaderAsync(
            cancellationToken);

        if (!await reader.ReadAsync(cancellationToken))
        {
            throw new InvalidOperationException(
                "Gagal membaca rencana merge observasi.");
        }

        return (reader.GetInt32(0), reader.GetInt32(1));
    }

    private static async Task<int> MergeObservationsAsync(
        NpgsqlConnection connection,
        NpgsqlTransaction transaction,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO ndbc.observation (
                station_id,
                observed_at_utc,
                first_seen_run_id,
                wind_direction_degree,
                wind_speed_meter_per_second,
                wind_gust_meter_per_second,
                wave_height_meter,
                dominant_wave_period_second,
                average_wave_period_second,
                mean_wave_direction_degree,
                sea_surface_temperature_celsius,
                source_row_number,
                source_url,
                extracted_at
            )
            SELECT
                station_id,
                observed_at_utc,
                first_seen_run_id,
                wind_direction_degree,
                wind_speed_meter_per_second,
                wind_gust_meter_per_second,
                wave_height_meter,
                dominant_wave_period_second,
                average_wave_period_second,
                mean_wave_direction_degree,
                sea_surface_temperature_celsius,
                source_row_number,
                source_url,
                extracted_at
            FROM observation_import
            ON CONFLICT (station_id, observed_at_utc) DO UPDATE SET
                wind_direction_degree = EXCLUDED.wind_direction_degree,
                wind_speed_meter_per_second = EXCLUDED.wind_speed_meter_per_second,
                wind_gust_meter_per_second = EXCLUDED.wind_gust_meter_per_second,
                wave_height_meter = EXCLUDED.wave_height_meter,
                dominant_wave_period_second = EXCLUDED.dominant_wave_period_second,
                average_wave_period_second = EXCLUDED.average_wave_period_second,
                mean_wave_direction_degree = EXCLUDED.mean_wave_direction_degree,
                sea_surface_temperature_celsius = EXCLUDED.sea_surface_temperature_celsius,
                source_row_number = EXCLUDED.source_row_number,
                source_url = EXCLUDED.source_url,
                extracted_at = EXCLUDED.extracted_at,
                loaded_at = CURRENT_TIMESTAMP
            WHERE ROW(
                observation.wind_direction_degree,
                observation.wind_speed_meter_per_second,
                observation.wind_gust_meter_per_second,
                observation.wave_height_meter,
                observation.dominant_wave_period_second,
                observation.average_wave_period_second,
                observation.mean_wave_direction_degree,
                observation.sea_surface_temperature_celsius
            ) IS DISTINCT FROM ROW(
                EXCLUDED.wind_direction_degree,
                EXCLUDED.wind_speed_meter_per_second,
                EXCLUDED.wind_gust_meter_per_second,
                EXCLUDED.wave_height_meter,
                EXCLUDED.dominant_wave_period_second,
                EXCLUDED.average_wave_period_second,
                EXCLUDED.mean_wave_direction_degree,
                EXCLUDED.sea_surface_temperature_celsius
            );
            """;

        await using NpgsqlCommand command = new(sql, connection, transaction)
        {
            CommandTimeout = 0
        };

        return await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task AnalyzeAsync(
        NpgsqlConnection connection,
        CancellationToken cancellationToken)
    {
        const string sql = """
            ANALYZE ndbc.data_provider;
            ANALYZE ndbc.scrape_run;
            ANALYZE ndbc.station;
            ANALYZE ndbc.station_extraction;
            ANALYZE ndbc.observation;
            """;

        await using NpgsqlCommand command = new(sql, connection)
        {
            CommandTimeout = 120
        };

        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task<(long StationCount, long ObservationCount)> ReadDatabaseCountsAsync(
        NpgsqlConnection connection,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                (SELECT COUNT(*) FROM ndbc.station) AS station_count,
                (SELECT COUNT(*) FROM ndbc.observation) AS observation_count;
            """;

        await using NpgsqlCommand command = new(sql, connection);
        await using NpgsqlDataReader reader = await command.ExecuteReaderAsync(
            cancellationToken);

        if (!await reader.ReadAsync(cancellationToken))
        {
            throw new InvalidOperationException("Gagal membaca jumlah data dari database.");
        }

        return (reader.GetInt64(0), reader.GetInt64(1));
    }

    private static bool HasMeasurement(ObservationData observation)
    {
        return observation.WindDirectionDegree is not null
            || observation.WindSpeedMeterPerSecond is not null
            || observation.WindGustMeterPerSecond is not null
            || observation.WaveHeightMeter is not null
            || observation.DominantWavePeriodSecond is not null
            || observation.AverageWavePeriodSecond is not null
            || observation.MeanWaveDirectionDegree is not null
            || observation.SeaSurfaceTemperatureCelsius is not null;
    }

    private static void WriteNullable(
        NpgsqlBinaryImporter importer,
        string? value,
        NpgsqlDbType dataType)
    {
        if (value is null)
        {
            importer.WriteNull();
            return;
        }

        importer.Write(value, dataType);
    }

    private static void WriteNullable<T>(
        NpgsqlBinaryImporter importer,
        T? value,
        NpgsqlDbType dataType)
        where T : struct
    {
        if (value is null)
        {
            importer.WriteNull();
            return;
        }

        importer.Write(value.Value, dataType);
    }
}
