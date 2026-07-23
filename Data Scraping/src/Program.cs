using System.Net;
using NdbcScraper.Configuration;
using NdbcScraper.Http;
using NdbcScraper.Parsing;
using NdbcScraper.Persistence;
using NdbcScraper.Scrapers;
using NdbcScraper.Services;
using NdbcScraper.Validation;

namespace NdbcScraper;

internal static class Program
{
    private static readonly Uri BaseUri = new("https://www.ndbc.noaa.gov");
    private static readonly Uri StationListUri = new(BaseUri, "/to_station.shtml");

    private static async Task Main(string[] args)
    {
        using CancellationTokenSource cancellationTokenSource = new();

        Console.CancelKeyPress += (_, eventArgs) =>
        {
            eventArgs.Cancel = true;
            cancellationTokenSource.Cancel();
        };

        try
        {
            ScrapeOptions options = ScrapeOptions.Parse(args);
            OutputPathProvider outputPaths = new(options.OutputDirectory);

            using HttpClient httpClient = CreateHttpClient();

            IHttpFetcher httpFetcher = new NdbcHttpFetcher(
                httpClient,
                maxAttempts: 3,
                initialRetryDelay: TimeSpan.FromSeconds(2),
                minimumRequestInterval: options.RequestDelay);

            StationListParser stationListParser = new(BaseUri);
            StationMetadataParser stationMetadataParser = new(BaseUri);
            ObservationQualityValidator observationValidator = new();
            ObservationParser observationParser = new(observationValidator);

            IStationListScraper stationListScraper = new StationListScraper(
                httpFetcher,
                stationListParser,
                StationListUri);

            IStationDataScraper stationDataScraper = new StationDataScraper(
                httpFetcher,
                stationMetadataParser,
                observationParser);

            JsonFileStore fileStore = new();
            RobotsPolicyChecker robotsPolicyChecker = new(httpFetcher, BaseUri);

            ScrapeRunner runner = new(
                stationListScraper,
                stationDataScraper,
                robotsPolicyChecker,
                fileStore,
                outputPaths);

            bool targetMet = await runner.RunAsync(
                options,
                cancellationTokenSource.Token);

            if (!targetMet)
            {
                Environment.ExitCode = 3;
            }
        }
        catch (OperationCanceledException)
        {
            Console.WriteLine();
            Console.WriteLine("Proses dihentikan. Checkpoint terakhir sudah tersimpan.");
            Environment.ExitCode = 2;
        }
        catch (ArgumentException exception)
        {
            Console.Error.WriteLine($"Argumen tidak valid: {exception.Message}");
            Environment.ExitCode = 1;
        }
        catch (Exception exception)
        {
            Console.Error.WriteLine($"Program gagal: {exception.Message}");
            Environment.ExitCode = 1;
        }
    }

    private static HttpClient CreateHttpClient()
    {
        SocketsHttpHandler handler = new()
        {
            AutomaticDecompression =
                DecompressionMethods.GZip |
                DecompressionMethods.Deflate |
                DecompressionMethods.Brotli
        };

        HttpClient client = new(handler)
        {
            Timeout = TimeSpan.FromSeconds(45)
        };

        client.DefaultRequestHeaders.TryAddWithoutValidation(
            "User-Agent",
            "BasisDataSelectionScraper/3.0 " +
            "(educational project; contact: " +
            "13524017@std.stei.itb.ac.id)");

        client.DefaultRequestHeaders.TryAddWithoutValidation(
            "Accept",
            "text/html,text/plain;q=0.9,*/*;q=0.8");

        client.DefaultRequestHeaders.TryAddWithoutValidation(
            "Accept-Language",
            "en-US,en;q=0.9");

        return client;
    }
}
