using NdbcDataLoader.Configuration;
using NdbcDataLoader.Models;
using NdbcDataLoader.Persistence;
using NdbcDataLoader.Utilities;
using Npgsql;

namespace NdbcDataLoader.Services;

internal sealed class DataLoadRunner
{
    private readonly JsonDataReader _jsonDataReader;
    private readonly SourceDataValidator _sourceDataValidator;
    private readonly PostgresSchemaInitializer _schemaInitializer;
    private readonly PostgresDataLoader _dataLoader;

    public DataLoadRunner(
        JsonDataReader jsonDataReader,
        SourceDataValidator sourceDataValidator,
        PostgresSchemaInitializer schemaInitializer,
        PostgresDataLoader dataLoader)
    {
        _jsonDataReader = jsonDataReader;
        _sourceDataValidator = sourceDataValidator;
        _schemaInitializer = schemaInitializer;
        _dataLoader = dataLoader;
    }

    public async Task<LoadSummary> RunAsync(
        LoadOptions options,
        CancellationToken cancellationToken)
    {
        ValidateInputPaths(options);

        string reportPath = Path.Combine(
            options.DataDirectory,
            "scraping_report.json");

        string stationsPath = Path.Combine(
            options.DataDirectory,
            "stations.json");

        string manifestPath = Path.Combine(
            options.DataDirectory,
            "observations_manifest.json");

        Console.WriteLine("Membaca dan memvalidasi data hasil scraping...");

        ScrapeRunReport report = await _jsonDataReader.ReadRequiredAsync<ScrapeRunReport>(
            reportPath,
            cancellationToken);

        List<StationData> stations = await _jsonDataReader.ReadRequiredAsync<List<StationData>>(
            stationsPath,
            cancellationToken);

        ObservationManifest manifest = await _jsonDataReader.ReadRequiredAsync<ObservationManifest>(
            manifestPath,
            cancellationToken);

        _sourceDataValidator.Validate(
            report,
            manifest,
            stations,
            options.DataDirectory);

        NpgsqlDataSourceBuilder dataSourceBuilder = new(options.ConnectionString);
        await using NpgsqlDataSource dataSource = dataSourceBuilder.Build();

        Console.WriteLine("Menerapkan schema PostgreSQL...");
        await _schemaInitializer.ApplyAsync(
            dataSource,
            options.SchemaFilePath,
            cancellationToken);

        Console.WriteLine("Memuat stasiun dan observasi ke PostgreSQL...");
        return await _dataLoader.LoadAsync(
            dataSource,
            report,
            manifest,
            stations,
            options.DataDirectory,
            cancellationToken);
    }

    private static void ValidateInputPaths(LoadOptions options)
    {
        if (!Directory.Exists(options.DataDirectory))
        {
            throw new DirectoryNotFoundException(
                $"Data directory tidak ditemukan: {options.DataDirectory}");
        }

        if (!File.Exists(options.SchemaFilePath))
        {
            throw new FileNotFoundException(
                "File schema SQL tidak ditemukan.",
                options.SchemaFilePath);
        }
    }
}
