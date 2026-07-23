using NdbcScraper.Models;

namespace NdbcScraper.Validation;

internal sealed class ObservationQualityValidator
{
    public IReadOnlyList<string> ValidateAndNormalize(
        ObservationData observation,
        IEnumerable<string> parserFlags)
    {
        HashSet<string> flags = new(
            parserFlags,
            StringComparer.OrdinalIgnoreCase);

        if (observation.WindDirectionDegree is < 0 or > 360)
        {
            observation.WindDirectionDegree = null;
            flags.Add(QualityFlagCodes.WindDirectionOutOfRange);
        }

        if (observation.MeanWaveDirectionDegree is < 0 or > 360)
        {
            observation.MeanWaveDirectionDegree = null;
            flags.Add(QualityFlagCodes.MeanWaveDirectionOutOfRange);
        }

        if (observation.WindSpeedMeterPerSecond < 0)
        {
            observation.WindSpeedMeterPerSecond = null;
            flags.Add(QualityFlagCodes.NegativeWindSpeed);
        }

        if (observation.WindGustMeterPerSecond < 0)
        {
            observation.WindGustMeterPerSecond = null;
            flags.Add(QualityFlagCodes.NegativeWindGust);
        }

        if (observation.WindGustMeterPerSecond is not null &&
            observation.WindSpeedMeterPerSecond is not null &&
            observation.WindGustMeterPerSecond <
            observation.WindSpeedMeterPerSecond)
        {
            flags.Add(QualityFlagCodes.GustLowerThanWindSpeed);
        }

        if (observation.WaveHeightMeter < 0)
        {
            observation.WaveHeightMeter = null;
            flags.Add(QualityFlagCodes.NegativeWaveHeight);
        }

        if (observation.DominantWavePeriodSecond < 0)
        {
            observation.DominantWavePeriodSecond = null;
            flags.Add(QualityFlagCodes.NegativeDominantWavePeriod);
        }

        if (observation.AverageWavePeriodSecond < 0)
        {
            observation.AverageWavePeriodSecond = null;
            flags.Add(QualityFlagCodes.NegativeAverageWavePeriod);
        }

        if (observation.SeaSurfaceTemperatureCelsius is < -5 or > 50)
        {
            observation.SeaSurfaceTemperatureCelsius = null;
            flags.Add(QualityFlagCodes.SeaTemperatureOutOfRange);
        }

        if (observation.AvailableMeasurementCount == 0)
        {
            flags.Add(QualityFlagCodes.AllTargetMeasurementsMissing);
        }

        return flags.OrderBy(flag => flag).ToList();
    }
}
