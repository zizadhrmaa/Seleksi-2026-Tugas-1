using System.Net;
using System.Text.RegularExpressions;

namespace NdbcScraper.Utilities;

internal static partial class TextNormalizer
{
    public static string Clean(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        string decoded = WebUtility.HtmlDecode(value);
        return WhitespaceRegex().Replace(decoded, " ").Trim();
    }

    [GeneratedRegex(@"\s+")]
    private static partial Regex WhitespaceRegex();
}
