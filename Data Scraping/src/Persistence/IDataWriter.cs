namespace BmkgScraper.Persistence;

internal interface IDataWriter
{
    Task WriteAsync<T>(
        T data,
        string outputPath,
        CancellationToken cancellationToken = default);
}
