using BmkgScraper.Models;
using BmkgScraper.Validation;

namespace BmkgScraper.Services;

internal sealed class QualityReportBuilder
{
    private readonly double _currentSpeedSpikeThresholdKnot;

    public QualityReportBuilder(
        double currentSpeedSpikeThresholdKnot)
    {
        if (currentSpeedSpikeThresholdKnot <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(currentSpeedSpikeThresholdKnot));
        }

        _currentSpeedSpikeThresholdKnot =
            currentSpeedSpikeThresholdKnot;
    }

    public QualityReportResult Build(
        string batchId,
        IReadOnlyList<ForecastData> forecasts,
        IReadOnlyList<PortScrapeResultData> portResults,
        DateTimeOffset generatedAt)
    {
        Dictionary<QualityFlagKey, QualityFlagAccumulator> flagAccumulators = [];
        HashSet<string> affectedRecordKeys =
            new(StringComparer.OrdinalIgnoreCase);
        HashSet<string> affectedPortCodes =
            new(StringComparer.OrdinalIgnoreCase);
        List<AnomalyData> anomalies = [];

        int rowQualityFlagCount = 0;
        int seriesQualityFlagCount = 0;

        foreach (ForecastData forecast in forecasts)
        {
            if (forecast.QualityFlags.Count > 0)
            {
                affectedRecordKeys.Add(CreateRecordKey(forecast));
                affectedPortCodes.Add(forecast.PortCode);
            }

            foreach (string qualityFlag in forecast.QualityFlags)
            {
                rowQualityFlagCount++;

                AddFlagOccurrence(
                    flagAccumulators,
                    qualityFlag,
                    "ROW",
                    forecast.PortCode,
                    CreateRecordKey(forecast));

                AddExtremeValueAnomalies(
                    anomalies,
                    forecast,
                    qualityFlag);
            }
        }

        foreach (PortScrapeResultData portResult in portResults)
        {
            foreach (string qualityFlag in portResult.SeriesQualityFlags)
            {
                seriesQualityFlagCount++;
                affectedPortCodes.Add(portResult.PortCode);

                AddFlagOccurrence(
                    flagAccumulators,
                    qualityFlag,
                    "SERIES",
                    portResult.PortCode,
                    recordKey: null);
            }
        }

        AddCurrentSpeedSpikeAnomalies(
            anomalies,
            forecasts,
            portResults);

        IReadOnlyList<QualityFlagSummaryData> flagSummaries =
            flagAccumulators
                .OrderBy(pair => pair.Key.Code)
                .ThenBy(pair => pair.Key.Scope)
                .Select(pair => new QualityFlagSummaryData
                {
                    Code = pair.Key.Code,
                    Scope = pair.Key.Scope,
                    Severity =
                        QualityFlagSeverityCatalog.Resolve(
                            pair.Key.Code),
                    OccurrenceCount = pair.Value.OccurrenceCount,
                    AffectedRecordCount =
                        pair.Value.AffectedRecordKeys.Count,
                    AffectedPortCount =
                        pair.Value.AffectedPortCodes.Count
                })
                .ToList();

        IReadOnlyList<AnomalyData> orderedAnomalies = anomalies
            .DistinctBy(CreateAnomalyKey)
            .OrderBy(anomaly => anomaly.PortName)
            .ThenBy(anomaly => anomaly.ForecastAt)
            .ThenBy(anomaly => anomaly.QualityFlag)
            .ThenBy(anomaly => anomaly.FieldName)
            .ToList();

        int infoCount = flagSummaries
            .Where(flag => flag.Severity ==
                QualityFlagSeverityCatalog.Info)
            .Sum(flag => flag.OccurrenceCount);

        int warningCount = flagSummaries
            .Where(flag => flag.Severity ==
                QualityFlagSeverityCatalog.Warning)
            .Sum(flag => flag.OccurrenceCount);

        int criticalCount = flagSummaries
            .Where(flag => flag.Severity ==
                QualityFlagSeverityCatalog.Critical)
            .Sum(flag => flag.OccurrenceCount);

        QualitySummaryData summary = new()
        {
            BatchId = batchId,
            GeneratedAt = generatedAt,
            TotalQualityFlagCount =
                rowQualityFlagCount + seriesQualityFlagCount,
            RowQualityFlagCount = rowQualityFlagCount,
            SeriesQualityFlagCount = seriesQualityFlagCount,
            AffectedRecordCount = affectedRecordKeys.Count,
            AffectedPortCount = affectedPortCodes.Count,
            InfoCount = infoCount,
            WarningCount = warningCount,
            CriticalCount = criticalCount,
            AnomalyCount = orderedAnomalies.Count,
            Flags = flagSummaries
        };

        return new QualityReportResult(
            summary,
            orderedAnomalies);
    }

    private static void AddFlagOccurrence(
        IDictionary<QualityFlagKey, QualityFlagAccumulator> accumulators,
        string qualityFlag,
        string scope,
        string portCode,
        string? recordKey)
    {
        QualityFlagKey key = new(qualityFlag, scope);

        if (!accumulators.TryGetValue(
                key,
                out QualityFlagAccumulator? accumulator))
        {
            accumulator = new QualityFlagAccumulator();
            accumulators[key] = accumulator;
        }

        accumulator.OccurrenceCount++;
        accumulator.AffectedPortCodes.Add(portCode);

        if (!string.IsNullOrWhiteSpace(recordKey))
        {
            accumulator.AffectedRecordKeys.Add(recordKey);
        }
    }

    private static void AddExtremeValueAnomalies(
        ICollection<AnomalyData> anomalies,
        ForecastData forecast,
        string qualityFlag)
    {
        switch (qualityFlag)
        {
            case QualityFlagCodes.VisibilityOutOfRange:
                anomalies.Add(CreateRowAnomaly(
                    forecast,
                    qualityFlag,
                    "visibility_km",
                    forecast.VisibilityKm,
                    "Jarak pandang berada di luar rentang validasi."));
                break;

            case QualityFlagCodes.NegativeWindSpeed:
                if (forecast.WindSpeedKnot < 0)
                {
                    anomalies.Add(CreateRowAnomaly(
                        forecast,
                        qualityFlag,
                        "wind_speed_knot",
                        forecast.WindSpeedKnot,
                        "Kecepatan angin bernilai negatif."));
                }

                if (forecast.WindGustKnot < 0)
                {
                    anomalies.Add(CreateRowAnomaly(
                        forecast,
                        qualityFlag,
                        "wind_gust_knot",
                        forecast.WindGustKnot,
                        "Kecepatan gust bernilai negatif."));
                }

                break;

            case QualityFlagCodes.NegativeWaveHeight:
                anomalies.Add(CreateRowAnomaly(
                    forecast,
                    qualityFlag,
                    "wave_height_meter",
                    forecast.WaveHeightMeter,
                    "Tinggi gelombang bernilai negatif."));
                break;

            case QualityFlagCodes.NegativeCurrentSpeed:
                anomalies.Add(CreateRowAnomaly(
                    forecast,
                    qualityFlag,
                    "current_speed_knot",
                    forecast.CurrentSpeedKnot,
                    "Kecepatan arus bernilai negatif."));
                break;

            case QualityFlagCodes.CurrentSpeedOutOfRange:
                anomalies.Add(CreateRowAnomaly(
                    forecast,
                    qualityFlag,
                    "current_speed_knot",
                    forecast.CurrentSpeedKnot,
                    "Kecepatan arus melampaui batas validasi."));
                break;

            case QualityFlagCodes.HumidityOutOfRange:
                anomalies.Add(CreateRowAnomaly(
                    forecast,
                    qualityFlag,
                    "humidity_percent",
                    forecast.HumidityPercent,
                    "Kelembapan berada di luar rentang 0-100 persen."));
                break;

            case QualityFlagCodes.TemperatureOutOfRange:
                anomalies.Add(CreateRowAnomaly(
                    forecast,
                    qualityFlag,
                    "temperature_celsius",
                    forecast.TemperatureCelsius,
                    "Suhu berada di luar rentang validasi."));
                break;
        }
    }

    private void AddCurrentSpeedSpikeAnomalies(
        ICollection<AnomalyData> anomalies,
        IReadOnlyList<ForecastData> forecasts,
        IReadOnlyList<PortScrapeResultData> portResults)
    {
        HashSet<string> portsWithSpikeFlag = portResults
            .Where(result => result.SeriesQualityFlags.Contains(
                QualityFlagCodes.CurrentSpeedSpike,
                StringComparer.OrdinalIgnoreCase))
            .Select(result => result.PortCode)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        foreach (IGrouping<string, ForecastData> portForecasts in forecasts
                     .Where(forecast =>
                         portsWithSpikeFlag.Contains(forecast.PortCode))
                     .GroupBy(
                         forecast => forecast.PortCode,
                         StringComparer.OrdinalIgnoreCase))
        {
            List<ForecastData> orderedForecasts = portForecasts
                .OrderBy(forecast => forecast.ForecastAt)
                .ToList();

            for (int index = 1;
                 index < orderedForecasts.Count;
                 index++)
            {
                ForecastData previous = orderedForecasts[index - 1];
                ForecastData current = orderedForecasts[index];

                double difference = Math.Abs(
                    current.CurrentSpeedKnot -
                    previous.CurrentSpeedKnot);

                if (difference < _currentSpeedSpikeThresholdKnot)
                {
                    continue;
                }

                anomalies.Add(new AnomalyData
                {
                    BatchId = current.BatchId,
                    PortCode = current.PortCode,
                    PortName = current.PortName,
                    Scope = "SERIES",
                    ForecastAt = current.ForecastAt,
                    FieldName = "current_speed_knot",
                    ParsedValue = current.CurrentSpeedKnot,
                    PreviousValue = previous.CurrentSpeedKnot,
                    QualityFlag =
                        QualityFlagCodes.CurrentSpeedSpike,
                    Severity =
                        QualityFlagSeverityCatalog.Resolve(
                            QualityFlagCodes.CurrentSpeedSpike),
                    Message =
                        "Perubahan kecepatan arus antartitik waktu " +
                        $"mencapai {difference:0.###} knot.",
                    SourceUrl = current.SourceUrl,
                    ExtractedAt = current.ExtractedAt
                });
            }
        }
    }

    private static AnomalyData CreateRowAnomaly(
        ForecastData forecast,
        string qualityFlag,
        string fieldName,
        double? parsedValue,
        string message)
    {
        return new AnomalyData
        {
            BatchId = forecast.BatchId,
            PortCode = forecast.PortCode,
            PortName = forecast.PortName,
            Scope = "ROW",
            ForecastAt = forecast.ForecastAt,
            FieldName = fieldName,
            ParsedValue = parsedValue,
            PreviousValue = null,
            QualityFlag = qualityFlag,
            Severity =
                QualityFlagSeverityCatalog.Resolve(qualityFlag),
            Message = message,
            SourceUrl = forecast.SourceUrl,
            ExtractedAt = forecast.ExtractedAt
        };
    }

    private static string CreateRecordKey(ForecastData forecast)
    {
        return $"{forecast.PortCode}|{forecast.ForecastAt:O}";
    }

    private static string CreateAnomalyKey(AnomalyData anomaly)
    {
        return string.Join(
            "|",
            anomaly.PortCode,
            anomaly.Scope,
            anomaly.ForecastAt?.ToString("O") ?? string.Empty,
            anomaly.FieldName ?? string.Empty,
            anomaly.QualityFlag,
            anomaly.ParsedValue?.ToString("R") ?? string.Empty,
            anomaly.PreviousValue?.ToString("R") ?? string.Empty);
    }

    private sealed record QualityFlagKey(
        string Code,
        string Scope);

    private sealed class QualityFlagAccumulator
    {
        public int OccurrenceCount { get; set; }

        public HashSet<string> AffectedRecordKeys { get; } =
            new(StringComparer.OrdinalIgnoreCase);

        public HashSet<string> AffectedPortCodes { get; } =
            new(StringComparer.OrdinalIgnoreCase);
    }
}
