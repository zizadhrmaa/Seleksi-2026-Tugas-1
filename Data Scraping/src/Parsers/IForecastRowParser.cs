using BmkgScraper.Models;
using HtmlAgilityPack;

namespace BmkgScraper.Parsers;

internal interface IForecastRowParser
{
    ForecastRowParseResult Parse(
        HtmlNode row,
        PortData port,
        ScrapeBatchContext batch,
        DateTimeOffset extractedAt);
}
