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
        int? portLimit,
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
            SelectPorts(ports, portLimit);

        List<ScrapeErrorData> errors = [];

        int successfulPortCount = 0;
        int failedPortCount = 0;
        int totalForecastCount = 0;
        int qualityWarningCount = 0;

        Console.WriteLine();
        Console.WriteLine($"Batch ID : {batch.BatchId}");
        Console.WriteLine(
            $"Pelabuhan yang akan diproses: " +
            $"{selectedPorts.Count}");

        for (int index = 0;
             index < selectedPorts.Count;
             index++)
        {
            cancellationToken.ThrowIfCancellationRequested();

            PortData port = selectedPorts[index];

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

                await _dataWriter.WriteAsync(
                    result.Forecasts,
                    _outputPathProvider.GetPortForecastPath(
                        batch.BatchId,
                        port.PortCode),
                    cancellationToken);

                errors.AddRange(result.Errors);
                totalForecastCount +=
                    result.Forecasts.Count;

                int portWarningCount =
                    result.Forecasts.Sum(
                        forecast =>
                            forecast.QualityFlags.Count);

                qualityWarningCount +=
                    portWarningCount;

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
            }
            catch (Exception exception)
                when (exception is not OperationCanceledException)
            {
                failedPortCount++;

                errors.Add(
                    CreatePortError(
                        batch,
                        port,
                        exception.Message));

                Console.WriteLine(
                    $"Gagal: {exception.Message}");
            }

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

        string errorsPath =
            _outputPathProvider.GetBatchErrorsPath(
                batch.BatchId);

        string metadataPath =
            _outputPathProvider.GetBatchMetadataPath(
                batch.BatchId);

        await _dataWriter.WriteAsync(
            errors,
            errorsPath,
            cancellationToken);

        await _dataWriter.WriteAsync(
            batchData,
            metadataPath,
            cancellationToken);

        PrintSummary(
            batchData,
            metadataPath);
    }

    private ScrapeErrorData CreatePortError(
        ScrapeBatchContext batch,
        PortData port,
        string message)
    {
        return new ScrapeErrorData
        {
            BatchId = batch.BatchId,
            PortCode = port.PortCode,
            PortName = port.PortName,
            ErrorScope = "PORT",
            RowIndex = null,
            Message = message,
            RawData = null,
            OccurredAt =
                DateTimeOffset.UtcNow.ToOffset(
                    _localOffset)
        };
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
        int? portLimit)
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

        if (portLimit == 1)
        {
            return [ports[0]];
        }

        List<PortData> selectedPorts = [];
        HashSet<string> selectedCodes =
            new(StringComparer.OrdinalIgnoreCase);

        double interval =
            (double)(ports.Count - 1) /
            (portLimit.Value - 1);

        for (int index = 0;
             index < portLimit.Value;
             index++)
        {
            int portIndex =
                (int)Math.Round(index * interval);

            PortData port =
                ports[portIndex];

            if (selectedCodes.Add(port.PortCode))
            {
                selectedPorts.Add(port);
            }
        }

        return selectedPorts;
    }

    private static void PrintSummary(
        ScrapeBatchData batchData,
        string metadataPath)
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
    }
}
