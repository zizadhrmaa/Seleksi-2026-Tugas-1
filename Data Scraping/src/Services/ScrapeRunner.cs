using System.Diagnostics;
using System.Globalization;
using BmkgScraper.Models;
using BmkgScraper.Persistence;
using BmkgScraper.Scrapers;

namespace BmkgScraper.Services;

internal sealed class ScrapeRunner
{
    private readonly IPortScraper _portScraper;
    private readonly IForecastScraper _forecastScraper;
    private readonly IDataWriter _dataWriter;
    private readonly IDataReader _dataReader;
    private readonly OutputPathProvider _outputPathProvider;
    private readonly QualityReportBuilder _qualityReportBuilder;
    private readonly TimeSpan _requestDelay;
    private readonly TimeSpan _sourceRetryDelay;
    private readonly TimeSpan _localOffset;

    public ScrapeRunner(
        IPortScraper portScraper,
        IForecastScraper forecastScraper,
        IDataWriter dataWriter,
        IDataReader dataReader,
        OutputPathProvider outputPathProvider,
        QualityReportBuilder qualityReportBuilder,
        TimeSpan requestDelay,
        TimeSpan sourceRetryDelay,
        TimeSpan localOffset)
    {
        if (requestDelay < TimeSpan.Zero)
        {
            throw new ArgumentOutOfRangeException(
                nameof(requestDelay));
        }

        if (sourceRetryDelay < TimeSpan.Zero)
        {
            throw new ArgumentOutOfRangeException(
                nameof(sourceRetryDelay));
        }

        _portScraper = portScraper;
        _forecastScraper = forecastScraper;
        _dataWriter = dataWriter;
        _dataReader = dataReader;
        _outputPathProvider = outputPathProvider;
        _qualityReportBuilder = qualityReportBuilder;
        _requestDelay = requestDelay;
        _sourceRetryDelay = sourceRetryDelay;
        _localOffset = localOffset;
    }

