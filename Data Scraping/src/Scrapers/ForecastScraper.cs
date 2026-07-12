using BmkgScraper.Http;
using BmkgScraper.Models;
using BmkgScraper.Parsers;
using HtmlAgilityPack;

namespace BmkgScraper.Scrapers;

internal sealed class ForecastScraper : IForecastScraper
{
    private readonly IHttpFetcher _httpFetcher;
    private readonly IForecastRowParser _rowParser;

    public ForecastScraper(
        IHttpFetcher httpFetcher,
        IForecastRowParser rowParser)
    {
        _httpFetcher = httpFetcher;
        _rowParser = rowParser;
    }

    public async Task<ForecastScrapeResult> ScrapeAsync(
        PortData port,
        ScrapeBatchContext batch,
        CancellationToken cancellationToken = default)
    {
        string html = await _httpFetcher.GetHtmlAsync(
            new Uri(port.DetailUrl),
            cancellationToken);

        HtmlDocument document = new();
        document.LoadHtml(html);

        HtmlNodeCollection? rows =
            document.DocumentNode.SelectNodes("//table//tr[td]");

        if (rows is null || rows.Count == 0)
        {
            throw new InvalidOperationException(
                $"Tidak ditemukan data prakiraan untuk {port.PortName}.");
        }

        List<ForecastData> forecasts = [];
        List<ScrapeErrorData> errors = [];

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
                parseResult));
        }

        if (forecasts.Count == 0 && errors.Count == 0)
        {
            errors.Add(new ScrapeErrorData
            {
                BatchId = batch.BatchId,
                PortCode = port.PortCode,
                PortName = port.PortName,
                ErrorScope = "PORT",
                RowIndex = null,
                Message =
                    "Halaman tidak menyediakan data prakiraan " +
                    "yang dapat diproses.",
                RawData = null,
                OccurredAt =
                    DateTimeOffset.UtcNow.ToOffset(
                        batch.BatchStartedAt.Offset)
            });
        }

        return new ForecastScrapeResult(forecasts, errors);
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
        ForecastRowParseResult parseResult)
    {
        return new ScrapeErrorData
        {
            BatchId = batch.BatchId,
            PortCode = port.PortCode,
            PortName = port.PortName,
            ErrorScope = "ROW",
            RowIndex = rowIndex,
            Message =
                parseResult.ErrorMessage ??
                "Unknown row parsing error.",
            RawData = parseResult.RawRowText,
            OccurredAt =
                DateTimeOffset.UtcNow.ToOffset(
                    batch.BatchStartedAt.Offset)
        };
    }
}
