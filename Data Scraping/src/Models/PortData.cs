using System.Text.Json.Serialization;

namespace BmkgScraper.Models;

internal sealed class PortData
{
    public PortData()
    {
    }

    [JsonPropertyName("port_code")]
    public required string PortCode { get; init; }

    [JsonPropertyName("port_name")]
    public required string PortName { get; init; }

    [JsonPropertyName("detail_url")]
    public required string DetailUrl { get; init; }
}
