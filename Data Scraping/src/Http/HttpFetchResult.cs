using System.Net;

namespace BmkgScraper.Http;

internal sealed record HttpFetchResult(
    string Html,
    int AttemptCount,
    HttpStatusCode StatusCode,
    long DurationMilliseconds);

internal sealed class HttpFetchException : HttpRequestException
{
    public HttpFetchException(
        string message,
        int attemptCount,
        long durationMilliseconds,
        HttpStatusCode? statusCode = null,
        Exception? innerException = null)
        : base(message, innerException, statusCode)
    {
        AttemptCount = attemptCount;
        DurationMilliseconds = durationMilliseconds;
    }

    public int AttemptCount { get; }

    public long DurationMilliseconds { get; }
}
