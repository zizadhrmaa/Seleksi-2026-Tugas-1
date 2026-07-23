using System.Text.Json;
using NdbcScraper.Models;

namespace NdbcScraper.Persistence;

internal sealed class JsonFileStore
{
    private readonly JsonSerializerOptions _serializerOptions = new()
    {
        WriteIndented = true,
        PropertyNameCaseInsensitive = true
    };

    public async Task WriteAsync<T>(
        string path,
        T data,
        CancellationToken cancellationToken = default)
    {
        string? directory = Path.GetDirectoryName(path);

        if (!string.IsNullOrWhiteSpace(directory))
        {
            Directory.CreateDirectory(directory);
        }

        string temporaryPath = path + ".tmp";

        await using (FileStream stream = new(
            temporaryPath,
            FileMode.Create,
            FileAccess.Write,
            FileShare.None,
            bufferSize: 81920,
            useAsync: true))
        {
            await JsonSerializer.SerializeAsync(
                stream,
                data,
                _serializerOptions,
                cancellationToken);

            await stream.FlushAsync(cancellationToken);
        }

        File.Move(temporaryPath, path, overwrite: true);
    }

    public async Task<T?> ReadAsync<T>(
        string path,
        CancellationToken cancellationToken = default)
    {
        if (!File.Exists(path))
        {
            return default;
        }

        await using FileStream stream = new(
            path,
            FileMode.Open,
            FileAccess.Read,
            FileShare.Read,
            bufferSize: 81920,
            useAsync: true);

        return await JsonSerializer.DeserializeAsync<T>(
            stream,
            _serializerOptions,
            cancellationToken);
    }

    public async Task WriteCombinedObservationsAsync(
        string outputPath,
        IEnumerable<string> stationObservationFiles,
        CancellationToken cancellationToken = default)
    {
        string? directory = Path.GetDirectoryName(outputPath);

        if (!string.IsNullOrWhiteSpace(directory))
        {
            Directory.CreateDirectory(directory);
        }

        string temporaryPath = outputPath + ".tmp";

        await using (FileStream stream = new(
            temporaryPath,
            FileMode.Create,
            FileAccess.Write,
            FileShare.None,
            bufferSize: 81920,
            useAsync: true))
        {
            using (Utf8JsonWriter writer = new(
                stream,
                new JsonWriterOptions { Indented = true }))
            {
                writer.WriteStartArray();

                foreach (string file in stationObservationFiles)
                {
                    cancellationToken.ThrowIfCancellationRequested();

                    List<ObservationData> observations =
                        await ReadAsync<List<ObservationData>>(
                            file,
                            cancellationToken) ?? new List<ObservationData>();

                    foreach (ObservationData observation in observations)
                    {
                        JsonSerializer.Serialize(
                            writer,
                            observation,
                            _serializerOptions);
                    }
                }

                writer.WriteEndArray();
                writer.Flush();
            }

            await stream.FlushAsync(cancellationToken);
        }

        File.Move(temporaryPath, outputPath, overwrite: true);
    }
}
