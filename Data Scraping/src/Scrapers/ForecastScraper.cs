using System.Diagnostics;
using BmkgScraper.Http;
using BmkgScraper.Models;
using BmkgScraper.Parsers;
using BmkgScraper.Validation;
using HtmlAgilityPack;

namespace BmkgScraper.Scrapers;

internal sealed class ForecastScraper : IForecastScraper
{
    private readonly IHttpFetcher _httpFetcher;
    private readonly IForecastRowParser _rowParser;
    private readonly IForecastSeriesValidator _seriesValidator;
    private readonly int _maxContentAttempts;
    private readonly TimeSpan _contentRetryDelay;

    public ForecastScraper(
        IHttpFetcher httpFetcher,
        IForecastRowParser rowParser,
        IForecastSeriesValidator seriesValidator,
        int maxContentAttempts,
        TimeSpan contentRetryDelay)
    {
        if (maxContentAttempts <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(maxContentAttempts));
        }

        if (contentRetryDelay < TimeSpan.Zero)
        {
            throw new ArgumentOutOfRangeException(
                nameof(contentRetryDelay));
        }

        _httpFetcher = httpFetcher;
        _rowParser = rowParser;
        _seriesValidator = seriesValidator;
        _maxContentAttempts = maxContentAttempts;
        _contentRetryDelay = contentRetryDelay;
    }

    public async Task<ForecastScrapeResult> ScrapeAsync(
        PortData port,
        ScrapeBatchContext batch,
        CancellationToken cancellationToken = default)
    {
        Stopwatch stopwatch = Stopwatch.StartNew();
        int totalAttemptCount = 0;
        HttpFetchResult? lastFetchResult = null;
        HtmlNodeCollection? rows = null;
        string lastHtml = string.Empty;

        for (int contentAttempt = 1;
             contentAttempt <= _maxContentAttempts;
             contentAttempt++)
        {
            try
            {
                lastFetchResult = await _httpFetcher.GetHtmlAsync(
                    new Uri(port.DetailUrl),
                    cancellationToken);
            }
            catch (HttpFetchException exception)
            {
                stopwatch.Stop();

                return CreatePortFailureResult(
                    port,
                    batch,
                    ScrapeErrorCodes.HttpRequestFailed,
                    exception.Message,
                    totalAttemptCount + exception.AttemptCount,
                    exception.StatusCode is null
                        ? null
                        : (int)exception.StatusCode,
                    stopwatch.ElapsedMilliseconds,
                    tableRowCount: null);
            }

            totalAttemptCount += lastFetchResult.AttemptCount;
            lastHtml = lastFetchResult.Html;

            HtmlDocument document = new();
            document.LoadHtml(lastHtml);

            rows = document.DocumentNode.SelectNodes(
                "//table//tr[td]");

            if (rows is not null && rows.Count > 0)
            {
                break;
            }

            if (contentAttempt < _maxContentAttempts)
            {
                await Task.Delay(
                    _contentRetryDelay,
                    cancellationToken);
            }
        }

        if (rows is null || rows.Count == 0)
        {
            stopwatch.Stop();

            bool sourceStillLoading =
                IsPageStillLoading(lastHtml);

            string errorCode = sourceStillLoading
                ? ScrapeErrorCodes.SourcePageLoading
                : ScrapeErrorCodes.ForecastTableNotFound;

            string message = sourceStillLoading
                ? "Halaman masih menampilkan status loading setelah " +
                  "percobaan ulang."
                : "Tabel prakiraan tidak ditemukan pada halaman sumber.";

            return CreatePortFailureResult(
                port,
                batch,
                errorCode,
                message,
                totalAttemptCount,
                lastFetchResult is null
                    ? null
                    : (int)lastFetchResult.StatusCode,
                stopwatch.ElapsedMilliseconds,
                tableRowCount: 0);
        }

        HttpFetchResult fetchResult = lastFetchResult ??
            throw new InvalidOperationException(
                "Metadata HTTP tidak tersedia setelah halaman berhasil diproses.");

        List<ForecastData> forecasts = [];
        List<ScrapeErrorData> errors = [];
        int nonEmptyRowCount = 0;

        DateTimeOffset extractedAt =
            DateTimeOffset.UtcNow.ToOffset(
                batch.BatchStartedAt.Offset);

        for (int index = 0; index < rows.Count; index++)
        {
            HtmlNode row = rows[index];

            if (IsEmptyRow(row))
            {
                continue;
            }

            nonEmptyRowCount++;

            ForecastRowParseResult parseResult = _rowParser.Parse(
                row,
                port,
                batch,
                extractedAt);

            if (parseResult.IsSuccess)
            {
                forecasts.Add(parseResult.Forecast!);
                continue;
            }

            errors.Add(CreateRowError(
                port,
                batch,
                index + 1,
                parseResult,
                rows.Count));
        }

        if (nonEmptyRowCount == 0)
        {
            errors.Add(CreatePortError(
                port,
                batch,
                ScrapeErrorCodes.AllRowsEmpty,
                "Seluruh baris pada tabel prakiraan kosong.",
                totalAttemptCount,
                (int)fetchResult.StatusCode,
                stopwatch.ElapsedMilliseconds,
                rows.Count));
        }
        else if (forecasts.Count == 0)
        {
            errors.Add(CreatePortError(
                port,
                batch,
                ScrapeErrorCodes.AllRowsInvalid,
                "Seluruh baris prakiraan gagal diproses.",
                totalAttemptCount,
                (int)fetchResult.StatusCode,
                stopwatch.ElapsedMilliseconds,
                rows.Count));
        }

        IReadOnlyList<string> seriesQualityFlags =
            forecasts.Count == 0
                ? []
                : _seriesValidator.Validate(forecasts);

        stopwatch.Stop();

        return new ForecastScrapeResult(
            forecasts,
            errors,
            seriesQualityFlags,
            totalAttemptCount,
            (int)fetchResult.StatusCode,
            stopwatch.ElapsedMilliseconds,
            rows.Count);
    }

    private static ForecastScrapeResult CreatePortFailureResult(
        PortData port,
        ScrapeBatchContext batch,
        string errorCode,
        string message,
        int attemptCount,
        int? httpStatusCode,
        long durationMilliseconds,
        int? tableRowCount)
    {
        ScrapeErrorData error = CreatePortError(
            port,
            batch,
            errorCode,
            message,
            attemptCount,
            httpStatusCode,
            durationMilliseconds,
            tableRowCount);

        return new ForecastScrapeResult(
            [],
            [error],
            [],
            attemptCount,
            httpStatusCode,
            durationMilliseconds,
            tableRowCount ?? 0);
    }

    private static bool IsPageStillLoading(string html)
    {
        if (string.IsNullOrWhiteSpace(html))
        {
            return false;
        }

        return html.Contains(
                   "Loading...",
                   StringComparison.OrdinalIgnoreCase) ||
               html.Contains(
                   "loading",
                   StringComparison.OrdinalIgnoreCase) &&
               !html.Contains(
                   "<table",
                   StringComparison.OrdinalIgnoreCase);
    }

    private static bool IsEmptyRow(HtmlNode row)
    {
        string text = TextNormalizer.Clean(row.InnerText);

        if (!string.IsNullOrWhiteSpace(text))
        {
            return false;
        }

        HtmlNodeCollection? images =
            row.SelectNodes(".//img[@alt]");

        if (images is null)
        {
            return true;
        }

        return images.All(image =>
            string.IsNullOrWhiteSpace(
                image.GetAttributeValue(
                    "alt",
                    string.Empty)));
    }

    private static ScrapeErrorData CreateRowError(
        PortData port,
        ScrapeBatchContext batch,
        int rowIndex,
        ForecastRowParseResult parseResult,
        int tableRowCount)
    {
        return new ScrapeErrorData
        {
            BatchId = batch.BatchId,
            PortCode = port.PortCode,
            PortName = port.PortName,
            ErrorScope = "ROW",
            ErrorCode =
                parseResult.ErrorCode ??
                ScrapeErrorCodes.RowParseFailed,
            RowIndex = rowIndex,
            Message =
                parseResult.ErrorMessage ??
                "Unknown row parsing error.",
            RawData = parseResult.RawRowText,
            HttpStatusCode = null,
            AttemptCount = null,
            DurationMilliseconds = null,
            TableRowCount = tableRowCount,
            OccurredAt =
                DateTimeOffset.UtcNow.ToOffset(
                    batch.BatchStartedAt.Offset)
        };
    }

    private static ScrapeErrorData CreatePortError(
        PortData port,
        ScrapeBatchContext batch,
        string errorCode,
        string message,
        int attemptCount,
        int? httpStatusCode,
        long durationMilliseconds,
        int? tableRowCount)
    {
        return new ScrapeErrorData
        {
            BatchId = batch.BatchId,
            PortCode = port.PortCode,
            PortName = port.PortName,
            ErrorScope = "PORT",
            ErrorCode = errorCode,
            RowIndex = null,
            Message = message,
            RawData = null,
            HttpStatusCode = httpStatusCode,
            AttemptCount = attemptCount,
            DurationMilliseconds = durationMilliseconds,
            TableRowCount = tableRowCount,
            OccurredAt =
                DateTimeOffset.UtcNow.ToOffset(
                    batch.BatchStartedAt.Offset)
        };
    }
}