    public async Task RunAsync(
        ScrapeRunOptions options,
        CancellationToken cancellationToken = default)
    {
        PreparedRun preparedRun =
            await PrepareRunAsync(
                options,
                cancellationToken);

        string batchId = preparedRun.Batch.BatchId;
        string metadataPath =
            _outputPathProvider.GetBatchMetadataPath(batchId);
        string selectedPortsPath =
            _outputPathProvider.GetSelectedPortsPath(batchId);
        string errorsPath =
            _outputPathProvider.GetBatchErrorsPath(batchId);
        string portResultsPath =
            _outputPathProvider.GetPortResultsPath(batchId);
        string qualitySummaryPath =
            _outputPathProvider.GetQualitySummaryPath(batchId);
        string anomaliesPath =
            _outputPathProvider.GetAnomaliesPath(batchId);

        bool sourceRetryCompleted =
            preparedRun.SourceRetryCompleted;

        await PersistCheckpointAsync(
            preparedRun,
            sourceRetryCompleted,
            BatchStatusCodes.Running,
            metadataPath,
            errorsPath,
            portResultsPath,
            cancellationToken);

        PrintRunHeader(preparedRun);

        try
        {
            HashSet<string> processedPortCodes = preparedRun.PortResults
                .Select(result => result.PortCode)
                .ToHashSet(StringComparer.OrdinalIgnoreCase);

            List<PortData> pendingPorts = preparedRun.SelectedPorts
                .Where(port =>
                    !processedPortCodes.Contains(port.PortCode))
                .ToList();

            for (int index = 0;
                 index < pendingPorts.Count;
                 index++)
            {
                cancellationToken.ThrowIfCancellationRequested();

                PortData port = pendingPorts[index];
                int completedBefore = preparedRun.PortResults.Count;

                Console.WriteLine();
                Console.WriteLine(
                    $"[{completedBefore + 1}/" +
                    $"{preparedRun.SelectedPorts.Count}] " +
                    port.PortName);

                await ProcessPortAsync(
                    preparedRun,
                    port,
                    isSourceRetry: false,
                    cancellationToken);

                await PersistCheckpointAsync(
                    preparedRun,
                    sourceRetryCompleted,
                    BatchStatusCodes.Running,
                    metadataPath,
                    errorsPath,
                    portResultsPath,
                    cancellationToken);

                if (index < pendingPorts.Count - 1)
                {
                    await DelayBetweenPortsAsync(
                        cancellationToken);
                }
            }

            if (!sourceRetryCompleted)
            {
                List<PortData> retryPorts =
                    ResolveSourceRetryPorts(preparedRun);

                if (retryPorts.Count > 0)
                {
                    Console.WriteLine();
                    Console.WriteLine(
                        $"Menunggu " +
                        $"{_sourceRetryDelay.TotalSeconds:0.##} detik " +
                        $"sebelum mencoba ulang {retryPorts.Count} " +
                        "pelabuhan dengan sumber kosong...");

                    if (_sourceRetryDelay > TimeSpan.Zero)
                    {
                        await Task.Delay(
                            _sourceRetryDelay,
                            cancellationToken);
                    }

                    for (int index = 0;
                         index < retryPorts.Count;
                         index++)
                    {
                        cancellationToken.ThrowIfCancellationRequested();

                        PortData port = retryPorts[index];

                        Console.WriteLine();
                        Console.WriteLine(
                            $"[Retry {index + 1}/" +
                            $"{retryPorts.Count}] {port.PortName}");

                        await ProcessPortAsync(
                            preparedRun,
                            port,
                            isSourceRetry: true,
                            cancellationToken);

                        await PersistCheckpointAsync(
                            preparedRun,
                            false,
                            BatchStatusCodes.Running,
                            metadataPath,
                            errorsPath,
                            portResultsPath,
                            cancellationToken);

                        if (index < retryPorts.Count - 1)
                        {
                            await DelayBetweenPortsAsync(
                                cancellationToken);
                        }
                    }
                }

                sourceRetryCompleted = true;

                await PersistCheckpointAsync(
                    preparedRun,
                    sourceRetryCompleted,
                    BatchStatusCodes.Running,
                    metadataPath,
                    errorsPath,
                    portResultsPath,
                    cancellationToken);
            }

            QualityReportResult qualityReports =
                await BuildQualityReportsAsync(
                    preparedRun,
                    cancellationToken);

            await _dataWriter.WriteAsync(
                qualityReports.Summary,
                qualitySummaryPath,
                cancellationToken);

            await _dataWriter.WriteAsync(
                qualityReports.Anomalies,
                anomaliesPath,
                cancellationToken);

            ScrapeBatchData finalBatchData = BuildBatchData(
                preparedRun,
                sourceRetryCompleted,
                ResolveFinalBatchStatus(
                    preparedRun.Errors,
                    preparedRun.PortResults,
                    qualityReports.Summary.TotalQualityFlagCount),
                qualityReports.Summary.TotalQualityFlagCount,
                finishedAt:
                    DateTimeOffset.UtcNow.ToOffset(_localOffset));

            await _dataWriter.WriteAsync(
                finalBatchData,
                metadataPath,
                cancellationToken);

            PrintSummary(
                finalBatchData,
                metadataPath,
                selectedPortsPath,
                portResultsPath,
                qualitySummaryPath,
                anomaliesPath);
        }
        catch (OperationCanceledException)
        {
            ScrapeBatchData cancelledBatchData = BuildBatchData(
                preparedRun,
                sourceRetryCompleted,
                BatchStatusCodes.Cancelled,
                qualityWarningCountOverride: null,
                finishedAt:
                    DateTimeOffset.UtcNow.ToOffset(_localOffset));

            await _dataWriter.WriteAsync(
                preparedRun.Errors,
                errorsPath,
                CancellationToken.None);

            await _dataWriter.WriteAsync(
                preparedRun.PortResults,
                portResultsPath,
                CancellationToken.None);

            await _dataWriter.WriteAsync(
                cancelledBatchData,
                metadataPath,
                CancellationToken.None);

            throw;
        }
    }

    private async Task<PreparedRun> PrepareRunAsync(
        ScrapeRunOptions options,
        CancellationToken cancellationToken)
    {
        return options.RunMode switch
        {
            ScrapeRunMode.New =>
                await PrepareNewRunAsync(
                    options,
                    cancellationToken),

            ScrapeRunMode.RetryBatch =>
                await PrepareRetryRunAsync(
                    options.ReferenceBatchId,
                    cancellationToken),

            ScrapeRunMode.Resume =>
                await PrepareResumeRunAsync(
                    options.ReferenceBatchId,
                    cancellationToken),

            _ => throw new ArgumentOutOfRangeException(
                nameof(options.RunMode))
        };
    }

    private async Task<PreparedRun> PrepareNewRunAsync(
        ScrapeRunOptions options,
        CancellationToken cancellationToken)
    {
        Console.WriteLine(
            "Mengambil daftar pelabuhan dari BMKG...");

        IReadOnlyList<PortData> ports =
            await _portScraper.ScrapeAsync(
                cancellationToken);

        if (ports.Count == 0)
        {
            throw new InvalidOperationException(
                "Tidak ditemukan tautan pelabuhan. " +
                "Struktur HTML mungkin berubah.");
        }

        await _dataWriter.WriteAsync(
            ports,
            _outputPathProvider.GetPortsPath(),
            cancellationToken);

        ScrapeBatchContext batch =
            ScrapeBatchContext.Create(_localOffset);

        IReadOnlyList<PortData> selectedPorts = SelectPorts(
            ports,
            options.PortLimit,
            options.SelectionMode);

        string selectionMode =
            selectedPorts.Count == ports.Count
                ? "ALL"
                : options.SelectionMode
                    .ToString()
                    .ToUpperInvariant();

        await _dataWriter.WriteAsync(
            selectedPorts,
            _outputPathProvider.GetSelectedPortsPath(
                batch.BatchId),
            cancellationToken);

        return new PreparedRun(
            batch,
            selectedPorts,
            [],
            [],
            ScrapeRunTypeCodes.Full,
            null,
            selectionMode,
            SourceRetryCompleted: false,
            IsResume: false);
    }

