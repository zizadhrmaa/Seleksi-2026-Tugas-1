using System.Text.Json;

namespace BmkgScraper.Persistence;

internal sealed class JsonDataReader : IDataReader
{
    private readonly JsonSerializerOptions _options = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public async Task<T?> ReadAsync<T>(
        string inputPath,
        CancellationToken cancellationToken = default)
    {
        if (!File.Exists(inputPath))
        {
            return default;
        }

        await using FileStream stream = new(
            inputPath,
            FileMode.Open,
            FileAccess.Read,
            FileShare.Read);

        return await JsonSerializer.DeserializeAsync<T>(
            stream,
            _options,
            cancellationToken);
    }
}
