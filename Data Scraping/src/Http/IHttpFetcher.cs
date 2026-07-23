namespace NdbcScraper.Http;

internal interface IHttpFetcher
{
    Task<HttpFetchResult> GetStringAsync(
        Uri url,
        CancellationToken cancellationToken = default);
}
