using NdbcScraper.Configuration;
using NdbcScraper.Models;
using NdbcScraper.Persistence;
using NdbcScraper.Scrapers;

namespace NdbcScraper.Services;

internal sealed class ScrapeRunner
{
    private const string StationListSourceUrl =
        "https://www.ndbc.noaa.gov/to_station.shtml";

    private readonly IStationListScraper _stationListScraper;
    private readonly IStationDataScraper _stationDataScraper;
    private readonly RobotsPolicyChecker _robotsPolicyChecker;
    private readonly JsonFileStore _fileStore;
    private readonly OutputPathProvider _outputPaths;

    public ScrapeRunner(
        IStationListScraper stationListScraper,
        IStationDataScraper stationDataScraper,
        RobotsPolicyChecker robotsPolicyChecker,
        JsonFileStore fileStore,
        OutputPathProvider outputPaths)
    {
        _stationListScraper = stationListScraper;
        _stationDataScraper = stationDataScraper;
        _robotsPolicyChecker = robotsPolicyChecker;
        _fileStore = fileStore;
        _outputPaths = outputPaths;
    }

    public async Task<bool> RunAsync(
        ScrapeOptions options,
        CancellationToken cancellationToken = default)
    {
        ScrapeProgress progress;
        List<StationData> stations;
        List<SkippedStationData> skippedStations;
        List<ScrapeErrorData> errors;

        if (options.Resume)
        {
            _outputPaths.EnsureDirectories();

            progress = await _fileStore.ReadAsync<ScrapeProgress>(
                _outputPaths.ProgressFile,
                cancellationToken) ?? throw new InvalidOperationException(
                "Checkpoint tidak ditemukan. Jalankan tanpa --resume terlebih dahulu.");

            stations = await _fileStore.ReadAsync<List<StationData>>(
                _outputPaths.StationsFile,
                cancellationToken) ?? new List<StationData>();

            skippedStations = await _fileStore.ReadAsync<List<SkippedStationData>>(
                _outputPaths.SkippedStationsFile,
                cancellationToken) ?? new List<SkippedStationData>();

            errors = await _fileStore.ReadAsync<List<ScrapeErrorData>>(
                _outputPaths.ErrorsFile,
                cancellationToken) ?? new List<ScrapeErrorData>();

            MigrateLegacyNoDataErrors(
                progress.ScrapeRunId,
                skippedStations,
                errors);

            await RepairResumeStateAsync(
                progress,
                stations,
                cancellationToken);

            Console.WriteLine(
                $"Melanjutkan run {progress.ScrapeRunId}. " +
                $"Stasiun berhasil: {progress.SuccessfulStationIds.Count}/" +
                $"{progress.TargetStationCount}.");
        }
        else
        {
            _outputPaths.PrepareNewRun();

            DateTimeOffset startedAt = DateTimeOffset.UtcNow;
            progress = new ScrapeProgress
            {
                ScrapeRunId = CreateRunId(startedAt),
                StartedAt = startedAt,
                TargetStationCount = options.TargetStationCount,
                SourceCandidateCount = 0,
                ProcessedStationIds = new List<string>(),
                SuccessfulStationIds = new List<string>(),
                SkippedNonBuoyCount = 0,
                SkippedNoDataCount = 0,
                FailedAttemptCount = 0,
                TotalObservationCount = 0,
                DuplicateObservationCount = 0,
                LastUpdatedAt = startedAt
            };

            stations = new List<StationData>();
            skippedStations = new List<SkippedStationData>();
            errors = new List<ScrapeErrorData>();
        }

        Console.WriteLine("Memeriksa kebijakan robots.txt...");
        string? robotsWarning = await _robotsPolicyChecker.CheckAsync(
            cancellationToken);

        if (!string.IsNullOrWhiteSpace(robotsWarning))
        {
            Console.WriteLine($"Peringatan: {robotsWarning}");
        }

        Console.WriteLine("Mengambil daftar stasiun NDBC...");
        IReadOnlyList<StationCandidate> candidates =
            await _stationListScraper.ScrapeAsync(cancellationToken);

        progress.SourceCandidateCount = candidates.Count;
        progress.LastUpdatedAt = DateTimeOffset.UtcNow;
        await SaveCheckpointAsync(
            progress,
            stations,
            skippedStations,
            errors,
            cancellationToken);

        HashSet<string> processedStationIds = new(
            progress.ProcessedStationIds,
            StringComparer.OrdinalIgnoreCase);

        HashSet<string> attemptedThisExecution = new(
            StringComparer.OrdinalIgnoreCase);

        for (int candidateIndex = 0;
             candidateIndex < candidates.Count;
             candidateIndex++)
        {
            cancellationToken.ThrowIfCancellationRequested();

            if (progress.SuccessfulStationIds.Count >=
                progress.TargetStationCount)
            {
                break;
            }

            StationCandidate candidate = candidates[candidateIndex];

            if (processedStationIds.Contains(candidate.StationId) ||
                !attemptedThisExecution.Add(candidate.StationId))
            {
                continue;
            }

            Console.Write(
                $"[Kandidat {candidateIndex + 1}/{candidates.Count} | " +
                $"Berhasil {progress.SuccessfulStationIds.Count}/" +
                $"{progress.TargetStationCount}] " +
                $"Memproses {candidate.StationId}... ");

            StationScrapeResult result =
                await _stationDataScraper.ScrapeAsync(
                    candidate,
                    progress.ScrapeRunId,
                    cancellationToken);

            errors.AddRange(result.Errors);

            switch (result.Outcome)
            {
                case StationScrapeOutcomes.Success:
                    RemoveSkippedStation(
                        skippedStations,
                        candidate.StationId);

                    await HandleSuccessAsync(
                        result,
                        progress,
                        stations,
                        processedStationIds,
                        cancellationToken);

                    Console.WriteLine(
                        $"berhasil, {result.Observations.Count} observasi.");
                    break;

                case StationScrapeOutcomes.NotBuoy:
                    MarkProcessed(
                        progress,
                        processedStationIds,
                        candidate.StationId);
                    progress.SkippedNonBuoyCount++;

                    UpsertSkippedStation(
                        skippedStations,
                        CreateSkippedStation(
                            progress.ScrapeRunId,
                            candidate,
                            result,
                            SkippedStationReasonCodes.NotBuoy,
                            "Stasiun tidak teridentifikasi sebagai buoy.",
                            null));

                    Console.WriteLine("dilewati, bukan buoy.");
                    break;

                case StationScrapeOutcomes.NoRealtimeData:
                    MarkProcessed(
                        progress,
                        processedStationIds,
                        candidate.StationId);
                    progress.SkippedNoDataCount++;

                    UpsertSkippedStation(
                        skippedStations,
                        CreateSkippedStation(
                            progress.ScrapeRunId,
                            candidate,
                            result,
                            SkippedStationReasonCodes.NoRealtimeMeteorologicalData,
                            "File standard meteorological real-time tidak tersedia.",
                            404));

                    Console.WriteLine(
                        "dilewati, file meteorologi real-time tidak tersedia.");
                    break;

                case StationScrapeOutcomes.NoRelevantMeasurements:
                    MarkProcessed(
                        progress,
                        processedStationIds,
                        candidate.StationId);
                    progress.SkippedNoDataCount++;

                    UpsertSkippedStation(
                        skippedStations,
                        CreateSkippedStation(
                            progress.ScrapeRunId,
                            candidate,
                            result,
                            SkippedStationReasonCodes.NoRelevantMeasurements,
                            "Data tersedia, tetapi tidak memuat pengukuran angin, " +
                            "gelombang, atau suhu laut yang dapat digunakan.",
                            null));

                    Console.WriteLine(
                        "dilewati, pengukuran relevan tidak tersedia.");
                    break;

                default:
                    progress.FailedAttemptCount++;
                    Console.WriteLine(
                        "gagal, detail dicatat pada errors.json.");
                    break;
            }

            progress.LastUpdatedAt = DateTimeOffset.UtcNow;
            await SaveCheckpointAsync(
                progress,
                stations,
                skippedStations,
                errors,
                cancellationToken);
        }

        await WriteCombinedOutputAsync(
            progress,
            stations,
            skippedStations,
            errors,
            cancellationToken);

        bool targetMet = progress.SuccessfulStationIds.Count >=
                         progress.TargetStationCount;

        DateTimeOffset finishedAt = DateTimeOffset.UtcNow;

        ScrapeRunReport report = new()
        {
            ScrapeRunId = progress.ScrapeRunId,
            StartedAt = progress.StartedAt,
            FinishedAt = finishedAt,
            TargetStationCount = progress.TargetStationCount,
            TargetMet = targetMet,
            SourceCandidateCount = progress.SourceCandidateCount,
            ProcessedCandidateCount = progress.ProcessedStationIds.Count,
            SuccessfulStationCount = progress.SuccessfulStationIds.Count,
            SkippedNonBuoyCount = progress.SkippedNonBuoyCount,
            SkippedNoDataCount = progress.SkippedNoDataCount,
            FailedAttemptCount = progress.FailedAttemptCount,
            TotalObservationCount = progress.TotalObservationCount,
            DuplicateObservationCount = progress.DuplicateObservationCount,
            StationListSourceUrl = StationListSourceUrl,
            OutputDirectory = _outputPaths.DataDirectory
        };

        await _fileStore.WriteAsync(
            _outputPaths.ReportFile,
            report,
            cancellationToken);

        Console.WriteLine();
        Console.WriteLine($"Run ID: {progress.ScrapeRunId}");
        Console.WriteLine(
            $"Stasiun berhasil: {progress.SuccessfulStationIds.Count}/" +
            $"{progress.TargetStationCount}");
        Console.WriteLine($"Stasiun dilewati: {skippedStations.Count}");
        Console.WriteLine($"Kesalahan tercatat: {errors.Count}");
        Console.WriteLine(
            $"Total observasi: {progress.TotalObservationCount}");
        Console.WriteLine($"Output: {_outputPaths.DataDirectory}");

        if (!targetMet)
        {
            Console.WriteLine(
                "Target belum tercapai karena kandidat yang memenuhi kriteria " +
                "telah habis atau sebagian request gagal. Jalankan kembali " +
                "dengan --resume untuk mencoba ulang kegagalan sementara.");
        }

        return targetMet;
    }

