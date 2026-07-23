namespace NdbcDataLoader.Configuration;

internal sealed class LoadOptions
{
    public required string ConnectionString { get; init; }

    public required string DataDirectory { get; init; }

    public required string SchemaFilePath { get; init; }

    public static LoadOptions Parse(string[] args)
    {
        Dictionary<string, string> values = new(StringComparer.OrdinalIgnoreCase);

        for (int index = 0; index < args.Length; index++)
        {
            string argument = args[index];

            if (!argument.StartsWith("--", StringComparison.Ordinal))
            {
                throw new ArgumentException($"Argumen tidak dikenal: {argument}");
            }

            if (index + 1 >= args.Length || args[index + 1].StartsWith("--", StringComparison.Ordinal))
            {
                throw new ArgumentException($"Nilai untuk {argument} tidak ditemukan.");
            }

            values[argument] = args[++index];
        }

        string? connectionString = GetValue(values, "--connection")
            ?? Environment.GetEnvironmentVariable("NDBC_DB_CONNECTION");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new ArgumentException(
                "Connection string wajib diberikan melalui --connection atau environment variable NDBC_DB_CONNECTION.");
        }

        string dataDirectory = GetValue(values, "--data")
            ?? Path.Combine("..", "..", "Data Scraping", "data");

        string schemaFilePath = GetValue(values, "--schema")
            ?? Path.Combine("..", "export", "schema.sql");

        return new LoadOptions
        {
            ConnectionString = connectionString,
            DataDirectory = Path.GetFullPath(dataDirectory),
            SchemaFilePath = Path.GetFullPath(schemaFilePath)
        };
    }

    private static string? GetValue(
        IReadOnlyDictionary<string, string> values,
        string key)
    {
        return values.TryGetValue(key, out string? value)
            ? value
            : null;
    }
}
