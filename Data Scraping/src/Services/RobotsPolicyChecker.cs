using System.Text.RegularExpressions;
using NdbcScraper.Http;

namespace NdbcScraper.Services;

internal sealed class RobotsPolicyChecker
{
    private const string UserAgentName = "BasisDataSelectionScraper";
    private readonly IHttpFetcher _httpFetcher;
    private readonly Uri _baseUri;

    public RobotsPolicyChecker(IHttpFetcher httpFetcher, Uri baseUri)
    {
        _httpFetcher = httpFetcher;
        _baseUri = baseUri;
    }

    public async Task<string?> CheckAsync(
        CancellationToken cancellationToken = default)
    {
        Uri robotsUri = new(_baseUri, "/robots.txt");
        string robotsText;

        try
        {
            HttpFetchResult result = await _httpFetcher.GetStringAsync(
                robotsUri,
                cancellationToken);
            robotsText = result.Content;
        }
        catch (HttpFetchException exception)
        {
            return "robots.txt tidak dapat dibaca. Proses tetap dilanjutkan " +
                   "karena NDBC menyediakan akses data real-time melalui HTTPS. " +
                   $"Detail: {exception.Message}";
        }

        string[] pathsToCheck =
        {
            "/to_station.shtml",
            "/station_page.php",
            "/data/realtime2/"
        };

        foreach (string path in pathsToCheck)
        {
            if (!IsAllowed(robotsText, UserAgentName, path))
            {
                throw new InvalidOperationException(
                    $"robots.txt tidak mengizinkan akses ke {path}.");
            }
        }

        return null;
    }

    private static bool IsAllowed(
        string robotsText,
        string userAgent,
        string path)
    {
        List<RobotsRule> activeRules = new();
        List<string> currentUserAgents = new();

        foreach (string rawLine in robotsText.Split('\n'))
        {
            string line = rawLine.Split('#', 2)[0].Trim();

            if (string.IsNullOrWhiteSpace(line))
            {
                currentUserAgents.Clear();
                continue;
            }

            int separatorIndex = line.IndexOf(':');

            if (separatorIndex < 0)
            {
                continue;
            }

            string field = line[..separatorIndex].Trim();
            string value = line[(separatorIndex + 1)..].Trim();

            if (field.Equals("User-agent", StringComparison.OrdinalIgnoreCase))
            {
                currentUserAgents.Add(value);
                continue;
            }

            bool applies = currentUserAgents.Any(agent =>
                agent.Equals("*", StringComparison.OrdinalIgnoreCase) ||
                userAgent.Contains(agent, StringComparison.OrdinalIgnoreCase));

            if (!applies ||
                (!field.Equals("Allow", StringComparison.OrdinalIgnoreCase) &&
                 !field.Equals("Disallow", StringComparison.OrdinalIgnoreCase)))
            {
                continue;
            }

            if (string.IsNullOrWhiteSpace(value))
            {
                continue;
            }

            activeRules.Add(new RobotsRule(
                value,
                field.Equals("Allow", StringComparison.OrdinalIgnoreCase)));
        }

        RobotsRule? matchingRule = activeRules
            .Where(rule => RuleMatches(rule.PathPattern, path))
            .OrderByDescending(rule => rule.PathPattern.Length)
            .ThenByDescending(rule => rule.Allow)
            .FirstOrDefault();

        return matchingRule?.Allow ?? true;
    }

    private static bool RuleMatches(string pattern, string path)
    {
        string regexPattern = "^" + Regex.Escape(pattern)
            .Replace("\\*", ".*");

        if (regexPattern.EndsWith("\\$", StringComparison.Ordinal))
        {
            regexPattern = regexPattern[..^2] + "$";
        }

        return Regex.IsMatch(
            path,
            regexPattern,
            RegexOptions.CultureInvariant);
    }

    private sealed record RobotsRule(string PathPattern, bool Allow);
}
