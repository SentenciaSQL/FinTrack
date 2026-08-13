using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace FinTrack.Infrastructure.Persistence;

public class FinTrackDbContextFactory : IDesignTimeDbContextFactory<FinTrackDbContext>
{
    public FinTrackDbContext CreateDbContext(string[] args)
    {
        var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
            ?? "Host=localhost;Port=5432;Database=fintrack_db;Username=postgres;Password=postgres";

        var options = new DbContextOptionsBuilder<FinTrackDbContext>()
            .UseNpgsql(connectionString)
            .Options;

        return new FinTrackDbContext(options);
    }
}
