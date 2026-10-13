namespace FinTrack.Application.Common;

public static class PasswordHashes
{
    public static bool IsSet(string? hash) =>
        !string.IsNullOrEmpty(hash) && hash.StartsWith("$2", StringComparison.Ordinal);
}
