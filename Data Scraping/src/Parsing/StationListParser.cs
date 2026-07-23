using System.Text.RegularExpressions;
using HtmlAgilityPack;
using NdbcScraper.Models;
using NdbcScraper.Utilities;

namespace NdbcScraper.Parsing;

internal sealed partial class StationListParser
{
    private const string TargetHeading =
        "National Data Buoy Center Stations";

    private readonly Uri _baseUri;

    public StationListParser(Uri baseUri)
    {
        _baseUri = baseUri;
    }

    public IReadOnlyList<StationCandidate> Parse(string html)
    {
        HtmlDocument document = new();
        document.LoadHtml(html);

        HtmlNode? heading = document.DocumentNode
            .SelectNodes("//h2")?
            .FirstOrDefault(node => TextNormalizer.Clean(node.InnerText)
                .Equals(TargetHeading, StringComparison.OrdinalIgnoreCase));

        if (heading is null)
        {
            throw new InvalidOperationException(
                $"Bagian '{TargetHeading}' tidak ditemukan.");
        }

        List<StationCandidate> candidates = new();
        HashSet<string> seenStationIds = new(
            StringComparer.OrdinalIgnoreCase);

        for (HtmlNode? node = heading.NextSibling;
             node is not null;
             node = node.NextSibling)
        {
            if (IsHeading(node))
            {
                break;
            }

            foreach (HtmlNode link in GetLinks(node))
            {
                string href = HtmlEntity.DeEntitize(
                    link.GetAttributeValue("href", string.Empty));

                Match match = StationIdQueryRegex().Match(href);

                if (!match.Success)
                {
                    continue;
                }

                string stationId = match.Groups[1].Value
                    .Trim()
                    .ToUpperInvariant();

                if (!seenStationIds.Add(stationId))
                {
                    continue;
                }

                Uri detailUri = new(_baseUri, href);

                candidates.Add(new StationCandidate(
                    stationId,
                    detailUri.AbsoluteUri));
            }
        }

        if (candidates.Count == 0)
        {
            throw new InvalidOperationException(
                "Tidak ada station ID yang berhasil dibaca dari bagian NDBC.");
        }

        return candidates;
    }

    private static bool IsHeading(HtmlNode node)
    {
        return node.NodeType == HtmlNodeType.Element &&
               HeadingNameRegex().IsMatch(node.Name);
    }

    private static IEnumerable<HtmlNode> GetLinks(HtmlNode node)
    {
        if (node.NodeType == HtmlNodeType.Element &&
            node.Name.Equals("a", StringComparison.OrdinalIgnoreCase))
        {
            yield return node;
        }

        foreach (HtmlNode descendant in node.Descendants("a"))
        {
            yield return descendant;
        }
    }

    [GeneratedRegex(
        @"(?:\?|&)station=([A-Za-z0-9]+)",
        RegexOptions.IgnoreCase)]
    private static partial Regex StationIdQueryRegex();

    [GeneratedRegex(@"^h[1-6]$", RegexOptions.IgnoreCase)]
    private static partial Regex HeadingNameRegex();
}
