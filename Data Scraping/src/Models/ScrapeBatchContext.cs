using System.Text.Json.Serialization;

namespace BmkgScraper.Models;

internal sealed record ScrapeBatchContext(
    string BatchId,
    DateTimeOffset BatchStartedAt)
{
    public static ScrapeBatchContext Create(TimeSpan utcOffset)
    {
        DateTimeOffset startedAt = DateTimeOffset.UtcNow.ToOffset(utcOffset);
        string uniqueSuffix = Guid.NewGuid().ToString("N")[..8];
        string batchId = $"batch-{startedAt:yyyyMMdd-HHmmss}-{uniqueSuffix}";

        return new ScrapeBatchContext(batchId, startedAt);
    }
}

internal sealed class ScrapeBatchData
{
    [JsonPropertyName("batch_id")]
    public required string BatchId { get; init; }

    [JsonPropertyName("batch_started_at")]
    public DateTimeOffset BatchStartedAt { get; init; }

    [JsonPropertyName("batch_finished_at")]
    public DateTimeOffset BatchFinishedAt { get; init; }

    [JsonPropertyName("requested_port_count")]
    public int RequestedPortCount { get; init; }

    [JsonPropertyName("successful_port_count")]
    public int SuccessfulPortCount { get; init; }

    [JsonPropertyName("failed_port_count")]
    public int FailedPortCount { get; init; }

    [JsonPropertyName("forecast_count")]
    public int ForecastCount { get; init; }

    [JsonPropertyName("error_count")]
    public int ErrorCount { get; init; }

    [JsonPropertyName("status")]
    public required string Status { get; init; }
}
