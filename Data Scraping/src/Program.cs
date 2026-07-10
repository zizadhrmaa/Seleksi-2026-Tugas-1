using BmkgScraper.Http;
using BmkgScraper.Parsers;
using BmkgScraper.Persistence;
using BmkgScraper.Scrapers;
using BmkgScraper.Services;
using BmkgScraper.Validation;

namespace BmkgScraper;

internal static class Program
{
    private static readonly Uri BaseUri = new("https://maritim.bmkg.go.id");
    private static readonly Uri PortListUri = new(BaseUri, "/cuaca/pelabuhan");

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
            int? portLimit = ResolvePortLimit(args);
            TimeSpan requestDelay = ResolveRequestDelay(args);

            using HttpClient httpClient = CreateHttpClient();

            IHttpFetcher httpFetcher = new BmkgHttpFetcher(httpClient);
            IPortScraper portScraper = new PortScraper(httpFetcher, BaseUri, PortListUri);

            IForecastValidator forecastValidator = new ForecastValidator();
            MeasurementParser measurementParser = new(maxReasonableVisibilityKm: 100);
            IForecastRowParser rowParser =
                new ForecastRowParser(measurementParser, forecastValidator);

            IForecastScraper forecastScraper =
                new ForecastScraper(httpFetcher, rowParser);

            OutputPathProvider outputPathProvider = new();
            IDataWriter dataWriter = new JsonDataWriter();

            ScrapeRunner runner = new(
                portScraper,
                forecastScraper,
                dataWriter,
                outputPathProvider,
                requestDelay,
                TimeSpan.FromHours(7));

            await runner.RunAsync(portLimit, cancellationTokenSource.Token);
        }
        catch (OperationCanceledException)
        {
            Console.WriteLine();
            Console.WriteLine("Proses dihentikan oleh pengguna.");
            Environment.ExitCode = 2;
        }
        catch (Exception exception)
        {
            Console.Error.WriteLine($"Program gagal: {exception.Message}");
            Environment.ExitCode = 1;
        }
    }

    private static HttpClient CreateHttpClient()
    {
        HttpClient client = new()
        {
            Timeout = TimeSpan.FromSeconds(30)
        };

        client.DefaultRequestHeaders.TryAddWithoutValidation(
            "User-Agent",
            "BasisDataSelectionScraper/2.0 " +
            "(educational project; contact: 13524017@std.stei.itb.ac.id)");

        client.DefaultRequestHeaders.TryAddWithoutValidation(
            "Accept-Language",
            "id-ID,id;q=0.9,en;q=0.8");

        return client;
    }

    private static int? ResolvePortLimit(string[] args)
    {
        if (args.Any(argument =>
                argument.Equals("--all", StringComparison.OrdinalIgnoreCase)))
        {
            return null;
        }

        int limitArgumentIndex = Array.FindIndex(
            args,
            argument => argument.Equals("--limit", StringComparison.OrdinalIgnoreCase));

        int limit = 0;

        bool hasValidLimit =
            limitArgumentIndex >= 0 &&
            limitArgumentIndex + 1 < args.Length &&
            int.TryParse(args[limitArgumentIndex + 1], out limit) &&
            limit > 0;

        // Sepuluh pelabuhan digunakan sebagai batas aman saat argumen tidak diberikan.
        return hasValidLimit ? limit : 10;
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
            double.TryParse(args[delayArgumentIndex + 1], out delaySeconds) &&
            delaySeconds >= 0;

        return hasValidDelay
            ? TimeSpan.FromSeconds(delaySeconds)
            : TimeSpan.FromSeconds(2);
    }
}
