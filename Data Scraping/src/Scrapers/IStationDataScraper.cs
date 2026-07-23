using NdbcScraper.Models;

namespace NdbcScraper.Scrapers;

internal interface IStationDataScraper
{
    Task<StationScrapeResult> ScrapeAsync(
        StationCandidate candidate,
        string scrapeRunId,
        CancellationToken cancellationToken = default);
}
