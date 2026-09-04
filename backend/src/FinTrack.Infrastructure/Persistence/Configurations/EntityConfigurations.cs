using FinTrack.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace FinTrack.Infrastructure.Persistence.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("users");

        builder.HasKey(user => user.Id);

        builder.Property(user => user.Name)
            .HasMaxLength(120)
            .IsRequired();

        builder.Property(user => user.Email)
            .HasMaxLength(256)
            .IsRequired();

        builder.HasIndex(user => user.Email)
            .IsUnique();

        builder.Property(user => user.PasswordHash)
            .HasMaxLength(512)
            .IsRequired();

        builder.Property(user => user.IsEmailVerified)
            .HasDefaultValue(false)
            .IsRequired();

        builder.Property(user => user.EmailVerificationTokenHash)
            .HasMaxLength(64);

        builder.Property(user => user.EmailVerificationTokenExpiresAt);

        builder.Property(user => user.PreferredLanguage)
            .HasMaxLength(8)
            .HasDefaultValue("es");

        builder.Property(user => user.PreferredCurrency)
            .HasMaxLength(8)
            .HasDefaultValue("DOP");

        builder.Property(user => user.CreatedAt)
            .IsRequired();

        builder.Property(user => user.UpdatedAt)
            .IsRequired();
    }
}