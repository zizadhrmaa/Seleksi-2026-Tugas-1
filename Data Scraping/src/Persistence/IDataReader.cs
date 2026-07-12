namespace BmkgScraper.Persistence;

internal interface IDataReader
{
    Task<T?> ReadAsync<T>(
        string inputPath,
        CancellationToken cancellationToken = default);
}
