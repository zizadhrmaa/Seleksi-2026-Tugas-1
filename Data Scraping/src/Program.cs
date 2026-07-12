using BmkgScraper.Http;
using BmkgScraper.Models;
using BmkgScraper.Parsers;
using BmkgScraper.Persistence;
using BmkgScraper.Scrapers;
using BmkgScraper.Services;
using BmkgScraper.Validation;

namespace BmkgScraper;

internal static class Program
{
    private static readonly Uri BaseUri =
        new("https://maritim.bmkg.go.id");

    private static readonly Uri PortListUri =
        new(BaseUri, "/cuaca/pelabuhan");

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
            ScrapeRunOptions runOptions =
                ResolveRunOptions(args);

            TimeSpan requestDelay =
                ResolveRequestDelay(args);

            using HttpClient httpClient = CreateHttpClient();

            IHttpFetcher httpFetcher = new BmkgHttpFetcher(
                httpClient,
                maxAttempts: 3,
                initialRetryDelay: TimeSpan.FromSeconds(2));

            IPortScraper portScraper = new PortScraper(
                httpFetcher,
                BaseUri,
                PortListUri);

            IForecastValidator forecastValidator =
                new ForecastValidator(
                    maxReasonableCurrentSpeedKnot: 15);

            const double currentSpeedSpikeThresholdKnot = 10;

            IForecastSeriesValidator seriesValidator =
                new ForecastSeriesValidator(
                    expectedForecastCount: 41,
                    currentSpeedSpikeThresholdKnot:
                        currentSpeedSpikeThresholdKnot,
                    laggedForecastThreshold:
                        TimeSpan.FromHours(24),
                    staleForecastThreshold:
                        TimeSpan.FromDays(7));

            MeasurementParser measurementParser =
                new(maxReasonableVisibilityKm: 100);

            IForecastRowParser rowParser =
                new ForecastRowParser(
                    measurementParser,
                    forecastValidator);

            IForecastScraper forecastScraper =
                new ForecastScraper(
                    httpFetcher,
                    rowParser,
                    seriesValidator,
                    maxContentAttempts: 2,
                    contentRetryDelay: TimeSpan.FromSeconds(3));

            OutputPathProvider outputPathProvider = new();
            IDataWriter dataWriter = new JsonDataWriter();
            IDataReader dataReader = new JsonDataReader();

            QualityReportBuilder qualityReportBuilder = new(
                currentSpeedSpikeThresholdKnot);

            ScrapeRunner runner = new(
                portScraper,
                forecastScraper,
                dataWriter,
                dataReader,
                outputPathProvider,
                qualityReportBuilder,
                requestDelay,
                sourceRetryDelay: TimeSpan.FromSeconds(30),
                localOffset: TimeSpan.FromHours(7));