    private async Task<PreparedRun> PrepareRetryRunAsync(
        string? sourceBatchId,
        CancellationToken cancellationToken)
    {
        string validatedBatchId =
            ValidateExistingBatchId(sourceBatchId);

        IReadOnlyList<PortData> sourceSelectedPorts =
            await ReadRequiredListAsync<PortData>(
                _outputPathProvider.GetSelectedPortsPath(
                    validatedBatchId),
                "selected_ports.json",
                cancellationToken);

        IReadOnlyList<PortScrapeResultData> sourcePortResults =
            await ReadRequiredListAsync<PortScrapeResultData>(
                _outputPathProvider.GetPortResultsPath(
                    validatedBatchId),
                "port_results.json",
                cancellationToken);

        HashSet<string> retryPortCodes = sourcePortResults
            .Where(result => result.Status is
                PortScrapeStatusCodes.SourceUnavailable or
                PortScrapeStatusCodes.Failed or
                PortScrapeStatusCodes.PartialSuccess)
            .Select(result => result.PortCode)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        List<PortData> selectedPorts = sourceSelectedPorts
            .Where(port => retryPortCodes.Contains(port.PortCode))
            .ToList();

        if (selectedPorts.Count == 0)
        {
            throw new InvalidOperationException(
                $"Batch {validatedBatchId} tidak memiliki pelabuhan " +
                "yang perlu dicoba ulang.");
        }

        ScrapeBatchContext batch =
            ScrapeBatchContext.Create(_localOffset);

        await _dataWriter.WriteAsync(
            selectedPorts,
            _outputPathProvider.GetSelectedPortsPath(
                batch.BatchId),
            cancellationToken);

        return new PreparedRun(
            batch,
            selectedPorts,
            [],
            [],
            ScrapeRunTypeCodes.Retry,
            validatedBatchId,
            SelectionMode: "RETRY",
            SourceRetryCompleted: false,
            IsResume: false);
    }

    private async Task<PreparedRun> PrepareResumeRunAsync(
        string? batchId,
        CancellationToken cancellationToken)
    {
        string validatedBatchId =
            ValidateExistingBatchId(batchId);

        IReadOnlyList<PortData> selectedPorts =
            await ReadRequiredListAsync<PortData>(
                _outputPathProvider.GetSelectedPortsPath(
                    validatedBatchId),
                "selected_ports.json",
                cancellationToken);

        List<PortScrapeResultData> portResults =
            await ReadOptionalListAsync<PortScrapeResultData>(
                _outputPathProvider.GetPortResultsPath(
                    validatedBatchId),
                cancellationToken);

        List<ScrapeErrorData> errors =
            await ReadOptionalListAsync<ScrapeErrorData>(
                _outputPathProvider.GetBatchErrorsPath(
                    validatedBatchId),
                cancellationToken);

        ScrapeBatchData? existingMetadata =
            await _dataReader.ReadAsync<ScrapeBatchData>(
                _outputPathProvider.GetBatchMetadataPath(
                    validatedBatchId),
                cancellationToken);

        bool allPortsProcessed =
            portResults
                .Select(result => result.PortCode)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Count() >= selectedPorts.Count;

        if (existingMetadata is not null &&
            IsFinalBatchStatus(existingMetadata.Status) &&
            allPortsProcessed)
        {
            throw new InvalidOperationException(
                $"Batch {validatedBatchId} sudah selesai. " +
                "Gunakan --retry-batch untuk mencoba ulang " +
                "pelabuhan bermasalah sebagai batch baru.");
        }

        DateTimeOffset startedAt =
            ResolveExistingBatchStart(
                validatedBatchId,
                existingMetadata,
                portResults);

        ScrapeBatchContext batch = new(
            validatedBatchId,
            startedAt);

        return new PreparedRun(
            batch,
            selectedPorts,
            errors,
            portResults,
            existingMetadata?.RunType ??
                ScrapeRunTypeCodes.Full,
            existingMetadata?.ParentBatchId,
            existingMetadata?.SelectionMode ?? "UNKNOWN",
            existingMetadata?.SourceRetryCompleted ?? false,
            IsResume: true);
    }

