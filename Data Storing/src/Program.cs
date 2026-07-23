using NdbcDataLoader.Configuration;
using NdbcDataLoader.Models;
using NdbcDataLoader.Persistence;
using NdbcDataLoader.Services;
using NdbcDataLoader.Utilities;

namespace NdbcDataLoader;

internal static class Program
{
    private static async Task Main(string[] args)
    {
        using CancellationTokenSource cancellationTokenSource = new();

        Console.CancelKeyPress += (_, eventArgs) =>
        {
            eventArgs.Cancel = true;
            cancellationTokenSource.Cancel();
        };

        try
        {
            LoadOptions options = LoadOptions.Parse(args);
            JsonDataReader jsonDataReader = new();
            SourceDataValidator sourceDataValidator = new();
            PostgresSchemaInitializer schemaInitializer = new();
            PostgresDataLoader dataLoader = new(jsonDataReader);

            DataLoadRunner runner = new(
                jsonDataReader,
                sourceDataValidator,
                schemaInitializer,
                dataLoader);

            LoadSummary summary = await runner.RunAsync(
                options,
                cancellationTokenSource.Token);

            Console.WriteLine();
            Console.WriteLine($"Run ID: {summary.ScrapeRunId}");
            Console.WriteLine($"Stasiun sumber: {summary.SourceStationCount:N0}");
            Console.WriteLine($"Observasi sumber: {summary.SourceObservationCount:N0}");
            Console.WriteLine($"Observasi baru tersimpan: {summary.InsertedObservationCount:N0}");
            Console.WriteLine($"Observasi lama diperbarui: {summary.UpdatedObservationCount:N0}");
            Console.WriteLine($"Observasi overlap tidak berubah: {summary.UnchangedObservationCount:N0}");
            Console.WriteLine($"Total stasiun di database: {summary.DatabaseStationCount:N0}");
            Console.WriteLine($"Total observasi di database: {summary.DatabaseObservationCount:N0}");
        }
        catch (OperationCanceledException)
        {
            Console.WriteLine();
            Console.WriteLine("Proses dihentikan. Transaksi database dibatalkan.");
            Environment.ExitCode = 2;
        }
        catch (ArgumentException exception)
        {
            Console.Error.WriteLine($"Argumen tidak valid: {exception.Message}");
            Environment.ExitCode = 1;
        }
        catch (Exception exception)
        {
            Console.Error.WriteLine("Data storing gagal.");
            Console.Error.WriteLine(exception);
            Environment.ExitCode = 1;
        }
    }
}
