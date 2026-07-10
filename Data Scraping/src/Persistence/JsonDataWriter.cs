using System.Text.Json;

namespace BmkgScraper.Persistence;

internal sealed class JsonDataWriter : IDataWriter
{
    private readonly JsonSerializerOptions _options = new()
    {
        WriteIndented = true
    };

    public async Task WriteAsync<T>(
        T data,
        string outputPath,
        CancellationToken cancellationToken = default)
    {
        string? directory = Path.GetDirectoryName(outputPath);

        if (!string.IsNullOrWhiteSpace(directory))
        {
            Directory.CreateDirectory(directory);
        }

        await using FileStream stream = File.Create(outputPath);

        await JsonSerializer.SerializeAsync(
            stream,
            data,
            _options,
            cancellationToken);
    }
}
