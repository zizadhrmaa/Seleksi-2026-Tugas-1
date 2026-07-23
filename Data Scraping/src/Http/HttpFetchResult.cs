using System.Net;

namespace NdbcScraper.Http;

internal sealed record HttpFetchResult(
    string Content,
    int AttemptCount,
    HttpStatusCode StatusCode,
    long DurationMilliseconds,
    Uri RequestedUrl);

internal sealed class HttpFetchException : HttpRequestException
{
    public HttpFetchException(
        string message,
        Uri requestedUrl,
        int attemptCount,
        long durationMilliseconds,
        HttpStatusCode? statusCode = null,
        Exception? innerException = null)
        : base(message, innerException, statusCode)
    {
        RequestedUrl = requestedUrl;
        AttemptCount = attemptCount;
        DurationMilliseconds = durationMilliseconds;
    }

    public Uri RequestedUrl { get; }

    public int AttemptCount { get; }

    public long DurationMilliseconds { get; }
}
