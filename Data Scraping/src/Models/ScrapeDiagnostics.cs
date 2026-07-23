using System.Text.Json.Serialization;

namespace NdbcScraper.Models;

internal sealed class ScrapeErrorData
{
    [JsonPropertyName("scrape_run_id")]
    public required string ScrapeRunId { get; init; }

    [JsonPropertyName("station_id")]
    public string? StationId { get; init; }

    [JsonPropertyName("scope")]
    public required string Scope { get; init; }

    [JsonPropertyName("error_code")]
    public required string ErrorCode { get; init; }

    [JsonPropertyName("message")]
    public required string Message { get; init; }

    [JsonPropertyName("source_url")]
    public string? SourceUrl { get; init; }

    [JsonPropertyName("source_row_number")]
    public int? SourceRowNumber { get; init; }

    [JsonPropertyName("raw_data")]
    public string? RawData { get; init; }

    [JsonPropertyName("http_status_code")]
    public int? HttpStatusCode { get; init; }

    [JsonPropertyName("attempt_count")]
    public int? AttemptCount { get; init; }

    [JsonPropertyName("occurred_at")]
    public DateTimeOffset OccurredAt { get; init; }
}

internal static class ScrapeErrorCodes
{
    public const string DetailRequestFailed = "DETAIL_REQUEST_FAILED";
    public const string DetailParseFailed = "DETAIL_PARSE_FAILED";
    public const string RealtimeRequestFailed = "REALTIME_REQUEST_FAILED";
    public const string RealtimeFileNotFound = "REALTIME_FILE_NOT_FOUND";
    public const string ObservationHeaderNotFound = "OBSERVATION_HEADER_NOT_FOUND";
    public const string ObservationRowTooShort = "OBSERVATION_ROW_TOO_SHORT";
    public const string ObservationTimeInvalid = "OBSERVATION_TIME_INVALID";
    public const string ObservationValueInvalid = "OBSERVATION_VALUE_INVALID";
}
