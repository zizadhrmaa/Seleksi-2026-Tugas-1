using BmkgScraper.Models;

namespace BmkgScraper.Scrapers;

internal interface IPortScraper
{
    Task<IReadOnlyList<PortData>> ScrapeAsync(
        CancellationToken cancellationToken = default);
}