    private async Task HandleSuccessAsync(
        StationScrapeResult result,
        ScrapeProgress progress,
        List<StationData> stations,
        HashSet<string> processedStationIds,
        CancellationToken cancellationToken)
    {
        StationData station = result.Station ??
            throw new InvalidOperationException(
                "Metadata stasiun tidak tersedia pada hasil yang sukses.");

        string observationFile =
            _outputPaths.GetStationObservationFile(station.StationId);

        await _fileStore.WriteAsync(
            observationFile,
            result.Observations,
            cancellationToken);

        stations.RemoveAll(existing => existing.StationId.Equals(
            station.StationId,
            StringComparison.OrdinalIgnoreCase));
        stations.Add(station);

        if (!progress.SuccessfulStationIds.Contains(
            station.StationId,
            StringComparer.OrdinalIgnoreCase))
        {
            progress.SuccessfulStationIds.Add(station.StationId);
            progress.TotalObservationCount += result.Observations.Count;
            progress.DuplicateObservationCount += result.DuplicateCount;
        }

        MarkProcessed(
            progress,
            processedStationIds,
            station.StationId);
    }

    private async Task SaveCheckpointAsync(
        ScrapeProgress progress,
        IReadOnlyList<StationData> stations,
        IReadOnlyList<SkippedStationData> skippedStations,
        IReadOnlyList<ScrapeErrorData> errors,
        CancellationToken cancellationToken)
    {
        await _fileStore.WriteAsync(
            _outputPaths.ProgressFile,
            progress,
            cancellationToken);

        await _fileStore.WriteAsync(
            _outputPaths.StationsFile,
            stations.OrderBy(station => station.StationId).ToList(),
            cancellationToken);

        await _fileStore.WriteAsync(
            _outputPaths.SkippedStationsFile,
            skippedStations
                .OrderBy(station => station.StationId)
                .ToList(),
            cancellationToken);

        await _fileStore.WriteAsync(
            _outputPaths.ErrorsFile,
            errors,
            cancellationToken);
    }

