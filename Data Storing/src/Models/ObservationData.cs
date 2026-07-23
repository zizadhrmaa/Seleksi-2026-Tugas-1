using System.Text.Json.Serialization;

namespace NdbcDataLoader.Models;

internal sealed class ObservationData
{
    [JsonPropertyName("scrape_run_id")]
    public required string ScrapeRunId { get; init; }

    [JsonPropertyName("station_id")]
    public required string StationId { get; init; }

    [JsonPropertyName("observed_at_utc")]
    public DateTimeOffset ObservedAtUtc { get; init; }

    [JsonPropertyName("wind_direction_degree")]
    public short? WindDirectionDegree { get; init; }

    [JsonPropertyName("wind_speed_meter_per_second")]
    public double? WindSpeedMeterPerSecond { get; init; }

    [JsonPropertyName("wind_gust_meter_per_second")]
    public double? WindGustMeterPerSecond { get; init; }

    [JsonPropertyName("wave_height_meter")]
    public double? WaveHeightMeter { get; init; }

    [JsonPropertyName("dominant_wave_period_second")]
    public double? DominantWavePeriodSecond { get; init; }

    [JsonPropertyName("average_wave_period_second")]
    public double? AverageWavePeriodSecond { get; init; }

    [JsonPropertyName("mean_wave_direction_degree")]
    public short? MeanWaveDirectionDegree { get; init; }

    [JsonPropertyName("sea_surface_temperature_celsius")]
    public double? SeaSurfaceTemperatureCelsius { get; init; }

    [JsonPropertyName("quality_flags")]
    public List<string> QualityFlags { get; init; } = [];

    [JsonPropertyName("source_row_number")]
    public int SourceRowNumber { get; init; }

    [JsonPropertyName("source_url")]
    public required string SourceUrl { get; init; }

    [JsonPropertyName("extracted_at")]
    public DateTimeOffset ExtractedAt { get; init; }
}
