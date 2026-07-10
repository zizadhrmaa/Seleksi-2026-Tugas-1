namespace BmkgScraper.Http;

internal interface IHttpFetcher
{
    Task<string> GetHtmlAsync(
        Uri url,
        CancellationToken cancellationToken = default);
}
