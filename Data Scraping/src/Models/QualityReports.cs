using System.Text.Json.Serialization;

namespace BmkgScraper.Models;

internal sealed class QualityFlagSummaryData
{
    [JsonPropertyName("code")]
    public string Code { get; init; } = string.Empty;

    [JsonPropertyName("severity")]
    public string Severity { get; init; } = string.Empty;

    [JsonPropertyName("scope")]
    public string Scope { get; init; } = string.Empty;

    [JsonPropertyName("occurrence_count")]
    public int OccurrenceCount { get; init; }

    [JsonPropertyName("affected_record_count")]
    public int AffectedRecordCount { get; init; }

    [JsonPropertyName("affected_port_count")]
    public int AffectedPortCount { get; init; }
}

internal sealed class QualitySummaryData
{
    [JsonPropertyName("batch_id")]
    public string BatchId { get; init; } = string.Empty;

    [JsonPropertyName("generated_at")]
    public DateTimeOffset GeneratedAt { get; init; }

    [JsonPropertyName("total_quality_flag_count")]
    public int TotalQualityFlagCount { get; init; }

    [JsonPropertyName("row_quality_flag_count")]
    public int RowQualityFlagCount { get; init; }

    [JsonPropertyName("series_quality_flag_count")]
    public int SeriesQualityFlagCount { get; init; }

    [JsonPropertyName("affected_record_count")]
    public int AffectedRecordCount { get; init; }

    [JsonPropertyName("affected_port_count")]
    public int AffectedPortCount { get; init; }

    [JsonPropertyName("info_count")]
    public int InfoCount { get; init; }

    [JsonPropertyName("warning_count")]
    public int WarningCount { get; init; }

    [JsonPropertyName("critical_count")]
    public int CriticalCount { get; init; }

    [JsonPropertyName("anomaly_count")]
    public int AnomalyCount { get; init; }

    [JsonPropertyName("flags")]
    public IReadOnlyList<QualityFlagSummaryData> Flags { get; init; } = [];
}

internal sealed class AnomalyData
{
    [JsonPropertyName("batch_id")]
    public string BatchId { get; init; } = string.Empty;

    [JsonPropertyName("port_code")]
    public string PortCode { get; init; } = string.Empty;

    [JsonPropertyName("port_name")]
    public string PortName { get; init; } = string.Empty;

    [JsonPropertyName("scope")]
    public string Scope { get; init; } = string.Empty;

    [JsonPropertyName("forecast_at")]
    public DateTimeOffset? ForecastAt { get; init; }

    [JsonPropertyName("field_name")]
    public string? FieldName { get; init; }

    [JsonPropertyName("parsed_value")]
    public double? ParsedValue { get; init; }

    [JsonPropertyName("previous_value")]
    public double? PreviousValue { get; init; }

    [JsonPropertyName("quality_flag")]
    public string QualityFlag { get; init; } = string.Empty;

    [JsonPropertyName("severity")]
    public string Severity { get; init; } = string.Empty;

    [JsonPropertyName("message")]
    public string Message { get; init; } = string.Empty;

    [JsonPropertyName("source_url")]
    public string? SourceUrl { get; init; }

    [JsonPropertyName("extracted_at")]
    public DateTimeOffset? ExtractedAt { get; init; }
}

internal sealed record QualityReportResult(
    QualitySummaryData Summary,
    IReadOnlyList<AnomalyData> Anomalies);
