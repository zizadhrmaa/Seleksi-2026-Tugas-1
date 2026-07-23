using System.Runtime.CompilerServices;
using System.Text.Json;

namespace NdbcDataLoader.Utilities;

internal sealed class JsonDataReader
{
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNameCaseInsensitive = false
    };

    public async Task<T> ReadRequiredAsync<T>(
        string filePath,
        CancellationToken cancellationToken)
    {
        if (!File.Exists(filePath))
        {
            throw new FileNotFoundException("File data tidak ditemukan.", filePath);
        }

        await using FileStream stream = File.OpenRead(filePath);
        T? value = await JsonSerializer.DeserializeAsync<T>(
            stream,
            SerializerOptions,
            cancellationToken);

        return value ?? throw new InvalidDataException(
            $"Isi file JSON kosong atau tidak sesuai model: {filePath}");
    }

    public async IAsyncEnumerable<T> StreamArrayAsync<T>(
        string filePath,
        [EnumeratorCancellation] CancellationToken cancellationToken)
    {
        if (!File.Exists(filePath))
        {
            throw new FileNotFoundException("File data tidak ditemukan.", filePath);
        }

        await using FileStream stream = File.OpenRead(filePath);

        await foreach (T? item in JsonSerializer.DeserializeAsyncEnumerable<T>(
            stream,
            SerializerOptions,
            cancellationToken))
        {
            if (item is null)
            {
                throw new InvalidDataException(
                    $"Ditemukan elemen null pada array JSON: {filePath}");
            }

            yield return item;
        }
    }
}