    private async Task ProcessPortAsync(
        PreparedRun preparedRun,
        PortData port,
        bool isSourceRetry,
        CancellationToken cancellationToken)
    {
        Stopwatch stopwatch = Stopwatch.StartNew();

        PortScrapeResultData? previousResult =
            preparedRun.PortResults.FirstOrDefault(result =>
                result.PortCode.Equals(
                    port.PortCode,
                    StringComparison.OrdinalIgnoreCase));

        try
        {
            ForecastScrapeResult result =
                await _forecastScraper.ScrapeAsync(
                    port,
                    preparedRun.Batch,
                    cancellationToken);

            stopwatch.Stop();

            await _dataWriter.WriteAsync(
                result.Forecasts,
                _outputPathProvider.GetPortForecastPath(
                    preparedRun.Batch.BatchId,
                    port.PortCode),
                cancellationToken);

            int rowWarningCount = result.Forecasts.Sum(
                forecast => forecast.QualityFlags.Count);

            int portWarningCount =
                rowWarningCount +
                result.SeriesQualityFlags.Count;

            int previousAttemptCount =
                isSourceRetry
                    ? previousResult?.AttemptCount ?? 0
                    : 0;

            long previousDurationMilliseconds =
                isSourceRetry
                    ? previousResult?.DurationMilliseconds ?? 0
                    : 0;

            int totalAttemptCount =
                previousAttemptCount + result.AttemptCount;

            long totalDurationMilliseconds =
                previousDurationMilliseconds +
                result.DurationMilliseconds;

            IReadOnlyList<ScrapeErrorData> accumulatedErrors =
                AccumulateErrorDiagnostics(
                    result.Errors,
                    previousAttemptCount,
                    previousDurationMilliseconds);

            string portStatus = ResolvePortStatus(
                result.Forecasts.Count,
                accumulatedErrors,
                portWarningCount);

            ReplacePortErrors(
                preparedRun.Errors,
                port.PortCode,
                accumulatedErrors);

            PortScrapeResultData portResult = new()
            {
                BatchId = preparedRun.Batch.BatchId,
                PortCode = port.PortCode,
                PortName = port.PortName,
                Status = portStatus,
                ForecastCount = result.Forecasts.Count,
                ErrorCount = accumulatedErrors.Count,
                QualityWarningCount = portWarningCount,
                SeriesQualityFlags =
                    result.SeriesQualityFlags,
                AttemptCount = totalAttemptCount,
                RetryCount =
                    (previousResult?.RetryCount ?? 0) +
                    (isSourceRetry ? 1 : 0),
                HttpStatusCode = result.HttpStatusCode,
                DurationMilliseconds =
                    totalDurationMilliseconds,
                ProcessedAt =
                    DateTimeOffset.UtcNow.ToOffset(
                        _localOffset)
            };

            UpsertPortResult(
                preparedRun.PortResults,
                portResult);

            PrintPortResult(
                result.Forecasts.Count,
                accumulatedErrors.Count,
                portWarningCount,
                portStatus,
                result.SeriesQualityFlags);
        }
        catch (Exception exception)
            when (exception is not OperationCanceledException)
        {
            stopwatch.Stop();

            ScrapeErrorData error = CreatePortError(
                preparedRun.Batch,
                port,
                exception.Message,
                stopwatch.ElapsedMilliseconds);

            ReplacePortErrors(
                preparedRun.Errors,
                port.PortCode,
                [error]);

            await _dataWriter.WriteAsync(
                Array.Empty<ForecastData>(),
                _outputPathProvider.GetPortForecastPath(
                    preparedRun.Batch.BatchId,
                    port.PortCode),
                cancellationToken);

            UpsertPortResult(
                preparedRun.PortResults,
                new PortScrapeResultData
                {
                    BatchId = preparedRun.Batch.BatchId,
                    PortCode = port.PortCode,
                    PortName = port.PortName,
                    Status = PortScrapeStatusCodes.Failed,
                    ForecastCount = 0,
                    ErrorCount = 1,
                    QualityWarningCount = 0,
                    SeriesQualityFlags = [],
                    AttemptCount =
                        isSourceRetry
                            ? previousResult?.AttemptCount ?? 0
                            : 0,
                    RetryCount =
                        (previousResult?.RetryCount ?? 0) +
                        (isSourceRetry ? 1 : 0),
                    HttpStatusCode = null,
                    DurationMilliseconds =
                        stopwatch.ElapsedMilliseconds +
                        (isSourceRetry
                            ? previousResult?.DurationMilliseconds ?? 0
                            : 0),
                    ProcessedAt =
                        DateTimeOffset.UtcNow.ToOffset(
                            _localOffset)
                });

            Console.WriteLine(
                $"Gagal teknis: {exception.Message}");
        }
    }

