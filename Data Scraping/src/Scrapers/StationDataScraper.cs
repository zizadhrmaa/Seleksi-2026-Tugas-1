using System.Net;
using NdbcScraper.Http;
using NdbcScraper.Models;
using NdbcScraper.Parsing;

namespace NdbcScraper.Scrapers;

internal sealed class StationDataScraper : IStationDataScraper
{
    private readonly IHttpFetcher _httpFetcher;
    private readonly StationMetadataParser _metadataParser;
    private readonly ObservationParser _observationParser;

    public StationDataScraper(
        IHttpFetcher httpFetcher,
        StationMetadataParser metadataParser,
        ObservationParser observationParser)
    {
        _httpFetcher = httpFetcher;
        _metadataParser = metadataParser;
        _observationParser = observationParser;
    }

    public async Task<StationScrapeResult> ScrapeAsync(
        StationCandidate candidate,
        string scrapeRunId,
        CancellationToken cancellationToken = default)
    {
        DateTimeOffset extractedAt = DateTimeOffset.UtcNow;
        HttpFetchResult detailResult;

        try
        {
            detailResult = await _httpFetcher.GetStringAsync(
                new Uri(candidate.DetailUrl),
                cancellationToken);
        }
        catch (HttpFetchException exception)
        {
            return Failure(
                candidate,
                scrapeRunId,
                ScrapeErrorCodes.DetailRequestFailed,
                exception.Message,
                exception,
                extractedAt);
        }

        StationMetadataParseResult metadataResult;

        try
        {
            metadataResult = _metadataParser.Parse(
                detailResult.Content,
                candidate,
                scrapeRunId,
                extractedAt);
        }
        catch (Exception exception)
        {
            ScrapeErrorData error = new()
            {
                ScrapeRunId = scrapeRunId,
                StationId = candidate.StationId,
                Scope = "STATION",
                ErrorCode = ScrapeErrorCodes.DetailParseFailed,
                Message = exception.Message,
                SourceUrl = candidate.DetailUrl,
                SourceRowNumber = null,
                RawData = null,
                HttpStatusCode = (int)detailResult.StatusCode,
                AttemptCount = detailResult.AttemptCount,
                OccurredAt = extractedAt
            };

            return new StationScrapeResult(
                StationScrapeOutcomes.Failed,
                null,
                Array.Empty<ObservationData>(),
                new[] { error },
                0,
                0);
        }

        if (!metadataResult.IsBuoy)
        {
            return new StationScrapeResult(
                StationScrapeOutcomes.NotBuoy,
                metadataResult.Station,
                Array.Empty<ObservationData>(),
                Array.Empty<ScrapeErrorData>(),
                0,
                0);
        }

        HttpFetchResult realtimeResult;

        try
        {
            realtimeResult = await _httpFetcher.GetStringAsync(
                new Uri(metadataResult.Station.RealtimeDataUrl),
                cancellationToken);
        }
        catch (HttpFetchException exception)
        {
            if (exception.StatusCode == HttpStatusCode.NotFound)
            {
                metadataResult.Station.Status = "NO_REALTIME_DATA";

                return new StationScrapeResult(
                    StationScrapeOutcomes.NoRealtimeData,
                    metadataResult.Station,
                    Array.Empty<ObservationData>(),
                    Array.Empty<ScrapeErrorData>(),
                    0,
                    0);
            }

            ScrapeErrorData error = CreateHttpError(
                candidate,
                scrapeRunId,
                metadataResult.Station.RealtimeDataUrl,
                ScrapeErrorCodes.RealtimeRequestFailed,
                exception,
                extractedAt);

            return new StationScrapeResult(
                StationScrapeOutcomes.Failed,
                metadataResult.Station,
                Array.Empty<ObservationData>(),
                new[] { error },
                0,
                0);
        }

        ObservationParseResult observationResult;

        try
        {
            observationResult = _observationParser.Parse(
                realtimeResult.Content,
                candidate.StationId,
                scrapeRunId,
                metadataResult.Station.RealtimeDataUrl,
                extractedAt);
        }
        catch (Exception exception)
        {
            ScrapeErrorData error = new()
            {
                ScrapeRunId = scrapeRunId,
                StationId = candidate.StationId,
                Scope = "FILE",
                ErrorCode = ScrapeErrorCodes.ObservationValueInvalid,
                Message = exception.Message,
                SourceUrl = metadataResult.Station.RealtimeDataUrl,
                SourceRowNumber = null,
                RawData = null,
                HttpStatusCode = (int)realtimeResult.StatusCode,
                AttemptCount = realtimeResult.AttemptCount,
                OccurredAt = extractedAt
            };

            return new StationScrapeResult(
                StationScrapeOutcomes.Failed,
                metadataResult.Station,
                Array.Empty<ObservationData>(),
                new[] { error },
                0,
                0);
        }

        bool hasRelevantMeasurements =
            observationResult.Observations.Count > 0;

        if (!hasRelevantMeasurements)
        {
            metadataResult.Station.Status = "NO_RELEVANT_DATA";

            return new StationScrapeResult(
                StationScrapeOutcomes.NoRelevantMeasurements,
                metadataResult.Station,
                observationResult.Observations,
                observationResult.Errors,
                observationResult.SourceRowCount,
                observationResult.DuplicateCount);
        }

        return new StationScrapeResult(
            StationScrapeOutcomes.Success,
            metadataResult.Station,
            observationResult.Observations,
            observationResult.Errors,
            observationResult.SourceRowCount,
            observationResult.DuplicateCount);
    }

    private static StationScrapeResult Failure(
        StationCandidate candidate,
        string scrapeRunId,
        string errorCode,
        string message,
        HttpFetchException exception,
        DateTimeOffset occurredAt)
    {
        ScrapeErrorData error = CreateHttpError(
            candidate,
            scrapeRunId,
            candidate.DetailUrl,
            errorCode,
            exception,
            occurredAt);

        return new StationScrapeResult(
            StationScrapeOutcomes.Failed,
            null,
            Array.Empty<ObservationData>(),
            new[] { error },
            0,
            0);
    }

    private static ScrapeErrorData CreateHttpError(
        StationCandidate candidate,
        string scrapeRunId,
        string sourceUrl,
        string errorCode,
        HttpFetchException exception,
        DateTimeOffset occurredAt)
    {
        return new ScrapeErrorData
        {
            ScrapeRunId = scrapeRunId,
            StationId = candidate.StationId,
            Scope = "HTTP",
            ErrorCode = errorCode,
            Message = exception.Message,
            SourceUrl = sourceUrl,
            SourceRowNumber = null,
            RawData = null,
            HttpStatusCode = exception.StatusCode is null
                ? null
                : (int)exception.StatusCode,
            AttemptCount = exception.AttemptCount,
            OccurredAt = occurredAt
        };
    }
}
