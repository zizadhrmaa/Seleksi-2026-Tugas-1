using System.Diagnostics;
using System.Net;

namespace NdbcScraper.Http;

internal sealed class NdbcHttpFetcher : IHttpFetcher
{
    private readonly HttpClient _httpClient;
    private readonly int _maxAttempts;
    private readonly TimeSpan _initialRetryDelay;
    private readonly TimeSpan _minimumRequestInterval;
    private readonly SemaphoreSlim _requestGate = new(1, 1);
    private DateTimeOffset? _lastRequestAtUtc;

    public NdbcHttpFetcher(
        HttpClient httpClient,
        int maxAttempts,
        TimeSpan initialRetryDelay,
        TimeSpan minimumRequestInterval)
    {
        if (maxAttempts <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(maxAttempts));
        }

        if (initialRetryDelay < TimeSpan.Zero)
        {
            throw new ArgumentOutOfRangeException(nameof(initialRetryDelay));
        }

        if (minimumRequestInterval < TimeSpan.Zero)
        {
            throw new ArgumentOutOfRangeException(
                nameof(minimumRequestInterval));
        }

        _httpClient = httpClient;
        _maxAttempts = maxAttempts;
        _initialRetryDelay = initialRetryDelay;
        _minimumRequestInterval = minimumRequestInterval;
    }

    public async Task<HttpFetchResult> GetStringAsync(
        Uri url,
        CancellationToken cancellationToken = default)
    {
        Stopwatch stopwatch = Stopwatch.StartNew();
        Exception? lastException = null;
        HttpStatusCode? lastStatusCode = null;

        for (int attempt = 1; attempt <= _maxAttempts; attempt++)
        {
            cancellationToken.ThrowIfCancellationRequested();

            try
            {
                await WaitForRequestSlotAsync(cancellationToken);

                using HttpResponseMessage response = await _httpClient.GetAsync(
                    url,
                    HttpCompletionOption.ResponseHeadersRead,
                    cancellationToken);

                lastStatusCode = response.StatusCode;

                if (response.IsSuccessStatusCode)
                {
                    string content = await response.Content.ReadAsStringAsync(
                        cancellationToken);

                    stopwatch.Stop();

                    return new HttpFetchResult(
                        content,
                        attempt,
                        response.StatusCode,
                        stopwatch.ElapsedMilliseconds,
                        url);
                }

                if (!IsTransientStatusCode(response.StatusCode) ||
                    attempt == _maxAttempts)
                {
                    stopwatch.Stop();

                    throw new HttpFetchException(
                        $"HTTP {(int)response.StatusCode} " +
                        $"({response.ReasonPhrase}) saat mengakses {url}.",
                        url,
                        attempt,
                        stopwatch.ElapsedMilliseconds,
                        response.StatusCode);
                }
            }
            catch (OperationCanceledException)
                when (!cancellationToken.IsCancellationRequested)
            {
                lastException = new TimeoutException(
                    $"Request ke {url} melewati batas waktu.");
            }
            catch (HttpFetchException)
            {
                throw;
            }
            catch (HttpRequestException exception)
            {
                lastException = exception;
                lastStatusCode = exception.StatusCode;
            }

            if (attempt < _maxAttempts)
            {
                await Task.Delay(
                    CalculateRetryDelay(attempt),
                    cancellationToken);
            }
        }

        stopwatch.Stop();

        throw new HttpFetchException(
            $"Gagal mengakses {url} setelah {_maxAttempts} percobaan.",
            url,
            _maxAttempts,
            stopwatch.ElapsedMilliseconds,
            lastStatusCode,
            lastException);
    }

    private async Task WaitForRequestSlotAsync(
        CancellationToken cancellationToken)
    {
        await _requestGate.WaitAsync(cancellationToken);

        try
        {
            if (_lastRequestAtUtc is not null)
            {
                TimeSpan elapsed =
                    DateTimeOffset.UtcNow - _lastRequestAtUtc.Value;

                TimeSpan remaining = _minimumRequestInterval - elapsed;

                if (remaining > TimeSpan.Zero)
                {
                    await Task.Delay(remaining, cancellationToken);
                }
            }

            _lastRequestAtUtc = DateTimeOffset.UtcNow;
        }
        finally
        {
            _requestGate.Release();
        }
    }

    private TimeSpan CalculateRetryDelay(int completedAttemptCount)
    {
        double multiplier = Math.Pow(2, completedAttemptCount - 1);
        double delayMilliseconds =
            _initialRetryDelay.TotalMilliseconds * multiplier;

        return TimeSpan.FromMilliseconds(delayMilliseconds);
    }

    private static bool IsTransientStatusCode(HttpStatusCode statusCode)
    {
        int numericStatusCode = (int)statusCode;

        return statusCode == HttpStatusCode.RequestTimeout ||
               numericStatusCode == 429 ||
               numericStatusCode >= 500;
    }
}
