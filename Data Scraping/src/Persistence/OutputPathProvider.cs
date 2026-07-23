namespace NdbcScraper.Persistence;

internal sealed class OutputPathProvider
{
    public OutputPathProvider(string dataDirectory)
    {
        DataDirectory = Path.GetFullPath(dataDirectory);
        ObservationFilesDirectory = Path.Combine(
            DataDirectory,
            "observations");
        CheckpointDirectory = Path.Combine(
            DataDirectory,
            "checkpoints");

        StationsFile = Path.Combine(DataDirectory, "stations.json");
        CombinedObservationsFile = Path.Combine(
            DataDirectory,
            "observations.json");
        ObservationManifestFile = Path.Combine(
            DataDirectory,
            "observations_manifest.json");
        SkippedStationsFile = Path.Combine(
            DataDirectory,
            "skipped_stations.json");
        ErrorsFile = Path.Combine(DataDirectory, "errors.json");
        ReportFile = Path.Combine(DataDirectory, "scraping_report.json");
        ProgressFile = Path.Combine(
            CheckpointDirectory,
            "progress.json");
    }

    public string DataDirectory { get; }
    public string ObservationFilesDirectory { get; }
    public string CheckpointDirectory { get; }
    public string StationsFile { get; }
    public string CombinedObservationsFile { get; }
    public string ObservationManifestFile { get; }
    public string SkippedStationsFile { get; }
    public string ErrorsFile { get; }
    public string ReportFile { get; }
    public string ProgressFile { get; }

    public string GetStationObservationFile(string stationId)
    {
        return Path.Combine(
            ObservationFilesDirectory,
            $"{stationId.ToLowerInvariant()}.json");
    }

    public void PrepareNewRun()
    {
        Directory.CreateDirectory(DataDirectory);

        DeleteFileIfExists(StationsFile);
        DeleteFileIfExists(CombinedObservationsFile);
        DeleteFileIfExists(ObservationManifestFile);
        DeleteFileIfExists(SkippedStationsFile);
        DeleteFileIfExists(ErrorsFile);
        DeleteFileIfExists(ReportFile);

        DeleteDirectoryIfExists(ObservationFilesDirectory);
        DeleteDirectoryIfExists(CheckpointDirectory);

        EnsureDirectories();
    }

    public void EnsureDirectories()
    {
        Directory.CreateDirectory(DataDirectory);
        Directory.CreateDirectory(ObservationFilesDirectory);
        Directory.CreateDirectory(CheckpointDirectory);
    }

    private static void DeleteFileIfExists(string path)
    {
        if (File.Exists(path))
        {
            File.Delete(path);
        }
    }

    private static void DeleteDirectoryIfExists(string path)
    {
        if (Directory.Exists(path))
        {
            Directory.Delete(path, recursive: true);
        }
    }
}
