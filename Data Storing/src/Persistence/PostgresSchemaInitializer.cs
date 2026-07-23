using Npgsql;

namespace NdbcDataLoader.Persistence;

internal sealed class PostgresSchemaInitializer
{
    public async Task ApplyAsync(
        NpgsqlDataSource dataSource,
        string schemaFilePath,
        CancellationToken cancellationToken)
    {
        if (!File.Exists(schemaFilePath))
        {
            throw new FileNotFoundException(
                "File schema SQL tidak ditemukan.",
                schemaFilePath);
        }

        string sql = await File.ReadAllTextAsync(
            schemaFilePath,
            cancellationToken);

        if (string.IsNullOrWhiteSpace(sql))
        {
            throw new InvalidDataException("File schema SQL kosong.");
        }

        await using NpgsqlCommand command = dataSource.CreateCommand(sql);
        command.CommandTimeout = 120;
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
