using System.Diagnostics;
using System.Net;

namespace BmkgScraper.Http;

internal sealed class BmkgHttpFetcher : IHttpFetcher
{
    private readonly HttpClient _httpClient;
    private readonly int _maxAttempts;
    private readonly TimeSpan _initialRetryDelay;

    public BmkgHttpFetcher(
        HttpClient httpClient,
        int maxAttempts,
        TimeSpan initialRetryDelay)
    {
        if (maxAttempts <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(maxAttempts));
        }

        if (initialRetryDelay < TimeSpan.Zero)
        {
            throw new ArgumentOutOfRangeException(nameof(initialRetryDelay));
        }

        _httpClient = httpClient;
        _maxAttempts = maxAttempts;
        _initialRetryDelay = initialRetryDelay;
    }

    public async Task<HttpFetchResult> GetHtmlAsync(
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
                using HttpResponseMessage response =
                    await _httpClient.GetAsync(url, cancellationToken);

                lastStatusCode = response.StatusCode;

                if (response.IsSuccessStatusCode)
                {
                    string html =
                        await response.Content.ReadAsStringAsync(cancellationToken);

                    stopwatch.Stop();

                    return new HttpFetchResult(
                        html,
                        attempt,
                        response.StatusCode,
                        stopwatch.ElapsedMilliseconds);
                }

                if (!IsTransientStatusCode(response.StatusCode) ||
                    attempt == _maxAttempts)
                {
                    stopwatch.Stop();

                    throw new HttpFetchException(
                        $"HTTP {(int)response.StatusCode} " +
                        $"({response.ReasonPhrase}) saat mengakses {url}.",
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
            _maxAttempts,
            stopwatch.ElapsedMilliseconds,
            lastStatusCode,
            lastException);
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
