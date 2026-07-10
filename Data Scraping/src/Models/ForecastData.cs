using System.Text.Json.Serialization;

namespace BmkgScraper.Models;

internal sealed class ForecastData
{
    [JsonPropertyName("batch_id")]
    public required string BatchId { get; init; }

    [JsonPropertyName("batch_started_at")]
    public DateTimeOffset BatchStartedAt { get; init; }

    [JsonPropertyName("port_code")]
    public required string PortCode { get; init; }

    [JsonPropertyName("port_name")]
    public required string PortName { get; init; }

    [JsonPropertyName("forecast_at")]
    public DateTimeOffset ForecastAt { get; init; }

    [JsonPropertyName("weather")]
    public required string Weather { get; init; }

    [JsonPropertyName("wind_direction")]
    public required string WindDirection { get; init; }

    [JsonPropertyName("wind_speed_knot")]
    public double WindSpeedKnot { get; init; }

    [JsonPropertyName("wind_gust_knot")]
    public double WindGustKnot { get; init; }

    [JsonPropertyName("wave_height_meter")]
    public double WaveHeightMeter { get; init; }

    [JsonPropertyName("wave_category")]
    public required string WaveCategory { get; init; }

    [JsonPropertyName("current_direction")]
    public required string CurrentDirection { get; init; }

    [JsonPropertyName("current_speed_knot")]
    public double CurrentSpeedKnot { get; init; }

    [JsonPropertyName("raw_visibility")]
    public required string RawVisibility { get; init; }

    [JsonPropertyName("visibility_km")]
    public double? VisibilityKm { get; init; }

    [JsonPropertyName("temperature_celsius")]
    public double TemperatureCelsius { get; init; }

    [JsonPropertyName("humidity_percent")]
    public double HumidityPercent { get; init; }

    [JsonPropertyName("raw_tide")]
    public required string RawTide { get; init; }

    [JsonPropertyName("tide_meter")]
    public double? TideMeter { get; init; }

    [JsonPropertyName("quality_flags")]
    public required IReadOnlyList<string> QualityFlags { get; init; }

    [JsonPropertyName("source_url")]
    public required string SourceUrl { get; init; }

    [JsonPropertyName("extracted_at")]
    public DateTimeOffset ExtractedAt { get; init; }
}
