using System.Text.Json.Serialization;

namespace BmkgScraper.Models;

internal sealed record WindParseResult(
    string Direction,
    double SpeedKnot,
    double GustKnot);

internal sealed record WaveParseResult(
    double HeightMeter,
    string Category);

internal sealed record CurrentParseResult(
    string Direction,
    double SpeedKnot);

internal sealed record VisibilityParseResult(
    string RawValue,
    double? ValueKm,
    IReadOnlyList<string> QualityFlags);

internal sealed record TideParseResult(
    string RawValue,
    double? ValueMeter,
    IReadOnlyList<string> QualityFlags);

internal sealed record ForecastRowParseResult(
    ForecastData? Forecast,
    string? ErrorCode,
    string? ErrorMessage,
    string? RawRowText)
{
    public bool IsSuccess => Forecast is not null;

    public static ForecastRowParseResult Success(ForecastData forecast)
    {
        return new ForecastRowParseResult(
            forecast,
            null,
            null,
            null);
    }

    public static ForecastRowParseResult Failure(
        string errorCode,
        string errorMessage,
        string rawRowText)
    {
        return new ForecastRowParseResult(
            null,
            errorCode,
            errorMessage,
            rawRowText);
    }
}

internal sealed record ForecastScrapeResult(
    IReadOnlyList<ForecastData> Forecasts,
    IReadOnlyList<ScrapeErrorData> Errors,
    IReadOnlyList<string> SeriesQualityFlags,
    int AttemptCount,
    int? HttpStatusCode,
    long DurationMilliseconds,
    int TableRowCount);

internal sealed class ScrapeErrorData
{
    [JsonPropertyName("batch_id")]
    public required string BatchId { get; init; }

    [JsonPropertyName("port_code")]
    public string? PortCode { get; init; }

    [JsonPropertyName("port_name")]
    public string? PortName { get; init; }

    [JsonPropertyName("error_scope")]
    public required string ErrorScope { get; init; }

    [JsonPropertyName("error_code")]
    public required string ErrorCode { get; init; }

    [JsonPropertyName("row_index")]
    public int? RowIndex { get; init; }

    [JsonPropertyName("message")]
    public required string Message { get; init; }

    [JsonPropertyName("raw_data")]
    public string? RawData { get; init; }

    [JsonPropertyName("http_status_code")]
    public int? HttpStatusCode { get; init; }

    [JsonPropertyName("attempt_count")]
    public int? AttemptCount { get; init; }

    [JsonPropertyName("duration_ms")]
    public long? DurationMilliseconds { get; init; }

    [JsonPropertyName("table_row_count")]
    public int? TableRowCount { get; init; }

    [JsonPropertyName("occurred_at")]
    public DateTimeOffset OccurredAt { get; init; }
}
