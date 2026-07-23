using System.Text.Json.Serialization;

namespace NdbcScraper.Models;

internal sealed class ObservationData
{
    [JsonPropertyName("scrape_run_id")]
    public required string ScrapeRunId { get; init; }

    [JsonPropertyName("station_id")]
    public required string StationId { get; init; }

    [JsonPropertyName("observed_at_utc")]
    public DateTimeOffset ObservedAtUtc { get; init; }

    [JsonPropertyName("wind_direction_degree")]
    public int? WindDirectionDegree { get; set; }

    [JsonPropertyName("wind_speed_meter_per_second")]
    public double? WindSpeedMeterPerSecond { get; set; }

    [JsonPropertyName("wind_gust_meter_per_second")]
    public double? WindGustMeterPerSecond { get; set; }

    [JsonPropertyName("wave_height_meter")]
    public double? WaveHeightMeter { get; set; }

    [JsonPropertyName("dominant_wave_period_second")]
    public double? DominantWavePeriodSecond { get; set; }

    [JsonPropertyName("average_wave_period_second")]
    public double? AverageWavePeriodSecond { get; set; }

    [JsonPropertyName("mean_wave_direction_degree")]
    public int? MeanWaveDirectionDegree { get; set; }

    [JsonPropertyName("sea_surface_temperature_celsius")]
    public double? SeaSurfaceTemperatureCelsius { get; set; }

    [JsonPropertyName("quality_flags")]
    public required IReadOnlyList<string> QualityFlags { get; set; }

    [JsonPropertyName("source_row_number")]
    public int SourceRowNumber { get; init; }

    [JsonPropertyName("source_url")]
    public required string SourceUrl { get; init; }

    [JsonPropertyName("extracted_at")]
    public DateTimeOffset ExtractedAt { get; init; }

    [JsonIgnore]
    public int AvailableMeasurementCount =>
        new object?[]
        {
            WindDirectionDegree,
            WindSpeedMeterPerSecond,
            WindGustMeterPerSecond,
            WaveHeightMeter,
            DominantWavePeriodSecond,
            AverageWavePeriodSecond,
            MeanWaveDirectionDegree,
            SeaSurfaceTemperatureCelsius
        }.Count(value => value is not null);
}
