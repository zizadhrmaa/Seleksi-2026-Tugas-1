using BmkgScraper.Models;
using BmkgScraper.Validation;
using HtmlAgilityPack;

namespace BmkgScraper.Parsers;

internal sealed class ForecastRowParser : IForecastRowParser
{
    private static readonly TimeSpan StaleForecastThreshold =
        TimeSpan.FromDays(7);

    private readonly MeasurementParser _measurementParser;
    private readonly IForecastValidator _forecastValidator;

    public ForecastRowParser(
        MeasurementParser measurementParser,
        IForecastValidator forecastValidator)
    {
        _measurementParser = measurementParser;
        _forecastValidator = forecastValidator;
    }

    public ForecastRowParseResult Parse(
        HtmlNode row,
        PortData port,
        ScrapeBatchContext batch,
        DateTimeOffset extractedAt)
    {
        string rawRowText = TextNormalizer.Clean(row.InnerText);

        try
        {
            HtmlNodeCollection? cells = row.SelectNodes("./td");

            if (cells is null || cells.Count < 9)
            {
                return ForecastRowParseResult.Failure(
                    ScrapeErrorCodes.InvalidColumnCount,
                    $"Jumlah kolom tidak valid. " +
                    $"Ditemukan {cells?.Count ?? 0}, minimal 9.",
                    rawRowText);
            }

            string forecastText = ExtractCellContent(cells[0]);

            if (!_measurementParser.TryParseForecastTime(
                    forecastText,
                    out DateTimeOffset forecastAt))
            {
                return ForecastRowParseResult.Failure(
                    ScrapeErrorCodes.ForecastTimeParseFailed,
                    $"Waktu gagal diproses: {forecastText}",
                    rawRowText);
            }

            string weather = ExtractCellContent(cells[1]);

            WindParseResult wind =
                _measurementParser.ParseWind(
                    ExtractCellContent(cells[2]));

            WaveParseResult wave =
                _measurementParser.ParseWave(
                    ExtractCellContent(cells[3]));

            CurrentParseResult current =
                _measurementParser.ParseCurrent(
                    ExtractCellContent(cells[4]));

            VisibilityParseResult visibility =
                _measurementParser.ParseVisibility(
                    ExtractCellContent(cells[5]));

            double temperatureCelsius =
                _measurementParser.ParseRequiredNumber(
                    ExtractCellContent(cells[6]));

            double humidityPercent =
                _measurementParser.ParseRequiredNumber(
                    ExtractCellContent(cells[7]));

            TideParseResult tide =
                _measurementParser.ParseTide(
                    ExtractCellContent(cells[8]));

            HashSet<string> qualityFlags = new(
                _forecastValidator.Validate(
                    wind,
                    wave,
                    current,
                    visibility,
                    tide,
                    temperatureCelsius,
                    humidityPercent),
                StringComparer.OrdinalIgnoreCase);

            TimeSpan forecastAge = extractedAt - forecastAt;

            if (forecastAge > StaleForecastThreshold)
            {
                qualityFlags.Add(
                    QualityFlagCodes.ForecastStale);
            }
            else if (forecastAge > TimeSpan.FromHours(24))
            {
                qualityFlags.Add(
                    QualityFlagCodes.ForecastPeriodLagged);
            }

            ForecastData forecast = new()
            {
                BatchId = batch.BatchId,
                BatchStartedAt = batch.BatchStartedAt,
                PortCode = port.PortCode,
                PortName = port.PortName,
                ForecastAt = forecastAt,
                Weather = weather,
                WindDirection = wind.Direction,
                WindSpeedKnot = wind.SpeedKnot,
                WindGustKnot = wind.GustKnot,
                WaveHeightMeter = wave.HeightMeter,
                WaveCategory = wave.Category,
                CurrentDirection = current.Direction,
                CurrentSpeedKnot = current.SpeedKnot,
                RawVisibility = visibility.RawValue,
                VisibilityKm = visibility.ValueKm,
                TemperatureCelsius = temperatureCelsius,
                HumidityPercent = humidityPercent,
                RawTide = tide.RawValue,
                TideMeter = tide.ValueMeter,
                QualityFlags = qualityFlags
                    .OrderBy(flag => flag)
                    .ToList(),
                SourceUrl = port.DetailUrl,
                ExtractedAt = extractedAt
            };

            return ForecastRowParseResult.Success(forecast);
        }
        catch (Exception exception)
        {
            return ForecastRowParseResult.Failure(
                ScrapeErrorCodes.RowParseFailed,
                exception.Message,
                rawRowText);
        }
    }

    private static string ExtractCellContent(HtmlNode cell)
    {
        List<string> contents = [];

        string text = TextNormalizer.Clean(cell.InnerText);

        if (!string.IsNullOrWhiteSpace(text))
        {
            contents.Add(text);
        }

        HtmlNodeCollection? images =
            cell.SelectNodes(".//img[@alt]");

        if (images is not null)
        {
            foreach (HtmlNode image in images)
            {
                string alternativeText =
                    TextNormalizer.Clean(
                        image.GetAttributeValue(
                            "alt",
                            string.Empty));

                if (!string.IsNullOrWhiteSpace(
                        alternativeText))
                {
                    contents.Add(alternativeText);
                }
            }
        }

        return string.Join(
            " | ",
            contents.Distinct(
                StringComparer.OrdinalIgnoreCase));
    }
}