    private async Task WriteCombinedOutputAsync(
        ScrapeProgress progress,
        IReadOnlyList<StationData> stations,
        IReadOnlyList<SkippedStationData> skippedStations,
        IReadOnlyList<ScrapeErrorData> errors,
        CancellationToken cancellationToken)
    {
        await SaveCheckpointAsync(
            progress,
            stations,
            skippedStations,
            errors,
            cancellationToken);

        List<(string StationId, string FilePath)> observationFiles =
            progress.SuccessfulStationIds
                .OrderBy(stationId => stationId)
                .Select(stationId => (
                    StationId: stationId,
                    FilePath: _outputPaths.GetStationObservationFile(stationId)))
                .Where(item => File.Exists(item.FilePath))
                .ToList();

        await _fileStore.WriteCombinedObservationsAsync(
            _outputPaths.CombinedObservationsFile,
            observationFiles.Select(item => item.FilePath),
            cancellationToken);

        ObservationManifestData manifest =
            await CreateObservationManifestAsync(
                progress,
                observationFiles,
                cancellationToken);

        await _fileStore.WriteAsync(
            _outputPaths.ObservationManifestFile,
            manifest,
            cancellationToken);
    }

    private async Task<ObservationManifestData> CreateObservationManifestAsync(
        ScrapeProgress progress,
        IReadOnlyList<(string StationId, string FilePath)> observationFiles,
        CancellationToken cancellationToken)
    {
        List<ObservationFileManifestEntry> entries = new();

        foreach ((string stationId, string filePath) in observationFiles)
        {
            cancellationToken.ThrowIfCancellationRequested();

            List<ObservationData> observations =
                await _fileStore.ReadAsync<List<ObservationData>>(
                    filePath,
                    cancellationToken) ?? new List<ObservationData>();

            FileInfo fileInfo = new(filePath);
            string relativePath = Path.GetRelativePath(
                    _outputPaths.DataDirectory,
                    filePath)
                .Replace(Path.DirectorySeparatorChar, '/')
                .Replace(Path.AltDirectorySeparatorChar, '/');

            entries.Add(new ObservationFileManifestEntry
            {
                StationId = stationId,
                RelativePath = relativePath,
                ObservationCount = observations.Count,
                FirstObservedAtUtc = observations.Count == 0
                    ? null
                    : observations[0].ObservedAtUtc,
                LastObservedAtUtc = observations.Count == 0
                    ? null
                    : observations[^1].ObservedAtUtc,
                FileSizeBytes = fileInfo.Length
            });
        }

        int manifestObservationCount = entries.Sum(entry =>
            entry.ObservationCount);

        if (manifestObservationCount != progress.TotalObservationCount)
        {
            throw new InvalidOperationException(
                "Jumlah observasi pada manifest tidak sama dengan checkpoint.");
        }

        return new ObservationManifestData
        {
            ScrapeRunId = progress.ScrapeRunId,
            GeneratedAt = DateTimeOffset.UtcNow,
            TotalStationCount = entries.Count,
            TotalObservationCount = manifestObservationCount,
            CombinedFile = Path.GetFileName(
                _outputPaths.CombinedObservationsFile) ?? "observations.json",
            CombinedFileGitIgnored = true,
            StationFiles = entries
        };
    }

