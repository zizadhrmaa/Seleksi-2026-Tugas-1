using System.Globalization;
using NdbcScraper.Models;
using NdbcScraper.Validation;

namespace NdbcScraper.Parsing;

internal sealed class ObservationParser
{
    private static readonly string[] TargetColumns =
    {
        "WDIR", "WSPD", "GST", "WVHT", "DPD", "APD", "MWD", "WTMP"
    };

    private readonly ObservationQualityValidator _validator;

    public ObservationParser(ObservationQualityValidator validator)
    {
        _validator = validator;
    }

    public ObservationParseResult Parse(
        string content,
        string stationId,
        string scrapeRunId,
        string sourceUrl,
        DateTimeOffset extractedAt)
    {
        string[] lines = content
            .Replace("\r\n", "\n", StringComparison.Ordinal)
            .Replace('\r', '\n')
            .Split('\n');

        int headerLineIndex = FindHeaderLineIndex(lines);

        if (headerLineIndex < 0)
        {
            ScrapeErrorData headerError = new()
            {
                ScrapeRunId = scrapeRunId,
                StationId = stationId,
                Scope = "FILE",
                ErrorCode = ScrapeErrorCodes.ObservationHeaderNotFound,
                Message = "Header standard meteorological data tidak ditemukan.",
                SourceUrl = sourceUrl,
                SourceRowNumber = null,
                RawData = null,
                HttpStatusCode = null,
                AttemptCount = null,
                OccurredAt = extractedAt
            };

            return new ObservationParseResult(
                Array.Empty<ObservationData>(),
                new[] { headerError },
                0,
                0,
                false);
        }

        string[] headers = SplitTokens(lines[headerLineIndex]);
        ColumnMap columns = ColumnMap.Create(headers);

        List<ObservationData> observations = new();
        List<ScrapeErrorData> errors = new();
        int sourceRowCount = 0;

        for (int lineIndex = headerLineIndex + 1;
             lineIndex < lines.Length;
             lineIndex++)
        {
            string rawLine = lines[lineIndex].Trim();

            if (string.IsNullOrWhiteSpace(rawLine) ||
                rawLine.StartsWith('#'))
            {
                continue;
            }

            sourceRowCount++;
            string[] values = SplitTokens(rawLine);

            if (values.Length <= columns.MinimumRequiredIndex)
            {
                errors.Add(CreateRowError(
                    scrapeRunId,
                    stationId,
                    sourceUrl,
                    lineIndex + 1,
                    ScrapeErrorCodes.ObservationRowTooShort,
                    "Jumlah nilai pada baris lebih pendek dari kolom waktu.",
                    rawLine,
                    extractedAt));
                continue;
            }

            if (!TryParseObservedAt(values, columns, out DateTimeOffset observedAt))
            {
                errors.Add(CreateRowError(
                    scrapeRunId,
                    stationId,
                    sourceUrl,
                    lineIndex + 1,
                    ScrapeErrorCodes.ObservationTimeInvalid,
                    "Tanggal atau waktu observasi tidak valid.",
                    rawLine,
                    extractedAt));
                continue;
            }

            List<string> parserFlags = new();

            ObservationData observation = new()
            {
                ScrapeRunId = scrapeRunId,
                StationId = stationId,
                ObservedAtUtc = observedAt,
                WindDirectionDegree = ParseNullableInteger(
                    values,
                    columns.GetIndex("WDIR"),
                    "WDIR",
                    parserFlags),
                WindSpeedMeterPerSecond = ParseNullableDouble(
                    values,
                    columns.GetIndex("WSPD"),
                    "WSPD",
                    parserFlags),
                WindGustMeterPerSecond = ParseNullableDouble(
                    values,
                    columns.GetIndex("GST"),
                    "GST",
                    parserFlags),
                WaveHeightMeter = ParseNullableDouble(
                    values,
                    columns.GetIndex("WVHT"),
                    "WVHT",
                    parserFlags),
                DominantWavePeriodSecond = ParseNullableDouble(
                    values,
                    columns.GetIndex("DPD"),
                    "DPD",
                    parserFlags),
                AverageWavePeriodSecond = ParseNullableDouble(
                    values,
                    columns.GetIndex("APD"),
                    "APD",
                    parserFlags),
                MeanWaveDirectionDegree = ParseNullableInteger(
                    values,
                    columns.GetIndex("MWD"),
                    "MWD",
                    parserFlags),
                SeaSurfaceTemperatureCelsius = ParseNullableDouble(
                    values,
                    columns.GetIndex("WTMP"),
                    "WTMP",
                    parserFlags),
                QualityFlags = Array.Empty<string>(),
                SourceRowNumber = lineIndex + 1,
                SourceUrl = sourceUrl,
                ExtractedAt = extractedAt
            };

            observation.QualityFlags =
                _validator.ValidateAndNormalize(observation, parserFlags);

            if (observation.AvailableMeasurementCount == 0)
            {
                continue;
            }

            observations.Add(observation);
        }

        List<ObservationData> deduplicated = observations
            .GroupBy(observation => observation.ObservedAtUtc)
            .Select(group => group
                .OrderByDescending(observation =>
                    observation.AvailableMeasurementCount)
                .ThenBy(observation => observation.SourceRowNumber)
                .First())
            .OrderBy(observation => observation.ObservedAtUtc)
            .ToList();

        int duplicateCount = observations.Count - deduplicated.Count;

        return new ObservationParseResult(
            deduplicated,
            errors,
            sourceRowCount,
            duplicateCount,
            true);
    }