    private async Task<QualityReportResult> BuildQualityReportsAsync(
        PreparedRun preparedRun,
        CancellationToken cancellationToken)
    {
        List<ForecastData> forecasts = [];

        foreach (PortScrapeResultData portResult in
                 preparedRun.PortResults)
        {
            if (portResult.ForecastCount <= 0)
            {
                continue;
            }

            string forecastPath =
                _outputPathProvider.GetPortForecastPath(
                    preparedRun.Batch.BatchId,
                    portResult.PortCode);

            List<ForecastData>? portForecasts =
                await _dataReader.ReadAsync<List<ForecastData>>(
                    forecastPath,
                    cancellationToken);

            if (portForecasts is null)
            {
                throw new InvalidDataException(
                    "File forecast tidak ditemukan untuk pelabuhan " +
                    $"{portResult.PortCode}.");
            }

            forecasts.AddRange(portForecasts);
        }

        return _qualityReportBuilder.Build(
            preparedRun.Batch.BatchId,
            forecasts,
            preparedRun.PortResults,
            DateTimeOffset.UtcNow.ToOffset(_localOffset));
    }

    private async Task PersistCheckpointAsync(
        PreparedRun preparedRun,
        bool sourceRetryCompleted,
        string status,
        string metadataPath,
        string errorsPath,
        string portResultsPath,
        CancellationToken cancellationToken)
    {
        await _dataWriter.WriteAsync(
            preparedRun.Errors,
            errorsPath,
            cancellationToken);

        await _dataWriter.WriteAsync(
            preparedRun.PortResults,
            portResultsPath,
            cancellationToken);

        ScrapeBatchData checkpointData = BuildBatchData(
            preparedRun,
            sourceRetryCompleted,
            status,
            qualityWarningCountOverride: null,
            finishedAt:
                status == BatchStatusCodes.Running
                    ? null
                    : DateTimeOffset.UtcNow.ToOffset(
                        _localOffset));

        await _dataWriter.WriteAsync(
            checkpointData,
            metadataPath,
            cancellationToken);
    }

    private ScrapeBatchData BuildBatchData(
        PreparedRun preparedRun,
        bool sourceRetryCompleted,
        string status,
        int? qualityWarningCountOverride,
        DateTimeOffset? finishedAt)
    {
        int successfulPortCount =
            preparedRun.PortResults.Count(result =>
                result.Status is
                    PortScrapeStatusCodes.Success or
                    PortScrapeStatusCodes.SuccessWithWarnings);

        int partialSuccessPortCount =
            preparedRun.PortResults.Count(result =>
                result.Status ==
                PortScrapeStatusCodes.PartialSuccess);

        int sourceUnavailablePortCount =
            preparedRun.PortResults.Count(result =>
                result.Status ==
                PortScrapeStatusCodes.SourceUnavailable);

        int technicalFailedPortCount =
            preparedRun.PortResults.Count(result =>
                result.Status ==
                PortScrapeStatusCodes.Failed);

        int processedPortCount = preparedRun.PortResults
            .Select(result => result.PortCode)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Count();

        int qualityWarningCount =
            qualityWarningCountOverride ??
            preparedRun.PortResults.Sum(result =>
                result.QualityWarningCount);

        int technicalErrorCount = preparedRun.Errors.Count(error =>
            !IsSourceUnavailableError(error.ErrorCode));

        return new ScrapeBatchData
        {
            BatchId = preparedRun.Batch.BatchId,
            BatchStartedAt =
                preparedRun.Batch.BatchStartedAt,
            BatchFinishedAt = finishedAt,
            RunType = preparedRun.RunType,
            ParentBatchId = preparedRun.ParentBatchId,
            SelectionMode = preparedRun.SelectionMode,
            RequestedPortCount =
                preparedRun.SelectedPorts.Count,
            ProcessedPortCount = processedPortCount,
            RemainingPortCount = Math.Max(
                0,
                preparedRun.SelectedPorts.Count -
                processedPortCount),
            SuccessfulPortCount = successfulPortCount,
            PartialSuccessPortCount =
                partialSuccessPortCount,
            SourceUnavailablePortCount =
                sourceUnavailablePortCount,
            TechnicalFailedPortCount =
                technicalFailedPortCount,
            FailedPortCount =
                sourceUnavailablePortCount +
                technicalFailedPortCount,
            ForecastCount = preparedRun.PortResults.Sum(result =>
                result.ForecastCount),
            ErrorCount = preparedRun.Errors.Count,
            TechnicalErrorCount = technicalErrorCount,
            QualityWarningCount = qualityWarningCount,
            SourceRetryCompleted = sourceRetryCompleted,
            Status = status
        };
    }

