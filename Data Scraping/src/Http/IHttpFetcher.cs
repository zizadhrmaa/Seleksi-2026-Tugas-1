namespace BmkgScraper.Http;

internal interface IHttpFetcher
{
    Task<HttpFetchResult> GetHtmlAsync(
        Uri url,
        CancellationToken cancellationToken = default);
}
