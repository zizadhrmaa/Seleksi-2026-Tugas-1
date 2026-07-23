using System.Text.Json.Serialization;

namespace NdbcDataLoader.Models;

internal sealed class ScrapeRunReport
{
    [JsonPropertyName("scrape_run_id")]
    public required string ScrapeRunId { get; init; }

    [JsonPropertyName("started_at")]
    public DateTimeOffset StartedAt { get; init; }

    [JsonPropertyName("finished_at")]
    public DateTimeOffset FinishedAt { get; init; }

    [JsonPropertyName("target_station_count")]
    public int TargetStationCount { get; init; }

    [JsonPropertyName("target_met")]
    public bool TargetMet { get; init; }

    [JsonPropertyName("source_candidate_count")]
    public int SourceCandidateCount { get; init; }

    [JsonPropertyName("processed_candidate_count")]
    public int ProcessedCandidateCount { get; init; }

    [JsonPropertyName("successful_station_count")]
    public int SuccessfulStationCount { get; init; }

    [JsonPropertyName("skipped_non_buoy_count")]
    public int SkippedNonBuoyCount { get; init; }

    [JsonPropertyName("skipped_no_data_count")]
    public int SkippedNoDataCount { get; init; }

    [JsonPropertyName("failed_attempt_count")]
    public int FailedAttemptCount { get; init; }

    [JsonPropertyName("total_observation_count")]
    public int TotalObservationCount { get; init; }

    [JsonPropertyName("duplicate_observation_count")]
    public int DuplicateObservationCount { get; init; }

    [JsonPropertyName("station_list_source_url")]
    public required string StationListSourceUrl { get; init; }

    [JsonPropertyName("output_directory")]
    public string? OutputDirectory { get; init; }
}
