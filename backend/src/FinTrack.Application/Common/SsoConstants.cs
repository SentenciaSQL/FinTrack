namespace FinTrack.Application.Common;

public static class SsoProviders
{
    public const string Google = "google";
    public const string Microsoft = "microsoft";
    public const string Oidc = "oidc";

    public static bool IsKnown(string? value) =>
        value is Google or Microsoft or Oidc;

    public static string? Normalize(string? value)
    {
        var name = value?.Trim().ToLowerInvariant();
        return IsKnown(name) ? name : null;
    }
}

public static class SsoIntents
{
    public const string SignIn = "sign_in";
    public const string Link = "link";
}

public static class SsoOutcomes
{
    public const string Pending = "pending";
    public const string Authenticated = "authenticated";
    public const string LinkRequired = "link_required";
    public const string Linked = "linked";
    public const string Error = "error";
}

public static class SsoStatuses
{
    public const string Authenticated = "authenticated";
    public const string LinkRequired = "link_required";
    public const string Linked = "linked";
}
