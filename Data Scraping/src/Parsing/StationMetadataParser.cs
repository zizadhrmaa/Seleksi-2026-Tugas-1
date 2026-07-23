using System.Globalization;
using System.Text.RegularExpressions;
using HtmlAgilityPack;
using NdbcScraper.Models;
using NdbcScraper.Utilities;

namespace NdbcScraper.Parsing;

internal sealed partial class StationMetadataParser
{
    private const string DefaultOwner = "National Data Buoy Center";
    private readonly Uri _baseUri;

    public StationMetadataParser(Uri baseUri)
    {
        _baseUri = baseUri;
    }

    public StationMetadataParseResult Parse(
        string html,
        StationCandidate candidate,
        string scrapeRunId,
        DateTimeOffset extractedAt)
    {
        HtmlDocument document = new();
        document.LoadHtml(html);

        HtmlNode? heading = document.DocumentNode.SelectSingleNode("//h1");

        if (heading is null)
        {
            throw new InvalidOperationException(
                $"Judul halaman stasiun {candidate.StationId} tidak ditemukan.");
        }

        string headingText = TextNormalizer.Clean(heading.InnerText);
        IReadOnlyList<string> lines = HtmlTextLineExtractor.Extract(
            heading.ParentNode ?? document.DocumentNode);

        int headingLineIndex = FindHeadingLineIndex(
            lines,
            candidate.StationId,
            headingText);

        List<string> metadataLines = lines
            .Skip(Math.Max(0, headingLineIndex + 1))
            .TakeWhile(line => !IsMetadataStopLine(line))
            .Take(40)
            .ToList();

        string? ownerLine = metadataLines.FirstOrDefault(line =>
            line.StartsWith(
                "Owned and maintained by",
                StringComparison.OrdinalIgnoreCase));

        string owner = ownerLine is null
            ? DefaultOwner
            : TextNormalizer.Clean(OwnerPrefixRegex().Replace(
                ownerLine,
                string.Empty));

        string? coordinateLine = metadataLines.FirstOrDefault(line =>
            CoordinateRegex().IsMatch(line));

        (double? latitude, double? longitude) =
            ParseCoordinates(coordinateLine);

        string? waterDepthLine = metadataLines.FirstOrDefault(line =>
            line.StartsWith(
                "Water depth:",
                StringComparison.OrdinalIgnoreCase));

        double? waterDepthMeter = ParseWaterDepth(waterDepthLine);

        string? deviceType = ResolveDeviceType(
            metadataLines,
            ownerLine,
            coordinateLine);

        string? payload = metadataLines.FirstOrDefault(line =>
            line.Contains("payload", StringComparison.OrdinalIgnoreCase));

        (string? stationName, string? location) = ParseNameAndLocation(
            headingText,
            candidate.StationId);

        string realtimeDataUrl = ResolveRealtimeDataUrl(
            document,
            candidate.StationId);

        string pageText = string.Join('\n', lines);
        string status = ResolveStatus(pageText);

        bool isBuoy = deviceType is not null &&
            BuoyDeviceTypeRegex().IsMatch(deviceType);

        StationData station = new()
        {
            ScrapeRunId = scrapeRunId,
            StationId = candidate.StationId,
            StationName = stationName,
            Location = location,
            Owner = owner,
            DeviceType = deviceType,
            Payload = payload,
            Latitude = latitude,
            Longitude = longitude,
            WaterDepthMeter = waterDepthMeter,
            Status = status,
            DetailUrl = candidate.DetailUrl,
            RealtimeDataUrl = realtimeDataUrl,
            ExtractedAt = extractedAt
        };

        return new StationMetadataParseResult(station, isBuoy);
    }

    private string ResolveRealtimeDataUrl(
        HtmlDocument document,
        string stationId)
    {
        HtmlNodeCollection? links =
            document.DocumentNode.SelectNodes("//a[@href]");

        if (links is not null)
        {
            foreach (HtmlNode link in links)
            {
                string href = HtmlEntity.DeEntitize(
                    link.GetAttributeValue("href", string.Empty));

                if (!RealtimeFileRegex(stationId).IsMatch(href))
                {
                    continue;
                }

                return new Uri(_baseUri, href).AbsoluteUri;
            }
        }

        return new Uri(
            _baseUri,
            $"/data/realtime2/{stationId}.txt").AbsoluteUri;
    }

