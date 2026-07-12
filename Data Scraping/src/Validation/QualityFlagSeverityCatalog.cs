namespace BmkgScraper.Validation;

internal static class QualityFlagSeverityCatalog
{
    public const string Info = "INFO";
    public const string Warning = "WARNING";
    public const string Critical = "CRITICAL";

    public static string Resolve(string qualityFlag)
    {
        return qualityFlag switch
        {
            QualityFlagCodes.TideMissing => Info,
            QualityFlagCodes.ForecastPeriodLagged => Info,

            QualityFlagCodes.ForecastStale => Warning,
            QualityFlagCodes.GustLowerThanWindSpeed => Warning,
            QualityFlagCodes.CurrentSpeedSpike => Warning,
            QualityFlagCodes.UnexpectedForecastCount => Warning,
            QualityFlagCodes.DuplicateForecastTime => Warning,
            QualityFlagCodes.ForecastTimeNotSorted => Warning,
            QualityFlagCodes.ForecastTimeGap => Warning,
            QualityFlagCodes.VisibilityParseFailed => Warning,
            QualityFlagCodes.TideParseFailed => Warning,

            QualityFlagCodes.VisibilityOutOfRange => Critical,
            QualityFlagCodes.NegativeWindSpeed => Critical,
            QualityFlagCodes.NegativeWaveHeight => Critical,
            QualityFlagCodes.NegativeCurrentSpeed => Critical,
            QualityFlagCodes.CurrentSpeedOutOfRange => Critical,
            QualityFlagCodes.HumidityOutOfRange => Critical,
            QualityFlagCodes.TemperatureOutOfRange => Critical,

            _ => Warning
        };
    }
}
