using System.Globalization;
using System.Net;
using System.Text.RegularExpressions;
using BmkgScraper.Models;
using BmkgScraper.Validation;

namespace BmkgScraper.Parsers;

internal sealed class MeasurementParser
{
    private const string NumberPattern = @"[+-]?\d+(?:[.,]\d+)?";

    private static readonly IReadOnlyDictionary<string, string>
        MonthAbbreviationMap =
            new Dictionary<string, string>(
                StringComparer.OrdinalIgnoreCase)
            {
                ["Jan"] = "Jan",
                ["Feb"] = "Feb",
                ["Mar"] = "Mar",
                ["Apr"] = "Apr",
                ["Mei"] = "May",
                ["May"] = "May",
                ["Jun"] = "Jun",
                ["Jul"] = "Jul",
                ["Agu"] = "Aug",
                ["Ags"] = "Aug",
                ["Aug"] = "Aug",
                ["Sep"] = "Sep",
                ["Okt"] = "Oct",
                ["Oct"] = "Oct",
                ["Nov"] = "Nov",
                ["Des"] = "Dec",
                ["Dec"] = "Dec"
            };

    private readonly double _maxReasonableVisibilityKm;

    public MeasurementParser(double maxReasonableVisibilityKm)
    {
        if (maxReasonableVisibilityKm <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(maxReasonableVisibilityKm));
        }

        _maxReasonableVisibilityKm = maxReasonableVisibilityKm;
    }

    public bool TryParseForecastTime(
        string text,
        out DateTimeOffset forecastAt)
    {
        Match match = Regex.Match(
            text,
            @"^(?<day>\d{1,2})\s+" +
            @"(?<month>[A-Za-z]{3})\s+" +
            @"(?<year>\d{2}),\s+" +
            @"(?<hour>\d{2})\." +
            @"(?<minute>\d{2})",
            RegexOptions.CultureInvariant);

        if (!match.Success)
        {
            forecastAt = default;
            return false;
        }

        string sourceMonth = match.Groups["month"].Value;

        if (!MonthAbbreviationMap.TryGetValue(
                sourceMonth,
                out string? normalizedMonth))
        {
            forecastAt = default;
            return false;
        }

        string normalizedDateText =
            $"{match.Groups["day"].Value} " +
            $"{normalizedMonth} " +
            $"{match.Groups["year"].Value}, " +
            $"{match.Groups["hour"].Value}." +
            $"{match.Groups["minute"].Value}";

        bool parsed = DateTime.TryParseExact(
            normalizedDateText,
            "d MMM yy, HH.mm",
            CultureInfo.InvariantCulture,
            DateTimeStyles.None,
            out DateTime parsedDate);

        if (!parsed)
        {
            forecastAt = default;
            return false;
        }

        forecastAt = new DateTimeOffset(
            DateTime.SpecifyKind(
                parsedDate,
                DateTimeKind.Unspecified),
            TimeSpan.FromHours(7));

        return true;
    }

    public WindParseResult ParseWind(string text)
    {
        Match match = Regex.Match(
            text,
            @"^(?<direction>.+?)\s+" +
            @"(?<speed>\d+(?:[.,]\d+)?)\s*kt" +
            @".*?:\s*" +
            @"(?<gust>\d+(?:[.,]\d+)?)\s*kt\s*$",
            RegexOptions.IgnoreCase);

        if (!match.Success)
        {
            throw new FormatException(
                $"Format data angin tidak dikenali: {text}");
        }

        return new WindParseResult(
            TextNormalizer.Clean(
                match.Groups["direction"].Value),
            ParseNumericText(
                match.Groups["speed"].Value),
            ParseNumericText(
                match.Groups["gust"].Value));
    }

    public WaveParseResult ParseWave(string text)
    {
        Match match = Regex.Match(
            text,
            @"^(?<height>[+-]?\d+(?:[.,]\d+)?)\s*m\s*(?<category>.+)$",
            RegexOptions.IgnoreCase);

        if (!match.Success)
        {
            throw new FormatException(
                $"Format data gelombang tidak dikenali: {text}");
        }

        return new WaveParseResult(
            ParseNumericText(
                match.Groups["height"].Value),
            TextNormalizer.Clean(
                match.Groups["category"].Value));
    }

    public CurrentParseResult ParseCurrent(string text)
    {
        Match match = Regex.Match(
            text,
            @"^(?<direction>.*?)" +
            @"(?<speed>[+-]?\d+(?:[.,]\d+)?)\s*Knot\s*$",
            RegexOptions.IgnoreCase);

        if (!match.Success)
        {
            throw new FormatException(
                $"Format data arus tidak dikenali: {text}");
        }

        return new CurrentParseResult(
            TextNormalizer.Clean(
                match.Groups["direction"].Value),
            ParseNumericText(
                match.Groups["speed"].Value));
    }

    public VisibilityParseResult ParseVisibility(string rawText)
    {
        Match match = Regex.Match(rawText, NumberPattern);

        if (!match.Success)
        {
            return new VisibilityParseResult(
                rawText,
                null,
                [QualityFlagCodes.VisibilityParseFailed]);
        }

        double valueKm = ParseNumericText(match.Value);

        if (valueKm < 0 || valueKm > _maxReasonableVisibilityKm)
        {
            return new VisibilityParseResult(
                rawText,
                null,
                [QualityFlagCodes.VisibilityOutOfRange]);
        }

        return new VisibilityParseResult(rawText, valueKm, []);
    }

    public TideParseResult ParseTide(string rawText)
    {
        string normalizedText = TextNormalizer.Clean(rawText);

        bool isMissing =
            string.IsNullOrWhiteSpace(normalizedText) ||
            Regex.IsMatch(
                normalizedText,
                @"^(?:-|N/?A|Tidak tersedia)\s*(?:m)?$",
                RegexOptions.IgnoreCase);

        if (isMissing)
        {
            return new TideParseResult(
                normalizedText,
                null,
                [QualityFlagCodes.TideMissing]);
        }

        Match match = Regex.Match(normalizedText, NumberPattern);

        if (!match.Success)
        {
            return new TideParseResult(
                normalizedText,
                null,
                [QualityFlagCodes.TideParseFailed]);
        }

        return new TideParseResult(
            normalizedText,
            ParseNumericText(match.Value),
            []);
    }

    public double ParseRequiredNumber(string text)
    {
        Match match = Regex.Match(text, NumberPattern);

        if (!match.Success)
        {
            throw new FormatException(
                $"Tidak ditemukan angka pada: {text}");
        }

        return ParseNumericText(match.Value);
    }

    private static double ParseNumericText(string text)
    {
        string normalizedText = text.Replace(',', '.');

        return double.Parse(
            normalizedText,
            NumberStyles.Float,
            CultureInfo.InvariantCulture);
    }
}

internal static class TextNormalizer
{
    public static string Clean(string text)
    {
        string decodedText = WebUtility.HtmlDecode(text);
        return Regex.Replace(decodedText, @"\s+", " ").Trim();
    }
}
