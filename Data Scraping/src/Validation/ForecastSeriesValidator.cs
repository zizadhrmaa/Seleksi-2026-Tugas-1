using BmkgScraper.Models;

namespace BmkgScraper.Validation;

internal sealed class ForecastSeriesValidator : IForecastSeriesValidator
{
    private readonly int _expectedForecastCount;
    private readonly double _currentSpeedSpikeThresholdKnot;

    public ForecastSeriesValidator(
        int expectedForecastCount,
        double currentSpeedSpikeThresholdKnot)
    {
        if (expectedForecastCount <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(expectedForecastCount));
        }

        if (currentSpeedSpikeThresholdKnot <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(currentSpeedSpikeThresholdKnot));
        }

        _expectedForecastCount = expectedForecastCount;
        _currentSpeedSpikeThresholdKnot =
            currentSpeedSpikeThresholdKnot;
    }

    public IReadOnlyList<string> Validate(
        IReadOnlyList<ForecastData> forecasts)
    {
        HashSet<string> qualityFlags =
            new(StringComparer.OrdinalIgnoreCase);

        if (forecasts.Count != _expectedForecastCount)
        {
            qualityFlags.Add(
                QualityFlagCodes.UnexpectedForecastCount);
        }

        if (forecasts.Count <= 1)
        {
            return qualityFlags.OrderBy(flag => flag).ToList();
        }

        HashSet<DateTimeOffset> forecastTimes = [];

        for (int index = 0; index < forecasts.Count; index++)
        {
            ForecastData current = forecasts[index];

            if (!forecastTimes.Add(current.ForecastAt))
            {
                qualityFlags.Add(
                    QualityFlagCodes.DuplicateForecastTime);
            }

            if (index == 0)
            {
                continue;
            }

            ForecastData previous = forecasts[index - 1];
            TimeSpan gap = current.ForecastAt - previous.ForecastAt;

            if (gap <= TimeSpan.Zero)
            {
                qualityFlags.Add(
                    QualityFlagCodes.ForecastTimeNotSorted);
            }
            else if (gap != TimeSpan.FromHours(1) &&
                     gap != TimeSpan.FromHours(3))
            {
                qualityFlags.Add(
                    QualityFlagCodes.ForecastTimeGap);
            }

            double currentSpeedDifference = Math.Abs(
                current.CurrentSpeedKnot -
                previous.CurrentSpeedKnot);

            if (currentSpeedDifference >=
                _currentSpeedSpikeThresholdKnot)
            {
                qualityFlags.Add(
                    QualityFlagCodes.CurrentSpeedSpike);
            }
        }

        return qualityFlags
            .OrderBy(flag => flag)
            .ToList();
    }
}
