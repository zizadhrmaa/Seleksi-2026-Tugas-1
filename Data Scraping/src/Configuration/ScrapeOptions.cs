using System.Globalization;

namespace NdbcScraper.Configuration;

internal sealed record ScrapeOptions(
    int TargetStationCount,
    TimeSpan RequestDelay,
    bool Resume,
    string OutputDirectory)
{
    public static ScrapeOptions Parse(string[] args)
    {
        int targetStationCount = ResolvePositiveInteger(
            args,
            "--limit",
            defaultValue: 100);

        double delaySeconds = ResolveNonNegativeDouble(
            args,
            "--delay-seconds",
            defaultValue: 1.0);

        bool resume = args.Any(argument =>
            argument.Equals("--resume", StringComparison.OrdinalIgnoreCase));

        string outputDirectory = ResolveOutputDirectory(args);

        return new ScrapeOptions(
            targetStationCount,
            TimeSpan.FromSeconds(delaySeconds),
            resume,
            outputDirectory);
    }

    private static int ResolvePositiveInteger(
        string[] args,
        string optionName,
        int defaultValue)
    {
        string? value = ResolveOptionValue(args, optionName);

        if (value is null)
        {
            return defaultValue;
        }

        if (!int.TryParse(value, NumberStyles.Integer,
                CultureInfo.InvariantCulture, out int parsedValue) ||
            parsedValue <= 0)
        {
            throw new ArgumentException(
                $"{optionName} harus berupa bilangan bulat lebih dari 0.");
        }

        return parsedValue;
    }

    private static double ResolveNonNegativeDouble(
        string[] args,
        string optionName,
        double defaultValue)
    {
        string? value = ResolveOptionValue(args, optionName);

        if (value is null)
        {
            return defaultValue;
        }

        if (!double.TryParse(value, NumberStyles.Float,
                CultureInfo.InvariantCulture, out double parsedValue) ||
            parsedValue < 0)
        {
            throw new ArgumentException(
                $"{optionName} harus berupa angka 0 atau lebih.");
        }

        return parsedValue;
    }

    private static string ResolveOutputDirectory(string[] args)
    {
        string? configuredPath = ResolveOptionValue(args, "--output");

        if (!string.IsNullOrWhiteSpace(configuredPath))
        {
            return Path.GetFullPath(configuredPath);
        }

        string currentDirectory = Directory.GetCurrentDirectory();
        bool runningFromSrcDirectory = string.Equals(
            Path.GetFileName(currentDirectory.TrimEnd(
                Path.DirectorySeparatorChar,
                Path.AltDirectorySeparatorChar)),
            "src",
            StringComparison.OrdinalIgnoreCase);

        string defaultPath = runningFromSrcDirectory
            ? Path.Combine(currentDirectory, "..", "data")
            : Path.Combine(currentDirectory, "data");

        return Path.GetFullPath(defaultPath);
    }

    private static string? ResolveOptionValue(
        string[] args,
        string optionName)
    {
        int optionIndex = Array.FindIndex(
            args,
            argument => argument.Equals(
                optionName,
                StringComparison.OrdinalIgnoreCase));

        if (optionIndex < 0)
        {
            return null;
        }

        if (optionIndex + 1 >= args.Length ||
            string.IsNullOrWhiteSpace(args[optionIndex + 1]) ||
            args[optionIndex + 1].StartsWith("--", StringComparison.Ordinal))
        {
            throw new ArgumentException(
                $"{optionName} membutuhkan nilai setelah nama opsi.");
        }

        return args[optionIndex + 1].Trim();
    }
}
