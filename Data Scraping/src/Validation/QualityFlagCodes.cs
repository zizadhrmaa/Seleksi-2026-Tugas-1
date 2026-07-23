namespace NdbcScraper.Validation;

internal static class QualityFlagCodes
{
    public const string WindDirectionOutOfRange =
        "WIND_DIRECTION_OUT_OF_RANGE";

    public const string MeanWaveDirectionOutOfRange =
        "MEAN_WAVE_DIRECTION_OUT_OF_RANGE";

    public const string NegativeWindSpeed =
        "NEGATIVE_WIND_SPEED";

    public const string NegativeWindGust =
        "NEGATIVE_WIND_GUST";

    public const string GustLowerThanWindSpeed =
        "GUST_LOWER_THAN_WIND_SPEED";

    public const string NegativeWaveHeight =
        "NEGATIVE_WAVE_HEIGHT";

    public const string NegativeDominantWavePeriod =
        "NEGATIVE_DOMINANT_WAVE_PERIOD";

    public const string NegativeAverageWavePeriod =
        "NEGATIVE_AVERAGE_WAVE_PERIOD";

    public const string SeaTemperatureOutOfRange =
        "SEA_TEMPERATURE_OUT_OF_RANGE";

    public const string AllTargetMeasurementsMissing =
        "ALL_TARGET_MEASUREMENTS_MISSING";

    public static string ParseFailed(string columnName)
    {
        return $"{columnName.ToUpperInvariant()}_PARSE_FAILED";
    }
}