    private string ValidateExistingBatchId(string? batchId)
    {
        if (string.IsNullOrWhiteSpace(batchId))
        {
            throw new ArgumentException(
                "Batch ID tidak boleh kosong.");
        }

        string normalizedBatchId = batchId.Trim();

        if (!_outputPathProvider.BatchExists(
                normalizedBatchId))
        {
            throw new DirectoryNotFoundException(
                $"Batch {normalizedBatchId} tidak ditemukan.");
        }

        return normalizedBatchId;
    }

    private async Task<IReadOnlyList<T>> ReadRequiredListAsync<T>(
        string inputPath,
        string displayName,
        CancellationToken cancellationToken)
    {
        List<T>? values =
            await _dataReader.ReadAsync<List<T>>(
                inputPath,
                cancellationToken);

        if (values is null || values.Count == 0)
        {
            throw new InvalidDataException(
                $"{displayName} tidak ditemukan atau kosong.");
        }

        return values;
    }

    private async Task<List<T>> ReadOptionalListAsync<T>(
        string inputPath,
        CancellationToken cancellationToken)
    {
        return await _dataReader.ReadAsync<List<T>>(
                   inputPath,
                   cancellationToken)
               ?? [];
    }

    private DateTimeOffset ResolveExistingBatchStart(
        string batchId,
        ScrapeBatchData? metadata,
        IReadOnlyList<PortScrapeResultData> portResults)
    {
        if (metadata is not null &&
            metadata.BatchStartedAt != default)
        {
            return metadata.BatchStartedAt;
        }

        if (TryParseBatchStartedAt(
                batchId,
                out DateTimeOffset parsedStartedAt))
        {
            return parsedStartedAt;
        }

        if (portResults.Count > 0)
        {
            return portResults.Min(result =>
                result.ProcessedAt);
        }

        return DateTimeOffset.UtcNow.ToOffset(_localOffset);
    }

    private bool TryParseBatchStartedAt(
        string batchId,
        out DateTimeOffset startedAt)
    {
        startedAt = default;
        string[] components = batchId.Split('-');

        if (components.Length < 4)
        {
            return false;
        }

        string timestamp =
            $"{components[1]}-{components[2]}";

        bool parsed = DateTime.TryParseExact(
            timestamp,
            "yyyyMMdd-HHmmss",
            CultureInfo.InvariantCulture,
            DateTimeStyles.None,
            out DateTime localDateTime);

        if (!parsed)
        {
            return false;
        }

        startedAt = new DateTimeOffset(
            DateTime.SpecifyKind(
                localDateTime,
                DateTimeKind.Unspecified),
            _localOffset);

        return true;
    }

    private static List<PortData> ResolveSourceRetryPorts(
        PreparedRun preparedRun)
    {
        HashSet<string> retryPortCodes = preparedRun.PortResults
            .Where(result =>
                result.Status ==
                    PortScrapeStatusCodes.SourceUnavailable &&
                result.RetryCount == 0)
            .Select(result => result.PortCode)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        return preparedRun.SelectedPorts
            .Where(port => retryPortCodes.Contains(port.PortCode))
            .ToList();
    }

    private async Task DelayBetweenPortsAsync(
        CancellationToken cancellationToken)
    {
        if (_requestDelay <= TimeSpan.Zero)
        {
            return;
        }

        Console.WriteLine(
            $"Menunggu {_requestDelay.TotalSeconds:0.##} detik...");

        await Task.Delay(
            _requestDelay,
            cancellationToken);
    }

    private ScrapeErrorData CreatePortError(
        ScrapeBatchContext batch,
        PortData port,
        string message,
        long durationMilliseconds)
    {
        return new ScrapeErrorData
        {
            BatchId = batch.BatchId,
            PortCode = port.PortCode,
            PortName = port.PortName,
            ErrorScope = "PORT",
            ErrorCode =
                ScrapeErrorCodes.UnexpectedPortError,
            RowIndex = null,
            Message = message,
            RawData = null,
            HttpStatusCode = null,
            AttemptCount = null,
            DurationMilliseconds =
                durationMilliseconds,
            TableRowCount = null,
            OccurredAt =
                DateTimeOffset.UtcNow.ToOffset(
                    _localOffset)
        };
    }

    private static IReadOnlyList<ScrapeErrorData>
        AccumulateErrorDiagnostics(
            IReadOnlyList<ScrapeErrorData> errors,
            int previousAttemptCount,
            long previousDurationMilliseconds)
    {
        if (previousAttemptCount <= 0 &&
            previousDurationMilliseconds <= 0)
        {
            return errors;
        }

        return errors
            .Select(error => new ScrapeErrorData
            {
                BatchId = error.BatchId,
                PortCode = error.PortCode,
                PortName = error.PortName,
                ErrorScope = error.ErrorScope,
                ErrorCode = error.ErrorCode,
                RowIndex = error.RowIndex,
                Message = error.Message,
                RawData = error.RawData,
                HttpStatusCode = error.HttpStatusCode,
                AttemptCount = error.AttemptCount is null
                    ? null
                    : previousAttemptCount +
                      error.AttemptCount.Value,
                DurationMilliseconds =
                    error.DurationMilliseconds is null
                        ? null
                        : previousDurationMilliseconds +
                          error.DurationMilliseconds.Value,
                TableRowCount = error.TableRowCount,
                OccurredAt = error.OccurredAt
            })
            .ToList();
    }

