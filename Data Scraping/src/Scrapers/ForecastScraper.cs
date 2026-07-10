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
            DateTimeOffset.UtcNow.ToOffset(batch.BatchStartedAt.Offset);

        for (int index = 0; index < rows.Count; index++)
        {
            ForecastRowParseResult parseResult = _rowParser.Parse(
                rows[index],
                port,
                batch,
                extractedAt);

            if (parseResult.IsSuccess)
            {
                forecasts.Add(parseResult.Forecast!);
                continue;
            }

            errors.Add(new ScrapeErrorData
            {
                BatchId = batch.BatchId,
                PortCode = port.PortCode,
                PortName = port.PortName,
                ErrorScope = "ROW",
                RowIndex = index + 1,
                Message = parseResult.ErrorMessage ?? "Unknown row parsing error.",
                RawData = parseResult.RawRowText,
                OccurredAt =
                    DateTimeOffset.UtcNow.ToOffset(batch.BatchStartedAt.Offset)
            });
        }

        return new ForecastScrapeResult(forecasts, errors);
    }
}
