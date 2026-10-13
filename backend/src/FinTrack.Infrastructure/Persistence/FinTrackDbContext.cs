using FinTrack.Application.Interfaces;
using FinTrack.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace FinTrack.Infrastructure.Persistence;

public class FinTrackDbContext : DbContext, IFinTrackDbContext
{
    public FinTrackDbContext(DbContextOptions<FinTrackDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Transaction> Transactions => Set<Transaction>();
    public DbSet<Budget> Budgets => Set<Budget>();
    public DbSet<SavingsGoal> SavingsGoals => Set<SavingsGoal>();
    public DbSet<SavingsContribution> SavingsContributions => Set<SavingsContribution>();
    public DbSet<RecurringTransaction> RecurringTransactions => Set<RecurringTransaction>();
    public DbSet<RecurringExecution> RecurringExecutions => Set<RecurringExecution>();
    public DbSet<ExternalLogin> ExternalLogins => Set<ExternalLogin>();
    public DbSet<SsoChallenge> SsoChallenges => Set<SsoChallenge>();

    public void DetachAll() => ChangeTracker.Clear();

    public Task<int> DeleteExpiredChallengesAsync(DateTime utcNow, CancellationToken cancellationToken = default) =>
        SsoChallenges.Where(challenge => challenge.ExpiresAt < utcNow).ExecuteDeleteAsync(cancellationToken);

    public Task<int> ClaimChallengeAsync(Guid challengeId, DateTime utcNow, CancellationToken cancellationToken = default) =>
        SsoChallenges
            .Where(challenge => challenge.Id == challengeId && challenge.AuthorizedAt == null && challenge.ExpiresAt > utcNow)
            .ExecuteUpdateAsync(
                setters => setters.SetProperty(challenge => challenge.AuthorizedAt, utcNow),
                cancellationToken);

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(FinTrackDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }
}
