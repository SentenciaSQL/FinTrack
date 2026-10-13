using FinTrack.Application.Interfaces;
using FinTrack.Domain.Common;
using FinTrack.Domain.Entities;

namespace FinTrack.Application.Services;

internal static class UserRegistration
{
    public static User CreateAccount(
        IFinTrackDbContext db,
        string name,
        string email,
        string passwordHash,
        string language,
        string currency,
        DateTime now)
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            Name = name,
            Email = email,
            PasswordHash = passwordHash,
            PreferredLanguage = language,
            PreferredCurrency = currency,
            CreatedAt = now,
            UpdatedAt = now
        };

        db.Users.Add(user);

        foreach (var (code, type, icon) in DefaultCategories.All)
        {
            db.Categories.Add(new Category
            {
                Id = Guid.NewGuid(),
                Name = code,
                Icon = icon,
                Type = type,
                UserId = user.Id,
                IsDefault = true,
                CreatedAt = now
            });
        }

        return user;
    }
}
