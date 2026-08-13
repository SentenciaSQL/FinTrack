using Microsoft.EntityFrameworkCore;
using FinTrack.Application.Interfaces;
using FinTrack.Domain.Entities;
using FinTrack.Domain.Enums;

namespace FinTrack.Application.Services;

public class DemoDataService : IDemoDataService
{
    private readonly IFinTrackDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly IDateTimeProvider _clock;

    public DemoDataService(IFinTrackDbContext db, ICurrentUser currentUser, IDateTimeProvider clock)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
    }

    public async Task SeedAsync(CancellationToken cancellationToken = default)
    {
        var userId = _currentUser.UserId;
        var now = _clock.UtcNow;
        var monthStart = new DateTime(now.Year, now.Month, 1, 12, 0, 0, DateTimeKind.Utc);

        var categories = await _db.Categories.Where(c => c.UserId == userId).ToListAsync(cancellationToken);
        Guid Cat(string code, TransactionType type) =>
            categories.First(c => c.Name == code && c.Type == type && c.IsDefault).Id;

        var samples = new (TransactionType Type, string Description, decimal Amount, string Category, PaymentMethod Method, int DayOffset)[]
        {
            (TransactionType.INCOME, "Salary", 95000, "SALARY", PaymentMethod.BANK_TRANSFER, 1),
            (TransactionType.INCOME, "Freelance", 20000, "FREELANCE", PaymentMethod.BANK_TRANSFER, 8),
            (TransactionType.EXPENSE, "Supermarket", 4850, "FOOD", PaymentMethod.DEBIT_CARD, 2),
            (TransactionType.EXPENSE, "Fuel", 3000, "TRANSPORTATION", PaymentMethod.CREDIT_CARD, 3),
            (TransactionType.EXPENSE, "Internet", 2500, "UTILITIES", PaymentMethod.BANK_TRANSFER, 4),
            (TransactionType.EXPENSE, "Netflix", 650, "SUBSCRIPTIONS", PaymentMethod.CREDIT_CARD, 5),
            (TransactionType.EXPENSE, "Restaurant", 3200, "FOOD", PaymentMethod.CREDIT_CARD, 6),
            (TransactionType.EXPENSE, "Pharmacy", 1800, "HEALTH", PaymentMethod.CASH, 7),
            (TransactionType.EXPENSE, "Gym", 2200, "HEALTH", PaymentMethod.BANK_TRANSFER, 9),
            (TransactionType.EXPENSE, "Shopping", 5400, "SHOPPING", PaymentMethod.CREDIT_CARD, 10)
        };

        foreach (var sample in samples)
        {
            var already = await _db.Transactions.AnyAsync(
                t => t.UserId == userId && t.Description == sample.Description && t.Amount == sample.Amount,
                cancellationToken);
            if (already)
            {
                continue;
            }

            _db.Transactions.Add(new Transaction
            {
                Id = Guid.NewGuid(),
                Type = sample.Type,
                Amount = sample.Amount,
                Description = sample.Description,
                Date = monthStart.AddDays(Math.Min(sample.DayOffset, DateTime.DaysInMonth(now.Year, now.Month) - 1)),
                CategoryId = Cat(sample.Category, sample.Type),
                PaymentMethod = sample.Method,
                UserId = userId,
                CreatedAt = now,
                UpdatedAt = now
            });
        }

        async Task EnsureBudget(string code, decimal amount)
        {
            var categoryId = Cat(code, TransactionType.EXPENSE);
            var exists = await _db.Budgets.AnyAsync(
                b => b.UserId == userId && b.CategoryId == categoryId && b.Month == now.Month && b.Year == now.Year,
                cancellationToken);
            if (exists)
            {
                return;
            }

            _db.Budgets.Add(new Budget
            {
                Id = Guid.NewGuid(),
                CategoryId = categoryId,
                Amount = amount,
                Month = now.Month,
                Year = now.Year,
                UserId = userId,
                CreatedAt = now,
                UpdatedAt = now
            });
        }

        await EnsureBudget("FOOD", 15000);
        await EnsureBudget("TRANSPORTATION", 8000);
        await EnsureBudget("UTILITIES", 6000);
        await EnsureBudget("SUBSCRIPTIONS", 2500);
        await EnsureBudget("HEALTH", 5000);

        if (!await _db.SavingsGoals.AnyAsync(g => g.UserId == userId && g.Name == "New MacBook", cancellationToken))
        {
            var goal = new SavingsGoal
            {
                Id = Guid.NewGuid(),
                Name = "New MacBook",
                Description = "Save for a new laptop",
                TargetAmount = 120000,
                CurrentAmount = 60000,
                TargetDate = now.AddMonths(6),
                UserId = userId,
                CreatedAt = now,
                UpdatedAt = now
            };
            _db.SavingsGoals.Add(goal);
            _db.SavingsContributions.Add(new SavingsContribution
            {
                Id = Guid.NewGuid(),
                SavingsGoalId = goal.Id,
                Amount = 60000,
                Date = now.AddDays(-20),
                CreatedAt = now
            });
        }

        if (!await _db.RecurringTransactions.AnyAsync(r => r.UserId == userId && r.Description == "Salary", cancellationToken))
        {
            _db.RecurringTransactions.Add(new RecurringTransaction
            {
                Id = Guid.NewGuid(),
                Type = TransactionType.INCOME,
                Amount = 95000,
                Description = "Salary",
                CategoryId = Cat("SALARY", TransactionType.INCOME),
                Frequency = RecurrenceFrequency.MONTHLY,
                NextExecutionDate = monthStart.AddMonths(1),
                Active = true,
                UserId = userId,
                CreatedAt = now,
                UpdatedAt = now
            });
        }

        if (!await _db.RecurringTransactions.AnyAsync(r => r.UserId == userId && r.Description == "Netflix", cancellationToken))
        {
            _db.RecurringTransactions.Add(new RecurringTransaction
            {
                Id = Guid.NewGuid(),
                Type = TransactionType.EXPENSE,
                Amount = 650,
                Description = "Netflix",
                CategoryId = Cat("SUBSCRIPTIONS", TransactionType.EXPENSE),
                Frequency = RecurrenceFrequency.MONTHLY,
                NextExecutionDate = monthStart.AddMonths(1),
                Active = true,
                UserId = userId,
                CreatedAt = now,
                UpdatedAt = now
            });
        }

        await _db.SaveChangesAsync(cancellationToken);
    }
}
