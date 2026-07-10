namespace BmkgScraper.Http;

internal sealed class BmkgHttpFetcher : IHttpFetcher
{
    private readonly HttpClient _httpClient;

    public BmkgHttpFetcher(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<string> GetHtmlAsync(
        Uri url,
        CancellationToken cancellationToken = default)
    {
        using HttpResponseMessage response =
            await _httpClient.GetAsync(url, cancellationToken);

        response.EnsureSuccessStatusCode();

        return await response.Content.ReadAsStringAsync(cancellationToken);
    }
}
