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
    string? ErrorMessage,
    string? RawRowText)
{
    public bool IsSuccess => Forecast is not null;

    public static ForecastRowParseResult Success(ForecastData forecast)
    {
        return new ForecastRowParseResult(forecast, null, null);
    }

    public static ForecastRowParseResult Failure(
        string errorMessage,
        string rawRowText)
    {
        return new ForecastRowParseResult(null, errorMessage, rawRowText);
    }
}

internal sealed record ForecastScrapeResult(
    IReadOnlyList<ForecastData> Forecasts,
    IReadOnlyList<ScrapeErrorData> Errors);

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

    [JsonPropertyName("row_index")]
    public int? RowIndex { get; init; }

    [JsonPropertyName("message")]
    public required string Message { get; init; }

    [JsonPropertyName("raw_data")]
    public string? RawData { get; init; }

    [JsonPropertyName("occurred_at")]
    public DateTimeOffset OccurredAt { get; init; }
}
