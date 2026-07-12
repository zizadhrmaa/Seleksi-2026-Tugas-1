namespace BmkgScraper.Validation;

internal static class QualityFlagCodes
{
    public const string VisibilityParseFailed =
        "VISIBILITY_PARSE_FAILED";

    public const string VisibilityOutOfRange =
        "VISIBILITY_OUT_OF_RANGE";

    public const string TideMissing =
        "TIDE_MISSING";

    public const string TideParseFailed =
        "TIDE_PARSE_FAILED";

    public const string ForecastStale =
        "FORECAST_STALE";

    public const string GustLowerThanWindSpeed =
        "GUST_LOWER_THAN_WIND_SPEED";

    public const string NegativeWindSpeed =
        "NEGATIVE_WIND_SPEED";

    public const string NegativeWaveHeight =
        "NEGATIVE_WAVE_HEIGHT";

    public const string NegativeCurrentSpeed =
        "NEGATIVE_CURRENT_SPEED";

    public const string HumidityOutOfRange =
        "HUMIDITY_OUT_OF_RANGE";

    public const string TemperatureOutOfRange =
        "TEMPERATURE_OUT_OF_RANGE";
}
