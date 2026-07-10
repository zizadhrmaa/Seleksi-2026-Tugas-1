using BmkgScraper.Models;

namespace BmkgScraper.Validation;

internal sealed class ForecastValidator : IForecastValidator
{
    public IReadOnlyList<string> Validate(
        WindParseResult wind,
        WaveParseResult wave,
        CurrentParseResult current,
        VisibilityParseResult visibility,
        TideParseResult tide,
        double temperatureCelsius,
        double humidityPercent)
    {
        HashSet<string> qualityFlags = new(
            visibility.QualityFlags,
            StringComparer.OrdinalIgnoreCase);

        qualityFlags.UnionWith(tide.QualityFlags);

        if (wind.GustKnot < wind.SpeedKnot)
        {
            qualityFlags.Add(QualityFlagCodes.GustLowerThanWindSpeed);
        }

        if (wind.SpeedKnot < 0 || wind.GustKnot < 0)
        {
            qualityFlags.Add(QualityFlagCodes.NegativeWindSpeed);
        }

        if (wave.HeightMeter < 0)
        {
            qualityFlags.Add(QualityFlagCodes.NegativeWaveHeight);
        }

        if (current.SpeedKnot < 0)
        {
            qualityFlags.Add(QualityFlagCodes.NegativeCurrentSpeed);
        }

        if (humidityPercent is < 0 or > 100)
        {
            qualityFlags.Add(QualityFlagCodes.HumidityOutOfRange);
        }

        if (temperatureCelsius is < -10 or > 60)
        {
            qualityFlags.Add(QualityFlagCodes.TemperatureOutOfRange);
        }

        return qualityFlags
            .OrderBy(flag => flag)
            .ToList();
    }
}
