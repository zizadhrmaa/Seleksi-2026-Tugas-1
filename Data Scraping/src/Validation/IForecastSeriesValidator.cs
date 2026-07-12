using BmkgScraper.Models;

namespace BmkgScraper.Validation;

internal interface IForecastSeriesValidator
{
    IReadOnlyList<string> Validate(
        IReadOnlyList<ForecastData> forecasts);
}
