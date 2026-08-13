using Microsoft.EntityFrameworkCore;
using FinTrack.Application.DTOs.Reports;
using FinTrack.Application.Interfaces;
using FinTrack.Domain.Enums;

namespace FinTrack.Application.Services;

public class ReportService : IReportService
{
    private readonly IFinTrackDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly IDateTimeProvider _clock;

    public ReportService(IFinTrackDbContext db, ICurrentUser currentUser, IDateTimeProvider clock)
    {
        _db = db;
        _currentUser = currentUser;
        _clock = clock;
    }

    public async Task<MonthlyReportDto> GetMonthlyAsync(int month, int year, CancellationToken cancellationToken = default)
    {
        if (month is < 1 or > 12)
        {
            month = _clock.UtcNow.Month;
        }

        if (year < 2000)
        {
            year = _clock.UtcNow.Year;
        }

        var query = UserTransactions().Where(t => t.Date.Month == month && t.Date.Year == year);
        var income = await query.Where(t => t.Type == TransactionType.INCOME).SumAsync(t => t.Amount, cancellationToken);
        var expense = await query.Where(t => t.Type == TransactionType.EXPENSE).SumAsync(t => t.Amount, cancellationToken);

        var allIncome = await UserTransactions().Where(t => t.Type == TransactionType.INCOME && (t.Date.Year < year || (t.Date.Year == year && t.Date.Month <= month))).SumAsync(t => t.Amount, cancellationToken);
        var allExpense = await UserTransactions().Where(t => t.Type == TransactionType.EXPENSE && (t.Date.Year < year || (t.Date.Year == year && t.Date.Month <= month))).SumAsync(t => t.Amount, cancellationToken);

        var top = await GetCategoryExpensesInternalAsync(query.Where(t => t.Type == TransactionType.EXPENSE), expense, 5, cancellationToken);

        return new MonthlyReportDto
        {
            Month = month,
            Year = year,
            Income = income,
            Expense = expense,
            Savings = income - expense,
            Balance = allIncome - allExpense,
            TopExpenseCategories = top
        };
    }

    public async Task<IReadOnlyList<CategoryExpenseDto>> GetCategoryExpensesAsync(DateTime? startDate, DateTime? endDate, CancellationToken cancellationToken = default)
    {
        var (start, end) = ResolveRange(startDate, endDate);
        var query = UserTransactions().Where(t => t.Type == TransactionType.EXPENSE && t.Date >= start && t.Date <= end);
        var total = await query.SumAsync(t => t.Amount, cancellationToken);
        return await GetCategoryExpensesInternalAsync(query, total, 20, cancellationToken);
    }

    public async Task<IncomeVsExpensesDto> GetIncomeVsExpensesAsync(DateTime? startDate, DateTime? endDate, CancellationToken cancellationToken = default)
    {
        var (start, end) = ResolveRange(startDate, endDate);
        var grouped = await UserTransactions()
            .Where(t => t.Date >= start && t.Date <= end)
            .GroupBy(t => new { t.Date.Year, t.Date.Month })
            .Select(g => new MonthlyPointDto
            {
                Year = g.Key.Year,
                Month = g.Key.Month,
                Income = g.Where(t => t.Type == TransactionType.INCOME).Sum(t => t.Amount),
                Expense = g.Where(t => t.Type == TransactionType.EXPENSE).Sum(t => t.Amount)
            })
            .ToListAsync(cancellationToken);

        var points = new List<MonthlyPointDto>();
        for (var cursor = new DateTime(start.Year, start.Month, 1, 0, 0, 0, DateTimeKind.Utc);
             cursor <= end;
             cursor = cursor.AddMonths(1))
        {
            var match = grouped.FirstOrDefault(g => g.Year == cursor.Year && g.Month == cursor.Month);
            points.Add(new MonthlyPointDto
            {
                Year = cursor.Year,
                Month = cursor.Month,
                Income = match?.Income ?? 0,
                Expense = match?.Expense ?? 0,
                Savings = (match?.Income ?? 0) - (match?.Expense ?? 0)
            });
        }

        return new IncomeVsExpensesDto { Points = points };
    }

    public async Task<BalanceHistoryDto> GetBalanceHistoryAsync(DateTime? startDate, DateTime? endDate, CancellationToken cancellationToken = default)
    {
        var (start, end) = ResolveRange(startDate, endDate);
        var priorIncome = await UserTransactions().Where(t => t.Type == TransactionType.INCOME && t.Date < start).SumAsync(t => t.Amount, cancellationToken);
        var priorExpense = await UserTransactions().Where(t => t.Type == TransactionType.EXPENSE && t.Date < start).SumAsync(t => t.Amount, cancellationToken);
        var running = priorIncome - priorExpense;

        var daily = await UserTransactions()
            .Where(t => t.Date >= start && t.Date <= end)
            .GroupBy(t => t.Date.Date)
            .Select(g => new
            {
                Date = g.Key,
                Delta = g.Sum(t => t.Type == TransactionType.INCOME ? t.Amount : -t.Amount)
            })
            .OrderBy(x => x.Date)
            .ToListAsync(cancellationToken);

        var points = new List<BalancePointDto>();
        var map = daily.ToDictionary(x => x.Date, x => x.Delta);
        for (var day = start.Date; day <= end.Date; day = day.AddDays(1))
        {
            if (map.TryGetValue(day, out var delta))
            {
                running += delta;
            }

            points.Add(new BalancePointDto { Date = DateTime.SpecifyKind(day, DateTimeKind.Utc), Balance = running });
        }

        return new BalanceHistoryDto { Points = points };
    }

    private IQueryable<Domain.Entities.Transaction> UserTransactions() =>
        _db.Transactions.AsNoTracking().Where(t => t.UserId == _currentUser.UserId);

    private static async Task<IReadOnlyList<CategoryExpenseDto>> GetCategoryExpensesInternalAsync(
        IQueryable<Domain.Entities.Transaction> query,
        decimal total,
        int take,
        CancellationToken cancellationToken)
    {
        var items = await query
            .Include(t => t.Category)
            .GroupBy(t => new { t.CategoryId, t.Category.Name, t.Category.Icon, t.Category.IsDefault })
            .Select(g => new CategoryExpenseDto
            {
                CategoryId = g.Key.CategoryId,
                CategoryName = g.Key.Name,
                CategoryIcon = g.Key.Icon,
                CategoryIsDefault = g.Key.IsDefault,
                Amount = g.Sum(t => t.Amount)
            })
            .OrderByDescending(x => x.Amount)
            .Take(take)
            .ToListAsync(cancellationToken);

        foreach (var item in items)
        {
            item.Percentage = total == 0 ? 0 : Math.Round(item.Amount / total * 100, 2);
        }

        return items;
    }

    private (DateTime Start, DateTime End) ResolveRange(DateTime? startDate, DateTime? endDate)
    {
        var now = _clock.UtcNow;
        var start = startDate?.ToUniversalTime() ?? new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc).AddMonths(-5);
        var end = endDate?.ToUniversalTime() ?? now;
        if (end < start)
        {
            (start, end) = (end, start);
        }

        return (start, end);
    }
}
