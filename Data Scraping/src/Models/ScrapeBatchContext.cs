using System.Text.Json.Serialization;

namespace BmkgScraper.Models;

internal sealed record ScrapeBatchContext(
    string BatchId,
    DateTimeOffset BatchStartedAt)
{
    public static ScrapeBatchContext Create(TimeSpan utcOffset)
    {
        DateTimeOffset startedAt =
            DateTimeOffset.UtcNow.ToOffset(utcOffset);

        string uniqueSuffix =
            Guid.NewGuid().ToString("N")[..8];

        string batchId =
            $"batch-{startedAt:yyyyMMdd-HHmmss}-{uniqueSuffix}";

        return new ScrapeBatchContext(
            batchId,
            startedAt);
    }
}

internal sealed class ScrapeBatchData
{
    public ScrapeBatchData()
    {
    }

    [JsonPropertyName("batch_id")]
    public string BatchId { get; init; } = string.Empty;

    [JsonPropertyName("batch_started_at")]
    public DateTimeOffset BatchStartedAt { get; init; }

    [JsonPropertyName("batch_finished_at")]
    public DateTimeOffset? BatchFinishedAt { get; init; }

    [JsonPropertyName("run_type")]
    public string RunType { get; init; } = ScrapeRunTypeCodes.Full;

    [JsonPropertyName("parent_batch_id")]
    public string? ParentBatchId { get; init; }

    [JsonPropertyName("selection_mode")]
    public string SelectionMode { get; init; } = "SPREAD";

    [JsonPropertyName("requested_port_count")]
    public int RequestedPortCount { get; init; }

    [JsonPropertyName("processed_port_count")]
    public int ProcessedPortCount { get; init; }

    [JsonPropertyName("remaining_port_count")]
    public int RemainingPortCount { get; init; }

    [JsonPropertyName("successful_port_count")]
    public int SuccessfulPortCount { get; init; }

    [JsonPropertyName("partial_success_port_count")]
    public int PartialSuccessPortCount { get; init; }

    [JsonPropertyName("source_unavailable_port_count")]
    public int SourceUnavailablePortCount { get; init; }

    [JsonPropertyName("technical_failed_port_count")]
    public int TechnicalFailedPortCount { get; init; }

    [JsonPropertyName("failed_port_count")]
    public int FailedPortCount { get; init; }

    [JsonPropertyName("forecast_count")]
    public int ForecastCount { get; init; }

    [JsonPropertyName("error_count")]
    public int ErrorCount { get; init; }

    [JsonPropertyName("technical_error_count")]
    public int TechnicalErrorCount { get; init; }

    [JsonPropertyName("quality_warning_count")]
    public int QualityWarningCount { get; init; }

    [JsonPropertyName("source_retry_completed")]
    public bool SourceRetryCompleted { get; init; }

    [JsonPropertyName("status")]
    public string Status { get; init; } = BatchStatusCodes.Running;
}
