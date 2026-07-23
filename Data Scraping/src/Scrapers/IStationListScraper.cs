using NdbcScraper.Models;

namespace NdbcScraper.Scrapers;

internal interface IStationListScraper
{
    Task<IReadOnlyList<StationCandidate>> ScrapeAsync(
        CancellationToken cancellationToken = default);
}