    private static void ReplacePortErrors(
        List<ScrapeErrorData> errors,
        string portCode,
        IReadOnlyList<ScrapeErrorData> replacementErrors)
    {
        errors.RemoveAll(error =>
            string.Equals(
                error.PortCode,
                portCode,
                StringComparison.OrdinalIgnoreCase));

        errors.AddRange(replacementErrors);
    }

    private static void UpsertPortResult(
        List<PortScrapeResultData> portResults,
        PortScrapeResultData replacement)
    {
        int existingIndex = portResults.FindIndex(result =>
            result.PortCode.Equals(
                replacement.PortCode,
                StringComparison.OrdinalIgnoreCase));

        if (existingIndex >= 0)
        {
            portResults[existingIndex] = replacement;
        }
        else
        {
            portResults.Add(replacement);
        }
    }

    private static string ResolvePortStatus(
        int forecastCount,
        IReadOnlyList<ScrapeErrorData> errors,
        int qualityWarningCount)
    {
        if (forecastCount == 0)
        {
            bool sourceUnavailable = errors.Count > 0 &&
                errors.All(error =>
                    IsSourceUnavailableError(
                        error.ErrorCode));

            return sourceUnavailable
                ? PortScrapeStatusCodes.SourceUnavailable
                : PortScrapeStatusCodes.Failed;
        }

        if (errors.Count > 0)
        {
            return PortScrapeStatusCodes.PartialSuccess;
        }

        return qualityWarningCount > 0
            ? PortScrapeStatusCodes.SuccessWithWarnings
            : PortScrapeStatusCodes.Success;
    }

    private static bool IsSourceUnavailableError(
        string errorCode)
    {
        return errorCode is
            ScrapeErrorCodes.SourcePageLoading or
            ScrapeErrorCodes.ForecastTableNotFound or
            ScrapeErrorCodes.AllRowsEmpty;
    }

    private static string ResolveFinalBatchStatus(
        IReadOnlyList<ScrapeErrorData> errors,
        IReadOnlyList<PortScrapeResultData> portResults,
        int qualityWarningCount)
    {
        bool hasTechnicalFailure = portResults.Any(result =>
            result.Status == PortScrapeStatusCodes.Failed);

        bool hasTechnicalError = errors.Any(error =>
            !IsSourceUnavailableError(error.ErrorCode));

        if (hasTechnicalFailure || hasTechnicalError)
        {
            return BatchStatusCodes.CompletedWithErrors;
        }

        bool hasSourceGap = portResults.Any(result =>
            result.Status ==
                PortScrapeStatusCodes.SourceUnavailable);

        if (hasSourceGap)
        {
            return BatchStatusCodes.CompletedWithSourceGaps;
        }

        return qualityWarningCount > 0
            ? BatchStatusCodes.CompletedWithWarnings
            : BatchStatusCodes.Completed;
    }

    private static bool IsFinalBatchStatus(string status)
    {
        return status is
            BatchStatusCodes.Completed or
            BatchStatusCodes.CompletedWithWarnings or
            BatchStatusCodes.CompletedWithSourceGaps or
            BatchStatusCodes.CompletedWithErrors;
    }

    private static IReadOnlyList<PortData> SelectPorts(
        IReadOnlyList<PortData> ports,
        int? portLimit,
        PortSelectionMode selectionMode)
    {
        if (portLimit is null ||
            portLimit >= ports.Count)
        {
            return ports;
        }

        if (portLimit <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(portLimit));
        }

