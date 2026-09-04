using System.Text;
using FinTrack.Application.Interfaces;
using FinTrack.Infrastructure.Auth;
using FinTrack.Infrastructure.BackgroundJobs;
using FinTrack.Infrastructure.Email;
using FinTrack.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;

namespace FinTrack.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString =
            configuration.GetConnectionString("DefaultConnection")
            ?? "Host=localhost;Port=5432;Database=fintrack_db;Username=postgres;Password=postgres";

        services.AddDbContext<FinTrackDbContext>(options =>
            options.UseNpgsql(connectionString));

        services.AddScoped<IFinTrackDbContext>(serviceProvider =>
            serviceProvider.GetRequiredService<FinTrackDbContext>());

        services.AddHttpContextAccessor();

        services.AddScoped<ICurrentUser, CurrentUser>();

        services.AddSingleton<IDateTimeProvider, DateTimeProvider>();

        services.AddSingleton<IPasswordHasher, BcryptPasswordHasher>();

        services.AddSingleton<IJwtTokenService, JwtTokenService>();

        services.AddHttpClient<IEmailService, ResendEmailService>(client =>
        {
            client.BaseAddress = new Uri("https://api.resend.com/");
        });

        services.AddHostedService<RecurringTransactionProcessor>();

        var secret =
            configuration["Jwt:Secret"]
            ?? "replace-with-a-secure-secret-that-is-long-enough-123456";

        var issuer =
            configuration["Jwt:Issuer"]
            ?? "FinTrack";

        var audience =
            configuration["Jwt:Audience"]
            ?? "FinTrackMobile";

        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.TokenValidationParameters =
                    new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidateAudience = true,
                        ValidateIssuerSigningKey = true,
                        ValidateLifetime = true,
                        ValidIssuer = issuer,
                        ValidAudience = audience,
                        IssuerSigningKey =
                            new SymmetricSecurityKey(
                                Encoding.UTF8.GetBytes(secret)),
                        ClockSkew = TimeSpan.FromMinutes(1)
                    };
            });

        services.AddAuthorization();

        return services;
    }
}