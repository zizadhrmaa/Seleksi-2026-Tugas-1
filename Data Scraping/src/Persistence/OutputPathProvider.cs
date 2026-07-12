namespace BmkgScraper.Persistence;

internal sealed class OutputPathProvider
{
    private readonly string _dataDirectory;

    public OutputPathProvider()
    {
        _dataDirectory = ResolveDataDirectory();
    }

    public string GetPortsPath()
    {
        return Path.Combine(_dataDirectory, "ports.json");
    }

    public string GetBatchMetadataPath(string batchId)
    {
        return Path.Combine(
            EnsureBatchDirectory(batchId),
            "batch.json");
    }

    public string GetBatchErrorsPath(string batchId)
    {
        return Path.Combine(
            EnsureBatchDirectory(batchId),
            "errors.json");
    }

    public string GetSelectedPortsPath(string batchId)
    {
        return Path.Combine(
            EnsureBatchDirectory(batchId),
            "selected_ports.json");
    }

    public string GetPortResultsPath(string batchId)
    {
        return Path.Combine(
            EnsureBatchDirectory(batchId),
            "port_results.json");
    }

    public string GetQualitySummaryPath(string batchId)
    {
        return Path.Combine(
            EnsureBatchDirectory(batchId),
            "quality_summary.json");
    }

    public string GetAnomaliesPath(string batchId)
    {
        return Path.Combine(
            EnsureBatchDirectory(batchId),
            "anomalies.json");
    }

    public string GetPortForecastPath(
        string batchId,
        string portCode)
    {
        string safePortCode = SanitizeFileName(portCode);

        return Path.Combine(
            EnsureBatchDirectory(batchId),
            "forecasts",
            $"{safePortCode}.json");
    }

    public bool BatchExists(string batchId)
    {
        return Directory.Exists(
            GetBatchDirectoryPath(batchId));
    }

    public string GetBatchDirectoryPath(string batchId)
    {
        return Path.Combine(
            _dataDirectory,
            "batches",
            SanitizeFileName(batchId));
    }

    private string EnsureBatchDirectory(string batchId)
    {
        string batchDirectory =
            GetBatchDirectoryPath(batchId);

        Directory.CreateDirectory(batchDirectory);
        return batchDirectory;
    }

    private static string ResolveDataDirectory()
    {
        DirectoryInfo? currentDirectory =
            new(AppContext.BaseDirectory);

        while (currentDirectory is not null)
        {
            if (currentDirectory.Name.Equals(
                    "Data Scraping",
                    StringComparison.OrdinalIgnoreCase))
            {
                string dataDirectory =
                    Path.Combine(
                        currentDirectory.FullName,
                        "data");

                Directory.CreateDirectory(dataDirectory);
                return dataDirectory;
            }

            currentDirectory = currentDirectory.Parent;
        }

        throw new DirectoryNotFoundException(
            "Folder 'Data Scraping' tidak ditemukan.");
    }

    private static string SanitizeFileName(string value)
    {
        HashSet<char> invalidCharacters =
            Path.GetInvalidFileNameChars().ToHashSet();

        char[] sanitizedCharacters = value
            .Select(character =>
                invalidCharacters.Contains(character)
                    ? '-'
                    : character)
            .ToArray();

        return new string(sanitizedCharacters).Trim();
    }
}
