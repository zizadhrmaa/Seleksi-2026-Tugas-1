using NdbcDataLoader.Models;

namespace NdbcDataLoader.Services;

internal sealed class SourceDataValidator
{
    public void Validate(
        ScrapeRunReport report,
        ObservationManifest manifest,
        IReadOnlyList<StationData> stations,
        string dataDirectory)
    {
        if (!report.TargetMet)
        {
            throw new InvalidDataException(
                "Scraping report menunjukkan target stasiun tidak tercapai.");
        }

        if (!string.Equals(
                report.ScrapeRunId,
                manifest.ScrapeRunId,
                StringComparison.Ordinal))
        {
            throw new InvalidDataException(
                "scrape_run_id pada report dan manifest tidak sama.");
        }

        if (stations.Count != report.SuccessfulStationCount)
        {
            throw new InvalidDataException(
                $"Jumlah stasiun pada stations.json ({stations.Count}) tidak sama " +
                $"dengan scraping report ({report.SuccessfulStationCount}).");
        }

        if (stations.Count != manifest.TotalStationCount)
        {
            throw new InvalidDataException(
                $"Jumlah stasiun pada stations.json ({stations.Count}) tidak sama " +
                $"dengan observation manifest ({manifest.TotalStationCount}).");
        }

        if (manifest.TotalObservationCount != report.TotalObservationCount)
        {
            throw new InvalidDataException(
                "Jumlah observasi pada report dan manifest tidak sama.");
        }

        HashSet<string> stationIds = new(StringComparer.OrdinalIgnoreCase);

        foreach (StationData station in stations)
        {
            if (!stationIds.Add(station.StationId))
            {
                throw new InvalidDataException(
                    $"Station ID duplikat pada stations.json: {station.StationId}");
            }

            if (!string.Equals(
                    station.ScrapeRunId,
                    report.ScrapeRunId,
                    StringComparison.Ordinal))
            {
                throw new InvalidDataException(
                    $"scrape_run_id stasiun {station.StationId} tidak sesuai report.");
            }
        }

        HashSet<string> manifestStationIds = new(StringComparer.OrdinalIgnoreCase);

        foreach (StationObservationFile stationFile in manifest.StationFiles)
        {
            if (!manifestStationIds.Add(stationFile.StationId))
            {
                throw new InvalidDataException(
                    $"Station ID duplikat pada manifest: {stationFile.StationId}");
            }

            if (!stationIds.Contains(stationFile.StationId))
            {
                throw new InvalidDataException(
                    $"Manifest merujuk stasiun yang tidak ada: {stationFile.StationId}");
            }

            string observationPath = Path.GetFullPath(
                Path.Combine(dataDirectory, stationFile.RelativePath));

            string normalizedDataDirectory = Path.GetFullPath(dataDirectory)
                .TrimEnd(Path.DirectorySeparatorChar)
                + Path.DirectorySeparatorChar;

            if (!observationPath.StartsWith(
                    normalizedDataDirectory,
                    StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidDataException(
                    $"Path observasi keluar dari data directory: {stationFile.RelativePath}");
            }

            if (!File.Exists(observationPath))
            {
                throw new FileNotFoundException(
                    $"File observasi untuk stasiun {stationFile.StationId} tidak ditemukan.",
                    observationPath);
            }
        }

        if (!stationIds.SetEquals(manifestStationIds))
        {
            throw new InvalidDataException(
                "Daftar station ID pada stations.json dan manifest tidak sama.");
        }
    }
}
