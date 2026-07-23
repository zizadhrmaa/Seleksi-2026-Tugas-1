using System.Text.Json.Serialization;

namespace NdbcScraper.Models;

internal sealed class SkippedStationData
{
    [JsonPropertyName("scrape_run_id")]
    public required string ScrapeRunId { get; init; }

    [JsonPropertyName("station_id")]
    public required string StationId { get; init; }

    [JsonPropertyName("reason_code")]
    public required string ReasonCode { get; init; }

    [JsonPropertyName("message")]
    public required string Message { get; init; }

    [JsonPropertyName("detail_url")]
    public string? DetailUrl { get; init; }

    [JsonPropertyName("realtime_data_url")]
    public string? RealtimeDataUrl { get; init; }

    [JsonPropertyName("http_status_code")]
    public int? HttpStatusCode { get; init; }

    [JsonPropertyName("skipped_at")]
    public DateTimeOffset SkippedAt { get; init; }
}

internal static class SkippedStationReasonCodes
{
    public const string NotBuoy = "NOT_BUOY";
    public const string NoRealtimeMeteorologicalData =
        "NO_REALTIME_METEOROLOGICAL_DATA";
    public const string NoRelevantMeasurements =
        "NO_RELEVANT_MEASUREMENTS";
}