    private async Task RepairResumeStateAsync(
        ScrapeProgress progress,
        List<StationData> stations,
        CancellationToken cancellationToken)
    {
        HashSet<string> validSuccessIds = new(
            StringComparer.OrdinalIgnoreCase);

        foreach (string stationId in progress.SuccessfulStationIds)
        {
            bool hasStationMetadata = stations.Any(station =>
                station.StationId.Equals(
                    stationId,
                    StringComparison.OrdinalIgnoreCase));

            bool hasObservationFile = File.Exists(
                _outputPaths.GetStationObservationFile(stationId));

            if (hasStationMetadata && hasObservationFile)
            {
                validSuccessIds.Add(stationId);
            }
        }

        HashSet<string> invalidSuccessIds = new(
            progress.SuccessfulStationIds.Where(stationId =>
                !validSuccessIds.Contains(stationId)),
            StringComparer.OrdinalIgnoreCase);

        progress.SuccessfulStationIds.RemoveAll(stationId =>
            invalidSuccessIds.Contains(stationId));

        progress.ProcessedStationIds.RemoveAll(stationId =>
            invalidSuccessIds.Contains(stationId));

        stations.RemoveAll(station =>
            invalidSuccessIds.Contains(station.StationId));

        int observationCount = 0;

        foreach (string stationId in progress.SuccessfulStationIds)
        {
            List<ObservationData> observations =
                await _fileStore.ReadAsync<List<ObservationData>>(
                    _outputPaths.GetStationObservationFile(stationId),
                    cancellationToken) ?? new List<ObservationData>();

            observationCount += observations.Count;
        }

        progress.TotalObservationCount = observationCount;
        progress.LastUpdatedAt = DateTimeOffset.UtcNow;
    }

