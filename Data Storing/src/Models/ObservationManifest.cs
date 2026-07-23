using System.Text.Json.Serialization;

namespace NdbcDataLoader.Models;

internal sealed class ObservationManifest
{
    [JsonPropertyName("scrape_run_id")]
    public required string ScrapeRunId { get; init; }

    [JsonPropertyName("total_station_count")]
    public int TotalStationCount { get; init; }

    [JsonPropertyName("total_observation_count")]
    public int TotalObservationCount { get; init; }

    [JsonPropertyName("station_files")]
    public required IReadOnlyList<StationObservationFile> StationFiles { get; init; }
}

internal sealed class StationObservationFile
{
    [JsonPropertyName("station_id")]
    public required string StationId { get; init; }

    [JsonPropertyName("relative_path")]
    public required string RelativePath { get; init; }

    [JsonPropertyName("observation_count")]
    public int ObservationCount { get; init; }
}
