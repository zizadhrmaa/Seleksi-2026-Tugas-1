using NdbcScraper.Http;
using NdbcScraper.Models;
using NdbcScraper.Parsing;

namespace NdbcScraper.Scrapers;

internal sealed class StationListScraper : IStationListScraper
{
    private readonly IHttpFetcher _httpFetcher;
    private readonly StationListParser _parser;
    private readonly Uri _stationListUri;

    public StationListScraper(
        IHttpFetcher httpFetcher,
        StationListParser parser,
        Uri stationListUri)
    {
        _httpFetcher = httpFetcher;
        _parser = parser;
        _stationListUri = stationListUri;
    }

    public async Task<IReadOnlyList<StationCandidate>> ScrapeAsync(
        CancellationToken cancellationToken = default)
    {
        HttpFetchResult result = await _httpFetcher.GetStringAsync(
            _stationListUri,
            cancellationToken);

        return _parser.Parse(result.Content);
    }
}
