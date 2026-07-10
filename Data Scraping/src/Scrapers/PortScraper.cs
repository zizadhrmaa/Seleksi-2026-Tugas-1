using System.Text.RegularExpressions;
using BmkgScraper.Http;
using BmkgScraper.Models;
using BmkgScraper.Parsers;
using HtmlAgilityPack;

namespace BmkgScraper.Scrapers;

internal sealed class PortScraper : IPortScraper
{
    private readonly IHttpFetcher _httpFetcher;
    private readonly Uri _baseUri;
    private readonly Uri _portListUri;

    public PortScraper(
        IHttpFetcher httpFetcher,
        Uri baseUri,
        Uri portListUri)
    {
        _httpFetcher = httpFetcher;
        _baseUri = baseUri;
        _portListUri = portListUri;
    }

    public async Task<IReadOnlyList<PortData>> ScrapeAsync(
        CancellationToken cancellationToken = default)
    {
        string html =
            await _httpFetcher.GetHtmlAsync(_portListUri, cancellationToken);

        HtmlDocument document = new();
        document.LoadHtml(html);

        HtmlNodeCollection? anchorNodes =
            document.DocumentNode.SelectNodes("//a[@href]");

        if (anchorNodes is null)
        {
            return [];
        }

        Dictionary<string, PortData> uniquePorts =
            new(StringComparer.OrdinalIgnoreCase);

        foreach (HtmlNode anchor in anchorNodes)
        {
            string href =
                anchor.GetAttributeValue("href", string.Empty).Trim();

            if (string.IsNullOrWhiteSpace(href))
            {
                continue;
            }

            if (!TryCreateDetailUri(href, out Uri detailUri))
            {
                continue;
            }

            string portCode = detailUri.AbsolutePath
                .TrimEnd('/')
                .Split('/', StringSplitOptions.RemoveEmptyEntries)
                .Last();

            string portName = Regex.Replace(
                    TextNormalizer.Clean(anchor.InnerText),
                    @"\s*Lihat detail cuaca\s*",
                    string.Empty,
                    RegexOptions.IgnoreCase)
                .Trim();

            if (string.IsNullOrWhiteSpace(portName))
            {
                continue;
            }

            uniquePorts[detailUri.AbsoluteUri] = new PortData
            {
                PortCode = portCode,
                PortName = portName,
                DetailUrl = detailUri.AbsoluteUri
            };
        }

        return uniquePorts.Values
            .OrderBy(port => port.PortName)
            .ToList();
    }

    private bool TryCreateDetailUri(string href, out Uri detailUri)
    {
        try
        {
            detailUri = new Uri(_baseUri, href);
        }
        catch (UriFormatException)
        {
            detailUri = null!;
            return false;
        }

        bool isSameHost = detailUri.Host.Equals(
            _baseUri.Host,
            StringComparison.OrdinalIgnoreCase);

        bool isPortDetailPath = detailUri.AbsolutePath
            .TrimEnd('/')
            .StartsWith(
                "/cuaca/pelabuhan/",
                StringComparison.OrdinalIgnoreCase);

        return isSameHost && isPortDetailPath;
    }
}