    private static int FindHeaderLineIndex(IReadOnlyList<string> lines)
    {
        for (int index = 0; index < lines.Count; index++)
        {
            string line = lines[index].Trim();

            if (!line.StartsWith('#'))
            {
                continue;
            }

            string[] tokens = SplitTokens(line);

            bool containsDateColumns =
                tokens.Contains("YY", StringComparer.OrdinalIgnoreCase) ||
                tokens.Contains("YYYY", StringComparer.OrdinalIgnoreCase) ||
                tokens.Contains("yr", StringComparer.OrdinalIgnoreCase);

            bool containsTargetColumn = TargetColumns.Any(column =>
                tokens.Contains(column, StringComparer.OrdinalIgnoreCase));

            if (containsDateColumns && containsTargetColumn)
            {
                return index;
            }
        }

        return -1;
    }

    private static bool TryParseObservedAt(
        IReadOnlyList<string> values,
        ColumnMap columns,
        out DateTimeOffset observedAt)
    {
        observedAt = default;

        if (!TryParseInteger(values, columns.YearIndex, out int year) ||
            !TryParseInteger(values, columns.MonthIndex, out int month) ||
            !TryParseInteger(values, columns.DayIndex, out int day))
        {
            return false;
        }

        if (year is >= 0 and < 100)
        {
            year += year >= 70 ? 1900 : 2000;
        }

        int hour;
        int minute;

        if (columns.CombinedTimeIndex >= 0)
        {
            string combinedTime = GetValue(values, columns.CombinedTimeIndex)
                .PadLeft(4, '0');

            if (combinedTime.Length != 4 ||
                !int.TryParse(combinedTime[..2], out hour) ||
                !int.TryParse(combinedTime[2..], out minute))
            {
                return false;
            }
        }
        else
        {
            if (!TryParseInteger(values, columns.HourIndex, out hour))
            {
                return false;
            }

            if (columns.MinuteIndex >= 0)
            {
                if (!TryParseInteger(
                    values,
                    columns.MinuteIndex,
                    out minute))
                {
                    return false;
                }
            }
            else
            {
                minute = 0;
            }
        }

        try
        {
            observedAt = new DateTimeOffset(
                year,
                month,
                day,
                hour,
                minute,
                0,
                TimeSpan.Zero);

            return true;
        }
        catch (ArgumentOutOfRangeException)
        {
            return false;
        }
    }

    private static int? ParseNullableInteger(
        IReadOnlyList<string> values,
        int index,
        string columnName,
        ICollection<string> flags)
    {
        double? parsedValue = ParseNullableDouble(
            values,
            index,
            columnName,
            flags);

        return parsedValue is null
            ? null
            : (int)Math.Round(
                parsedValue.Value,
                MidpointRounding.AwayFromZero);
    }

