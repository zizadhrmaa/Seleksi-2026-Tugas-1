namespace NdbcScraper.Models;

internal sealed record StationMetadataParseResult(
    StationData Station,
    bool IsBuoy);

internal sealed record ObservationParseResult(
    IReadOnlyList<ObservationData> Observations,
    IReadOnlyList<ScrapeErrorData> Errors,
    int SourceRowCount,
    int DuplicateCount,
    bool HeaderFound);

internal static class StationScrapeOutcomes
{
    public const string Success = "SUCCESS";
    public const string NotBuoy = "NOT_BUOY";
    public const string NoRealtimeData = "NO_REALTIME_DATA";
    public const string NoRelevantMeasurements = "NO_RELEVANT_MEASUREMENTS";
    public const string Failed = "FAILED";
}

internal sealed record StationScrapeResult(
    string Outcome,
    StationData? Station,
    IReadOnlyList<ObservationData> Observations,
    IReadOnlyList<ScrapeErrorData> Errors,
    int SourceRowCount,
    int DuplicateCount)
{
    public bool IsSuccess =>
        Outcome.Equals(
            StationScrapeOutcomes.Success,
            StringComparison.Ordinal);
}