    private static int FindHeadingLineIndex(
        IReadOnlyList<string> lines,
        string stationId,
        string headingText)
    {
        int exactIndex = lines.ToList().FindIndex(line =>
            line.Equals(headingText, StringComparison.OrdinalIgnoreCase));

        if (exactIndex >= 0)
        {
            return exactIndex;
        }

        return lines.ToList().FindIndex(line =>
            line.StartsWith(
                $"Station {stationId}",
                StringComparison.OrdinalIgnoreCase));
    }

    private static bool IsMetadataStopLine(string line)
    {
        string[] prefixes =
        {
            "Latest NWS Marine Forecast",
            "Important Notice to Mariners",
            "Search And Rescue",
            "Meteorological Observations",
            "Regional HF Radar",
            "Map Type:",
            "Conditions at",
            "No Recent Reports"
        };

        return prefixes.Any(prefix => line.StartsWith(
            prefix,
            StringComparison.OrdinalIgnoreCase));
    }

    private static string? ResolveDeviceType(
        IReadOnlyList<string> metadataLines,
        string? ownerLine,
        string? coordinateLine)
    {
        int ownerIndex = ownerLine is null
            ? -1
            : metadataLines.ToList().FindIndex(line =>
                line.Equals(ownerLine, StringComparison.Ordinal));

        IEnumerable<string> linesAfterOwner = ownerIndex >= 0
            ? metadataLines.Skip(ownerIndex + 1)
            : metadataLines;

        List<string> candidates = linesAfterOwner
            .TakeWhile(line => !line.Equals(
                coordinateLine,
                StringComparison.Ordinal))
            .Where(IsDeviceTypeCandidate)
            .ToList();

        return candidates.FirstOrDefault(IsRecognizedDeviceType) ??
               candidates.FirstOrDefault();
    }

    private static bool IsDeviceTypeCandidate(string line)
    {
        return !string.IsNullOrWhiteSpace(line) &&
            !line.StartsWith(
                "Data provided by",
                StringComparison.OrdinalIgnoreCase) &&
            !line.StartsWith(
                "Data courtesy of",
                StringComparison.OrdinalIgnoreCase) &&
            !line.StartsWith(
                "Previous data provided by",
                StringComparison.OrdinalIgnoreCase) &&
            !line.Contains("payload", StringComparison.OrdinalIgnoreCase) &&
            !line.Contains("elevation:", StringComparison.OrdinalIgnoreCase) &&
            !line.Contains("height:", StringComparison.OrdinalIgnoreCase) &&
            !line.Contains("depth:", StringComparison.OrdinalIgnoreCase) &&
            !line.Contains("radius:", StringComparison.OrdinalIgnoreCase) &&
            !CoordinateRegex().IsMatch(line) &&
            !line.StartsWith(
                "Owned and maintained",
                StringComparison.OrdinalIgnoreCase);
    }

    private static bool IsRecognizedDeviceType(string line)
    {
        return BuoyDeviceTypeRegex().IsMatch(line) ||
            line.Contains("C-MAN Station", StringComparison.OrdinalIgnoreCase) ||
            line.Contains(
                "Uncrewed Surface Vehicle",
                StringComparison.OrdinalIgnoreCase) ||
            line.Contains("Weather Station", StringComparison.OrdinalIgnoreCase) ||
            line.Contains("Fixed Platform", StringComparison.OrdinalIgnoreCase) ||
            line.Contains("Tower", StringComparison.OrdinalIgnoreCase);
    }

