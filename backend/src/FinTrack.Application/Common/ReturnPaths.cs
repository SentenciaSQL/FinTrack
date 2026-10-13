namespace FinTrack.Application.Common;

/// <summary>
/// Allows only in-app routes so a return target cannot become an open redirect.
/// </summary>
public static class ReturnPaths
{
    private static readonly string[] Allowed =
    [
        "/home",
        "/transactions",
        "/budgets",
        "/reports",
        "/more",
        "/profile",
        "/settings",
        "/categories",
        "/savings",
        "/recurring"
    ];

    public static string? Normalize(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var candidate = value.Trim();
        if (candidate.Length > 200
            || !candidate.StartsWith('/')
            || candidate.StartsWith("//", StringComparison.Ordinal)
            || candidate.Contains('\\', StringComparison.Ordinal)
            || candidate.Contains("..", StringComparison.Ordinal)
            || candidate.Contains("://", StringComparison.Ordinal))
        {
            return null;
        }

        var queryIndex = candidate.IndexOf('?', StringComparison.Ordinal);
        var path = queryIndex >= 0 ? candidate[..queryIndex] : candidate;
        var query = queryIndex >= 0 ? candidate[(queryIndex + 1)..] : null;
        if (path.Contains('?', StringComparison.Ordinal) || path.Contains('#', StringComparison.Ordinal))
        {
            return null;
        }

        var allowed = false;
        foreach (var prefix in Allowed)
        {
            if (path == prefix || path.StartsWith(prefix + "/", StringComparison.Ordinal))
            {
                allowed = true;
                break;
            }
        }

        if (!allowed)
        {
            return null;
        }

        if (query is not null
            && (query.Contains("://", StringComparison.Ordinal)
                || query.Contains("//", StringComparison.Ordinal)
                || query.Contains('\\', StringComparison.Ordinal)))
        {
            return null;
        }

        return candidate;
    }
}