    private static SkippedStationData CreateSkippedStation(
        string scrapeRunId,
        StationCandidate candidate,
        StationScrapeResult result,
        string reasonCode,
        string message,
        int? httpStatusCode)
    {
        return new SkippedStationData
        {
            ScrapeRunId = scrapeRunId,
            StationId = candidate.StationId,
            ReasonCode = reasonCode,
            Message = message,
            DetailUrl = candidate.DetailUrl,
            RealtimeDataUrl = result.Station?.RealtimeDataUrl,
            HttpStatusCode = httpStatusCode,
            SkippedAt = DateTimeOffset.UtcNow
        };
    }

    private static void UpsertSkippedStation(
        List<SkippedStationData> skippedStations,
        SkippedStationData skippedStation)
    {
        RemoveSkippedStation(
            skippedStations,
            skippedStation.StationId);
        skippedStations.Add(skippedStation);
    }

    private static void RemoveSkippedStation(
        List<SkippedStationData> skippedStations,
        string stationId)
    {
        skippedStations.RemoveAll(station =>
            station.StationId.Equals(
                stationId,
                StringComparison.OrdinalIgnoreCase));
    }

    private static void MigrateLegacyNoDataErrors(
        string scrapeRunId,
        List<SkippedStationData> skippedStations,
        List<ScrapeErrorData> errors)
    {
        List<ScrapeErrorData> legacyNoDataErrors = errors
            .Where(error =>
                error.ErrorCode.Equals(
                    ScrapeErrorCodes.RealtimeFileNotFound,
                    StringComparison.Ordinal) &&
                !string.IsNullOrWhiteSpace(error.StationId))
            .ToList();

        foreach (ScrapeErrorData error in legacyNoDataErrors)
        {
            UpsertSkippedStation(
                skippedStations,
                new SkippedStationData
                {
                    ScrapeRunId = scrapeRunId,
                    StationId = error.StationId!,
                    ReasonCode =
                        SkippedStationReasonCodes.NoRealtimeMeteorologicalData,
                    Message =
                        "File standard meteorological real-time tidak tersedia.",
                    DetailUrl = null,
                    RealtimeDataUrl = error.SourceUrl,
                    HttpStatusCode = error.HttpStatusCode ?? 404,
                    SkippedAt = error.OccurredAt
                });
        }

        errors.RemoveAll(error =>
            error.ErrorCode.Equals(
                ScrapeErrorCodes.RealtimeFileNotFound,
                StringComparison.Ordinal));
    }

    private static void MarkProcessed(
        ScrapeProgress progress,
        HashSet<string> processedStationIds,
        string stationId)
    {
        if (processedStationIds.Add(stationId))
        {
            progress.ProcessedStationIds.Add(stationId);
        }
    }

    private static string CreateRunId(DateTimeOffset startedAt)
    {
        return $"ndbc-{startedAt:yyyyMMdd-HHmmss}-{Guid.NewGuid():N}"[..31];
    }
}
