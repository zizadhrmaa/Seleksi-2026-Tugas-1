using System.Text.Json.Serialization;

namespace NdbcScraper.Models;

internal sealed class ScrapeProgress
{
    [JsonPropertyName("scrape_run_id")]
    public required string ScrapeRunId { get; init; }

    [JsonPropertyName("started_at")]
    public DateTimeOffset StartedAt { get; init; }

    [JsonPropertyName("target_station_count")]
    public int TargetStationCount { get; init; }

    [JsonPropertyName("source_candidate_count")]
    public int SourceCandidateCount { get; set; }

    [JsonPropertyName("processed_station_ids")]
    public required List<string> ProcessedStationIds { get; init; }

    [JsonPropertyName("successful_station_ids")]
    public required List<string> SuccessfulStationIds { get; init; }

    [JsonPropertyName("skipped_non_buoy_count")]
    public int SkippedNonBuoyCount { get; set; }

    [JsonPropertyName("skipped_no_data_count")]
    public int SkippedNoDataCount { get; set; }

    [JsonPropertyName("failed_attempt_count")]
    public int FailedAttemptCount { get; set; }

    [JsonPropertyName("total_observation_count")]
    public int TotalObservationCount { get; set; }

    [JsonPropertyName("duplicate_observation_count")]
    public int DuplicateObservationCount { get; set; }

    [JsonPropertyName("last_updated_at")]
    public DateTimeOffset LastUpdatedAt { get; set; }
}
