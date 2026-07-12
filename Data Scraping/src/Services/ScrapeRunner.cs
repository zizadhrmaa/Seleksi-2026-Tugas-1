using System.Diagnostics;
using BmkgScraper.Models;
using BmkgScraper.Persistence;
using BmkgScraper.Scrapers;

namespace BmkgScraper.Services;

internal sealed class ScrapeRunner
{
    private readonly IPortScraper _portScraper;
    private readonly IForecastScraper _forecastScraper;
    private readonly IDataWriter _dataWriter;
    private readonly OutputPathProvider _outputPathProvider;
    private readonly TimeSpan _requestDelay;
    private readonly TimeSpan _localOffset;

    public ScrapeRunner(
        IPortScraper portScraper,
        IForecastScraper forecastScraper,
        IDataWriter dataWriter,
        OutputPathProvider outputPathProvider,
        TimeSpan requestDelay,
        TimeSpan localOffset)
    {
        _portScraper = portScraper;
        _forecastScraper = forecastScraper;
        _dataWriter = dataWriter;
        _outputPathProvider = outputPathProvider;
        _requestDelay = requestDelay;
        _localOffset = localOffset;
    }

    public async Task RunAsync(
        ScrapeRunOptions options,
        CancellationToken cancellationToken = default)
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

        IReadOnlyList<PortData> selectedPorts =
            SelectPorts(
                ports,
                options.PortLimit,
                options.SelectionMode);

        string selectedPortsPath =
            _outputPathProvider.GetSelectedPortsPath(
                batch.BatchId);

        string errorsPath =
            _outputPathProvider.GetBatchErrorsPath(
                batch.BatchId);

        string portResultsPath =
            _outputPathProvider.GetPortResultsPath(
                batch.BatchId);

        string metadataPath =
            _outputPathProvider.GetBatchMetadataPath(
                batch.BatchId);

        await _dataWriter.WriteAsync(
            selectedPorts,
            selectedPortsPath,
            cancellationToken);

        List<ScrapeErrorData> errors = [];
        List<PortScrapeResultData> portResults = [];

        int successfulPortCount = 0;
        int failedPortCount = 0;
        int totalForecastCount = 0;
        int qualityWarningCount = 0;

        Console.WriteLine();
        Console.WriteLine($"Batch ID : {batch.BatchId}");
        Console.WriteLine(
            $"Mode pemilihan pelabuhan: " +
            $"{options.SelectionMode.ToString().ToUpperInvariant()}");
        Console.WriteLine(
            $"Pelabuhan yang akan diproses: " +
            $"{selectedPorts.Count}");

        for (int index = 0;
             index < selectedPorts.Count;
             index++)
        {
            cancellationToken.ThrowIfCancellationRequested();

            PortData port = selectedPorts[index];
            Stopwatch portStopwatch = Stopwatch.StartNew();

            Console.WriteLine();
            Console.WriteLine(
                $"[{index + 1}/{selectedPorts.Count}] " +
                $"{port.PortName}");

            try
            {
                ForecastScrapeResult result =
                    await _forecastScraper.ScrapeAsync(
                        port,
                        batch,
                        cancellationToken);

                portStopwatch.Stop();

                await _dataWriter.WriteAsync(
                    result.Forecasts,
                    _outputPathProvider.GetPortForecastPath(
                        batch.BatchId,
                        port.PortCode),
                    cancellationToken);

                errors.AddRange(result.Errors);
                totalForecastCount +=
                    result.Forecasts.Count;

                int rowWarningCount =
                    result.Forecasts.Sum(
                        forecast =>
                            forecast.QualityFlags.Count);

                int portWarningCount =
                    rowWarningCount +
                    result.SeriesQualityFlags.Count;

                qualityWarningCount += portWarningCount;

                string portStatus = ResolvePortStatus(
                    result.Forecasts.Count,
                    result.Errors,
                    portWarningCount);

                if (result.Forecasts.Count == 0)
                {
                    failedPortCount++;

                    Console.WriteLine(
                        $"Gagal: tidak ada record valid, " +
                        $"{result.Errors.Count} masalah.");
                }
                else
                {
                    successfulPortCount++;

                    Console.WriteLine(
                        $"Berhasil: {result.Forecasts.Count} record, " +
                        $"{result.Errors.Count} masalah, " +
                        $"{portWarningCount} warning kualitas.");
                }

                if (result.SeriesQualityFlags.Count > 0)
                {
                    Console.WriteLine(
                        "Warning seri: " +
                        string.Join(
                            ", ",
                            result.SeriesQualityFlags));
                }

                portResults.Add(new PortScrapeResultData
                {
                    BatchId = batch.BatchId,
                    PortCode = port.PortCode,
                    PortName = port.PortName,
                    Status = portStatus,
                    ForecastCount = result.Forecasts.Count,
                    ErrorCount = result.Errors.Count,
                    QualityWarningCount = portWarningCount,
                    SeriesQualityFlags =
                        result.SeriesQualityFlags,
                    AttemptCount = result.AttemptCount,
                    HttpStatusCode = result.HttpStatusCode,
                    DurationMilliseconds =
                        result.DurationMilliseconds,
                    ProcessedAt =
                        DateTimeOffset.UtcNow.ToOffset(
                            _localOffset)
                });
            }
            catch (Exception exception)
                when (exception is not OperationCanceledException)
            {
                portStopwatch.Stop();
                failedPortCount++;

                ScrapeErrorData error = CreatePortError(
                    batch,
                    port,
                    exception.Message,
                    portStopwatch.ElapsedMilliseconds);

                errors.Add(error);

                await _dataWriter.WriteAsync(
                    Array.Empty<ForecastData>(),
                    _outputPathProvider.GetPortForecastPath(
                        batch.BatchId,
                        port.PortCode),
                    cancellationToken);

                portResults.Add(new PortScrapeResultData
                {
                    BatchId = batch.BatchId,
                    PortCode = port.PortCode,
                    PortName = port.PortName,
                    Status = PortScrapeStatusCodes.Failed,
                    ForecastCount = 0,
                    ErrorCount = 1,
                    QualityWarningCount = 0,
                    SeriesQualityFlags = [],
                    AttemptCount = 0,
                    HttpStatusCode = null,
                    DurationMilliseconds =
                        portStopwatch.ElapsedMilliseconds,
                    ProcessedAt =
                        DateTimeOffset.UtcNow.ToOffset(
                            _localOffset)
                });

                Console.WriteLine(
                    $"Gagal: {exception.Message}");
            }

            await _dataWriter.WriteAsync(
                errors,
                errorsPath,
                cancellationToken);

            await _dataWriter.WriteAsync(
                portResults,
                portResultsPath,
                cancellationToken);

            if (index < selectedPorts.Count - 1 &&
                _requestDelay > TimeSpan.Zero)
            {
                Console.WriteLine(
                    $"Menunggu " +
                    $"{_requestDelay.TotalSeconds:0.##} " +
                    "detik...");

                await Task.Delay(
                    _requestDelay,
                    cancellationToken);
            }
        }

