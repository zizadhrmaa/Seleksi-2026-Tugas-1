using System.Text.Json.Serialization;

namespace NdbcScraper.Models;

internal sealed class ObservationManifestData
{
    [JsonPropertyName("scrape_run_id")]
    public required string ScrapeRunId { get; init; }

    [JsonPropertyName("generated_at")]
    public DateTimeOffset GeneratedAt { get; init; }

    [JsonPropertyName("total_station_count")]
    public int TotalStationCount { get; init; }

    [JsonPropertyName("total_observation_count")]
    public int TotalObservationCount { get; init; }

    [JsonPropertyName("combined_file")]
    public required string CombinedFile { get; init; }

    [JsonPropertyName("combined_file_git_ignored")]
    public bool CombinedFileGitIgnored { get; init; }

    [JsonPropertyName("station_files")]
    public required IReadOnlyList<ObservationFileManifestEntry> StationFiles
    {
        get;
        init;
    }
}

internal sealed class ObservationFileManifestEntry
{
    [JsonPropertyName("station_id")]
    public required string StationId { get; init; }

    [JsonPropertyName("relative_path")]
    public required string RelativePath { get; init; }

    [JsonPropertyName("observation_count")]
    public int ObservationCount { get; init; }

    [JsonPropertyName("first_observed_at_utc")]
    public DateTimeOffset? FirstObservedAtUtc { get; init; }

    [JsonPropertyName("last_observed_at_utc")]
    public DateTimeOffset? LastObservedAtUtc { get; init; }

    [JsonPropertyName("file_size_bytes")]
    public long FileSizeBytes { get; init; }
}
