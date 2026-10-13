using FinTrack.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace FinTrack.Application.Interfaces;

public interface IFinTrackDbContext
{
    DbSet<User> Users { get; }
    DbSet<Category> Categories { get; }
    DbSet<Transaction> Transactions { get; }
    DbSet<Budget> Budgets { get; }
    DbSet<SavingsGoal> SavingsGoals { get; }
    DbSet<SavingsContribution> SavingsContributions { get; }
    DbSet<RecurringTransaction> RecurringTransactions { get; }
    DbSet<RecurringExecution> RecurringExecutions { get; }
    DbSet<ExternalLogin> ExternalLogins { get; }
    DbSet<SsoChallenge> SsoChallenges { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
    void DetachAll();
    Task<int> DeleteExpiredChallengesAsync(DateTime utcNow, CancellationToken cancellationToken = default);
    Task<int> ClaimChallengeAsync(Guid challengeId, DateTime utcNow, CancellationToken cancellationToken = default);
}