            await runner.RunAsync(
                runOptions,
                cancellationTokenSource.Token);
        }
        catch (OperationCanceledException)
        {
            Console.WriteLine();
            Console.WriteLine("Proses dihentikan oleh pengguna.");
            Environment.ExitCode = 2;
        }
        catch (Exception exception)
        {
            Console.Error.WriteLine(
                $"Program gagal: {exception.Message}");

            Environment.ExitCode = 1;
        }
    }

    private static ScrapeRunOptions ResolveRunOptions(
        string[] args)
    {
        string? retryBatchId =
            ResolveOptionValue(args, "--retry-batch");

        string? resumeBatchId =
            ResolveOptionValue(args, "--resume");

        if (retryBatchId is not null &&
            resumeBatchId is not null)
        {
            throw new ArgumentException(
                "--retry-batch dan --resume tidak dapat digunakan " +
                "bersamaan.");
        }

        if (retryBatchId is not null)
        {
            EnsureNoSelectionArguments(args, "--retry-batch");

            return new ScrapeRunOptions(
                PortLimit: null,
                SelectionMode: PortSelectionMode.Spread,
                RunMode: ScrapeRunMode.RetryBatch,
                ReferenceBatchId: retryBatchId);
        }

        if (resumeBatchId is not null)
        {
            EnsureNoSelectionArguments(args, "--resume");

            return new ScrapeRunOptions(
                PortLimit: null,
                SelectionMode: PortSelectionMode.Spread,
                RunMode: ScrapeRunMode.Resume,
                ReferenceBatchId: resumeBatchId);
        }

        return new ScrapeRunOptions(
            ResolvePortLimit(args),
            ResolveSelectionMode(args),
            ScrapeRunMode.New,
            ReferenceBatchId: null);
    }

    private static void EnsureNoSelectionArguments(
        string[] args,
        string activeArgument)
    {
        string[] incompatibleArguments =
            ["--all", "--limit", "--selection"];

        if (args.Any(argument =>
                incompatibleArguments.Contains(
                    argument,
                    StringComparer.OrdinalIgnoreCase)))
        {
            throw new ArgumentException(
                $"{activeArgument} tidak dapat digabungkan dengan " +
                "--all, --limit, atau --selection.");
        }
    }

    private static string? ResolveOptionValue(
        string[] args,
        string optionName)
    {
        int optionIndex = Array.FindIndex(
            args,
            argument => argument.Equals(
                optionName,
                StringComparison.OrdinalIgnoreCase));

        if (optionIndex < 0)
        {
            return null;
        }

        if (optionIndex + 1 >= args.Length ||
            string.IsNullOrWhiteSpace(args[optionIndex + 1]) ||
            args[optionIndex + 1].StartsWith("--"))
        {
            throw new ArgumentException(
                $"{optionName} membutuhkan batch ID.");
        }

        return args[optionIndex + 1].Trim();
    }

    private static HttpClient CreateHttpClient()
    {
        HttpClient client = new()
        {
            Timeout = TimeSpan.FromSeconds(30)
        };

        client.DefaultRequestHeaders.TryAddWithoutValidation(
            "User-Agent",
            "BasisDataSelectionScraper/2.2 " +
            "(educational project; contact: " +
            "13524017@std.stei.itb.ac.id)");

        client.DefaultRequestHeaders.TryAddWithoutValidation(
            "Accept-Language",
            "id-ID,id;q=0.9,en;q=0.8");

        return client;
    }

    private static int? ResolvePortLimit(string[] args)
    {
        if (args.Any(argument =>
                argument.Equals(
                    "--all",
                    StringComparison.OrdinalIgnoreCase)))
        {
            return null;
        }

        int limitArgumentIndex = Array.FindIndex(
            args,
            argument => argument.Equals(
                "--limit",
                StringComparison.OrdinalIgnoreCase));

        int limit = 0;

        bool hasValidLimit =
            limitArgumentIndex >= 0 &&
            limitArgumentIndex + 1 < args.Length &&
            int.TryParse(
                args[limitArgumentIndex + 1],
                out limit) &&
            limit > 0;

        return hasValidLimit ? limit : 10;
    }

    private static PortSelectionMode ResolveSelectionMode(
        string[] args)
    {
        int selectionArgumentIndex = Array.FindIndex(
            args,
            argument => argument.Equals(
                "--selection",
                StringComparison.OrdinalIgnoreCase));

        if (selectionArgumentIndex < 0 ||
            selectionArgumentIndex + 1 >= args.Length)
        {
            return PortSelectionMode.Spread;
        }

        string selectionValue =
            args[selectionArgumentIndex + 1];

        return selectionValue.ToLowerInvariant() switch
        {
            "spread" => PortSelectionMode.Spread,
            "sequential" => PortSelectionMode.Sequential,
            _ => throw new ArgumentException(
                "Nilai --selection harus 'spread' " +
                "atau 'sequential'.")
        };
    }

    private static TimeSpan ResolveRequestDelay(string[] args)
    {
        int delayArgumentIndex = Array.FindIndex(
            args,
            argument => argument.Equals(
                "--delay-seconds",
                StringComparison.OrdinalIgnoreCase));

        double delaySeconds = 0;

        bool hasValidDelay =
            delayArgumentIndex >= 0 &&
            delayArgumentIndex + 1 < args.Length &&
            double.TryParse(
                args[delayArgumentIndex + 1],
                out delaySeconds) &&
            delaySeconds >= 0;

        return hasValidDelay
            ? TimeSpan.FromSeconds(delaySeconds)
            : TimeSpan.FromSeconds(2);
    }
}
