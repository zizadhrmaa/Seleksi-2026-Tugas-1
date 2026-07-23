using System.Text;
using HtmlAgilityPack;
using NdbcScraper.Utilities;

namespace NdbcScraper.Parsing;

internal static class HtmlTextLineExtractor
{
    private static readonly HashSet<string> BlockElements = new(
        new[]
        {
            "address", "article", "aside", "blockquote", "div", "dl",
            "dt", "dd", "fieldset", "figcaption", "figure", "footer",
            "form", "h1", "h2", "h3", "h4", "h5", "h6", "header",
            "hr", "li", "main", "nav", "ol", "p", "pre", "section",
            "table", "tbody", "td", "tfoot", "th", "thead", "tr", "ul"
        },
        StringComparer.OrdinalIgnoreCase);

    public static IReadOnlyList<string> Extract(HtmlNode root)
    {
        List<string> lines = new();
        StringBuilder currentLine = new();

        AppendNode(root, lines, currentLine);
        FlushLine(lines, currentLine);

        return lines
            .Where(line => !string.IsNullOrWhiteSpace(line))
            .ToList();
    }

    private static void AppendNode(
        HtmlNode node,
        List<string> lines,
        StringBuilder currentLine)
    {
        if (node.NodeType == HtmlNodeType.Text)
        {
            string text = TextNormalizer.Clean(node.InnerText);

            if (!string.IsNullOrWhiteSpace(text))
            {
                if (currentLine.Length > 0)
                {
                    currentLine.Append(' ');
                }

                currentLine.Append(text);
            }

            return;
        }

        if (node.Name.Equals("br", StringComparison.OrdinalIgnoreCase) ||
            node.Name.Equals("hr", StringComparison.OrdinalIgnoreCase))
        {
            FlushLine(lines, currentLine);
            return;
        }

        bool isBlock = BlockElements.Contains(node.Name);

        if (isBlock)
        {
            FlushLine(lines, currentLine);
        }

        foreach (HtmlNode child in node.ChildNodes)
        {
            AppendNode(child, lines, currentLine);
        }

        if (isBlock)
        {
            FlushLine(lines, currentLine);
        }
    }

    private static void FlushLine(
        List<string> lines,
        StringBuilder currentLine)
    {
        string line = TextNormalizer.Clean(currentLine.ToString());

        if (!string.IsNullOrWhiteSpace(line))
        {
            lines.Add(line);
        }

        currentLine.Clear();
    }
}