    private static double? ParseNullableDouble(
        IReadOnlyList<string> values,
        int index,
        string columnName,
        ICollection<string> flags)
    {
        if (index < 0 || index >= values.Count)
        {
            return null;
        }

        string rawValue = values[index].Trim();

        if (string.IsNullOrWhiteSpace(rawValue) ||
            rawValue.Equals("MM", StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        if (double.TryParse(
            rawValue,
            NumberStyles.Float | NumberStyles.AllowLeadingSign,
            CultureInfo.InvariantCulture,
            out double parsedValue))
        {
            return parsedValue;
        }

        flags.Add(QualityFlagCodes.ParseFailed(columnName));
        return null;
    }

    private static bool TryParseInteger(
        IReadOnlyList<string> values,
        int index,
        out int parsedValue)
    {
        parsedValue = 0;

        if (index < 0 || index >= values.Count)
        {
            return false;
        }

        return int.TryParse(
            values[index],
            NumberStyles.Integer,
            CultureInfo.InvariantCulture,
            out parsedValue);
    }

    private static string GetValue(
        IReadOnlyList<string> values,
        int index)
    {
        return index >= 0 && index < values.Count
            ? values[index].Trim()
            : string.Empty;
    }

    private static string[] SplitTokens(string line)
    {
        return line
            .Trim()
            .TrimStart('#')
            .Split(
                (char[]?)null,
                StringSplitOptions.RemoveEmptyEntries |
                StringSplitOptions.TrimEntries);
    }

    private static ScrapeErrorData CreateRowError(
        string scrapeRunId,
        string stationId,
        string sourceUrl,
        int sourceRowNumber,
        string errorCode,
        string message,
        string rawData,
        DateTimeOffset occurredAt)
    {
        return new ScrapeErrorData
        {
            ScrapeRunId = scrapeRunId,
            StationId = stationId,
            Scope = "ROW",
            ErrorCode = errorCode,
            Message = message,
            SourceUrl = sourceUrl,
            SourceRowNumber = sourceRowNumber,
            RawData = rawData,
            HttpStatusCode = null,
            AttemptCount = null,
            OccurredAt = occurredAt
        };
    }

    private sealed class ColumnMap
    {
        private readonly Dictionary<string, int> _targetIndexes;

        private ColumnMap(
            int yearIndex,
            int monthIndex,
            int dayIndex,
            int hourIndex,
            int minuteIndex,
            int combinedTimeIndex,
            Dictionary<string, int> targetIndexes)
        {
            YearIndex = yearIndex;
            MonthIndex = monthIndex;
            DayIndex = dayIndex;
            HourIndex = hourIndex;
            MinuteIndex = minuteIndex;
            CombinedTimeIndex = combinedTimeIndex;
            _targetIndexes = targetIndexes;

            int[] requiredIndexes =
            {
                YearIndex,
                MonthIndex,
                DayIndex,
                CombinedTimeIndex >= 0
                    ? CombinedTimeIndex
                    : Math.Max(HourIndex, MinuteIndex)
            };

            MinimumRequiredIndex = requiredIndexes.Max();
        }

        public int YearIndex { get; }
        public int MonthIndex { get; }
        public int DayIndex { get; }
        public int HourIndex { get; }
        public int MinuteIndex { get; }
        public int CombinedTimeIndex { get; }
        public int MinimumRequiredIndex { get; }

        public int GetIndex(string columnName)
        {
            return _targetIndexes.TryGetValue(columnName, out int index)
                ? index
                : -1;
        }

        public static ColumnMap Create(IReadOnlyList<string> headers)
        {
            int yearIndex = FindIndex(headers, "YY", "YYYY", "yr");
            int monthIndex = FindIndexExact(headers, "MM", "mo", "MO");
            int dayIndex = FindIndex(headers, "DD", "dy");
            int combinedTimeIndex = FindIndex(headers, "hhmm", "hrmn");
            int hourIndex = FindIndexExact(headers, "hh", "hr", "HH", "HR");
            int minuteIndex = FindIndexExact(headers, "mm", "mn");

            if (yearIndex < 0 || monthIndex < 0 || dayIndex < 0 ||
                (combinedTimeIndex < 0 && hourIndex < 0))
            {
                throw new InvalidOperationException(
                    "Kolom tanggal dan waktu pada file observasi tidak lengkap.");
            }

            Dictionary<string, int> targetIndexes = new(
                StringComparer.OrdinalIgnoreCase);

            foreach (string targetColumn in TargetColumns)
            {
                targetIndexes[targetColumn] = FindIndex(
                    headers,
                    targetColumn);
            }

            return new ColumnMap(
                yearIndex,
                monthIndex,
                dayIndex,
                hourIndex,
                minuteIndex,
                combinedTimeIndex,
                targetIndexes);
        }

        private static int FindIndex(
            IReadOnlyList<string> values,
            params string[] candidates)
        {
            for (int index = 0; index < values.Count; index++)
            {
                if (candidates.Any(candidate => values[index].Equals(
                    candidate,
                    StringComparison.OrdinalIgnoreCase)))
                {
                    return index;
                }
            }

            return -1;
        }

        private static int FindIndexExact(
            IReadOnlyList<string> values,
            params string[] candidates)
        {
            for (int index = 0; index < values.Count; index++)
            {
                if (candidates.Contains(values[index], StringComparer.Ordinal))
                {
                    return index;
                }
            }

            return -1;
        }
    }
}