        return selectionMode switch
        {
            PortSelectionMode.Sequential =>
                ports.Take(portLimit.Value).ToList(),
            PortSelectionMode.Spread =>
                SelectSpreadPorts(ports, portLimit.Value),
            _ => throw new ArgumentOutOfRangeException(
                nameof(selectionMode))
        };
    }

    private static IReadOnlyList<PortData> SelectSpreadPorts(
        IReadOnlyList<PortData> ports,
        int portLimit)
    {
        if (portLimit == 1)
        {
            return [ports[0]];
        }

        List<PortData> selectedPorts = [];
        double interval =
            (double)(ports.Count - 1) /
            (portLimit - 1);

        for (int index = 0;
             index < portLimit;
             index++)
        {
            int portIndex =
                (int)Math.Round(index * interval);

            selectedPorts.Add(ports[portIndex]);
        }

        return selectedPorts;
    }

    private static void PrintRunHeader(PreparedRun preparedRun)
    {
        Console.WriteLine();
        Console.WriteLine(
            $"Batch ID : {preparedRun.Batch.BatchId}");
        Console.WriteLine(
            $"Tipe run : {preparedRun.RunType}");

        if (!string.IsNullOrWhiteSpace(
                preparedRun.ParentBatchId))
        {
            Console.WriteLine(
                $"Parent batch : {preparedRun.ParentBatchId}");
        }

        Console.WriteLine(
            $"Mode pemilihan pelabuhan: " +
            $"{preparedRun.SelectionMode}");
        Console.WriteLine(
            $"Pelabuhan yang akan diproses: " +
            $"{preparedRun.SelectedPorts.Count}");

        if (preparedRun.IsResume)
        {
            Console.WriteLine(
                $"Melanjutkan dari " +
                $"{preparedRun.PortResults.Count} " +
                "pelabuhan yang sudah tercatat.");
        }
    }

    private static void PrintPortResult(
        int forecastCount,
        int errorCount,
        int qualityWarningCount,
        string portStatus,
        IReadOnlyList<string> seriesQualityFlags)
    {
        if (forecastCount == 0)
        {
            string failureLabel =
                portStatus ==
                    PortScrapeStatusCodes.SourceUnavailable
                    ? "Sumber tidak tersedia"
                    : "Gagal teknis";

            Console.WriteLine(
                $"{failureLabel}: tidak ada record valid, " +
                $"{errorCount} masalah.");
        }
        else
        {
            Console.WriteLine(
                $"Berhasil: {forecastCount} record, " +
                $"{errorCount} masalah, " +
                $"{qualityWarningCount} warning kualitas.");
        }

        if (seriesQualityFlags.Count > 0)
        {
            Console.WriteLine(
                "Warning seri: " +
                string.Join(
                    ", ",
                    seriesQualityFlags));
        }
    }

    private static void PrintSummary(
        ScrapeBatchData batchData,
        string metadataPath,
        string selectedPortsPath,
        string portResultsPath,
        string qualitySummaryPath,
        string anomaliesPath)
    {
        Console.WriteLine();
        Console.WriteLine(
            "======================================");
        Console.WriteLine(
            "RINGKASAN SCRAPING");
        Console.WriteLine(
            "======================================");
        Console.WriteLine(
            $"Batch ID             : " +
            $"{batchData.BatchId}");
        Console.WriteLine(
            $"Tipe run             : " +
            $"{batchData.RunType}");
        Console.WriteLine(
            $"Mode pemilihan       : " +
            $"{batchData.SelectionMode}");
        Console.WriteLine(
            $"Pelabuhan diminta    : " +
            $"{batchData.RequestedPortCount}");
        Console.WriteLine(
            $"Pelabuhan berhasil   : " +
            $"{batchData.SuccessfulPortCount}");
        Console.WriteLine(
            $"Berhasil parsial     : " +
            $"{batchData.PartialSuccessPortCount}");
        Console.WriteLine(
            $"Sumber tidak tersedia: " +
            $"{batchData.SourceUnavailablePortCount}");
        Console.WriteLine(
            $"Gagal teknis         : " +
            $"{batchData.TechnicalFailedPortCount}");
        Console.WriteLine(
            $"Total forecast       : " +
            $"{batchData.ForecastCount}");
        Console.WriteLine(
            $"Total diagnostik     : " +
            $"{batchData.ErrorCount}");
        Console.WriteLine(
            $"Error teknis         : " +
            $"{batchData.TechnicalErrorCount}");
        Console.WriteLine(
            $"Warning kualitas     : " +
            $"{batchData.QualityWarningCount}");
        Console.WriteLine(
            $"Status               : " +
            $"{batchData.Status}");
        Console.WriteLine(
            $"Metadata batch       : " +
            $"{metadataPath}");
        Console.WriteLine(
            $"Daftar sampel        : " +
            $"{selectedPortsPath}");
        Console.WriteLine(
            $"Hasil per pelabuhan  : " +
            $"{portResultsPath}");
        Console.WriteLine(
            $"Ringkasan kualitas   : " +
            $"{qualitySummaryPath}");
        Console.WriteLine(
            $"Laporan anomali      : " +
            $"{anomaliesPath}");
    }

    private sealed record PreparedRun(
        ScrapeBatchContext Batch,
        IReadOnlyList<PortData> SelectedPorts,
        List<ScrapeErrorData> Errors,
        List<PortScrapeResultData> PortResults,
        string RunType,
        string? ParentBatchId,
        string SelectionMode,
        bool SourceRetryCompleted,
        bool IsResume);
}