        ScrapeBatchData batchData = new()
        {
            BatchId = batch.BatchId,
            BatchStartedAt =
                batch.BatchStartedAt,
            BatchFinishedAt =
                DateTimeOffset.UtcNow.ToOffset(
                    _localOffset),
            SelectionMode =
                options.SelectionMode
                    .ToString()
                    .ToUpperInvariant(),
            RequestedPortCount =
                selectedPorts.Count,
            SuccessfulPortCount =
                successfulPortCount,
            FailedPortCount =
                failedPortCount,
            ForecastCount =
                totalForecastCount,
            ErrorCount =
                errors.Count,
            QualityWarningCount =
                qualityWarningCount,
            Status = ResolveBatchStatus(
                failedPortCount,
                errors.Count,
                qualityWarningCount)
        };

        await _dataWriter.WriteAsync(
            batchData,
            metadataPath,
            cancellationToken);

        PrintSummary(
            batchData,
            metadataPath,
            selectedPortsPath,
            portResultsPath);
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

    private static string ResolvePortStatus(
        int forecastCount,
        IReadOnlyList<ScrapeErrorData> errors,
        int qualityWarningCount)
    {
        if (forecastCount == 0)
        {
            bool sourceUnavailable = errors.Any(error =>
                error.ErrorCode is
                    ScrapeErrorCodes.HttpRequestFailed or
                    ScrapeErrorCodes.SourcePageLoading or
                    ScrapeErrorCodes.ForecastTableNotFound or
                    ScrapeErrorCodes.AllRowsEmpty);

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

    private static string ResolveBatchStatus(
        int failedPortCount,
        int errorCount,
        int qualityWarningCount)
    {
        if (failedPortCount > 0)
        {
            return "COMPLETED_WITH_ERRORS";
        }

        return errorCount > 0 ||
               qualityWarningCount > 0
            ? "COMPLETED_WITH_WARNINGS"
            : "COMPLETED";
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

    private static void PrintSummary(
        ScrapeBatchData batchData,
        string metadataPath,
        string selectedPortsPath,
        string portResultsPath)
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
            $"Mode pemilihan       : " +
            $"{batchData.SelectionMode}");
        Console.WriteLine(
            $"Pelabuhan diminta    : " +
            $"{batchData.RequestedPortCount}");
        Console.WriteLine(
            $"Pelabuhan berhasil   : " +
            $"{batchData.SuccessfulPortCount}");
        Console.WriteLine(
            $"Pelabuhan gagal      : " +
            $"{batchData.FailedPortCount}");
        Console.WriteLine(
            $"Total forecast       : " +
            $"{batchData.ForecastCount}");
        Console.WriteLine(
            $"Total error          : " +
            $"{batchData.ErrorCount}");
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
    }
}
