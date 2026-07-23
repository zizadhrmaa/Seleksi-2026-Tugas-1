namespace NdbcDataLoader.Models;

internal sealed record LoadSummary(
    string ScrapeRunId,
    int SourceStationCount,
    int SourceObservationCount,
    int InsertedObservationCount,
    int UpdatedObservationCount,
    int UnchangedObservationCount,
    long DatabaseStationCount,
    long DatabaseObservationCount);
