using BmkgScraper.Models;

namespace BmkgScraper.Scrapers;

internal interface IForecastScraper
{
    Task<ForecastScrapeResult> ScrapeAsync(
        PortData port,
        ScrapeBatchContext batch,
        CancellationToken cancellationToken = default);
}