    private static (string? StationName, string? Location)
        ParseNameAndLocation(string headingText, string stationId)
    {
        string suffix = StationHeadingPrefixRegex(stationId).Replace(
            headingText,
            string.Empty);

        if (string.IsNullOrWhiteSpace(suffix) ||
            suffix.Equals(headingText, StringComparison.Ordinal))
        {
            return (null, null);
        }

        string[] parts = suffix.Split(
            " - ",
            2,
            StringSplitOptions.TrimEntries);

        return parts.Length == 1
            ? (parts[0], null)
            : (parts[0], parts[1]);
    }

    private static (double? Latitude, double? Longitude)
        ParseCoordinates(string? coordinateLine)
    {
        if (string.IsNullOrWhiteSpace(coordinateLine))
        {
            return (null, null);
        }

        Match match = CoordinateRegex().Match(coordinateLine);

        if (!match.Success ||
            !double.TryParse(
                match.Groups["latitude"].Value,
                NumberStyles.Float,
                CultureInfo.InvariantCulture,
                out double latitude) ||
            !double.TryParse(
                match.Groups["longitude"].Value,
                NumberStyles.Float,
                CultureInfo.InvariantCulture,
                out double longitude))
        {
            return (null, null);
        }

        if (match.Groups["latitude_hemisphere"].Value
            .Equals("S", StringComparison.OrdinalIgnoreCase))
        {
            latitude *= -1;
        }

        if (match.Groups["longitude_hemisphere"].Value
            .Equals("W", StringComparison.OrdinalIgnoreCase))
        {
            longitude *= -1;
        }

        return (latitude, longitude);
    }

    private static double? ParseWaterDepth(string? waterDepthLine)
    {
        if (string.IsNullOrWhiteSpace(waterDepthLine))
        {
            return null;
        }

        Match match = WaterDepthRegex().Match(waterDepthLine);

        if (!match.Success ||
            !double.TryParse(
                match.Groups["value"].Value,
                NumberStyles.Float,
                CultureInfo.InvariantCulture,
                out double value))
        {
            return null;
        }

        string unit = match.Groups["unit"].Value;

        return unit.Equals("ft", StringComparison.OrdinalIgnoreCase)
            ? Math.Round(value * 0.3048, 3)
            : value;
    }

    private static string ResolveStatus(string pageText)
    {
        if (pageText.Contains(
                "No Recent Reports",
                StringComparison.OrdinalIgnoreCase) ||
            pageText.Contains(
                "No data available",
                StringComparison.OrdinalIgnoreCase))
        {
            return "NO_RECENT_DATA";
        }

        if (pageText.Contains(
            "Conditions at",
            StringComparison.OrdinalIgnoreCase))
        {
            return "ACTIVE";
        }

        return "UNKNOWN";
    }

    private static Regex RealtimeFileRegex(string stationId)
    {
        return new Regex(
            $@"(?:^|/)data/realtime2/{Regex.Escape(stationId)}\.txt(?:\?|$)",
            RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
    }

    private static Regex StationHeadingPrefixRegex(string stationId)
    {
        return new Regex(
            $@"^Station\s+{Regex.Escape(stationId)}(?:\s+\([^)]*\))?\s*-\s*",
            RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
    }

    [GeneratedRegex(
        @"\bbuoy\b",
        RegexOptions.IgnoreCase | RegexOptions.CultureInvariant)]
    private static partial Regex BuoyDeviceTypeRegex();

    [GeneratedRegex(
        @"^Owned and maintained by\s*",
        RegexOptions.IgnoreCase)]
    private static partial Regex OwnerPrefixRegex();

    [GeneratedRegex(
        @"(?<latitude>\d+(?:\.\d+)?)\s*(?<latitude_hemisphere>[NS])\s+" +
        @"(?<longitude>\d+(?:\.\d+)?)\s*(?<longitude_hemisphere>[EW])",
        RegexOptions.IgnoreCase)]
    private static partial Regex CoordinateRegex();

    [GeneratedRegex(
        @"Water depth:\s*(?<value>\d+(?:\.\d+)?)\s*(?<unit>m|ft)\b",
        RegexOptions.IgnoreCase)]
    private static partial Regex WaterDepthRegex();
}
