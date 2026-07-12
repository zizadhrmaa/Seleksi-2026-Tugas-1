using System.Text.Json.Serialization;

namespace BmkgScraper.Models;

internal static class ScrapeErrorCodes
{
    public const string HttpRequestFailed = "HTTP_REQUEST_FAILED";
    public const string SourcePageLoading = "SOURCE_PAGE_LOADING";
    public const string ForecastTableNotFound = "FORECAST_TABLE_NOT_FOUND";
    public const string AllRowsEmpty = "ALL_ROWS_EMPTY";
    public const string AllRowsInvalid = "ALL_ROWS_INVALID";
    public const string InvalidColumnCount = "INVALID_COLUMN_COUNT";
    public const string ForecastTimeParseFailed = "FORECAST_TIME_PARSE_FAILED";
    public const string RowParseFailed = "ROW_PARSE_FAILED";
    public const string UnexpectedPortError = "UNEXPECTED_PORT_ERROR";
}

internal static class PortScrapeStatusCodes
{
    public const string Success = "SUCCESS";
    public const string SuccessWithWarnings = "SUCCESS_WITH_WARNINGS";
    public const string PartialSuccess = "PARTIAL_SUCCESS";
    public const string SourceUnavailable = "SOURCE_UNAVAILABLE";
    public const string Failed = "FAILED";
}

internal static class BatchStatusCodes
{
    public const string Running = "RUNNING";
    public const string Cancelled = "CANCELLED";
    public const string Completed = "COMPLETED";
    public const string CompletedWithWarnings = "COMPLETED_WITH_WARNINGS";
    public const string CompletedWithSourceGaps =
        "COMPLETED_WITH_SOURCE_GAPS";
    public const string CompletedWithErrors =
        "COMPLETED_WITH_ERRORS";
}

internal static class ScrapeRunTypeCodes
{
    public const string Full = "FULL";
    public const string Retry = "RETRY";
}

internal sealed class PortScrapeResultData
{
    public PortScrapeResultData()
    {
    }

    [JsonPropertyName("batch_id")]
    public string BatchId { get; init; } = string.Empty;

    [JsonPropertyName("port_code")]
    public string PortCode { get; init; } = string.Empty;

    [JsonPropertyName("port_name")]
    public string PortName { get; init; } = string.Empty;

    [JsonPropertyName("status")]
    public string Status { get; init; } = string.Empty;

    [JsonPropertyName("forecast_count")]
    public int ForecastCount { get; init; }

    [JsonPropertyName("error_count")]
    public int ErrorCount { get; init; }

    [JsonPropertyName("quality_warning_count")]
    public int QualityWarningCount { get; init; }

    [JsonPropertyName("series_quality_flags")]
    public IReadOnlyList<string> SeriesQualityFlags { get; init; } = [];

    [JsonPropertyName("attempt_count")]
    public int AttemptCount { get; init; }

    [JsonPropertyName("retry_count")]
    public int RetryCount { get; init; }

    [JsonPropertyName("http_status_code")]
    public int? HttpStatusCode { get; init; }

    [JsonPropertyName("duration_ms")]
    public long DurationMilliseconds { get; init; }

    [JsonPropertyName("processed_at")]
    public DateTimeOffset ProcessedAt { get; init; }
}

internal enum PortSelectionMode
{
    Spread,
    Sequential
}

internal enum ScrapeRunMode
{
    New,
    RetryBatch,
    Resume
}

internal sealed record ScrapeRunOptions(
    int? PortLimit,
    PortSelectionMode SelectionMode,
    ScrapeRunMode RunMode,
    string? ReferenceBatchId);
