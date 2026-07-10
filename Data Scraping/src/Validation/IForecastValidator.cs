using BmkgScraper.Models;

namespace BmkgScraper.Validation;

internal interface IForecastValidator
{
    IReadOnlyList<string> Validate(
        WindParseResult wind,
        WaveParseResult wave,
        CurrentParseResult current,
        VisibilityParseResult visibility,
        TideParseResult tide,
        double temperatureCelsius,
        double humidityPercent);
}
