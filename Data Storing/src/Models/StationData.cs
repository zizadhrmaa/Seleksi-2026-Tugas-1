using System.Text.Json.Serialization;

namespace NdbcDataLoader.Models;

internal sealed class StationData
{
    [JsonPropertyName("scrape_run_id")]
    public required string ScrapeRunId { get; init; }

    [JsonPropertyName("station_id")]
    public required string StationId { get; init; }

    [JsonPropertyName("station_name")]
    public required string StationName { get; init; }

    [JsonPropertyName("location")]
    public string? Location { get; init; }

    [JsonPropertyName("owner")]
    public required string Owner { get; init; }

    [JsonPropertyName("device_type")]
    public required string DeviceType { get; init; }

    [JsonPropertyName("payload")]
    public required string Payload { get; init; }

    [JsonPropertyName("latitude")]
    public double Latitude { get; init; }

    [JsonPropertyName("longitude")]
    public double Longitude { get; init; }

    [JsonPropertyName("water_depth_meter")]
    public double WaterDepthMeter { get; init; }

    [JsonPropertyName("status")]
    public required string Status { get; init; }

    [JsonPropertyName("detail_url")]
    public required string DetailUrl { get; init; }

    [JsonPropertyName("realtime_data_url")]
    public required string RealtimeDataUrl { get; init; }

    [JsonPropertyName("extracted_at")]
    public DateTimeOffset ExtractedAt { get; init; }
}
