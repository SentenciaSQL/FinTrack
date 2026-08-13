using FinTrack.Application.Interfaces;
using FinTrack.Domain.Entities;
using FinTrack.Domain.Enums;
using FinTrack.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace FinTrack.Infrastructure.BackgroundJobs;

public class RecurringTransactionProcessor : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<RecurringTransactionProcessor> _logger;

    public RecurringTransactionProcessor(IServiceScopeFactory scopeFactory, ILogger<RecurringTransactionProcessor> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await Task.Delay(TimeSpan.FromSeconds(15), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessDueTransactionsAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to process recurring transactions");
            }

            await Task.Delay(TimeSpan.FromMinutes(15), stoppingToken);
        }
    }

    private async Task ProcessDueTransactionsAsync(CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<FinTrackDbContext>();
        var clock = scope.ServiceProvider.GetRequiredService<IDateTimeProvider>();
        var today = clock.UtcNow.Date;

        var due = await db.RecurringTransactions
            .Where(r => r.Active && r.NextExecutionDate.Date <= today)
            .ToListAsync(cancellationToken);

        foreach (var item in due)
        {
            var executionDate = item.NextExecutionDate.Date;
            while (executionDate <= today)
            {
                var alreadyProcessed = await db.RecurringExecutions.AnyAsync(
                    e => e.RecurringTransactionId == item.Id && e.ExecutionDate == executionDate,
                    cancellationToken);

                if (!alreadyProcessed)
                {
                    var now = clock.UtcNow;
                    var transaction = new Transaction
                    {
                        Id = Guid.NewGuid(),
                        Type = item.Type,
                        Amount = item.Amount,
                        Description = item.Description,
                        Date = DateTime.SpecifyKind(executionDate, DateTimeKind.Utc),
                        CategoryId = item.CategoryId,
                        PaymentMethod = PaymentMethod.OTHER,
                        UserId = item.UserId,
                        RecurringTransactionId = item.Id,
                        CreatedAt = now,
                        UpdatedAt = now
                    };

                    db.Transactions.Add(transaction);
                    db.RecurringExecutions.Add(new RecurringExecution
                    {
                        Id = Guid.NewGuid(),
                        RecurringTransactionId = item.Id,
                        ExecutionDate = executionDate,
                        TransactionId = transaction.Id,
                        CreatedAt = now
                    });
                }

                executionDate = Advance(executionDate, item.Frequency);
            }

            item.NextExecutionDate = DateTime.SpecifyKind(executionDate, DateTimeKind.Utc);
            item.UpdatedAt = clock.UtcNow;
        }

        if (due.Count > 0)
        {
            await db.SaveChangesAsync(cancellationToken);
            _logger.LogInformation("Processed {Count} recurring transaction definitions", due.Count);
        }
    }

    private static DateTime Advance(DateTime date, RecurrenceFrequency frequency) =>
        frequency switch
        {
            RecurrenceFrequency.WEEKLY => date.AddDays(7),
            RecurrenceFrequency.BIWEEKLY => date.AddDays(14),
            RecurrenceFrequency.MONTHLY => date.AddMonths(1),
            RecurrenceFrequency.YEARLY => date.AddYears(1),
            _ => date.AddMonths(1)
        };
}
